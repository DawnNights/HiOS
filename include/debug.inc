%ifndef DEBUG_INC
%define DEBUG_INC

%include "include/builtin.inc"
; %define NDEBUG

;-------------------------------------------------------------------------------
; 宏原型: void panic(pointer_t error)
;-------------------------------------------------------------------------------
extern_lib panic

%macro panic 1
    ; 关闭中断防止干扰
    cli

    ; 异常信息字符串入栈
    push_32 %1

    ; 函数名称字符串入栈
    push_32 __FUNCSTR__

    ; 行号入栈
    push_32 __LINE__

    ; 文件名字符串入栈
    push_32 __FILE__

    ; 调用函数并恢复栈顶
    call_lib panic
    add esp, 4 * 4

    ; 将程序停止于此
    jmp $
%endmacro

%define panic(error) panic error

;-------------------------------------------------------------------------------
; 宏名称: assert
; 描述: 当程序执行到断言的位置时, 对应的条件为假, 程序会中止执行, 并给出错误信息 
; 输入: 
;   - %1: 判断元素a
;   - %2: 判断标识符
;   - %3: 判断元素b
; 修改的寄存器: 无
;-------------------------------------------------------------------------------

%macro assert 3
%ifndef NDEBUG

    ; 相等
    %ifidn %2, ==
        cmp %1, %3
        je %%condition_true
        jmp %%condition_false
    
    ; 不相等
    %elifidn %2, !=
        cmp %1, %3
        jne %%condition_true
        jmp %%condition_false
    
    ; 大于
    %elifidn %2, >
        cmp %1, %3
        jg %%condition_true
        jmp %%condition_false
    
    ; 小于
    %elifidn %2, <
        cmp %1, %3
        jl %%condition_true
        jmp %%condition_false

    ; 大于等于
    %elifidn %2, >=
        cmp %1, %3
        jge %%condition_true
        jmp %%condition_false
    
    ; 小于等于
    %elifidn %2, <=
        cmp %1, %3
        jle %%condition_true
        jmp %%condition_false

        ; 逻辑或
    %elifidn %2, ||
        cmp %1, 0
        jne %%condition_true

        cmp %3, 0
        jne %%condition_true

        jmp %%condition_false
    
    ; 逻辑与
    %elifidn %2, &&
        cmp %1, 0
        jne %%condition_and
        jmp %%condition_false

        %%condition_and:
            cmp %3, 0
            jne %%condition_true
            jmp %%condition_false
    
    %endif

    %%condition_false: panic(DQ_MARK %+ Condition: %+ %1 %+ %2 %+ %3 %+ DQ_MARK)

    %%condition_true: 
%endif
%endmacro

%endif