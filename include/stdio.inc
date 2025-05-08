%ifndef STDIO_INC
%define STDIO_INC

%include "include/builtin.inc"

;-------------------------------------------------------------------------------
; 宏原型: void put_char(char_t ascii)
;-------------------------------------------------------------------------------
extern char_attr
extern_lib put_char

%macro put_char 1
    ; 1 字节大小的 ascii 参数入栈
    push_8 %1

    ; 调用函数并恢复栈顶
    call_lib put_char
    add esp, dword 1
%endmacro

%define put_char(ascii) put_char ascii

;-------------------------------------------------------------------------------
; 宏原型: uint32_t put_str(pointer_t char_ptr)
;-------------------------------------------------------------------------------
extern_lib put_str

%macro put_str 1
    ; 4 字节大小的 char_ptr 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib put_str
    add esp, dword 4
%endmacro

%define put_str(char_ptr) put_str char_ptr

;-------------------------------------------------------------------------------
; 宏原型: uint32_t put_uint(uint32_t number)
;-------------------------------------------------------------------------------
extern_lib put_uint

%macro put_uint 1
    ; 4 字节大小的 number 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib put_uint
    add esp, dword 4
%endmacro

%define put_uint(number) put_uint number

;-------------------------------------------------------------------------------
; 宏原型: uint32_t put_int(uint32_t number)
;-------------------------------------------------------------------------------
extern_lib put_int

%macro put_int 1
    ; 4 字节大小的 number 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib put_int
    add esp, dword 4
%endmacro

%define put_int(number) put_int number

;-------------------------------------------------------------------------------
; 宏原型: uint32_t put_hex(uint32_t number, bool_t is_upper)
;-------------------------------------------------------------------------------
extern_lib put_hex

%macro put_hex 2
    ; 1 字节大小的 is_upper 参数入栈
    push_8 %2 

    ; 4 字节大小的 number 参数入栈
    push_32 %1

    ; 调用函数并恢复栈顶
    call_lib put_hex
    add esp, dword 4 + 1
%endmacro

%define put_hex(number, is_upper) put_hex number, is_upper

;-------------------------------------------------------------------------------
; 宏原型: uint32_t printf(pointer_t format, ...)
;-------------------------------------------------------------------------------
extern_lib printf

%macro printf 1-*
    %rep %0
        %rotate %0 - 1
        push_32 %1     
    %endrep

    call_lib printf
    add esp, %0 * 4
%endmacro

%define printf(format) printf format
%define printf(format, arg1) printf format, arg1
%define printf(format, arg1, arg2) printf format, arg1, arg2
%define printf(format, arg1, arg2, arg3) printf format, arg1, arg2, arg3
%define printf(format, arg1, arg2, arg3, arg4) printf format, arg1, arg2, arg3, arg4
%define printf(format, arg1, arg2, arg3, arg4, arg5) printf format, arg1, arg2, arg3, arg4, arg5
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6) printf format, arg1, arg2, arg3, arg4, arg5, arg6
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6, arg7) printf format, arg1, arg2, arg3, arg4, arg5, arg6, arg7
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) printf format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) printf format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

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
    cli
    jmp $
%endmacro

%define panic(error) panic error

%endif
