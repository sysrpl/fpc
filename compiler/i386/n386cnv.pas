{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl

    Generate i386 assembler for type converting nodes

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
unit n386cnv;

{$i fpcdefs.inc}

interface

    uses
      node,ncgcnv,defutil,defcmp,nx86cnv;

    type
       ti386typeconvnode = class(tx86typeconvnode)
         protected
         { procedure second_int_to_int;override; }
         { procedure second_string_to_string;override; }
         { procedure second_cstring_to_pchar;override; }
         { procedure second_string_to_chararray;override; }
         { procedure second_array_to_pointer;override; }
         { procedure second_pointer_to_array;override; }
         { procedure second_chararray_to_string;override; }
         { procedure second_char_to_string;override; }
         { function first_int_to_real: tnode; override; }
         { procedure second_int_to_real;override; }
         { procedure second_real_to_real;override; }
         { procedure second_cord_to_pointer;override; }
         { procedure second_proc_to_procvar;override; }
         { procedure second_bool_to_int;override; }
         { procedure second_int_to_bool;override; }
         { procedure second_load_smallset;override;  }
         { procedure second_ansistring_to_pchar;override; }
         { procedure second_pchar_to_string;override; }
         { procedure second_class_to_intf;override;  }
         { procedure second_char_to_char;override; }
       end;


implementation

   uses
      verbose,systems,
      symconst,symdef,aasmbase,aasmtai,aasmcpu,
      cgbase,
      ncon,ncal,ncnv,
      cpubase,tgobj,
      cgobj,cga,cgx86,ncgutil;


begin
   ctypeconvnode:=ti386typeconvnode;
end.
{
  $Log$
  Revision 1.73  2004-06-20 08:55:31  florian
    * logs truncated

  Revision 1.72  2004/02/05 01:24:08  florian
    * several fixes to compile x86-64 system

}
