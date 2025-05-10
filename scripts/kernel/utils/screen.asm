%include "include/builtin.inc"

[bits 32]
SELECTOR_K_VIDEO equ (0x03 << 3) | 0 | 0

;-------------------------------------------------------------------------------
; 函数名: roll_screen
; 描述: 控制台滚屏, 将所有行的字符搬运至上一行
; 参数: 
;   - %1: 需要滚行的次数(1~25)
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib roll_screen
    arg uint8_t, count
    
    mov ax, SELECTOR_K_VIDEO
    mov es, ax

    roll_loop:
        cmp count, byte 0
        je __FUNCEND__

        ; (25-1) * 80 * 2 = 3840 字节要搬运
        mov edi, 0x00 ; 第零行行首
        mov esi, 0xa0 ; 第一行行首

        cpy_loop:
            mov edx, dword [es:esi+ecx]
            mov dword [es:edi+ecx], edx

            add ecx, 4
            cmp ecx, 3840
            jne cpy_loop


        ; 将最后一行填充为空白
        mov ebx, 3840
        mov ecx, 80

        cls_loop:
            mov word [es:ebx], 0x0720
            add ebx, 2
            loop cls_loop

        dec byte count
        jmp roll_loop
func_end