%include "include/stdio.inc"
%include "include/thread.inc"

; 定义我们想要的中断发生频率, 100HZ
IRQ0_FREQUENCY equ 100

; 计数器0的工作脉冲信号评率
INPUT_FREQUENCY equ 1193180

; 要写入初值的计数器数值
COUNTER0_VALUE equ (INPUT_FREQUENCY / IRQ0_FREQUENCY)

; 要写入初值的计数器端口号
CONTRER0_PORT equ 0x40

; 要操作的计数器的号码
COUNTER0_NO equ 0

; 用在控制字中设定工作模式的号码, 这里表示比率发生器
COUNTER_MODE equ 2

; 用在控制字中设定读/写/锁存操作位, 这里表示先写入低字节, 然后写入高字节
READ_WRITE_LATCH equ 3   

; 控制字寄存器的端口
PIT_CONTROL_PORT equ 0x43

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
    
    ; lea esi, [ebx + ThreadControl.Name]
    ; printf("Thread %s Ticks is %d\n", esi, [ebx + ThreadControl.Ticks])

    popad
    pop ss
    pop gs
    pop fs
    pop es
    pop ds
    iret

;-------------------------------------------------------------------------------
; 函数名: timer_init
; 描述: 初始化可编程中断控制器
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