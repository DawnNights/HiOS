%include "include/list.inc"
%include "include/stdio.inc"

extern intr_disable
extern intr_recover

;-------------------------------------------------------------------------------
; 函数名: list_clear
; 描述: 清空链表中的所有元素
; 参数: 
;   - %1: 链表的指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib list_clear
    ; 取消宏定义防止变量名冲突
    %undef list

    ; 声明函数传参
    arg pointer_t, list

    ; 以下是函数主体
    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edi, [ebx + List.Tail]

    mov [esi + ListElem.Prev], dword NULL
    mov [esi + ListElem.Next], dword edi

    mov [edi + ListElem.Prev], dword esi
    mov [edi + ListElem.Next], dword NULL
func_end

;-------------------------------------------------------------------------------
; 函数名: list_append
; 描述: 在链表的末尾添加一个元素
; 参数: 
;   - %1: 链表的指针
;   - %2: 添加元素的指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib list_append
    ; 取消宏定义防止变量名冲突
    %undef list
    %undef elem

    ; 声明函数传参
    arg pointer_t, list
    arg pointer_t, elem

    ; 以下是函数主体
    call intr_disable

    mov ebx, list
    mov edi, [ebx + List.Tail]
    mov edx, elem

    mov eax, [edi + ListElem.Prev]
    mov [edx + ListElem.Prev], eax
    mov [edx + ListElem.Next], edi

    mov esi, [edx + ListElem.Prev]
    mov [esi + ListElem.Next], edx

    mov [edi + ListElem.Prev], edx

    call intr_recover
func_end

;-------------------------------------------------------------------------------
; 函数名: list_push
; 描述: 在链表的开头添加一个元素
; 参数: 
;   - %1: 链表的指针
;   - %2: 添加元素的指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib list_push
    ; 取消宏定义防止变量名冲突
    %undef list
    %undef elem

    ; 声明函数传参
    arg pointer_t, list
    arg pointer_t, elem

    ; 以下是函数主体
    call intr_disable

    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edx, elem

    mov eax, [esi + ListElem.Next]
    mov [edx + ListElem.Prev], esi
    mov [edx + ListElem.Next], eax

    mov edi, [edx + ListElem.Next]
    mov [edi + ListElem.Prev], edx

    mov [esi + ListElem.Next], edx

    call intr_recover
func_end

;-------------------------------------------------------------------------------
; 函数名: list_print
; 描述: 打印链表字符串到屏幕
; 参数: 
;   - %1: 参数1
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib list_print
    ; 取消宏定义防止变量名冲突
    %undef list

    ; 声明函数传参
    arg pointer_t, list

    ; 以下是函数主体
    call intr_disable

    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edi, [ebx + List.Tail]
    mov edx, [esi + ListElem.Next]

    put_str("Head -> ")

    print_loop:
        cmp edx, edi
        je print_tail

        printf("%p -> ",edx)
        mov edx, [edx + ListElem.Next]
        jmp print_loop

    print_tail: put_str("Tail")

    call intr_recover
func_end

;-------------------------------------------------------------------------------
; 函数名: list_remove
; 描述: 使指定元素脱离链表
; 参数: 
;   - %1: 指定元素的指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib list_remove
    ; 取消宏定义防止变量名冲突
    %undef elem

    ; 声明函数传参
    arg pointer_t, elem

    ; 以下是函数主体
    call intr_disable

    mov ebx, elem
    mov esi, [ebx + ListElem.Prev]
    mov edi, [ebx + ListElem.Next]

    mov [esi + ListElem.Next], edi
    mov [edi + ListElem.Prev], esi

    call intr_recover
func_end

;-------------------------------------------------------------------------------
; 函数名: list_pop
; 描述: 弹出并返回链表队首的元素
; 参数: 
;   - %1: 指向链表的指针
; 返回值: 链表开头的元素的指针
;-------------------------------------------------------------------------------
func_lib list_pop
    ; 取消宏定义防止变量名冲突
    %undef list
    %undef elem

    ; 声明函数传参
    arg pointer_t, list

    mov ebx, list
    mov esi, [ebx + List.Head]

    pointer_t elem, [esi +ListElem.Next]
    list_remove(elem)
    return_32 elem
func_end