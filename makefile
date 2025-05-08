ld = i686-elf-ld
clear_cmd = del /S /Q .\*.o .\*.bin 2>NUL || (exit 0)

# ---------- 写入虚拟硬盘 ----------
sector_bin = builds/boot/sector.bin
loader_bin = builds/boot/loader.bin
kernel_bin = builds/kernel/kernel.bin

virtual_disk = builds/virtual_disk
$(virtual_disk): $(sector_bin) $(loader_bin) $(kernel_bin)
	dd if=$(sector_bin) of=$(virtual_disk) bs=512 count=1 conv=notrunc
	dd if=$(loader_bin) of=$(virtual_disk) bs=512 count=4 seek=1 conv=notrunc
	dd if=$(kernel_bin) of=$(virtual_disk) bs=512 count=200 seek=5 conv=notrunc

# ---------- 编译引导相关 ----------
sector_src = scripts/boot/sector.asm
loader_src = scripts/boot/loader.asm

$(sector_bin): $(sector_src)
	nasm -f bin -o $(sector_bin) $(sector_src)

$(loader_bin): $(loader_src)
	nasm -f bin -o $(loader_bin) $(loader_src)

# ---------- 编译内核相关 ----------
kernel_srcs := $(wildcard scripts/kernel/*.asm scripts/kernel/**/*.asm)
kernel_objs = $(patsubst scripts/kernel/%.asm,builds/kernel/%.o,$(kernel_srcs))

$(kernel_bin): $(kernel_objs)
	$(ld) -m elf_i386 -Od -Ttext 0xc0000d00 --oformat binary -o $(kernel_bin) $(kernel_objs)

# ---------- 清理相关文件 ----------
clear:
	@$(clear_cmd)

# 内核入口
in_dir = scripts/kernel
out_dir = builds/kernel

target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	nasm -f elf32 -w-all $< -o $@

# 中断相关
in_dir = scripts/kernel/interrupt
out_dir = builds/kernel/interrupt


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	nasm -f elf32 -w-all $< -o $@

# 内存相关
in_dir = scripts/kernel/memory
out_dir = builds/kernel/memory


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	nasm -f elf32 -w-all $< -o $@

# 打印相关
in_dir = scripts/kernel/print
out_dir = builds/kernel/print


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	nasm -f elf32 -w-all $< -o $@

# 线程相关
in_dir = scripts/kernel/thread
out_dir = builds/kernel/thread


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	nasm -f elf32 -w-all $< -o $@

# 其它相关
in_dir = scripts/kernel/utils
out_dir = builds/kernel/utils


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	nasm -f elf32 -w-all $< -o $@
