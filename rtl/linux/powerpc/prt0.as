/* Startup code for programs linked with GNU libc.
   Copyright (C) 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <sysdep.h>
#include "bp-sym.h"

 /* These are the various addresses we require.  */
	.section ".rodata"
	.align	2
	weak_extern(_init)
	weak_extern(_fini)
L(start_addresses):
	.long	_SDA_BASE_
	.long	JUMPTARGET(BP_SYM (main))
	.long 	JUMPTARGET(_init)
	.long 	JUMPTARGET(_fini)
	ASM_SIZE_DIRECTIVE(L(start_addresses))

	.section ".text"
ENTRY(_start)
 /* Save the stack pointer, in case we're statically linked under Linux.  */
	mr	r9,r1
 /* Set up an initial stack frame, and clear the LR.  */
	clrrwi	r1,r1,4
	li	r0,0
	stwu	r1,-16(r1)
	mtlr	r0
	stw	r0,0(r1)
 /* Set r13 to point at the 'small data area', and put the address of
    start_addresses in r8...  */
	lis	r8,L(start_addresses)@ha
	lwzu	r13,L(start_addresses)@l(r8)
 /* and continue in libc-start, in glibc.  */
	b	JUMPTARGET(BP_SYM (__libc_start_main))
END(_start)

/* Define a symbol for the first piece of initialized data.  */
	.section ".data"
	.globl	__data_start
__data_start:
weak_alias (__data_start, data_start)
/*
  $Log$
  Revision 1.2  2002-07-26 17:09:44  florian
    * log fixed

  Revision 1.1  2002/07/26 16:57:40  florian
    + initial version, plain copy from glibc/sysdeps/powerpc/elf/start.S
*/

