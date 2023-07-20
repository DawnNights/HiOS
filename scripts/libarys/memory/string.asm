%include "include/builtin.inc"

[bits 32]
;-------------------------------------------------------------------------------
; 函数名: memset
; 描述: 将某一块内存中的内容全部设置为指定的字节
; 参数: 
;   - %1: 指向内存块的地址
;   - %2: 用于设置的字节内容
;   - %3: 需要设置的内存块长度
; 返回值: 所打印的字符总数
;-------------------------------------------------------------------------------
func_lib memset
    arg pointer_t, buffer
    arg uint8_t, value
    arg uint32_t, setlen

    mov esi, buffer
    mov ecx, setlen

    mov dl, value
    set_loop:
        mov [esi], dl
        inc esi
        loop set_loop
    
    return_32 buffer
func_end

;-------------------------------------------------------------------------------
; 函数名: memcpy
; 描述: 拷贝一块内存到另一块内存
; 参数: 
;   - %1: 被设置的目标内存块起始地址
;   - %2: 用于设置的源内存块起始地址
;   - %3: 需要拷贝的内存块长度
; 返回值: 目标内存块起始地址
;-------------------------------------------------------------------------------
func_lib memcpy
    arg pointer_t, target
    arg pointer_t, source
    arg uint32_t, cpylen

    mov ecx, cpylen
    mov esi, source
    mov edi, target

    cpy_loop:
        mov dl, byte [esi]
        mov byte [edi], dl

        inc esi
        inc edi
        loop cpy_loop

    return_32 target
func_end