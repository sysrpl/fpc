{
    $Id$
    Copyright (c) 2001-2002 by Peter Vreman

    This unit implements support import,export,link routines for MacOS.

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
unit t_macos;

{$i fpcdefs.inc}

interface

  uses
     import,symsym,symdef,link;

  type
    timportlibmacos=class(timportlib)
      procedure preparelib(const s:string);override;
      procedure importprocedure(aprocdef:tprocdef;const module:string;index:longint;const name:string);override;
      procedure importvariable(vs:tvarsym;const name,module:string);override;
      procedure generatelib;override;
    end;

    tlinkermpw=class(texternallinker)
    private
      Function  WriteResponseFile(isdll:boolean) : Boolean;
    public
      constructor Create;override;
      procedure SetDefaultInfo;override;
      function  MakeExecutable:boolean;override;
    end;

implementation

    uses
       cutils,cclasses,
       globtype,globals,systems,verbose,script,fmodule,i_macos,
       symconst;

{*****************************************************************************
                               TIMPORTLIBMACOS
*****************************************************************************}

procedure timportlibmacos.preparelib(const s : string);
begin
end;


procedure timportlibmacos.importprocedure(aprocdef:tprocdef;const module:string;index:longint;const name:string);
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


procedure timportlibmacos.importvariable(vs:tvarsym;const name,module:string);
begin
  { insert sharedlibrary }
  current_module.linkothersharedlibs.add(SplitName(module),link_allways);
  { reset the mangledname and turn off the dll_var option }
  vs.set_mangledname(name);
  exclude(vs.varoptions,vo_is_dll_var);
end;


procedure timportlibmacos.generatelib;
begin
end;

{*****************************************************************************
                                  TLINKERMPW
*****************************************************************************}

Constructor TLinkerMPW.Create;
begin
  Inherited Create;
  //LibrarySearchPath.AddPath('/lib;/usr/lib;/usr/X11R6/lib',true);
end;


procedure TLinkerMPW.SetDefaultInfo;

begin
  with Info do
   begin
     ExeCmd[1]:='PPCLink $OPT $DYNLINK $STATIC $STRIP -tocdataref off -dead on -o $EXE -@filelist $RES';
     DllCmd[1]:='PPCLink $OPT $INIT $FINI $SONAME -shared -o $EXE -@filelist $RES';
   end;
end;


Function TLinkerMPW.WriteResponseFile(isdll:boolean) : Boolean;

begin
  WriteResponseFile:=False;
end;


function TLinkerMPW.MakeExecutable:boolean;
var
  binstr,
  cmdstr  : string;
  success : boolean;
  DynLinkStr : string[60];
  StaticStr,
  StripStr   : string[40];

  s: string;

begin
  //TODO Only external link in MPW is possible, otherwise yell.

  if not(cs_link_extern in aktglobalswitches) then
    Message1(exec_i_linking,current_module.exefilename^);

{ Create some replacements }
(*
  StaticStr:='';
  StripStr:='';
  DynLinkStr:='';
  if (cs_link_staticflag in aktglobalswitches) then
   StaticStr:='-static';
  if (cs_link_strip in aktglobalswitches) then
   StripStr:='-s';
  If (cs_profile in aktmoduleswitches) or
     ((Info.DynamicLinker<>'') and (not SharedLibFiles.Empty)) then
   DynLinkStr:='-dynamic-linker='+Info.DynamicLinker;
*)

{ Call linker }
  SplitBinCmd(Info.ExeCmd[1],binstr,cmdstr);
  Replace(cmdstr,'$EXE',ScriptFixFileName(current_module.exefilename^));
  Replace(cmdstr,'$OPT',Info.ExtraOptions);
  Replace(cmdstr,'$RES',ScriptFixFileName(outputexedir+Info.ResName));
  Replace(cmdstr,'$STATIC',StaticStr);
  Replace(cmdstr,'$STRIP',StripStr);
  Replace(cmdstr,'$DYNLINK',DynLinkStr);

  with AsmRes do
    begin
      {#182 is escape char in MPW (analog to backslash in unix). The space}
      {ensures there is whitespace separating items.}
      Add('PPCLink '#182);

      { Add MPW standard libraries}
      if apptype = app_cui then
        begin
          Add('"{PPCLibraries}PPCSIOW.o" '#182);
          Add('"{PPCLibraries}PPCToolLibs.o" '#182);
        end;

      Add('"{SharedLibraries}InterfaceLib" '#182);
      Add('"{SharedLibraries}StdCLib" '#182);
      Add('"{SharedLibraries}MathLib" '#182);
      Add('"{PPCLibraries}StdCRuntime.o" '#182);
      Add('"{PPCLibraries}PPCCRuntime.o" '#182);

      {Add main objectfiles}
      while not ObjectFiles.Empty do
        begin
          s:=ObjectFiles.GetFirst;
          if s<>'' then
            Add(s+' '#182);
        end;
		
	  {Add last lines of the link command}
      if apptype = app_tool then
        Add('-t "MPST" -c "MPS " '#182);

      if apptype = app_cui then {If SIOW, to avoid some warnings.}
        Add('-ignoredups __start -ignoredups .__start -ignoredups main -ignoredups .main '#182); 

      Add('-tocdataref off -sym on -dead on -o '+ ScriptFixFileName(current_module.exefilename^)); 

      Add('Exit If "{Status}" != 0');

      {Add mac resources}
      if apptype = app_cui then
        begin
          Add('Rez -append "{RIncludes}"SIOW.r -o ' + ScriptFixFileName(current_module.exefilename^));
          Add('Exit If "{Status}" != 0');
        end;
      success:= true;
    end;

  MakeExecutable:=success;   { otherwise a recursive call to link method }
end;



{*****************************************************************************
                                  Initialize
*****************************************************************************}

initialization
{$ifdef m68k}
  RegisterTarget(system_m68k_macos_info);
  RegisterImport(system_m68k_macos,timportlibmacos);
{$endif m68k}
{$ifdef powerpc}
  RegisterExternalLinker(system_powerpc_macos_info,TLinkerMPW);
  RegisterTarget(system_powerpc_macos_info);
  RegisterImport(system_powerpc_macos,timportlibmacos);
{$endif powerpc}
end.
{
  $Log$
  Revision 1.10  2004-06-20 08:55:32  florian
    * logs truncated

  Revision 1.9  2004/05/11 18:24:39  olle
    + added GUI apptype to MacOS

  Revision 1.8  2004/04/06 22:44:22  olle
    + Status checks in scripts
    + Scripts support apptype tool
    + Added some ScriptFixFileName

  Revision 1.7  2004/02/19 20:40:20  olle
    + Support for Link on target especially for MacOS
    + TLinkerMPW
    + TAsmScriptMPW

}
