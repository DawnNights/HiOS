%include "include/sync.inc"
%include "include/ioqueue.inc"
%include "include/thread.inc"

;-------------------------------------------------------------------------------
; 函数名: ioq_init
; 描述: 初始化环形队列
; 参数:
;   - %1: 指向队列的指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib ioq_init
    ; 取消宏定义防止变量名冲突
    %undef ioq
    
    ; 声明函数传参
    arg pointer_t, ioq
    
    ; 以下是函数主体
    mov ebx, ioq

    lea edx, [ebx+IOQueue.Lock]
    lock_init(edx)

    mov [ebx+IOQueue.Producer], dword NULL
    mov [ebx+IOQueue.Consumer], dword NULL

    mov [ebx+IOQueue.Head], dword 0
    mov [ebx+IOQueue.Tail], dword 0
func_end

;-------------------------------------------------------------------------------
; 函数名: ioq_next_pos
; 描述: 获取队列缓冲区的下一个位置
; 参数:
;   - %1: 位置索引
; 返回值: 下一个位置索引
;-------------------------------------------------------------------------------
func_lib ioq_next_pos
    ; 取消宏定义防止变量名冲突
    %undef pos

    ; 声明函数传参
    arg uint32_t, pos

    ; 以下是函数主体
    add pos, dword 1
    mov eax, pos
    mov ebx, BUFSIZE

    xor edx, edx
    div ebx
    return_32 edx
func_end

;-------------------------------------------------------------------------------
; 函数名: ioq_full
; 描述: 判断队列是否为满
; 参数:
;   - %1: 指向队列的指针
; 返回值: 若队列为满返回TRUE, 否则返回FALSE
;-------------------------------------------------------------------------------
func_lib ioq_full
    ; 取消宏定义防止变量名冲突
    %undef ioq

    ; 声明函数传参
    arg pointer_t, ioq

    ; 以下是函数主体
    mov ebx, ioq

    ioq_next_pos([ebx+IOQueue.Head])
    cmp eax, [ebx+IOQueue.Tail]
    jne not_full

    return_8 TRUE
    not_full: return_8 FALSE
func_end

;-------------------------------------------------------------------------------
; 函数名: ioq_empty
; 描述: 判断队列是否为空
; 参数:
;   - %1: 指向队列的指针
; 返回值: 若队列为空返回TRUE, 否则返回FALSE
;-------------------------------------------------------------------------------
func_lib ioq_empty
    ; 取消宏定义防止变量名冲突
    %undef ioq

    ; 声明函数传参
    arg pointer_t, ioq

    ; 以下是函数主体
    mov ebx, ioq

    mov eax, [ebx+IOQueue.Head]
    cmp eax, [ebx+IOQueue.Tail]
    jne not_empty

    return_8 TRUE
    not_empty: return_8 FALSE
func_end

;-------------------------------------------------------------------------------
; 函数名: ioq_wait
; 描述: 使当前生产者或消费者在此缓冲区上等待
; 参数:
;   - %1: 指向线程的二级指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib ioq_wait
    ; 取消宏定义防止变量名冲突
    %undef waiter

    ; 声明函数传参
    arg pointer_t, waiter

    ; 以下是函数主体
    mov ebx, waiter
    
    call get_running_thread
    mov [ebx], eax
    thread_block(TASK_BLOCKED)
func_end

;-------------------------------------------------------------------------------
; 函数名: ioq_wakeup
; 描述: 唤醒正在等待的生产者或消费者
; 参数:
;   - %1: 指向线程的二级指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib ioq_wakeup
    ; 取消宏定义防止变量名冲突
    %undef waiter

    ; 声明函数传参
    arg pointer_t, waiter

    ; 以下是函数主体
    mov ebx, waiter
    thread_unblock([ebx])
    mov [ebx], dword NULL
func_end

;-------------------------------------------------------------------------------
; 函数名: ioq_getchar
; 描述: 消费者从队列中获取一个字符
; 参数:
;   - %1: 指向队列的指针
; 返回值: 一个ascii字符
;-------------------------------------------------------------------------------
func_lib ioq_getchar
    ; 取消宏定义防止变量名冲突
    %undef ioq

    ; 声明函数传参
    arg pointer_t, ioq

    ; 声明函数变量
    char_t char, 0

    ; 以下是函数主体
    mov ebx, ioq

    while_ioq_empty:
        ioq_empty(ebx)
        cmp eax, FALSE
        je ioq_not_empty

        lea edx, [ebx+IOQueue.Lock]
        lea ecx, [ebx+IOQueue.Consumer]

        lock_acquire(edx)
        ioq_wait(ecx)
        lock_release(edx)

        jmp while_ioq_empty

    ioq_not_empty:
        lea ecx, [ebx+IOQueue.Buffer]
        add ecx, [ebx+IOQueue.Tail]
        mov al, [ecx]
        mov char, al

        ioq_next_pos([ebx+IOQueue.Tail])
        mov [ebx+IOQueue.Tail], eax

        cmp [ebx+IOQueue.Producer], dword NULL
        je get_char_ret

        lea ecx, [ebx+IOQueue.Producer]
        ioq_wakeup(ecx)

    get_char_ret:
        return_8 char
func_end

;-------------------------------------------------------------------------------
; 函数名: ioq_putchar
; 描述: 生产者向队列中写入一个字符
; 参数:
;   - %1: 指向队列的指针
;   - %2: 一个ascii字符
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib ioq_putchar
    ; 取消宏定义防止变量名冲突
    %undef ioq
    %undef char

    ; 声明函数传参
    arg pointer_t, ioq
    arg char_t, char

    ; 以下是函数主体
    mov ebx, ioq
    
    while_ioq_full:
        ioq_full(ebx)
        cmp eax, FALSE
        je ioq_not_full

        lea edx, [ebx+IOQueue.Lock]
        lea ecx, [ebx+IOQueue.Producer]

        lock_acquire(edx)
        ioq_wait(ecx)
        lock_release(edx)

        jmp while_ioq_full

    ioq_not_full:
        lea ecx, [ebx+IOQueue.Buffer]
        add ecx, [ebx+IOQueue.Head]
        mov al, char
        mov [ecx], al

        ioq_next_pos([ebx+IOQueue.Head])
        mov [ebx+IOQueue.Head], eax

        cmp [ebx+IOQueue.Consumer], dword NULL
        je __FUNCEND__

        lea ecx, [ebx+IOQueue.Consumer]
        ioq_wakeup(ecx)
func_end
