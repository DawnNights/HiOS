%ifndef GDT_INC
%define GDT_INC

; GDT指针结构, 指向GDT表的限制和起始地址
struc GdtPointer
    Limit:    resw 1   ; GDT界限
    BaseAddr: resd 1   ; GDT起始地址
endstruc

; 段描述符结构
struc SegDescriptor
    ; 低32位
    LimitLow:      resw 1   ; 段界限 15 ~ 0
    BaseAddrLow:   resw 1   ; 段基址 15 ~ 0
    
    ; 高32位
    BaseAddrMid:   resb 1   ; 段基址 23 ~ 16
    AttrType:      resb 1   ; 属性和类型（P | DPL | S | TYPE）
    AttrLimit:     resb 1   ; 属性和界限（G | D/B | L | AVL | 段界限 19 ~ 16）
    BaseAddrHigh:  resb 1   ; 段基址 31 ~ 24
endstruc

; AttrType中的P位用于判断段是否存在
; P位为1表示段存在于内存中, 如果为0, CPU将抛出异常
DESC_P equ 1_0000000b

; AttrType中的DPL字段用于表示内存段的特权级
; 特权级分为0、1、2、3四种, 数字越小特权级越高, 一般内核态为0级, 用户态为3级
DESC_DPL_0 equ 0_00_00000b
DESC_DPL_1 equ 0_01_00000b
DESC_DPL_2 equ 0_10_00000b
DESC_DPL_3 equ 0_11_00000b

; AttrType中的S位用于判断当前描述符是否是系统段
; S位为0表示是系统段, 反之表示为非系统段（按代码段和数据段划分）
DESC_S_SYS  equ 000_0_0000b
DESC_S_CODE equ 000_1_0000b
DESC_S_DATA equ DESC_S_CODE

; AttrType中的TYPE字段用于表示内存段或门的子类型
; 在表示非系统段的代码段中, 这4位的含义分别是: X（是否可执行）、C（是否一致性）、R（是否可读）、A（是否访问）
; 在表示非系统段的数据段中, 这4位的含义分别是: X（是否可执行）、E（段扩展方向）、W（是否可写）、A（是否访问）
; A位是由CPU设置的, 当新段描述符被创建时此位为0, 当CPU访问后则设置为1, 通过此位可判断描述符是否可用
; C位为0时表示非一致性代码段, 绝对禁止不同级程序访问, 即使是内核态也不能访问用户态, 用户态亦不能访问内核态
; C位为1时表示一致性代码段, 特权级高的程序不允许访问特权级低的数据, 反之可以访问, 但特权级不随访问发生变化
; E位表示标识段的扩展方向, E位为0表示向上扩展即地址越来越高, 通常用于代码段和数据段, 反之向下扩展用于栈段
DESC_TYPE_CODE equ 0000_1000b ; 可执行、非一致性、不可读、访问位清零的代码段
DESC_TYPE_DATA equ 0000_0010b ; 不可执行、向上扩展、可写、访问位清零的数据段


; AttrLimit中的G位用于指定段界限的单位量
; 若G位为0, 则单位量为1B, 否则单位量为4KB
; 故段界限的范围要么为2^20即1MB大小, 要么因为4KB == 2^12所以为2^(20+12)即4GB大小
DESC_G_4K equ 1_0000000b

; AttrLimit中的D/B位用于指示有效地址（段内偏移地址）及操作数的大小
; 对于代码段来说此位是D位, 若为0则表示指令中的有效地址和操作数是16位用IP寄存器, 反之是32位且用EIP寄存器
; 对于栈段来说此位是B位, 若为0则表示使用SP寄存器也就是栈的起始地址是16位寄存器的最大寻址范围0xFFFF, 反之是32位且用ESP寄存器
DESC_D_32 equ 0_1_000000b

; AttrLimit中的L位用于标记是否为64位代码段
; 我们目前在32位CPU下编程, 所以暂置为0即可
DESC_L equ 00_0_00000b

; AttrLimit中的AVL位没有专门的定义用途
DESC_AVL equ 000_0_0000b

; AttrLimit中最后4位是段界限的高4位
; 与段描述符低32位中的段界限的低16位共同组成完整的20位段界限
DESC_LIMIT_CODE2  equ 0000_1111b
DESC_LIMIT_DATA2  equ DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2 equ 0000_0000b

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
SELECTOR_K_VIDEO equ (0x03 << 3) | TI_GDT | RPL_0

%endif
