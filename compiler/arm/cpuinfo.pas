{
    $Id$
    Copyright (c) 1998-2002 by the Free Pascal development team

    Basic Processor information for the ARM

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

Unit CPUInfo;

Interface

  uses
    globtype;

Type
   bestreal = double;
   ts32real = single;
   ts64real = double;
   ts80real = type extended;
   ts128real = type extended;
   ts64comp = comp;

   pbestreal=^bestreal;

   { possible supported processors for this target }
   tprocessors =
      (no_processor,
       armv3,
       armv4,
       armv5
      );

   tfputype =
     (no_fpuprocessor,
      fpu_soft,
      fpu_libgcc,
      fpu_fpa,
      fpu_fpa10,
      fpu_fpa11,
      fpu_vfp
     );

Const
   {# Size of native extended floating point type }
   extended_size = 8;
   {# Size of a multimedia register               }
   mmreg_size = 16;
   { target cpu string (used by compiler options) }
   target_cpu_string = 'arm';
   { size of the buffer used for setjump/longjmp
     the size of this buffer is deduced from the
     jmp_buf structure in setjumph.inc file
   }
   { for linux: }
   jmp_buf_size = 220; { according to sizeof(jmp_buf) on my Zaurus (FK) }

   { calling conventions supported by the code generator }
   supported_calling_conventions : tproccalloptions = [
     pocall_internproc,
     pocall_compilerproc,
     pocall_inline,
     pocall_stdcall,
     { same as stdcall only different name mangling }
     pocall_cdecl,
     { same as stdcall only different name mangling }
     pocall_cppdecl,
     { same as stdcall but floating point numbers are handled like equal sized integers }
     pocall_softfloat
   ];

   processorsstr : array[tprocessors] of string[5] = ('',
     'ARMV3',
     'ARMV4',
     'ARMV5'
   );

   fputypestr : array[tfputype] of string[6] = ('',
     'SOFT',
     'LIBGCC',
     'FPA',
     'FPA10',
     'FPA11',
     'VFP'
   );


Implementation

end.
{
  $Log$
  Revision 1.9  2004-06-20 08:55:31  florian
    * logs truncated

  Revision 1.8  2004/06/16 20:07:10  florian
    * dwarf branch merged

  Revision 1.7  2004/04/28 15:19:03  florian
    + syscall directive support for MorphOS added

  Revision 1.6.2.1  2004/05/01 16:02:10  peter
    * POINTER_SIZE replaced with sizeof(aint)
    * aint,aword,tconst*int moved to globtype

  Revision 1.6  2004/03/06 20:35:19  florian
    * fixed arm compilation
    * cleaned up code generation for exported linux procedures

}
