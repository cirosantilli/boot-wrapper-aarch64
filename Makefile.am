#
# Makefile.am - build a kernel+filesystem image for stand-alone Linux
# booting
#
# Copyright (C) 2012 ARM Limited. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.txt file.

# VE
PHYS_OFFSET	:= 0x80000000
UART_BASE	:= 0x1c090000
SYSREGS_BASE	:= 0x1c010000
GIC_DIST_BASE	:= 0x2c001000
GIC_CPU_BASE	:= 0x2c002000
CNTFRQ		:= 0x01800000	# 24Mhz
CPU_IDS		?= 0x0,0x1,0x2,0x3

DEFINES		= -DCNTFRQ=$(CNTFRQ)
DEFINES		+= -DCPU_IDS=$(CPU_IDS)
DEFINES		+= -DGIC_CPU_BASE=$(GIC_CPU_BASE)
DEFINES		+= -DGIC_DIST_BASE=$(GIC_DIST_BASE)
DEFINES		+= -DSYSREGS_BASE=$(SYSREGS_BASE)
DEFINES		+= -DUART_BASE=$(UART_BASE)

BOOTLOADER	:= boot.S

if PSCI
BOOTMETHOD	:= psci.o
else
BOOTMETHOD	:= spin.o
endif

MBOX_OFFSET	:= 0xfff8
KERNEL_OFFSET	:= 0x80000
LD_SCRIPT	:= model.lds.S
IMAGE		:= linux-system.axf

FS_OFFSET	:= 0x10000000
FILESYSTEM_START:= $(shell echo $$(($(PHYS_OFFSET) + $(FS_OFFSET))))
FILESYSTEM_SIZE	:= $(shell stat -Lc %s $(FILESYSTEM) 2>/dev/null || echo 0)
FILESYSTEM_END	:= $(shell echo $$(($(FILESYSTEM_START) + $(FILESYSTEM_SIZE))))

FDT_OFFSET	:= 0x08000000

if INITRD
INITRD_FLAGS	:= -DUSE_INITRD
CHOSEN_NODE	:= chosen {						\
			bootargs = \"$(CMDLINE)\";			\
			linux,initrd-start = <$(FILESYSTEM_START)>;	\
			linux,initrd-end = <$(FILESYSTEM_END)>;		\
		   };
else
INITRD_FLAGS	:=
CHOSEN_NODE	:= chosen {						\
			bootargs = \"$(CMDLINE)\";			\
		   };
endif

CPPFLAGS	+= $(INITRD_FLAGS)

all: $(IMAGE)

CLEANFILES = $(IMAGE) boot.o cache.o gic.o mmu.o ns.o $(BOOTMETHOD) model.lds fdt.dtb

$(IMAGE): boot.o cache.o gic.o mmu.o ns.o $(BOOTMETHOD) model.lds fdt.dtb $(KERNEL_IMAGE) $(FILESYSTEM)
	$(LD) -o $@ --script=model.lds

%.o: %.S Makefile
	$(CC) $(CPPFLAGS) $(CFLAGS) $(DEFINES) -c -o $@ $<

model.lds: $(LD_SCRIPT) Makefile
	$(CPP) $(CPPFLAGS) -ansi -DPHYS_OFFSET=$(PHYS_OFFSET) -DMBOX_OFFSET=$(MBOX_OFFSET) -DKERNEL_OFFSET=$(KERNEL_OFFSET) -DFDT_OFFSET=$(FDT_OFFSET) -DFS_OFFSET=$(FS_OFFSET) -DKERNEL=$(KERNEL_IMAGE) -DFILESYSTEM=$(FILESYSTEM) -DBOOTMETHOD=$(BOOTMETHOD) -P -C -o $@ $<

fdt.dtb: $(KERNEL_DTB) Makefile
	( $(DTC) -O dts -I dtb $(KERNEL_DTB) ; echo "/ { $(CHOSEN_NODE) };" ) | $(DTC) -O dtb -o $@ -

# The filesystem archive might not exist if INITRD is not being used
.PHONY: all clean $(FILESYSTEM)
