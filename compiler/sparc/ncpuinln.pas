{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl

    Generate SPARC inline nodes

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
unit ncpuinln;

{$i fpcdefs.inc}

interface

    uses
      node,ninl,ncginl;

    type
      tsparcinlinenode = class(tcgInlineNode)
        function first_abs_real: tnode; override;
        function first_sqr_real: tnode; override;
        function first_sqrt_real: tnode; override;
        procedure second_abs_real; override;
        procedure second_sqr_real; override;
        procedure second_sqrt_real; override;
      private
        procedure load_fpu_location;
      end;


implementation

    uses
      globtype,systems,
      cutils,verbose,globals,fmodule,
      symconst,symdef,
      aasmbase,aasmtai,aasmcpu,
      cgbase,pass_1,pass_2,
      cpubase,paramgr,
      nbas,ncon,ncal,ncnv,nld,
      tgobj,ncgutil,cgobj,cg64f32,rgobj,rgcpu;

{*****************************************************************************
                              tsparcinlinenode
*****************************************************************************}

    procedure tsparcinlinenode.load_fpu_location;
      begin
        secondpass(left);
        location_force_fpureg(exprasmlist,left.location,true);
        location_copy(location,left.location);
        if left.location.loc=LOC_CFPUREGISTER then
          begin
           location.register:=cg.getfpuregister(exprasmlist,location.size);
           location.loc := LOC_FPUREGISTER;
         end;
      end;


    function tsparcinlinenode.first_abs_real : tnode;
      begin
        expectloc:=LOC_FPUREGISTER;
        registersint:=left.registersint;
        registersfpu:=max(left.registersfpu,1);
        first_abs_real := nil;
      end;


    function tsparcinlinenode.first_sqr_real : tnode;
      begin
        expectloc:=LOC_FPUREGISTER;
        registersint:=left.registersint;
        registersfpu:=max(left.registersfpu,1);
        first_sqr_real:=nil;
      end;


    function tsparcinlinenode.first_sqrt_real : tnode;
      begin
        expectloc:=LOC_FPUREGISTER;
        registersint:=left.registersint;
        registersfpu:=max(left.registersfpu,1);
        first_sqrt_real := nil;
      end;


    procedure tsparcinlinenode.second_abs_real;
      begin
        load_fpu_location;
        case tfloatdef(left.resulttype.def).typ of
          s32real:
            exprasmlist.concat(taicpu.op_reg_reg(A_FABSs,left.location.register,location.register));
          s64real:
            exprasmlist.concat(taicpu.op_reg_reg(A_FABSd,left.location.register,location.register));
          s128real:
            exprasmlist.concat(taicpu.op_reg_reg(A_FABSq,left.location.register,location.register));
          else
            internalerror(200410031);
        end;
      end;


    procedure tsparcinlinenode.second_sqr_real;
      begin
        load_fpu_location;
        case tfloatdef(left.resulttype.def).typ of
          s32real:
            exprasmlist.concat(taicpu.op_reg_reg_reg(A_FMULs,left.location.register,left.location.register,location.register));
          s64real:
            exprasmlist.concat(taicpu.op_reg_reg_reg(A_FMULd,left.location.register,left.location.register,location.register));
          s128real:
            exprasmlist.concat(taicpu.op_reg_reg_reg(A_FMULq,left.location.register,left.location.register,location.register));
          else
            internalerror(200410032);
        end;
      end;


    procedure tsparcinlinenode.second_sqrt_real;
      begin
        load_fpu_location;
        case tfloatdef(left.resulttype.def).typ of
          s32real:
            exprasmlist.concat(taicpu.op_reg_reg(A_FSQRTs,left.location.register,location.register));
          s64real:
            exprasmlist.concat(taicpu.op_reg_reg(A_FSQRTd,left.location.register,location.register));
          s128real:
            exprasmlist.concat(taicpu.op_reg_reg(A_FSQRTq,left.location.register,location.register));
          else
            internalerror(200410033);
        end;
      end;

begin
  cInlineNode:=tsparcinlinenode;
end.
{
  $Log$
  Revision 1.10  2004-10-03 12:42:22  florian
    * made sqrt, sqr and abs internal for the sparc

  Revision 1.9  2004/06/20 08:55:32  florian
    * logs truncated

  Revision 1.8  2004/02/03 22:32:54  peter
    * renamed xNNbittype to xNNinttype
    * renamed registers32 to registersint
    * replace some s32bit,u32bit with torddef([su]inttype).def.typ

}
