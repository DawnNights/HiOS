%ifndef LIST_INC
%define LIST_INC

%include "include/builtin.inc"

; 链表结构
struc List
    .Head:  resd 1  ; 链表开头元素的指针
    .Tail:  resd 1  ; 链表末尾元素的指针
endstruc

; 链表元素结构
struc ListElem
    .Prev:  resd 1  ; 上一个元素的指针
    .Next:  resd 1  ; 下一个元素的指针
endstruc

;-------------------------------------------------------------------------------
; 宏原型: void list_clear(pointer_t list)
;-------------------------------------------------------------------------------
extern_lib list_clear

%macro list_clear 1
    ; 4 字节大小的 list 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib list_clear
    add esp, dword 4
%endmacro

%define list_clear(list) list_clear list

;-------------------------------------------------------------------------------
; 宏原型: void list_append(pointer_t list, pointer_t elem)
;-------------------------------------------------------------------------------
extern_lib list_append

%macro list_append 2
    ; 4 字节大小的 elem 参数入栈
    push_32 %2

    ; 4 字节大小的 list 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib list_append
    add esp, dword 4 + 4
%endmacro

%define list_append(list, elem) list_append list, elem

;-------------------------------------------------------------------------------
; 宏原型: void list_push(pointer_t list, pointer_t elem)
;-------------------------------------------------------------------------------
extern_lib list_push

%macro list_push 2
    ; 4 字节大小的 elem 参数入栈
    push_32 %2

    ; 4 字节大小的 list 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib list_push
    add esp, dword 4 + 4
%endmacro

%define list_push(list, elem) list_push list, elem

;-------------------------------------------------------------------------------
; 宏原型: void list_print(pointer_t list)
;-------------------------------------------------------------------------------
extern_lib list_print

%macro list_print 1
    ; 4 字节大小的 list 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib list_print
    add esp, dword 4
%endmacro

%define list_print(list) list_print list

;-------------------------------------------------------------------------------
; 宏原型: void list_remove(pointer_t elem)
;-------------------------------------------------------------------------------
extern_lib list_remove

%macro list_remove 1
    ; 4 字节大小的 elem 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib list_remove
    add esp, dword 4
%endmacro

%define list_remove(elem) list_remove elem

;-------------------------------------------------------------------------------
; 宏原型: pointer_t list_pop(pointer_t list)
;-------------------------------------------------------------------------------
extern_lib list_pop

%macro list_pop 1
    ; 4 字节大小的 list 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib list_pop
    add esp, dword 4
%endmacro

%define list_pop(list) list_pop list

%endif