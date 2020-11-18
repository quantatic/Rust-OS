arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso

target ?= $(arch)-os
rust_os := build/libos.a

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

.PHONY: all clean run iso
.FORCE:

all: $(kernel)

clean:
	rm -r build
	xargo clean

run: $(iso)
	qemu-system-x86_64 -cdrom $(iso)

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	mkdir -p build/isofiles/boot/grub
	cp $(kernel) build/isofiles/boot/kernel.bin
	cp $(grub_cfg) build/isofiles/boot/grub
	grub-mkrescue -o $(iso) build/isofiles
	rm -r build/isofiles

$(rust_os): .FORCE
	mkdir -p build/
	RUST_TARGET_PATH=$(CURDIR) xargo rustc --target $(target) -- --emit link=$@

$(kernel): $(rust_os) $(assembly_object_files) $(linker_script)
	ld -n -T $(linker_script) -o $(kernel) $(assembly_object_files) $(rust_os)

build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	mkdir -p $(dir $@)
	nasm -felf64 $< -o $@ -Werror
