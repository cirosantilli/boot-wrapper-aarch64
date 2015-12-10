/*
 * model.lds.S - simple linker script for stand-alone Linux booting
 *
 * Copyright (C) 2012 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */

OUTPUT_FORMAT("elf64-littleaarch64")
OUTPUT_ARCH(aarch64)
TARGET(binary)

INPUT(KERNEL)
INPUT(./fdt.dtb)

#ifdef USE_INITRD
INPUT(FILESYSTEM)
#endif

ENTRY(_start)

SECTIONS
{
	/*
	 * Order matters: consume binary blobs first, so they won't appear in
	 * the boot section's *(.data)
	 */
	.kernel (PHYS_OFFSET + KERNEL_OFFSET): {
		kernel = .;
		KERNEL
	}

	.dtb (PHYS_OFFSET + FDT_OFFSET): {
		dtb = .;
		./fdt.dtb
	}

#ifdef USE_INITRD
	.filesystem (PHYS_OFFSET + FS_OFFSET): {
		filesystem = .;
		FILESYSTEM
		fs_size = . - filesystem;
	}
#endif

	.boot PHYS_OFFSET: {
		*(.init)
		*(.text* .data* .rodata* .bss* COMMON)
		*(.vectors)
		*(.stack)
	}

	.mbox (PHYS_OFFSET + MBOX_OFFSET): {
		mbox = .;
		QUAD(0x0)
	}
}
