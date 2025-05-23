%ifndef IDT_INC
%define IDT_INC

;-------------------------------------------------------------------------------
; 描述: 定义了与IDT（中断描述符表）相关的常量和注释, 包括中断门描述符结构以及相关属性和标志 
;-------------------------------------------------------------------------------

; IDT指针结构, 指向IDT表的限制和起始地址
struc IdtPointer
    Limit:    resw 1   ; IDT界限
    BaseAddr: resd 1   ; IDT起始地址
endstruc

; 中断门描述符
struc InterruptGate
    ; 低32位
    FuncLow:    resw 1   ; 中断处理程序目标代码段内偏移量的低16位
    Selector:   resw 1   ; 中断处理程序目标代码段描述符的选择子
    
    ; 高32位
    ArgCount:      resb 1   ; 参数个数与3位的固定零值
    AttrType:     resb 1   ; 属性和类型（P | DPL | S | TYPE）
    FuncHigh:  resw 1   ; 中断处理程序目标代码段内偏移量的高16位
endstruc

; AttrType中的P位用于判断段是否存在
; P位为1表示段存在于内存中, 如果为0, CPU将抛出异常
DESC_P equ 1_0000000b

; AttrType中的DPL字段用于表示内存段的特权级
; 特权级分为0、1、2、3四种, 数字越小特权级越高, 一般内核态为0级, 用户态为3级
DESC_DPL_0 equ 0_00_00000b
DESC_DPL_3 equ 0_11_00000b

; AttrType中的S位用于判断当前描述符是否是系统段
; S位为0表示是系统段, 反之表示为非系统段（按代码段和数据段划分）
DESC_S_SYS  equ 000_0_0000b

; AttrType中的TYPE字段用于表示内存段或门的子类型
; 在表示非系统段的代码段中, 这4位的含义分别是: X（是否可执行）、C（是否一致性）、R（是否可读）、A（是否访问）
; 在表示非系统段的数据段中, 这4位的含义分别是: X（是否可执行）、E（段扩展方向）、W（是否可写）、A（是否访问）
; A位是由CPU设置的, 当新段描述符被创建时此位为0, 当CPU访问后则设置为1, 通过此位可判断描述符是否可用
; C位为0时表示非一致性代码段, 绝对禁止不同级程序访问, 即使是内核态也不能访问用户态, 用户态亦不能访问内核态
; C位为1时表示一致性代码段, 特权级高的程序不允许访问特权级低的数据, 反之可以访问, 但特权级不随访问发生变化
; E位表示标识段的扩展方向, E位为0表示向上扩展即地址越来越高, 通常用于代码段和数据段, 反之向下扩展用于栈段
DESC_TYPE_32 equ 0000_1110b

;-------------------------------------------------------------------------------
; 描述: 定义了与选择子相关的常量和注释, 包括请求特权级（RPL）和表指示符（TI）的取值 
;-------------------------------------------------------------------------------

; 选择子共16位, 其低2位即1~0位用于存储请求特权级（RPL）
RPL_0 equ 00b
RPL_1 equ 01b
RPL_2 equ 10b
RPL_3 equ 11b

; 选择子的第2位是表指示符（TI）位
; TI位为0表示在GDT（全局描述符表）中索引描述符, 反之在LDT（局部描述符表）中索引
TI_GDT equ 00b
TI_LDT equ 10b

; 段描述符的选择子
SELECTOR_K_CODE equ (0x01 << 3) | TI_GDT | RPL_0
SELECTOR_K_DATA equ (0x02 << 3) | TI_GDT | RPL_0
SELECTOR_STACK equ SELECTOR_K_DATA
SELECTOR_K_VIDEO equ (0x03 << 3) | TI_GDT | RPL_0

%endif