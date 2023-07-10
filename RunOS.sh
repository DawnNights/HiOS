if [[ -f "builds/virtual_disk.lock" ]]; then
    # 删除因强退而没有清理的锁文件
    rm builds/virtual_disk.lock
fi

make
bochs -f builds/bochsrc
