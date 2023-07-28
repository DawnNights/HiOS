%include "include/builtin.inc"
%include "include/system/idt.inc"


[bits 32]
section .data
    ; 用于存储 33 个 4 字节大小的中断入口函数地址
    extern intr_entry_table
    
    ; 用于存储 33 个 8 字节大小的中断描述符
    intr_desc_table times 8 * 0x21 db 0

    ; 该结构体用于初始化 idt 表
    idt_ptr: istruc IdtPointer
        at Limit,    dw 8 * 0x21 - 1
        at BaseAddr, dd intr_desc_table
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
; 函数名: idt_init
; 描述: 初始化中断相关并加载IDT表
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
extern pic_init
extern timer_init

func idt_init
    ; 初始化中断相关内容
    call pic_init
    call timer_init

    ; 使用lidt指令加载IDT表
    call idt_desc_init
    lidt [idt_ptr]
func_end