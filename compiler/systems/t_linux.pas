{
    $Id$
    Copyright (c) 1998-2002 by Peter Vreman

    This unit implements support import,export,link routines
    for the (i386) Linux target

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
unit t_linux;

{$i fpcdefs.inc}

interface

  uses
    symsym,symdef,
    import,export,link;

  type
    timportliblinux=class(timportlib)
      procedure preparelib(const s:string);override;
      procedure importprocedure(aprocdef:tprocdef;const module:string;index:longint;const name:string);override;
      procedure importvariable(vs:tvarsym;const name,module:string);override;
      procedure generatelib;override;
    end;

    texportliblinux=class(texportlib)
      procedure preparelib(const s : string);override;
      procedure exportprocedure(hp : texported_item);override;
      procedure exportvar(hp : texported_item);override;
      procedure generatelib;override;
    end;

    tlinkerlinux=class(texternallinker)
    private
      Glibc2,
      Glibc21 : boolean;
      Function  WriteResponseFile(isdll:boolean) : Boolean;
    public
      constructor Create;override;
      procedure SetDefaultInfo;override;
      function  MakeExecutable:boolean;override;
      function  MakeSharedLibrary:boolean;override;
    end;


implementation

  uses
    cutils,cclasses,
    verbose,systems,globtype,globals,
    symconst,script,
    fmodule,dos
    ,aasmbase,aasmtai,aasmcpu,cpubase
    ,i_linux
    ;

{*****************************************************************************
                               TIMPORTLIBLINUX
*****************************************************************************}

procedure timportliblinux.preparelib(const s : string);
begin
end;


procedure timportliblinux.importprocedure(aprocdef:tprocdef;const module:string;index:longint;const name:string);
begin
  { insert sharedlibrary }
  current_module.linkothersharedlibs.add(SplitName(module),link_allways);
  { do nothing with the procedure, only set the mangledname }
  if name<>'' then
   begin
     aprocdef.setmangledname(name);
   end
  else
    message(parser_e_empty_import_name);
end;


procedure timportliblinux.importvariable(vs:tvarsym;const name,module:string);
begin
  { insert sharedlibrary }
  current_module.linkothersharedlibs.add(SplitName(module),link_allways);
  { reset the mangledname and turn off the dll_var option }
  vs.set_mangledname(name);
  exclude(vs.varoptions,vo_is_dll_var);
end;


procedure timportliblinux.generatelib;
begin
end;


{*****************************************************************************
                               TEXPORTLIBLINUX
*****************************************************************************}

procedure texportliblinux.preparelib(const s:string);
begin
end;


procedure texportliblinux.exportprocedure(hp : texported_item);
var
  hp2 : texported_item;
begin
  { first test the index value }
  if (hp.options and eo_index)<>0 then
   begin
     Message1(parser_e_no_export_with_index_for_target,'linux');
     exit;
   end;
  { now place in correct order }
  hp2:=texported_item(current_module._exports.first);
  while assigned(hp2) and
     (hp.name^>hp2.name^) do
    hp2:=texported_item(hp2.next);
  { insert hp there !! }
  if assigned(hp2) and (hp2.name^=hp.name^) then
    begin
      { this is not allowed !! }
      Message1(parser_e_export_name_double,hp.name^);
      exit;
    end;
  if hp2=texported_item(current_module._exports.first) then
    current_module._exports.concat(hp)
  else if assigned(hp2) then
    begin
       hp.next:=hp2;
       hp.previous:=hp2.previous;
       if assigned(hp2.previous) then
         hp2.previous.next:=hp;
       hp2.previous:=hp;
    end
  else
    current_module._exports.concat(hp);
end;


procedure texportliblinux.exportvar(hp : texported_item);
begin
  hp.is_var:=true;
  exportprocedure(hp);
end;


procedure texportliblinux.generatelib;
var
  hp2 : texported_item;
begin
  hp2:=texported_item(current_module._exports.first);
  while assigned(hp2) do
   begin
     if (not hp2.is_var) and
        (hp2.sym.typ=procsym) then
      begin
        { the manglednames can already be the same when the procedure
          is declared with cdecl }
        if tprocsym(hp2.sym).first_procdef.mangledname<>hp2.name^ then
         begin
{$ifdef i386}
           { place jump in codesegment }
           codesegment.concat(Tai_align.Create_op(4,$90));
           codeSegment.concat(Tai_symbol.Createname_global(hp2.name^,AT_FUNCTION,0));
           codeSegment.concat(Taicpu.Op_sym(A_JMP,S_NO,objectlibrary.newasmsymbol(tprocsym(hp2.sym).first_procdef.mangledname,AB_EXTERNAL,AT_FUNCTION)));
           codeSegment.concat(Tai_symbol_end.Createname(hp2.name^));
{$else i386}
{$ifdef m68k}
           { place jump in codesegment }
           codesegment.concat(tai_align.create(4));
           codesegment.concat(tai_symbol.createname_global(hp2.name^,AT_FUNCTION,0));
           codesegment.concat(taicpu.op_sym(A_JMP,S_NO,objectlibrary.newasmsymbol(tprocsym(hp2.sym).first_procdef.mangledname,AB_EXTERNAL,AT_FUNCTION)));
           codesegment.concat(tai_symbol_end.createname(hp2.name^));
{$else m68k}
{$ifdef powerpc}
           { place jump in codesegment }
           codesegment.concat(tai_align.create(4));
           codesegment.concat(tai_symbol.createname_global(hp2.name^,AT_FUNCTION,0));
           codesegment.concat(taicpu.op_sym(A_B,objectlibrary.newasmsymbol(tprocsym(hp2.sym).first_procdef.mangledname,AB_EXTERNAL,AT_FUNCTION)));
           codesegment.concat(tai_symbol_end.createname(hp2.name^));
{$endif powerpc}
{$else powerpc}
{$error Exportliblinux.generatelib not yet implemented for target processor}
{$endif m68k}
{$endif i386}
         end;
      end
     else
      Message1(parser_e_no_export_of_variables_for_target,'linux');
     hp2:=texported_item(hp2.next);
   end;
end;


{*****************************************************************************
                                  TLINKERLINUX
*****************************************************************************}

Constructor TLinkerLinux.Create;
begin
  Inherited Create;
  if NOT Dontlinkstdlibpath Then
   LibrarySearchPath.AddPath('/lib;/usr/lib;/usr/X11R6/lib',true);
end;


procedure TLinkerLinux.SetDefaultInfo;
{
  This will also detect which libc version will be used
}
{$ifdef m68k}
var
  St : SearchRec;
{$endif m68k}
begin
  Glibc2:=false;
  Glibc21:=false;
  with Info do
   begin
     ExeCmd[1]:='ld $OPT $DYNLINK $STATIC $STRIP -L. -o $EXE $RES';
     DllCmd[1]:='ld $OPT $INIT $FINI $SONAME -shared -L. -o $EXE $RES';
     DllCmd[2]:='strip --strip-unneeded $EXE';
{$ifdef m68k}
     Glibc2:=true;
     FindFirst('/lib/ld*',AnyFile,st);
     while DosError=0 do
      begin
        if copy(st.name,1,5)='ld-2.' then
         begin
               DynamicLinker:='/lib/'+St.name;
               Glibc21:=st.name[6]<>'0';
           break;
             end;
            FindNext(St);
      end;
     FindClose(St);
{$else m68k}
{$ifdef i386}
     { first try glibc2 }
     DynamicLinker:='/lib/ld-linux.so.2';
     if FileExists(DynamicLinker) then
      begin
        Glibc2:=true;
        { Check for 2.0 files, else use the glibc 2.1 stub }
        if FileExists('/lib/ld-2.0.*') then
         Glibc21:=false
        else
         Glibc21:=true;
      end
     else
      DynamicLinker:='/lib/ld-linux.so.1';
{$else i386}
     Glibc2 := true;
     DynamicLinker:='/lib/ld.so.1';
{$endif i386}
{$endif m68k}
   end;
end;


Function TLinkerLinux.WriteResponseFile(isdll:boolean) : Boolean;
Var
  linkres      : TLinkRes;
  i            : longint;
  cprtobj,
  gprtobj,
  prtobj       : string[80];
  HPath        : TStringListItem;
  s,s1,s2      : string;
  found1,
  found2,
  linkdynamic,
  linklibc     : boolean;
begin
  WriteResponseFile:=False;
{ set special options for some targets }
  linkdynamic:=not(SharedLibFiles.empty);
  linklibc:=(SharedLibFiles.Find('c')<>nil);
  if isdll then
   begin
     prtobj:='dllprt0';
     cprtobj:='dllprt0';
     gprtobj:='dllprt0';
   end
  else
   begin
     prtobj:='prt0';
     cprtobj:='cprt0';
     gprtobj:='gprt0';
     if glibc21 then
      begin
        cprtobj:='cprt21';
        gprtobj:='gprt21';
      end;
   end;
  if cs_profile in aktmoduleswitches then
   begin
     prtobj:=gprtobj;
     if not glibc2 then
      AddSharedLibrary('gmon');
     AddSharedLibrary('c');
     linklibc:=true;
   end
  else
   begin
     if linklibc then
      prtobj:=cprtobj;
   end;

  { Open link.res file }
  LinkRes:=TLinkRes.Create(outputexedir+Info.ResName);

  { Write path to search libraries }
  HPath:=TStringListItem(current_module.locallibrarysearchpath.First);
  while assigned(HPath) do
   begin
     LinkRes.Add('SEARCH_DIR('+HPath.Str+')');
     HPath:=TStringListItem(HPath.Next);
   end;
  HPath:=TStringListItem(LibrarySearchPath.First);
  while assigned(HPath) do
   begin
     LinkRes.Add('SEARCH_DIR('+HPath.Str+')');
     HPath:=TStringListItem(HPath.Next);
   end;

  LinkRes.Add('INPUT(');
  { add objectfiles, start with prt0 always }
  if prtobj<>'' then
   LinkRes.AddFileName(FindObjectFile(prtobj,'',false));
  { try to add crti and crtbegin if linking to C }
  if linklibc then
   begin
     if librarysearchpath.FindFile('crtbegin.o',s) then
      LinkRes.AddFileName(s);
     if librarysearchpath.FindFile('crti.o',s) then
      LinkRes.AddFileName(s);
   end;
  { main objectfiles }
  while not ObjectFiles.Empty do
   begin
     s:=ObjectFiles.GetFirst;
     if s<>'' then
      LinkRes.AddFileName(s);
   end;
  LinkRes.Add(')');

  { Write staticlibraries }
  if not StaticLibFiles.Empty then
   begin
     LinkRes.Add('GROUP(');
     While not StaticLibFiles.Empty do
      begin
        S:=StaticLibFiles.GetFirst;
        LinkRes.AddFileName(s)
      end;
     LinkRes.Add(')');
   end;

  { Write sharedlibraries like -l<lib>, also add the needed dynamic linker
    here to be sure that it gets linked this is needed for glibc2 systems (PFV) }
  if not SharedLibFiles.Empty then
   begin
     LinkRes.Add('INPUT(');
     While not SharedLibFiles.Empty do
      begin
        S:=SharedLibFiles.GetFirst;
        if s<>'c' then
         begin
           i:=Pos(target_info.sharedlibext,S);
           if i>0 then
            Delete(S,i,255);
           LinkRes.Add('-l'+s);
         end
        else
         begin
           linklibc:=true;
           linkdynamic:=false; { libc will include the ld-linux for us }
         end;
      end;
     { be sure that libc is the last lib }
     if linklibc then
      LinkRes.Add('-lc');
     { when we have -static for the linker the we also need libgcc }
     if (cs_link_staticflag in aktglobalswitches) then
      LinkRes.Add('-lgcc');
     if linkdynamic and (Info.DynamicLinker<>'') then
      LinkRes.AddFileName(Info.DynamicLinker);
     LinkRes.Add(')');
   end;

  { objects which must be at the end }
  if linklibc then
   begin
     found1:=librarysearchpath.FindFile('crtend.o',s1);
     found2:=librarysearchpath.FindFile('crtn.o',s2);
     if found1 or found2 then
      begin
        LinkRes.Add('INPUT(');
        if found1 then
         LinkRes.AddFileName(s1);
        if found2 then
         LinkRes.AddFileName(s2);
        LinkRes.Add(')');
      end;
   end;
{ Write and Close response }
  linkres.writetodisk;
  linkres.Free;

  WriteResponseFile:=True;
end;


function TLinkerLinux.MakeExecutable:boolean;
var
  binstr,
  cmdstr  : string;
  success : boolean;
  DynLinkStr : string[60];
  StaticStr,
  StripStr   : string[40];
begin
  if not(cs_link_extern in aktglobalswitches) then
   Message1(exec_i_linking,current_module.exefilename^);

{ Create some replacements }
  StaticStr:='';
  StripStr:='';
  DynLinkStr:='';
  if (cs_link_staticflag in aktglobalswitches) then
   StaticStr:='-static';
  if (cs_link_strip in aktglobalswitches) then
   StripStr:='-s';
  If (cs_profile in aktmoduleswitches) or
     ((Info.DynamicLinker<>'') and (not SharedLibFiles.Empty)) then
   begin
     DynLinkStr:='-dynamic-linker='+Info.DynamicLinker;
     if cshared Then
       DynLinkStr:='--shared ' + DynLinkStr;
     if rlinkpath<>'' Then
       DynLinkStr:='--rpath-link '+rlinkpath + ' '+ DynLinkStr;
   End;

{ Write used files and libraries }
  WriteResponseFile(false);

{ Call linker }
  SplitBinCmd(Info.ExeCmd[1],binstr,cmdstr);
  Replace(cmdstr,'$EXE',current_module.exefilename^);
  Replace(cmdstr,'$OPT',Info.ExtraOptions);
  Replace(cmdstr,'$RES',outputexedir+Info.ResName);
  Replace(cmdstr,'$STATIC',StaticStr);
  Replace(cmdstr,'$STRIP',StripStr);
  Replace(cmdstr,'$DYNLINK',DynLinkStr);
  success:=DoExec(FindUtil(utilsprefix+BinStr),CmdStr,true,false);

{ Remove ReponseFile }
  if (success) and not(cs_link_extern in aktglobalswitches) then
   RemoveFile(outputexedir+Info.ResName);

  MakeExecutable:=success;   { otherwise a recursive call to link method }
end;


Function TLinkerLinux.MakeSharedLibrary:boolean;
var
  InitStr,
  FiniStr,
  SoNameStr : string[80];
  binstr,
  cmdstr  : string;
  success : boolean;
begin
  MakeSharedLibrary:=false;
  if not(cs_link_extern in aktglobalswitches) then
   Message1(exec_i_linking,current_module.sharedlibfilename^);

{ Write used files and libraries }
  WriteResponseFile(true);

 { Create some replacements }
  InitStr:='-init FPC_LIB_START';
  FiniStr:='-fini FPC_LIB_EXIT';
  SoNameStr:='-soname '+SplitFileName(current_module.sharedlibfilename^);

{ Call linker }
  SplitBinCmd(Info.DllCmd[1],binstr,cmdstr);
  Replace(cmdstr,'$EXE',current_module.sharedlibfilename^);
  Replace(cmdstr,'$OPT',Info.ExtraOptions);
  Replace(cmdstr,'$RES',outputexedir+Info.ResName);
  Replace(cmdstr,'$INIT',InitStr);
  Replace(cmdstr,'$FINI',FiniStr);
  Replace(cmdstr,'$SONAME',SoNameStr);
  success:=DoExec(FindUtil(utilsprefix+binstr),cmdstr,true,false);

{ Strip the library ? }
  if success and (cs_link_strip in aktglobalswitches) then
   begin
     SplitBinCmd(Info.DllCmd[2],binstr,cmdstr);
     Replace(cmdstr,'$EXE',current_module.sharedlibfilename^);
     success:=DoExec(FindUtil(utilsprefix+binstr),cmdstr,true,false);
   end;

{ Remove ReponseFile }
  if (success) and not(cs_link_extern in aktglobalswitches) then
   RemoveFile(outputexedir+Info.ResName);

  MakeSharedLibrary:=success;   { otherwise a recursive call to link method }
end;


{*****************************************************************************
                                  Initialize
*****************************************************************************}

initialization
{$ifdef i386}
  RegisterExternalLinker(system_i386_linux_info,TLinkerLinux);
  RegisterImport(system_i386_linux,timportliblinux);
  RegisterExport(system_i386_linux,texportliblinux);
  RegisterTarget(system_i386_linux_info);
{$endif i386}
{$ifdef m68k}
  RegisterExternalLinker(system_m68k_linux_info,TLinkerLinux);
  RegisterImport(system_m68k_linux,timportliblinux);
  RegisterExport(system_m68k_linux,texportliblinux);
  RegisterTarget(system_m68k_linux_info);
{$endif m68k}
{$ifdef powerpc}
  RegisterExternalLinker(system_powerpc_linux_info,TLinkerLinux);
  RegisterImport(system_powerpc_linux,timportliblinux);
  RegisterExport(system_powerpc_linux,texportliblinux);
  RegisterTarget(system_powerpc_linux_info);
{$endif powerpc}
{$ifdef alpha}
  RegisterExternalLinker(system_alpha_linux_info,TLinkerLinux);
  RegisterImport(system_alpha_linux,timportliblinux);
  RegisterExport(system_alpha_linux,texportliblinux);
  RegisterTarget(system_alpha_linux_info);
{$endif alpha}
{$ifdef x86_64}
  RegisterExternalLinker(system_x86_64_linux_info,TLinkerLinux);
  RegisterImport(system_x86_64_linux,timportliblinux);
  RegisterExport(system_x86_64_linux,texportliblinux);
  RegisterTarget(system_x86_64_linux_info);
{$endif x86_64}
{$ifdef SPARC}
  RegisterExternalLinker(system_sparc_linux_info,TLinkerLinux);
  RegisterImport(system_SPARC_linux,timportliblinux);
  RegisterExport(system_SPARC_linux,texportliblinux);
  RegisterTarget(system_SPARC_linux_info);
{$endif SPARC}
{$ifdef ARM}
  RegisterExternalLinker(system_arm_linux_info,TLinkerLinux);
  RegisterImport(system_arm_linux,timportliblinux);
  RegisterExport(system_arm_linux,texportliblinux);
  RegisterTarget(system_arm_linux_info);
{$endif ARM}
end.

{
  $Log$
  Revision 1.15  2004-03-02 00:36:33  olle
    * big transformation of Tai_[const_]Symbol.Create[data]name*

  Revision 1.14  2004/01/03 13:51:05  jonas
    + support exported procedures for linuxppc
    * refuse to compile systems/t_linux.pas if processor-specific  support
      for exported procedures is absent
    + generate .type and .size info for all currently defined linux-variants
      in aggas.pas

  Revision 1.13  2004/01/01 15:34:50  jonas
    * default linker name for non-i386 and non-m68k

  Revision 1.12  2003/10/30 18:35:30  marco
   * librarysuffix + profiling

  Revision 1.11  2003/10/11 19:32:04  marco
   * -Xd

  Revision 1.10  2003/10/03 14:16:48  marco
   * -XP<prefix> support

  Revision 1.9  2003/07/21 11:52:57  florian
    * very basic stuff for the arm

  Revision 1.8  2003/04/27 07:29:52  peter
    * aktprocdef cleanup, aktprocdef is now always nil when parsing
      a new procdef declaration
    * aktprocsym removed
    * lexlevel removed, use symtable.symtablelevel instead
    * implicit init/final code uses the normal genentry/genexit
    * funcret state checking updated for new funcret handling

  Revision 1.7  2003/04/26 09:16:08  peter
    * .o files belonging to the unit are first searched in the same dir
      as the .ppu

  Revision 1.6  2002/12/14 13:02:45  carl
    - remove extra ifdef i386 (avoir compilation errors)

  Revision 1.5  2002/12/06 17:51:43  peter
    * m68k library support

  Revision 1.4  2002/11/17 16:32:04  carl
    * memory optimization (3-4%) : cleanup of tai fields,
       cleanup of tdef and tsym fields.
    * make it work for m68k

  Revision 1.3  2002/11/15 01:59:02  peter
    * merged changes from 1.0.7 up to 04-11
      - -V option for generating bug report tracing
      - more tracing for option parsing
      - errors for cdecl and high()
      - win32 import stabs
      - win32 records<=8 are returned in eax:edx (turned off by default)
      - heaptrc update
      - more info for temp management in .s file with EXTDEBUG

  Revision 1.2  2002/09/09 17:34:17  peter
    * tdicationary.replace added to replace and item in a dictionary. This
      is only allowed for the same name
    * varsyms are inserted in symtable before the types are parsed. This
      fixes the long standing "var longint : longint" bug
    - consume_idlist and idstringlist removed. The loops are inserted
      at the callers place and uses the symtable for duplicate id checking

  Revision 1.1  2002/09/06 15:03:51  carl
    * moved files to systems directory

  Revision 1.33  2002/09/03 16:26:28  daniel
    * Make Tprocdef.defs protected

  Revision 1.32  2002/08/12 15:08:44  carl
    + stab register indexes for powerpc (moved from gdb to cpubase)
    + tprocessor enumeration moved to cpuinfo
    + linker in target_info is now a class
    * many many updates for m68k (will soon start to compile)
    - removed some ifdef or correct them for correct cpu

  Revision 1.31  2002/08/11 14:32:32  peter
    * renamed current_library to objectlibrary

  Revision 1.30  2002/08/11 13:24:19  peter
    * saving of asmsymbols in ppu supported
    * asmsymbollist global is removed and moved into a new class
      tasmlibrarydata that will hold the info of a .a file which
      corresponds with a single module. Added librarydata to tmodule
      to keep the library info stored for the module. In the future the
      objectfiles will also be stored to the tasmlibrarydata class
    * all getlabel/newasmsymbol and friends are moved to the new class

  Revision 1.29  2002/07/26 21:15:46  florian
    * rewrote the system handling

  Revision 1.28  2002/07/04 20:43:02  florian
    * first x86-64 patches

  Revision 1.27  2002/07/01 18:46:35  peter
    * internal linker
    * reorganized aasm layer

  Revision 1.26  2002/05/18 13:34:26  peter
    * readded missing revisions

  Revision 1.25  2002/05/16 19:46:53  carl
  + defines.inc -> fpcdefs.inc to avoid conflicts if compiling by hand
  + try to fix temp allocation (still in ifdef)
  + generic constructor calls
  + start of tassembler / tmodulebase class cleanup

  Revision 1.22  2002/05/06 19:46:36  carl
  + added more patches from Mazen for SPARC port

  Revision 1.21  2002/04/22 18:19:22  carl
  - remove use_bound_instruction field

  Revision 1.20  2002/04/20 21:43:18  carl
  * fix stack size for some targets
  + add offset to parameters from frame pointer info.
  - remove some unused stuff

  Revision 1.19  2002/04/19 15:46:05  peter
    * mangledname rewrite, tprocdef.mangledname is now created dynamicly
      in most cases and not written to the ppu
    * add mangeledname_prefix() routine to generate the prefix of
      manglednames depending on the current procedure, object and module
    * removed static procprefix since the mangledname is now build only
      on demand from tprocdef.mangledname

  Revision 1.18  2002/04/15 19:44:23  peter
    * fixed stackcheck that would be called recursively when a stack
      error was found
    * generic changeregsize(reg,size) for i386 register resizing
    * removed some more routines from cga unit
    * fixed returnvalue handling
    * fixed default stacksize of linux and go32v2, 8kb was a bit small :-)

  Revision 1.17  2002/04/15 19:16:57  carl
  - remove size_of_pointer field

  Revision 1.16  2002/01/29 21:27:34  peter
    * default alignment changed to 4 bytes for locals and static const,var

  Revision 1.15  2002/01/09 07:38:37  michael
  + Patch from Peter for library imports
}
