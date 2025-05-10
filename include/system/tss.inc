%ifndef TSS_INC
%define TSS_INC

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

; TSS任务状态段结构
struc TaskStateSegment
    .BackLink: resd 1
    .Esp0:     resd 1
    .Ss0:      resd 1
    .Esp1:     resd 1
    .Ss1:      resd 1
    .Esp2:     resd 1
    .Ss2:      resd 1
    .Cr3:      resd 1
    .Eip:      resd 1
    .Eflags:   resd 1
    .Eax:      resd 1
    .Ecx:      resd 1
    .Edx:      resd 1
    .Ebx:      resd 1
    .Esp:      resd 1
    .Ebp:      resd 1
    .Esi:      resd 1
    .Edi:      resd 1
    .Es:       resd 1
    .Cs:       resd 1
    .Ss:       resd 1
    .Ds:       resd 1
    .Fs:       resd 1
    .Gs:       resd 1
    .Ldt:      resd 1
    .Trace:    resd 1
    .IoBase:   resd 1
endstruc

; TSS结构体内存大小
TSS_SIZE equ 27 * 4

; GDT 常量定义
DESC_G_4K equ 1
DESC_D_32 equ 1
DESC_L    equ 0
DESC_AVL  equ 0
DESC_P    equ 1
DESC_DPL_0 equ 0
DESC_DPL_1 equ 1
DESC_DPL_2 equ 2
DESC_DPL_3 equ 3

TI_GDT equ 0
RPL_0 equ 0
RPL_1 equ 1
RPL_2 equ 2
RPL_3 equ 3

DESC_S_CODE equ 1
DESC_S_DATA equ 1
DESC_S_SYS  equ 0
DESC_TYPE_CODE  equ 8
DESC_TYPE_DATA  equ 2

; 段描述符的选择子
SELECTOR_K_DATA equ (0x02 << 3) | TI_GDT | RPL_0
SELECTOR_TSS    equ (0x04 << 3) | TI_GDT | RPL_0
SELECTOR_U_CODE equ (0x05 << 3) | TI_GDT | RPL_0
SELECTOR_U_DATA equ (0x06 << 3) | TI_GDT | RPL_0


; 32位可用TSS（Type=1001b）
; 32位繁忙TSS（Type=1011b）
DESC_TYPE_TSS equ 0000_1001b

; TSS描述符的D位（B位）
; - 在TSS描述符中，D/B位称为B位。当B=0时表示任务非繁忙状态（未在运行），
;   B=1时表示任务繁忙（正在执行或嵌套）。初始化时应设为0。
TSS_DESC_D equ 0

;   - DESC_P << 7      : P=1，段存在
;   - DESC_DPL_0 << 5  : DPL=0，仅内核态可访问
;   - DESC_S_SYS << 4  : S=0，系统段（TSS属于系统段）
;   - DESC_TYPE_TSS     : Type=0x9 (32位可用TSS)
TSS_ATTR_LOW equ (DESC_P << 7) | (DESC_DPL_0 << 5) | (DESC_S_SYS << 4) | DESC_TYPE_TSS

;   - DESC_G_4K << 7   : G=1，段界限单位为4KB
;   - TSS_DESC_D << 6  : B=0，任务初始非繁忙状态
;   - DESC_L << 5      : L=0，非64位模式
;   - DESC_S_SYS << 4  : 保留位（实际无意义，但需与描述符格式对齐）
TSS_ATTR_HIGH equ (DESC_G_4K << 7) | (TSS_DESC_D << 6) | (DESC_L << 5) | (DESC_S_SYS << 4)

; 高字节属性（AttrHigh）组合公式
GDT_ATTR_HIGH equ (DESC_G_4K << 7) | (DESC_D_32 << 6) | (DESC_L << 5) | (DESC_AVL << 4)

; 用户态（DPL=3）代码段低字节属性
GDT_CODE_ATTR_LOW_DPL3 equ (DESC_P << 7) | (DESC_DPL_3 << 5) | (DESC_S_CODE << 4) | DESC_TYPE_CODE

; 用户态（DPL=3）数据段低字节属性
GDT_DATA_ATTR_LOW_DPL3 equ (DESC_P << 7) | (DESC_DPL_3 << 5) | (DESC_S_CODE << 4) | DESC_TYPE_DATA

%endif
