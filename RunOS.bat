@echo off

REM 检查 virtual_disk 是否存在，若不存在则生成
if not exist "builds\virtual_disk" (
    bximage -hd -mode="flat" -size=60 -q builds\virtual_disk
)

REM 删除残留的锁文件（如果存在）
if exist "builds\virtual_disk.lock" (
    del "builds\virtual_disk.lock"
)

REM 编译并运行 Bochs
make
bochsdbg -f builds\bochsrc.bxrc
