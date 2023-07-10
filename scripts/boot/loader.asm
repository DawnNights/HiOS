%include "include/system/gdt.inc"
%include "include/system/page.inc"
%include "include/system/primary.inc"

section .text vstart=0x500
    jmp detect_by_e801

    ; 物理内存容量
    total_mem_bytes dd 0

    ; GDT 中不可用的第 0 个描述符
    null_desc: istruc SegDescriptor
        at LimitLow,      dw 0
        at BaseAddrLow,   dw 0

        at BaseAddrMid,   db 0
        at AttrType,      db 0
        at AttrLimit,     db 0
        at BaseAddrHigh,  db 0
    iend

    ; 代码段描述符
    code_desc: istruc SegDescriptor
        at LimitLow,      dw 0xffff
        at BaseAddrLow,   dw 0x0000

        at BaseAddrMid,   db 0x00
        at AttrType,      db DESC_P | DESC_DPL_0 | DESC_S_CODE | DESC_TYPE_CODE
        at AttrLimit,     db DESC_G_4K | DESC_D_32 | DESC_L | DESC_AVL | DESC_LIMIT_CODE2
        at BaseAddrHigh,  db 0x00
    iend

    ; 数据段描述符
    data_desc: istruc SegDescriptor
        at LimitLow,      dw 0xffff
        at BaseAddrLow,   dw 0x0000

        at BaseAddrMid,   db 0x00
        at AttrType,      db DESC_P | DESC_DPL_0 | DESC_S_DATA | DESC_TYPE_DATA
        at AttrLimit,     db DESC_G_4K | DESC_D_32 | DESC_L | DESC_AVL | DESC_LIMIT_DATA2
        at BaseAddrHigh,  db 0x00
    iend

    ; 显存段描述符
    VIDEO_BASE equ 0xb8000
    video_desc: istruc SegDescriptor
        at LimitLow,      dw 0x0007   ; (7 + 1) * 4KB = 32 KB
        at BaseAddrLow,   dw VIDEO_BASE & 0000_1111111111111111b

        at BaseAddrMid,   db VIDEO_BASE >> 16
        at AttrType,      db DESC_P | DESC_DPL_0 | DESC_S_DATA | DESC_TYPE_DATA
        at AttrLimit,     db DESC_G_4K | DESC_D_32 | DESC_L | DESC_AVL | DESC_LIMIT_VIDEO2
        at BaseAddrHigh,  db 0x00   ; VIDEO_BASE >> 24
    iend

    ; 赋值给 GDTR 使其得知 GDT 所在位置与界限
    GDT_LIMIT equ ($ - null_desc) - 1

    gdt_ptr: istruc GdtPointer
        at Limit,    dw GDT_LIMIT
        at BaseAddr, dd null_desc
    iend

; 通过 0x15 中断子功能 0xE801 获取内存, 上限为4GB
; 获取物理内存成功则跳转进入保护模式
detect_by_e801:
    mov ax, 0xE801
    int 0x15
    jc detect_failed

    ; (ax + bx * 64 + 1024) * 1024
    shl ebx, 6  ; 乘以 64
    add ebx, eax
    add ebx, 1024
    shl ebx, 10 ; 乘以 1024

    mov [total_mem_bytes], ebx
    jmp enter_protected_mode

detect_failed:
    jmp $

; 从16位实模式切换到32位保护模式 
enter_protected_mode:
    ; 打开 A20 地址线
    in al, 0x92
    mov al, 00000010b
    out 0x92, al

    ; 加载 GDT
    lgdt [gdt_ptr]

    ; 将 CR0 的 PE 位设置为 1
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax
    
    ; 刷新流水线, 使其按照 32 位指令译码
    jmp dword SELECTOR_CODE:protected_mode_main

[bits 32]
protected_mode_main:
    mov ax, SELECTOR_VIDEO
    mov es, ax
    mov ax, SELECTOR_DATA
    mov ss, ax

    jmp open_page_mode

; 设置页表并初始化内存位图
setup_page:
    mov ax, SELECTOR_DATA
    mov ds, ax

    ; 清空页目录占用的空间
    mov ecx, 4096
    mov esi, 0
    clear_page_dir:
        mov byte [PAGE_DIR_PHYS_ADDR + esi], 2

        add esi, 1
        loop clear_page_dir
    
    ; 开始创建页目录项(Page Directory Entry)
    ; PS: 页表是一种动态的数据结构, 可以灵活的分配或清零
    PAGE_ADDR equ PAGE_US_USER | PAGE_RW_READ_WRITE | PAGE_P

    create_pde:
        ; 使第一个目录项指向页表的起始地址
        ; 为了实现操作系统的共享, 所以将虚拟内存中的 3~4 GB分配给操作系统
        mov eax, PAGE_TABLE_PHYS_ADDR | PAGE_ADDR
        mov [PAGE_DIR_PHYS_ADDR + 0], eax
        mov [PAGE_DIR_PHYS_ADDR + (1024 - 256) * 4], eax
        
        ; 使最后一个目录项指向页目录表的起始地址
        mov eax, PAGE_DIR_PHYS_ADDR | PAGE_ADDR
        mov [PAGE_DIR_PHYS_ADDR + (1024 - 1) * 4], eax


    ; 开始创建页表项(Page Table Entry)
    mov ebx, PAGE_TABLE_PHYS_ADDR
    mov ecx, 256    ; 1MB 低端内存可以拆分成 256 个 4KB 大小的物理内存页
    mov esi, 0
    mov edx, PAGE_ADDR

    create_pte:
        ; 将第一个页表的前256个页表项对应到 1MB 低端内存拆分的物理页
        mov [ebx+esi*4], edx
        add edx, 4096

        add esi, 1
        loop create_pte

    ; 开始创建内核页表
    ; PS: 此时除了第一个页表外的页表都没有分配对应的物理页, 但为了所有用户进程共享内核空间需要提前占满
    mov eax, (PAGE_TABLE_PHYS_ADDR + 0x1000) | PAGE_ADDR ; 指向第二个页表
    mov ebx, PAGE_DIR_PHYS_ADDR
    mov ecx, 254
    mov esi, 769

    create_kernel_pde:
        mov [ebx+esi*4], eax
        add esi, 1  ; 指向下一个页目录项
        add eax, 0x1000 ; 指向下一个页表
        loop create_kernel_pde
    ret

; 开启分页模式
open_page_mode:
    call setup_page
    sgdt [gdt_ptr]

    ; 将显存段基址放到3~4GB的内核虚拟空间中, 防止被用户进程操作
    ; 此处操作相当于 video_desc.BaseAddr = video_desc.BaseAddr + 0xc0000000
    or dword [video_desc + 4], 0xc0000000

    ; 将 GDT 的显存段基址放到3~4GB的内核虚拟空间中
    ; 将栈指针同样放到3~4GB的内核虚拟空间中
    add dword [gdt_ptr + BaseAddr], 0xc0000000
    add esp, 0xc0000000

    ; 把页目录地址赋值给cr3寄存器
    mov eax, PAGE_DIR_PHYS_ADDR
    mov cr3, eax

    ; 打开 cr0 寄存器的 PG 位
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    lgdt [gdt_ptr]
    jmp enter_kernel

; 载入内核并跳转内核执行
enter_kernel:
    mov eax, 0x05   ; kernel所在的LBA扇区号

    mov dx, PRIMARY_LBA_LOW
    out dx, al
    
    mov dx, PRIMARY_LBA_MID
    shr eax, 8
    out dx, al

    mov dx, PRIMARY_LBA_HIGH
    shr eax, 8
    out dx, al

    mov dx, PRIMARY_DEVICE
    shr eax, 8
    and al, 00001111b   ; 27~24位写入 divice 寄存器第四位
    or al, 11100000b    ; 设置高4位为0代表主盘, LBA模式
    out dx, al

    ; 向命令端口写入读命令让硬盘执行
    mov dx, PRIMARY_COMMAND
    mov al, 0x20    ; read sector, 即读扇区
    out dx, al

    ; 检测硬盘状态
    mov dx, PRIMARY_STATUS
    .not_ready:
        nop ; 空操作, 消耗一条指令周期(即等待时间)

        in al, dx
        and al, 10001000b   ; 保留第 3 位和第 7 位
        cmp al, 00001000b   ; BSY 位为 0 且 data_request 位为 1 则准备完成
        jnz .not_ready      ; 若结果不等, 则跳转回去继续等待
    
    ; 从数据端口中读取数据
    mov ax, 200   ; kernel 所占的扇区数
    mov dx, 256 ; 一个扇区512字节, 一次一个字, 所以每个扇区读 512/2 次
    mul dx

    mov cx, ax
    mov dx, PRIMARY_SECTOR_DATA

    mov ebx, 0xd00   ; 0x500 + 512 * 4
    .go_on_read:
        in ax, dx
        mov [ebx], ax
        add ebx, 2
        loop .go_on_read
    jmp 0xd00   ; 跳转至 kernel 执行