%include "include/builtin.inc"
%include "include/system/tss.inc"

; 预留描述符的起始位置
null_desc equ 0x502

tss_desc equ null_desc + 4 * 8

code_dpl3_desc equ tss_desc + 8

data_dpl3_desc equ code_dpl3_desc + 8


section .data
    tss:istruc TaskStateSegment
        at TaskStateSegment.BackLink, dd 0
        at TaskStateSegment.Esp0,     dd 0
        at TaskStateSegment.Ss0,      dd 0
        at TaskStateSegment.Esp1,     dd 0
        at TaskStateSegment.Ss1,      dd 0
        at TaskStateSegment.Esp2,     dd 0
        at TaskStateSegment.Ss2,      dd 0
        at TaskStateSegment.Cr3,      dd 0
        at TaskStateSegment.Eip,      dd 0
        at TaskStateSegment.Eflags,   dd 0
        at TaskStateSegment.Eax,      dd 0
        at TaskStateSegment.Ecx,      dd 0
        at TaskStateSegment.Edx,      dd 0
        at TaskStateSegment.Ebx,      dd 0
        at TaskStateSegment.Esp,      dd 0
        at TaskStateSegment.Ebp,      dd 0
        at TaskStateSegment.Esi,      dd 0
        at TaskStateSegment.Edi,      dd 0
        at TaskStateSegment.Es,       dd 0
        at TaskStateSegment.Cs,       dd 0
        at TaskStateSegment.Ss,       dd 0
        at TaskStateSegment.Ds,       dd 0
        at TaskStateSegment.Fs,       dd 0
        at TaskStateSegment.Gs,       dd 0
        at TaskStateSegment.Ldt,      dd 0
        at TaskStateSegment.Trace,    dd 0
        at TaskStateSegment.IoBase,   dd 0
    iend

    gdt_ptr: istruc GdtPointer
        at Limit,    dw 0
        at BaseAddr, dd null_desc
    iend

%macro write_gdt_desc 5
    mov eax, %3
    and eax, 0x0000ffff
    mov [%1+LimitLow], ax

    mov eax, %2
    and eax, 0x0000ffff
    mov [%1+BaseAddrLow], ax

    mov eax, %2
    and eax, 0x00ff0000
    shr eax, 16
    mov [%1+BaseAddrMid], al

    mov [%1+AttrType], byte %4

    mov [%1+AttrLimit], byte %5

    mov eax, %2
    shr eax, 24
    mov [%1+BaseAddrHigh], byte al
%endmacro

%define write_gdt_desc(desc_addr, desc_base, limit, attr_low, attr_high) write_gdt_desc desc_addr, desc_base, limit, attr_low, attr_high

;-------------------------------------------------------------------------------
; 函数名: tss_init
; 描述: 在gdt中创建tss并重载gdt
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func tss_init
    mov [tss+TaskStateSegment.Ss0], dword SELECTOR_K_DATA
    mov [tss+TaskStateSegment.IoBase], dword TSS_SIZE

    ; 在gdt中添加DPL为0的TSS描述符
    write_gdt_desc(tss_desc, tss, TSS_SIZE-1, TSS_ATTR_LOW, TSS_ATTR_HIGH)

    ; 在gdt中添加DPL为3的代码段和数据段描述符
    write_gdt_desc(code_dpl3_desc, 0, 0xfffff, GDT_CODE_ATTR_LOW_DPL3, GDT_ATTR_HIGH)
    write_gdt_desc(data_dpl3_desc, 0, 0xfffff, GDT_DATA_ATTR_LOW_DPL3, GDT_ATTR_HIGH)

    ; 7个8字节描述符大小
    mov [gdt_ptr + Limit], word 8 * 7 - 1
    lgdt [gdt_ptr]

    ; 加载tss到TR寄存器
    mov eax, SELECTOR_TSS
    ltr ax
func_end
