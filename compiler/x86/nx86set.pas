{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl

    Generate x86 assembler for in/case nodes

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
unit nx86set;

{$i fpcdefs.inc}

interface

    uses
       node,nset,pass_1,ncgset;

    type

       tx86innode = class(tinnode)
          procedure pass_2;override;
          function pass_1 : tnode;override;
       end;


implementation

    uses
      globtype,systems,
      verbose,globals,
      symconst,symdef,defutil,
      aasmbase,aasmtai,aasmcpu,
      cgbase,pass_2,
      ncon,
      cpubase,cpuinfo,procinfo,
      cga,cgutils,cgobj,ncgutil,
      cgx86;

{*****************************************************************************
                              TX86INNODE
*****************************************************************************}

    function tx86innode.pass_1 : tnode;
      begin
         result:=nil;
         { this is the only difference from the generic version }
         expectloc:=LOC_FLAGS;

         firstpass(right);
         firstpass(left);
         if codegenerror then
           exit;

         left_right_max;
         { a smallset needs maybe an misc. register }
         if (left.nodetype<>ordconstn) and
            not(right.location.loc in [LOC_CREGISTER,LOC_REGISTER]) and
            (right.registersint<1) then
           inc(registersint);
      end;



    procedure tx86innode.pass_2;
       type
         Tsetpart=record
           range : boolean;      {Part is a range.}
           start,stop : byte;    {Start/stop when range; Stop=element when an element.}
         end;
       var
         genjumps,
         use_small,
         ranges     : boolean;
         hr,hr2,
         pleftreg   : tregister;
         href       : treference;
         opsize     : tcgsize;
         setparts   : array[1..8] of Tsetpart;
         i,numparts : byte;
         adjustment : longint;
         l,l2       : tasmlabel;
         r          : Tregister;
{$ifdef CORRECT_SET_IN_FPC}
         AM         : tasmop;
{$endif CORRECT_SET_IN_FPC}

         function analizeset(Aset:pconstset;is_small:boolean):boolean;
           var
             compares,maxcompares:word;
             i:byte;
           begin
             if tnormalset(Aset^)=[] then
                {The expression...
                    if expr in []
                 ...is allways false. It should be optimized away in the
                 resulttype pass, and thus never occur here. Since we
                 do generate wrong code for it, do internalerror.}
                internalerror(2002072301);
             analizeset:=false;
             ranges:=false;
             numparts:=0;
             compares:=0;
             { Lots of comparisions take a lot of time, so do not allow
               too much comparisions. 8 comparisions are, however, still
               smalller than emitting the set }
             if cs_littlesize in aktglobalswitches then
               maxcompares:=8
             else
               maxcompares:=5;
             { when smallset is possible allow only 3 compares the smallset
               code is for littlesize also smaller when more compares are used }
             if is_small then
               maxcompares:=3;
             for i:=0 to 255 do
              if i in tnormalset(Aset^) then
               begin
                 if (numparts=0) or (i<>setparts[numparts].stop+1) then
                  begin
                  {Set element is a separate element.}
                    inc(compares);
                    if compares>maxcompares then
                         exit;
                    inc(numparts);
                    setparts[numparts].range:=false;
                    setparts[numparts].stop:=i;
                  end
                 else
                  {Set element is part of a range.}
                  if not setparts[numparts].range then
                   begin
                     {Transform an element into a range.}
                     setparts[numparts].range:=true;
                     setparts[numparts].start:=setparts[numparts].stop;
                     setparts[numparts].stop:=i;
                     ranges := true;
                     { there's only one compare per range anymore. Only a }
                     { sub is added, but that's much faster than a        }
                     { cmp/jcc combo so neglect its effect                }
{                     inc(compares);
                     if compares>maxcompares then
                      exit; }
                   end
                  else
                   begin
                    {Extend a range.}
                    setparts[numparts].stop:=i;
                   end;
              end;
             analizeset:=true;
           end;

       begin
         { We check first if we can generate jumps, this can be done
           because the resulttype.def is already set in firstpass }

         { check if we can use smallset operation using btl which is limited
           to 32 bits, the left side may also not contain higher values !! }
         use_small:=(tsetdef(right.resulttype.def).settype=smallset) and
                    ((left.resulttype.def.deftype=orddef) and (torddef(left.resulttype.def).high<=32) or
                     (left.resulttype.def.deftype=enumdef) and (tenumdef(left.resulttype.def).max<=32));

         { Can we generate jumps? Possible for all types of sets }
         genjumps:=(right.nodetype=setconstn) and
                   analizeset(tsetconstnode(right).value_set,use_small);
         { calculate both operators }
         { the complex one first }
         firstcomplex(self);
         secondpass(left);
         { Only process the right if we are not generating jumps }
         if not genjumps then
          begin
            secondpass(right);
          end;
         if codegenerror then
          exit;

         { ofcourse not commutative }
         if nf_swaped in flags then
          swapleftright;

         if genjumps then
          begin
            { It gives us advantage to check for the set elements
              separately instead of using the SET_IN_BYTE procedure.
              To do: Build in support for LOC_JUMP }

            opsize := def_cgsize(left.resulttype.def);
            { If register is used, use only lower 8 bits }
            if left.location.loc in [LOC_REGISTER,LOC_CREGISTER] then
             begin
               { for ranges we always need a 32bit register, because then we }
               { use the register as base in a reference (JM)                }
               if ranges then
                 begin
                   pleftreg:=cg.makeregsize(exprasmlist,left.location.register,OS_ADDR);
                   cg.a_load_reg_reg(exprasmlist,left.location.size,OS_ADDR,left.location.register,pleftreg);
                   if opsize<>OS_ADDR then
                     cg.a_op_const_reg(exprasmlist,OP_AND,OS_ADDR,255,pleftreg);
                   opsize:=OS_ADDR;
                 end
               else
                 { otherwise simply use the lower 8 bits (no "and" }
                 { necessary this way) (JM)                        }
                 begin
                   pleftreg:=cg.makeregsize(exprasmlist,left.location.register,OS_8);
                   opsize := OS_8;
                 end;
             end
            else
             begin
               { load the value in a register }
               pleftreg:=cg.getintregister(exprasmlist,OS_32);
               opsize:=OS_32;
               cg.a_load_ref_reg(exprasmlist,OS_8,OS_32,left.location.reference,pleftreg);
               location_release(exprasmlist,left.location);
             end;

            { Get a label to jump to the end }
            location_reset(location,LOC_FLAGS,OS_NO);

            { It's better to use the zero flag when there are
              no ranges }
            if ranges then
              location.resflags:=F_C
            else
              location.resflags:=F_E;

            objectlibrary.getlabel(l);

            { how much have we already substracted from the x in the }
            { "x in [y..z]" expression                               }
            adjustment := 0;

            r:=NR_NO;
            for i:=1 to numparts do
             if setparts[i].range then
              { use fact that a <= x <= b <=> cardinal(x-a) <= cardinal(b-a) }
              begin
                { is the range different from all legal values? }
                if (setparts[i].stop-setparts[i].start <> 255) then
                  begin
                    { yes, is the lower bound <> 0? }
                    if (setparts[i].start <> 0) then
                      { we're going to substract from the left register,   }
                      { so in case of a LOC_CREGISTER first move the value }
                      { to edi (not done before because now we can do the  }
                      { move and substract in one instruction with LEA)    }
                      if (left.location.loc = LOC_CREGISTER) then
                        begin
                          cg.ungetregister(exprasmlist,pleftreg);
                          r:=cg.getintregister(exprasmlist,OS_32);
                          reference_reset_base(href,pleftreg,-setparts[i].start);
                          cg.a_loadaddr_ref_reg(exprasmlist,href,r);
                          { only now change pleftreg since previous value is }
                          { still used in previous instruction               }
                          pleftreg := r;
                          opsize := OS_32;
                        end
                      else
                        begin
                          { otherwise, the value is already in a register   }
                          { that can be modified                            }
                          cg.a_op_const_reg(exprasmlist,OP_SUB,opsize,setparts[i].start-adjustment,pleftreg);
                        end;
                    { new total value substracted from x:           }
                    { adjustment + (setparts[i].start - adjustment) }
                    adjustment := setparts[i].start;

                    { check if result < b-a+1 (not "result <= b-a", since }
                    { we need a carry in case the element is in the range }
                    { (this will never overflow since we check at the     }
                    { beginning whether stop-start <> 255)                }
                    cg.a_cmp_const_reg_label(exprasmlist,opsize,OC_B,setparts[i].stop-setparts[i].start+1,pleftreg,l);
                  end
                else
                  { if setparts[i].start = 0 and setparts[i].stop = 255,  }
                  { it's always true since "in" is only allowed for bytes }
                  begin
                    exprasmlist.concat(taicpu.op_none(A_STC,S_NO));
                    cg.a_jmp_always(exprasmlist,l);
                  end;
              end
             else
              begin
                { Emit code to check if left is an element }
                exprasmlist.concat(taicpu.op_const_reg(A_CMP,TCGSize2OpSize[opsize],setparts[i].stop-adjustment,
                  pleftreg));
                { Result should be in carry flag when ranges are used }
                if ranges then
                  exprasmlist.concat(taicpu.op_none(A_STC,S_NO));
                { If found, jump to end }
                cg.a_jmp_flags(exprasmlist,F_E,l);
              end;
             if ranges and
                { if the last one was a range, the carry flag is already }
                { set appropriately                                      }
                not(setparts[numparts].range) then
               exprasmlist.concat(taicpu.op_none(A_CLC,S_NO));
             { To compensate for not doing a second pass }
             right.location.reference.symbol:=nil;
             { Now place the end label }
             cg.a_label(exprasmlist,l);
             cg.ungetregister(exprasmlist,pleftreg);
             if r<>NR_NO then
              cg.ungetregister(exprasmlist,r);
          end
         else
          begin
            location_reset(location,LOC_FLAGS,OS_NO);

            { We will now generated code to check the set itself, no jmps,
              handle smallsets separate, because it allows faster checks }
            if use_small then
             begin
               if left.nodetype=ordconstn then
                begin
                  location.resflags:=F_NE;
                  case right.location.loc of
                    LOC_REGISTER,
                    LOC_CREGISTER:
                      begin
                         emit_const_reg(A_TEST,S_L,
                           1 shl (tordconstnode(left).value and 31),right.location.register);
                      end;
                    LOC_REFERENCE,
                    LOC_CREFERENCE :
                      begin
                        emit_const_ref(A_TEST,S_L,1 shl (tordconstnode(left).value and 31),
                           right.location.reference);
                      end;
                    else
                      internalerror(200203312);
                  end;
                  location_release(exprasmlist,right.location);
                end
               else
                begin
                  case left.location.loc of
                     LOC_REGISTER,
                     LOC_CREGISTER:
                       begin
                          hr:=cg.makeregsize(exprasmlist,left.location.register,OS_32);
                          cg.a_load_reg_reg(exprasmlist,left.location.size,OS_32,left.location.register,hr);
                       end;
                  else
                    begin
                      { the set element isn't never samller than a byte
                        and because it's a small set we need only 5 bits
                        but 8 bits are easier to load                    }
                      hr:=cg.getintregister(exprasmlist,OS_32);
                      cg.a_load_ref_reg(exprasmlist,OS_8,OS_32,left.location.reference,hr);
                      location_release(exprasmlist,left.location);
                    end;
                  end;

                  case right.location.loc of
                    LOC_REGISTER,
                    LOC_CREGISTER :
                      begin
                        emit_reg_reg(A_BT,S_L,hr,
                          right.location.register);
                        cg.ungetregister(exprasmlist,right.location.register);
                      end;
                     LOC_CONSTANT :
                       begin
                         { We have to load the value into a register because
                            btl does not accept values only refs or regs (PFV) }
                         hr2:=cg.getintregister(exprasmlist,OS_32);
                         cg.a_load_const_reg(exprasmlist,OS_32,right.location.value,hr2);
                         emit_reg_reg(A_BT,S_L,hr,hr2);
                         cg.ungetregister(exprasmlist,hr2);
                       end;
                     LOC_CREFERENCE,
                     LOC_REFERENCE :
                       begin
                         location_release(exprasmlist,right.location);
                         emit_reg_ref(A_BT,S_L,hr,right.location.reference);
                       end;
                     else
                       internalerror(2002032210);
                  end;
                  { simply to indicate EDI is deallocated here too (JM) }
                  cg.ungetregister(exprasmlist,hr);
                  location.resflags:=F_C;
                end;
             end
            else
             begin
               if right.location.loc=LOC_CONSTANT then
                begin
                  location.resflags:=F_C;
                  objectlibrary.getlabel(l);
                  objectlibrary.getlabel(l2);

                  { load constants to a register }
                  if left.nodetype=ordconstn then
                    location_force_reg(exprasmlist,left.location,OS_INT,true);

                  case left.location.loc of
                     LOC_REGISTER,
                     LOC_CREGISTER:
                       begin
                          hr:=cg.makeregsize(exprasmlist,left.location.register,OS_32);
                          cg.a_load_reg_reg(exprasmlist,left.location.size,OS_32,left.location.register,hr);
                          cg.a_cmp_const_reg_label(exprasmlist,OS_32,OC_BE,31,hr,l);
                          { reset carry flag }
                          exprasmlist.concat(taicpu.op_none(A_CLC,S_NO));
                          cg.a_jmp_always(exprasmlist,l2);
                          cg.a_label(exprasmlist,l);
                          { We have to load the value into a register because
                            btl does not accept values only refs or regs (PFV) }
                          hr2:=cg.getintregister(exprasmlist,OS_32);
                          cg.a_load_const_reg(exprasmlist,OS_32,right.location.value,hr2);
                          emit_reg_reg(A_BT,S_L,hr,hr2);
                          cg.ungetregister(exprasmlist,hr2);
                       end;
                  else
                    begin
{$ifdef CORRECT_SET_IN_FPC}
                          if m_tp in aktmodeswitches then
                            begin
                              {***WARNING only correct if
                                reference is 32 bits (PM) *****}
                               emit_const_ref(A_CMP,S_L,31,reference_copy(left.location.reference));
                            end
                          else
{$endif CORRECT_SET_IN_FPC}
                            begin
                               emit_const_ref(A_CMP,S_B,31,left.location.reference);
                            end;
                       cg.a_jmp_flags(exprasmlist,F_BE,l);
                       { reset carry flag }
                       exprasmlist.concat(taicpu.op_none(A_CLC,S_NO));
                       cg.a_jmp_always(exprasmlist,l2);
                       cg.a_label(exprasmlist,l);
                       location_release(exprasmlist,left.location);
                       hr:=cg.getintregister(exprasmlist,OS_32);
                       cg.a_load_ref_reg(exprasmlist,OS_32,OS_32,left.location.reference,hr);
                       { We have to load the value into a register because
                         btl does not accept values only refs or regs (PFV) }
                       hr2:=cg.getintregister(exprasmlist,OS_32);
                       cg.a_load_const_reg(exprasmlist,OS_32,right.location.value,hr2);
                       emit_reg_reg(A_BT,S_L,hr,hr2);
                       cg.ungetregister(exprasmlist,hr2);
                    end;
                  end;
                  cg.a_label(exprasmlist,l2);
                end { of right.location.loc=LOC_CONSTANT }
               { do search in a normal set which could have >32 elementsm
                 but also used if the left side contains higher values > 32 }
               else if left.nodetype=ordconstn then
                begin
                  location.resflags:=F_NE;
                  inc(right.location.reference.offset,tordconstnode(left).value shr 3);
                  emit_const_ref(A_TEST,S_B,1 shl (tordconstnode(left).value and 7),right.location.reference);
                  location_release(exprasmlist,right.location);
                end
               else
                begin
                  if (left.location.loc in [LOC_REGISTER,LOC_CREGISTER]) then
                    pleftreg:=cg.makeregsize(exprasmlist,left.location.register,OS_32)
                  else
                    pleftreg:=cg.getintregister(exprasmlist,OS_32);
                  cg.a_load_loc_reg(exprasmlist,OS_32,left.location,pleftreg);
                  location_freetemp(exprasmlist,left.location);
                  location_release(exprasmlist,left.location);
                  emit_reg_ref(A_BT,S_L,pleftreg,right.location.reference);
                  cg.ungetregister(exprasmlist,pleftreg);
                  location_release(exprasmlist,right.location);
                  { tg.ungetiftemp(exprasmlist,right.location.reference) happens below }
                  location.resflags:=F_C;
                end;
             end;
          end;
          if not genjumps then
            location_freetemp(exprasmlist,right.location);
       end;

begin
   cinnode:=tx86innode;
end.
{
  $Log$
  Revision 1.3  2004-05-22 23:34:28  peter
  tai_regalloc.allocation changed to ratype to notify rgobj of register size changes

  Revision 1.2  2004/02/27 10:21:06  florian
    * top_symbol killed
    + refaddr to treference added
    + refsymbol to treference added
    * top_local stuff moved to an extra record to save memory
    + aint introduced
    * tppufile.get/putint64/aint implemented

  Revision 1.1  2004/02/22 12:04:04  florian
    + nx86set added
    * some more x86-64 fixes
 }
