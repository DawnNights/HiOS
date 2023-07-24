%include "include/stdio.inc"

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
    
    printf(\
        "\n\nAn error occurred while system was running\n  File %s, line %d, in <%s>\n%s",\
        file,\
        line,\
        name,\
        error\
    )
func_end