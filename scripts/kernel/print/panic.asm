%include "include/stdio.inc"
%include "include/stdlib.inc"
%include "include/string.inc"

[bits 32]
;-------------------------------------------------------------------------------
; 函数名: panic
; 描述: 异常输出函数
; 参数: 
;   - %1: 异常所在的文件
;   - %2: 异常所在的行号
;   - %1: 发生异常的函数名
;   - %2: 异常的提示信息
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib panic
    arg pointer_t, file
    arg uint32_t,  line
    arg pointer_t, name
    arg pointer_t, error
    
    set_text_attr(FALSE, BLACK, RED)
    printf(\
        "\n\n!! ERROR TRACE !!\n| File: %s\n| Line: %d\n| Function: <%s>\n\n  %s\n\n",\
        file,\
        line,\
        name,\
        error\
    )

    strlen(error)
    lea ecx, [eax+4]

    under_loop:
        put_char("^")
        loop under_loop

    set_text_attr(FALSE, BLACK, LIGHT_WHITE)
func_end
