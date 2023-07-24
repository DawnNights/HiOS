%include "include/list.inc"
%include "include/string.inc"
%include "include/stdio.inc"

%include "include/system/memory.inc"
%include "include/system/thread.inc"

%define SHOW_THREAD_INFO

section .data
    head  dq 0
    tail  dq 0

    thread_sign_list: istruc List
        at List.Head,   dd head
        at List.Tail,   dd tail
    iend
    
    reserved_stack_addr dd 0

[bits 32]
section .text
;-------------------------------------------------------------------------------
; 函数名: get_running_thread
; 描述: 获取正在运行的线程的控制模块
; 参数: 无
; 返回值: 当前线程控制模块的地址
;-------------------------------------------------------------------------------
global get_running_thread

get_running_thread:
    mov eax, esp
    and eax, 0xfffff000
    ret

;-------------------------------------------------------------------------------
; 函数名: thread_ctrl_init
; 描述: 初始化线程控制模块
; 参数: 
;   - %1: 线程控制模块地址
;   - %2: 线程名称字符串地址(上限15个字符)
;   - %3: 线程单次允许执行的时钟周期
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib thread_ctrl_init
    ; 取消宏定义防止变量名冲突
    %undef ctrl
    %undef name
    %undef priority

    ; 声明函数传参
    arg pointer_t, ctrl
    arg pointer_t, name
    arg uint32_t, priority

    ; 以下是函数主体
    mov ebx, ctrl
    memset(ebx, 0, ThreadControl_size)

    ; 传入的线程的名字填入线程的pcb
    lea esi, [ebx + ThreadControl.Name]
    strcpy(esi, name)

    ; 设置线程的状态为准备态
    mov [ebx + ThreadControl.Status], dword TASK_READY

    ; 设置线程的执行周期
    set_priority: mov edx, priority
    mov [ebx + ThreadControl.Priority], dword edx
    mov [ebx + ThreadControl.Ticks], dword edx
    mov [ebx + ThreadControl.TotalTicks], dword 0

    ; 线程没有自己的地址空间, 故设置为 NULL
    mov [ebx + ThreadControl.PageDir], dword NULL

    ; 本操作系统的线程不会太大，向下偏移一页大小内存作栈足够
    mov [ebx + ThreadControl.StackTop], ebx
    add [ebx + ThreadControl.StackTop], dword PAGE_SIZE

    ; 边界魔数, 防止栈向上偏移覆盖了 ThreadControl 信息
    mov [ebx + ThreadControl.MagicNum], dword 0x20130427
func_end

;-------------------------------------------------------------------------------
; 函数名: thread_start
; 描述: 创建一个线程并启动
; 参数: 
;   - %1: 线程执行函数的地址
;   - %2: 线程执行函数的名称
;   - %3: 线程单次允许执行的时钟周期
;   - %4: 线程执行函数的传参地址
; 返回值: 新线程的控制模块
;-------------------------------------------------------------------------------
thread_exit:
    cli
    call get_running_thread
    mov ebx, eax
    jmp when_thread_died

func_lib thread_start
    ; 取消宏定义防止变量名冲突
    %undef function
    %undef name
    %undef priority
    %undef func_arg

    ; 声明函数传参
    arg pointer_t, function
    arg pointer_t, name
    arg uint32_t, priority
    arg pointer_t, func_arg

    ; 申请一页内存用于当作控制模块+栈内存
    get_kernel_pages(1)
    mov ebx, eax
    thread_ctrl_init(ebx, name, priority)
    
    ; 在线程栈压入传参和返回地址
    mov esp, [ebx + ThreadControl.StackTop]

    push dword func_arg
    push dword thread_exit

    ; 在线程栈压入中断返回内容
    pushfd
    push dword cs
    push dword function

    ; 在线程栈压入栈寄存器
    push ds
    push es
    push fs
    push gs
    push ss

    ; 在线程栈压入通用寄存器
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0

    ; 写入当前栈顶的值
    mov [ebx + ThreadControl.StackTop], esp
    
    ; 将线程任务置入调度表中
    lea esi, [ebx + ThreadControl.SignElem]
    list_append(thread_sign_list, esi)

    %ifdef SHOW_THREAD_INFO
        put_str("\n--------------------------------\n")
        printf("Start Thread: %s\nMalloc Page Addr: %p", name, ebx)
        put_str("\n--------------------------------\n")
    %endif

    return_32 ebx
func_end


;-------------------------------------------------------------------------------
; 函数名: thread_schedule
; 描述: 进行线程调度
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
global thread_schedule

thread_schedule:
    cli ; 关闭中断防止当前调度被打断

    ; 判断调度线程的状态并进行处理
    call get_running_thread
    mov ebx, eax

    cmp [ebx + ThreadControl.Status], dword TASK_RUNNING
    je when_thread_running

    cmp [ebx + ThreadControl.Status], dword TASK_READY
    je when_thread_ready
    
    cmp [ebx + ThreadControl.Status], dword TASK_BLOCKED
    je when_thread_block

    cmp [ebx + ThreadControl.Status], dword TASK_WAITING
    je when_thread_block

    cmp [ebx + ThreadControl.Status], dword TASK_HANGING
    je when_thread_block

    cmp [ebx + ThreadControl.Status], dword TASK_DIED
    je when_thread_died

    ; 进入下一个线程
    enter_next_thread:
        list_pop(thread_sign_list)
        lea ebx, [eax - ThreadControl.SignElem]
        mov esp, [ebx + ThreadControl.StackTop]
        jmp thread_schedule
        

    ; 表示调度线程还未执行完毕, 只是单次执行周期到达上限
    ; 使用刷新该线程的执行周期, 更改为就绪态重新放入调度表后再进入下一个线程
    when_thread_running:
        mov edx, [ebx + ThreadControl.Priority]
        mov [ebx + ThreadControl.Ticks], edx

        mov [ebx + ThreadControl.Status], dword TASK_READY
        
        lea edx, [ebx + ThreadControl.SignElem]
        list_append(thread_sign_list, edx)
        jmp enter_next_thread

    ; 表示调度线程已经准备就绪, 跳转到执行函数运行
    when_thread_ready:
        mov [ebx + ThreadControl.Status], dword TASK_RUNNING
        
        popad
        pop ss
        pop gs
        pop fs
        pop es
        pop ds

        sti ; 打开中断使得线程可以继续调度
        iret

    ; 表示调度线程被阻塞, 直接进入下一个线程
    when_thread_block:
        jmp enter_next_thread
    
    ; 表示调度线程已经执行完毕, 释放占用的页内存再进入下一个线程
    when_thread_died:
        %ifdef SHOW_THREAD_INFO
            lea edx, [ebx + ThreadControl.Name]

            put_str("\n--------------------------------\n")
            printf("Exit Thread: %s\nFree Page Addr: %p", edx, ebx)
            put_str("\n--------------------------------\n")
        %endif

        mov esp, [reserved_stack_addr]
        free_kernel_pages(ebx, 1)
        jmp enter_next_thread

;-------------------------------------------------------------------------------
; 函数名: thread_init
; 描述: 初始化线程调度相关内容
; 参数: 无
; 返回值: 无
;-------------------------------------------------------------------------------
global thread_init

thread_init:
    ; 获取主函数执行地址
    pop edi

    ; 申请一页内存当作预留空间
    get_kernel_pages(1)
    add eax, PAGE_SIZE  ; 栈地址由高到低偏移
    mov [reserved_stack_addr], eax

    ; 初始化主函数控制模块
    call get_running_thread
    mov ebx, eax
    thread_ctrl_init(ebx, "_start", 30)

    ; 设置主线程栈内容
    mov [ebx + ThreadControl.Status], dword TASK_RUNNING
    mov esp, [ebx + ThreadControl.StackTop]


    ; 压入中断返回内容
    pushfd
    push dword cs
    push dword edi

    ; 压入栈寄存器
    push ds
    push es
    push fs
    push gs
    push ss

    ; 压入通用寄存器
    sub esp, 4 * 8

    ; EBP = ebx + PAGE_SIZE
    mov [esp + 8], ebx  
    add [esp + 8], dword PAGE_SIZE

    ; 线程调度
    mov [ebx + ThreadControl.StackTop], esp

    list_clear(thread_sign_list)
    call thread_schedule