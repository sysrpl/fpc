{
    $Id$
    Copyright (c) 1998-2000 by Florian Klaempfl, Pierre Muller

    Symbol table constants

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
unit symconst;

{$i defines.inc}

interface

const
  def_alignment = 4;

  { if you change one of the following contants, }
  { you have also to change the typinfo unit}
  { and the rtl/i386,template/rttip.inc files    }
  tkUnknown  = 0;
  tkInteger  = 1;
  tkChar     = 2;
  tkEnumeration   = 3;
  tkFloat    = 4;
  tkSet      = 5;
  tkMethod   = 6;
  tkSString  = 7;
  tkString   = tkSString;
  tkLString  = 8;
  tkAString  = 9;
  tkWString  = 10;
  tkVariant  = 11;
  tkArray    = 12;
  tkRecord   = 13;
  tkInterface= 14;
  tkClass    = 15;
  tkObject   = 16;
  tkWChar    = 17;
  tkBool     = 18;
  tkInt64    = 19;
  tkQWord    = 20;
  tkDynArray = 21;
  tkInterfaceCorba = 22;

  otSByte    = 0;
  otUByte    = 1;
  otSWord    = 2;
  otUWord    = 3;
  otSLong    = 4;
  otULong    = 5;

  ftSingle   = 0;
  ftDouble   = 1;
  ftExtended = 2;
  ftComp     = 3;
  ftCurr     = 4;

  mkProcedure= 0;
  mkFunction = 1;
  mkConstructor   = 2;
  mkDestructor    = 3;
  mkClassProcedure= 4;
  mkClassFunction = 5;

  pfvar      = 1;
  pfConst    = 2;
  pfArray    = 4;
  pfAddress  = 8;
  pfReference= 16;
  pfOut      = 32;

  main_program_level = 1;
  unit_init_level = 1;
  normal_function_level = 2;


type
  { Deref entry options }
  tdereftype = (derefnil,
    derefaktrecordindex,
    derefaktstaticindex,
    derefunit,
    derefrecord,
    derefindex,
    dereflocal,
    derefpara,
    derefaktlocal
  );

  { symbol options }
  tsymoption=(sp_none,
    sp_public,
    sp_private,
    sp_published,
    sp_protected,
    sp_static,
    sp_hint_deprecated,
    sp_hint_platform,
    sp_hint_library,
    sp_has_overloaded
    ,sp_10
    ,sp_11
    ,sp_12
    ,sp_13
    ,sp_14
    ,sp_15
    ,sp_16
    ,sp_17
    ,sp_18
    ,sp_19
    ,sp_20
    ,sp_21
    ,sp_22
    ,sp_23
    ,sp_24
  );
  tsymoptions=set of tsymoption;

  { flags for a definition }
  tdefoption=(df_none,
    df_has_inittable,           { init data has been generated }
    df_has_rttitable            { rtti data has been generated }
    ,df_3
    ,df_4
    ,df_5
    ,df_6
    ,df_7
    ,df_8
    ,df_9
    ,df_10
    ,df_11
    ,df_12
    ,df_13
    ,df_14
    ,df_15
    ,df_16
    ,df_17
    ,df_18
    ,df_19
    ,df_20
    ,df_21
    ,df_22
    ,df_23
    ,df_24
  );
  tdefoptions=set of tdefoption;

  { tsymlist entry types }
  tsltype = (sl_none,
    sl_load,
    sl_call,
    sl_subscript,
    sl_vec
  );

  { base types for orddef }
  tbasetype = (
    uauto,uvoid,uchar,
    u8bit,u16bit,u32bit,
    s8bit,s16bit,s32bit,
    bool8bit,bool16bit,bool32bit,
    u64bit,s64bit,uwidechar
  );

  { float types }
  tfloattype = (
    s32real,s64real,s80real,
    s64comp
  );

  { string types }
  tstringtype = (st_default,
    st_shortstring, st_longstring, st_ansistring, st_widestring
  );

  { set types }
  tsettype = (
    normset,smallset,varset
  );

  { calling convention for tprocdef and tprocvardef }
  tproccalloption=(pocall_none,
    pocall_clearstack,    { Use IBM flat calling convention. (Used by GCC.) }
    pocall_leftright,     { Push parameters from left to right }
    pocall_cdecl,         { procedure uses C styled calling }
    pocall_register,      { procedure uses register (fastcall) calling }
    pocall_stdcall,       { procedure uses stdcall call }
    pocall_safecall,      { safe call calling conventions }
    pocall_palmossyscall, { procedure is a PalmOS system call }
    pocall_system,
    pocall_inline,        { Procedure is an assembler macro }
    pocall_internproc,    { Procedure has compiler magic}
    pocall_internconst,   { procedure has constant evaluator intern }
    pocall_cppdecl,       { C++ calling conventions }
    pocall_compilerproc   { Procedure is used for internal compiler calls }
    ,pocall_14
    ,pocall_15
    ,pocall_16
    ,pocall_17
    ,pocall_18
    ,pocall_19
    ,pocall_20
    ,pocall_21
    ,pocall_22
    ,pocall_23
    ,pocall_24
  );
  tproccalloptions=set of tproccalloption;

  { basic type for tprocdef and tprocvardef }
  tproctypeoption=(potype_none,
    potype_proginit,     { Program initialization }
    potype_unitinit,     { unit initialization }
    potype_unitfinalize, { unit finalization }
    potype_constructor,  { Procedure is a constructor }
    potype_destructor,   { Procedure is a destructor }
    potype_operator      { Procedure defines an operator }
    ,potype_7
    ,potype_8
    ,potype_9
    ,potype_10
    ,potype_11
    ,potype_12
    ,potype_13
    ,potype_14
    ,potype_15
    ,potype_16
    ,potype_17
    ,potype_18
    ,potype_19
    ,potype_20
    ,potype_21
    ,potype_22
    ,potype_23
    ,potype_24
  );
  tproctypeoptions=set of tproctypeoption;

  { other options for tprocdef and tprocvardef }
  tprocoption=(po_none,
    po_classmethod,       { class method }
    po_virtualmethod,     { Procedure is a virtual method }
    po_abstractmethod,    { Procedure is an abstract method }
    po_staticmethod,      { static method }
    po_overridingmethod,  { method with override directive }
    po_methodpointer,     { method pointer, only in procvardef, also used for 'with object do' }
    po_containsself,      { self is passed explicit to the compiler }
    po_interrupt,         { Procedure is an interrupt handler }
    po_iocheck,           { IO checking should be done after a call to the procedure }
    po_assembler,         { Procedure is written in assembler }
    po_msgstr,            { method for string message handling }
    po_msgint,            { method for int message handling }
    po_exports,           { Procedure has export directive (needed for OS/2) }
    po_external,          { Procedure is external (in other object or lib)}
    po_savestdregs,       { save std regs cdecl and stdcall need that ! }
    po_saveregisters,     { save all registers }
    po_overload,          { procedure is declared with overload directive }
    po_varargs            { printf like arguments }
    ,po_19
    ,po_20
    ,po_21
    ,po_22
    ,po_23
    ,po_24
  );
  tprocoptions=set of tprocoption;

  { options for objects and classes }
  tobjectdeftype = (odt_none,
    odt_class,
    odt_object,
    odt_interfacecom,
    odt_interfacecorba,
    odt_cppclass
  );

  { options for objects and classes }
  tobjectoption=(oo_none,
    oo_is_forward,         { the class is only a forward declared yet }
    oo_has_virtual,        { the object/class has virtual methods }
    oo_has_private,
    oo_has_protected,
    oo_has_constructor,    { the object/class has a constructor }
    oo_has_destructor,     { the object/class has a destructor }
    oo_has_vmt,            { the object/class has a vmt }
    oo_has_msgstr,
    oo_has_msgint,
    oo_has_abstract,       { the object/class has an abstract method => no instances can be created }
    oo_can_have_published { the class has rtti, i.e. you can publish properties }
    ,oo_12
    ,oo_13
    ,oo_14
    ,oo_15
    ,oo_16
    ,oo_17
    ,oo_18
    ,oo_19
    ,oo_20
    ,oo_21
    ,oo_22
    ,oo_23
    ,oo_24
  );
  tobjectoptions=set of tobjectoption;

  { options for properties }
  tpropertyoption=(ppo_none,
    ppo_indexed,
    ppo_defaultproperty,
    ppo_stored,
    ppo_hasparameters,
    ppo_is_override
    ,ppo_6
    ,ppo_7
    ,ppo_8
    ,ppo_9
    ,ppo_10
    ,ppo_11
    ,ppo_12
    ,ppo_13
    ,ppo_14
    ,ppo_15
    ,ppo_16
    ,ppo_17
    ,ppo_18
    ,ppo_19
    ,ppo_20
    ,ppo_21
    ,ppo_22
    ,ppo_23
    ,ppo_24
  );
  tpropertyoptions=set of tpropertyoption;

  { options for variables }
  tvaroption=(vo_none,
    vo_regable,
    vo_is_C_var,
    vo_is_external,
    vo_is_dll_var,
    vo_is_thread_var,
    vo_fpuregable,
    vo_is_local_copy,
    vo_is_const,  { variable is declared as const (parameter) and can't be written to }
    vo_is_exported
    ,vo_10
    ,vo_11
    ,vo_12
    ,vo_13
    ,vo_14
    ,vo_15
    ,vo_16
    ,vo_17
    ,vo_18
    ,vo_19
    ,vo_20
    ,vo_21
    ,vo_22
    ,vo_23
    ,vo_24
  );
  tvaroptions=set of tvaroption;

  { types of the symtables }
  tsymtabletype = (abstractsymtable,
    globalsymtable,staticsymtable,
    objectsymtable,recordsymtable,
    localsymtable,parasymtable,
    withsymtable,stt_exceptsymtable,
    { used for inline detection }
    inlineparasymtable,inlinelocalsymtable
  );


  { definition contains the informations about a type }
  tdeftype = (abstractdef,arraydef,recorddef,pointerdef,orddef,
              stringdef,enumdef,procdef,objectdef,errordef,
              filedef,formaldef,setdef,procvardef,floatdef,
              classrefdef,forwarddef,variantdef);

  { possible types for symtable entries }
  tsymtyp = (abstractsym,varsym,typesym,procsym,unitsym,
             constsym,enumsym,typedconstsym,errorsym,syssym,
             labelsym,absolutesym,propertysym,funcretsym,
             macrosym,rttisym);

  { State of the variable, if it's declared, assigned or used }
  tvarstate=(vs_none,
    vs_declared,vs_declared_and_first_found,
    vs_set_but_first_not_passed,vs_assigned,vs_used
  );

  absolutetyp = (tovar,toasm,toaddr);

  tconsttyp = (constnone,
    constord,conststring,constreal,constbool,
    constint,constchar,constset,constpointer,constnil,
    constresourcestring,constwstring,constwchar,constguid
  );

  { RTTI information to store }
  trttitype = (
    fullrtti,initrtti
  );

{$ifdef GDB}
type
  tdefstabstatus = (
    not_written,
    being_written,
    written);

const
  tagtypes : Set of tdeftype =
    [recorddef,enumdef,
    {$IfNDef GDBKnowsStrings}
    stringdef,
    {$EndIf not GDBKnowsStrings}
    {$IfNDef GDBKnowsFiles}
    filedef,
    {$EndIf not GDBKnowsFiles}
    objectdef];
{$endif GDB}

const
  { relevant options for assigning a proc or a procvar to a procvar }
  po_compatibility_options = [
    po_classmethod,
    po_staticmethod,
    po_methodpointer,
    po_containsself,
    po_interrupt,
    po_iocheck,
    po_varargs,
    po_exports
  ];

const
     SymTypeName : array[tsymtyp] of string[12] =
     ('abstractsym','variable','type','proc','unit',
      'const','enum','typed const','errorsym','system sym',
      'label','absolute','property','funcret',
      'macrosym','rttisym');

implementation

end.
{
  $Log$
  Revision 1.25  2001-10-21 12:33:07  peter
    * array access for properties added

  Revision 1.24  2001/10/20 20:30:21  peter
    * read only typed const support, switch $J-

  Revision 1.23  2001/08/30 20:13:54  peter
    * rtti/init table updates
    * rttisym for reusable global rtti/init info
    * support published for interfaces

  Revision 1.22  2001/08/19 21:11:21  florian
    * some bugs fix:
      - overload; with external procedures fixed
      - better selection of routine to do an overloaded
        type case
      - ... some more

  Revision 1.21  2001/08/01 15:07:29  jonas
    + "compilerproc" directive support, which turns both the public and mangled
      name to lowercase(declaration_name). This prevents a normal user from
      accessing the routine, but they can still be easily looked up within
      the compiler. This is used for helper procedures and should facilitate
      the writing of more processor independent code in the code generator
      itself (mostly written by Peter)
    + new "createintern" constructor for tcal nodes to create a call to
      helper exported using the "compilerproc" directive
    + support for high(dynamic_array) using the the above new things
    + definition of 'HASCOMPILERPROC' symbol (to be able to check in the
      compiler and rtl whether the "compilerproc" directive is supported)

  Revision 1.20  2001/06/04 18:14:54  peter
    * varargs added for proc to procvar comparison

  Revision 1.19  2001/06/04 11:53:13  peter
    + varargs directive

  Revision 1.18  2001/06/03 21:57:38  peter
    + hint directive parsing support

  Revision 1.17  2001/05/08 21:06:31  florian
    * some more support for widechars commited especially
      regarding type casting and constants

  Revision 1.16  2001/04/13 01:22:15  peter
    * symtable change to classes
    * range check generation and errors fixed, make cycle DEBUG=1 works
    * memory leaks fixed

  Revision 1.15  2001/04/02 21:20:34  peter
    * resulttype rewrite

  Revision 1.14  2001/03/22 00:10:58  florian
    + basic variant type support in the compiler

  Revision 1.13  2001/02/26 19:44:55  peter
    * merged generic m68k updates from fixes branch

  Revision 1.12  2000/11/04 14:25:21  florian
    + merged Attila's changes for interfaces, not tested yet

  Revision 1.11  2000/10/31 22:02:51  peter
    * symtable splitted, no real code changes

  Revision 1.9  2000/10/15 07:47:52  peter
    * unit names and procedure names are stored mixed case

  Revision 1.8  2000/10/14 10:14:52  peter
    * moehrendorf oct 2000 rewrite

  Revision 1.7  2000/09/24 15:06:28  peter
    * use defines.inc

  Revision 1.6  2000/08/21 11:27:44  pierre
   * fix the stabs problems

  Revision 1.5  2000/08/06 19:39:28  peter
    * default parameters working !

  Revision 1.4  2000/08/05 13:25:06  peter
    * packenum 1 fixes (merged)

  Revision 1.3  2000/07/13 12:08:27  michael
  + patched to 1.1.0 with former 1.09patch from peter

  Revision 1.2  2000/07/13 11:32:49  michael
  + removed logs

}
