%include "include/stdio.inc"
%include "include/thread.inc"
%include "include/system/timer.inc"

[bits 32]
;-------------------------------------------------------------------------------
; 函数名: timer_intr_entry
; 描述: 0x20 时钟中断发生时的入口函数
; 备注: 该中断发生时不会压入错误码
;-------------------------------------------------------------------------------
timer_intr_entry:
    push ds
    push es
    push fs
    push gs
    push ss
    pushad

    ; 向主从片发送EOI
    mov al,0x20
    out 0xa0,al
    out 0x20,al

    ; 获取当前运行线程的控制模块
    call get_running_thread
    mov ebx, eax

    ; 判断是否到达该线程单次执行时间
    cmp [ebx + ThreadControl.Ticks], dword 0
    jg time_intr_exit

    ; 调度该线程
    mov [ebx + ThreadControl.StackTop], esp
    call thread_schedule

time_intr_exit:
    inc dword [ebx + ThreadControl.TotalTicks]
    dec dword [ebx + ThreadControl.Ticks]

    popad
    pop ss
    pop gs
    pop fs
    pop es
    pop ds
    iret

;-------------------------------------------------------------------------------
; 函数名: timer_init
; 描述: 初始化时钟中断
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
extern intr_entry_table

func timer_init
    ; 往控制字寄存器端口0x43中写入控制字
    mov al, (COUNTER0_NO << 6 | READ_WRITE_LATCH << 4 | COUNTER_MODE << 1)
    out PIT_CONTROL_PORT, al

    ; 先写入COUNTER0_VALUE的低8位
    mov eax, COUNTER0_VALUE
    out CONTRER0_PORT, al

    ; 再写入counter_value的高8位
    shr eax, 8
    out CONTRER0_PORT, al

    ; 将 timer_intr_entry 注册到 intr_entry_table 中
    mov [intr_entry_table + 0x20 * 4], dword timer_intr_entry
func_end
