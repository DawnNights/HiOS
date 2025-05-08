%include "include/string.inc"
%include "include/memory.inc"

[bits 32]
section .text
    extern kernel_pool
    extern user_pool
    extern kernel_vaddr

;-------------------------------------------------------------------------------
; 函数名: vaddr_get
; 描述: 在虚拟地址池中申请指定数量的虚拟内存页
; 参数: 
;   - %1: 地址池标识
;   - %2: 申请的内存页数
; 返回值: 成功则返回虚拟页的起始地址, 失败则返回 NULL
;-------------------------------------------------------------------------------
func_lib vaddr_get
    arg bool_t,   pflag
    arg uint32_t, pcount

    uint32_t cnt, 0
    uint32_t bit_idx_start, 0

    ; 判断申请的内存池
    cmp pflag, byte PF_KERNEL
    je kernel_get
    jmp user_get

    ; 在内核内存池中申请
    kernel_get:
        mov ecx, pcount
        mov esi, kernel_vaddr + VirtualAddr.BitMap
        bitmap_scan(esi, ecx)

        mov bit_idx_start, eax
        cmp eax, -1
        jne kset_loop
        return_32 NULL

        kset_loop:
            bitmap_set(kernel_vaddr + VirtualAddr.BitMap, eax, TRUE)
            inc eax
            loop kset_loop
        
        mov eax, bit_idx_start
        shl eax, 12 ; bit_idx_start * 4096
        add eax, [kernel_vaddr + VirtualAddr.AddrStart]
        return_32 eax

    
    ; 在用户内存池中申请
    user_get:
        return_32 NULL
func_end

;-------------------------------------------------------------------------------
; 函数名: palloc
; 描述: 在物理内存池中分配1个物理页
; 参数: 
;   - %1: 物理内存池的指向
; 返回值: 成功则返回页框的物理地址,失败则返回 NULL
;-------------------------------------------------------------------------------
func_lib palloc
    arg pointer_t, m_pool

    int32_t bit_idx, 0
    bitmap_scan(m_pool, 1)
    mov bit_idx, eax

    cmp eax, -1
    jne pget_ok
    return_32 NULL

    pget_ok:
        bitmap_set(m_pool, eax, TRUE)

        mov eax, bit_idx
        shl eax, 12 ; bit_idx * 4096

        mov esi, m_pool
        add eax, [esi+MemPool.AddrStart]
        return_32 eax
func_end

;-------------------------------------------------------------------------------
; 函数名: pde_ptr
; 描述: 得到虚拟地址vaddr对应的pde的指针
; 参数: 
;   - %1: 虚拟地址
; 返回值: pde指针
;-------------------------------------------------------------------------------
func_lib pde_ptr
    arg uint32_t, vaddr
    mov eax, vaddr

    ; 0xfffff000 + ((vaddr & 0xffc00000) >> 22) * 4)
    and eax, 0xffc00000
    shr eax, 22
    shl eax, 2
    
    add eax, 0xfffff000
    return_32 eax
func_end

;-------------------------------------------------------------------------------
; 函数名: pte_ptr
; 描述: 得到虚拟地址vaddr对应的pte的指针
; 参数: 
;   - %1: 虚拟地址
; 返回值: pte指针
;-------------------------------------------------------------------------------
func_lib pte_ptr
    %undef vaddr
    arg uint32_t, vaddr
    mov eax, vaddr
    mov ebx, vaddr

    ; 0xffc00000 + ((vaddr & 0xffc00000) >> 10) + ((vaddr & 0x003ff000) >> 12) * 4
    and ebx, 0xffc00000
    shr ebx, 10

    and eax, 0x003ff000
    shr eax, 12
    shl eax, 2

    add eax, ebx
    add eax, 0xffc00000
    return_32 eax
func_end

;-------------------------------------------------------------------------------
; 函数名: page_table_add
; 描述: 页表中添加虚拟地址与物理地址的映射
; 参数: 
;   - %1: 虚拟地址
;   - %2: 物理地址
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib page_table_add
    arg pointer_t, _vaddr
    arg pointer_t, _paddr

    pde_ptr(_vaddr)
    mov edi, eax

    pte_ptr(_vaddr)
    mov esi, eax

    ; 执行*pte,会访问到空的pde。所以确保pde创建完成后才能执行*pte
    ; 先在页目录内判断目录项的P位, 若为1,则表示该表已存在
    mov eax, [edi]
    and eax, 0x00000001
    cmp eax, 1
    je pde_exist
    jmp pde_not_exist

    pde_exist:
        mov eax, _paddr
        or eax, PAGE_US_USER | PAGE_RW_READ_WRITE | PAGE_P
        mov [esi], eax
        jmp __FUNCEND__

    ; 页目录项不存在,所以要先创建页目录再创建页表项
    pde_not_exist:
        ; 页表中用到的页框一律从内核空间分配
        palloc(kernel_pool)
        or eax, PAGE_US_USER | PAGE_RW_READ_WRITE | PAGE_P
        mov [esi], eax

        ; 分配到的物理页地址对应的物理内存清0
        and esi, 0xfffff000
        memset(esi, 0, PAGE_SIZE)
func_end

;-------------------------------------------------------------------------------
; 函数名: malloc_page
; 描述: 分配指定数量的页空间
; 参数: 
;   - %1: 地址池标识
;   - %2: 申请的内存页数
; 返回值: 成功则返回起始虚拟地址,失败时返回 NULL
;-------------------------------------------------------------------------------
func_lib malloc_page
    %undef pflag
    %undef pcount
    arg bool_t,   pflag
    arg uint32_t, pcount

    ; 通过vaddr_get在虚拟内存池中申请虚拟地址
    vaddr_get(pflag, pcount)
    uint32_t vaddr_start, eax

    cmp eax, NULL
    jne vget_ok
    return_32 NULL

    vget_ok:
        %undef vaddr
        uint32_t vaddr, eax
    
    ; 因为虚拟地址是连续的, 但物理地址可以是不连续的, 所以逐个做映射
    mov ecx, pcount
    padd_loop:
        cmp pflag, byte PF_KERNEL
        je kernel_alloc

        user_alloc:
            palloc(user_pool)
            jmp alloc_done

        kernel_alloc:
            palloc(kernel_pool)
        
        alloc_done:
            cmp eax, NULL
            jne alloc_ok
            return_32 NULL

        alloc_ok:
            page_table_add(vaddr, eax)
            add vaddr, dword PAGE_SIZE
        loop padd_loop

    return_32 vaddr_start
func_end

;-------------------------------------------------------------------------------
; 函数名: get_kernel_pages
; 描述: 从内核物理内存池中分配指定数量的页空间
; 参数: 
;   - %1: 申请的内存页数
; 返回值: 成功则返回起始虚拟地址,失败时返回 NULL
;-------------------------------------------------------------------------------
func_lib get_kernel_pages
    %undef pcount
    arg uint32_t, pcount

    malloc_page(PF_KERNEL, pcount)
    %undef vaddr
    uint32_t vaddr, eax

    cmp eax, NULL
    je kgp_ret

    mov ecx, pcount
    shl ecx, 12
    memset(vaddr, 0, ecx)

    kgp_ret: return_32 vaddr
func_end

;-------------------------------------------------------------------------------
; 函数名: free_kernel_pages
; 描述: 释放从内核物理内存池中分配的页空间
; 参数: 
;   - %1: 内存页虚拟地址
;   - %2: 释放的内存页数
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib free_kernel_pages
    %undef vaddr
    %undef pcount

    arg pointer_t, vaddr
    arg uint32_t, pcount

    mov ecx, pcount
    mov ebx, vaddr

    ; (vaddr & 0x0ffff000) / 4096 - 256
    and ebx, 0x0ffff000
    shr ebx, 12
    sub ebx, 0x100

    free_loop:
        ; 清空页内存
        memset(vaddr, 0, PAGE_SIZE)

        ; 设置物理内存池位图对应状态
        bitmap_set(kernel_pool + MemPool.BitMap, ebx, FALSE)

        ; 设置虚拟地址池位图对应状态
        bitmap_set(kernel_vaddr + VirtualAddr.BitMap, ebx, FALSE)

        
        ; 解除虚拟地址与物理地址的映射关系
        pte_ptr(vaddr)
        mov [eax], dword 0

        ; 进行下一页内存的释放
        inc ebx
        add vaddr, dword PAGE_SIZE
        loop free_loop
func_end