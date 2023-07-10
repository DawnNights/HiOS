%include "include/stdio.inc"

[bits 32]
;-------------------------------------------------------------------------------
; 函数名: put_str
; 描述: 在终端打印字符串
; 参数: 
;   - %1: 要打印的字符串的地址
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib put_str
    ; 用于记录所打印的字符总数
    uint32_t put_count, 0

    ; 遍历字符串进行打印
    arg pointer_t, char_ptr
    mov esi, char_ptr

    put_str_loop:
        cmp [esi], byte '\'
        je need_escape
        jmp is_nothing

        ; 需要进行转义
        need_escape:
            inc esi

            cmp [esi], byte 'n'
            je is_wrap

            cmp [esi], byte 'b'
            je is_back

            jmp is_nothing
            
        ; 转义-换行
        is_wrap:
            put_char(0x0A)
            jmp put_str_next

        ; 转义-退格
        is_back:
            put_char(0x08)
            sub put_count, dword 1
            jmp put_str_next

        ; 无需转义
        is_nothing:
            mov dl, [esi]
            put_char(dl)
            jmp put_str_next

    put_str_next:
        add put_count, dword 1

        ; 如果为 null 字符则结束打印
        inc esi
        cmp [esi], byte 0
        jne put_str_loop

    return_32 put_count
func_end