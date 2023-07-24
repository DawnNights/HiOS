%include "include/stdio.inc"

[bits 32]
extern intr_disable
extern intr_recover

;-------------------------------------------------------------------------------
; 函数名: printf
; 描述: 格式化输出函数
; 参数: 
;   - %1: 格式控制字符串
;   - %1+: 用于格式化的参数
; 返回值: 所打印的字符总数
;-------------------------------------------------------------------------------
func_lib printf
    call intr_disable

    ; 用于记录所打印的字符总数
    uint32_t put_count, 0

    push esi
    push edi

    ; 用于指向栈中的参数
    arg pointer_t, format
    lea edi, format
    mov esi, [edi]

    put_str_loop:
        cmp [esi], byte '\'
        je need_escape
        
        cmp [esi], byte '%'
        je need_format
        
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
            mov [esi], byte 0x0A
            jmp is_nothing

        ; 转义-退格
        is_back:
            put_char(0x08)
            jmp print_str_next

        ; 需要进行格式化
        need_format:
            inc esi

            cmp [esi], byte 's'
            je is_string
            cmp [esi], byte 'd'
            je is_int
            cmp [esi], byte 'u'
            je is_uint
            cmp [esi], byte 'p'
            je is_ptr
            cmp [esi], byte 'x'
            je is_hex_lower
            cmp [esi], byte 'X'
            je is_hex_upper
            cmp [esi], byte 'n'
            je is_count

            jmp is_nothing

        ; 格式化-字符串
        is_string:
            add edi, 4
            put_str([edi])

            add put_count, eax
            jmp print_str_next

        ; 格式化-整数
        is_int:
            add edi, 4
            put_int([edi])

            add put_count, eax
            jmp print_str_next
        
        ; 格式化-正整数
        is_uint:
            add edi, 4
            put_uint([edi])

            add put_count, eax
            jmp print_str_next
        
        ; 格式化-地址
        is_ptr:
            put_char('0')
            put_char('x')
            jmp is_hex_lower

        ; 格式化-十六进制
        is_hex_lower:
            add edi, 4
            put_hex([edi], 0)

            add put_count, eax
            jmp print_str_next
        
        is_hex_upper:
            add edi, 4
            put_hex([edi], 1)

            add put_count, eax
            jmp print_str_next

        ; 格式化-打印次数统计
        is_count:
            put_uint(put_count)

            add put_count, eax
            jmp print_str_next

        ; 无需转义或格式化
        is_nothing:
            put_char([esi])

            add put_count, dword 1
            jmp print_str_next

    print_str_next:
        ; 如果为 null 字符则结束打印
        inc esi
        cmp [esi], byte 0
        jne put_str_loop

    call intr_recover
    return_32 put_count
func_end