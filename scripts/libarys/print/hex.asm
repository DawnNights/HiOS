%include "include/stdio.inc"

[bits 32]
;-------------------------------------------------------------------------------
; 函数名: put_hex
; 描述: 输出类型为无符号十六进制整数
; 参数: 
;   - %1: 要打印的正整数
;   - %2: 是否以大写形式打印
; 返回值: 所打印的字符总数
;-------------------------------------------------------------------------------
func_lib put_hex
    ; 在十六进制数字转字符时用于求余
    uint32_t divisor, 16

    ; 在十六进制数字转字符时用于缓冲
    ; 4 字节最大值 ffffffff, 共八位字符
    uint8_t buffer_end, 0
    local char_t * 8, buffer

    ; 通过除以 16 求余来获取数字对应的字符并打印
    arg uint32_t, u_num
    arg bool_t, is_upper
    mov eax, dword u_num

    lea esi, buffer
    add esi, 8

    hex_fmt_loop:
        dec esi

        mov edx, 0
        idiv dword divisor

        cmp dl, 9
        jg more_nine

        add dl, '0'
        jmp hex_fmt_next

        ; 余数大于9
        more_nine:
            add dl, 'A' - 10

            cmp is_upper, byte 0
            jne hex_fmt_next

            add dl, 'a' - 'A'
            
    hex_fmt_next:
        mov [esi], byte dl

        cmp eax, 0
        jne hex_fmt_loop
    
    put_str(esi)
func_end