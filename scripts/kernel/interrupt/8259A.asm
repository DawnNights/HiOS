%include "include/builtin.inc"

PIC_M_CTRL equ 0x20
PIC_M_DATA equ 0x21
PIC_S_CTRL equ 0xA0
PIC_S_DATA equ 0xA1

;-------------------------------------------------------------------------------
; 函数名: pic_init
; 描述: 初始化可编程中断控制器
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func pic_init
    ; 初始化主片8259A
    mov al, 0x11      ; 初始化命令字1
    out PIC_M_CTRL, al     ; 发送命令字1到主片的命令端口

    mov al, 0x20      ; 设置主片的中断向量偏移量为0x20
    out PIC_M_DATA, al     ; 发送中断向量偏移量到主片的数据端口

    mov al, 0x04      ; 设置主片的IR2引脚连接从片
    out PIC_M_DATA, al     ; 发送IR2配置到主片的数据端口

    mov al, 0x01      ; 设置主片工作在8086兼容模式
    out PIC_M_DATA, al     ; 发送模式配置到主片的数据端口

    ; 初始化从片8259A
    mov al, 0x11      ; 初始化命令字1
    out PIC_S_CTRL, al     ; 发送命令字1到从片的命令端口

    mov al, 0x28      ; 设置从片的中断向量偏移量为0x28
    out PIC_S_DATA, al     ; 发送中断向量偏移量到从片的数据端口

    mov al, 0x02      ; 设置从片的IR2引脚连接主片
    out PIC_S_DATA, al     ; 发送IR2配置到从片的数据端口

    mov al, 0x01      ; 设置从片工作在8086兼容模式
    out PIC_S_DATA, al     ; 发送模式配置到从片的数据端口

    ; 打开主片上IR0, 也就是目前只接受时钟产生的中断
    mov al, 0xfe
    out PIC_M_DATA, al

    mov al, 0xff
    out PIC_S_DATA, al
func_end