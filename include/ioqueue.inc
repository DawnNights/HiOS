%ifndef IOQUEUE_INC
%define IOQUEUE_INC

%include "include/builtin.inc"

; 缓冲区大小
BUFSIZE equ 64

; 环形队列结构
struc IOQueue
    .Head:      resd 1        ; 队列首
    .Tail:      resd 1        ; 队列尾
    .Lock:      resd 4        ; 互斥锁
    .Producer:  resd 1        ; 生产者
    .Consumer:  resd 1        ; 消费者
    .Buffer:    resb BUFSIZE  ; 缓冲区
endstruc

;-------------------------------------------------------------------------------
; 宏原型: void ioq_init(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_init

%macro ioq_init 1
    ; 4 字节大小的 ioq 参数入栈
    push_32 %1
    
    ; 调用函数并恢复栈顶
    call_lib ioq_init
    add esp, dword 4
%endmacro

%define ioq_init(ioq) ioq_init ioq

;-------------------------------------------------------------------------------
; 宏原型: uint32_t ioq_next_pos(uint32_t pos)
;-------------------------------------------------------------------------------
extern_lib ioq_next_pos

%macro ioq_next_pos 1
    ; 4 字节大小的 pos 参数入栈
    push_32 %1
    
    ; 调用函数并恢复栈顶
    call_lib ioq_next_pos
    add esp, dword 4
%endmacro

%define ioq_next_pos(pos) ioq_next_pos pos

;-------------------------------------------------------------------------------
; 宏原型: bool_t ioq_full(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_full

%macro ioq_full 1
    ; 4 字节大小的 ioq 参数入栈
    push_32 %1
    
    ; 调用函数并恢复栈顶
    call_lib ioq_full
    add esp, dword 4
%endmacro

%define ioq_full(ioq) ioq_full ioq

;-------------------------------------------------------------------------------
; 宏原型: bool_t ioq_empty(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_empty

%macro ioq_empty 1
    ; 4 字节大小的 ioq 参数入栈
    push_32 %1
    
    ; 调用函数并恢复栈顶
    call_lib ioq_empty
    add esp, dword 4
%endmacro

%define ioq_empty(ioq) ioq_empty ioq

;-------------------------------------------------------------------------------
; 宏原型: void ioq_wait(pointer_t waiter)
;-------------------------------------------------------------------------------
extern_lib ioq_wait

%macro ioq_wait 1
    ; 4 字节大小的 waiter 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib ioq_wait
    add esp, dword 4
%endmacro

%define ioq_wait(waiter) ioq_wait waiter

;-------------------------------------------------------------------------------
; 宏原型: void ioq_wakeup(pointer_t waiter)
;-------------------------------------------------------------------------------
extern_lib ioq_wakeup

%macro ioq_wakeup 1
    ; 4 字节大小的 waiter 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib ioq_wakeup
    add esp, dword 4
%endmacro

%define ioq_wakeup(waiter) ioq_wakeup waiter

;-------------------------------------------------------------------------------
; 宏原型: char_t ioq_getchar(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_getchar

%macro ioq_getchar 1
    ; 4 字节大小的 ioq 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib ioq_getchar
    add esp, dword 4
%endmacro

%define ioq_getchar(ioq) ioq_getchar ioq

;-------------------------------------------------------------------------------
; 宏原型: void ioq_putchar(pointer_t ioq, char_t char)
;-------------------------------------------------------------------------------
extern_lib ioq_putchar

%macro ioq_putchar 2
    ; 1 字节大小的 char 参数入栈
    push_8 %2

    ; 4 字节大小的 ioq 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib ioq_putchar
    add esp, dword 4 + 1
%endmacro

%define ioq_putchar(ioq, char) ioq_putchar ioq, char

%endif
