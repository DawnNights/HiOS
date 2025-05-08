%ifndef BUILTIN_INC
%define BUILTIN_INC

%define DQ_MARK "

;-------------------------------------------------------------------------------
; 宏名称: func
; 描述: 开始一个函数并设置堆栈帧 
; 输入: 
;   - %1: 函数标签的名称 
; 修改的寄存器: ebp, esp
;-------------------------------------------------------------------------------
%macro func 1
    %assign __RETVALUE__ 0
    %assign __STACK_VAR__ 0
    %assign __STACK_ARG__ 4 * 9

    %define __FUNCNAME__ %1
    %define __FUNCEND__ %1 %+ _end
    %define __FUNCSTR__ DQ_MARK %+ %1 %+ DQ_MARK

    section .text
    global __FUNCNAME__

    __FUNCNAME__:
        pushad
        mov ebp, esp
%endmacro

;-------------------------------------------------------------------------------
; 宏名称: func_end
; 描述: 结束一个函数并恢复堆栈帧并返回 
; 输入: 无
; 修改的寄存器: ebp, esp
;-------------------------------------------------------------------------------
%macro func_end 0
    __FUNCEND__:
        mov esp, ebp
        
        ; 需要设置返回值
        %if __RETVALUE__ == 1
            mov [esp + 28], dword eax
        %endif

        popad
        ret
%endmacro

;-------------------------------------------------------------------------------
; 宏名称: return_8/16/32
; 描述: 设置寄存器 eax 的值并跳转至返回
; 输入: 
;   - %1: 要设置为返回值的内容
; 修改的寄存器: eax
;-------------------------------------------------------------------------------
%macro return_8 1
    %assign __RETVALUE__ 1

    %ifnum %1
        mov eax, %1
    %else
        movzx eax, byte %1
    %endif
    
    jmp __FUNCEND__
%endmacro

%macro return_16 1
    %assign __RETVALUE__ 1
   
    %ifnum %1
        mov eax, %1
    %else
        movzx eax, word %1
    %endif

    jmp __FUNCEND__
%endmacro

%macro return_32 1
    %assign __RETVALUE__ 1

    %ifnidni %1, eax
        mov eax, dword %1
    %endif
    
    jmp __FUNCEND__
%endmacro

;-------------------------------------------------------------------------------
; 宏名称: local
; 描述: 用于在栈中分配指定长度的内存块声明为变量
; 输入: 
;   - %1: 变量所占字节大小
;   - %2: 变量名称
; 修改的寄存器: esp
;-------------------------------------------------------------------------------
%macro local 2
    %define uint8_t 1
    %define uint16_t 2
    %define uint32_t 4

    %assign __STACK_VAR__ __STACK_VAR__ - (%1)
    sub esp, dword %1
    %xdefine @%2 ebp %+ __STACK_VAR__
    %xdefine %2 [@%2]

    %undef uint8_t
    %undef uint16_t
    %undef uint32_t
%endmacro

;-------------------------------------------------------------------------------
; 宏名称: uint8_t / uint16_t / uint32_t / ...
; 描述: 申请一个 1 / 2 / 4 字节大小的变量并设置默认值
; 输入: 
;   - %1: 变量名称
;   - %2: 变量默认值
; 修改的寄存器: esp
;-------------------------------------------------------------------------------
%macro uint8_t 2
    %assign __STACK_VAR__ __STACK_VAR__ - 1
    %xdefine @%1 ebp %+ __STACK_VAR__
    %xdefine %1 [@%1]
    push_8 %2
%endmacro

%macro uint16_t 2
    %assign __STACK_VAR__ __STACK_VAR__ - 2
    %xdefine @%1 ebp %+ __STACK_VAR__
    %xdefine %1 [@%1]
    push_16 %2
%endmacro

%macro uint32_t 2
    %assign __STACK_VAR__ __STACK_VAR__ - 4
    %xdefine @%1 ebp %+ __STACK_VAR__
    %xdefine %1 [@%1]
    push_32 %2
%endmacro

%xdefine int8_t  uint8_t
%xdefine int16_t uint16_t
%xdefine int32_t uint32_t

%xdefine bool_t    uint8_t
%xdefine char_t    uint8_t
%xdefine pointer_t uint32_t

%xdefine NULL  0 ; 空值
%xdefine TRUE  1 ; 布尔值-真
%xdefine FALSE 0 ; 布尔值-假

;-------------------------------------------------------------------------------
; 宏名称: arg
; 描述: 用于声明栈中传参的大小与名称
; 输入: 
;   - %1: 参数所占字节大小
;   - %2: 参数名称
; 修改的寄存器: esp
;-------------------------------------------------------------------------------
%macro arg 2
    %define uint8_t 1
    %define uint16_t 2
    %define uint32_t 4

    %xdefine @%2  ebp+ %+ __STACK_ARG__
    %xdefine %2 [@%2]
    %assign __STACK_ARG__ __STACK_ARG__ + %1

    %undef uint8_t
    %undef uint16_t
    %undef uint32_t
%endmacro

;-------------------------------------------------------------------------------
; 宏名称: push_8/16/32
; 描述: 将一个8/16/32位内容压入栈中
; 输入: 
;   - %1: 对应位数的内容
; 修改的寄存器: 无
;-------------------------------------------------------------------------------
%macro push_8 1
    ; 内容为立即数
    %ifnum %1
        sub esp, dword 1
        mov [esp], byte %1

    ; 内容为寄存器
    %elifid %1
        sub esp, dword 1
        mov [esp], byte %1
    
    ; 内容为变量或参数
    %else
        sub esp, 1
        push eax
        mov al, byte %1
        mov [esp+4], byte al
        pop eax
    %endif
%endmacro

%macro push_16 1
    push word %1
%endmacro

%macro push_32 1
    ; 内容为字符串
    %ifstr %1
        ; section .data
        ;     %%str db %1, 0
        ; section .text
        ;     push dword %%str
        __pushstr %1
    
    ; 内容为标号或偏移
    %elifid %1
        %define ebp
            %ifnum %1
                %assign %%offset %1
            %else
                %assign %%offset 0
            %endif
        %undef ebp

        %if %%offset == 0
            push dword %1
        %else
            push dword ebp
            add [esp], dword %%offset
        %endif

    ; 内容为其它
    %else
        push dword %1
    
    %endif
%endmacro

;-------------------------------------------------------------------------------
; 宏名称: __pushstr
; 描述: 创建一个全局字符串量入栈, 若字符串已存在则不再创建
; 补充: 因为判断是否有重复定义的字符串太复杂了所以单独拎出来
; 输入: 
;   - %1: 字符串
; 修改的寄存器: 无
;-------------------------------------------------------------------------------
%assign __str_count__ 0 ; 用于被定义字符串的数量

%macro def_str 2
    %define %1 %2
%endmacro

%macro __pushstr 1
    %assign __str_exist__ 0 ; 用于判断字符串是否定义
    %assign __str_index__ 0 ; 用于遍历已定义的字符串

    %rep __str_count__
        %ifidn %1, __def_str__ %+ __str_index__
            %assign __str_exist__ 1
        %endif

        %if __str_exist__ == 0
            %assign __str_index__ __str_index__ + 1
        %endif
    %endrep

    %if __str_exist__ == 0
        section .data
            __str__ %+ __str_count__ db %1, 0
        section .text
            push dword __str__ %+ __str_count__
            def_str __def_str__ %+ __str_index__, %1

        %assign __str_count__ __str_count__ + 1
    %else
        push dword __str__ %+ __str_index__
    %endif

%endmacro

;-------------------------------------------------------------------------------
; 宏名称: intr_disable
; 描述: 关闭中断并将中断状态存储至edi
; 输入: 无
; 修改的寄存器: edi
;-------------------------------------------------------------------------------
%macro intr_disable 0
    pushfd
    pop edi
    cli
%endmacro

;-------------------------------------------------------------------------------
; 宏名称: intr_recover
; 描述: 恢复中断状态并跳转至函数结尾
; 输入: 无
; 修改的寄存器: 无
;-------------------------------------------------------------------------------
%macro intr_recover 0
    bt edi, 9
    jnc __FUNCEND__
    sti
%endmacro

;-------------------------------------------------------------------------------
; 描述: 方便进行库函数的声明、定义等所使用的宏
;-------------------------------------------------------------------------------
%macro func_lib 1
    func lib_%1
%endmacro

%macro call_lib 1
    call lib_%1
%endmacro

%macro extern_lib 1
    extern lib_%1
%endmacro

%endif
