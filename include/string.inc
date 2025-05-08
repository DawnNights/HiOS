%ifndef STRING_INC
%define STRING_INC

%include "include/builtin.inc"

;-------------------------------------------------------------------------------
; 宏原型: void memset(pointer_t buffer, uint8_t value, uint32_t length)
;-------------------------------------------------------------------------------
extern_lib memset

%macro memset 3
    ; 4 字节大小的 length 参数入栈
    push_32 %3

    ; 1 字节大小的 value 参数入栈
    push_8 %2

    ; 4 字节大小的 buffer 参数入栈
    push_32 %1

    call_lib memset
    add esp, 4 + 1 + 4
%endmacro

%define memset(buffer, value, length) memset buffer, value, length

;-------------------------------------------------------------------------------
; 宏原型: pointer_t memcpy(pointer_t target, pointer_t source, uint32_t length)
;-------------------------------------------------------------------------------
extern_lib memcpy

%macro memcpy 3
    ; 4 字节大小的 length 参数入栈
    push_32 %3

    ; 4 字节大小的 source 参数入栈
    push_32 %2
    
    ; 4 字节大小的 target 参数入栈
    push_32 %1

    call_lib memcpy
    add esp, 4 + 4 + 4
%endmacro

%define memcpy(target, source, length) memcpy target, source, length

;-------------------------------------------------------------------------------
; 宏原型: pointer_t strcpy(pointer_t target, pointer_t source)
;-------------------------------------------------------------------------------
extern_lib strcpy

%macro strcpy 2
    ; 4 字节大小的 source 参数入栈
    push_32 %2
    
    ; 4 字节大小的 target 参数入栈
    push_32 %1

    call_lib strcpy
    add esp, 4 + 4
%endmacro

%define strcpy(target, source) strcpy target, source

;-------------------------------------------------------------------------------
; 宏原型: uint32_t strlen(pointer_t str)
;-------------------------------------------------------------------------------
extern_lib strlen

%macro strlen 1
    ; 4 字节大小的 str 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib strlen
    add esp, dword 4
%endmacro

%define strlen(str) strlen str

%endif
