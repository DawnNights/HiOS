%include "include/string.inc"
%include "include/bitmap.inc"

;-------------------------------------------------------------------------------
; 函数名: bitmap_empty
; 描述: 将位图所占的数据块清零
; 参数: 
;   - %1: 指向位图的指针
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib bitmap_empty
    arg pointer_t, btmp
    
    mov esi, btmp
    memset([esi + BitMap.BitPointer], 0, [esi + BitMap.ByteSize])
func_end

;-------------------------------------------------------------------------------
; 函数名: bitmap_get
; 描述: 获取位图指定下标bit位的状态
; 参数: 
;   - %1: 指向位图的指针
;   - %2: 指定bit位的下标
; 返回值: bit位的状态(0或1)
;-------------------------------------------------------------------------------
func_lib bitmap_get
    ; 取消宏定义防止变量名冲突
    %undef btmp

    ; 声明函数传参
    arg pointer_t, btmp
    arg uint32_t, bit_idx

    ; 声明临时变量
    uint32_t byte_idx, 0
    uint8_t bit_odd, 0
    
    ; byte_idx = bit_idx / 8
    ; bit_odd = bit_idx % 8
    mov eax, bit_idx
    mov ebx, 8
    xor edx, edx
    div ebx

    mov byte_idx, eax
    mov bit_odd, dl

    ; 此时bl为指定下标bit位所在的byte的值
    mov esi, btmp
    mov edi, [esi + BitMap.BitPointer]

    add edi, byte_idx
    mov bl, byte [edi]

    ; 通过位运算清零其它下标bit位的值
    mov cl, bit_odd

    mov dl, 1
    shl dl, cl

    and bl, dl

    ; 判断此时bl是否为 0
    cmp bl, 0
    jz is_zero

    is_one:
        return_8 1

    is_zero:
        return_8 0
func_end

;-------------------------------------------------------------------------------
; 函数名: bitmap_set
; 描述: 设置位图指定下标bit位的状态
; 参数: 
;   - %1: 指向位图的指针
;   - %2: 指定bit位的下标
;   - %3: bit位的状态(0或1)
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib bitmap_set
    ; 取消宏定义防止变量名冲突
    %undef btmp 
    %undef bit_idx
    %undef byte_idx
    %undef bit_odd
    
    ; 声明函数传参
    arg pointer_t, btmp
    arg uint32_t, bit_idx
    arg uint8_t, state

    ; 声明临时变量
    uint32_t byte_idx, 0
    bool_t bit_odd, FALSE

    ; byte_idx = bit_idx / 8
    ; bit_odd = bit_idx % 8
    mov eax, bit_idx
    mov ebx, 8
    xor edx, edx
    div ebx

    mov byte_idx, eax
    mov bit_odd, dl

    ; 此时bl为指定下标bit位所在的byte的值
    mov esi, btmp
    mov edi, [esi + BitMap.BitPointer]

    add edi, byte_idx
    mov bl, byte [edi]

    ; 通过位运算设置指定下标bit位的值
    mov cl, bit_odd

    cmp state, byte 0
    je set_zero
    jmp set_one
    
    set_zero:
        mov dl, 0
        jmp set_end
    
    set_one:
        mov dl, 1

    set_end:    
        shl dl, cl
        or bl, dl
    mov [edi], byte bl
func_end

;-------------------------------------------------------------------------------
; 函数名: bitmap_scan
; 描述: 在位图中申请连续长度的bit位, 成功返回起下标, 失败则返回 -1
; 参数: 
;   - %1: 指向位图的指针
;   - %2: 要申请的可用bit位的长度
; 返回值: 无
;-------------------------------------------------------------------------------
func_lib bitmap_scan
    ; 取消宏定义防止变量名冲突
    %undef btmp
    %undef bit_idx
    %undef byte_idx
    
    ; 声明函数传参
    arg pointer_t, btmp
    arg uint32_t, count

    ; 声明临时变量
    uint32_t byte_idx, 0
    uint32_t bit_idx, 0

    ; 遍历字节跳过非空闲字节
    mov esi, btmp
    mov ecx, [esi + BitMap.ByteSize]
    mov edi, [esi + BitMap.BitPointer]

    is_full_loop:
        mov dl, byte [edi]
        cmp dl, 11111111b
        jne is_byte_free

        inc edi
        inc dword byte_idx

        cmp byte_idx, ecx
        jae is_all_full

        jmp is_full_loop

    is_all_full:
        return_32 -1
    
    is_byte_free:
        mov eax, byte_idx
        shl eax, 3  ; eax * 8
        mov bit_idx, eax
    
    fetch_bits_init:
        uint32_t bit_count, 0
        uint32_t fetch_times, 0
        uint32_t next_idx, bit_idx

        ; fetch_times = btmp.ByteSize * 8 - bit_idx
        mov eax, [esi + BitMap.ByteSize]
        shl eax, 3  ; eax * 8
        sub eax, bit_idx
        mov fetch_times, eax

        mov bit_idx, dword -1
        mov ecx, count
    
    fetch_bits_loop:
        cmp fetch_times, dword 0
        je fetch_bits_done

        ; 调用 bitmap_get 函数
        push dword next_idx
        push dword btmp
        call_lib bitmap_get

        ; 若结果不为0则表示该bit位被占用
        cmp eax, 0
        jne bit_used

        inc dword bit_count
        cmp bit_count, ecx
        je bit_enough

        jmp fetch_bits_continue
        
        bit_used:
            mov bit_count, dword 0
            jmp fetch_bits_continue

        bit_enough:
            inc dword next_idx
            sub next_idx, ecx

            mov ecx, next_idx
            mov bit_idx, ecx

            jmp fetch_bits_done

    fetch_bits_continue:
        inc dword next_idx
        dec dword fetch_times
        
        cmp fetch_times, dword 0
        je fetch_bits_done
        jmp fetch_bits_loop

    fetch_bits_done: return_32 bit_idx
func_end