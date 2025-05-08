%include "include/ioqueue.inc"
%include "include/stdio.inc"
%include "include/stdlib.inc"
%include "include/system/keyboard.inc"

section .data
    ; ctrl 是否被按下
    ctrl_status     db 0

    ; shift 是否被按下
    shift_status    db 0

    ; alt 是否被按下
    alt_status      db 0

    ; capslock 是否被按下
    caps_status     db 0

    ; map 字符映射表
    map1 db 0, 0, "1234567890-=", 0x08, 0x09, "qwertyuiop[]", 0x0A, 0, "asdfghjkl;'`", 0, "\zxcvbnm,./", 0, 0, 0, ' '
    map2 db 0, 0, "1234567890-=", 0x08, 0x09, "QWERTYUIOP[]", 0x0A, 0, "ASDFGHJKL;'`", 0, "\ZXCVBNM,./", 0, 0, 0, ' '
    map3 db 0, 0, "!@#$%^&*()_+", 0x08, 0x09, "QWERTYUIOP{}", 0x0A, 0, "ASDFGHJKL:", 0x22, '~', 0, "|ZXCVBNM<>?", 0, 0, 0, ' '
    map4 db 0, 0, "!@#$%^&*()_+", 0x08, 0x09, "qwertyuiop{}", 0x0A, 0, "asdfghjkl:", 0x22, '~', 0, "|zxcvbnm<>?", 0, 0, 0, ' '

    ; 键盘环形缓冲区
    global kbd_ioq
    kbd_ioq: istruc IOQueue
        at IOQueue.Head, dd 0
        at IOQueue.Tail, dd 0
        at IOQueue.Lock, dd 0,0,0,0
        at IOQueue.Producer, dd 0
        at IOQueue.Consumer, dd 0
        at IOQueue.Buffer, times BUFSIZE db 0
    iend

section .text
;-------------------------------------------------------------------------------
; 函数名: keyboard_intr_entry
; 描述: 0x21 键盘中断发生时的入口函数
; 备注: 该中断发生时不会压入错误码
;-------------------------------------------------------------------------------
keyboard_intr_entry:
    pushad
    
    ; 向主从片发送EOI(中断结束标记)
    mov al,0x20
    out 0xa0,al
    out 0x20,al

    ; 读取输出缓存区寄存器
read_code:
    in al, KBD_BUF_PORT
    movzx eax, al

    cmp eax, EXT_SCANCODE
    je keyboard_intr_exit

    cmp eax, SHIFT_LEFT_MAKE
    je is_shift_make

    cmp eax, SHIFT_LEFT_BREAK
    je is_shift_break

    cmp eax, SHIFT_RIGHT_MAKE
    je is_shift_make

    cmp eax, SHIFT_RIGHT_BREAK
    je is_shift_break

    cmp eax, CTRL_MAKE
    je is_ctrl_make

    cmp eax, CTRL_BREAK
    je is_ctrl_break

    cmp eax, ALT_MAKE
    je is_alt_make

    cmp eax, ALT_BREAK
    je is_alt_break

    cmp eax, CAPSLOCK
    je is_caps_lock

    cmp eax, KEY_UP
    je is_key_up

    cmp eax, KEY_DOWN
    je is_key_down

    cmp eax, KEY_LEFT
    je is_key_left

    cmp eax, KEY_RIGHT
    je is_key_right

    jmp write_code
    
    is_shift_make:
        mov [shift_status], byte 1
        jmp keyboard_intr_exit

    is_shift_break:
        mov [shift_status], byte 0
        jmp keyboard_intr_exit

    is_ctrl_make:
        mov [ctrl_status], byte 1
        jmp keyboard_intr_exit

    is_ctrl_break:
        mov [ctrl_status], byte 0
        jmp keyboard_intr_exit

    is_alt_make:
        mov [alt_status], byte 1
        jmp keyboard_intr_exit

    is_alt_break:
        mov [alt_status], byte 0
        jmp keyboard_intr_exit

    is_caps_lock:
        cmp [caps_status], byte 0
        je caps_open
        jmp caps_close

        caps_open:
            mov [caps_status], byte 1
            jmp keyboard_intr_exit

        caps_close:
            mov [caps_status], byte 0
            jmp keyboard_intr_exit

    is_key_up:
        get_cursor_ex()
        sub ah, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    is_key_down:
        get_cursor_ex()
        add ah, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    is_key_left:
        get_cursor_ex()
        sub al, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    is_key_right:
        get_cursor_ex()
        add al, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    ; 在终端输出字符
write_code:
    cmp eax, 0x80
    jge keyboard_intr_exit

    cmp [shift_status], byte 1
    je use_map3_or_map4

    cmp [caps_status], byte 1
    je use_map2

    jmp use_map1

    use_map3_or_map4:
        cmp [caps_status], byte 1
        je use_map4
        jmp use_map3

        use_map4:
            lea esi, [eax + map4]
            jmp code_put

        use_map3:
            lea esi, [eax + map3]
            jmp code_put
    
    use_map2:
        lea esi, [eax + map2]
        jmp code_put

    use_map1:
        lea esi, [eax + map1]
    
    code_put: 
        ioq_putchar(kbd_ioq, [esi])
        ; put_char([esi])

    ; 从中断返回
keyboard_intr_exit:
    popad
    iret

;-------------------------------------------------------------------------------
; 函数名: keyboard_init
; 描述: 初始化键盘中断
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
extern intr_entry_table

func keyboard_init
    ; 初始化缓冲区
    ioq_init(kbd_ioq)

    ; 将 timer_intr_entry 注册到 intr_entry_table 中
    mov [intr_entry_table + 0x21 * 4], dword keyboard_intr_entry
func_end
