%include "include/stdio.inc"
%include "include/system/idt.inc"

%define ERROR nop
%define NONE push dword 0

%macro DefineIntrEntry 2
section .text
    intr_%1_entry:
        %2
        ; 保存上下文
        push ds
        push es
        push fs
        push gs
        pushad
        
        ; 向主从片发送EOI
        mov al,0x20
        out 0xa0,al
        out 0x20,al

        ; 调用中断处理程序
        sub esp, dword 1
        mov [esp], byte %1
        call [intr_handle_table + %1 * 4]
        add esp, dword 1

        ; 恢复上下文
        popad
        pop gs
        pop fs
        pop es
        pop ds

        add esp, dword 4
        iret

    section .data
        dd intr_%1_entry    ; 存储各个中断入口程序的地址
%endmacro

%macro DefineIntrName 2
    section .data
        intr_name_%1 db %2, 0
    section .text
        mov [intr_name_table + %1 * 4], dword intr_name_%1

%endmacro

[bits 32]
section .data
    ; 用于存储 33 个 4 字节大小的中断处理函数地址
    intr_handle_table times 4 * 0x21 db 0

    ; 用于存储 33 个 4 字节大小的中断名称字符串地址
    intr_name_table times 4 * 0x21 db 0

    unknown db "unknown", 0 ; 默认名称

    ; 用创建和定义 33 个 4 字节大小的中断入口函数地址
    intr_entry_table:
        DefineIntrEntry 0x00, NONE
        DefineIntrEntry 0x01, NONE
        DefineIntrEntry 0x02, NONE
        DefineIntrEntry 0x03, NONE 
        DefineIntrEntry 0x04, NONE
        DefineIntrEntry 0x05, NONE
        DefineIntrEntry 0x06, NONE
        DefineIntrEntry 0x07, NONE 
        DefineIntrEntry 0x08, ERROR
        DefineIntrEntry 0x09, NONE
        DefineIntrEntry 0x0a, ERROR
        DefineIntrEntry 0x0b, ERROR 
        DefineIntrEntry 0x0c, NONE
        DefineIntrEntry 0x0d, ERROR
        DefineIntrEntry 0x0e, ERROR
        DefineIntrEntry 0x0f, NONE 
        DefineIntrEntry 0x10, NONE
        DefineIntrEntry 0x11, ERROR
        DefineIntrEntry 0x12, NONE
        DefineIntrEntry 0x13, NONE 
        DefineIntrEntry 0x14, NONE
        DefineIntrEntry 0x15, NONE
        DefineIntrEntry 0x16, NONE
        DefineIntrEntry 0x17, NONE 
        DefineIntrEntry 0x18, ERROR
        DefineIntrEntry 0x19, NONE
        DefineIntrEntry 0x1a, ERROR
        DefineIntrEntry 0x1b, ERROR 
        DefineIntrEntry 0x1c, NONE
        DefineIntrEntry 0x1d, ERROR
        DefineIntrEntry 0x1e, ERROR
        DefineIntrEntry 0x1f, NONE 
        DefineIntrEntry 0x20, NONE
    
    ; 用于存储 33 个 8 字节大小的中断描述符
    intr_desc_table times 8 * 0x21 db 0

    idt_ptr: istruc IdtPointer
        at Limit,    dw 0
        at BaseAddr, dd 0
    iend

;-------------------------------------------------------------------------------
; 函数名: make_idt_desc
; 描述: 在intr_desc_table中注册一个中断描述符
; 参数: 
;   - %1: 描述符地址
;   - %2: 描述符属性
;   - %3: 入口函数地址
; 返回值: 无
;-------------------------------------------------------------------------------
func make_idt_desc
    arg pointer_t, p_gdesc
    arg uint8_t, attr
    arg pointer_t, function

    mov ebx, function
    mov eax, [ebx]

    mov ebx, p_gdesc

    mov word [ebx + FuncLow], ax
    shr eax, 16
    mov word [ebx + FuncHigh], ax

    mov word [ebx + Selector], SELECTOR_CODE

    mov byte [ebx + ArgCount],  0

    mov al, attr
    mov byte [ebx + AttrType], al
func_end

;-------------------------------------------------------------------------------
; 函数名: intr_handle
; 描述: 通用中断处理函数
; 参数: 
;   - %1: 中断向量
; 返回值: 无
;-------------------------------------------------------------------------------
func intr_handle
    arg uint8_t, vec_nr
    movzx edx, byte vec_nr

    ; 伪中断, 无需处理
    cmp dl, 0x27
    je __FUNCEND__
    cmp dl, 0x2f
    je __FUNCEND__

    printf("int vector: %p\n", edx)
func_end

;-------------------------------------------------------------------------------
; 函数名: idt_desc_init
; 描述: 初始化中断描述符表
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func idt_desc_init
    mov ecx, 0x21   ; 目前支持的中断数
    mov edi, intr_desc_table
    mov esi, intr_entry_table

    make_loop:
        sub esp, 4
        mov dword [esp], esi

        sub esp, 1
        mov byte [esp], DESC_P | DESC_DPL_0 | DESC_S_SYS | DESC_TYPE_32

        sub esp, 4
        mov dword [esp], edi

        call make_idt_desc
        add esp, 4 + 1 + 4
        
        add edi, 8
        add esi, 4
        loop make_loop
func_end

;-------------------------------------------------------------------------------
; 函数名: pic_init
; 描述: 初始化可编程中断控制器
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func pic_init
    ; 初始化主片8259A
    mov al, 0x11      ; 初始化命令字1
    out PIC_M_CTRL, al     ; 发送命令字1到主片的命令端口

    mov al, 0x20      ; 设置主片的中断向量偏移量为0x20
    out PIC_M_DATA, al     ; 发送中断向量偏移量到主片的数据端口

    mov al, 0x04      ; 设置主片的IR2引脚连接从片
    out PIC_M_DATA, al     ; 发送IR2配置到主片的数据端口

    mov al, 0x01      ; 设置主片工作在8086兼容模式
    out PIC_M_DATA, al     ; 发送模式配置到主片的数据端口

    ; 初始化从片8259A
    mov al, 0x11      ; 初始化命令字1
    out PIC_S_CTRL, al     ; 发送命令字1到从片的命令端口

    mov al, 0x28      ; 设置从片的中断向量偏移量为0x28
    out PIC_S_DATA, al     ; 发送中断向量偏移量到从片的数据端口

    mov al, 0x02      ; 设置从片的IR2引脚连接主片
    out PIC_S_DATA, al     ; 发送IR2配置到从片的数据端口

    mov al, 0x01      ; 设置从片工作在8086兼容模式
    out PIC_S_DATA, al     ; 发送模式配置到从片的数据端口

    ; 打开主片上IR0, 也就是目前只接受时钟产生的中断
    mov al, 0xfe
    out PIC_M_DATA, al

    mov al, 0xff
    out PIC_S_DATA, al

func_end

;-------------------------------------------------------------------------------
; 函数名: exception_init
; 描述: 初始化中断处理函数表和中断名称表
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func exception_init
    mov esi, 0
    make2_loop:
        mov [intr_handle_table + esi * 4], dword intr_handle
        mov [intr_name_table + esi * 4], dword unknown

        inc esi
        cmp esi, 0x21
        jne make2_loop
    
    DefineIntrName 0, "#DE Divide Error"
    DefineIntrName 1, "#DB Debug Exception"
    DefineIntrName 2, "NMI Interrupt"
    DefineIntrName 3, "#BP Breakpoint Exception"
    DefineIntrName 4, "#OF Overflow Exception"
    DefineIntrName 5, "#BR BOUND Range Exceeded Exception"
    DefineIntrName 6, "#UD Invalid Opcode Exception"
    DefineIntrName 7, "#NM Device Not Available Exception"
    DefineIntrName 8, "#DF Double Fault Exception"
    DefineIntrName 9, "Coprocessor Segment Overrun"
    DefineIntrName 10, "#TS Invalid TSS Exception"
    DefineIntrName 11, "#NP Segment Not Present"
    DefineIntrName 12, "#SS Stack Fault Exception"
    DefineIntrName 13, "#GP General Protection Exception"
    DefineIntrName 14, "#PF Page-Fault Exception"
    ; DefineIntrName 15 第15项是intel保留项, 未使用
    DefineIntrName 16, "#MF x87 FPU Floating-Point Error"
    DefineIntrName 17, "#AC Alignment Check Exception"
    DefineIntrName 18, "#MC Machine-Check Exception"
    DefineIntrName 19, "#XF SIMD Floating-Point Exception"

func_end

;-------------------------------------------------------------------------------
; 函数名: idt_init
; 描述: 初始化中断相关并加载IDT表
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
extern timer_init

func idt_init
    call idt_desc_init
    call pic_init
    call exception_init
    call timer_init

    mov word [idt_ptr + Limit], 8 * 0x21 - 1
    mov dword [idt_ptr + BaseAddr], intr_desc_table
    lidt [idt_ptr]     ; 使用lidt指令加载IDT表
func_end