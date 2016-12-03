#-
# Copyright (c) 2007 Yahoo!, Inc.
# All rights reserved.
# Written by: John Baldwin <jhb@FreeBSD.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the author nor the names of any co-contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# From FreeBSD: head/sys/boot/i386/pmbr/pmbr.s 173957 2007-11-26 21:29:59Z jhb
#
# Partly from: src/sys/boot/i386/mbr/mbr.s 1.7

# A 512 byte PMBR boot manager that looks for a FreeBSD boot GPT partition
# and boots it.

		.set LOAD,0x7c00		# Load address
		.set EXEC,0x600 		# Execution address
		.set MAGIC,0xaa55		# Magic: bootable
		.set SECSIZE,0x200		# Size of a single disk sector
		.set DISKSIG,440		# Disk signature offset
		.set STACK,EXEC+SECSIZE*4	# Stack address
		.set GPT_ADDR,STACK		# GPT header address
		.set GPT_SIG,0
		.set GPT_SIG_0,0x20494645
		.set GPT_SIG_1,0x54524150
		.set GPT_MYLBA,24
		.set GPT_PART_LBA,72
		.set GPT_NPART,80
		.set GPT_PART_SIZE,84
		.set PART_ADDR,GPT_ADDR+SECSIZE	# GPT partition array address
		.set PART_TYPE,0
		.set PART_START_LBA,32
		.set PART_END_LBA,40

		.set NHRDRV,0x475		# Number of hard drives

		.globl start			# Entry point
		.code16

#
# Setup the segment registers for flat addressing and setup the stack.
#
start:		cld				# String ops inc
		xorw %ax,%ax			# Zero
		movw %ax,%es			# Address
		movw %ax,%ds			#  data
		movw %ax,%ss			# Set up
		movw $STACK,%sp			#  stack
#
# Relocate ourself to a lower address so that we have more room to load
# other sectors.
# 
		movw $main-EXEC+LOAD,%si	# Source
		movw $main,%di			# Destination
		movw $SECSIZE-(main-start),%cx	# Byte count
		rep				# Relocate
		movsb				#  code
#
# Jump to the relocated code.
#
		jmp main-LOAD+EXEC		# To relocated code

main:		movw $msg_datadisk,%si
		jmp putstr

#
# Output an ASCIZ string to the console via the BIOS.
# 
putstr.0:	movw $0x7,%bx	 		# Page:attribute
		movb $0xe,%ah			# BIOS: Display
		int $0x10			#  character
putstr: 	lodsb				# Get character
		testb %al,%al			# End of string?
		jnz putstr.0			# No
putstr.1:	jmp putstr.1			# Await reset

msg_datadisk:	.asciz "This is a NAS data disk and can not boot system.  System halted."

boot_uuid:	.long 0x83bd6b9d
		.word 0x7f41
		.word 0x11dc
		.byte 0xbe
		.byte 0x0b
		.byte 0x00
		.byte 0x15
		.byte 0x60
		.byte 0xb8
		.byte 0x4f
		.byte 0x0f

		.org DISKSIG,0x90
sig:		.long 0				# OS Disk Signature
		.word 0				# "Unknown" in PMBR

partbl: 	.fill 0x10,0x4,0x0		# Partition table
		.word MAGIC			# Magic number
