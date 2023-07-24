%include "include/stdio.inc"

[bits 32]
;-------------------------------------------------------------------------------
; 函数名: put_uint
; 描述: 输出类型为无符号十进制整数
; 参数: 
;   - %1: 要打印的正整数
; 返回值: 所打印的字符总数
;-------------------------------------------------------------------------------
func_lib put_uint
    ; 在十进制数字转字符时用于求余
    uint32_t divisor, 10

    ; 在十进制数字转字符时用于缓冲
    ; 4 字节无符号整数最大值 4294967295, 共十位字符
    uint8_t buffer_end, 0
    local char_t * 10, buffer

    ; 通过除以 10 求余来获取数字对应的字符并打印
    arg uint32_t, u_num
    mov eax, dword u_num

    lea esi, buffer
    add esi, 10

    uint_fmt_loop:
        dec esi

        mov edx, 0
        idiv dword divisor

        add dl, '0'
        mov [esi], dl

        cmp eax, 0
        jne uint_fmt_loop

    put_str(esi)
func_end

;-------------------------------------------------------------------------------
; 函数名: put_int
; 描述: 输出类型为有符号的十进制整数
; 参数: 
;   - %1: 要打印的整数
; 返回值: 所打印的字符总数
;-------------------------------------------------------------------------------
func_lib put_int
    arg int32_t, num
    mov ecx, dword num

    test ecx, 0x80000000
    jnz is_negative
    
    put_uint(ecx)
    return_32 eax

    ; 是负数
    is_negative:
        put_char('-')

        neg ecx
        put_uint(ecx)

        add eax, 1
        return_32 eax
func_end