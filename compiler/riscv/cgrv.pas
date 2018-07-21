{
    Copyright (c) 2006 by Florian Klaempfl

    This unit implements the common part of the code generator for the Risc-V

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
unit cgrv;

{$i fpcdefs.inc}
  interface

    uses
       globtype,symtype,symdef,
       cgbase,cgobj,
       aasmbase,aasmcpu,aasmtai,aasmdata,
       cpubase,cpuinfo,cgutils,rgcpu,
       parabase;

    type

      { tcgrv }

      tcgrv = class(tcg)
        procedure a_loadaddr_ref_cgpara(list : TAsmList;const r : treference;const paraloc : tcgpara); override;

        procedure a_bit_scan_reg_reg(list: TAsmList; reverse: boolean; srcsize, dstsize: tcgsize; src, dst: TRegister); override;

        procedure a_call_reg(list : TAsmList;reg: tregister); override;
        procedure a_call_name(list : TAsmList;const s : string; weak: boolean); override;

        procedure a_load_const_ref(list: TAsmList; size: tcgsize; a: tcgint; const ref: treference); override;
        procedure a_load_reg_ref(list: TAsmList; fromsize, tosize: TCGSize; reg: tregister; const ref: treference); override;
        procedure a_load_ref_reg(list: TAsmList; fromsize, tosize: tcgsize; const ref: treference; reg: tregister); override;
        procedure a_load_const_reg(list: TAsmList; size: tcgsize; a: tcgint; register: tregister); override;            

        procedure a_op_const_reg(list : TAsmList; Op: TOpCG; size: TCGSize; a: tcgint; reg: TRegister); override;
        procedure a_op_reg_reg(list : TAsmList; Op: TOpCG; size: TCGSize; src, dst: TRegister); override;

        procedure a_op_const_reg_reg(list: TAsmList; op: TOpCg; size: tcgsize; a: tcgint; src, dst: tregister); override;
        procedure a_op_reg_reg_reg(list: TAsmList; op: TOpCg; size: tcgsize; src1, src2, dst: tregister); override;

        procedure a_loadaddr_ref_reg(list : TAsmList;const ref : treference;r : tregister);override;

        procedure a_cmp_const_reg_label(list : TAsmList;size : tcgsize;cmp_op : topcmp;a : tcgint;reg : tregister; l : tasmlabel); override;
        procedure a_cmp_reg_reg_label(list : TAsmList;size : tcgsize;cmp_op : topcmp;reg1,reg2 : tregister;l : tasmlabel); override;

        procedure a_jmp_name(list : TAsmList;const s : string); override;
        procedure a_jmp_always(list : TAsmList;l: tasmlabel); override;          

        procedure g_save_registers(list: TAsmList); override;
        procedure g_restore_registers(list: TAsmList); override;

        { fpu move instructions }
        procedure a_loadfpu_reg_reg(list: TAsmList; fromsize, tosize: tcgsize; reg1, reg2: tregister); override;
        procedure a_loadfpu_ref_reg(list: TAsmList; fromsize, tosize: tcgsize; const ref: treference; reg: tregister); override;
        procedure a_loadfpu_reg_ref(list: TAsmList; fromsize, tosize: tcgsize; reg: tregister; const ref: treference); override;
      protected
        function  fixref(list: TAsmList; var ref: treference): boolean;
      end;

  const
    TOpCmp2AsmCond: Array[topcmp] of TAsmCond = (C_NONE,C_EQ,C_NONE,
                         C_LT,C_GE,C_None,C_NE,C_NONE,C_LT,C_GE,C_NONE);         

  const
    TOpCG2AsmConstOp: Array[topcg] of TAsmOp = (A_NONE,
          A_NONE,A_ADDI,A_ANDI,A_NONE,A_NONE,A_NONE,A_NONE,
          A_None,A_None,A_ORI,A_SRAI,A_SLLI,A_SRLI,A_NONE,A_XORI,A_None,A_None);
    TOpCG2AsmOp: Array[topcg] of TAsmOp = (A_NONE,
          A_NONE,A_ADD,A_AND,A_DIVU,A_DIV,A_MUL,A_MUL,
          A_None,A_None,A_OR,A_SRA,A_SLL,A_SRL,A_SUB,A_XOR,A_None,A_None);


  implementation

    uses
       {$ifdef extdebug}sysutils,{$endif}
       globals,verbose,systems,cutils,
       symconst,symsym,symtable,fmodule,
       rgobj,tgobj,cpupi,procinfo,paramgr;


    procedure tcgrv.a_call_name(list : TAsmList;const s : string; weak: boolean);
      var
        tmpreg: TRegister;
        href: treference;
        l: TAsmLabel;
      begin
        if not(weak) then
          reference_reset_symbol(href,current_asmdata.RefAsmSymbol(s,AT_FUNCTION),0,0,[])
        else
          reference_reset_symbol(href,current_asmdata.WeakRefAsmSymbol(s,AT_FUNCTION),0,0,[]);

        tmpreg:=getintregister(list,OS_ADDR);

        current_asmdata.getjumplabel(l);

        a_label(list,l);

        href.refaddr:=addr_pcrel_hi20;
        list.concat(taicpu.op_reg_ref(A_AUIPC,tmpreg,href));

        reference_reset_symbol(href,l,0,0,[]);
        href.refaddr:=addr_pcrel_lo12;
        list.concat(taicpu.op_reg_reg_ref(A_JALR,NR_RETURN_ADDRESS_REG,tmpreg,href));

         {if not(weak) then
           list.concat(taicpu.op_reg_sym(A_JAL,NR_RETURN_ADDRESS_REG,current_asmdata.RefAsmSymbol(s,AT_FUNCTION)))
         else
           list.concat(taicpu.op_reg_sym(A_JAL,NR_RETURN_ADDRESS_REG,current_asmdata.WeakRefAsmSymbol(s,AT_FUNCTION)));}
       { not assigned while generating external wrappers }
       if assigned(current_procinfo) then
         include(current_procinfo.flags,pi_do_call);
      end;


    procedure tcgrv.a_load_const_ref(list: TAsmList; size: tcgsize; a: tcgint; const ref: treference);
      begin
        if a=0 then
          a_load_reg_ref(list,size,size,NR_X0,ref)
        else
          inherited a_load_const_ref(list, size, a, ref);
      end;


    procedure tcgrv.a_loadaddr_ref_cgpara(list : TAsmList;const r : treference;const paraloc : tcgpara);
      var
        ref: treference;
        tmpreg: tregister;

      begin
        paraloc.check_simple_location;
        paramanager.allocparaloc(list,paraloc.location);
        case paraloc.location^.loc of
           LOC_REGISTER,LOC_CREGISTER:
             a_loadaddr_ref_reg(list,r,paraloc.location^.register);
           LOC_REFERENCE:
             begin
               reference_reset(ref,paraloc.alignment,[]);
               ref.base := paraloc.location^.reference.index;
               ref.offset := paraloc.location^.reference.offset;
               tmpreg := rg[R_INTREGISTER].getregister(list,R_SUBWHOLE);
               a_loadaddr_ref_reg(list,r,tmpreg);
               a_load_reg_ref(list,OS_ADDR,OS_ADDR,tmpreg,ref);
             end;
           else
             internalerror(2002080701);
        end;
      end;


    procedure tcgrv.a_bit_scan_reg_reg(list: TAsmList; reverse: boolean; srcsize, dstsize: tcgsize; src, dst: TRegister);
      begin
        internalerror(2016060401);
      end;       


    procedure tcgrv.a_op_const_reg(list : TAsmList; Op: TOpCG; size: TCGSize; a: tcgint; reg: TRegister);
      begin
        a_op_const_reg_reg(list,op,size,a,reg,reg);
      end;


    procedure tcgrv.a_op_reg_reg(list : TAsmList; Op: TOpCG; size: TCGSize; src, dst: TRegister);
      begin
        a_op_reg_reg_reg(list,op,size,src,dst,dst);
      end;


    procedure tcgrv.a_op_const_reg_reg(list: TAsmList; op: TOpCg; size: tcgsize; a: tcgint; src, dst: tregister);
      var
        tmpreg: TRegister;
      begin
        optimize_op_const(size,op,a);

        if op=OP_NONE then
          begin
            a_load_reg_reg(list,size,size,src,dst);
            exit;
          end;

        if op=OP_SUB then
          begin
            op:=OP_ADD;
            a:=-a;
          end;

        if (TOpCG2AsmConstOp[op]<>A_None) and
           is_imm12(a) then
          list.concat(taicpu.op_reg_reg_const(TOpCG2AsmConstOp[op],dst,src,a))
        else
          begin
            tmpreg:=getintregister(list,size);
            a_load_const_reg(list,size,a,tmpreg);
            a_op_reg_reg_reg(list,op,size,tmpreg,src,dst);
          end;
      end;   


    procedure tcgrv.a_op_reg_reg_reg(list: TAsmList; op: TOpCg; size: tcgsize; src1, src2, dst: tregister);
      begin
        case op of
          OP_NOT:
            list.concat(taicpu.op_reg_reg_const(A_XORI,dst,src1,-1));
          OP_NEG:
            list.concat(taicpu.op_reg_reg_reg(A_SUB,dst,NR_X0,src1));
          OP_MOVE:
            a_load_reg_reg(list,size,size,src1,dst);
        else
          list.concat(taicpu.op_reg_reg_reg(TOpCG2AsmOp[op],dst,src2,src1));
        end;
      end;


    procedure tcgrv.a_loadaddr_ref_reg(list : TAsmList;const ref : treference;r : tregister);
      var
        href: treference;
        b, tmpreg: TRegister;
        l: TAsmLabel;
      begin
        href:=ref;
        fixref(list,href);

        if (not assigned(href.symbol)) and
           (href.offset=0) then
          a_load_reg_reg(list,OS_ADDR,OS_ADDR,href.base,r)
        else if (assigned(href.symbol) or
            (not is_imm12(href.offset))) and
           (href.base<>NR_NO) then
          begin
            b:= href.base;

            current_asmdata.getjumplabel(l);
            a_label(list,l);

            href.base:=NR_NO;
            href.refaddr:=addr_pcrel_hi20;
            list.concat(taicpu.op_reg_ref(A_AUIPC,r,href));

            reference_reset_symbol(href,l,0,0,ref.volatility);
            href.refaddr:=addr_pcrel_lo12;
            list.concat(taicpu.op_reg_reg_ref(A_ADDI,r,r,href));

            list.concat(taicpu.op_reg_reg_reg(A_ADD,r,r,b));
          end
        else if is_imm12(href.offset) and
           (href.base<>NR_NO) then
          begin
            list.concat(taicpu.op_reg_reg_const(A_ADDI,r,href.base,href.offset));
          end
        else if (href.refaddr=addr_pcrel) then
          begin                     
            tmpreg:=getintregister(list,OS_ADDR);

            b:=href.base;
            href.base:=NR_NO;
                                        
            current_asmdata.getjumplabel(l);
            a_label(list,l);

            href.refaddr:=addr_pcrel_hi20;
            list.concat(taicpu.op_reg_ref(A_AUIPC,tmpreg,href));

            reference_reset_symbol(href,l,0,0,ref.volatility);
            href.refaddr:=addr_pcrel_lo12;
            list.concat(taicpu.op_reg_reg_ref(A_ADDI,r,tmpreg,href));

            if b<>NR_NO then
              list.concat(taicpu.op_reg_reg_reg(A_ADD,r,r,b));
          end
        else
          internalerror(2016060504);
      end;                


    procedure tcgrv.a_cmp_const_reg_label(list: TAsmList; size: tcgsize; cmp_op: topcmp; a: tcgint; reg: tregister; l: tasmlabel);
      begin
        if a=0 then
          a_cmp_reg_reg_label(list,size,cmp_op,NR_X0,reg,l)
        else
          inherited;
      end;


    procedure tcgrv.a_cmp_reg_reg_label(list : TAsmList;size : tcgsize;cmp_op : topcmp; reg1,reg2 : tregister;l : tasmlabel);
      var
        tmpreg: TRegister;
        ai: taicpu;
      begin
        if TOpCmp2AsmCond[cmp_op]=C_None then
          begin
            cmp_op:=swap_opcmp(cmp_op);
            tmpreg:=reg1;
            reg1:=reg2;
            reg2:=tmpreg;
          end;

        ai:=taicpu.op_reg_reg_sym_ofs(A_Bxx,reg2,reg1,l,0);
        ai.is_jmp:=true;
        ai.condition:=TOpCmp2AsmCond[cmp_op];
        list.concat(ai);
      end;


    procedure tcgrv.a_jmp_name(list : TAsmList;const s : string);
      var
        ai: taicpu;
        href: treference;
        tmpreg: TRegister;
        l: TAsmLabel;
      begin
        reference_reset_symbol(href,current_asmdata.RefAsmSymbol(s,AT_FUNCTION),0,0,[]);

        tmpreg:=getintregister(list,OS_ADDR);

        current_asmdata.getjumplabel(l);
        a_label(list,l);

        href.refaddr:=addr_pcrel_hi20;
        list.concat(taicpu.op_reg_ref(A_AUIPC,tmpreg,href));
        reference_reset_symbol(href,l,0,0,[]);
        href.refaddr:=addr_pcrel_lo12;
        ai:=taicpu.op_reg_reg_ref(A_JALR,NR_X0,tmpreg,href);
        ai.is_jmp:=true;
        list.concat(ai);

        //ai:=taicpu.op_reg_sym(A_JAL,NR_X0,current_asmdata.RefAsmSymbol(s));
        //ai.is_jmp:=true;
      end;


    procedure tcgrv.a_jmp_always(list : TAsmList;l: tasmlabel);
      var
        ai: taicpu;
        {href: treference;
        tmpreg: TRegister;}
      begin
        {reference_reset_symbol(href,l,0,0);

        tmpreg:=getintregister(list,OS_ADDR);    

        current_asmdata.getjumplabel(l);
        a_label(list,l);

        href.refaddr:=addr_pcrel_hi20;
        list.concat(taicpu.op_reg_ref(A_AUIPC,tmpreg,href));
        reference_reset_symbol(href,l,0,0);
        href.refaddr:=addr_pcrel_lo12;
        ai:=taicpu.op_reg_reg_ref(A_JALR,NR_X0,tmpreg,href);
        ai.is_jmp:=true;
        list.concat(ai);}

        ai:=taicpu.op_reg_sym(A_JAL,NR_X0,l);
        ai.is_jmp:=true;
        list.concat(ai);
       end;


    procedure tcgrv.g_save_registers(list: TAsmList);
      begin
      end;


    procedure tcgrv.g_restore_registers(list: TAsmList);
      begin
      end;


    procedure tcgrv.a_call_reg(list : TAsmList;reg: tregister);
      begin
        list.concat(taicpu.op_reg_reg(A_JALR,NR_RETURN_ADDRESS_REG,reg));
        include(current_procinfo.flags,pi_do_call);
      end;


    procedure tcgrv.a_load_reg_ref(list: TAsmList; fromsize, tosize: TCGSize;
        reg: tregister; const ref: treference);

      const
        StoreInstr: array[OS_8..OS_INT] of TAsmOp =
        (A_SB,A_SH,A_SW
{$ifdef cpu64bitalu}
         ,
         A_SD
{$endif cpu64bitalu}
         );
      var
        ref2: TReference;
        tmpreg: tregister;
        op: TAsmOp;
      begin
        if not (fromsize in [OS_8..OS_INT,OS_S8..OS_SINT]) then
          internalerror(2002090904);
        if not (tosize in [OS_8..OS_INT,OS_S8..OS_SINT]) then
          internalerror(2002090905);

        tosize:=tcgsize2unsigned[tosize];

        ref2 := ref;
        fixref(list, ref2);

        op := storeinstr[tcgsize2unsigned[tosize]];
        list.concat(taicpu.op_reg_ref(op, reg,ref2));
      end;


    procedure tcgrv.a_load_ref_reg(list: TAsmList; fromsize, tosize: tcgsize; const ref: treference; reg: tregister);
      var
        href: treference;
        op: TAsmOp;
        tmpreg: TRegister;
      begin
        href:=ref;
        fixref(list,href);

        if href.refaddr=addr_pcrel then
          begin
            tmpreg:=getintregister(list,OS_ADDR);
            a_loadaddr_ref_reg(list,href,tmpreg);
            reference_reset_base(href,tmpreg,0,ctempposinvalid,0,ref.volatility);
          end;

        case fromsize of
          OS_8: op:=A_LBU;
          OS_16: op:=A_LHU;
          OS_S8: op:=A_LB;
          OS_S16: op:=A_LH;
{$ifdef RISCV64}
          OS_32: op:=A_LWU;
          OS_S32: op:=A_LW;
          OS_64,
          OS_S64: op:=A_LD;
{$else}
          OS_32,
          OS_S32: op:=A_LW;
{$endif}
        else
          internalerror(2016060502);
        end;

        list.concat(taicpu.op_reg_ref(op,reg,href));
      end;


    procedure tcgrv.a_load_const_reg(list: TAsmList; size: tcgsize; a: tcgint; register: tregister);
      begin
        if a=0 then
          a_load_reg_reg(list,size,size,NR_X0,register)
        else
          begin
            if is_imm12(a) then
              list.concat(taicpu.op_reg_reg_const(A_ADDI,register,NR_X0,a))
            else if is_lui_imm(a) then
              list.concat(taicpu.op_reg_const(A_LUI,register,(a shr 12) and $FFFFF))
            else
              begin
                if (a and $800)<>0 then
                  list.concat(taicpu.op_reg_const(A_LUI,register,((a shr 12)+1) and $FFFFF))
                else
                  list.concat(taicpu.op_reg_const(A_LUI,register,(a shr 12) and $FFFFF));

                list.concat(taicpu.op_reg_reg_const(A_ADDI,register,register,SarSmallint(a shl 4,4)));
              end;
          end;
      end;


    procedure tcgrv.a_loadfpu_reg_reg(list: TAsmList; fromsize, tosize: tcgsize; reg1, reg2: tregister);
      var
        op: TAsmOp;
        ai: taicpu;

      const
        convOp: array[OS_F32..OS_F64,OS_F32..OS_F64] of TAsmOp =
        ((A_None,A_FCVT_D_S),
         (A_FCVT_S_D,A_None));

      begin
        if fromsize<>tosize then
          list.concat(taicpu.op_reg_reg(convOp[fromsize,tosize],reg2,reg1))
        else
          begin
            if tosize=OS_F32 then
              op:=A_FSGNJ_S
            else
              op:=A_FSGNJ_D;

            ai:=taicpu.op_reg_reg_reg(op,reg2,reg1,reg1);
            list.concat(ai);
            rg[R_FPUREGISTER].add_move_instruction(ai);
          end;
      end;


    procedure tcgrv.a_loadfpu_ref_reg(list: TAsmList; fromsize, tosize: tcgsize; const ref: treference; reg: tregister);
      var
        href: treference;
        op: TAsmOp;
        tmpreg: TRegister;
        l: TAsmLabel;
      begin
        href:=ref;
        fixref(list,href);      

        if href.refaddr=addr_pcrel then
          begin
            tmpreg:=getintregister(list,OS_ADDR);
            a_loadaddr_ref_reg(list,href,tmpreg);
            reference_reset_base(href,tmpreg,0,ctempposinvalid,0,ref.volatility);
          end;

        if fromsize=OS_F32 then
          op:=A_FLW
        else
          op:=A_FLD;

        list.concat(taicpu.op_reg_ref(op,reg,href));

        if fromsize<>tosize then
          a_loadfpu_reg_reg(list,fromsize,tosize,reg,reg);
      end;


    procedure tcgrv.a_loadfpu_reg_ref(list: TAsmList; fromsize, tosize: tcgsize; reg: tregister; const ref: treference);
      var
        href: treference;
        op: TAsmOp;
        tmpreg: TRegister;
      begin
        href:=ref;
        fixref(list,href);    

        if href.refaddr=addr_pcrel then
          begin
            tmpreg:=getintregister(list,OS_ADDR);
            a_loadaddr_ref_reg(list,href,tmpreg);
            reference_reset_base(href,tmpreg,0,ctempposinvalid,0,ref.volatility);
          end;

        if fromsize<>tosize then
          begin
            tmpreg:=getfpuregister(list,tosize);
            a_loadfpu_reg_reg(list,fromsize,tosize,reg,tmpreg);
            reg:=tmpreg;
          end;

        if tosize=OS_F32 then
          op:=A_FSW
        else
          op:=A_FSD;

        list.concat(taicpu.op_reg_ref(op,reg,href));
      end;


    function tcgrv.fixref(list: TAsmList; var ref: treference): boolean;
      var
        tmpreg: TRegister;
        href: treference;
        l: TAsmLabel;
      begin
        result:=true;

        if ref.refaddr=addr_pcrel then
          exit;

        if assigned(ref.symbol) then
          begin
            reference_reset_symbol(href,ref.symbol,ref.offset,ref.alignment,ref.volatility);
            ref.symbol:=nil;
            ref.offset:=0;

            tmpreg:=getintregister(list,OS_INT);

            current_asmdata.getaddrlabel(l);
            a_label(list,l);

            href.refaddr:=addr_pcrel_hi20;
            list.concat(taicpu.op_reg_ref(A_AUIPC,tmpreg,href));
            reference_reset_symbol(href,l,0,0,ref.volatility);
            href.refaddr:=addr_pcrel_lo12;
            list.concat(taicpu.op_reg_reg_ref(A_ADDI,tmpreg,tmpreg,href));

            if (ref.index<>NR_NO) and
               (ref.base<>NR_NO) then
              begin
                a_op_reg_reg(list,OP_ADD,OS_INT,ref.base,tmpreg);
                ref.base:=tmpreg;
              end
            else if (ref.index=NR_NO) and
               (ref.base<>NR_NO) then
              ref.index:=tmpreg
            else
              ref.base:=tmpreg;
          end
        else if (ref.index=NR_NO) and
                (ref.base=NR_NO) then
          begin              
            tmpreg:=getintregister(list,OS_INT);

            a_load_const_reg(list, OS_ADDR,ref.offset,tmpreg);

            reference_reset_base(ref,tmpreg,0,ctempposinvalid,ref.alignment,ref.volatility);
          end;

        if (ref.index<>NR_NO) and
           (ref.base=NR_NO) then
          begin
            ref.base:=ref.index;
            ref.index:=NR_NO;
          end;

        if not is_imm12(ref.offset) then
          begin
            tmpreg:=getintregister(list,OS_INT);
            a_load_const_reg(list,OS_INT,ref.offset,tmpreg);

            ref.offset:=0;

            if (ref.index<>NR_NO) and
               (ref.base<>NR_NO) then
              begin
                a_op_reg_reg(list,OP_ADD,OS_INT,ref.index,tmpreg);
                ref.index:=tmpreg;
              end
            else
              ref.index:=tmpreg;
          end;

        if (ref.index<>NR_NO) and
           (ref.base<>NR_NO) then
          begin
            tmpreg:=getaddressregister(list);
            list.concat(taicpu.op_reg_reg_reg(A_ADD,tmpreg,ref.base,ref.index));
            ref.base:=tmpreg;
            ref.index:=NR_NO;
          end;
      end;

end.
