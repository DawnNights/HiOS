%include "include/builtin.inc"

[bits 32]

;-------------------------------------------------------------------------------
; 函数名: get_cursor
; 描述: 获取光标当前位置
; 参数: 无
; 返回值: 光标的位置
;-------------------------------------------------------------------------------
func_lib get_cursor
    ; 获取光标位置的高八位
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    in al, dx
    mov ah, al

    ; 获取光标位置的低八位
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    in al, dx

    return_16 ax
func_end

;-------------------------------------------------------------------------------
; 函数名: set_cursor
; 描述: 设置光标当前位置
; 参数: 
;   - %1: 光标位置的高八位
;   - %2: 光标位置的低八位
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib set_cursor
    arg uint8_t, high
    arg uint8_t, low

    ; 设置光标位置的高八位
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    
    mov al, high
    out dx, al

    ; 设置光标位置的低八位
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5

    mov al, low
    out dx, al
func_end

;-------------------------------------------------------------------------------
; 函数名: set_cursor_ex
; 描述: 设置光标当前坐标
; 参数: 
;   - %1: 光标的纵坐标
;   - %2: 光标的横坐标
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib set_cursor_ex
    arg uint8_t, row
    arg uint8_t, col

    movzx ax, byte row
    mov dl, 80
    mul dl

    movzx cx, byte col
    add cx, ax

    push_8 cl
    push_8 ch
    call_lib set_cursor
func_end