%include "include/builtin.inc"

[bits 32]

section .data
global intr_entry_table

; 中断入口程序地址数组
intr_entry_table:
    dd intr_entry_no_err      ; 0x00
    dd intr_entry_no_err      ; 0x01
    dd intr_entry_no_err      ; 0x02
    dd intr_entry_no_err      ; 0x03
    dd intr_entry_no_err      ; 0x04
    dd intr_entry_no_err      ; 0x05
    dd intr_entry_no_err      ; 0x06
    dd intr_entry_no_err      ; 0x07
    dd intr_entry_with_err    ; 0x08
    dd intr_entry_no_err      ; 0x09
    dd intr_entry_with_err    ; 0x0a
    dd intr_entry_with_err    ; 0x0b
    dd intr_entry_no_err      ; 0x0c
    dd intr_entry_with_err    ; 0x0d
    dd intr_entry_with_err    ; 0x0e
    dd intr_entry_no_err      ; 0x0f
    dd intr_entry_no_err      ; 0x10
    dd intr_entry_with_err    ; 0x11
    dd intr_entry_no_err      ; 0x12
    dd intr_entry_no_err      ; 0x13
    dd intr_entry_no_err      ; 0x14
    dd intr_entry_no_err      ; 0x15
    dd intr_entry_no_err      ; 0x16
    dd intr_entry_no_err      ; 0x17
    dd intr_entry_with_err    ; 0x18
    dd intr_entry_no_err      ; 0x19
    dd intr_entry_with_err    ; 0x1a
    dd intr_entry_with_err    ; 0x1b
    dd intr_entry_no_err      ; 0x1c
    dd intr_entry_with_err    ; 0x1d
    dd intr_entry_with_err    ; 0x1e
    dd intr_entry_no_err      ; 0x1f
    dd intr_entry_no_err      ; 0x20

section .text

; 未压入错误码的通用中断入口函数
intr_entry_no_err:
    ; 向主从片发送EOI(中断结束标记)
    push eax
    
    mov al,0x20
    out 0xa0,al
    out 0x20,al

    pop eax

    ; 从中断返回
    iret


; 压入错误码的通用中断入口函数
intr_entry_with_err:
    ; 跳过错误码
    add esp, 4

    ; 向主从片发送EOI(中断结束标记)
    push eax
    
    mov al,0x20
    out 0xa0,al
    out 0x20,al

    pop eax

    ; 从中断返回
    iret