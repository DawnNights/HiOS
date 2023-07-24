%ifndef PAGE_INC
%define PAGE_INC

; 一页的大小
PAGE_SIZE equ 0x1000

; 在二级页表中, 页目录表的物理地址
; 数量为1M的页表项被分割成了数量为1K个页目录项, 每个页目录项指向一个包含数量为1K个页表项的页表
PAGE_DIR_PHYS_ADDR equ 0x100000

; 在二级页表中, 第一个页表的物理地址
; 因为每个页目录项占4字节, 共计1K个页目录项, 所以页表的地址就在页目录表的4K字节后
PAGE_TABLE_PHYS_ADDR equ PAGE_DIR_PHYS_ADDR + PAGE_SIZE

; 页目录项/页表项中的P位表示存在位
; 若为1, 则表示该页存在于物理内存中, 反之则不存在于物理内存中
; 操作系统的页式虚拟内存管理通过P位和页面错误异常来实现
PAGE_P equ 1b

; 页目录项/页表项中的RW位表示读写位
; 若为1, 则表示可读可写, 反之表示该页仅可读
PAGE_RW_READ_ONLY  equ 00b
PAGE_RW_READ_WRITE equ 10b

; 页目录项/页表项中的US位表示普通用户/超级用户位
; 若为1, 则表示处于用户级别, 任意特权级别（包括3）的程序都可以访问该页
; 若为0, 则表示处于超级用户级别, 仅允许特权级别为0、1、2的程序访问
PAGE_US_SUPERVISOR equ 000b
PAGE_US_USER       equ 100b

%endif