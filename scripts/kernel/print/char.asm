%include "include/stdlib.inc"

[bits 32]
SELECTOR_K_VIDEO equ (0x03 << 3) | 0 | 0

section .data
    global CHAR_ATTR
    CHAR_ATTR db 00001111b

;-------------------------------------------------------------------------------
; 函数名: put_char
; 描述: 在终端打印字符
; 参数: 
;   - %1: 要打印的字符
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib put_char
    intr_disable

    ; 空字符不打印
    arg char_t, ascii
    cmp ascii, byte 0x00
    je __FUNCEND__

    ; 获取显存单元位置至寄存器bx
    get_cursor()
    shl ax, 1
    mov bx, ax

    ; 初始化es为显存段选择子
    mov ax, SELECTOR_K_VIDEO
    mov es, ax

    ; 打印字符至对应显存单元
    cmp ascii, byte 0x08
    je ascii_BS
    cmp ascii, byte 0x09
    je ascii_HT
    cmp ascii, byte 0x0A
    je ascii_LF

    call need_roll
    mov dh, [CHAR_ATTR]
    mov dl, ascii

    mov word [es:bx], dx
    add bx, 2
    jmp update_cursor

    ; 退格控制字符
    ascii_BS:
        mov dl, 160
        mov ax, bx
        div dl

        cmp ah, 0
        je update_cursor

        sub bx, 2
        mov word [es:bx], 0x0f20
        jmp update_cursor

    ; 水平制表字符
    ascii_HT:
        ; 将 bx 的值除以 160 得到的商为当前光标纵坐标纵坐标
        mov dl, 160
        mov ax, bx
        div dl
        mov dl, al

        ; 将纵坐标存储至dl寄存器, 将其加一在乘以 160 则得到下一行坐标
        mov ax, 160
        add dl, 1
        mul dl
        sub ax, 2

        mov ecx, 4
        HT_loop:
            cmp bx, ax
            je update_cursor

            mov word [es:bx], 0x0f20
            add bx, 2
            loop HT_loop
        
        jmp update_cursor

    ; 换行控制字符
    ascii_LF:
        ; 将 bx 的值除以 160 得到的商为当前光标纵坐标纵坐标
        mov dl, 160
        mov ax, bx
        div dl
        mov dl, al

        ; 将纵坐标存储至dl寄存器, 将其加一在乘以 160 则得到下一行坐标
        mov ax, 160
        add dl, 1
        mul dl
        mov bx, ax

        jmp update_cursor

    ; 判断是否需要滚行
    need_roll:
        cmp bx, 4000
        jl is_not_need

        roll_screen(1); 全局计次宏变量

        mov bx, (24 * 80 + 0)
        set_cursor(bh, bl)
        shl bx, 1

        is_not_need:
            ret

    ; 更新光标所在坐标
    update_cursor:
        shr bx, 1
        set_cursor(bh, bl)
    
    intr_recover
func_end
