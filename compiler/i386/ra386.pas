{
    $Id$
    Copyright (c) 1998-2002 by Carl Eric Codere and Peter Vreman

    Handles the common i386 assembler reader routines

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
unit Ra386;

{$i fpcdefs.inc}

interface

uses
  aasmbase,aasmtai,aasmcpu,
  cpubase,rautils,cclasses;

{ Parser helpers }
function is_prefix(t:tasmop):boolean;
function is_override(t:tasmop):boolean;
Function CheckPrefix(prefixop,op:tasmop): Boolean;
Function CheckOverride(overrideop,op:tasmop): Boolean;
Procedure FWaitWarning;

type
  T386Operand=class(TOperand)
    Procedure SetCorrectSize(opcode:tasmop);override;
  end;

  T386Instruction=class(TInstruction)
    { Operand sizes }
    procedure AddReferenceSizes;
    procedure SetInstructionOpsize;
    procedure CheckOperandSizes;
    procedure CheckNonCommutativeOpcodes;
    { opcode adding }
    procedure ConcatInstruction(p : taasmoutput);override;
  end;

  tstr2opentry = class(Tnamedindexitem)
    op: TAsmOp;
  end;

const
  AsmPrefixes = 6;
  AsmPrefix : array[0..AsmPrefixes-1] of TasmOP =(
    A_LOCK,A_REP,A_REPE,A_REPNE,A_REPNZ,A_REPZ
  );

  AsmOverrides = 6;
  AsmOverride : array[0..AsmOverrides-1] of TasmOP =(
    A_SEGCS,A_SEGES,A_SEGDS,A_SEGFS,A_SEGGS,A_SEGSS
  );

  CondAsmOps=3;
  CondAsmOp:array[0..CondAsmOps-1] of TasmOp=(
    A_CMOVcc, A_Jcc, A_SETcc
  );
  CondAsmOpStr:array[0..CondAsmOps-1] of string[4]=(
    'CMOV','J','SET'
  );

  { Convert reg to opsize }
  reg_2_opsize:array[firstreg..lastreg] of topsize = (S_NO,
    S_L,S_L,S_L,S_L,S_L,S_L,S_L,S_L,
    S_W,S_W,S_W,S_W,S_W,S_W,S_W,S_W,
    S_B,S_B,S_B,S_B,S_B,S_B,S_B,S_B,
    S_W,S_W,S_W,S_W,S_W,S_W,
    S_FL,S_FL,S_FL,S_FL,S_FL,S_FL,S_FL,S_FL,S_FL,
    S_L,S_L,S_L,S_L,S_L,S_L,
    S_L,S_L,S_L,S_L,
    S_L,S_L,S_L,S_L,S_L,
    S_D,S_D,S_D,S_D,S_D,S_D,S_D,S_D,
    S_D,S_D,S_D,S_D,S_D,S_D,S_D,S_D
  );

implementation

uses
  globtype,globals,systems,verbose,
  cpuinfo,ag386att;

{$define ATTOP}
{$define INTELOP}

{$ifdef NORA386INT}
  {$ifdef NOAG386NSM}
    {$ifdef NOAG386INT}
      {$undef INTELOP}
    {$endif}
  {$endif}
{$endif}

{$ifdef NORA386ATT}
  {$ifdef NOAG386ATT}
    {$undef ATTOP}
  {$endif}
{$endif}



{*****************************************************************************
                              Parser Helpers
*****************************************************************************}

function is_prefix(t:tasmop):boolean;
var
  i : longint;
Begin
  is_prefix:=false;
  for i:=1 to AsmPrefixes do
   if t=AsmPrefix[i-1] then
    begin
      is_prefix:=true;
      exit;
    end;
end;


function is_override(t:tasmop):boolean;
var
  i : longint;
Begin
  is_override:=false;
  for i:=1 to AsmOverrides do
   if t=AsmOverride[i-1] then
    begin
      is_override:=true;
      exit;
    end;
end;


Function CheckPrefix(prefixop,op:tasmop): Boolean;
{ Checks if the prefix is valid with the following opcode }
{ return false if not, otherwise true                          }
Begin
  CheckPrefix := TRUE;
(*  Case prefix of
    A_REP,A_REPNE,A_REPE:
      Case opcode Of
        A_SCASB,A_SCASW,A_SCASD,
        A_INS,A_OUTS,A_MOVS,A_CMPS,A_LODS,A_STOS:;
        Else
          Begin
            CheckPrefix := FALSE;
            exit;
          end;
      end; { case }
    A_LOCK:
      Case opcode Of
        A_BT,A_BTS,A_BTR,A_BTC,A_XCHG,A_ADD,A_OR,A_ADC,A_SBB,A_AND,A_SUB,
        A_XOR,A_NOT,A_NEG,A_INC,A_DEC:;
        Else
          Begin
            CheckPrefix := FALSE;
            Exit;
          end;
      end; { case }
    A_NONE: exit; { no prefix here }
    else
      CheckPrefix := FALSE;
   end; { end case } *)
end;


Function CheckOverride(overrideop,op:tasmop): Boolean;
{ Check if the override is valid, and if so then }
{ update the instr variable accordingly.         }
Begin
  CheckOverride := true;
{     Case instr.getinstruction of
    A_MOVS,A_XLAT,A_CMPS:
      Begin
        CheckOverride := TRUE;
        Message(assem_e_segment_override_not_supported);
      end
  end }
end;


Procedure FWaitWarning;
begin
  if (target_info.system=system_i386_GO32V2) and (cs_fp_emulation in aktmoduleswitches) then
   Message(asmr_w_fwait_emu_prob);
end;

{*****************************************************************************
                              T386Operand
*****************************************************************************}

Procedure T386Operand.SetCorrectSize(opcode:tasmop);
begin
  if gas_needsuffix[opcode]=attsufFPU then
    begin
     case size of
      S_L : size:=S_FS;
      S_IQ : size:=S_FL;
     end;
    end
  else if gas_needsuffix[opcode]=attsufFPUint then
    begin
      case size of
      S_W : size:=S_IS;
      S_L : size:=S_IL;
      end;
    end;
end;


{*****************************************************************************
                              T386Instruction
*****************************************************************************}

procedure T386Instruction.AddReferenceSizes;
{ this will add the sizes for references like [esi] which do not
  have the size set yet, it will take only the size if the other
  operand is a register }
var
  operand2,i : longint;
  s : tasmsymbol;
  so : longint;
begin
  for i:=1to ops do
   begin
   operands[i].SetCorrectSize(opcode);
   if (operands[i].size=S_NO) then
    begin
      case operands[i].Opr.Typ of
        OPR_REFERENCE :
          begin
            if i=2 then
             operand2:=1
            else
             operand2:=2;
            if operand2<ops then
             begin
               { Only allow register as operand to take the size from }
               if operands[operand2].opr.typ=OPR_REGISTER then
                 begin
                   if ((opcode<>A_MOVD) and
                       (opcode<>A_CVTSI2SS)) then
                     operands[i].size:=operands[operand2].size;
                 end
               else
                begin
                  { if no register then take the opsize (which is available with ATT),
                    if not availble then give an error }
                  if opsize<>S_NO then
                    operands[i].size:=opsize
                  else
                   begin
                     Message(asmr_e_unable_to_determine_reference_size);
                     { recovery }
                     operands[i].size:=S_L;
                   end;
                end;
             end
            else
             begin
               if opsize<>S_NO then
                 operands[i].size:=opsize
             end;
          end;
        OPR_SYMBOL :
          begin
            { Fix lea which need a reference }
            if opcode=A_LEA then
             begin
               s:=operands[i].opr.symbol;
               so:=operands[i].opr.symofs;
               operands[i].opr.typ:=OPR_REFERENCE;
               Fillchar(operands[i].opr.ref,sizeof(treference),0);
               operands[i].opr.ref.symbol:=s;
               operands[i].opr.ref.offset:=so;
             end;
            operands[i].size:=S_L;
          end;
      end;
    end;
   end;
end;


procedure T386Instruction.SetInstructionOpsize;
begin
  if opsize<>S_NO then
   exit;
  case ops of
    0 : ;
    1 :
      { "push es" must be stored as a long PM }
      if ((opcode=A_PUSH) or
          (opcode=A_POP)) and
         (operands[1].opr.typ=OPR_REGISTER) and
         ((operands[1].opr.reg>=firstsreg) and
          (operands[1].opr.reg<=lastsreg)) then
        opsize:=S_L
      else
        opsize:=operands[1].size;
    2 :
      begin
        case opcode of
          A_MOVZX,A_MOVSX :
            begin
              case operands[1].size of
                S_W :
                  case operands[2].size of
                    S_L :
                      opsize:=S_WL;
                  end;
                S_B :
                  case operands[2].size of
                    S_W :
                      opsize:=S_BW;
                    S_L :
                      opsize:=S_BL;
                  end;
              end;
            end;
          A_MOVD : { movd is a move from a mmx register to a
                     32 bit register or memory, so no opsize is correct here PM }
            exit;
          A_OUT :
            opsize:=operands[1].size;
          else
            opsize:=operands[2].size;
        end;
      end;
    3 :
      opsize:=operands[3].size;
  end;
end;


procedure T386Instruction.CheckOperandSizes;
var
  sizeerr : boolean;
  i : longint;
begin
  { Check only the most common opcodes here, the others are done in
    the assembler pass }
  case opcode of
    A_PUSH,A_POP,A_DEC,A_INC,A_NOT,A_NEG,
    A_CMP,A_MOV,
    A_ADD,A_SUB,A_ADC,A_SBB,
    A_AND,A_OR,A_TEST,A_XOR: ;
  else
    exit;
  end;
  { Handle the BW,BL,WL separatly }
  sizeerr:=false;
  { special push/pop selector case }
  if ((opcode=A_PUSH) or
      (opcode=A_POP)) and
     (operands[1].opr.typ=OPR_REGISTER) and
     ((operands[1].opr.reg>=firstsreg) and
      (operands[1].opr.reg<=lastsreg)) then
     exit;
  if opsize in [S_BW,S_BL,S_WL] then
   begin
     if ops<>2 then
      sizeerr:=true
     else
      begin
        case opsize of
          S_BW :
            sizeerr:=(operands[1].size<>S_B) or (operands[2].size<>S_W);
          S_BL :
            sizeerr:=(operands[1].size<>S_B) or (operands[2].size<>S_L);
          S_WL :
            sizeerr:=(operands[1].size<>S_W) or (operands[2].size<>S_L);
        end;
      end;
   end
  else
   begin
     for i:=1 to ops do
      begin
        if (operands[i].opr.typ<>OPR_CONSTANT) and
           (operands[i].size in [S_B,S_W,S_L]) and
           (operands[i].size<>opsize) then
         sizeerr:=true;
      end;
   end;
  if sizeerr then
   begin
     { if range checks are on then generate an error }
     if (cs_compilesystem in aktmoduleswitches) or
        not (cs_check_range in aktlocalswitches) then
       Message(asmr_w_size_suffix_and_dest_dont_match)
     else
       Message(asmr_e_size_suffix_and_dest_dont_match);
   end;
end;


{ This check must be done with the operand in ATT order
  i.e.after swapping in the intel reader
  but before swapping in the NASM and TASM writers PM }
procedure T386Instruction.CheckNonCommutativeOpcodes;
begin
  if ((ops=2) and
     (operands[1].opr.typ=OPR_REGISTER) and
     (operands[2].opr.typ=OPR_REGISTER) and
     { if the first is ST and the second is also a register
       it is necessarily ST1 .. ST7 }
     (operands[1].opr.reg in [R_ST..R_ST0])) or
      (ops=0)  then
      if opcode=A_FSUBR then
        opcode:=A_FSUB
      else if opcode=A_FSUB then
        opcode:=A_FSUBR
      else if opcode=A_FDIVR then
        opcode:=A_FDIV
      else if opcode=A_FDIV then
        opcode:=A_FDIVR
      else if opcode=A_FSUBRP then
        opcode:=A_FSUBP
      else if opcode=A_FSUBP then
        opcode:=A_FSUBRP
      else if opcode=A_FDIVRP then
        opcode:=A_FDIVP
      else if opcode=A_FDIVP then
        opcode:=A_FDIVRP;
  if  ((ops=1) and
      (operands[1].opr.typ=OPR_REGISTER) and
      (operands[1].opr.reg in [R_ST1..R_ST7])) then
      if opcode=A_FSUBRP then
        opcode:=A_FSUBP
      else if opcode=A_FSUBP then
        opcode:=A_FSUBRP
      else if opcode=A_FDIVRP then
        opcode:=A_FDIVP
      else if opcode=A_FDIVP then
        opcode:=A_FDIVRP;
end;

{*****************************************************************************
                              opcode Adding
*****************************************************************************}

procedure T386Instruction.ConcatInstruction(p : taasmoutput);
var
  siz  : topsize;
  i,asize : longint;
  ai   : taicpu;
begin
{ Get Opsize }
  if (opsize<>S_NO) or (Ops=0) then
   siz:=opsize
  else
   begin
     if (Ops=2) and (operands[1].opr.typ=OPR_REGISTER) then
      siz:=operands[1].size
     else
      siz:=operands[Ops].size;
     { MOVD should be of size S_LQ or S_QL, but these do not exist PM }
     if (ops=2) and (operands[1].size<>S_NO) and
        (operands[2].size<>S_NO) and (operands[1].size<>operands[2].size) then
       siz:=S_NO;
   end;

   if ((opcode=A_MOVD)or
       (opcode=A_CVTSI2SS)) and
      ((operands[1].size=S_NO) or
       (operands[2].size=S_NO)) then
     siz:=S_NO;
   { NASM does not support FADD without args
     as alias of FADDP
     and GNU AS interprets FADD without operand differently
     for version 2.9.1 and 2.9.5 !! }
   if (ops=0) and
      ((opcode=A_FADD) or
       (opcode=A_FMUL) or
       (opcode=A_FSUB) or
       (opcode=A_FSUBR) or
       (opcode=A_FDIV) or
       (opcode=A_FDIVR)) then
     begin
       if opcode=A_FADD then
         opcode:=A_FADDP
       else if opcode=A_FMUL then
         opcode:=A_FMULP
       else if opcode=A_FSUB then
         opcode:=A_FSUBP
       else if opcode=A_FSUBR then
         opcode:=A_FSUBRP
       else if opcode=A_FDIV then
         opcode:=A_FDIVP
       else if opcode=A_FDIVR then
         opcode:=A_FDIVRP;
{$ifdef ATTOP}
       message1(asmr_w_fadd_to_faddp,gas_op2str[opcode]);
{$else}
  {$ifdef INTELOP}
       message1(asmr_w_fadd_to_faddp,std_op2str[opcode]);
  {$else}
       message1(asmr_w_fadd_to_faddp,'fXX');
  {$endif INTELOP}
{$endif ATTOP}
     end;

   { GNU AS interprets FDIV without operand differently
     for version 2.9.1 and 2.10
     we add explicit args to it !! }
  if (ops=0) and
     ((opcode=A_FSUBP) or
      (opcode=A_FSUBRP) or
      (opcode=A_FDIVP) or
      (opcode=A_FDIVRP) or
      (opcode=A_FSUB) or
      (opcode=A_FSUBR) or
      (opcode=A_FDIV) or
      (opcode=A_FDIVR)) then
     begin
{$ifdef ATTOP}
       message1(asmr_w_adding_explicit_args_fXX,gas_op2str[opcode]);
{$else}
  {$ifdef INTELOP}
       message1(asmr_w_adding_explicit_args_fXX,std_op2str[opcode]);
  {$else}
       message1(asmr_w_adding_explicit_args_fXX,'fXX');
  {$endif INTELOP}
{$endif ATTOP}
       ops:=2;
       operands[1].opr.typ:=OPR_REGISTER;
       operands[2].opr.typ:=OPR_REGISTER;
       operands[1].opr.reg:=R_ST;
       operands[2].opr.reg:=R_ST1;
     end;
  if (ops=1) and
      ((operands[1].opr.typ=OPR_REGISTER) and
      (operands[1].opr.reg in [R_ST1..R_ST7])) and
      ((opcode=A_FSUBP) or
      (opcode=A_FSUBRP) or
      (opcode=A_FDIVP) or
      (opcode=A_FDIVRP) or
      (opcode=A_FADDP) or
      (opcode=A_FMULP)) then
     begin
{$ifdef ATTOP}
       message1(asmr_w_adding_explicit_first_arg_fXX,gas_op2str[opcode]);
{$else}
  {$ifdef INTELOP}
       message1(asmr_w_adding_explicit_first_arg_fXX,std_op2str[opcode]);
  {$else}
       message1(asmr_w_adding_explicit_first_arg_fXX,'fXX');
  {$endif INTELOP}
{$endif ATTOP}
       ops:=2;
       operands[2].opr.typ:=OPR_REGISTER;
       operands[2].opr.reg:=operands[1].opr.reg;
       operands[1].opr.reg:=R_ST;
     end;

  if (ops=1) and
      ((operands[1].opr.typ=OPR_REGISTER) and
      (operands[1].opr.reg in [R_ST1..R_ST7])) and
      ((opcode=A_FSUB) or
      (opcode=A_FSUBR) or
      (opcode=A_FDIV) or
      (opcode=A_FDIVR) or
      (opcode=A_FADD) or
      (opcode=A_FMUL)) then
     begin
{$ifdef ATTOP}
       message1(asmr_w_adding_explicit_second_arg_fXX,gas_op2str[opcode]);
{$else}
  {$ifdef INTELOP}
       message1(asmr_w_adding_explicit_second_arg_fXX,std_op2str[opcode]);
  {$else}
       message1(asmr_w_adding_explicit_second_arg_fXX,'fXX');
  {$endif INTELOP}
{$endif ATTOP}
       ops:=2;
       operands[2].opr.typ:=OPR_REGISTER;
       operands[2].opr.reg:=R_ST;
     end;

   { I tried to convince Linus Torwald to add
     code to support ENTER instruction
     (when raising a stack page fault)
     but he replied that ENTER is a bad instruction and
     Linux does not need to support it
     So I think its at least a good idea to add a warning
     if someone uses this in assembler code
     FPC itself does not use it at all PM }
   if (opcode=A_ENTER) and ((target_info.system=system_i386_linux) or
        (target_info.system=system_i386_FreeBSD)) then
     begin
       message(asmr_w_enter_not_supported_by_linux);
     end;

  ai:=taicpu.op_none(opcode,siz);
  ai.Ops:=Ops;
  for i:=1to Ops do
   begin
     case operands[i].opr.typ of
       OPR_CONSTANT :
         ai.loadconst(i-1,aword(operands[i].opr.val));
       OPR_REGISTER:
         ai.loadreg(i-1,operands[i].opr.reg);
       OPR_SYMBOL:
         ai.loadsymbol(i-1,operands[i].opr.symbol,operands[i].opr.symofs);
       OPR_REFERENCE:
         begin
           ai.loadref(i-1,operands[i].opr.ref);
           if operands[i].size<>S_NO then
             begin
               asize:=0;
               case operands[i].size of
                   S_B :
                     asize:=OT_BITS8;
                   S_W, S_IS :
                     asize:=OT_BITS16;
                   S_L, S_IL, S_FS:
                     asize:=OT_BITS32;
                   S_Q, S_D, S_FL, S_FV :
                     asize:=OT_BITS64;
                   S_FX :
                     asize:=OT_BITS80;
                 end;
               if asize<>0 then
                 ai.oper[i-1].ot:=(ai.oper[i-1].ot and not OT_SIZE_MASK) or asize;
             end;
         end;
     end;
   end;

  if (opcode=A_CALL) and (opsize=S_FAR) then
    opcode:=A_LCALL;
  if (opcode=A_JMP) and (opsize=S_FAR) then
    opcode:=A_LJMP;
  if (opcode=A_LCALL) or (opcode=A_LJMP) then
    opsize:=S_FAR;
 { Condition ? }
  if condition<>C_None then
   ai.SetCondition(condition);

 { Concat the opcode or give an error }
  if assigned(ai) then
   begin
     { Check the instruction if it's valid }
{$ifndef NOAG386BIN}
     ai.CheckIfValid;
{$endif NOAG386BIN}
     p.concat(ai);
   end
  else
   Message(asmr_e_invalid_opcode_and_operand);
end;

end.
{
  $Log$
  Revision 1.25  2002-10-31 13:28:32  pierre
   * correct last wrong fix for tw2158

  Revision 1.24  2002/10/30 17:10:00  pierre
   * merge of fix for tw2158 bug

  Revision 1.23  2002/07/26 21:15:44  florian
    * rewrote the system handling

  Revision 1.22  2002/07/01 18:46:34  peter
    * internal linker
    * reorganized aasm layer

  Revision 1.21  2002/05/18 13:34:25  peter
    * readded missing revisions

  Revision 1.20  2002/05/16 19:46:52  carl
  + defines.inc -> fpcdefs.inc to avoid conflicts if compiling by hand
  + try to fix temp allocation (still in ifdef)
  + generic constructor calls
  + start of tassembler / tmodulebase class cleanup

  Revision 1.18  2002/05/12 16:53:18  peter
    * moved entry and exitcode to ncgutil and cgobj
    * foreach gets extra argument for passing local data to the
      iterator function
    * -CR checks also class typecasts at runtime by changing them
      into as
    * fixed compiler to cycle with the -CR option
    * fixed stabs with elf writer, finally the global variables can
      be watched
    * removed a lot of routines from cga unit and replaced them by
      calls to cgobj
    * u32bit-s32bit updates for and,or,xor nodes. When one element is
      u32bit then the other is typecasted also to u32bit without giving
      a rangecheck warning/error.
    * fixed pascal calling method with reversing also the high tree in
      the parast, detected by tcalcst3 test

  Revision 1.17  2002/04/15 19:12:09  carl
  + target_info.size_of_pointer -> pointer_size
  + some cleanup of unused types/variables
  * move several constants from cpubase to their specific units
    (where they are used)
  + att_Reg2str -> gas_reg2str
  + int_reg2str -> std_reg2str

  Revision 1.16  2002/04/04 19:06:13  peter
    * removed unused units
    * use tlocation.size in cg.a_*loc*() routines

  Revision 1.15  2002/04/02 17:11:39  peter
    * tlocation,treference update
    * LOC_CONSTANT added for better constant handling
    * secondadd splitted in multiple routines
    * location_force_reg added for loading a location to a register
      of a specified size
    * secondassignment parses now first the right and then the left node
      (this is compatible with Kylix). This saves a lot of push/pop especially
      with string operations
    * adapted some routines to use the new cg methods

  Revision 1.14  2002/01/24 18:25:53  peter
   * implicit result variable generation for assembler routines
   * removed m_tp modeswitch, use m_tp7 or not(m_fpc) instead

}
