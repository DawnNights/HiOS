# ----------定义全局变量 ----------

dir_src = ./scripts
dir_bin = ./builds/binary
dir_obj = ./builds/object
virtual_disk = ./builds/virtual_disk

# ---------- 定义引导相关 ----------

sector_bin = $(dir_bin)/sector.bin
sector_src = $(dir_src)/boot/sector.asm

loader_bin = $(dir_bin)/loader.bin
loader_src = $(dir_src)/boot/loader.asm

# ---------- 定义内核相关 ----------

kernel_bin = $(dir_bin)/kernel.bin
kernel_srcs = $(dir_src)/main.asm \
	$(wildcard $(dir_src)/interrupt/*.asm) \
	$(wildcard $(dir_src)/device/*.asm) \
	$(wildcard $(dir_src)/libarys/*.asm) \
	$(wildcard $(dir_src)/libarys/print/*.asm) \
	$(wildcard $(dir_src)/libarys/memory/*.asm)

# ---------- 编译执行流程 ----------

# 写入虚拟硬盘
all: $(sector_bin) $(loader_bin) $(kernel_bin)
	dd if=$(sector_bin) of=$(virtual_disk) bs=512 count=1 conv=notrunc
	dd if=$(loader_bin) of=$(virtual_disk) bs=512 count=4 seek=1 conv=notrunc
	dd if=$(kernel_bin) of=$(virtual_disk) bs=512 count=200 seek=5 conv=notrunc

# 编译主引导程序
$(sector_bin): $(sector_src)
	nasm -f bin -o $(sector_bin) $(sector_src)

# 编译内核加载器
$(loader_bin): $(loader_src)
	nasm -f bin -o $(loader_bin) $(loader_src)

# 编译内核及依赖
kernel_objs = $(foreach src, $(kernel_srcs), $(dir_obj)/$(notdir $(patsubst %/,%, $(dir $(src))))_$(basename $(notdir $(src))).obj)

$(kernel_objs): $(kernel_srcs)
	$(foreach src,$(kernel_srcs), \
		{ \
			nasm -f elf32 $(src) -o $(dir_obj)/$(notdir $(patsubst %/,%, $(dir $(src))))_$(basename $(notdir $(src))).obj; \
		}; \
	)

$(kernel_bin): $(kernel_objs)
	ld -m elf_i386 -Od -Ttext 0xc0000d00 --oformat binary -o $(kernel_bin) $(kernel_objs)