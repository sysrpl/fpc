{
    $Id$
    Copyright (C) 2000 by Florian Klaempfl

    this unit implements an asmlistitem class for the iA-64 architecture

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
unit cpubase;

  interface

    uses
       strings,systems,cobjects,globals,aasm,cpuinfo;

type
  tasmop = (A_ADD,A_SUB,A_ADDP4,A_AND,A_ANDCM,A_OR,A_XOR,A_SHLADD,
            A_SHLADDP4,A_ADDS,A_ADDL,A_CMP,A_CMP4,A_PADD1,A_PADD2,
            A_PADD4,A_PSUB1,A_PSUB2,A_PSUB4,A_PAVG1,A_PAVG2,A_PAVGSUB1,
            A_PAVGSUB2,A_PCMP1,A_PCMP2,A_PCMP4,A_PSHLADD2,A_PSHRADD2,
            A_PMPY2,A_MIX1,A_MIX2,A_MIX4,A_PACK2,A_PACK4,A_UNPACK2,
            A_UNPACK4,A_PMIN1,A_PMAX1,A_PMIN2,A_PMAX2,A_PSAD1,A_MUX1,
            A_MUX2,A_PSHR2,A_PSHR4,A_SHR,A_PSHL2,A_SHL4,A_SHL,
            A_POPCNT,A_SHRP,A_EXTR,A_DEP,A_TBIT,A_TNAT,A_BREAK,
            A_NOP,A_CHK,A_MOV,A_ZX1,A_ZX2,A_ZXT4,A_SXT1,A_SXT2,A_SXT4,
            A_CXZ1,A_CZX2,A_LD1,A_LD2,A_LD4,A_LD8,A_ST1,A_ST2,A_ST4,
            A_ST8,A_LDFS,A_LDFD,A_LDF8,A_LDFE,A_LDF,A_STFS,A_STFD,A_STF8,
            A_STFE,A_STF,A_LDFPS,A_LDFPD,A_LDFP8,A_LFETCH,A_CMPXCHG1,
            A_CMPXCHG2,A_CMPXHG4,A_CMPXCHG8,A_XCHG1,A_XCHG2,A_XCHG4,
            A_XCHG8,A_FETCHADD4,A_FETCHADD8,A_SETF,A_GETF,A_CHK,
            A_INVALA,A_MF,A_SRLZ,A_SYNC,A_FLUSHRS,A_FC,A_ALLOC,A_SUM
            A_RUM,A_BR,A_CLRRRB,A_FMA,A_FPMA,A_FMS,A_FPMS,A_FNMA,A_FPNMA,
            A_XMA,A_FSELECT,A_CMP,A_FCLASS,A_FRCPA,A_FPRCPA,A_FRSQRTA,
            A_FPRSQRTA,A_FMIN,A_FMAX,A_FAMIN,A_FAMAX,A_FPMIN,A_FPMAX,
            A_FPAMIN,A_FPAMAX,A_FPCMP,A_FMERGE,A_FMIX,A_FSXT,A_FPACK,
            A_FSWAP,A_FAND,A_FANDCM,A_FOR,A_FXOR,A_FPMERGE,A_FCVT,
            A_FPCVT,A_FSETC,A_FCLRT,A_FCHKF,A_MOVL);

Const
  firstop = low(tasmop);
  lastop  = high(tasmop);

type
  TAsmCond =
   (
    C_None,C_A,C_AE,C_B,C_BE,C_C,C_E,C_G,C_GE,C_L,C_LE,C_NA,C_NAE,
    C_NB,C_NBE,C_NC,C_NE,C_NG,C_NGE,C_NL,C_NLE,C_NO,C_NP,C_NS,C_NZ,C_O,C_P,
    C_PE,C_PO,C_S,C_Z
   );


Type

 { ALL registers }
 TRegister = (R_NO,  { R_NO is Mandatory, signifies no register }
              R_0,R_1,R_2,R_3,R_4,R_5,R_6,R_7,R_8,R_9,
              R_10,R_11,R_12,R_13,R_14,R_15,R_16,R_17,R_18,R_19,
              R_20,R_21,R_22,R_23,R_24,R_25,R_26,R_27,R_28,R_29,
              R_30,R_31,
              R_F0,R_F1,R_F2,R_F3,R_F4,R_F5,R_F6,R_F7,R_F8,R_F9,
              R_F10,R_F11,R_F12,R_F13,R_F14,R_F15,R_F16,R_F17,R_F18,R_F19,
              R_F20,R_F21,R_F22,R_F23,R_F24,R_F25,R_F26,R_F27,R_F28,R_F29,
              R_F30,R_F31);

  TRegisterset = Set of TRegister;

{ Constants describing the registers }

Const
  Firstreg = R_0;
  LastReg = R_F31;

  stack_pointer = R_30;
  frame_pointer = R_15;
  self_pointer  = R_16;
  accumulator   = R_0;
  global_pointer = R_29;
  return_pointer = R_26;
  { it is used to pass the offset to the destructor helper routine }
  vmt_offset_reg = R_1;

  max_scratch_regs = 2;
  scratch_regs : array[1..max_scratch_regs] of tregister = (R_1,R_2);

{ low and high of the available maximum width integer general purpose }
{ registers                                                           }
  LoGPReg = R_0;
  HiGPReg = R_31;

{ low and high of every possible width general purpose register (same as }
{ above on most architctures apart from the 80x86)                       }
  LoReg = R_0;
  HiReg = R_31;

  cpuflags = [cf_64bitaddr];

  { sizes }
  pointersize   = 8;
  extended_size = 16;

  general_registers = [R_0..R_31];

  intregs = [R_0..R_31];
  fpuregs = [R_F0..R_F31];
  mmregs = [];

  availabletempregsint = [R_0..R_14,R_16..R_25,R_28];
  availabletempregsfpu = [R_F0..R_F30];
  availabletempregsmm  = [];

  c_countusableregsint = 26;
  c_countusableregsfpu = 31;
  c_countusableregsmm  = 0;

  max_operands = 4;

  registers_saved_on_cdecl = [R_9..R_14,R_F2..R_F9];
  maxvarregs = 6;

  varregs : Array [1..maxvarregs] of Tregister =
            (R_9,R_10,R_11,R_12,R_13,R_14);

Type
 TReference = record
   offset : aword;
   symbol : pasmsymbol;
   base : tregister;
   is_immediate : boolean;
   offsetfixup : word; {needed for inline}
   { the boundary to which the reference is surely aligned }
   alignment : byte;
   end;
 PReference = ^TReference;

 tloc = (LOC_INVALID,
         LOC_REGISTER,
         LOC_MEM,
         LOC_REFERENCE,
         LOC_JUMP,
         { the alpha doesn't have flags, but this }
         { avoid some conditional compiling       }
         { DON'T USE for the alpha                }
         LOC_FLAGS,
         LOC_CREGISTER,
         LOC_CONST);

 tlocation = record
   case loc : tloc of
     LOC_REFERENCE,LOC_MEM : (reference : treference);
     LOC_REGISTER : (register : tregister);
   end;

{*****************************************************************************
                                Operands
*****************************************************************************}


{ Types of operand }
 toptype=(top_none,top_reg,top_ref,top_const,top_symbol);

 toper=record
   ot  : longint;
   case typ : toptype of
    top_none   : ();
    top_reg    : (reg:tregister);
    top_ref    : (ref:preference);
    top_const  : (val:longint);
    top_symbol : (sym:pasmsymbol;symofs:longint);
 end;

Const
  { offsets for the integer and floating point registers }
  INT_REG = 0;
  FLOAT_REG = 32;

  { operator qualifiers }
  OQ_CHOPPED_ROUNDING            = $01;  { /C }
  OQ_ROUNDING_MODE_DYNAMIC       = $02;  { /D }
  OQ_ROUND_TOWARD_MINUS_INFINITY = $04;  { /M }
  OQ_INEXACT_RESULT_ENABLE        = $08; { /I }
  OQ_SOFTWARE_COMPLETION_ENABLE  = $10;  { /S }
  OQ_FLOATING_UNDERFLOW_ENABLE   = $20;  { /U }
  OQ_INTEGER_OVERFLOW_ENABLE     = $40;  { /V }


{*****************************************************************************
                   Opcode propeties (needed for optimizer)
*****************************************************************************}

{$ifndef NOOPT}
Type
{What an instruction can change}
  TInsChange = (Ch_None);
{$endif}


{ resets all values of ref to defaults }
procedure reset_reference(var ref : treference);
{ set mostly used values of a new reference }
function new_reference(base : tregister;offset : longint) : preference;
function newreference(const r : treference) : preference;
procedure disposereference(var r : preference);

function reg2str(r : tregister) : string;

{*****************************************************************************
                                  Init/Done
*****************************************************************************}

  procedure InitCpu;
  procedure DoneCpu;

implementation

uses
   verbose;

function reg2str(r : tregister) : string;

  begin
     if r in [R_0..R_31] then
       reg2str:='R'+tostr(longint(r)-longint(R_0))
     else if r in [R_F0..R_F31] then
       reg2str:='F'+tostr(longint(r)-longint(R_F0))
     else internalerror(38991);
  end;

procedure reset_reference(var ref : treference);
begin
  FillChar(ref,sizeof(treference),0);
end;


function new_reference(base : tregister;offset : longint) : preference;
var
  r : preference;
begin
  new(r);
  FillChar(r^,sizeof(treference),0);
  r^.offset:=offset;
  r^.alignment:=8;
  new_reference:=r;
end;

function newreference(const r : treference) : preference;

var
   p : preference;
begin
   new(p);
   p^:=r;
   newreference:=p;
end;

procedure disposereference(var r : preference);

begin
  dispose(r);
  r:=Nil;
end;

{*****************************************************************************
                                  Init/Done
*****************************************************************************}

  procedure InitCpu;
    begin
    end;

  procedure DoneCpu;
    begin
    end;

end.
{
  $Log$
  Revision 1.1  2000-03-09 20:28:00  florian
    * initial release derieved from the ALPHA cpubase.pas, the
      file still contains some ALPHA stuff

}
