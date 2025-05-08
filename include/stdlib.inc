%ifndef STDLIB_INC
%define STDLIB_INC

%include "include/builtin.inc"

;-------------------------------------------------------------------------------
; 宏原型: uint16_t get_cursor()
;-------------------------------------------------------------------------------
extern_lib get_cursor
%define get_cursor(...) call_lib get_cursor

;-------------------------------------------------------------------------------
; 宏原型: uint16_t get_cursor_ex()
;-------------------------------------------------------------------------------
extern_lib get_cursor_ex
%define get_cursor_ex(...) call_lib get_cursor_ex

;-------------------------------------------------------------------------------
; 宏原型: void set_cursor(uint8_t high, uint8_t low)
;-------------------------------------------------------------------------------
extern_lib set_cursor

%macro set_cursor 2
    ; 1 字节大小的 low 参数入栈
    push_8 %2

    ; 1 字节大小的 high 参数入栈
    push_8 %1

    ; 调用函数并恢复栈顶
    call_lib set_cursor
    add esp, dword 1 + 1
%endmacro

%define set_cursor(high, low) set_cursor high, low

;-------------------------------------------------------------------------------
; 宏原型: void set_cursor_ex(uint8_t row, uint8_t col)
;-------------------------------------------------------------------------------
extern_lib set_cursor_ex

%macro set_cursor_ex 2
    ; 1 字节大小的 col 参数入栈
    push_8 %2

    ; 1 字节大小的 row 参数入栈
    push_8 %1

    ; 调用函数并恢复栈顶
    call_lib set_cursor_ex
    add esp, dword 1 + 1
%endmacro

%define set_cursor_ex(row, col) set_cursor_ex row, col

;-------------------------------------------------------------------------------
; 宏原型: void roll_screen(uint8_t count)
;-------------------------------------------------------------------------------
extern_lib roll_screen

%macro roll_screen 1
    ; 1 字节大小的 count 参数入栈
    push_8 %1

    ; 调用函数并恢复栈顶
    call_lib roll_screen
    add esp, dword 1
%endmacro

%define roll_screen(count) roll_screen count

%endif