%ifndef SYNC_INC
%define SYNC_INC

%include "include/list.inc"

; 互斥锁结构
struc MutexLock
    .Holder:        resd 1  ; 锁的持有者
    .Sema:          resd 1  ; 锁的信号量
    .WaiterList:    resd 2  ; 锁的等待队列
endstruc

;-------------------------------------------------------------------------------
; 宏原型: void lock_init(pointer_t plock)
;-------------------------------------------------------------------------------
extern_lib lock_init

%macro lock_init 1
    ; 4 字节大小的 plock 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib lock_init
    add esp, dword 4
%endmacro

%define lock_init(plock) lock_init plock

;-------------------------------------------------------------------------------
; 宏原型: void lock_acquire(pointer_t plock)
;-------------------------------------------------------------------------------
extern_lib lock_acquire

%macro lock_acquire 1
    ; 4 字节大小的 plock 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib lock_acquire
    add esp, dword 4
%endmacro

%define lock_acquire(plock) lock_acquire plock

;-------------------------------------------------------------------------------
; 宏原型: void lock_release(pointer_t plock)
;-------------------------------------------------------------------------------
extern_lib lock_release

%macro lock_release 1
    ; 4 字节大小的 plock 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib lock_release
    add esp, dword 4
%endmacro

%define lock_release(plock) lock_release plock

%endif