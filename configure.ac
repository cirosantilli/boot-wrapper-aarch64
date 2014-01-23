# configure.ac - autoconf script for the AArch64 bootwrapper
#
# Copyright (c) 2014 ARM Limited. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can
# be found in the LICENSE.txt file.

AC_INIT([aarch64-boot-wrapper], [v0.1])

# Ensure that we're using an AArch64 compiler
AC_CANONICAL_SYSTEM

if test "x$host_cpu" != "xaarch64"; then
	AC_MSG_ERROR([The boot-wrapper can only be used with an AArch64 compiler.])
fi

AM_INIT_AUTOMAKE([foreign])

# Allow a user to pass --with-kernel-dir
AC_ARG_WITH([kernel-dir],
	AS_HELP_STRING([--with-kernel-dir], [specify the root Linux kernel build directory (required)]),
	AC_SUBST([KERN_DIR], [$withval]),
	AC_MSG_ERROR([No kernel directory specified. Use --with-kernel-dir]))
KERN_IMAGE=/arch/arm64/boot/Image
KERN_DTB=/arch/arm64/boot/dts/rtsm_ve-aemv8a.dtb

# Ensure that the user has provided us with a sane kernel dir.
m4_define([CHECKFILES], [KERN_DIR,
	KERN_DIR$KERN_DTB,
	KERN_DIR$KERN_IMAGE])

m4_foreach([checkfile], [CHECKFILES],
	[AC_CHECK_FILE([$checkfile], [], AC_MSG_ERROR([No such file or directory: $checkfile]))])

AC_SUBST([KERNEL_IMAGE], [$KERN_DIR$KERN_IMAGE])
AC_SUBST([KERNEL_DTB], [$KERN_DIR$KERN_DTB])

# Allow a user to pass --enable-psci
USE_PSCI=no
AC_ARG_ENABLE([psci],
	AS_HELP_STRING([--enable-psci], [enable the psci boot method]),
	[USE_PSCI=yes],
	[USE_PSCI=no])
AM_CONDITIONAL([PSCI], [test "x$USE_PSCI" = "xyes"])


# Allow a user to pass --with-initrd
AC_ARG_WITH([initrd],
	AS_HELP_STRING([--with-initrd], [embed an initrd in the kernel image]),
	USE_INITRD=$withval)
AC_SUBST([FILESYSTEM], [$USE_INITRD])
AM_CONDITIONAL([INITRD], [test "x$USE_INITRD" != "x"])

C_CMDLINE="console=ttyAMA0 earlyprintk=pl011,0x1c090000"
AC_ARG_WITH([cmdline],
	AS_HELP_STRING([--with-cmdline], [set a command line for the kernel]),
	[C_CMDLINE=$withval])
AC_SUBST([CMDLINE], [$C_CMDLINE])

# Ensure that we have all the needed programs
AC_PROG_CC
AC_PROG_CPP
AM_PROG_AS
AC_PROG_SED
AC_PROG_LN_S
AC_PATH_PROG([DTC], dtc, error, [$PATH$PATH_SEPARATOR$KERN_DIR/scripts/dtc])
if test "x$DTC" = "xerror"; then
	AC_MSG_ERROR([cannot find the device tree compiler (dtc)])
fi
AC_CHECK_TOOL(LD, ld)

AC_CONFIG_FILES([Makefile])

AC_OUTPUT

# Print the final config to the user.
echo ""
echo "  Boot wrapper configuration"
echo "  =========================="
echo ""
echo "  Linux kernel build dir:            ${KERN_DIR}"
echo "  Linux kernel command line:         ${CMDLINE}"
echo "  Embedded initrd:                   ${FILESYSTEM:-NONE}"
echo "  Use PSCI?                          ${USE_PSCI}"
echo ""
