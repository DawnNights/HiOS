%include "include/builtin.inc"
%include "include/system/idt.inc"

[bits 32]
; 8259A 主从片的相关端口
PIC_M_CTRL equ 0x20
PIC_M_DATA equ 0x21
PIC_S_CTRL equ 0xA0
PIC_S_DATA equ 0xA1

; 支持的中断数量
INTR_DESC_CNT equ 0x30

section .data
    ; 用于存储 INTR_DESC_CNT 个 8 字节大小的中断描述符
    intr_desc_table times 8 * INTR_DESC_CNT db 0

    ; 该结构体用于初始化 idt 表
    idt_ptr: istruc IdtPointer
        at Limit,    dw 8 * INTR_DESC_CNT - 1
        at BaseAddr, dd intr_desc_table
    iend

    ; 用于存储 INTR_DESC_CNT 个 4 字节大小的中断入口函数地址
    global intr_entry_table

    intr_entry_table:
        ; 0x00 除零异常, 当执行除法操作时除数为零, 导致除法错误
        dd intr_entry_no_err

        ; 0x01 调试异常, 用于调试目的, 通常由调试器使用
        dd intr_entry_no_err

        ; 0x02 非屏蔽中断, 优先级高于可屏蔽中断, 通常用于处理严重的系统级问题
        dd intr_entry_no_err

        ; 0x03 断点异常, 当执行了 INT3 指令（调试断点）时触发
        dd intr_entry_no_err

        ; 0x04 保留的中断
        dd intr_entry_no_err

        ; 0x05 保留的中断
        dd intr_entry_no_err

        ; 0x06 保留的中断
        dd intr_entry_no_err

        ; 0x07 保留的中断
        dd intr_entry_no_err

        ; 0x08 双重错误, 当产生一个异常时发生另一个异常
        dd intr_entry_with_err

        ; 0x09 协处理器段越界, 当使用协处理器时访问超出有效段范围
        dd intr_entry_no_err

        ; 0x0a 保留的中断
        dd intr_entry_with_err

        ; 0x0b 浮点错误, 当使用浮点协处理器发生错误
        dd intr_entry_with_err

        ; 0x0c 段不存在, 当使用一个不存在的段或访问段描述符时发生
        dd intr_entry_no_err

        ; 0x0d 栈段错误, 当执行堆栈操作时发生堆栈段错误
        dd intr_entry_with_err

        ; 0x0e 页错误, 当发生页面错误时（访问不存在的页面、非法权限等）
        dd intr_entry_with_err

        ; 0x0f 处理器检测到执行了一个保护模式下的无效指令
        dd intr_entry_no_err

        ; 0x10 保留的中断
        dd intr_entry_no_err

        ; 0x11 保留的中断
        dd intr_entry_with_err

        ; 0x12 协处理器错误, 当协处理器发生错误且未被屏蔽时触发
        dd intr_entry_no_err

        ; 0x13 保留的中断
        dd intr_entry_no_err

        ; 0x14 保留的中断
        dd intr_entry_no_err

        ; 0x15 保留的中断
        dd intr_entry_no_err

        ; 0x16 保留的中断
        dd intr_entry_no_err

        ; 0x17 保留的中断
        dd intr_entry_no_err

        ; 0x18 保留的中断
        dd intr_entry_with_err

        ; 0x19 保留的中断
        dd intr_entry_no_err

        ; 0x1a 保留的中断
        dd intr_entry_with_err

        ; 0x1b 保留的中断
        dd intr_entry_with_err

        ; 0x1c 保留的中断
        dd intr_entry_no_err

        ; 0x1d 保留的中断
        dd intr_entry_with_err

        ; 0x1e 保留的中断
        dd intr_entry_with_err

        ; 0x1f 保留的中断
        dd intr_entry_no_err

        ; 0x20 定时器(IRQ0)中断, 由可编程定时器发出的中断
        dd intr_entry_no_err

        ; 0x21 键盘(IRQ1)中断, 当用户按下或释放一个键时触发
        dd intr_entry_no_err

        ; 0x22 保留的中断
        dd intr_entry_no_err

        ; 0x23 保留的中断
        dd intr_entry_no_err

        ; 0x24 保留的中断
        dd intr_entry_no_err

        ; 0x25 保留的中断
        dd intr_entry_no_err

        ; 0x26 保留的中断
        dd intr_entry_no_err

        ; 0x27 保留的中断
        dd intr_entry_no_err

        ; 0x28 保留的中断
        dd intr_entry_no_err

        ; 0x29 保留的中断
        dd intr_entry_no_err

        ; 0x2a 保留的中断
        dd intr_entry_no_err

        ; 0x2b 保留的中断
        dd intr_entry_no_err

        ; 0x2c 保留的中断
        dd intr_entry_no_err

        ; 0x2d 保留的中断
        dd intr_entry_no_err

        ; 0x2e 保留的中断
        dd intr_entry_no_err

        ; 0x2f 保留的中断
        dd intr_entry_no_err

section .text
    ; 未压入错误码的通用中断入口函数
    intr_entry_no_err:
        ; 向主从片发送EOI(中断结束标记)
        push eax
        
        mov al, PIC_M_CTRL
        out 0xa0,al
        out 0x20,al

        pop eax

        ; 从中断返回
        iret


    ; 压入错误码的通用中断入口函数
    intr_entry_with_err:
        ; 跳过错误码
        add esp, 4

        ; 向主从片发送EOI(中断结束标记)
        push eax
        
        mov al, PIC_M_CTRL
        out 0xa0,al
        out 0x20,al

        pop eax

        ; 从中断返回
        iret

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
; 函数名: idt_desc_init
; 描述: 初始化中断描述符表
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func idt_desc_init
    mov ecx, INTR_DESC_CNT
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
; 函数名: idt_init
; 描述: 初始化中断相关并加载IDT表
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
extern timer_init
extern keyboard_init

func idt_init
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

    ; 初始化外设中断
    call timer_init
    call keyboard_init

    ; 同时打开主片上IR0和IR1
    mov al, 0xfc
    out PIC_M_DATA, al

    mov al, 0xff
    out PIC_S_DATA, al

    ; 使用lidt指令加载IDT表
    call idt_desc_init
    lidt [idt_ptr]
func_end
