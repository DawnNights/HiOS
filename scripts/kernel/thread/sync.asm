%include "include/stdio.inc"
%include "include/sync.inc"
%include "include/thread.inc"

;-------------------------------------------------------------------------------
; 函数名: lock_init
; 描述: 初始化互斥锁
; 参数: 
;   - %1: 互斥锁的指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib lock_init
    ; 取消宏定义防止变量名冲突
    %undef plock

    ; 声明函数传参
    arg pointer_t, plock

    ; 以下是函数主体
    mov esi, plock

    mov [esi + MutexLock.Holder], dword NULL
    mov [esi + MutexLock.Sema], dword 0
    
    lea edx, [esi + MutexLock.WaiterList]
    list_clear(edx)
func_end

;-------------------------------------------------------------------------------
; 函数名: lock_acquire
; 描述: 占用互斥锁
; 参数: 
;   - %1: 参数1
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib lock_acquire
    ; 取消宏定义防止变量名冲突
    %undef plock

    ; 声明函数传参
    arg pointer_t, plock

    ; 以下是函数主体
    intr_disable
    mov esi, plock
    
    ; 如果当前运行线程为锁持有线程
    call get_running_thread
    mov ebx, eax

    cmp [esi + MutexLock.Holder], ebx
    je inc_sema

    ; 如果信号量不为 0 则表示锁当前被占用
    cmp [esi + MutexLock.Sema], dword 0
    jne lock_used

    mov [esi + MutexLock.Holder], ebx
    je inc_sema

    ; 当锁被占用时将阻塞当前线程并置入等待队列中
    lock_used:
        lea ecx, [esi + MutexLock.WaiterList]
        lea edx, [ebx + ThreadControl.SignElem]
        mov [ebx + ThreadControl.Status], dword TASK_BLOCKED
        list_append(ecx, edx)

        ; 压入中断返回内容
        pushfd
        push dword cs
        push dword inc_sema

        ; 压入段和通用寄存器
        push ds
        push es
        push fs
        push gs
        push ss
        pushad

        ; 线程调度
        mov [ebx + ThreadControl.StackTop], esp
        jmp thread_schedule

    inc_sema: inc dword [esi + MutexLock.Sema]
    intr_recover
func_end

;-------------------------------------------------------------------------------
; 函数名: lock_release
; 描述: 释放互斥锁
; 参数: 
;   - %1: 参数1
; 返回值: 无
;-------------------------------------------------------------------------------
extern thread_ready_list

func_lib lock_release
    ; 取消宏定义防止变量名冲突
    %undef plock

    ; 声明函数传参
    arg pointer_t, plock

    ; 以下是函数主体
    intr_disable
    mov esi, plock
    
    ; 如果当前运行线程不为锁持有线程则直接返回
    call get_running_thread
    mov ebx, eax

    cmp [esi + MutexLock.Holder], ebx
    je is_hold_thread
    jmp release_end    

    ; 如果信号量大于1说明锁在当前线程被多次持有, 需要多次释放
    is_hold_thread:
        cmp [esi + MutexLock.Sema], dword 1
        je lock_free

        dec dword [esi + MutexLock.Sema]
        intr_recover

    lock_free:
        mov [esi + MutexLock.Holder], dword NULL
        mov [esi + MutexLock.Sema], dword 0

    ; 若等待队列为空则直接返回
    lea ecx, [esi + MutexLock.WaiterList]
    list_is_empty(ecx)

    cmp eax, FALSE
    je have_wait_thread
    jmp release_end

    ; 若等待队列不为空则解除队首线程的阻塞并加入调度表
    have_wait_thread:
        ; 设置当前线程栈内容
        pushfd
        push dword cs
        push dword release_end

        push ds
        push es
        push fs
        push gs
        push ss
        pushad

        mov [ebx + ThreadControl.StackTop], esp
        
        ; 解除等待队列的队首线程并调度
        list_pop(ecx)
        lea ebx, [eax - ThreadControl.SignElem]
        mov [esi + MutexLock.Holder], ebx

        mov [ebx + ThreadControl.Status], dword TASK_READY
        list_push(thread_ready_list, eax)
        jmp thread_schedule

    release_end: intr_recover
func_end
