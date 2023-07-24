%include "include/stdio.inc"
%include "include/stdlib.inc"
%include "include/string.inc"
%include "include/bitmap.inc"
%include "include/list.inc"
%include "include/system/thread.inc"

[bits 32]
extern idt_init
extern mem_init
extern thread_init

func _start
    ; ------------- 初始化系统相关模块 -------------
    set_cursor_ex(0, 0) ; 光标位置初始化
    call idt_init       ; 中断机制初始化
    call mem_init       ; 内存管理初始化
    call thread_init    ; 线程调度初始化

    thread_start(my_thread1, "my_thread1", 8, "INFO: I'm Thread 1, run times %d\n")
    thread_start(my_thread2, "my_thread2", 6, "INFO: I'm Thread 2, run times %d\n")
    thread_start(my_thread3, "my_thread3", 4, "INFO: I'm Thread 3, run times %d\n")

    print_loop0:
        mov ecx, 60000000
        delay_loop0: loop delay_loop0

        printf("INFO: I'm Thread Main\n")
    
    mov [ebp - 0x1000 + ThreadControl.Status], dword TASK_BLOCKED
    jmp print_loop0
func_end


func my_thread1
    arg pointer_t, my_arg1
    uint32_t times1, 0

    print_loop1: 
        mov ecx, 60000000
        delay_loop1: loop delay_loop1

        inc dword times1
        printf(my_arg1, times1)
    
    jmp print_loop1
func_end

func my_thread2
    arg pointer_t, my_arg2
    uint32_t times2, 0

    mov eax, 0
    print_loop2: 
        mov ecx, 60000000
        delay_loop2: loop delay_loop2

        inc dword times2
        printf(my_arg2, times2)
    
    ; jmp print_loop2
func_end

func my_thread3
    arg pointer_t, my_arg3
    uint32_t times3, 0

    mov eax, 0
    print_loop3: 
        mov ecx, 60000000
        delay_loop3: loop delay_loop3

        inc dword times3
        printf(my_arg3, times3)
   
    jmp print_loop3
func_end