%include "include/stdio.inc"
%include "include/stdlib.inc"
%include "include/string.inc"
%include "include/bitmap.inc"

%include "include/system/memory.inc"

[bits 32]
extern idt_init
extern mem_init

extern kernel_pool
extern kernel_vaddr

func _start
    ; ------------- 初始化系统相关模块 -------------
    call idt_init   ; 中断初始化
    call mem_init   ; 内存初始化
    
    malloc_page(PF_KERNEL, 1)
    malloc_page(PF_KERNEL, 1)
    jmp $
func_end