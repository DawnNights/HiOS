%include "include/stdio.inc"
%include "include/stdlib.inc"

[bits 32]


func _start
    set_cursor_ex(0, 0)
    uint32_t my_var, 0x12abcdef
    printf(\
        "str: %s\nint: %d\nunsigned int: %u\nlower hex: %x\nupper hex: %X\npointer: %p",\
        "DawnNights",\
        -1234567,\
        12345678,\
        my_var,\
        my_var,\
        @my_var\
    )
    jmp $
func_end