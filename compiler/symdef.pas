{
    Symbol table implementation for the definitions

    Copyright (c) 1998-2005 by Florian Klaempfl, Pierre Muller

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
unit symdef;

{$i fpcdefs.inc}

interface

    uses
       { common }
       cclasses,
       { global }
       globtype,globals,tokens,constexp,
       { symtable }
       symconst,symbase,symtype,
       { ppu }
       ppu,
       { node }
       node,
       { aasm }
       aasmbase,aasmtai,aasmdata,
       cpubase,cpuinfo,
       cgbase,cgutils,
       parabase
       ;


    type
{************************************************
                    TDef
************************************************}

       { tstoreddef }

       tstoreddef = class(tdef)
       protected
          typesymderef  : tderef;
       public
{$ifdef EXTDEBUG}
          fileinfo   : tfileposinfo;
{$endif}
          { generic support }
          genericdef      : tstoreddef;
          genericdefderef : tderef;
          generictokenbuf : tdynamicarray;
          constructor create(dt:tdeftyp);
          constructor ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
          destructor  destroy;override;
          function getcopy : tstoreddef;virtual;
          procedure ppuwrite(ppufile:tcompilerppufile);virtual;
          procedure buildderef;override;
          procedure buildderefimpl;override;
          procedure deref;override;
          procedure derefimpl;override;
          function  size:aint;override;
          function  getvardef:longint;override;
          function  alignment:shortint;override;
          function  is_publishable : boolean;override;
          function  needs_inittable : boolean;override;
          function  rtti_mangledname(rt:trttitype):string;override;
          function  in_currentunit: boolean;
          { regvars }
          function is_intregable : boolean;
          function is_fpuregable : boolean;
          { generics }
          procedure initgeneric;
       private
          savesize  : aint;
       end;

       tfiletyp = (ft_text,ft_typed,ft_untyped);

       tfiledef = class(tstoreddef)
          filetyp : tfiletyp;
          typedfiledef : tdef;
          typedfiledefderef : tderef;
          constructor createtext;
          constructor createuntyped;
          constructor createtyped(def : tdef);
          constructor ppuload(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderef;override;
          procedure deref;override;
          function  GetTypeName:string;override;
          function  getmangledparaname:string;override;
          procedure setsize;
       end;

       tvariantdef = class(tstoreddef)
          varianttype : tvarianttype;
          constructor create(v : tvarianttype);
          constructor ppuload(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          function GetTypeName:string;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  getvardef:longint;override;
          procedure setsize;
          function is_publishable : boolean;override;
          function needs_inittable : boolean;override;
       end;

       tformaldef = class(tstoreddef)
          typed:boolean;
          constructor create(Atyped:boolean);
          constructor ppuload(ppufile:tcompilerppufile);
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
       end;

       tforwarddef = class(tstoreddef)
          tosymname : pshortstring;
          forwardpos : tfileposinfo;
          constructor create(const s:string;const pos : tfileposinfo);
          destructor destroy;override;
          function  GetTypeName:string;override;
       end;

       tundefineddef = class(tstoreddef)
          constructor create;
          constructor ppuload(ppufile:tcompilerppufile);
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
       end;

       terrordef = class(tstoreddef)
          constructor create;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
          function  getmangledparaname : string;override;
       end;

       tabstractpointerdef = class(tstoreddef)
          pointeddef : tdef;
          pointeddefderef : tderef;
          constructor create(dt:tdeftyp;def:tdef);
          constructor ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderef;override;
          procedure deref;override;
       end;

       tpointerdef = class(tabstractpointerdef)
          is_far : boolean;
          constructor create(def:tdef);
          constructor createfar(def:tdef);
          function getcopy : tstoreddef;override;
          constructor ppuload(ppufile:tcompilerppufile);
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
       end;

       { tabstractrecorddef }

       tabstractrecorddef= class(tstoreddef)
          objname,
          objrealname: PShortString;
          symtable : TSymtable;
          cloneddef      : tabstractrecorddef;
          cloneddefderef : tderef;
          objectoptions  : tobjectoptions;
          constructor create(const n:string; dt:tdeftyp);
          constructor ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          destructor destroy; override;
          function  GetSymtable(t:tGetSymtable):TSymtable;override;
          function is_packed:boolean;
          function RttiName: string;
       end;

       trecorddef = class(tabstractrecorddef)
       public
          isunion       : boolean;
          constructor create(const n:string; p:TSymtable);
          constructor ppuload(ppufile:tcompilerppufile);
          destructor destroy;override;
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderef;override;
          procedure deref;override;
          function  size:aint;override;
          function  alignment : shortint;override;
          function  padalignment: shortint;
          function  GetTypeName:string;override;
          { debug }
          function  needs_inittable : boolean;override;
       end;

       tprocdef = class;
       tobjectdef = class;

       { TImplementedInterface }

       TImplementedInterface = class
         IntfDef      : tobjectdef;
         IntfDefDeref : tderef;
         IType        : tinterfaceentrytype;
         IOffset      : longint;
         VtblImplIntf : TImplementedInterface;
         NameMappings : TFPHashList;
         ProcDefs     : TFPObjectList;
         ImplementsGetter :  tsym;
         constructor create(aintf: tobjectdef);
         constructor create_deref(d:tderef);
         destructor  destroy; override;
         function  getcopy:TImplementedInterface;
         procedure buildderef;
         procedure deref;
         procedure AddMapping(const origname, newname: string);
         function  GetMapping(const origname: string):string;
         procedure AddImplProc(pd:tprocdef);
         function  IsImplMergePossible(MergingIntf:TImplementedInterface;out weight: longint): boolean;
       end;

       { tvmtentry }
       tvmtentry = record
         procdef      : tprocdef;
         procdefderef : tderef;
         visibility   : tvisibility;
       end;
       pvmtentry = ^tvmtentry;

       { tobjectdef }

       tvmcallstatic = (vmcs_default, vmcs_yes, vmcs_no, vmcs_unreachable);
       pmvcallstaticinfo = ^tmvcallstaticinfo;
       tmvcallstaticinfo = array[0..1024*1024-1] of tvmcallstatic;
       tobjectdef = class(tabstractrecorddef)
       private
          fcurrent_dispid: longint;
       public
          dwarf_struct_lab : tasmsymbol;
          childof        : tobjectdef;
          childofderef   : tderef;

          { for C++ classes: name of the library this class is imported from }
          import_lib,
          { for Objective-C: protocols and classes can have the same name there }
          objextname     : pshortstring;
          { to be able to have a variable vmt position }
          { and no vmt field for objects without virtuals }
          vmtentries     : TFPList;
          vmcallstaticinfo : pmvcallstaticinfo;
          vmt_offset     : longint;
          objecttype     : tobjecttyp;
          iidguid        : pguid;
          iidstr         : pshortstring;
          writing_class_record_dbginfo,
          { a class of this type has been created in this module }
          created_in_current_module,
          { a loadvmtnode for this class has been created in this
            module, so if a classrefdef variable of this or a parent
            class is used somewhere to instantiate a class, then this
            class may be instantiated
          }
          maybe_created_in_current_module,
          { a "class of" this particular class has been created in
            this module
          }
          classref_created_in_current_module : boolean;
          { store implemented interfaces defs and name mappings }
          ImplementedInterfaces : TFPObjectList;
          constructor create(ot:tobjecttyp;const n:string;c:tobjectdef);
          constructor ppuload(ppufile:tcompilerppufile);
          destructor  destroy;override;
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function GetTypeName:string;override;
          procedure buildderef;override;
          procedure deref;override;
          procedure buildderefimpl;override;
          procedure derefimpl;override;
          procedure resetvmtentries;
          procedure copyvmtentries(objdef:tobjectdef);
          function  getparentdef:tdef;override;
          function  size : aint;override;
          function  alignment:shortint;override;
          function  vmtmethodoffset(index:longint):longint;
          function  members_need_inittable : boolean;
          function  find_implemented_interface(aintfdef:tobjectdef):TImplementedInterface;
          { this should be called when this class implements an interface }
          procedure prepareguid;
          function  is_publishable : boolean;override;
          function  is_related(d : tdef) : boolean;override;
          function  needs_inittable : boolean;override;
          function  rtti_mangledname(rt:trttitype):string;override;
          function  vmt_mangledname : string;
          procedure check_forwards;
          procedure insertvmt;
          procedure set_parent(c : tobjectdef);
          function find_procdef_bytype(pt:tproctypeoption): tprocdef;
          function find_destructor: tprocdef;
          function implements_any_interfaces: boolean;
          { dispinterface support }
          function get_next_dispid: longint;
          { enumerator support }
          function search_enumerator_get: tprocdef;
          function search_enumerator_move: tprocdef;
          function search_enumerator_current: tsym;
          { WPO }
          procedure register_created_object_type;override;
          procedure register_maybe_created_object_type;
          procedure register_created_classref_type;
          procedure register_vmt_call(index:longint);
          { ObjC & C++ }
          procedure make_all_methods_external;
          { ObjC }
          procedure finish_objc_data;
          function check_objc_types: boolean;
          { C++ }
          procedure finish_cpp_data;
       end;

       tclassrefdef = class(tabstractpointerdef)
          constructor create(def:tdef);
          constructor ppuload(ppufile:tcompilerppufile);
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
          function  is_publishable : boolean;override;
          function  rtti_mangledname(rt:trttitype):string;override;
          procedure register_created_object_type;override;
       end;

       tarraydef = class(tstoreddef)
          lowrange,
          highrange  : aint;
          rangedef   : tdef;
          rangedefderef : tderef;
          arrayoptions : tarraydefoptions;
       protected
          _elementdef : tdef;
          _elementdefderef : tderef;
          procedure setelementdef(def:tdef);
       public
          function elesize : aint;
          function elepackedbitsize : aint;
          function elecount : aword;
          constructor create_from_pointer(def:tdef);
          constructor create(l,h : aint;def:tdef);
          constructor ppuload(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
          function  getmangledparaname : string;override;
          procedure buildderef;override;
          procedure deref;override;
          function size : aint;override;
          function alignment : shortint;override;
          { returns the label of the range check string }
          function needs_inittable : boolean;override;
          property elementdef : tdef read _elementdef write setelementdef;
          function is_publishable : boolean;override;
       end;

       torddef = class(tstoreddef)
          low,high : TConstExprInt;
          ordtype  : tordtype;
          constructor create(t : tordtype;v,b : TConstExprInt);
          constructor ppuload(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  is_publishable : boolean;override;
          function  GetTypeName:string;override;
          function alignment:shortint;override;
          procedure setsize;
          function  packedbitsize: aint; override;
          function getvardef : longint;override;
       end;

       tfloatdef = class(tstoreddef)
          floattype : tfloattype;
          constructor create(t : tfloattype);
          constructor ppuload(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
          function  is_publishable : boolean;override;
          function alignment:shortint;override;
          procedure setsize;
          function  getvardef:longint;override;
       end;

       { tabstractprocdef }

       tabstractprocdef = class(tstoreddef)
          { saves a definition to the return type }
          returndef       : tdef;
          returndefderef  : tderef;
          parast          : TSymtable;
          paras           : tparalist;
          proctypeoption  : tproctypeoption;
          proccalloption  : tproccalloption;
          procoptions     : tprocoptions;
          callerargareasize,
          calleeargareasize: pint;
          { number of user visibile parameters }
          maxparacount,
          minparacount    : byte;
{$ifdef m68k}
          exp_funcretloc : tregister;   { explicit funcretloc for AmigaOS }
{$endif}
          funcretloc : array[tcallercallee] of TCGPara;
          has_paraloc_info : tcallercallee; { paraloc info is available }
          constructor create(dt:tdeftyp;level:byte);
          constructor ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
          destructor destroy;override;
          procedure  ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderef;override;
          procedure deref;override;
          procedure calcparas;
          function  typename_paras(showhidden:boolean): string;
          function  is_methodpointer:boolean;virtual;
          function  is_addressonly:boolean;virtual;
          function  no_self_node:boolean;
          procedure check_mark_as_nested;
          procedure init_paraloc_info(side: tcallercallee);
          function stack_tainting_parameter(side: tcallercallee): boolean;
       private
          procedure count_para(p:TObject;arg:pointer);
          procedure insert_para(p:TObject;arg:pointer);
       end;

       tprocvardef = class(tabstractprocdef)
          constructor create(level:byte);
          constructor ppuload(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetSymtable(t:tGetSymtable):TSymtable;override;
          function  size : aint;override;
          function  GetTypeName:string;override;
          function  is_publishable : boolean;override;
          function  is_methodpointer:boolean;override;
          function  is_addressonly:boolean;override;
          function  getmangledparaname:string;override;
       end;

       tmessageinf = record
         case integer of
           0 : (str : pshortstring);
           1 : (i : longint);
       end;

       tinlininginfo = record
          { node tree }
          code  : tnode;
          flags : tprocinfoflags;
       end;
       pinlininginfo = ^tinlininginfo;


{$ifdef oldregvars}
       { register variables }
       pregvarinfo = ^tregvarinfo;
       tregvarinfo = record
          regvars : array[1..maxvarregs] of tsym;
          regvars_para : array[1..maxvarregs] of boolean;
          regvars_refs : array[1..maxvarregs] of longint;

          fpuregvars : array[1..maxfpuvarregs] of tsym;
          fpuregvars_para : array[1..maxfpuvarregs] of boolean;
          fpuregvars_refs : array[1..maxfpuvarregs] of longint;
       end;
{$endif oldregvars}

       { tprocdef }

       tprocdef = class(tabstractprocdef)
       private
          _mangledname : pshortstring;
       public
          messageinf : tmessageinf;
          dispid : longint;
{$ifndef EXTDEBUG}
          { where is this function defined and what were the symbol
            flags, needed here because there
            is only one symbol for all overloaded functions
            EXTDEBUG has fileinfo in tdef (PFV) }
          fileinfo : tfileposinfo;
{$endif}
          symoptions : tsymoptions;
          deprecatedmsg : pshortstring;
          { symbol owning this definition }
          procsym : tsym;
          procsymderef : tderef;
          { alias names }
          aliasnames : TCmdStrList;
          { symtables }
          localst : TSymtable;
          funcretsym : tsym;
          funcretsymderef : tderef;
          struct : tabstractrecorddef;
          structderef : tderef;
{$if defined(powerpc) or defined(m68k)}
          { library symbol for AmigaOS/MorphOS }
          libsym : tsym;
          libsymderef : tderef;
{$endif powerpc or m68k}
          { name of the result variable to insert in the localsymtable }
          resultname : pshortstring;
          { import info }
          import_dll,
          import_name : pshortstring;
          { info for inlining the subroutine, if this pointer is nil,
            the procedure can't be inlined }
          inlininginfo : pinlininginfo;
{$ifdef oldregvars}
          regvarinfo: pregvarinfo;
{$endif oldregvars}
          { First/last assembler symbol/instruction in aasmoutput list.
            Note: initialised after compiling the code for the procdef, but
              not saved to/restored from ppu. Used when inserting debug info }
          procstarttai,
          procendtai   : tai;
          import_nr    : word;
          extnumber    : word;
{$ifdef i386}
          fpu_used     : byte;
{$endif i386}
          visibility   : tvisibility;
          { true, if the procedure is only declared
            (forward procedure) }
          forwarddef,
          { true if the procedure is declared in the interface }
          interfacedef : boolean;
          { true if the procedure has a forward declaration }
          hasforward  : boolean;
          constructor create(level:byte);
          constructor ppuload(ppufile:tcompilerppufile);
          destructor  destroy;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderef;override;
          procedure buildderefimpl;override;
          procedure deref;override;
          procedure derefimpl;override;
          function  GetSymtable(t:tGetSymtable):TSymtable;override;
          function  GetTypeName : string;override;
          function  mangledname : string;
          procedure setmangledname(const s : string);
          function  fullprocname(showhidden:boolean):string;
          function  cplusplusmangledname : string;
          function  objcmangledname : string;
          function  is_methodpointer:boolean;override;
          function  is_addressonly:boolean;override;
       end;

       { single linked list of overloaded procs }
       pprocdeflist = ^tprocdeflist;
       tprocdeflist = record
         def  : tprocdef;
         defderef : tderef;
         next : pprocdeflist;
       end;

       tstringdef = class(tstoreddef)
          stringtype : tstringtype;
          len        : aint;
          constructor createshort(l : byte);
          constructor loadshort(ppufile:tcompilerppufile);
          constructor createlong(l : aint);
          constructor loadlong(ppufile:tcompilerppufile);
          constructor createansi;
          constructor loadansi(ppufile:tcompilerppufile);
          constructor createwide;
          constructor loadwide(ppufile:tcompilerppufile);
          constructor createunicode;
          constructor loadunicode(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          function  stringtypname:string;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          function  GetTypeName:string;override;
          function  getmangledparaname:string;override;
          function  is_publishable : boolean;override;
          function alignment : shortint;override;
          function  needs_inittable : boolean;override;
          function  getvardef:longint;override;
       end;

       { tenumdef }

       tenumdef = class(tstoreddef)
          minval,
          maxval    : aint;
          has_jumps : boolean;
          basedef   : tenumdef;
          basedefderef : tderef;
          symtable  : TSymtable;
          constructor create;
          constructor create_subrange(_basedef:tenumdef;_min,_max:aint);
          constructor ppuload(ppufile:tcompilerppufile);
          destructor destroy;override;
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderef;override;
          procedure deref;override;
          function  GetTypeName:string;override;
          function  is_publishable : boolean;override;
          procedure calcsavesize;
          function  packedbitsize: aint; override;
          procedure setmax(_max:aint);
          procedure setmin(_min:aint);
          function  min:aint;
          function  max:aint;
          function  getfirstsym:tsym;
       end;

       tsetdef = class(tstoreddef)
          elementdef : tdef;
          elementdefderef : tderef;
          setbase,
          setmax   : aword;
          constructor create(def:tdef;low, high : aint);
          constructor ppuload(ppufile:tcompilerppufile);
          function getcopy : tstoreddef;override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderef;override;
          procedure deref;override;
          function  GetTypeName:string;override;
          function  is_publishable : boolean;override;
       end;

    var
       current_structdef: tabstractrecorddef;
       current_objectdef : tobjectdef absolute current_structdef;  { used for private functions check !! }
       current_genericdef : tobjectdef; { used to reject declaration of generic class inside generic class }
       current_specializedef : tobjectdef; { used to implement usage of generic class in itself }

    { default types }
       generrordef,              { error in definition }
       voidpointertype,           { pointer for Void-pointeddef }
       charpointertype,           { pointer for Char-pointeddef }
       widecharpointertype,       { pointer for WideChar-pointeddef }
       voidfarpointertype,
       cundefinedtype,
       cformaltype,               { unique formal definition }
       ctypedformaltype,          { unique typed formal definition }
       voidtype,                  { Void (procedure) }
       cchartype,                 { Char }
       cwidechartype,             { WideChar }
       booltype,                  { boolean type }
       bool8type,
       bool16type,
       bool32type,
       bool64type,                { implement me }
       u8inttype,                 { 8-Bit unsigned integer }
       s8inttype,                 { 8-Bit signed integer }
       u16inttype,                { 16-Bit unsigned integer }
       s16inttype,                { 16-Bit signed integer }
       u32inttype,                { 32-Bit unsigned integer }
       s32inttype,                { 32-Bit signed integer }
       u64inttype,                { 64-bit unsigned integer }
       s64inttype,                { 64-bit signed integer }
       s32floattype,              { 32 bit floating point number }
       s64floattype,              { 64 bit floating point number }
       s80floattype,              { 80 bit floating point number }
       sc80floattype,             { 80 bit floating point number but stored like in C }
       s64currencytype,           { pointer to a currency type }
       cshortstringtype,          { pointer to type of short string const   }
       clongstringtype,           { pointer to type of long string const   }
       cansistringtype,           { pointer to type of ansi string const  }
       cwidestringtype,           { pointer to type of wide string const  }
       cunicodestringtype,
       openshortstringtype,       { pointer to type of an open shortstring,
                                    needed for readln() }
       openchararraytype,         { pointer to type of an open array of char,
                                    needed for readln() }
       cfiletype,                 { get the same definition for all file }
                                  { used for stabs }
       methodpointertype,         { typecasting of methodpointers to extract self }
       hresultdef,
       { we use only one variant def for every variant class }
       cvarianttype,
       colevarianttype,
       { default integer type s32inttype on 32 bit systems, s64bittype on 64 bit systems }
       sinttype,
       uinttype,
       { unsigned and signed ord type with the same size as a pointer }
       ptruinttype,
       ptrsinttype,
       { several types to simulate more or less C++ objects for GDB }
       vmttype,
       vmtarraytype,
       pvmttype      : tdef;     { type of classrefs, used for stabs }

       { pointer to the anchestor of all classes }
       class_tobject : tobjectdef;
       { pointer to the ancestor of all COM interfaces }
       interface_iunknown : tobjectdef;
       { pointer to the TGUID type
         of all interfaces         }
       rec_tguid : trecorddef;

       { pointer to jump buffer }
       rec_jmp_buf : trecorddef;

       { Objective-C base types }
       objc_metaclasstype,
       objc_superclasstype,
       objc_idtype,
       objc_seltype              : tpointerdef;
       objc_objecttype           : trecorddef;
       { base type of @protocol(protocolname) Objective-C statements }
       objc_protocoltype         : tobjectdef;
       { helper types for for-in "fast enumeration" support in Objective-C 2.0 }
       objc_fastenumeration      : tobjectdef;
       objc_fastenumerationstate : trecorddef;

    const
{$ifdef i386}
       pbestrealtype : ^tdef = @s80floattype;
{$endif}
{$ifdef x86_64}
       pbestrealtype : ^tdef = @s80floattype;
{$endif}
{$ifdef m68k}
       pbestrealtype : ^tdef = @s64floattype;
{$endif}
{$ifdef alpha}
       pbestrealtype : ^tdef = @s64floattype;
{$endif}
{$ifdef powerpc}
       pbestrealtype : ^tdef = @s64floattype;
{$endif}
{$ifdef POWERPC64}
       pbestrealtype : ^tdef = @s64floattype;
{$endif}
{$ifdef ia64}
       pbestrealtype : ^tdef = @s64floattype;
{$endif}
{$ifdef SPARC}
       pbestrealtype : ^tdef = @s64floattype;
{$endif SPARC}
{$ifdef vis}
       pbestrealtype : ^tdef = @s64floattype;
{$endif vis}
{$ifdef ARM}
       pbestrealtype : ^tdef = @s64floattype;
{$endif ARM}
{$ifdef MIPS}
       pbestrealtype : ^tdef = @s64floattype;
{$endif MIPS}
{$ifdef AVR}
       pbestrealtype : ^tdef = @s64floattype;
{$endif AVR}

    function make_mangledname(const typeprefix:string;st:TSymtable;const suffix:string):string;

    { should be in the types unit, but the types unit uses the node stuff :( }
    function is_interfacecom(def: tdef): boolean;
    function is_interfacecorba(def: tdef): boolean;
    function is_interface(def: tdef): boolean;
    function is_dispinterface(def: tdef): boolean;
    function is_object(def: tdef): boolean;
    function is_class(def: tdef): boolean;
    function is_cppclass(def: tdef): boolean;
    function is_objcclass(def: tdef): boolean;
    function is_objcclassref(def: tdef): boolean;
    function is_objcprotocol(def: tdef): boolean;
    function is_objccategory(def: tdef): boolean;
    function is_objc_class_or_protocol(def: tdef): boolean;
    function is_objc_protocol_or_category(def: tdef): boolean;
    function is_class_or_interface(def: tdef): boolean;
    function is_class_or_interface_or_objc(def: tdef): boolean;
    function is_class_or_interface_or_object(def: tdef): boolean;
    function is_class_or_interface_or_dispinterface(def: tdef): boolean;
    function is_class_or_interface_or_dispinterface_or_objc(def: tdef): boolean;
    function is_class_or_object(def: tdef): boolean;
    function is_record(def: tdef): boolean;

    procedure loadobjctypes;
    procedure maybeloadcocoatypes;

    function use_vectorfpu(def : tdef) : boolean;

implementation

    uses
      SysUtils,
      cutils,
      { global }
      verbose,
      { target }
      systems,aasmcpu,paramgr,
      { symtable }
      symsym,symtable,symutil,defutil,objcdef,
      { module }
      fmodule,
      { other }
      gendef,
      fpccrc
      ;

{****************************************************************************
                                  Helpers
****************************************************************************}

    function make_mangledname(const typeprefix:string;st:TSymtable;const suffix:string):string;
      var
        s,hs,
        prefix : string;
        oldlen,
        newlen,
        i   : longint;
        crc : dword;
        hp  : tparavarsym;
      begin
        prefix:='';
        if not assigned(st) then
         internalerror(200204212);
        { sub procedures }
        while (st.symtabletype=localsymtable) do
         begin
           if st.defowner.typ<>procdef then
            internalerror(200204173);
           { Add the full mangledname of procedure to prevent
             conflicts with 2 overloads having both a nested procedure
             with the same name, see tb0314 (PFV) }
           s:=tprocdef(st.defowner).procsym.name;
           oldlen:=length(s);
           for i:=0 to tprocdef(st.defowner).paras.count-1 do
            begin
              hp:=tparavarsym(tprocdef(st.defowner).paras[i]);
              if not(vo_is_hidden_para in hp.varoptions) then
                s:=s+'$'+hp.vardef.mangledparaname;
            end;
           if not is_void(tprocdef(st.defowner).returndef) then
             s:=s+'$$'+tprocdef(st.defowner).returndef.mangledparaname;
           newlen:=length(s);
           { Replace with CRC if the parameter line is very long }
           if (newlen-oldlen>12) and
              ((newlen+length(prefix)>100) or (newlen-oldlen>32)) then
             begin
               crc:=0;
               for i:=0 to tprocdef(st.defowner).paras.count-1 do
                 begin
                   hp:=tparavarsym(tprocdef(st.defowner).paras[i]);
                   if not(vo_is_hidden_para in hp.varoptions) then
                     begin
                       hs:=hp.vardef.mangledparaname;
                       crc:=UpdateCrc32(crc,hs[1],length(hs));
                     end;
                 end;
               hs:=hp.vardef.mangledparaname;
               crc:=UpdateCrc32(crc,hs[1],length(hs));
               s:=Copy(s,1,oldlen)+'$crc'+hexstr(crc,8);
             end;
           if prefix<>'' then
             prefix:=s+'_'+prefix
           else
             prefix:=s;
           if length(prefix)>100 then
             begin
               crc:=0;
               crc:=UpdateCrc32(crc,prefix[1],length(prefix));
               prefix:='$CRC'+hexstr(crc,8);
             end;
           st:=st.defowner.owner;
         end;
        { object/classes symtable, nested type definitions in classes require the while loop }
        while st.symtabletype in [ObjectSymtable,recordsymtable] do
         begin
           if not (st.defowner.typ in [objectdef,recorddef]) then
            internalerror(200204174);
           prefix:=tabstractrecorddef(st.defowner).objname^+'_$_'+prefix;
           st:=st.defowner.owner;
         end;
        { symtable must now be static or global }
        if not(st.symtabletype in [staticsymtable,globalsymtable]) then
          internalerror(200204175);
        result:='';
        if typeprefix<>'' then
          result:=result+typeprefix+'_';
        { Add P$ for program, which can have the same name as
          a unit }
        if (TSymtable(main_module.localsymtable)=st) and
           (not main_module.is_unit) then
          result:=result+'P$'+st.name^
        else
          result:=result+st.name^;
        if prefix<>'' then
          result:=result+'_'+prefix;
        if suffix<>'' then
          result:=result+'_'+suffix;
        { the Darwin assembler assumes that all symbols starting with 'L' are local }
        { Further, the Mac OS X 10.5 linker does not consider symbols which do not  }
        { start with '_' as regular symbols (it does not generate N_GSYM entries    }
        { those in the debug map, leading to troubles with dsymutil). So always     }
        { add an underscore on darwin.                                              }
        if (target_info.system in systems_darwin) then
          result := '_' + result;
      end;


{****************************************************************************
                     TDEF (base class for definitions)
****************************************************************************}

    constructor tstoreddef.create(dt:tdeftyp);
      var
        insertstack : psymtablestackitem;
      begin
         inherited create(dt);
         savesize := 0;
{$ifdef EXTDEBUG}
         fileinfo := current_filepos;
{$endif}
         generictokenbuf:=nil;
         genericdef:=nil;
         { Don't register forwarddefs, they are disposed at the
           end of an type block }
         if (dt=forwarddef) then
           exit;
         { Register in current_module }
         if assigned(current_module) then
           begin
             current_module.deflist.Add(self);
             DefId:=current_module.deflist.Count-1;
           end;
         { Register in symtable stack }
         if assigned(symtablestack) then
           begin
             insertstack:=symtablestack.stack;
             while assigned(insertstack) and
                   (insertstack^.symtable.symtabletype=withsymtable) do
               insertstack:=insertstack^.next;
             if not assigned(insertstack) then
               internalerror(200602044);
             insertstack^.symtable.insertdef(self);
           end;
      end;


    destructor tstoreddef.destroy;
      begin
        { Direct calls are not allowed, use symtable.deletedef() }
        if assigned(owner) then
          internalerror(200612311);
        if assigned(generictokenbuf) then
          begin
            generictokenbuf.free;
            generictokenbuf:=nil;
          end;
        inherited destroy;
      end;


    constructor tstoreddef.ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
      var
        sizeleft,i : longint;
        buf  : array[0..255] of byte;
      begin
         inherited create(dt);
         DefId:=ppufile.getlongint;
         current_module.deflist[DefId]:=self;
{$ifdef EXTDEBUG}
         fillchar(fileinfo,sizeof(fileinfo),0);
{$endif}
         { load }
         ppufile.getderef(typesymderef);
         ppufile.getsmallset(defoptions);
         ppufile.getsmallset(defstates);
         if df_generic in defoptions then
           begin
             sizeleft:=ppufile.getlongint;
             initgeneric;
             while sizeleft>0 do
               begin
                 if sizeleft>sizeof(buf) then
                   i:=sizeof(buf)
                 else
                   i:=sizeleft;
                 ppufile.getdata(buf,i);
                 generictokenbuf.write(buf,i);
                 dec(sizeleft,i);
               end;
           end;
        if df_specialization in defoptions then
          ppufile.getderef(genericdefderef);
      end;


    function Tstoreddef.rtti_mangledname(rt:trttitype):string;
      var
        prefix : string[4];
      begin
        if rt=fullrtti then
          begin
            prefix:='RTTI';
            include(defstates,ds_rtti_table_used);
          end
        else
          begin
            prefix:='INIT';
            include(defstates,ds_init_table_used);
          end;
        if assigned(typesym) and
           (owner.symtabletype in [staticsymtable,globalsymtable]) then
          result:=make_mangledname(prefix,owner,typesym.name)
        else
          result:=make_mangledname(prefix,findunitsymtable(owner),'DEF'+tostr(DefId))
      end;


    function tstoreddef.in_currentunit: boolean;
      var
        st: tsymtable;
      begin
        st:=owner;
        while not(st.symtabletype in [globalsymtable,staticsymtable]) do
          st:=st.defowner.owner;
        result:=st.iscurrentunit;
      end;


    function tstoreddef.getcopy : tstoreddef;
      begin
        Message(sym_e_cant_create_unique_type);
        getcopy:=terrordef.create;
      end;


    procedure tstoreddef.ppuwrite(ppufile:tcompilerppufile);
      var
        sizeleft,i : longint;
        buf  : array[0..255] of byte;
        oldintfcrc : boolean;
      begin
        ppufile.putlongint(DefId);
        ppufile.putderef(typesymderef);
        ppufile.putsmallset(defoptions);
        oldintfcrc:=ppufile.do_crc;
        ppufile.do_crc:=false;
        ppufile.putsmallset(defstates);
        if df_generic in defoptions then
          begin
            if assigned(generictokenbuf) then
              begin
                sizeleft:=generictokenbuf.size;
                generictokenbuf.seek(0);
              end
            else
              sizeleft:=0;
            ppufile.putlongint(sizeleft);
            while sizeleft>0 do
              begin
                if sizeleft>sizeof(buf) then
                  i:=sizeof(buf)
                else
                  i:=sizeleft;
                generictokenbuf.read(buf,i);
                ppufile.putdata(buf,i);
                dec(sizeleft,i);
              end;
          end;
        ppufile.do_crc:=oldintfcrc;
        if df_specialization in defoptions then
          ppufile.putderef(genericdefderef);
      end;


    procedure tstoreddef.buildderef;
      begin
        typesymderef.build(typesym);
        genericdefderef.build(genericdef);
      end;


    procedure tstoreddef.buildderefimpl;
      begin
      end;


    procedure tstoreddef.deref;
      begin
        typesym:=ttypesym(typesymderef.resolve);
        if df_specialization in defoptions then
          genericdef:=tstoreddef(genericdefderef.resolve);
      end;


    procedure tstoreddef.derefimpl;
      begin
      end;


    function tstoreddef.size : aint;
      begin
         size:=savesize;
      end;


    function tstoreddef.getvardef:longint;
      begin
        result:=varUndefined;
      end;


    function tstoreddef.alignment : shortint;
      begin
         { natural alignment by default }
         alignment:=size_2_align(savesize);
         { can happen if savesize = 0, e.g. for voiddef or
           an empty record
         }
         if (alignment=0) then
           alignment:=1;
      end;


    { returns true, if the definition can be published }
    function tstoreddef.is_publishable : boolean;
      begin
         is_publishable:=false;
      end;


    { needs an init table }
    function tstoreddef.needs_inittable : boolean;
      begin
         needs_inittable:=false;
      end;


   function tstoreddef.is_intregable : boolean;
     var
       recsize,temp: longint;
     begin
        is_intregable:=false;
        case typ of
          orddef,
          pointerdef,
          enumdef,
          classrefdef:
            is_intregable:=true;
          procvardef :
            is_intregable:=tprocvardef(self).is_addressonly;
          objectdef:
            is_intregable:=(is_class_or_interface_or_dispinterface_or_objc(self)) and not needs_inittable;
          setdef:
            is_intregable:=is_smallset(self);
          recorddef:
            begin
              recsize:=size;
              is_intregable:=
                ispowerof2(recsize,temp) and
                (recsize <= sizeof(aint));
            end;
        end;
     end;


   function tstoreddef.is_fpuregable : boolean;
     begin
{$ifdef x86}
       result:=use_vectorfpu(self);
{$else x86}
       result:=(typ=floatdef) and not(cs_fp_emulation in current_settings.moduleswitches);
{$endif x86}
     end;


   procedure tstoreddef.initgeneric;
     begin
       if assigned(generictokenbuf) then
         internalerror(200512131);
       generictokenbuf:=tdynamicarray.create(256);
     end;


{****************************************************************************
                               Tstringdef
****************************************************************************}

    constructor tstringdef.createshort(l : byte);
      begin
         inherited create(stringdef);
         stringtype:=st_shortstring;
         len:=l;
         savesize:=len+1;
      end;


    constructor tstringdef.loadshort(ppufile:tcompilerppufile);
      begin
         inherited ppuload(stringdef,ppufile);
         stringtype:=st_shortstring;
         len:=ppufile.getbyte;
         savesize:=len+1;
      end;


    constructor tstringdef.createlong(l : aint);
      begin
         inherited create(stringdef);
         stringtype:=st_longstring;
         len:=l;
         savesize:=sizeof(pint);
      end;


    constructor tstringdef.loadlong(ppufile:tcompilerppufile);
      begin
         inherited ppuload(stringdef,ppufile);
         stringtype:=st_longstring;
         len:=ppufile.getaint;
         savesize:=sizeof(pint);
      end;


    constructor tstringdef.createansi;
      begin
         inherited create(stringdef);
         stringtype:=st_ansistring;
         len:=-1;
         savesize:=sizeof(pint);
      end;


    constructor tstringdef.loadansi(ppufile:tcompilerppufile);
      begin
         inherited ppuload(stringdef,ppufile);
         stringtype:=st_ansistring;
         len:=ppufile.getaint;
         savesize:=sizeof(pint);
      end;


    constructor tstringdef.createwide;
      begin
         inherited create(stringdef);
         stringtype:=st_widestring;
         len:=-1;
         savesize:=sizeof(pint);
      end;


    constructor tstringdef.loadwide(ppufile:tcompilerppufile);
      begin
         inherited ppuload(stringdef,ppufile);
         stringtype:=st_widestring;
         len:=ppufile.getaint;
         savesize:=sizeof(pint);
      end;


    constructor tstringdef.createunicode;
      begin
         inherited create(stringdef);
         stringtype:=st_unicodestring;
         len:=-1;
         savesize:=sizeof(pint);
      end;


    constructor tstringdef.loadunicode(ppufile:tcompilerppufile);
      begin
         inherited ppuload(stringdef,ppufile);
         stringtype:=st_unicodestring;
         len:=ppufile.getaint;
         savesize:=sizeof(pint);
      end;


    function tstringdef.getcopy : tstoreddef;
      begin
        result:=tstringdef.create(typ);
        result.typ:=stringdef;
        tstringdef(result).stringtype:=stringtype;
        tstringdef(result).len:=len;
        tstringdef(result).savesize:=savesize;
      end;


    function tstringdef.stringtypname:string;
      const
        typname:array[tstringtype] of string[10]=(
          'shortstr','longstr','ansistr','widestr','unicodestr'
        );
      begin
        stringtypname:=typname[stringtype];
      end;


    procedure tstringdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         if stringtype=st_shortstring then
           begin
{$ifdef extdebug}
            if len > 255 then internalerror(12122002);
{$endif}
            ppufile.putbyte(byte(len))
           end
         else
           ppufile.putaint(len);
         case stringtype of
            st_shortstring : ppufile.writeentry(ibshortstringdef);
            st_longstring : ppufile.writeentry(iblongstringdef);
            st_ansistring : ppufile.writeentry(ibansistringdef);
            st_widestring : ppufile.writeentry(ibwidestringdef);
            st_unicodestring : ppufile.writeentry(ibunicodestringdef);
         end;
      end;


    function tstringdef.needs_inittable : boolean;
      begin
         needs_inittable:=stringtype in [st_ansistring,st_widestring,st_unicodestring];
      end;


    function tstringdef.GetTypeName : string;
      const
         names : array[tstringtype] of string[15] = (
           'ShortString','LongString','AnsiString','WideString','UnicodeString');
      begin
         GetTypeName:=names[stringtype];
      end;


    function tstringdef.getvardef : longint;
      const
        vardef : array[tstringtype] of longint = (
          varUndefined,varUndefined,varString,varOleStr,varUString);
      begin
        result:=vardef[stringtype];
      end;


    function tstringdef.alignment : shortint;
      begin
        case stringtype of
          st_unicodestring,
          st_widestring,
          st_ansistring:
            alignment:=size_2_align(savesize);
          st_longstring,
          st_shortstring:
              { char to string accesses byte 0 and 1 with one word access }
            if (tf_requires_proper_alignment in target_info.flags) or
              { macpas needs an alignment of 2 (MetroWerks compatible) }
               (m_mac in current_settings.modeswitches) then
              alignment:=size_2_align(2)
            else
              alignment:=size_2_align(1);
          else
            internalerror(200412301);
        end;
      end;


    function tstringdef.getmangledparaname : string;
      begin
        getmangledparaname:='STRING';
      end;


    function tstringdef.is_publishable : boolean;
      begin
         is_publishable:=true;
      end;


{****************************************************************************
                                 TENUMDEF
****************************************************************************}

    constructor tenumdef.create;
      begin
         inherited create(enumdef);
         minval:=0;
         maxval:=0;
         calcsavesize;
         has_jumps:=false;
         basedef:=nil;
         symtable:=tenumsymtable.create(self);
      end;


    constructor tenumdef.create_subrange(_basedef:tenumdef;_min,_max:aint);
      begin
         inherited create(enumdef);
         minval:=_min;
         maxval:=_max;
         basedef:=_basedef;
         calcsavesize;
         has_jumps:=false;
         symtable:=basedef.symtable.getcopy;
         include(defoptions, df_copied_def);
       end;


    constructor tenumdef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(enumdef,ppufile);
         minval:=ppufile.getaint;
         maxval:=ppufile.getaint;
         savesize:=ppufile.getaint;
         has_jumps:=false;
         if df_copied_def in defoptions then
           begin
             symtable:=nil;
             ppufile.getderef(basedefderef);
           end
         else
           begin
             // create with nil defowner first to prevent values changes on insert
             symtable:=tenumsymtable.create(nil);
             tenumsymtable(symtable).ppuload(ppufile);
             symtable.defowner:=self;
           end;
      end;

    destructor tenumdef.destroy;
      begin
        symtable.free;
        symtable:=nil;
        inherited destroy;
      end;


    function tenumdef.getcopy : tstoreddef;
      begin
        if assigned(basedef) then
          result:=tenumdef.create_subrange(basedef,minval,maxval)
        else
          begin
            result:=tenumdef.create;
            tenumdef(result).minval:=minval;
            tenumdef(result).maxval:=maxval;
            tenumdef(result).symtable.free;
            tenumdef(result).symtable:=symtable.getcopy;
            tenumdef(result).basedef:=self;
          end;
        tenumdef(result).has_jumps:=has_jumps;
        tenumdef(result).basedefderef:=basedefderef;
        include(tenumdef(result).defoptions,df_copied_def);
      end;


    procedure tenumdef.calcsavesize;
      begin
        if (current_settings.packenum=8) or (min<low(longint)) or (int64(max)>high(cardinal)) then
         savesize:=8
        else
         if (current_settings.packenum=4) or (min<low(smallint)) or (max>high(word)) then
          savesize:=4
        else
         if (current_settings.packenum=2) or (min<low(shortint)) or (max>high(byte)) then
          savesize:=2
        else
         savesize:=1;
      end;


    function tenumdef.packedbitsize: aint;
      var
        sizeval: tconstexprint;
        power: longint;
      begin
        result := 0;
        if (minval >= 0) and
           (maxval <= 1) then
          result := 1
        else
          begin
            if (minval>=0) then
              sizeval:=maxval
            else
              { don't count 0 twice }
              sizeval:=(cutils.max(-minval,maxval)*2)-1;
            { 256 must become 512 etc. }
            nextpowerof2(sizeval+1,power);
            result := power;
          end;
      end;


    procedure tenumdef.setmax(_max:aint);
      begin
        maxval:=_max;
        calcsavesize;
      end;


    procedure tenumdef.setmin(_min:aint);
      begin
        minval:=_min;
        calcsavesize;
      end;


    function tenumdef.min:aint;
      begin
        min:=minval;
      end;


    function tenumdef.max:aint;
      begin
        max:=maxval;
      end;

    function tenumdef.getfirstsym: tsym;
      var
        i:integer;
      begin
        for i := 0 to symtable.SymList.Count - 1 do
          begin
            result:=tsym(symtable.SymList[i]);
            if tenumsym(result).value=minval then
              exit;
          end;
        result:=nil;
      end;


    procedure tenumdef.buildderef;
      begin
        inherited buildderef;
        if df_copied_def in defoptions then
          basedefderef.build(basedef)
        else
          tenumsymtable(symtable).buildderef;
      end;


    procedure tenumdef.deref;
      begin
        inherited deref;
        if df_copied_def in defoptions then
          begin
            basedef:=tenumdef(basedefderef.resolve);
            symtable:=basedef.symtable.getcopy;
          end
        else
          tenumsymtable(symtable).deref;
      end;


    procedure tenumdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putaint(min);
         ppufile.putaint(max);
         ppufile.putaint(savesize);
         if df_copied_def in defoptions then
           ppufile.putderef(basedefderef);
         ppufile.writeentry(ibenumdef);
         if not (df_copied_def in defoptions) then
           tenumsymtable(symtable).ppuwrite(ppufile);
      end;


    function tenumdef.is_publishable : boolean;
      begin
         is_publishable:=true;
      end;


    function tenumdef.GetTypeName : string;
      begin
         GetTypeName:='<enumeration type>';
      end;


{****************************************************************************
                                 TORDDEF
****************************************************************************}

    constructor torddef.create(t : tordtype;v,b : TConstExprInt);
      begin
         inherited create(orddef);
         low:=v;
         high:=b;
         ordtype:=t;
         setsize;
      end;


    constructor torddef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(orddef,ppufile);
         ordtype:=tordtype(ppufile.getbyte);
         low:=ppufile.getexprint;
         high:=ppufile.getexprint;
         setsize;
      end;


    function torddef.getcopy : tstoreddef;
      begin
         result:=torddef.create(ordtype,low,high);
         result.typ:=orddef;
         torddef(result).low:=low;
         torddef(result).high:=high;
         torddef(result).ordtype:=ordtype;
         torddef(result).savesize:=savesize;
      end;


    function torddef.alignment:shortint;
      begin
        if (target_info.system in [system_i386_darwin,system_i386_iphonesim,system_arm_darwin]) and
           (ordtype in [s64bit,u64bit]) then
          result := 4
        else
          result := inherited alignment;
      end;


    procedure torddef.setsize;
      const
        sizetbl : array[tordtype] of longint = (
          0,
          1,2,4,8,
          1,2,4,8,
          1,1,2,4,8,
          1,2,8
        );
      begin
        savesize:=sizetbl[ordtype];
      end;


    function torddef.packedbitsize: aint;
      var
        sizeval: tconstexprint;
        power: longint;
      begin
        result := 0;
        if ordtype = uvoid then
          exit;

{$ifndef cpu64bitalu}
        if (ordtype in [s64bit,u64bit]) then
{$else not cpu64bitalu}
        if (ordtype = u64bit) or
           ((ordtype = s64bit) and
            ((low <= (system.low(int64) div 2)) or
             (high > (system.high(int64) div 2)))) then
{$endif cpu64bitalu}
          result := 64
        else if (low >= 0) and
           (high <= 1) then
          result := 1
        else
          begin
            if (low>=0) then
              sizeval:=high
            else
              { don't count 0 twice }
              sizeval:=(cutils.max(-low,high)*2)-1;
            { 256 must become 512 etc. }
            nextpowerof2(sizeval+1,power);
            result := power;
         end;
      end;


    function torddef.getvardef : longint;
      const
        basetype2vardef : array[tordtype] of longint = (
          varUndefined,
          varbyte,varword,varlongword,varqword,
          varshortint,varsmallint,varinteger,varint64,
          varboolean,varboolean,varboolean,varUndefined,varUndefined,
          varUndefined,varUndefined,varCurrency);
      begin
        result:=basetype2vardef[ordtype];
      end;


    procedure torddef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putbyte(byte(ordtype));
         ppufile.putexprint(low);
         ppufile.putexprint(high);
         ppufile.writeentry(iborddef);
      end;


    function torddef.is_publishable : boolean;
      begin
         is_publishable:=(ordtype<>uvoid);
      end;


    function torddef.GetTypeName : string;
      const
        names : array[tordtype] of string[20] = (
          'untyped',
          'Byte','Word','DWord','QWord',
          'ShortInt','SmallInt','LongInt','Int64',
          'Boolean','ByteBool','WordBool','LongBool','QWordBool',
          'Char','WideChar','Currency');

      begin
         GetTypeName:=names[ordtype];
      end;


{****************************************************************************
                                TFLOATDEF
****************************************************************************}

    constructor tfloatdef.create(t : tfloattype);
      begin
         inherited create(floatdef);
         floattype:=t;
         setsize;
      end;


    constructor tfloatdef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(floatdef,ppufile);
         floattype:=tfloattype(ppufile.getbyte);
         setsize;
      end;


    function tfloatdef.getcopy : tstoreddef;
      begin
         result:=tfloatdef.create(floattype);
         result.typ:=floatdef;
         tfloatdef(result).savesize:=savesize;
      end;


    function tfloatdef.alignment:shortint;
      begin
        if (target_info.system in [system_i386_darwin,system_i386_iphonesim,system_arm_darwin]) then
          case floattype of
            s80real: result:=16;
            s64real,
            s64currency,
            s64comp : result:=4;
            else
              result := inherited alignment;
          end
        else
          result := inherited alignment;
      end;


    procedure tfloatdef.setsize;
      begin
         case floattype of
           s32real : savesize:=4;
           s80real : savesize:=10;
           sc80real:
             if target_info.system in [system_i386_darwin,system_i386_iphonesim,system_x86_64_darwin,
                  system_x86_64_linux,system_x86_64_freebsd,
                  system_x86_64_solaris,system_x86_64_embedded] then
               savesize:=16
             else
               savesize:=12;
           s64real,
           s64currency,
           s64comp : savesize:=8;
         else
           savesize:=0;
         end;
      end;


    function tfloatdef.getvardef : longint;
      const
        floattype2vardef : array[tfloattype] of longint = (
          varSingle,varDouble,varUndefined,varUndefined,
          varUndefined,varCurrency,varUndefined);
      begin
        if (upper(typename)='TDATETIME') and
          assigned(owner) and
          assigned(owner.name) and
          (owner.name^='SYSTEM') then
          result:=varDate
        else
          result:=floattype2vardef[floattype];
      end;


    procedure tfloatdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putbyte(byte(floattype));
         ppufile.writeentry(ibfloatdef);
      end;


    function tfloatdef.is_publishable : boolean;
      begin
         is_publishable:=true;
      end;


    function tfloatdef.GetTypeName : string;
      const
        names : array[tfloattype] of string[20] = (
          'Single','Double','Extended','CExtended','Comp','Currency','Float128');
      begin
         GetTypeName:=names[floattype];
      end;


{****************************************************************************
                                TFILEDEF
****************************************************************************}

    constructor tfiledef.createtext;
      begin
         inherited create(filedef);
         filetyp:=ft_text;
         typedfiledef:=nil;
         setsize;
      end;


    constructor tfiledef.createuntyped;
      begin
         inherited create(filedef);
         filetyp:=ft_untyped;
         typedfiledef:=nil;
         setsize;
      end;


    constructor tfiledef.createtyped(def:tdef);
      begin
         inherited create(filedef);
         filetyp:=ft_typed;
         typedfiledef:=def;
         setsize;
      end;


    constructor tfiledef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(filedef,ppufile);
         filetyp:=tfiletyp(ppufile.getbyte);
         if filetyp=ft_typed then
           ppufile.getderef(typedfiledefderef)
         else
           typedfiledef:=nil;
         setsize;
      end;


    function tfiledef.getcopy : tstoreddef;
      begin
        case filetyp of
          ft_typed:
            result:=tfiledef.createtyped(typedfiledef);
          ft_untyped:
            result:=tfiledef.createuntyped;
          ft_text:
            result:=tfiledef.createtext;
          else
            internalerror(2004121201);
        end;
      end;


    procedure tfiledef.buildderef;
      begin
        inherited buildderef;
        if filetyp=ft_typed then
          typedfiledefderef.build(typedfiledef);
      end;


    procedure tfiledef.deref;
      begin
        inherited deref;
        if filetyp=ft_typed then
          typedfiledef:=tdef(typedfiledefderef.resolve);
      end;


    procedure tfiledef.setsize;
      begin
{$ifdef cpu64bitaddr}
        case filetyp of
          ft_text :
            if target_info.system in [system_x86_64_win64,system_ia64_win64] then
              savesize:=632{+8}
            else
              savesize:=628{+8};
          ft_typed,
          ft_untyped :
            if target_info.system in [system_x86_64_win64,system_ia64_win64] then
              savesize:=372
            else
              savesize:=368;
        end;
{$else cpu64bitaddr}
        case filetyp of
          ft_text :
            savesize:=592{+4};
          ft_typed,
          ft_untyped :
            savesize:=332;
        end;
{$endif cpu64bitaddr}
      end;


    procedure tfiledef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putbyte(byte(filetyp));
         if filetyp=ft_typed then
           ppufile.putderef(typedfiledefderef);
         ppufile.writeentry(ibfiledef);
      end;


    function tfiledef.GetTypeName : string;
      begin
         case filetyp of
           ft_untyped:
             GetTypeName:='File';
           ft_typed:
             GetTypeName:='File Of '+typedfiledef.typename;
           ft_text:
             GetTypeName:='Text'
         end;
      end;


    function tfiledef.getmangledparaname : string;
      begin
         case filetyp of
           ft_untyped:
             getmangledparaname:='FILE';
           ft_typed:
             getmangledparaname:='FILE$OF$'+typedfiledef.mangledparaname;
           ft_text:
             getmangledparaname:='TEXT'
         end;
      end;


{****************************************************************************
                               TVARIANTDEF
****************************************************************************}

    constructor tvariantdef.create(v : tvarianttype);
      begin
         inherited create(variantdef);
         varianttype:=v;
         setsize;
      end;


    constructor tvariantdef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(variantdef,ppufile);
         varianttype:=tvarianttype(ppufile.getbyte);
         setsize;
      end;


    function tvariantdef.getcopy : tstoreddef;
      begin
        result:=tvariantdef.create(varianttype);
      end;


    procedure tvariantdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putbyte(byte(varianttype));
         ppufile.writeentry(ibvariantdef);
      end;


    function tvariantdef.getvardef : longint;
      begin
        Result:=varVariant;
      end;


    procedure tvariantdef.setsize;
      begin
{$ifdef cpu64bitaddr}
        savesize:=24;
{$else cpu64bitaddr}
        savesize:=16;
{$endif cpu64bitaddr}
      end;


    function tvariantdef.GetTypeName : string;
      begin
         case varianttype of
           vt_normalvariant:
             GetTypeName:='Variant';
           vt_olevariant:
             GetTypeName:='OleVariant';
         end;
      end;


    function tvariantdef.needs_inittable : boolean;
      begin
         needs_inittable:=true;
      end;


    function tvariantdef.is_publishable : boolean;
      begin
         is_publishable:=true;
      end;


{****************************************************************************
                            TABSTRACtpointerdef
****************************************************************************}

    constructor tabstractpointerdef.create(dt:tdeftyp;def:tdef);
      begin
        inherited create(dt);
        pointeddef:=def;
        savesize:=sizeof(pint);
      end;


    constructor tabstractpointerdef.ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
      begin
         inherited ppuload(dt,ppufile);
         ppufile.getderef(pointeddefderef);
         savesize:=sizeof(pint);
      end;


    procedure tabstractpointerdef.buildderef;
      begin
        inherited buildderef;
        pointeddefderef.build(pointeddef);
      end;


    procedure tabstractpointerdef.deref;
      begin
        inherited deref;
        pointeddef:=tdef(pointeddefderef.resolve);
      end;


    procedure tabstractpointerdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putderef(pointeddefderef);
      end;


{****************************************************************************
                               tpointerdef
****************************************************************************}

    constructor tpointerdef.create(def:tdef);
      begin
        inherited create(pointerdef,def);
        is_far:=false;
      end;


    constructor tpointerdef.createfar(def:tdef);
      begin
        inherited create(pointerdef,def);
        is_far:=true;
      end;


    constructor tpointerdef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(pointerdef,ppufile);
         is_far:=(ppufile.getbyte<>0);
      end;


    function tpointerdef.getcopy : tstoreddef;
      begin
        result:=tpointerdef.create(pointeddef);
        tpointerdef(result).is_far:=is_far;
        tpointerdef(result).savesize:=savesize;
      end;


    procedure tpointerdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putbyte(byte(is_far));
         ppufile.writeentry(ibpointerdef);
      end;


    function tpointerdef.GetTypeName : string;
      begin
         if is_far then
          GetTypeName:='^'+pointeddef.typename+';far'
         else
          GetTypeName:='^'+pointeddef.typename;
      end;


{****************************************************************************
                              TCLASSREFDEF
****************************************************************************}

    constructor tclassrefdef.create(def:tdef);
      begin
         inherited create(classrefdef,def);
      end;


    constructor tclassrefdef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(classrefdef,ppufile);
      end;


    procedure tclassrefdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.writeentry(ibclassrefdef);
      end;


    function tclassrefdef.GetTypeName : string;
      begin
         GetTypeName:='Class Of '+pointeddef.typename;
      end;


    function tclassrefdef.is_publishable : boolean;
      begin
         result:=true;
      end;


    function tclassrefdef.rtti_mangledname(rt: trttitype): string;
      begin
        if (tobjectdef(pointeddef).objecttype<>odt_objcclass) then
          result:=inherited rtti_mangledname(rt)
        else
          result:=tobjectdef(pointeddef).rtti_mangledname(objcmetartti);
      end;


    procedure tclassrefdef.register_created_object_type;
      begin
        tobjectdef(pointeddef).register_created_classref_type;
      end;

{***************************************************************************
                                   TSETDEF
***************************************************************************}

    constructor tsetdef.create(def:tdef;low, high : aint);
      var
        setallocbits: aint;
        packedsavesize: aint;
      begin
         inherited create(setdef);
         elementdef:=def;
         setmax:=high;
         if (current_settings.setalloc=0) then
           begin
             setbase:=0;
             if (high<32) then
               savesize:=Sizeof(longint)
             else if (high<256) then
               savesize:=32
             else
               savesize:=(high+7) div 8
           end
         else
           begin
             setallocbits:=current_settings.setalloc*8;
             setbase:=low and not(setallocbits-1);
             packedsavesize:=current_settings.setalloc*((((high+setallocbits)-setbase)) DIV setallocbits);
             savesize:=packedsavesize;
             if savesize=3 then
               savesize:=4;
           end;
      end;


    constructor tsetdef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(setdef,ppufile);
         ppufile.getderef(elementdefderef);
         savesize:=ppufile.getaint;
         setbase:=ppufile.getaint;
         setmax:=ppufile.getaint;
      end;


    function tsetdef.getcopy : tstoreddef;
      begin
        result:=tsetdef.create(elementdef,setbase,setmax);
        { the copy might have been created with a different setalloc setting }
        tsetdef(result).savesize:=savesize;
      end;


    procedure tsetdef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putderef(elementdefderef);
         ppufile.putaint(savesize);
         ppufile.putaint(setbase);
         ppufile.putaint(setmax);
         ppufile.writeentry(ibsetdef);
      end;


    procedure tsetdef.buildderef;
      begin
        inherited buildderef;
        elementdefderef.build(elementdef);
      end;


    procedure tsetdef.deref;
      begin
        inherited deref;
        elementdef:=tdef(elementdefderef.resolve);
      end;


    function tsetdef.is_publishable : boolean;
      begin
         is_publishable:=savesize in [1,2,4];
      end;


    function tsetdef.GetTypeName : string;
      begin
         if assigned(elementdef) then
          GetTypeName:='Set Of '+elementdef.typename
         else
          GetTypeName:='Empty Set';
      end;


{***************************************************************************
                                 TFORMALDEF
***************************************************************************}

    constructor tformaldef.create(Atyped:boolean);
      begin
         inherited create(formaldef);
         typed:=Atyped;
         savesize:=0;
      end;


    constructor tformaldef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(formaldef,ppufile);
         typed:=boolean(ppufile.getbyte);
         savesize:=0;
      end;


    procedure tformaldef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putbyte(byte(typed));
         ppufile.writeentry(ibformaldef);
      end;


    function tformaldef.GetTypeName : string;
      begin
         if typed then
           GetTypeName:='<Typed formal type>'
         else
           GetTypeName:='<Formal type>';
      end;


{***************************************************************************
                           TARRAYDEF
***************************************************************************}

    constructor tarraydef.create(l,h : aint;def:tdef);
      begin
         inherited create(arraydef);
         lowrange:=l;
         highrange:=h;
         rangedef:=def;
         _elementdef:=nil;
         arrayoptions:=[];
      end;


    constructor tarraydef.create_from_pointer(def:tdef);
      begin
         { use -1 so that the elecount will not overflow }
         self.create(0,high(aint)-1,s32inttype);
         arrayoptions:=[ado_IsConvertedPointer];
         setelementdef(def);
      end;


    constructor tarraydef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(arraydef,ppufile);
         { the addresses are calculated later }
         ppufile.getderef(_elementdefderef);
         ppufile.getderef(rangedefderef);
         lowrange:=ppufile.getaint;
         highrange:=ppufile.getaint;
         ppufile.getsmallset(arrayoptions);
      end;


    function tarraydef.getcopy : tstoreddef;
      begin
        result:=tarraydef.create(lowrange,highrange,rangedef);
        tarraydef(result).arrayoptions:=arrayoptions;
        tarraydef(result)._elementdef:=_elementdef;
      end;


    procedure tarraydef.buildderef;
      begin
        inherited buildderef;
        _elementdefderef.build(_elementdef);
        rangedefderef.build(rangedef);
      end;


    procedure tarraydef.deref;
      begin
        inherited deref;
        _elementdef:=tdef(_elementdefderef.resolve);
        rangedef:=tdef(rangedefderef.resolve);
      end;


    procedure tarraydef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.putderef(_elementdefderef);
         ppufile.putderef(rangedefderef);
         ppufile.putaint(lowrange);
         ppufile.putaint(highrange);
         ppufile.putsmallset(arrayoptions);
         ppufile.writeentry(ibarraydef);
      end;


    function tarraydef.elesize : aint;
      begin
        if (ado_IsBitPacked in arrayoptions) then
          internalerror(2006080101);
        if assigned(_elementdef) then
          result:=_elementdef.size
        else
          result:=0;
      end;


    function tarraydef.elepackedbitsize : aint;
      begin
        if not(ado_IsBitPacked in arrayoptions) then
          internalerror(2006080102);
	if assigned(_elementdef) then
          result:=_elementdef.packedbitsize
	else
	  result:=0;
      end;


    function tarraydef.elecount : aword;
      var
        qhigh,qlow : qword;
      begin
        if ado_IsDynamicArray in arrayoptions then
          begin
            result:=0;
            exit;
          end;
        if (highrange>0) and (lowrange<0) then
          begin
            qhigh:=highrange;
            qlow:=qword(-lowrange);
            { prevent overflow, return 0 to indicate overflow }
            if qhigh+qlow>qword(high(aint)-1) then
              result:=0
            else
              result:=qhigh+qlow+1;
          end
        else
          result:=int64(highrange)-lowrange+1;
      end;


    function tarraydef.size : aint;
      var
        cachedelecount : aword;
        cachedelesize : aint;
      begin
        if ado_IsDynamicArray in arrayoptions then
          begin
            size:=sizeof(pint);
            exit;
          end;

        { Tarraydef.size may never be called for an open array! }
        if highrange<lowrange then
          internalerror(99080501);
        if not (ado_IsBitPacked in arrayoptions) then
          cachedelesize:=elesize
        else
          cachedelesize := elepackedbitsize;
        cachedelecount:=elecount;

        if (cachedelesize = 0) then
          begin
            size := 0;
            exit;
          end;

        if (cachedelecount = 0) then
          begin
            size := -1;
            exit;
          end;

        { prevent overflow, return -1 to indicate overflow }
        { also make sure we don't need 64/128 bit arithmetic to calculate offsets }
        if (cachedelecount > aword(high(aint))) or
           ((high(aint) div cachedelesize) < aint(cachedelecount)) or
           { also lowrange*elesize must be < high(aint) to prevent overflow when
             accessing the array, see ncgmem (PFV) }
           ((high(aint) div cachedelesize) < abs(lowrange)) then
          begin
            result:=-1;
            exit;
          end;

        result:=cachedelesize*aint(cachedelecount);
        if (ado_IsBitPacked in arrayoptions) then
          { can't just add 7 and divide by 8, because that may overflow }
          result:=result div 8 + ord((result mod 8)<>0);
      end;


    procedure tarraydef.setelementdef(def:tdef);
      begin
        _elementdef:=def;
        if not(
               (ado_IsDynamicArray in arrayoptions) or
               (ado_IsConvertedPointer in arrayoptions) or
               (highrange<lowrange)
	      ) and
           (size=-1) then
          Message(sym_e_segment_too_large);
      end;


    function tarraydef.alignment : shortint;
      begin
         { alignment of dyn. arrays doesn't depend on the element size }
         if (ado_IsDynamicArray in arrayoptions) then
           alignment:=size_2_align(sizeof(pint))
         { alignment is the alignment of the elements }
         else if (elementdef.typ in [arraydef,recorddef,orddef,enumdef,floatdef]) or
           ((elementdef.typ=objectdef) and
             is_object(elementdef)) then
           alignment:=elementdef.alignment
         { alignment is the size of the elements }
         else if not (ado_IsBitPacked in arrayoptions) then
           alignment:=size_2_align(elesize)
         else
           alignment:=packedbitsloadsize(elepackedbitsize);
      end;


    function tarraydef.needs_inittable : boolean;
      begin
         needs_inittable:=(ado_IsDynamicArray in arrayoptions) or elementdef.needs_inittable;
      end;


    function tarraydef.GetTypeName : string;
      begin
         if (ado_IsConstString in arrayoptions) then
           result:='Constant String'
         else if (ado_isarrayofconst in arrayoptions) or
                 (ado_isConstructor in arrayoptions) then
           begin
             if (ado_isvariant in arrayoptions) or ((highrange=-1) and (lowrange=0)) then
               GetTypeName:='Array Of Const'
             else
               GetTypeName:='Array Of Const/Constant Open Array of '+elementdef.typename;
           end
         else if (ado_IsDynamicArray in arrayoptions) then
           GetTypeName:='Dynamic Array Of '+elementdef.typename
         else if ((highrange=-1) and (lowrange=0)) then
           GetTypeName:='Open Array Of '+elementdef.typename
         else
           begin
              result := '';
              if (ado_IsBitPacked in arrayoptions) then
                result:='Packed ';
              if rangedef.typ=enumdef then
                result:=result+'Array['+rangedef.typename+'] Of '+elementdef.typename
              else
                result:=result+'Array['+tostr(lowrange)+'..'+
                  tostr(highrange)+'] Of '+elementdef.typename
           end;
      end;


    function tarraydef.getmangledparaname : string;
      begin
         if ado_isarrayofconst in arrayoptions then
          getmangledparaname:='array_of_const'
         else
          if ((highrange=-1) and (lowrange=0)) then
           getmangledparaname:='array_of_'+elementdef.mangledparaname
         else
          internalerror(200204176);
      end;


    function tarraydef.is_publishable : boolean;
      begin
        Result:=ado_IsDynamicArray in arrayoptions;
      end;

{***************************************************************************
                              tabstractrecorddef
***************************************************************************}

    constructor tabstractrecorddef.create(const n:string; dt:tdeftyp);
      begin
        inherited create(dt);
        objname:=stringdup(upper(n));
        objrealname:=stringdup(n);
        objectoptions:=[];
      end;

    constructor tabstractrecorddef.ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
      begin
        inherited ppuload(dt,ppufile);
        objrealname:=stringdup(ppufile.getstring);
        objname:=stringdup(upper(objrealname^));
        ppufile.getsmallset(objectoptions);
      end;

    procedure tabstractrecorddef.ppuwrite(ppufile: tcompilerppufile);
      begin
        inherited ppuwrite(ppufile);
        ppufile.putstring(objrealname^);
        ppufile.putsmallset(objectoptions);
      end;

    destructor tabstractrecorddef.destroy;
      begin
        stringdispose(objname);
        stringdispose(objrealname);
        inherited destroy;
      end;

    function tabstractrecorddef.GetSymtable(t:tGetSymtable):TSymtable;
      begin
         if t=gs_record then
         GetSymtable:=symtable
        else
         GetSymtable:=nil;
      end;


    function tabstractrecorddef.is_packed:boolean;
      begin
        result:=tabstractrecordsymtable(symtable).is_packed;
      end;

    function tabstractrecorddef.RttiName: string;
      var
        tmp: tabstractrecorddef;
      begin
        Result:=objrealname^;
        tmp:=self;
        repeat
          if tmp.owner.symtabletype in [ObjectSymtable,recordsymtable] then
            tmp:=tabstractrecorddef(tmp.owner.defowner)
          else
            break;
          Result:=tmp.objrealname^+'.'+Result;
        until tmp=nil;
      end;


{***************************************************************************
                                  trecorddef
***************************************************************************}

    constructor trecorddef.create(const n:string; p:TSymtable);
      begin
         inherited create(n,recorddef);
         symtable:=p;
         { we can own the symtable only if nobody else owns a copy so far }
         if symtable.refcount=1 then
           symtable.defowner:=self;
         isunion:=false;
      end;


    constructor trecorddef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(recorddef,ppufile);
         if df_copied_def in defoptions then
           ppufile.getderef(cloneddefderef)
         else
           begin
             symtable:=trecordsymtable.create(objrealname^,0);
             trecordsymtable(symtable).fieldalignment:=shortint(ppufile.getbyte);
             trecordsymtable(symtable).recordalignment:=shortint(ppufile.getbyte);
             trecordsymtable(symtable).padalignment:=shortint(ppufile.getbyte);
             trecordsymtable(symtable).usefieldalignment:=shortint(ppufile.getbyte);
             trecordsymtable(symtable).datasize:=ppufile.getaint;
             trecordsymtable(symtable).ppuload(ppufile);
             { requires usefieldalignment to be set }
             symtable.defowner:=self;
           end;
         isunion:=false;
      end;


    destructor trecorddef.destroy;
      begin
         if assigned(symtable) then
           begin
             symtable.free;
             symtable:=nil;
           end;
         inherited destroy;
      end;


    function trecorddef.getcopy : tstoreddef;
      begin
        result:=trecorddef.create(objrealname^,symtable.getcopy);
        trecorddef(result).isunion:=isunion;
        include(trecorddef(result).defoptions,df_copied_def);
      end;


    function trecorddef.needs_inittable : boolean;
      begin
        needs_inittable:=trecordsymtable(symtable).needs_init_final
      end;


    procedure trecorddef.buildderef;
      begin
         inherited buildderef;
         if df_copied_def in defoptions then
           cloneddefderef.build(symtable.defowner)
         else
           tstoredsymtable(symtable).buildderef;
      end;


    procedure trecorddef.deref;
      begin
         inherited deref;
         { now dereference the definitions }
         if df_copied_def in defoptions then
           begin
             cloneddef:=trecorddef(cloneddefderef.resolve);
             symtable:=cloneddef.symtable.getcopy;
           end
         else
           tstoredsymtable(symtable).deref;

         { assign TGUID? load only from system unit }
         if not(assigned(rec_tguid)) and
            (upper(typename)='TGUID') and
            assigned(owner) and
            assigned(owner.name) and
            (owner.name^='SYSTEM') then
           rec_tguid:=self;

         { assign JMP_BUF? load only from system unit }
         if not(assigned(rec_jmp_buf)) and
            (upper(typename)='JMP_BUF') and
            assigned(owner) and
            assigned(owner.name) and
            (owner.name^='SYSTEM') then
           rec_jmp_buf:=self;
      end;


    procedure trecorddef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         if df_copied_def in defoptions then
           ppufile.putderef(cloneddefderef)
         else
           begin
             ppufile.putbyte(byte(trecordsymtable(symtable).fieldalignment));
             ppufile.putbyte(byte(trecordsymtable(symtable).recordalignment));
             ppufile.putbyte(byte(trecordsymtable(symtable).padalignment));
             ppufile.putbyte(byte(trecordsymtable(symtable).usefieldalignment));
             ppufile.putaint(trecordsymtable(symtable).datasize);
           end;

         ppufile.writeentry(ibrecorddef);

         if not(df_copied_def in defoptions) then
           trecordsymtable(symtable).ppuwrite(ppufile);
      end;


    function trecorddef.size:aint;
      begin
        result:=trecordsymtable(symtable).datasize;
      end;


    function trecorddef.alignment:shortint;
      begin
        alignment:=trecordsymtable(symtable).recordalignment;
      end;


    function trecorddef.padalignment:shortint;
      begin
        padalignment := trecordsymtable(symtable).padalignment;
      end;


    function trecorddef.GetTypeName : string;
      begin
         GetTypeName:='<record type>'
      end;


{***************************************************************************
                       TABSTRACTPROCDEF
***************************************************************************}

    constructor tabstractprocdef.create(dt:tdeftyp;level:byte);
      begin
         inherited create(dt);
         parast:=tparasymtable.create(self,level);
         paras:=nil;
         minparacount:=0;
         maxparacount:=0;
         proctypeoption:=potype_none;
         proccalloption:=pocall_none;
         procoptions:=[];
         returndef:=voidtype;
         savesize:=sizeof(pint);
         callerargareasize:=0;
         calleeargareasize:=0;
         has_paraloc_info:=callnoside;
         funcretloc[callerside].init;
         funcretloc[calleeside].init;
         check_mark_as_nested;
      end;


    destructor tabstractprocdef.destroy;
      begin
         if assigned(paras) then
           begin
{$ifdef MEMDEBUG}
             memprocpara.start;
{$endif MEMDEBUG}
             paras.free;
             paras:=nil;
{$ifdef MEMDEBUG}
             memprocpara.stop;
{$endif MEMDEBUG}
          end;
         if assigned(parast) then
          begin
{$ifdef MEMDEBUG}
            memprocparast.start;
{$endif MEMDEBUG}
            parast.free;
            parast:=nil;
{$ifdef MEMDEBUG}
            memprocparast.stop;
{$endif MEMDEBUG}
          end;
         funcretloc[callerside].done;
         funcretloc[calleeside].done;
         inherited destroy;
      end;


    procedure tabstractprocdef.count_para(p:TObject;arg:pointer);
      begin
        if (tsym(p).typ<>paravarsym) then
          exit;
        inc(plongint(arg)^);
        if not(vo_is_hidden_para in tparavarsym(p).varoptions) then
         begin
           if not assigned(tparavarsym(p).defaultconstsym) then
             inc(minparacount);
           inc(maxparacount);
         end;
      end;


    procedure tabstractprocdef.insert_para(p:TObject;arg:pointer);
      begin
        if (tsym(p).typ<>paravarsym) then
          exit;
        paras.add(p);
      end;


    procedure tabstractprocdef.calcparas;
      var
        paracount : longint;
      begin
        { This can already be assigned when
          we need to reresolve this unit (PFV) }
        if assigned(paras) then
          paras.free;
        paras:=tparalist.create(false);
        paracount:=0;
        minparacount:=0;
        maxparacount:=0;
        parast.SymList.ForEachCall(@count_para,@paracount);
        paras.capacity:=paracount;
        { Insert parameters in table }
        parast.SymList.ForEachCall(@insert_para,nil);
        { Order parameters }
        paras.sortparas;
      end;


    procedure tabstractprocdef.buildderef;
      begin
         { released procdef? }
         if not assigned(parast) then
           exit;
         inherited buildderef;
         returndefderef.build(returndef);
         { parast }
         tparasymtable(parast).buildderef;
      end;


    procedure tabstractprocdef.deref;
      begin
         inherited deref;
         returndef:=tdef(returndefderef.resolve);
         { parast }
         tparasymtable(parast).deref;
         { recalculated parameters }
         calcparas;
      end;


    constructor tabstractprocdef.ppuload(dt:tdeftyp;ppufile:tcompilerppufile);
      begin
         inherited ppuload(dt,ppufile);
         parast:=nil;
         Paras:=nil;
         minparacount:=0;
         maxparacount:=0;
         ppufile.getderef(returndefderef);
{ TODO: remove fpu_used loading}
         ppufile.getbyte;
         proctypeoption:=tproctypeoption(ppufile.getbyte);
         proccalloption:=tproccalloption(ppufile.getbyte);
         ppufile.getnormalset(procoptions);

         funcretloc[callerside].init;
         if po_explicitparaloc in procoptions then
           funcretloc[callerside].ppuload(ppufile);

         savesize:=sizeof(pint);
         if (po_explicitparaloc in procoptions) then
           has_paraloc_info:=callerside;
      end;


    procedure tabstractprocdef.ppuwrite(ppufile:tcompilerppufile);
      var
        oldintfcrc : boolean;
      begin
         { released procdef? }
         if not assigned(parast) then
           exit;
         inherited ppuwrite(ppufile);
         ppufile.putderef(returndefderef);
         oldintfcrc:=ppufile.do_interface_crc;
         ppufile.do_interface_crc:=false;
         ppufile.putbyte(0);
         ppufile.putbyte(ord(proctypeoption));
         ppufile.putbyte(ord(proccalloption));
         ppufile.putnormalset(procoptions);
         ppufile.do_interface_crc:=oldintfcrc;

         if (po_explicitparaloc in procoptions) then
           funcretloc[callerside].ppuwrite(ppufile);
      end;


    function tabstractprocdef.typename_paras(showhidden:boolean) : string;
      var
        hs,s  : string;
        hp    : TParavarsym;
        hpc   : tconstsym;
        first : boolean;
        i     : integer;
      begin
        s:='';
        first:=true;
        for i:=0 to paras.count-1 do
         begin
           hp:=tparavarsym(paras[i]);
           if not(vo_is_hidden_para in hp.varoptions) or
              (showhidden) then
            begin
               if first then
                begin
                  s:=s+'(';
                  first:=false;
                end
               else
                s:=s+',';
               if vo_is_hidden_para in hp.varoptions then
                 s:=s+'<';
               case hp.varspez of
                 vs_var :
                   s:=s+'var ';
                 vs_const :
                   s:=s+'const ';
                 vs_out :
                   s:=s+'out ';
                 vs_constref :
                   s:=s+'constref ';
               end;
               if hp.univpara then
                 s:=s+'univ ';
               if assigned(hp.vardef.typesym) then
                 begin
                   hs:=hp.vardef.typesym.realname;
                   if hs[1]<>'$' then
                     s:=s+hs
                   else
                     s:=s+hp.vardef.GetTypeName;
                 end
               else
                 s:=s+hp.vardef.GetTypeName;
               { default value }
               if assigned(hp.defaultconstsym) then
                begin
                  hpc:=tconstsym(hp.defaultconstsym);
                  hs:='';
                  case hpc.consttyp of
                    conststring,
                    constresourcestring :
                      begin
                      If hpc.value.len>0 then
                        begin
                          setLength(hs,hpc.value.len);
                          { don't write past the end of hs if the constant
                            is > 255 chars }
                          move(hpc.value.valueptr^,hs[1],length(hs));
                          { make sure that constant strings with newline chars
                            don't create a linebreak in the assembler code,
                            since comments are line-based. Also remove nulls
                            because the comments are written as a pchar. }
                          ReplaceCase(hs,#0,'.');
                          ReplaceCase(hs,#10,'.');
                          ReplaceCase(hs,#13,'.');
                        end;
                      end;
                    constreal :
                      str(pbestreal(hpc.value.valueptr)^,hs);
                    constpointer :
                      hs:=tostr(hpc.value.valueordptr);
                    constord :
                      begin
                        if is_boolean(hpc.constdef) then
                          begin
                            if hpc.value.valueord<>0 then
                             hs:='TRUE'
                            else
                             hs:='FALSE';
                          end
                        else
                          hs:=tostr(hpc.value.valueord);
                      end;
                    constnil :
                      hs:='nil';
                    constset :
                      hs:='<set>';
                  end;
                  if hs<>'' then
                   s:=s+'="'+hs+'"';
                end;
               if vo_is_hidden_para in hp.varoptions then
                 s:=s+'>';
             end;
         end;
        if not first then
         s:=s+')';
        if (po_varargs in procoptions) then
         s:=s+';VarArgs';
        typename_paras:=s;
      end;


    function tabstractprocdef.is_methodpointer:boolean;
      begin
        result:=false;
      end;


    function tabstractprocdef.is_addressonly:boolean;
      begin
        result:=true;
      end;

    function tabstractprocdef.no_self_node: boolean;
      begin
        Result:=([po_staticmethod,po_classmethod]<=procoptions)or
                (proctypeoption in [potype_class_constructor,potype_class_destructor]);
      end;


    procedure tabstractprocdef.check_mark_as_nested;
      begin
         { nested procvars require that nested functions use the Delphi-style
           nested procedure calling convention }
         if (parast.symtablelevel>normal_function_level) and
            (m_nested_procvars in current_settings.modeswitches) then
           include(procoptions,po_delphi_nested_cc);
      end;


    procedure tabstractprocdef.init_paraloc_info(side: tcallercallee);
      begin
        if (side in [callerside,callbothsides]) and
           not(has_paraloc_info in [callerside,callbothsides]) then
          begin
            callerargareasize:=paramanager.create_paraloc_info(self,callerside);
            if has_paraloc_info in [calleeside,callbothsides] then
              has_paraloc_info:=callbothsides
            else
              has_paraloc_info:=callerside;
          end;
        if (side in [calleeside,callbothsides]) and
           not(has_paraloc_info in [calleeside,callbothsides]) then
          begin
            calleeargareasize:=paramanager.create_paraloc_info(self,calleeside);
            if has_paraloc_info in [callerside,callbothsides] then
              has_paraloc_info:=callbothsides
            else
              has_paraloc_info:=calleeside;
          end;
      end;


    function tabstractprocdef.stack_tainting_parameter(side: tcallercallee): boolean;
      var
        p: tparavarsym;
        ploc: PCGParalocation;
        i: longint;
      begin
        result:=false;
        init_paraloc_info(side);
        for i:=0 to parast.SymList.Count-1 do
          if tsym(parast.SymList[i]).typ=paravarsym then
            begin
              p:=tparavarsym(parast.SymList[i]);
              { check if no parameter is located on the stack }
              if is_open_array(p.vardef) or
                 is_array_of_const(p.vardef) then
                begin
                  result:=true;
                  exit;
                end;
              ploc:=p.paraloc[side].location;
              while assigned(ploc) do
                begin
                  if (ploc^.loc=LOC_REFERENCE) then
                    begin
                      result:=true;
                      exit
                    end;
                  ploc:=ploc^.next;
                end;
            end;
      end;




{***************************************************************************
                                  TPROCDEF
***************************************************************************}

    constructor tprocdef.create(level:byte);
      begin
         inherited create(procdef,level);
         localst:=tlocalsymtable.create(self,parast.symtablelevel);
         _mangledname:=nil;
         fileinfo:=current_filepos;
         extnumber:=$ffff;
         aliasnames:=TCmdStrList.create;
         funcretsym:=nil;
         forwarddef:=true;
         interfacedef:=false;
         hasforward:=false;
         struct := nil;
         import_dll:=nil;
         import_name:=nil;
         import_nr:=0;
         inlininginfo:=nil;
         deprecatedmsg:=nil;
{$ifdef i386}
          fpu_used:=maxfpuregs;
{$endif i386}
      end;


    constructor tprocdef.ppuload(ppufile:tcompilerppufile);
      var
        i,aliasnamescount : longint;
        level : byte;
      begin
         inherited ppuload(procdef,ppufile);
         if po_has_mangledname in procoptions then
          _mangledname:=stringdup(ppufile.getstring)
         else
          _mangledname:=nil;
         extnumber:=ppufile.getword;
         level:=ppufile.getbyte;
         ppufile.getderef(structderef);
         ppufile.getderef(procsymderef);
         ppufile.getposinfo(fileinfo);
         visibility:=tvisibility(ppufile.getbyte);
         ppufile.getsmallset(symoptions);
         if sp_has_deprecated_msg in symoptions then
           deprecatedmsg:=stringdup(ppufile.getstring)
         else
           deprecatedmsg:=nil;
{$ifdef powerpc}
         { library symbol for AmigaOS/MorphOS }
         ppufile.getderef(libsymderef);
{$endif powerpc}
         { import stuff }
         if po_has_importdll in procoptions then
           import_dll:=stringdup(ppufile.getstring)
         else
           import_dll:=nil;
         if po_has_importname in procoptions then
           import_name:=stringdup(ppufile.getstring)
         else
           import_name:=nil;
         import_nr:=ppufile.getword;
         if (po_msgint in procoptions) then
           messageinf.i:=ppufile.getlongint;
         if (po_msgstr in procoptions) then
           messageinf.str:=stringdup(ppufile.getstring);
         if (po_dispid in procoptions) then
           dispid:=ppufile.getlongint;
         { inline stuff }
         if (po_has_inlininginfo in procoptions) then
           begin
             ppufile.getderef(funcretsymderef);
             new(inlininginfo);
             ppufile.getsmallset(inlininginfo^.flags);
           end
         else
           begin
             inlininginfo:=nil;
             funcretsym:=nil;
           end;

         aliasnames:=TCmdStrList.create;
         { count alias names }
         aliasnamescount:=ppufile.getbyte;
         for i:=1 to aliasnamescount do
           aliasnames.insert(ppufile.getstring);

         { load para symtable }
         parast:=tparasymtable.create(self,level);
         tparasymtable(parast).ppuload(ppufile);
         { load local symtable }
         if (po_has_inlininginfo in procoptions) then
          begin
            localst:=tlocalsymtable.create(self,level);
            tlocalsymtable(localst).ppuload(ppufile);
          end
         else
          localst:=nil;
         { inline stuff }
         if (po_has_inlininginfo in procoptions) then
           inlininginfo^.code:=ppuloadnodetree(ppufile);
         { default values for no persistent data }
         if (cs_link_deffile in current_settings.globalswitches) and
            (tf_need_export in target_info.flags) and
            (po_exports in procoptions) then
           deffile.AddExport(mangledname);
         forwarddef:=false;
         interfacedef:=false;
         hasforward:=false;
         { Disable po_has_inlining until the derefimpl is done }
         exclude(procoptions,po_has_inlininginfo);
{$ifdef i386}
         fpu_used:=maxfpuregs;
{$endif i386}
      end;


    destructor tprocdef.destroy;
      begin
         aliasnames.free;
         aliasnames:=nil;
         if assigned(localst) and
           (localst.symtabletype<>staticsymtable) then
          begin
{$ifdef MEMDEBUG}
            memproclocalst.start;
{$endif MEMDEBUG}
            localst.free;
            localst:=nil;
{$ifdef MEMDEBUG}
            memproclocalst.start;
{$endif MEMDEBUG}
          end;
         if assigned(inlininginfo) then
          begin
{$ifdef MEMDEBUG}
            memprocnodetree.start;
{$endif MEMDEBUG}
            tnode(inlininginfo^.code).free;
{$ifdef MEMDEBUG}
            memprocnodetree.start;
{$endif MEMDEBUG}
            dispose(inlininginfo);
            inlininginfo:=nil;
          end;
         stringdispose(resultname);
         stringdispose(import_dll);
         stringdispose(import_name);
         stringdispose(deprecatedmsg);
         if (po_msgstr in procoptions) then
           stringdispose(messageinf.str);
         if assigned(_mangledname) then
          begin
{$ifdef MEMDEBUG}
            memmanglednames.start;
{$endif MEMDEBUG}
            stringdispose(_mangledname);
{$ifdef MEMDEBUG}
            memmanglednames.stop;
{$endif MEMDEBUG}
          end;
         inherited destroy;
      end;


    procedure tprocdef.ppuwrite(ppufile:tcompilerppufile);
      var
        oldintfcrc : boolean;
        aliasnamescount : longint;
        item : TCmdStrListItem;
      begin
         { released procdef? }
         if not assigned(parast) then
           exit;

         inherited ppuwrite(ppufile);
         if po_has_mangledname in procoptions then
          ppufile.putstring(_mangledname^);

         ppufile.putword(extnumber);
         ppufile.putbyte(parast.symtablelevel);
         ppufile.putderef(structderef);
         ppufile.putderef(procsymderef);
         ppufile.putposinfo(fileinfo);
         ppufile.putbyte(byte(visibility));
         ppufile.putsmallset(symoptions);
         if sp_has_deprecated_msg in symoptions then
           ppufile.putstring(deprecatedmsg^);
{$ifdef powerpc}
         { library symbol for AmigaOS/MorphOS }
         ppufile.putderef(libsymderef);
{$endif powerpc}
         { import }
         if po_has_importdll in procoptions then
           ppufile.putstring(import_dll^);
         if po_has_importname in procoptions then
           ppufile.putstring(import_name^);
         ppufile.putword(import_nr);
         if (po_msgint in procoptions) then
           ppufile.putlongint(messageinf.i);
         if (po_msgstr in procoptions) then
           ppufile.putstring(messageinf.str^);
         if (po_dispid in procoptions) then
           ppufile.putlongint(dispid);
         { inline stuff }
         oldintfcrc:=ppufile.do_crc;
         ppufile.do_crc:=false;
         if (po_has_inlininginfo in procoptions) then
           begin
             ppufile.putderef(funcretsymderef);
             ppufile.putsmallset(inlininginfo^.flags);
           end;

         { count alias names }
         aliasnamescount:=0;
         item:=TCmdStrListItem(aliasnames.first);
         while assigned(item) do
           begin
             inc(aliasnamescount);
             item:=TCmdStrListItem(item.next);
           end;
         if aliasnamescount>255 then
           internalerror(200711021);
         ppufile.putbyte(aliasnamescount);
         item:=TCmdStrListItem(aliasnames.first);
         while assigned(item) do
          begin
            ppufile.putstring(item.str);
            item:=TCmdStrListItem(item.next);
          end;

         ppufile.do_crc:=oldintfcrc;

         { write this entry }
         ppufile.writeentry(ibprocdef);

         { Save the para symtable, this is taken from the interface }
         tparasymtable(parast).ppuwrite(ppufile);

         { save localsymtable for inline procedures or when local
           browser info is requested, this has no influence on the crc }
         if (po_has_inlininginfo in procoptions) then
          begin
            oldintfcrc:=ppufile.do_crc;
            ppufile.do_crc:=false;
            tlocalsymtable(localst).ppuwrite(ppufile);
            ppufile.do_crc:=oldintfcrc;
          end;

         { node tree for inlining }
         oldintfcrc:=ppufile.do_crc;
         ppufile.do_crc:=false;
         if (po_has_inlininginfo in procoptions) then
           ppuwritenodetree(ppufile,inlininginfo^.code);
         ppufile.do_crc:=oldintfcrc;
      end;


    function tprocdef.fullprocname(showhidden:boolean):string;
      var
        s : string;
        t : ttoken;
      begin
{$ifdef EXTDEBUG}
        showhidden:=true;
{$endif EXTDEBUG}
        s:='';
        if assigned(struct) then
         begin
           s:=struct.RttiName+'.';
           if (po_classmethod in procoptions) and
              not (proctypeoption in [potype_class_constructor,potype_class_destructor]) then
             s:='class ' + s;
         end;
        if proctypeoption=potype_operator then
          begin
            for t:=NOTOKEN to last_overloaded do
              if procsym.realname='$'+overloaded_names[t] then
                begin
                  s:='operator '+arraytokeninfo[t].str+typename_paras(showhidden);
                  break;
                end;
          end
        else
          s:=s+procsym.realname+typename_paras(showhidden);
        case proctypeoption of
          potype_constructor:
            s:='constructor '+s;
          potype_destructor:
            s:='destructor '+s;
          potype_class_constructor:
            s:='class constructor '+s;
          potype_class_destructor:
            s:='class destructor '+s;
          else
            if assigned(returndef) and
              not(is_void(returndef)) then
              s:=s+':'+returndef.GetTypeName;
        end;
        if owner.symtabletype=localsymtable then
          s:=s+' is nested';
        s:=s+';';
        { forced calling convention? }
        if (po_hascallingconvention in procoptions) then
          s:=s+' '+ProcCallOptionStr[proccalloption]+';';
        if (po_staticmethod in procoptions) and
           not (proctypeoption in [potype_class_constructor,potype_class_destructor]) then
          s:=s+' Static;';
        fullprocname:=s;
      end;


    function tprocdef.is_methodpointer:boolean;
      begin
        { don't check assigned(_class), that's also the case for nested
          procedures inside methods }
        result:=owner.symtabletype=ObjectSymtable;
      end;


    function tprocdef.is_addressonly:boolean;
      begin
        result:=assigned(owner) and
                (owner.symtabletype<>ObjectSymtable) and
                (not(m_nested_procvars in current_settings.modeswitches) or
                 not is_nested_pd(self));
      end;

    function tprocdef.GetSymtable(t:tGetSymtable):TSymtable;
      begin
        case t of
          gs_local :
            GetSymtable:=localst;
          gs_para :
            GetSymtable:=parast;
          else
            GetSymtable:=nil;
        end;
      end;


    procedure tprocdef.buildderef;
      begin
         inherited buildderef;
         structderef.build(struct);
         { procsym that originaly defined this definition, should be in the
           same symtable }
         procsymderef.build(procsym);
{$ifdef powerpc}
         { library symbol for AmigaOS/MorphOS }
         libsymderef.build(libsym);
{$endif powerpc}
      end;


    procedure tprocdef.buildderefimpl;
      begin
         inherited buildderefimpl;

         { Localst is not available for main/unit init }
         if assigned(localst) then
           begin
             tlocalsymtable(localst).buildderef;
             tlocalsymtable(localst).buildderefimpl;
           end;

         { inline tree }
         if (po_has_inlininginfo in procoptions) then
           begin
             funcretsymderef.build(funcretsym);
             inlininginfo^.code.buildderefimpl;
           end;
      end;


    procedure tprocdef.deref;
      begin
         inherited deref;
         struct:=tabstractrecorddef(structderef.resolve);
         { procsym that originaly defined this definition, should be in the
           same symtable }
         procsym:=tprocsym(procsymderef.resolve);
{$ifdef powerpc}
         { library symbol for AmigaOS/MorphOS }
         libsym:=tsym(libsymderef.resolve);
{$endif powerpc}
      end;


    procedure tprocdef.derefimpl;
      begin
         { Enable has_inlininginfo when the inlininginfo
           structure is available. The has_inlininginfo was disabled
           after the load, since the data was invalid }
         if assigned(inlininginfo) then
           include(procoptions,po_has_inlininginfo);

         { Locals }
         if assigned(localst) then
           begin
             tlocalsymtable(localst).deref;
             tlocalsymtable(localst).derefimpl;
           end;

        { Inline }
        if (po_has_inlininginfo in procoptions) then
          begin
            inlininginfo^.code.derefimpl;
            { funcretsym, this is always located in the localst }
            funcretsym:=tsym(funcretsymderef.resolve);
          end
        else
          begin
            { safety }
            { Not safe! A unit may be reresolved after its interface has been
              parsed but before its implementation has been parsed, and in that
              case the funcretsym is still required!
            funcretsym:=nil; }
          end;
      end;


    function tprocdef.GetTypeName : string;
      begin
         GetTypeName := FullProcName(false);
      end;


    function tprocdef.mangledname : string;
      var
        hp   : TParavarsym;
        hs   : string;
        crc  : dword;
        newlen,
        oldlen,
        i    : integer;
      begin
        if assigned(_mangledname) then
         begin
         {$ifdef compress}
           mangledname:=minilzw_decode(_mangledname^);
         {$else}
           mangledname:=_mangledname^;
         {$endif}
           exit;
         end;
        { we need to use the symtable where the procsym is inserted,
          because that is visible to the world }
        mangledname:=make_mangledname('',procsym.owner,procsym.name);
        oldlen:=length(mangledname);
        { add parameter types }
        for i:=0 to paras.count-1 do
         begin
           hp:=tparavarsym(paras[i]);
           if not(vo_is_hidden_para in hp.varoptions) then
             mangledname:=mangledname+'$'+hp.vardef.mangledparaname;
         end;
        { add resultdef, add $$ as separator to make it unique from a
          parameter separator }
        if not is_void(returndef) then
          mangledname:=mangledname+'$$'+returndef.mangledparaname;
        newlen:=length(mangledname);
        { Replace with CRC if the parameter line is very long }
        if (newlen-oldlen>12) and
           ((newlen>100) or (newlen-oldlen>64)) then
          begin
            crc:=0;
            for i:=0 to paras.count-1 do
              begin
                hp:=tparavarsym(paras[i]);
                if not(vo_is_hidden_para in hp.varoptions) then
                  begin
                    hs:=hp.vardef.mangledparaname;
                    crc:=UpdateCrc32(crc,hs[1],length(hs));
                  end;
              end;
            hs:=hp.vardef.mangledparaname;
            crc:=UpdateCrc32(crc,hs[1],length(hs));
            mangledname:=Copy(mangledname,1,oldlen)+'$crc'+hexstr(crc,8);
          end;
       {$ifdef compress}
        _mangledname:=stringdup(minilzw_encode(mangledname));
       {$else}
        _mangledname:=stringdup(mangledname);
       {$endif}
      end;


    function tprocdef.cplusplusmangledname : string;

      function getcppparaname(p : tdef) : string;

        const
{$ifdef NAMEMANGLING_GCC2}
           ordtype2str : array[tordtype] of string[2] = (
             '',
             'Uc','Us','Ui','Us',
             'Sc','s','i','x',
             'b','b','b','b','b',
             'c','w','x');
{$else NAMEMANGLING_GCC2}
           ordtype2str : array[tordtype] of string[1] = (
             'v',
             'h','t','j','y',
             'a','s','i','x',
             'b','b','b','b','b',
             'c','w','x');

           floattype2str : array[tfloattype] of string[1] = (
             'f','d','e','e',
             'd','d','g');
{$endif NAMEMANGLING_GCC2}

        var
           s : string;

        begin
           case p.typ of
              orddef:
                s:=ordtype2str[torddef(p).ordtype];
              pointerdef:
                s:='P'+getcppparaname(tpointerdef(p).pointeddef);
{$ifndef NAMEMANGLING_GCC2}
              floatdef:
                s:=floattype2str[tfloatdef(p).floattype];
{$endif NAMEMANGLING_GCC2}
              else
                internalerror(2103001);
           end;
           getcppparaname:=s;
        end;

      var
         s,s2 : string;
         hp   : TParavarsym;
         i    : integer;

      begin
{$ifdef NAMEMANGLING_GCC2}

        { outdated gcc 2.x name mangling scheme }
         s := procsym.realname;
         if procsym.owner.symtabletype=ObjectSymtable then
           begin
              s2:=upper(tobjectdef(procsym.owner.defowner).objrealname^);
              case proctypeoption of
                 potype_destructor:
                   s:='_$_'+tostr(length(s2))+s2;
                 potype_constructor:
                   s:='___'+tostr(length(s2))+s2;
                 else
                   s:='_'+s+'__'+tostr(length(s2))+s2;
              end;

           end
         else s:=s+'__';

         s:=s+'F';

         { concat modifiers }
         { !!!!! }

         { now we handle the parameters }
         if maxparacount>0 then
           begin
             for i:=0 to paras.count-1 do
               begin
                 hp:=tparavarsym(paras[i]);
                 { no hidden parameters form part of a C++ mangled name:
                     a) self is not included
                     b) there are no "high" or other hidden parameters
                 }
                 if vo_is_hidden_para in hp.varoptions then
                   continue;
                 s2:=getcppparaname(hp.vardef);
                 if hp.varspez in [vs_var,vs_out] then
                   s2:='R'+s2;
                 s:=s+s2;
               end;
           end
         else
           s:=s+'v';
         cplusplusmangledname:=s;
{$else NAMEMANGLING_GCC2}

         { gcc 3.x and 4.x name mangling scheme }
         { see http://www.codesourcery.com/public/cxx-abi/abi.html#mangling }
         if procsym.owner.symtabletype=ObjectSymtable then
           begin
             s:='_ZN';

             s2:=tobjectdef(procsym.owner.defowner).objextname^;
             s:=s+tostr(length(s2))+s2;
             case proctypeoption of
                potype_constructor:
                  s:=s+'C1';
                potype_destructor:
                  s:=s+'D1';
                else
                  s:=s+tostr(length(procsym.realname))+procsym.realname;
             end;

             s:=s+'E';
           end
         else
           s:=procsym.realname;

         { now we handle the parameters }
         if maxparacount>0 then
           begin
             for i:=0 to paras.count-1 do
               begin
                 hp:=tparavarsym(paras[i]);
                 { no hidden parameters form part of a C++ mangled name:
                     a) self is not included
                     b) there are no "high" or other hidden parameters
                 }
                 if vo_is_hidden_para in hp.varoptions then
                   continue;
                 s2:=getcppparaname(hp.vardef);
                 if hp.varspez in [vs_var,vs_out] then
                   s2:='R'+s2;
                 s:=s+s2;
               end;
           end
         else
           s:=s+'v';
         cplusplusmangledname:=s;
{$endif NAMEMANGLING_GCC2}
      end;


    function  tprocdef.objcmangledname : string;
      var
        manglednamelen: longint;
        iscatmethod   : boolean;
      begin
        if not (po_msgstr in procoptions) then
          internalerror(2009030901);
        { we may very well need longer strings to handle these... }
        manglednamelen:=length(tobjectdef(procsym.owner.defowner).objextname^)+
          length('+"[ ]"')+length(messageinf.str^);
        iscatmethod:=oo_is_classhelper in tobjectdef(procsym.owner.defowner).objectoptions;
        if (iscatmethod) then
          inc(manglednamelen,length(tobjectdef(procsym.owner.defowner).childof.objextname^)+length('()'));
        if manglednamelen>255 then
          Message1(parser_e_objc_message_name_too_long,messageinf.str^);
        if not(po_classmethod in procoptions) then
          result:='"-['
        else
          result:='"+[';
        { quotes are necessary because the +/- otherwise confuse the assembler
          into expecting a number
        }
        if iscatmethod then
          result:=result+tobjectdef(procsym.owner.defowner).childof.objextname^+'(';
        result:=result+tobjectdef(procsym.owner.defowner).objextname^;
        if iscatmethod then
          result:=result+')';
        result:=result+' '+messageinf.str^+']"';
      end;


    procedure tprocdef.setmangledname(const s : string);
      begin
        { This is not allowed anymore, the forward declaration
          already needs to create the correct mangledname, no changes
          afterwards are allowed (PFV) }
        { Exception: interface definitions in mode macpas, since in that }
        {   case no reference to the old name can exist yet (JM)         }
        if assigned(_mangledname) then
          if ((m_mac in current_settings.modeswitches) and
              (interfacedef)) then
            stringdispose(_mangledname)
          else
            internalerror(200411171);
      {$ifdef compress}
        _mangledname:=stringdup(minilzw_encode(s));
      {$else}
        _mangledname:=stringdup(s);
      {$endif}
        include(procoptions,po_has_mangledname);
      end;


{***************************************************************************
                                 TPROCVARDEF
***************************************************************************}

    constructor tprocvardef.create(level:byte);
      begin
         inherited create(procvardef,level);
      end;


    constructor tprocvardef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(procvardef,ppufile);
         { load para symtable }
         parast:=tparasymtable.create(self,ppufile.getbyte);
         tparasymtable(parast).ppuload(ppufile);
      end;


    function tprocvardef.getcopy : tstoreddef;
      var
        i : tcallercallee;
        j : longint;
      begin
        result:=tprocvardef.create(parast.symtablelevel);
        tprocvardef(result).returndef:=returndef;
        tprocvardef(result).returndefderef:=returndefderef;
        tprocvardef(result).parast:=parast.getcopy;
        tprocvardef(result).savesize:=savesize;

        { create paralist copy }
        tprocvardef(result).paras:=tparalist.create(false);
        tprocvardef(result).paras.count:=paras.count;
        for j:=0 to paras.count-1 do
          tprocvardef(result).paras[j]:=paras[j];

        tprocvardef(result).proctypeoption:=proctypeoption;
        tprocvardef(result).proccalloption:=proccalloption;
        tprocvardef(result).procoptions:=procoptions;
        tprocvardef(result).callerargareasize:=callerargareasize;
        tprocvardef(result).calleeargareasize:=calleeargareasize;
        tprocvardef(result).maxparacount:=maxparacount;
        tprocvardef(result).minparacount:=minparacount;
        for i:=low(tcallercallee) to high(tcallercallee) do
          tprocvardef(result).funcretloc[i]:=funcretloc[i].getcopy;
        tprocvardef(result).has_paraloc_info:=has_paraloc_info;
{$ifdef m68k}
        tprocvardef(result).exp_funcretloc:=exp_funcretloc;
{$endif}
      end;


    procedure tprocvardef.ppuwrite(ppufile:tcompilerppufile);
      begin
        inherited ppuwrite(ppufile);

        { Save the para symtable level (necessary to distinguish nested
          procvars) }
        ppufile.putbyte(parast.symtablelevel);

        { Write this entry }
        ppufile.writeentry(ibprocvardef);

        { Save the para symtable, this is taken from the interface }
        tparasymtable(parast).ppuwrite(ppufile);
      end;


    function tprocvardef.GetSymtable(t:tGetSymtable):TSymtable;
      begin
        case t of
          gs_para :
            GetSymtable:=parast;
          else
            GetSymtable:=nil;
        end;
      end;


    function tprocvardef.size : aint;
      begin
         if ((po_methodpointer in procoptions) or
             is_nested_pd(self)) and
            not(po_addressonly in procoptions) then
           size:=2*sizeof(pint)
         else
           size:=sizeof(pint);
      end;


    function tprocvardef.is_methodpointer:boolean;
      begin
        result:=(po_methodpointer in procoptions);
      end;


    function tprocvardef.is_addressonly:boolean;
      begin
        result:=(not(po_methodpointer in procoptions) and
                 not is_nested_pd(self)) or
                (po_addressonly in procoptions);
      end;


    function tprocvardef.getmangledparaname:string;
      begin
        if not(po_methodpointer in procoptions) then
          if not is_nested_pd(self) then
            result:='procvar'
          else
            result:='nestedprovar'
        else
          result:='procvarofobj'
      end;


    function tprocvardef.is_publishable : boolean;
      begin
         is_publishable:=(po_methodpointer in procoptions);
      end;


    function tprocvardef.GetTypeName : string;
      var
        s: string;
        showhidden : boolean;
      begin
{$ifdef EXTDEBUG}
         showhidden:=true;
{$else EXTDEBUG}
         showhidden:=false;
{$endif EXTDEBUG}
         s:='<';
         if po_classmethod in procoptions then
           s := s+'class method type of'
         else
           if po_addressonly in procoptions then
             s := s+'address of'
           else
             s := s+'procedure variable type of';
         if assigned(returndef) and
            (returndef<>voidtype) then
           s:=s+' function'+typename_paras(showhidden)+':'+returndef.GetTypeName
         else
           s:=s+' procedure'+typename_paras(showhidden);
         if po_methodpointer in procoptions then
           s := s+' of object';
         if is_nested_pd(self) then
           s := s+' is nested';
         GetTypeName := s+';'+ProcCallOptionStr[proccalloption]+'>';
      end;


{***************************************************************************
                              TOBJECTDEF
***************************************************************************}

   constructor tobjectdef.create(ot:tobjecttyp;const n:string;c:tobjectdef);
     begin
        inherited create(n,objectdef);
        fcurrent_dispid:=0;
        objecttype:=ot;
        childof:=nil;
        symtable:=tObjectSymtable.create(self,n,current_settings.packrecords);
        { create space for vmt !! }
        vmtentries:=TFPList.Create;
        vmt_offset:=0;
        set_parent(c);
        if objecttype in [odt_interfacecorba,odt_interfacecom,odt_dispinterface] then
          prepareguid;
        { setup implemented interfaces }
        if objecttype in [odt_class,odt_objcclass,odt_objcprotocol] then
          ImplementedInterfaces:=TFPObjectList.Create(true)
        else
          ImplementedInterfaces:=nil;
        writing_class_record_dbginfo:=false;
     end;


    constructor tobjectdef.ppuload(ppufile:tcompilerppufile);
      var
         i,
         implintfcount : longint;
         d : tderef;
         ImplIntf : TImplementedInterface;
         vmtentry : pvmtentry;
      begin
         inherited ppuload(objectdef,ppufile);
         objecttype:=tobjecttyp(ppufile.getbyte);
         objextname:=stringdup(ppufile.getstring);
         { only used for external Objective-C classes/protocols }
         if (objextname^='') then
           stringdispose(objextname);
         import_lib:=stringdup(ppufile.getstring);
         { only used for external C++ classes }
         if (import_lib^='') then
           stringdispose(import_lib);
         symtable:=tObjectSymtable.create(self,objrealname^,0);
         tObjectSymtable(symtable).datasize:=ppufile.getaint;
         tObjectSymtable(symtable).fieldalignment:=ppufile.getbyte;
         tObjectSymtable(symtable).recordalignment:=ppufile.getbyte;
         vmt_offset:=ppufile.getlongint;
         ppufile.getderef(childofderef);

         { load guid }
         iidstr:=nil;
         if objecttype in [odt_interfacecom,odt_interfacecorba,odt_dispinterface] then
           begin
              new(iidguid);
              ppufile.getguid(iidguid^);
              iidstr:=stringdup(ppufile.getstring);
           end;

         vmtentries:=TFPList.Create;
         vmtentries.count:=ppufile.getlongint;
         for i:=0 to vmtentries.count-1 do
           begin
             ppufile.getderef(d);
             new(vmtentry);
             vmtentry^.procdef:=nil;
             vmtentry^.procdefderef:=d;
             vmtentry^.visibility:=tvisibility(ppufile.getbyte);
             vmtentries[i]:=vmtentry;
           end;

         { load implemented interfaces }
         if objecttype in [odt_class,odt_objcclass,odt_objcprotocol] then
           begin
             ImplementedInterfaces:=TFPObjectList.Create(true);
             implintfcount:=ppufile.getlongint;
             for i:=0 to implintfcount-1 do
               begin
                 ppufile.getderef(d);
                 ImplIntf:=TImplementedInterface.Create_deref(d);
                 ImplIntf.IOffset:=ppufile.getlongint;
                 ImplementedInterfaces.Add(ImplIntf);
               end;
           end
         else
           ImplementedInterfaces:=nil;

         if df_copied_def in defoptions then
           ppufile.getderef(cloneddefderef)
         else
           tObjectSymtable(symtable).ppuload(ppufile);

         { handles the predefined class tobject  }
         { the last TOBJECT which is loaded gets }
         { it !                                  }
         if (childof=nil) and
            (objecttype=odt_class) and
            (objname^='TOBJECT') then
           class_tobject:=self;
         if (childof=nil) and
            (objecttype=odt_interfacecom) and
            (objname^='IUNKNOWN') then
           interface_iunknown:=self;
         if (childof=nil) and
            (objecttype=odt_objcclass) and
            (objname^='PROTOCOL') then
           objc_protocoltype:=self;
         writing_class_record_dbginfo:=false;
       end;


    destructor tobjectdef.destroy;
      begin
         if assigned(symtable) then
           begin
             symtable.free;
             symtable:=nil;
           end;
         stringdispose(objextname);
         stringdispose(import_lib);
         stringdispose(iidstr);
         if assigned(ImplementedInterfaces) then
           begin
             ImplementedInterfaces.free;
             ImplementedInterfaces:=nil;
           end;
         if assigned(iidguid) then
           begin
             dispose(iidguid);
             iidguid:=nil;
           end;
         if assigned(vmtentries) then
           begin
             resetvmtentries;
             vmtentries.free;
             vmtentries:=nil;
           end;
         if assigned(vmcallstaticinfo) then
           begin
             freemem(vmcallstaticinfo);
             vmcallstaticinfo:=nil;
           end;
         inherited destroy;
      end;


    function tobjectdef.getcopy : tstoreddef;
      var
        i : longint;
      begin
        result:=tobjectdef.create(objecttype,objrealname^,childof);
        { the constructor allocates a symtable which we release to avoid memory leaks }
        tobjectdef(result).symtable.free;
        tobjectdef(result).symtable:=symtable.getcopy;
        if assigned(objextname) then
          tobjectdef(result).objextname:=stringdup(objextname^);
        if assigned(import_lib) then
          tobjectdef(result).import_lib:=stringdup(import_lib^);
        tobjectdef(result).objectoptions:=objectoptions;
        include(tobjectdef(result).defoptions,df_copied_def);
        tobjectdef(result).vmt_offset:=vmt_offset;
        if assigned(iidguid) then
          begin
            new(tobjectdef(result).iidguid);
            move(iidguid^,tobjectdef(result).iidguid^,sizeof(iidguid^));
          end;
        if assigned(iidstr) then
          tobjectdef(result).iidstr:=stringdup(iidstr^);
        if assigned(ImplementedInterfaces) then
          begin
            for i:=0 to ImplementedInterfaces.count-1 do
              tobjectdef(result).ImplementedInterfaces.Add(TImplementedInterface(ImplementedInterfaces[i]).Getcopy);
          end;
        if assigned(vmtentries) then
          begin
            tobjectdef(result).vmtentries:=TFPList.Create;
            tobjectdef(result).copyvmtentries(self);
          end;
      end;


    procedure tobjectdef.ppuwrite(ppufile:tcompilerppufile);
      var
         i : longint;
         vmtentry : pvmtentry;
         ImplIntf : TImplementedInterface;
         old_do_indirect_crc: boolean;
      begin
         { if class1 in unit A changes, and class2 in unit B inherits from it
           (so unit B uses unit A), then unit B with class2 will be recompiled.
           However, if there is also a class3 in unit C that only depends on
           unit B, then unit C will not be recompiled because nothing changed
           to the interface of unit B. Nevertheless, unit C can indirectly
           depend on unit A via derefs, and these must be updated -> the
           indirect crc keeps track of such changes. }
         old_do_indirect_crc:=ppufile.do_indirect_crc;
         ppufile.do_indirect_crc:=true;
         inherited ppuwrite(ppufile);
         ppufile.putbyte(byte(objecttype));
         if assigned(objextname) then
           ppufile.putstring(objextname^)
         else
           ppufile.putstring('');
         if assigned(import_lib) then
           ppufile.putstring(import_lib^)
         else
           ppufile.putstring('');
         ppufile.putaint(tObjectSymtable(symtable).datasize);
         ppufile.putbyte(tObjectSymtable(symtable).fieldalignment);
         ppufile.putbyte(tObjectSymtable(symtable).recordalignment);
         ppufile.putlongint(vmt_offset);
         ppufile.putderef(childofderef);
         if objecttype in [odt_interfacecom,odt_interfacecorba,odt_dispinterface] then
           begin
              ppufile.putguid(iidguid^);
              ppufile.putstring(iidstr^);
           end;

         ppufile.putlongint(vmtentries.count);
         for i:=0 to vmtentries.count-1 do
           begin
             vmtentry:=pvmtentry(vmtentries[i]);
             ppufile.putderef(vmtentry^.procdefderef);
             ppufile.putbyte(byte(vmtentry^.visibility));
           end;


         if assigned(ImplementedInterfaces) then
           begin
             ppufile.putlongint(ImplementedInterfaces.Count);
             for i:=0 to ImplementedInterfaces.Count-1 do
               begin
                 ImplIntf:=TImplementedInterface(ImplementedInterfaces[i]);
                 ppufile.putderef(ImplIntf.intfdefderef);
                 ppufile.putlongint(ImplIntf.Ioffset);
               end;
           end;

         if df_copied_def in defoptions then
           ppufile.putderef(cloneddefderef);

         ppufile.writeentry(ibobjectdef);

         if not(df_copied_def in defoptions) then
           tObjectSymtable(symtable).ppuwrite(ppufile);

         ppufile.do_indirect_crc:=old_do_indirect_crc;
      end;


    function tobjectdef.GetTypeName:string;
      begin
        { in this case we will go in endless recursion, because then  }
        { there is no tsym associated yet with the def. It can occur  }
        { (tests/webtbf/tw4757.pp), so for now give a generic name    }
        { instead of the actual type name                             }
        if not assigned(typesym) then
          result:='<Currently Parsed Class>'
        else
          result:=typename;
      end;


    procedure tobjectdef.buildderef;
      var
         i : longint;
         vmtentry : pvmtentry;
      begin
         inherited buildderef;
         childofderef.build(childof);
         if df_copied_def in defoptions then
           cloneddefderef.build(symtable.defowner)
         else
           tstoredsymtable(symtable).buildderef;

         for i:=0 to vmtentries.count-1 do
           begin
             vmtentry:=pvmtentry(vmtentries[i]);
             vmtentry^.procdefderef.build(vmtentry^.procdef);
           end;

         if assigned(ImplementedInterfaces) then
           begin
             for i:=0 to ImplementedInterfaces.count-1 do
               TImplementedInterface(ImplementedInterfaces[i]).buildderef;
           end;
      end;


    procedure tobjectdef.deref;
      var
         i : longint;
         vmtentry : pvmtentry;
      begin
         inherited deref;
         childof:=tobjectdef(childofderef.resolve);
         if df_copied_def in defoptions then
           begin
             cloneddef:=tobjectdef(cloneddefderef.resolve);
             symtable:=cloneddef.symtable.getcopy;
           end
         else
           tstoredsymtable(symtable).deref;
         for i:=0 to vmtentries.count-1 do
           begin
             vmtentry:=pvmtentry(vmtentries[i]);
             vmtentry^.procdef:=tprocdef(vmtentry^.procdefderef.resolve);
           end;
         if assigned(ImplementedInterfaces) then
           begin
             for i:=0 to ImplementedInterfaces.count-1 do
               TImplementedInterface(ImplementedInterfaces[i]).deref;
           end;
      end;


    procedure create_class_helper_for_procdef(def: tobject; arg: pointer);
      var
        pd: tprocdef absolute def;
        st: tsymtable;
        psym: tsym;
        nname: TIDString;
      begin
        if (tdef(def).typ<>procdef) then
          exit;
        { pd.owner = objcclass symtable -> defowner = objcclassdef ->
          owner = symtable in which objcclassdef is defined
        }
        st:=pd.owner.defowner.owner;
        nname:=class_helper_prefix+tprocsym(pd.procsym).name;
        { check for an existing procsym with our special name }
        psym:=tsym(st.find(nname));
        if not assigned(psym) then
          begin
            psym:=tprocsym.create(nname);
            { avoid warning about this symbol being unused }
            psym.IncRefCount;
            st.insert(psym,true);
          end
        else if (psym.typ<>procsym) then
          internalerror(2009111501);
        { add ourselves to this special procsym }
        tprocsym(psym).procdeflist.add(def);
      end;


    procedure tobjectdef.buildderefimpl;
      begin
         inherited buildderefimpl;
         if not (df_copied_def in defoptions) then
           tstoredsymtable(symtable).buildderefimpl;
      end;


    procedure tobjectdef.derefimpl;
      begin
         inherited derefimpl;
         if not (df_copied_def in defoptions) then
           tstoredsymtable(symtable).derefimpl;
         { the procdefs are not owned by the class helper procsyms, so they
           are not stored/restored either -> re-add them here }
         if (objecttype=odt_objcclass) or
            (oo_is_classhelper in objectoptions) then
           symtable.DefList.ForEachCall(@create_class_helper_for_procdef,nil);
      end;


    procedure tobjectdef.resetvmtentries;
      var
        i : longint;
      begin
        for i:=0 to vmtentries.Count-1 do
          Dispose(pvmtentry(vmtentries[i]));
        vmtentries.clear;
      end;


    procedure tobjectdef.copyvmtentries(objdef:tobjectdef);
      var
        i : longint;
        vmtentry : pvmtentry;
      begin
        resetvmtentries;
        vmtentries.count:=objdef.vmtentries.count;
        for i:=0 to objdef.vmtentries.count-1 do
          begin
            new(vmtentry);
            vmtentry^:=pvmtentry(objdef.vmtentries[i])^;
            vmtentries[i]:=vmtentry;
          end;
       end;


    function tobjectdef.getparentdef:tdef;
      begin
{ TODO: Remove getparentdef hack}
        { With 2 forward declared classes with the child class before the
          parent class the child class is written earlier to the ppu. Leaving it
          possible to have a reference to the parent class for property overriding,
          but the parent class still has the childof not resolved yet (PFV) }
        if childof=nil then
          childof:=tobjectdef(childofderef.resolve);
        result:=childof;
      end;


    procedure tobjectdef.prepareguid;
      begin
        { set up guid }
        if not assigned(iidguid) then
         begin
            new(iidguid);
            fillchar(iidguid^,sizeof(iidguid^),0); { default null guid }
         end;
        { setup iidstring }
        if not assigned(iidstr) then
          iidstr:=stringdup(''); { default is empty string }
      end;


    procedure tobjectdef.set_parent( c : tobjectdef);
      begin
        if assigned(childof) then
          exit;
        childof:=c;
        if not assigned(c) then
          exit;
        { inherit options and status }
        objectoptions:=objectoptions+(c.objectoptions*inherited_objectoptions);
        { add the data of the anchestor class/object }
        if (objecttype in [odt_class,odt_object,odt_objcclass]) then
          begin
            tObjectSymtable(symtable).datasize:=tObjectSymtable(symtable).datasize+tObjectSymtable(c.symtable).datasize;
            { inherit recordalignment }
            tObjectSymtable(symtable).recordalignment:=tObjectSymtable(c.symtable).recordalignment;
            if (oo_has_vmt in objectoptions) and
               (oo_has_vmt in c.objectoptions) then
              tObjectSymtable(symtable).datasize:=tObjectSymtable(symtable).datasize-sizeof(pint);
            { if parent has a vmt field then the offset is the same for the child PM }
            if (oo_has_vmt in c.objectoptions) or is_class(self) then
              begin
                vmt_offset:=c.vmt_offset;
                include(objectoptions,oo_has_vmt);
              end;
          end;
      end;


   procedure tobjectdef.insertvmt;
     var
       vs: tfieldvarsym;
     begin
        if objecttype in [odt_interfacecom,odt_interfacecorba,odt_dispinterface,odt_objcclass,odt_objcprotocol] then
          exit;
        if (oo_has_vmt in objectoptions) then
          internalerror(12345)
        else
          begin
             tObjectSymtable(symtable).datasize:=align(tObjectSymtable(symtable).datasize,
                 tObjectSymtable(symtable).fieldalignment);

             if (tf_requires_proper_alignment in target_info.flags) then
               begin
                 { Align VMT pointer and whole object instance if target CPU requires alignment. }
                 tObjectSymtable(symtable).datasize:=align(tObjectSymtable(symtable).datasize,sizeof(pint));
                 tObjectSymtable(symtable).alignrecord(tObjectSymtable(symtable).datasize,sizeof(pint));
               end;
             vs:=tfieldvarsym.create('_vptr$'+objname^,vs_value,voidpointertype,[]);
             hidesym(vs);
             tObjectSymtable(symtable).insert(vs);
             tObjectSymtable(symtable).addfield(vs,vis_hidden);
             if (tObjectSymtable(symtable).usefieldalignment<>bit_alignment) then
               vmt_offset:=vs.fieldoffset
             else
               vmt_offset:=vs.fieldoffset div 8;
             include(objectoptions,oo_has_vmt);
          end;
     end;



   procedure tobjectdef.check_forwards;
     begin
        if not(objecttype in [odt_interfacecom,odt_interfacecorba,odt_dispinterface,odt_objcprotocol]) then
          tstoredsymtable(symtable).check_forwards;
        if (oo_is_forward in objectoptions) then
          begin
             { ok, in future, the forward can be resolved }
             Message1(sym_e_class_forward_not_resolved,objrealname^);
             exclude(objectoptions,oo_is_forward);
          end;
     end;


   { true if prot implements d (or if they are equal) }
   function is_related_protocol(prot: tobjectdef; d : tdef) : boolean;
     var
       i  : longint;
     begin
       { objcprotocols have multiple inheritance, all protocols from which
         the current protocol inherits are stored in implementedinterfaces }
       result:=prot=d;
       if result then
         exit;

       for i:=0 to prot.ImplementedInterfaces.count-1 do
         begin
           result:=is_related_protocol(TImplementedInterface(prot.ImplementedInterfaces[i]).intfdef,d);
           if result then
             exit;
         end;
     end;


   { true, if self inherits from d (or if they are equal) }
   function tobjectdef.is_related(d : tdef) : boolean;
     var
        hp : tobjectdef;
     begin
        if self=d then
          begin
            is_related:=true;
            exit;
          end;

        if (d.typ<>objectdef) then
          begin
            is_related:=false;
            exit;
          end;

        { Objective-C protocols can use multiple inheritance }
        if (objecttype=odt_objcprotocol) then
          begin
            is_related:=is_related_protocol(self,d);
            exit
          end;

        { formally declared Objective-C classes match Objective-C classes with
          the same name }
        if (objecttype=odt_objcclass) and
           (tobjectdef(d).objecttype=odt_objcclass) and
           ((oo_is_formal in objectoptions) or
            (oo_is_formal in tobjectdef(d).objectoptions)) and
           (objrealname^=tobjectdef(d).objrealname^) then
          begin
            is_related:=true;
            exit;
          end;

        hp:=childof;
        while assigned(hp) do
          begin
             if hp=d then
               begin
                  is_related:=true;
                  exit;
               end;
             hp:=hp.childof;
          end;
        is_related:=false;
     end;

   function tobjectdef.find_procdef_bytype(pt:tproctypeoption): tprocdef;
     var
       i: longint;
       sym: tsym;
     begin
       for i:=0 to symtable.SymList.Count-1 do
         begin
           sym:=tsym(symtable.SymList[i]);
           if sym.typ=procsym then
             begin
               result:=tprocsym(sym).find_procdef_bytype(pt);
               if assigned(result) then
                 exit;
             end;
         end;
         result:=nil;
     end;

   function tobjectdef.find_destructor: tprocdef;
     var
       objdef: tobjectdef;
     begin
        objdef:=self;
        while assigned(objdef) do
          begin
            result:=objdef.find_procdef_bytype(potype_destructor);
            if assigned(result) then
              exit;
            objdef:=objdef.childof;
          end;
        result:=nil;
     end;

    function tobjectdef.implements_any_interfaces: boolean;
      begin
        result := (ImplementedInterfaces.Count > 0) or
          (assigned(childof) and childof.implements_any_interfaces);
      end;

    function tobjectdef.size : aint;
      begin
        if objecttype in [odt_class,odt_interfacecom,odt_interfacecorba,odt_dispinterface,odt_objcclass,odt_objcprotocol] then
          result:=sizeof(pint)
        else
          result:=tObjectSymtable(symtable).datasize;
      end;


    function tobjectdef.alignment:shortint;
      begin
        if objecttype in [odt_class,odt_interfacecom,odt_interfacecorba,odt_dispinterface,odt_objcclass,odt_objcprotocol] then
          alignment:=sizeof(pint)
        else
          alignment:=tObjectSymtable(symtable).recordalignment;
      end;


    function tobjectdef.vmtmethodoffset(index:longint):longint;
      begin
        { for offset of methods for classes, see rtl/inc/objpash.inc }
        case objecttype of
        odt_class:
          { the +2*sizeof(pint) is size and -size }
          vmtmethodoffset:=(index+10)*sizeof(pint)+2*sizeof(pint);
        odt_objcclass,
        odt_objcprotocol:
          vmtmethodoffset:=0;
        odt_interfacecom,odt_interfacecorba:
          vmtmethodoffset:=index*sizeof(pint);
        else
{$ifdef WITHDMT}
          vmtmethodoffset:=(index+4)*sizeof(pint);
{$else WITHDMT}
          vmtmethodoffset:=(index+3)*sizeof(pint);
{$endif WITHDMT}
        end;
      end;


    function tobjectdef.vmt_mangledname : string;
      begin
        if not(oo_has_vmt in objectoptions) then
          Message1(parser_n_object_has_no_vmt,objrealname^);
        vmt_mangledname:=make_mangledname('VMT',owner,objname^);
      end;


    function tobjectdef.needs_inittable : boolean;
      begin
         case objecttype of
            odt_dispinterface,
            odt_class :
              needs_inittable:=false;
            odt_interfacecom:
              needs_inittable:=true;
            odt_interfacecorba:
              needs_inittable:=is_related(interface_iunknown);
            odt_object:
              needs_inittable:=tObjectSymtable(symtable).needs_init_final;
            odt_cppclass,
            odt_objcclass,
            odt_objcprotocol:
              needs_inittable:=false;
            else
              internalerror(200108267);
         end;
      end;


    function tobjectdef.rtti_mangledname(rt: trttitype): string;
      begin
        if not(objecttype in [odt_objcclass,odt_objcprotocol]) then
          result:=inherited rtti_mangledname(rt)
        else
          begin
            { necessary in case of a dynamic array of nsobject, or
              if an nsobject field appears in a record that needs
              init/finalisation }
            if rt=initrtti then
              begin
                result:=voidpointertype.rtti_mangledname(rt);
                exit;
              end;

            if not(target_info.system in systems_objc_nfabi) then
              begin
                result:=target_asm.labelprefix;
                case objecttype of
                  odt_objcclass:
                    begin
                      case rt of
                        objcclassrtti:
                          if not(oo_is_classhelper in objectoptions) then
                            result:=result+'_OBJC_CLASS_'
                          else
                            result:=result+'_OBJC_CATEGORY_';
                        objcmetartti:
                          if not(oo_is_classhelper in objectoptions) then
                            result:=result+'_OBJC_METACLASS_'
                          else
                            internalerror(2009111511);
                        else
                         internalerror(2009092302);
                      end;
                    end;
                  odt_objcprotocol:
                    result:=result+'_OBJC_PROTOCOL_';
                end;
              end
            else
              begin
                case objecttype of
                  odt_objcclass:
                    begin
                      if (oo_is_classhelper in objectoptions) and
                         (rt<>objcclassrtti) then
                        internalerror(2009111512);
                      case rt of
                        objcclassrtti:
                          if not(oo_is_classhelper in objectoptions) then
                            result:='_OBJC_CLASS_$_'
                          else
                            result:='_OBJC_$_CATEGORY_';
                        objcmetartti:
                          result:='_OBJC_METACLASS_$_';
                        objcclassrortti:
                          result:=lower(target_asm.labelprefix)+'_OBJC_CLASS_RO_$_';
                        objcmetarortti:
                          result:=lower(target_asm.labelprefix)+'_OBJC_METACLASS_RO_$_';
                        else
                         internalerror(2009092303);
                      end;
                    end;
                  odt_objcprotocol:
                    begin
                      result:=lower(target_asm.labelprefix);
                      case rt of
                        objcclassrtti:
                          result:=result+'_OBJC_PROTOCOL_$_';
                        objcmetartti:
                          result:=result+'_OBJC_LABEL_PROTOCOL_$_';
                        else
                          internalerror(2009092501);
                      end;
                    end;
                end;
              end;
            result:=result+objextname^;
          end;
      end;


    function tobjectdef.members_need_inittable : boolean;
      begin
        members_need_inittable:=tObjectSymtable(symtable).needs_init_final;
      end;


    function tobjectdef.find_implemented_interface(aintfdef:tobjectdef):TImplementedInterface;
      var
        ImplIntf : TImplementedInterface;
        i : longint;
      begin
        result:=nil;
        if not assigned(ImplementedInterfaces) then
          exit;
        for i:=0 to ImplementedInterfaces.Count-1 do
          begin
            ImplIntf:=TImplementedInterface(ImplementedInterfaces[i]);
            if ImplIntf.intfdef=aintfdef then
              begin
                result:=ImplIntf;
                exit;
              end;
          end;
      end;


    function tobjectdef.is_publishable : boolean;
      begin
         is_publishable:=objecttype in [odt_class,odt_interfacecom,odt_interfacecorba,odt_dispinterface];
      end;


    function tobjectdef.get_next_dispid: longint;
      begin
        inc(fcurrent_dispid);
        result:=fcurrent_dispid;
      end;

    function tobjectdef.search_enumerator_get: tprocdef;
     var
        objdef : tobjectdef;
        sym : tsym;
        i : integer;
        pd : tprocdef;
        hashedid : THashedIDString;
     begin
        result:=nil;
        objdef:=self;
        hashedid.id:='GETENUMERATOR';
        while assigned(objdef) do
          begin
            sym:=tsym(objdef.symtable.FindWithHash(hashedid));
            if assigned(sym) and (sym.typ=procsym) then
              begin
                for i := 0 to Tprocsym(sym).ProcdefList.Count - 1 do
                begin
                  pd := tprocdef(Tprocsym(sym).ProcdefList[i]);
                  if (pd.proctypeoption = potype_function) and
                     is_class_or_interface_or_object(pd.returndef) and
                     (pd.visibility >= vis_public) then
                  begin
                    result:=pd;
                    exit;
                  end;
                end;
              end;
            objdef:=objdef.childof;
          end;
      end;

    function tobjectdef.search_enumerator_move: tprocdef;
     var
        objdef : tobjectdef;
        sym : tsym;
        i : integer;
        pd : tprocdef;
        hashedid : THashedIDString;
     begin
        result:=nil;
        objdef:=self;
        // first search for po_enumerator_movenext method modifier
        // then search for public function MoveNext: Boolean
        hashedid.id:='MOVENEXT';
        while assigned(objdef) do
          begin
            for i:=0 to objdef.symtable.SymList.Count-1 do
              begin
                sym:=TSym(objdef.symtable.SymList[i]);
                if (sym.typ=procsym) then
                begin
                  pd:=Tprocsym(sym).find_procdef_byoptions([po_enumerator_movenext]);
                  if assigned(pd) then
                    begin
                      result:=pd;
                      exit;
                    end;
                end;
              end;
            sym:=tsym(objdef.symtable.FindWithHash(hashedid));
            if assigned(sym) and (sym.typ=procsym) then
              begin
                for i := 0 to Tprocsym(sym).ProcdefList.Count - 1 do
                begin
                  pd := tprocdef(Tprocsym(sym).ProcdefList[i]);
                  if (pd.proctypeoption = potype_function) and
                     is_boolean(pd.returndef) and
                     (pd.minparacount = 0) and
                     (pd.visibility >= vis_public) then
                  begin
                    result:=pd;
                    exit;
                  end;
                end;
              end;
            objdef:=objdef.childof;
          end;
      end;

    function tobjectdef.search_enumerator_current: tsym;
     var
        objdef : tobjectdef;
        sym: tsym;
        i: integer;
        hashedid : THashedIDString;
     begin
        result:=nil;
        objdef:=self;
        hashedid.id:='CURRENT';
        // first search for ppo_enumerator_current property modifier
        // then search for public property Current
        while assigned(objdef) do
          begin
            for i:=0 to objdef.symtable.SymList.Count-1 do
              begin
                sym:=TSym(objdef.symtable.SymList[i]);
                if (sym.typ=propertysym) and (ppo_enumerator_current in tpropertysym(sym).propoptions) then
                begin
                  result:=sym;
                  exit;
                end;
              end;
            sym:=tsym(objdef.symtable.FindWithHash(hashedid));
            if assigned(sym) and (sym.typ=propertysym) and
               (sym.visibility >= vis_public) and not tpropertysym(sym).propaccesslist[palt_read].empty then
              begin
                result:=sym;
                exit;
              end;
            objdef:=objdef.childof;
          end;
      end;

    procedure tobjectdef.register_created_classref_type;
      begin
        if not classref_created_in_current_module then
          begin
            classref_created_in_current_module:=true;
            current_module.wpoinfo.addcreatedobjtypeforclassref(self);
          end;
      end;


    procedure tobjectdef.register_created_object_type;
      begin
        if not created_in_current_module then
          begin
            created_in_current_module:=true;
            current_module.wpoinfo.addcreatedobjtype(self);
          end;
      end;


    procedure tobjectdef.register_maybe_created_object_type;
      begin
        { if we know it has been created for sure, no need
          to also record that it maybe can be created in
          this module
        }
        if not (created_in_current_module) and
           not (maybe_created_in_current_module) then
          begin
            maybe_created_in_current_module:=true;
            current_module.wpoinfo.addmaybecreatedbyclassref(self);
          end;
      end;


    procedure tobjectdef.register_vmt_call(index: longint);
      begin
        if (is_object(self) or is_class(self)) then
          current_module.wpoinfo.addcalledvmtentry(self,index);
      end;


    procedure make_procdef_external(data: tobject; arg: pointer);
      var
        def: tdef absolute data;
      begin
        if (def.typ = procdef) then
          begin
            include(tprocdef(def).procoptions,po_external);
            tprocdef(def).forwarddef:=false;
          end;
      end;


    procedure tobjectdef.make_all_methods_external;
      begin
         self.symtable.deflist.foreachcall(@make_procdef_external,nil);
      end;


    procedure check_and_finish_msg(data: tobject; arg: pointer);
      var
        def: tdef absolute data;
        pd: tprocdef absolute data;
        i,
        paracount: longint;
      begin
        if (def.typ=procdef) then
          begin
            { add all messages also under a dummy name to the symtable in
              which the objcclass/protocol/category is declared, so they can
              be called via id.<name>
            }
            create_class_helper_for_procdef(pd,nil);

            { we have to wait until now to set the mangled name because it
              depends on the (possibly external) class name, which is defined
              at the very end.  }
            if not(po_msgstr in pd.procoptions) then
              begin
                CGMessagePos(pd.fileinfo,parser_e_objc_requires_msgstr);
                { recover to avoid internalerror later on }
                include(pd.procoptions,po_msgstr);
                pd.messageinf.str:=stringdup('MissingDeclaration');
              end;
            { Mangled name is already set in case this is a copy of
              another type.  }
            if not(po_has_mangledname in pd.procoptions) then
              begin
                { check whether the number of formal parameters is correct,
                  and whether they have valid Objective-C types }
                paracount:=0;
                for i:=1 to length(pd.messageinf.str^) do
                  if pd.messageinf.str^[i]=':' then
                    inc(paracount);
                for i:=0 to pd.paras.count-1 do
                  if not(vo_is_hidden_para in tparavarsym(pd.paras[i]).varoptions) and
                     not is_array_of_const(tparavarsym(pd.paras[i]).vardef) then
                    dec(paracount);
                if (paracount<>0) then
                  MessagePos(pd.fileinfo,sym_e_objc_para_mismatch);

                pd.setmangledname(pd.objcmangledname);
              end
            else
              { all checks already done }
              exit;
            if not(oo_is_external in pd.struct.objectoptions) then
              begin
                if (po_varargs in pd.procoptions) then
                  MessagePos(pd.fileinfo,parser_e_varargs_need_cdecl_and_external)
                else
                  begin
                    { check for "array of const" parameters }
                    for i:=0 to pd.parast.symlist.count-1 do
                      begin
                        if (tsym(pd.parast.symlist[i]).typ=paravarsym) and
                           is_array_of_const(tparavarsym(pd.parast.symlist[i]).vardef) then
                          MessagePos(pd.fileinfo,parser_e_varargs_need_cdecl_and_external);
                      end;
                  end;
              end;
          end;
      end;


    procedure mark_private_fields_used(data: tobject; arg: pointer);
      var
        sym: tsym absolute data;
      begin
        if (sym.typ=fieldvarsym) and
           (tfieldvarsym(sym).visibility in [vis_private,vis_strictprivate]) then
          sym.IncRefCount;
      end;


    procedure tobjectdef.finish_objc_data;
      begin
        self.symtable.DefList.foreachcall(@check_and_finish_msg,nil);
        if (oo_is_external in objectoptions) then
          self.symtable.SymList.ForEachCall(@mark_private_fields_used,nil);
      end;


    procedure verify_objc_vardef(data: tobject; arg: pointer);
      var
        sym: tabstractvarsym absolute data;
        res: pboolean absolute arg;
        founderrordef: tdef;
      begin
        if not(tsym(data).typ in [paravarsym,fieldvarsym]) then
          exit;
        if (sym.typ=paravarsym) and
           ((vo_is_hidden_para in tparavarsym(sym).varoptions) or
            is_array_of_const(tparavarsym(sym).vardef)) then
          exit;
        if not objcchecktype(sym.vardef,founderrordef) then
          begin
            MessagePos1(sym.fileinfo,type_e_objc_type_unsupported,founderrordef.typename);
            res^:=false;
          end;
      end;


    procedure verify_objc_procdef_paras(data: tobject; arg: pointer);
      var
        def: tdef absolute data;
        res: pboolean absolute arg;
        founderrordef: tdef;
      begin
        if (def.typ<>procdef) then
          exit;
        { check parameter types for validity }
        tprocdef(def).paras.foreachcall(@verify_objc_vardef,arg);
        { check the result type for validity }
        if not objcchecktype(tprocdef(def).returndef,founderrordef) then
          begin
            MessagePos1(tprocdef(def).funcretsym.fileinfo,type_e_objc_type_unsupported,founderrordef.typename);
            res^:=false;
          end;
      end;


    function tobjectdef.check_objc_types: boolean;
      begin
        { done in separate step from finish_objc_data, because when
          finish_objc_data is called, not all forwarddefs have been resolved
          yet and we need to know all types here }
        result:=true;
        self.symtable.symlist.foreachcall(@verify_objc_vardef,@result);
        self.symtable.deflist.foreachcall(@verify_objc_procdef_paras,@result);
      end;


    procedure do_cpp_import_info(data: tobject; arg: pointer);
      var
        def: tdef absolute data;
        pd: tprocdef absolute data;
      begin
        if (def.typ=procdef) then
          begin
            pd.setmangledname(target_info.Cprefix+pd.cplusplusmangledname);
            if (oo_is_external in pd.struct.objectoptions) then
              begin
                { copied from psub.read_proc }
                if assigned(tobjectdef(pd.struct).import_lib) then
                   current_module.AddExternalImport(tobjectdef(pd.struct).import_lib^,pd.mangledname,0,false,false)
                 else
                   begin
                     { add import name to external list for DLL scanning }
                     if tf_has_dllscanner in target_info.flags then
                       current_module.dllscannerinputlist.Add(pd.mangledname,pd);
                   end;

              end;
          end;
      end;


    procedure tobjectdef.finish_cpp_data;
      begin
        self.symtable.DefList.ForEachCall(@do_cpp_import_info,nil);
      end;

{****************************************************************************
                             TImplementedInterface
****************************************************************************}

    constructor TImplementedInterface.create(aintf: tobjectdef);
      begin
        inherited create;
        intfdef:=aintf;
        IOffset:=-1;
        IType:=etStandard;
        NameMappings:=nil;
        procdefs:=nil;
      end;


    constructor TImplementedInterface.create_deref(d:tderef);
      begin
        inherited create;
        intfdef:=nil;
        intfdefderef:=d;
        IOffset:=-1;
        IType:=etStandard;
        NameMappings:=nil;
        procdefs:=nil;
      end;


    destructor  TImplementedInterface.destroy;
      var
        i : longint;
        mappedname : pshortstring;
      begin
        if assigned(NameMappings) then
          begin
            for i:=0 to NameMappings.Count-1 do
              begin
                mappedname:=pshortstring(NameMappings[i]);
                stringdispose(mappedname);
              end;
            NameMappings.free;
            NameMappings:=nil;
          end;
        if assigned(procdefs) then
          begin
            procdefs.free;
            procdefs:=nil;
          end;
        inherited destroy;
      end;


    procedure TImplementedInterface.buildderef;
      begin
        intfdefderef.build(intfdef);
      end;


    procedure TImplementedInterface.deref;
      begin
        intfdef:=tobjectdef(intfdefderef.resolve);
      end;


    procedure TImplementedInterface.AddMapping(const origname,newname: string);
      begin
        if not assigned(NameMappings) then
          NameMappings:=TFPHashList.Create;
        NameMappings.Add(origname,stringdup(newname));
      end;


    function TImplementedInterface.GetMapping(const origname: string):string;
      var
        mappedname : pshortstring;
      begin
        result:='';
        if not assigned(NameMappings) then
          exit;
        mappedname:=PShortstring(NameMappings.Find(origname));
        if assigned(mappedname) then
          result:=mappedname^;
      end;


    procedure TImplementedInterface.AddImplProc(pd:tprocdef);
      begin
        if not assigned(procdefs) then
          procdefs:=TFPObjectList.Create(false);
        { duplicate entries must be stored, because multiple }
        { interfaces can declare methods with the same name  }
        { and all of these get their own VMT entry           }
        procdefs.Add(pd);
      end;


    function TImplementedInterface.IsImplMergePossible(MergingIntf:TImplementedInterface;out weight: longint): boolean;
      var
        i : longint;
      begin
        result:=false;
        { interfaces being implemented through delegation are not mergable (FK) }
        if (IType<>etStandard) or (MergingIntf.IType<>etStandard) or not(assigned(ProcDefs)) or not(assigned(MergingIntf.ProcDefs)) then
          exit;
        weight:=0;
        { empty interface is mergeable }
        if ProcDefs.Count=0 then
          begin
            result:=true;
            exit;
          end;
        { The interface to merge must at least the number of
          procedures of this interface }
        if MergingIntf.ProcDefs.Count<ProcDefs.Count then
          exit;
        for i:=0 to ProcDefs.Count-1 do
          begin
            if MergingIntf.ProcDefs[i]<>ProcDefs[i] then
              exit;
          end;
        weight:=ProcDefs.Count;
        result:=true;
      end;


    function TImplementedInterface.getcopy:TImplementedInterface;
      begin
        Result:=TImplementedInterface.Create(nil);
        {$warning: this is completely wrong on so many levels...}
        { 1) the procdefs list will be freed once for each copy
          2) since the procdefs list owns its elements, those will also be freed for each copy
          3) idem for the name mappings
        }
        Move(pointer(self)^,pointer(result)^,InstanceSize);
      end;


{****************************************************************************
                                TFORWARDDEF
****************************************************************************}

   constructor tforwarddef.create(const s:string;const pos : tfileposinfo);
     begin
        inherited create(forwarddef);
        tosymname:=stringdup(s);
        forwardpos:=pos;
     end;


    function tforwarddef.GetTypeName:string;
      begin
        GetTypeName:='unresolved forward to '+tosymname^;
      end;


    destructor tforwarddef.destroy;
      begin
        stringdispose(tosymname);
        inherited destroy;
      end;


{****************************************************************************
                               TUNDEFINEDDEF
****************************************************************************}

   constructor tundefineddef.create;
     begin
        inherited create(undefineddef);
     end;


    constructor tundefineddef.ppuload(ppufile:tcompilerppufile);
      begin
         inherited ppuload(undefineddef,ppufile);
      end;

    function tundefineddef.GetTypeName:string;
      begin
        GetTypeName:='<undefined type>';
      end;


    procedure tundefineddef.ppuwrite(ppufile:tcompilerppufile);
      begin
         inherited ppuwrite(ppufile);
         ppufile.writeentry(ibundefineddef);
      end;


{****************************************************************************
                                  TERRORDEF
****************************************************************************}

    constructor terrordef.create;
      begin
        inherited create(errordef);
        { prevent consecutive faults }
        savesize:=1;
      end;


    procedure terrordef.ppuwrite(ppufile:tcompilerppufile);
      begin
        { Can't write errordefs to ppu }
        internalerror(200411063);
      end;


    function terrordef.GetTypeName:string;
      begin
        GetTypeName:='<erroneous type>';
      end;


    function terrordef.getmangledparaname:string;
      begin
        getmangledparaname:='error';
      end;


{****************************************************************************
                           Definition Helpers
****************************************************************************}

    function is_interfacecom(def: tdef): boolean;
      begin
        is_interfacecom:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_interfacecom);
      end;

    function is_interfacecorba(def: tdef): boolean;
      begin
        is_interfacecorba:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_interfacecorba);
      end;

    function is_interface(def: tdef): boolean;
      begin
        is_interface:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype in [odt_interfacecom,odt_interfacecorba]);
      end;


    function is_dispinterface(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_dispinterface);
      end;


    function is_class(def: tdef): boolean;
      begin
        is_class:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_class);
      end;


    function is_object(def: tdef): boolean;
      begin
        is_object:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_object);
      end;


    function is_cppclass(def: tdef): boolean;
      begin
        is_cppclass:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_cppclass);
      end;


    function is_objcclass(def: tdef): boolean;
      begin
        is_objcclass:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_objcclass);
      end;


    function is_objcclassref(def: tdef): boolean;
      begin
        is_objcclassref:=
          assigned(def) and
          (def.typ=classrefdef) and
          is_objcclass(tclassrefdef(def).pointeddef);
      end;


    function is_objcprotocol(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype=odt_objcprotocol);
      end;


    function is_objccategory(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          { if used as a forward type }
          ((tobjectdef(def).objecttype=odt_objccategory) or
          { if used as after it has been resolved }
           ((tobjectdef(def).objecttype=odt_objcclass) and
            (oo_is_classhelper in tobjectdef(def).objectoptions)));
      end;

    function is_objc_class_or_protocol(def: tdef): boolean;
      begin
         result:=
           assigned(def) and
           (def.typ=objectdef) and
           (tobjectdef(def).objecttype in [odt_objcclass,odt_objcprotocol]);
      end;


    function is_objc_protocol_or_category(def: tdef): boolean;
      begin
         result:=
           assigned(def) and
           (def.typ=objectdef) and
           ((tobjectdef(def).objecttype = odt_objcprotocol) or
            ((tobjectdef(def).objecttype = odt_objcclass) and
             (oo_is_classhelper in tobjectdef(def).objectoptions)));
      end;


    function is_class_or_interface(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype in [odt_class,odt_interfacecom,odt_interfacecorba]);
      end;


    function is_class_or_interface_or_objc(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype in [odt_class,odt_interfacecom,odt_interfacecorba,odt_objcclass,odt_objcprotocol]);
      end;


    function is_class_or_interface_or_object(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype in [odt_class,odt_interfacecom,odt_interfacecorba,odt_object]);
      end;


    function is_class_or_interface_or_dispinterface(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype in [odt_class,odt_interfacecom,odt_interfacecorba,odt_dispinterface]);
      end;


    function is_class_or_interface_or_dispinterface_or_objc(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype in [odt_class,odt_interfacecom,odt_interfacecorba,odt_dispinterface,odt_objcclass,odt_objcprotocol]);
      end;

    function is_class_or_object(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=objectdef) and
          (tobjectdef(def).objecttype in [odt_class,odt_object]);
      end;

    function is_record(def: tdef): boolean;
      begin
        result:=
          assigned(def) and
          (def.typ=recorddef);
      end;

    procedure loadobjctypes;
      begin
        objc_metaclasstype:=tpointerdef(search_named_unit_globaltype('OBJC','POBJC_CLASS',true).typedef);
        objc_superclasstype:=tpointerdef(search_named_unit_globaltype('OBJC','POBJC_SUPER',true).typedef);
        objc_idtype:=tpointerdef(search_named_unit_globaltype('OBJC','ID',true).typedef);
        objc_seltype:=tpointerdef(search_named_unit_globaltype('OBJC','SEL',true).typedef);
        objc_objecttype:=trecorddef(search_named_unit_globaltype('OBJC','OBJC_OBJECT',true).typedef);
      end;


    procedure maybeloadcocoatypes;
      var
        tsym: ttypesym;
      begin
        if assigned(objc_fastenumeration) then
          exit;
        tsym:=search_named_unit_globaltype('COCOAALL','NSFASTENUMERATIONPROTOCOL',false);
        if assigned(tsym) then
          objc_fastenumeration:=tobjectdef(tsym.typedef)
        else
          objc_fastenumeration:=nil;
        tsym:=search_named_unit_globaltype('COCOAALL','NSFASTENUMERATIONSTATE',false);
        if assigned(tsym) then
          objc_fastenumerationstate:=trecorddef(tsym.typedef)
        else
        objc_fastenumerationstate:=nil;
      end;


    function use_vectorfpu(def : tdef) : boolean;
      begin
{$ifdef x86}
{$define use_vectorfpuimplemented}
        use_vectorfpu:=(is_single(def) and (current_settings.fputype in sse_singlescalar)) or
          (is_double(def) and (current_settings.fputype in sse_doublescalar));
{$endif x86}
{$ifdef arm}
{$define use_vectorfpuimplemented}
        use_vectorfpu:=(current_settings.fputype in vfp_scalar);
{$endif arm}
{$ifndef use_vectorfpuimplemented}
        use_vectorfpu:=false;
{$endif}
      end;

end.
