%include "include/system/memory.inc"

[bits 32]
section .text
    global kernel_pool
    global user_pool
    global kernel_vaddr

section .data
    ; 内核内存池
    kernel_pool: istruc MemPool
        at MemPool.BitMap,      dq 0
        at MemPool.AddrStart,   dd 0
        at MemPool.PoolSize,    dd 0
    iend

    ; 用户内存池
    user_pool: istruc MemPool
        at MemPool.BitMap,      dq 0
        at MemPool.AddrStart,   dd 0
        at MemPool.PoolSize,    dd 0
    iend

    ; 内核虚拟地址
    kernel_vaddr: istruc VirtualAddr
        at VirtualAddr.BitMap,      dq 0
        at VirtualAddr.AddrStart,   dd 0
    iend

;-------------------------------------------------------------------------------
; 函数名: mem_pool_init
; 描述: 初始化内存池
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func mem_pool_init
    ; 物理内存容量(即 builds/bochsrc 中的 megs 参数)
    all_mem equ 0x2000000 ; 32MB

    ; 页表大小 = 1页的页目录表 + 第0和第768个页目录项指向同一个页表 + 第769~1022个页目录项共指向254个页表, 共256个页表
    page_table_size equ PAGE_SIZE * 256

    ; 已使用内存 = 1MB + 256个页表
    used_mem equ page_table_size + 0x100000

    ; 空闲内存 = 所有内存 - 已使用内存
    free_mem equ all_mem - used_mem

    ; 将空闲内存转换为页的数量, 内存分配以页为单位, 丢掉的内存不考虑
    all_free_pages equ free_mem / PAGE_SIZE

    ; 空闲内存是用户与内核各一半, 所以分到的页自然也是一半
    kernel_free_pages equ all_free_pages / 2

    ; 剩下的为用户空间分到的页
    user_free_pages equ all_free_pages - kernel_free_pages
    
    ; 为简化位图操作, 余数不处理, 坏处是这样做会丢内存
    ; 好处是不用做内存的越界检查, 因为位图表示的内存少于实际物理内存

    ; 内核物理内存池的位图长度, 位图中的一位表示一页, 以字节为单位
    kbm_length equ kernel_free_pages / 8

    ; 用户物理内存池的位图长度, 位图中的一位表示一页, 以字节为单位
    ubm_length equ user_free_pages / 8

    ; Kernel Pool start, 内核使用的物理内存池的起始地址
    kp_start equ used_mem

    ; User Pool start, 用户使用的物理内存池的起始地址
    up_start equ kp_start + kernel_free_pages * PAGE_SIZE

    ; --------------------------------
    mov [kernel_pool + MemPool.AddrStart], dword kp_start
    mov [kernel_pool + MemPool.PoolSize], dword (kernel_free_pages * PAGE_SIZE)

    mov [user_pool + MemPool.AddrStart], dword up_start
    mov [user_pool + MemPool.PoolSize], dword (user_free_pages * PAGE_SIZE)

    ; --------------------------------
    mov [kernel_pool + BitMap.ByteSize], dword kbm_length
    mov [kernel_pool + BitMap.BitPointer], dword MEM_BITMAP_BASE
    bitmap_empty(kernel_pool + MemPool.BitMap)

    mov [user_pool + BitMap.ByteSize], dword ubm_length
    mov [user_pool + BitMap.BitPointer], dword (MEM_BITMAP_BASE + kbm_length)
    bitmap_empty(user_pool + MemPool.BitMap)

    ; --------------------------------
    mov [kernel_vaddr + BitMap.ByteSize], dword kbm_length
    mov [kernel_vaddr + BitMap.BitPointer], dword (MEM_BITMAP_BASE + kbm_length + ubm_length)
    mov [kernel_vaddr + VirtualAddr.AddrStart], dword K_HEAP_START
    bitmap_empty(kernel_vaddr + VirtualAddr.BitMap)
func_end

;-------------------------------------------------------------------------------
; 函数名: mem_init
; 描述: 初始化内存管理相关内容
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
func mem_init
    call mem_pool_init
func_end