%ifndef PRIMARY_INC
%define PRIMARY_INC

; 硬盘控制器主要数据寄存器, 负责管理数据, 是一个16位寄存器（其余寄存器为8位）
PRIMARY_SECTOR_DATA equ 0x1F0

; 存储尚未读取的扇区数的寄存器
PRIMARY_SECTOR_COUNT equ 0x1F2

; 存储LBA28中的7~0位的寄存器
PRIMARY_LBA_LOW equ 0x1F3

; 存储LBA28中的15~8位的寄存器
PRIMARY_LBA_MID equ 0x1F4

; 存储LBA28中的23~16位的寄存器
PRIMARY_LBA_HIGH equ 0x1F5

; LBA模式选择和盘符设置的寄存器
; 低4位存储LBA28中的27~24位
; 高4位: 7 - 固定为1；6 - 1代表LBA模式, 0代表CHS模式；5 - 固定为1；4 - 1代表从盘, 0代表主盘
PRIMARY_DEVICE equ 0x1F6

; 写操作时用于存储要执行的硬盘命令的寄存器
; 常见命令: 0xEC（硬盘识别）、0x20（读扇区）、0x30（写扇区）
PRIMARY_COMMAND equ 0x1F7

; 读操作时用于提供硬盘状态信息的寄存器
; 第0位是ERR位, 如果为1表示命令出错
; 第3位是DATA_REQUEST位, 如果为1表示硬盘已准备好数据可供主机读取
; 第6位是DRDY位, 如果为1表示硬盘就绪可继续执行命令
; 第7位是BSY位, 如果为1表示硬盘繁忙, 此寄存器的其他位无效
PRIMARY_STATUS equ 0x1F7

%endif