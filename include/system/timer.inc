%ifndef TIMER_INC
%define TIMER_INC

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

; 8259A 主从片的相关端口
PIC_M_CTRL equ 0x20
PIC_M_DATA equ 0x21
PIC_S_CTRL equ 0xA0
PIC_S_DATA equ 0xA1

%endif