{
    $Id$
    Copyright (c) 2002 by Florian Klaempfl

    Generates the argument location information for i386

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published bymethodpointer
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
{ Generates the argument location information for i386.
}
unit cpupara;

{$i fpcdefs.inc}

  interface

    uses
       cpubase,
       globtype,
       symtype,symdef,paramgr;

    type
       { Returns the location for the nr-st 32 Bit int parameter
         if every parameter before is an 32 Bit int parameter as well
         and if the calling conventions for the helper routines of the
         rtl are used.
       }
       ti386paramanager = class(tparamanager)
          function ret_in_acc(def : tdef;calloption : tproccalloption) : boolean;override;
          function ret_in_param(def : tdef;calloption : tproccalloption) : boolean;override;
          function push_addr_param(def : tdef;calloption : tproccalloption) : boolean;override;
          function getintparaloc(nr : longint) : tparalocation;override;
          procedure create_param_loc_info(p : tabstractprocdef);override;
          function getselflocation(p : tabstractprocdef) : tparalocation;override;
       end;

  implementation

    uses
       systems,verbose,
       symconst,
       cginfo;

    function ti386paramanager.ret_in_acc(def : tdef;calloption : tproccalloption) : boolean;
      begin
        { Win32 returns small records in the accumulator }
        if ((target_info.system=system_i386_win32) and
            (calloption=pocall_stdcall) and
            (def.deftype=recorddef) and (def.size<=8)) then
          result:=true
        else
          result:=inherited ret_in_acc(def,calloption);
      end;

    function ti386paramanager.ret_in_param(def : tdef;calloption : tproccalloption) : boolean;
      begin
        { Win32 returns small records in the accumulator }
        if ((target_info.system=system_i386_win32) and
            (calloption=pocall_stdcall) and
            (def.deftype=recorddef) and (def.size<=8)) then
          result:=false
        else
          result:=inherited ret_in_param(def,calloption);
      end;

    function ti386paramanager.push_addr_param(def : tdef;calloption : tproccalloption) : boolean;
      begin
        case target_info.system of
          system_i386_win32 :
            begin
              case def.deftype of
                recorddef :
                  begin
                    if (calloption=pocall_stdcall) and (def.size<=8) then
                     begin
                       result:=false;
                       exit;
                     end;
                  end;
                arraydef :
                  begin
                    if (tarraydef(def).highrange>=tarraydef(def).lowrange) and
                       (calloption in [pocall_cdecl,pocall_cppdecl]) then
                     begin
                       result:=false;
                       exit;
                     end;
                  end;
              end;
            end;
        end;
        result:=inherited push_addr_param(def,calloption);
      end;

    function ti386paramanager.getintparaloc(nr : longint) : tparalocation;
      begin
         getintparaloc.loc:=LOC_REFERENCE;
         getintparaloc.reference.index.enum:=R_EBP;
         getintparaloc.reference.offset:=4*nr;
      end;

    procedure ti386paramanager.create_param_loc_info(p : tabstractprocdef);
      begin
         { set default para_alignment to target_info.stackalignment }
         { if para_alignment=0 then
           para_alignment:=aktalignment.paraalign;
         }
      end;

    function ti386paramanager.getselflocation(p : tabstractprocdef) : tparalocation;
      begin
         getselflocation.loc:=LOC_REFERENCE;
         getselflocation.reference.index.enum:=R_ESP;
         getselflocation.reference.offset:=4;
      end;

begin
   paramanager:=ti386paramanager.create;
end.
{
  $Log$
  Revision 1.10  2003-04-22 23:50:23  peter
    * firstpass uses expectloc
    * checks if there are differences between the expectloc and
      location.loc from secondpass in EXTDEBUG

  Revision 1.9  2003/04/22 14:33:38  peter
    * removed some notes/hints

  Revision 1.8  2003/01/08 18:43:57  daniel
   * Tregister changed into a record

  Revision 1.7  2002/12/24 15:56:50  peter
    * stackpointer_alloc added for adjusting ESP. Win32 needs
      this for the pageprotection

  Revision 1.6  2002/12/17 22:19:33  peter
    * fixed pushing of records>8 bytes with stdcall
    * simplified hightree loading

  Revision 1.5  2002/11/18 17:32:00  peter
    * pass proccalloption to ret_in_xxx and push_xxx functions

  Revision 1.4  2002/11/15 01:58:56  peter
    * merged changes from 1.0.7 up to 04-11
      - -V option for generating bug report tracing
      - more tracing for option parsing
      - errors for cdecl and high()
      - win32 import stabs
      - win32 records<=8 are returned in eax:edx (turned off by default)
      - heaptrc update
      - more info for temp management in .s file with EXTDEBUG

  Revision 1.3  2002/08/09 07:33:04  florian
    * a couple of interface related fixes

  Revision 1.2  2002/07/11 14:41:32  florian
    * start of the new generic parameter handling

  Revision 1.1  2002/07/07 09:52:33  florian
    * powerpc target fixed, very simple units can be compiled
    * some basic stuff for better callparanode handling, far from being finished

}
