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

;-------------------------------------------------------------------------------
; 宏原型: void set_text_attr(bool_t blink, uint8_t bg_color, uint8_t fg_color)
;-------------------------------------------------------------------------------
extern CHAR_ATTR
extern_lib set_text_attr

; 黑色 | 灰色
BLACK equ 000b
GRAY equ 1000b

; 蓝色 | 浅蓝色
BLUE  equ 001b
LIGHT_BULE equ 1001b

; 绿色 | 浅绿色
GREEN equ 010b
LIGHT_GREEN equ 1010b

; 青色 | 浅青色
CYAN equ 011b
LIGHT_CYAN equ 1011b

; 红色 | 浅红色
RED equ 100b
LIGHT_RED equ 1100b

; 品红 | 浅品红
MAGENTA equ 101b
LIGHT_MAGENTA equ 1101b

; 棕色 | 黄色
BROWN equ 110b
YELLOW equ 1110b

; 白色 | 亮白色
WHITE equ 111b
LIGHT_WHITE equ 1111b

%macro set_text_attr 3
    mov [CHAR_ATTR], byte %1 << 7 | %2 << 4 | %3 
%endmacro

%define set_text_attr(blink, bg_color, fg_color) set_text_attr blink, bg_color, fg_color

%endif
