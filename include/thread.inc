%ifndef TASK_INC
%define TASK_INC

%include "include/builtin.inc"
%include "include/system/page.inc"

; 线程运行的状态
TASK_RUNNING    equ 0
TASK_READY      equ 1
TASK_BLOCKED    equ 2
TASK_WAITING    equ 3
TASK_HANGING    equ 4
TASK_DIED       equ 5

; 线程控制结构
struc ThreadControl
    .StackTop:      resd 1      ; 线程栈的栈顶
    .Status:        resd 1      ; 线程当前的运行状态
    .Priority:      resd 1      ; 线程优先级, 即线程单次允许执行的时钟周期
    .Name:          resd 4      ; 线程名称字符数组

    .Ticks:         resd 1      ; 线程剩余的可执行周期
    .TotalTicks:    resd 1      ; 线程执行的总时钟周期

    .PageDir        resd 1      ; 进程页表的虚拟地址
    .SignElem:      resd 2      ; 线程列表标识元素

    .MagicNum:      resd 1      ; 边界魔数, 用于防止栈溢出
endstruc

extern get_running_thread

extern thread_schedule

;-------------------------------------------------------------------------------
; 宏原型: void thread_ctrl_init(pointer_t ctrl, pointer_t name, uint32_t ticks)
;-------------------------------------------------------------------------------
extern_lib thread_ctrl_init

%macro thread_ctrl_init 3
    ; 4 字节大小的 ticks 参数入栈
    push_32 %3

    ; 4 字节大小的 name 参数入栈
    push_32 %2

    ; 4 字节大小的 ctrl 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib thread_ctrl_init
    add esp, dword 4 + 4 + 4
%endmacro

%define thread_ctrl_init(ctrl, name, ticks) thread_ctrl_init ctrl, name, ticks

;-------------------------------------------------------------------------------
; 宏原型: pointer_t thread_start(pointer_t function, pointer_t name, pointer_t priority, pointer_t func_arg)
;-------------------------------------------------------------------------------
extern_lib thread_start

%macro thread_start 4
    ; 4 字节大小的 func_arg 参数入栈
    push_32 %4

    ; 4 字节大小的 priority 参数入栈
    push_32 %3

    ; 4 字节大小的 name 参数入栈
    push_32 %2

    ; 4 字节大小的 function 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib thread_start
    add esp, dword 4 + 4 + 4 + 4
%endmacro

%define thread_start(function, name, priority, func_arg) thread_start function, name, priority, func_arg

%endif