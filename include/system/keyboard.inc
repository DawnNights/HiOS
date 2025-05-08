%ifndef KEYBOARD_INC
%define KEYBOARD_INC

; 8259A 主从片的相关端口
PIC_M_CTRL equ 0x20
PIC_M_DATA equ 0x21
PIC_S_CTRL equ 0xA0
PIC_S_DATA equ 0xA1

; 键盘缓冲区寄存器端口
KBD_BUF_PORT equ 0x60

; 扩展扫描码
EXT_SCANCODE equ 0xe0

; 左 shift 键的通码断码
SHIFT_LEFT_MAKE  equ 0x2a
SHIFT_LEFT_BREAK equ 0xaa

; 右 shift 键的通码断码
SHIFT_RIGHT_MAKE  equ 0x36
SHIFT_RIGHT_BREAK equ 0xb6

; alt 键的通码断码
ALT_MAKE  equ 0x38
ALT_BREAK equ 0xb8

; ctrl 键的通码断码
CTRL_MAKE  equ 0x1d
CTRL_BREAK equ 0x9d

; capslock 键的通码
CAPSLOCK  equ 0x3a

; 方向键的通码
KEY_UP equ 0x48

KEY_DOWN equ 0x50

KEY_LEFT equ 0x4b

KEY_RIGHT equ 0x4d

%endif