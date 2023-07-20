%ifndef MEMORY_INC
%define MEMORY_INC

%include "include/bitmap.inc"
%include "include/system/page.inc"

; 这个地址是位图的起始地址, 1MB内存布局中, 9FBFF是最大一段可用区域的边界
; 我们计划这个可用空间最后的位置将来用来放PCB, 而PCB占用内存是一个自然页, 所以起始地址必须是0xxxx000这种形式, 离0x9fbff最近的符合这个形式的地址是0x9f000
; 我们又为了将来可能的拓展, 所以让位图可以支持管理512MB的内存空间, 所以预留位图大小为16KB, 也就是4页, 所以选择0x9a000作为位图的起始地址
MEM_BITMAP_BASE equ 0xc009a000

; 定义内核堆区起始地址, 堆区就是用来进行动态内存分配的地方, 咱们的系统内核运行在c00000000开始的1MB虚拟地址空间, 所以自然要跨过这个空间
; 堆区的起始地址并没有跨过256个页表, 没关系, 反正使用虚拟地址最终都会被我们的页表转换为物理地址, 我们建立物理映射的时候, 跳过256个页表就行了
K_HEAP_START equ 0xc0100000

; 虚拟地址结构, 有一个位图与其管理的起始虚拟地址
struc VirtualAddr
    .BitMap:    resd 2   ; 虚拟地址使用位图
    .AddrStart: resd 1   ; 虚拟地址起始地址
endstruc

; 物理内存池结构, 生成两个实例用于管理内核物理内存池和用户物理内存池
struc MemPool
    .BitMap:    resd 2   ; 内存池使用位图
    .AddrStart: resd 1   ; 内存池起始地址
    .PoolSize:  resd 1   ; 内存池字节容量
endstruc

; 内存池标记, 用于判断内存池的类型
PF_USER equ 0
PF_KERNEL equ 1

;-------------------------------------------------------------------------------
; 宏原型: pointer_t vaddr_get(bool_t pflag, uint32_t pcount)
;-------------------------------------------------------------------------------
extern_lib vaddr_get

%macro vaddr_get 2
    ; 4 字节大小的 pcount 参数入栈
    push_32 %2

    ; 1 字节大小的 pflag 参数入栈
    push_8 %1

    ; 调用函数并恢复栈顶
    call_lib vaddr_get
    add esp, dword 1 + 4
%endmacro

%define vaddr_get(pflag, pcount) vaddr_get pflag, pcount

;-------------------------------------------------------------------------------
; 宏原型: pointer_t palloc(pointer_t m_pool)
;-------------------------------------------------------------------------------
extern_lib palloc

%macro palloc 1
    ; 4 字节大小的 m_pool 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib palloc
    add esp, dword 4
%endmacro

%define palloc(m_pool) palloc m_pool

;-------------------------------------------------------------------------------
; 宏原型: pointer_t pde_ptr(uint32_t vaddr)
;-------------------------------------------------------------------------------
extern_lib pde_ptr

%macro pde_ptr 1
    ; 4 字节大小的 vaddr 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib pde_ptr
    add esp, dword 4
%endmacro

%define pde_ptr(vaddr) pde_ptr vaddr

;-------------------------------------------------------------------------------
; 宏原型: pointer_t pte_ptr(uint32_t vaddr)
;-------------------------------------------------------------------------------
extern_lib pte_ptr

%macro pte_ptr 1
    ; 4 字节大小的 vaddr 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib pte_ptr
    add esp, dword 4
%endmacro

%define pte_ptr(vaddr) pte_ptr vaddr

;-------------------------------------------------------------------------------
; 宏原型: void page_table_add(pointer_t _vaddr, pointer_t _paddr)
;-------------------------------------------------------------------------------
extern_lib page_table_add

%macro page_table_add 2
    ; 4 字节大小的 _paddr 参数入栈
    push_32 %2

    ; 4 字节大小的 _vaddr 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib page_table_add
    add esp, dword 4 + 4
%endmacro

%define page_table_add(_vaddr, _paddr) page_table_add _vaddr, _paddr

;-------------------------------------------------------------------------------
; 宏原型: pointer_t malloc_page(bool_t pflag, uint32_t pcount)
;-------------------------------------------------------------------------------
extern_lib malloc_page

%macro malloc_page 2
    ; 4 字节大小的 pcount 参数入栈
    push_32 %2

    ; 1 字节大小的 pflag 参数入栈
    push_8 %1

    ; 调用函数并恢复栈顶
    call_lib malloc_page
    add esp, dword 1 + 4
%endmacro

%define malloc_page(pflag, pcount) malloc_page pflag, pcount

;-------------------------------------------------------------------------------
; 宏原型: pointer_t get_kernel_pages(bint32_t pcount)
;-------------------------------------------------------------------------------
extern_lib get_kernel_pages

%macro get_kernel_pages 1
    ; 4 字节大小的 pcount 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib get_kernel_pages
    add esp, dword 4
%endmacro

%define get_kernel_pages(pcount) get_kernel_pages pcount

%endif