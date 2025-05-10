%include "include/system/primary.inc"

[bits 16]
section .text vstart=0x7c00
    ; ---------- 寄存器初始化 ----------
    mov ax, 0
    mov cx, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov sp, 0x7c00

    ; ---------- 调用中断清屏 ----------
    mov ah, 0x06    ; 上卷功能
    mov al, 0x00    ; 上卷行数, 为0则表示全部
    mov bh, 0x07    ; 上卷行属性

    ; 左上角x, y坐标均为0
    mov ch, 0
    mov cl, 0

    ; 右下角坐标为(80, 25)
    mov dh, 24
    mov dl, 79

    ; 调用中断
    int 0x10

    ; ---------- 将loader读入内存 ----------
    mov eax, 0x01   ; loader所在的LBA扇区号

    mov dx, PRIMARY_LBA_LOW
    out dx, al
    
    mov dx, PRIMARY_LBA_MID
    shr eax, 8
    out dx, al

    mov dx, PRIMARY_LBA_HIGH
    shr eax, 8
    out dx, al

    mov dx, PRIMARY_DEVICE
    shr eax, 8
    and al, 00001111b   ; 27~24位写入 divice 寄存器第四位
    or al, 11100000b    ; 设置高4位为0代表主盘, LBA模式
    out dx, al

    ; 向命令端口写入读命令让硬盘执行
    mov dx, PRIMARY_COMMAND
    mov al, 0x20    ; read sector, 即读扇区
    out dx, al

    ; 检测硬盘状态
    mov dx, PRIMARY_STATUS
    .not_ready:
        nop ; 空操作, 消耗一条指令周期(即等待时间)

        in al, dx
        and al, 10001000b   ; 保留第 3 位和第 7 位
        cmp al, 00001000b   ; BSY 位为 0 且 data_request 位为 1 则准备完成
        jnz .not_ready      ; 若结果不等, 则跳转回去继续等待
    
    ; 从数据端口中读取数据
    mov ax, 4   ; loader 所占的扇区数
    mov dx, 256 ; 一个扇区512字节, 一次一个字, 所以每个扇区读 512/2 次
    mul dx

    mov cx, ax
    mov dx, PRIMARY_SECTOR_DATA
    mov bx, 0x500   ; 放在实模式可用区域0x500-0x7BFF中
    .go_on_read:
        in ax, dx
        mov [bx], ax
        add bx, 2
        loop .go_on_read
    jmp 0x500   ; 跳转至 loader 执行

    ; mbr 尾部填充及协议魔数
    times 510-($-$$) db 0
    db 0x55, 0xaa