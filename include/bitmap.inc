%ifndef BITMAP_INC
%define BITMAP_INC

%include "include/builtin.inc"

; 位图结构
struc BitMap
    .ByteSize:   resd 1   ; 位图占字节大小
    .BitPointer: resd 1   ; 指向数据的指针
endstruc

;-------------------------------------------------------------------------------
; 宏原型: void bitmap_empty(pointer_t btmp)
;-------------------------------------------------------------------------------
extern_lib bitmap_empty

%macro bitmap_empty 1
    ; 4 字节大小的 btmp 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib bitmap_empty
    add esp, dword 4
%endmacro

%define bitmap_empty(btmp) bitmap_empty btmp

;-------------------------------------------------------------------------------
; 宏原型: bool_t bitmap_get(pointer_t btmp, uint32_t bit_idx)
;-------------------------------------------------------------------------------
extern_lib bitmap_get

%macro bitmap_get 2
    ; 4 字节大小的 bit_idx 参数入栈
    push_32 %2

    ; 4 字节大小的 btmp 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib bitmap_get
    add esp, dword 4 + 4
%endmacro

%define bitmap_get(btmp, bit_idx) bitmap_get btmp, bit_idx

;-------------------------------------------------------------------------------
; 宏原型: void bitmap_set(pointer_t btmp, uint32_t bit_idx, bool_t state)
;-------------------------------------------------------------------------------
extern_lib bitmap_set

%macro bitmap_set 3
    ; 1 字节大小的 state 参数入栈
    push_8 %3

    ; 4 字节大小的 bit_idx 参数入栈
    push_32 %2

    ; 4 字节大小的 btmp 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib bitmap_set
    add esp, dword 4 + 4 + 1
%endmacro

%define bitmap_set(btmp, bit_idx, state) bitmap_set btmp, bit_idx, state

;-------------------------------------------------------------------------------
; 宏原型: uint32_t bitmap_scan(pointer_t btmp, uint32_t count)
;-------------------------------------------------------------------------------
extern_lib bitmap_scan

%macro bitmap_scan 2
    ; 4 字节大小的 count 参数入栈
    push_32 %2

    ; 4 字节大小的 btmp 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib bitmap_scan
    add esp, dword 4 + 4
%endmacro

%define bitmap_scan(btmp, count) bitmap_scan btmp, count

%endif