{
    $Id$
    Copyright (c) 1998-2003 by Jonas Maebe

    This unit implements the generic implementation of optimized nodes

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
unit ncgopt;

{$i fpcdefs.inc}

interface
uses node, nopt;

type
  tcgaddsstringcharoptnode = class(taddsstringcharoptnode)
     function det_resulttype: tnode; override;
     function pass_1: tnode; override;
     procedure pass_2; override;
  end;


implementation

uses
  globtype,
  pass_1,defutil,htypechk,
  symdef,paramgr,
  aasmbase,aasmtai,
  ncnv, ncon, pass_2,
  cginfo, cgbase, cpubase,
  tgobj, rgobj, cgobj, ncgutil;


{*****************************************************************************
                             TCGADDOPTNODE
*****************************************************************************}

function tcgaddsstringcharoptnode.det_resulttype: tnode;
begin
  det_resulttype := nil;
  resulttypepass(left);
  resulttypepass(right);
  if codegenerror then
    exit;
  { update the curmaxlen field (before converting to a string!) }
  updatecurmaxlen;
  if not is_shortstring(left.resulttype.def) then
    inserttypeconv(left,cshortstringtype);
  resulttype:=left.resulttype;
end;


function tcgaddsstringcharoptnode.pass_1: tnode;
begin
  pass_1 := nil;
  firstpass(left);
  firstpass(right);
  if codegenerror then
    exit;
  expectloc:=LOC_REFERENCE;
  if not is_constcharnode(right) then
    { it's not sure we need the register, but we can't know it here yet }
    calcregisters(self,2,0,0)
  else
    calcregisters(self,1,0,0);
end;


procedure tcgaddsstringcharoptnode.pass_2;
var
  l: tasmlabel;
  href,href2 :  treference;
  hreg, lengthreg: tregister;
  checklength: boolean;
  len : integer;
begin
  { first, we have to more or less replicate some code from }
  { ti386addnode.pass_2                                     }
  secondpass(left);
  if not(tg.istemp(left.location.reference) and
         (tg.sizeoftemp(exprasmlist,left.location.reference) = 256)) and
     not(nf_use_strconcat in flags) then
    begin
       tg.Gettemp(exprasmlist,256,tt_normal,href);
       cg.g_copyshortstring(exprasmlist,left.location.reference,href,255,true,false);
       { location is released by copyshortstring }
       location_freetemp(exprasmlist,left.location);
       { return temp reference }
       location_reset(left.location,LOC_REFERENCE,def_cgsize(resulttype.def));
       left.location.reference:=href;
    end;
  secondpass(right);
  { special case for string := string + char (JM) }
  hreg.enum:=R_INTREGISTER;
  hreg.number:=NR_NO;

  { we have to load the char before checking the length, because we }
  { may need registers from the reference                           }

  { is it a constant char? }
  if not is_constcharnode(right) then
    { no, make sure it is in a register }
    if right.location.loc in [LOC_REFERENCE,LOC_CREFERENCE] then
      begin
        { free the registers of right }
        reference_release(exprasmlist,right.location.reference);
        { get register for the char }
        hreg := rg.getregisterint(exprasmlist,OS_8);
        cg.a_load_ref_reg(exprasmlist,OS_8,OS_8,right.location.reference,hreg);
        { I don't think a temp char exists, but it won't hurt (JM) }
        tg.ungetiftemp(exprasmlist,right.location.reference);
      end
    else hreg := right.location.register;

  { load the current string length }
  lengthreg := rg.getregisterint(exprasmlist,OS_INT);
  cg.a_load_ref_reg(exprasmlist,OS_8,OS_INT,left.location.reference,lengthreg);

  { do we have to check the length ? }
  if tg.istemp(left.location.reference) then
    checklength := curmaxlen = 255
  else
    checklength := curmaxlen >= tstringdef(left.resulttype.def).len;
  if checklength then
    begin
      { is it already maximal? }
      objectlibrary.getlabel(l);
      if tg.istemp(left.location.reference) then
        len:=255
      else
        len:=tstringdef(left.resulttype.def).len;
      cg.a_cmp_const_reg_label(exprasmlist,OS_INT,OC_EQ,len,lengthreg,l)
    end;

  { no, so increase the length and add the new character }
  href2 := left.location.reference;

  { we need a new reference to store the character }
  { at the end of the string. Check if the base or }
  { index register is still free                   }
  if (href2.base.number <> NR_NO) and
     (href2.index.number <> NR_NO) then
    begin
      { they're not free, so add the base reg to       }
      { the string length (since the index can         }
      { have a scalefactor) and use lengthreg as base  }
      cg.a_op_reg_reg(exprasmlist,OP_ADD,OS_INT,href2.base,lengthreg);
      href2.base := lengthreg;
    end
  else
    { at least one is still free, so put EDI there }
    if href2.base.number = NR_NO then
      href2.base := lengthreg
    else
      begin
        href2.index := lengthreg;
{$ifdef i386}
        href2.scalefactor := 1;
{$endif i386}
      end;
  { we need to be one position after the last char }
  inc(href2.offset);
  { store the character at the end of the string }
  if (right.nodetype <> ordconstn) then
    begin
      { no new_reference(href2) because it's only }
      { used once (JM)                            }
      cg.a_load_reg_ref(exprasmlist,OS_8,OS_8,hreg,href2);
      rg.ungetregisterint(exprasmlist,hreg);
    end
  else
    cg.a_load_const_ref(exprasmlist,OS_8,tordconstnode(right).value,href2);
  lengthreg.number:=(lengthreg.number and not $ff) or R_SUBL;
  { increase the string length }
  cg.a_op_const_reg(exprasmlist,OP_ADD,OS_8,1,lengthreg);
  cg.a_load_reg_ref(exprasmlist,OS_8,OS_8,lengthreg,left.location.reference);
  rg.ungetregisterint(exprasmlist,lengthreg);
  if checklength then
    cg.a_label(exprasmlist,l);
  location_copy(location,left.location);
end;

begin
  caddsstringcharoptnode := tcgaddsstringcharoptnode;
end.

{
  $Log$
  Revision 1.6  2003-06-03 21:11:09  peter
    * cg.a_load_* get a from and to size specifier
    * makeregsize only accepts newregister
    * i386 uses generic tcgnotnode,tcgunaryminus

  Revision 1.5  2003/06/03 13:01:59  daniel
    * Register allocator finished

  Revision 1.4  2003/06/01 21:38:06  peter
    * getregisterfpu size parameter added
    * op_const_reg size parameter added
    * sparc updates

  Revision 1.3  2003/05/26 21:15:18  peter
    * disable string node optimizations for the moment

  Revision 1.2  2003/04/26 09:12:55  peter
    * add string returns in LOC_REFERENCE

  Revision 1.1  2003/04/24 11:20:06  florian
    + created from n386opt
}
