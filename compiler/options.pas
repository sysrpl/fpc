{
    $Id$
    Copyright (c) 1998-2000 by Florian Klaempfl and Peter Vreman

    Reads command line options and config files

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
unit options;

interface

uses
  globtype,globals,verbose;

type
  POption=^TOption;
  TOption=object
    FirstPass,
    NoPressEnter,
    DoWriteLogo : boolean;
    FileLevel : longint;
    ParaIncludePath,
    ParaUnitPath,
    ParaObjectPath,
    ParaLibraryPath : TSearchPathList;
    Constructor Init;
    Destructor Done;
    procedure WriteLogo;
    procedure WriteInfo;
    procedure WriteHelpPages;
    procedure QuickInfo(const s:string);
    procedure IllegalPara(const opt:string);
    function  Unsetbool(const opts:string; pos: Longint):boolean;
    procedure interpret_proc_specific_options(const opt:string);virtual;
    procedure interpret_option(const opt :string;ispara:boolean);
    procedure Interpret_envvar(const envname : string);
    procedure Interpret_file(const filename : string);
    procedure Read_Parameters;
    procedure parsecmd(cmd:string);
  end;

procedure read_arguments(cmd:string);


implementation

uses
{$ifdef Delphi}
  dmisc,
{$else Delphi}
  dos,
{$endif Delphi}
  version,systems,
  cobjects,
  symtable,scanner,link,messages
{$ifdef BrowserLog}
  ,browlog
{$endif BrowserLog}
{$ifdef i386}
  ,opts386
{$endif}
{$ifdef m68k}
  ,opts68k
{$endif}
  ;

const
  page_size = 24;

var
  option     : poption;
  read_configfile,        { read config file, set when a cfgfile is found }
  target_is_set : boolean;  { do not allow contradictory target settings }
  asm_is_set  : boolean; { -T also change initoutputformat if not set idrectly }
  ppccfg,
  msgfilename,
  param_file    : string;   { file to compile specified on the commandline }

{****************************************************************************
                                 Defines
****************************************************************************}

procedure def_symbol(const s : string);
begin
  if s='' then
   exit;
  initdefines.concat(new(pstring_item,init(upper(s))));
end;


procedure undef_symbol(const s : string);
var
  item,next : pstring_item;
begin
  if s='' then
   exit;
  item:=pstring_item(initdefines.first);
  while assigned(item) do
   begin
     if (item^.str^=s) then
      begin
        next:=pstring_item(item^.next);
        initdefines.remove(item);
        dispose(item,done);
        item:=next;
      end
     else
      if item<>pstring_item(item^.next) then
       item:=pstring_item(item^.next)
      else
       break;
   end;
end;


function check_symbol(const s:string):boolean;
var
  hp : pstring_item;
begin
  hp:=pstring_item(initdefines.first);
  while assigned(hp) do
   begin
     if (hp^.str^=s) then
      begin
        check_symbol:=true;
        exit;
      end;
     hp:=pstring_item(hp^.next);
   end;
  check_symbol:=false;
end;

procedure MaybeLoadMessageFile;
begin
{ Load new message file }
  if (msgfilename<>'')  then
    begin
       if fileexists(msgfilename) then
         LoadMsgFile(msgfilename);
       msgfilename:='';
    end;
end;

{****************************************************************************
                                 Toption
****************************************************************************}

procedure StopOptions;
begin
  if assigned(Option) then
   begin
     dispose(Option,Done);
     Option:=nil;
   end;
  DoneVerbose;
  Stop;
end;


procedure Toption.WriteLogo;
var
  i : tmsgconst;
begin
  MaybeLoadMessageFile;
  for i:=option_logo_start to option_logo_end do
   Message1(i,target_cpu_string);
end;


procedure Toption.WriteInfo;
var
  i : tmsgconst;
begin
  MaybeLoadMessageFile;
  for i:=option_info_start to option_info_end do
   Message(i);
  StopOptions;
end;


procedure Toption.WriteHelpPages;

  function PadEnd(s:string;i:longint):string;
  begin
    while (length(s)<i) do
     s:=s+' ';
    PadEnd:=s;
  end;

var
  idx,
  lastident,
  j,outline,
  ident,
  lines : longint;
  show  : boolean;
  opt   : string[32];
  input,
  s     : string;
begin
  MaybeLoadMessageFile;
  Message1(option_usage,paramstr(0));
  lastident:=0;
  if DoWriteLogo then
   lines:=3
  else
   lines:=1;
  for idx:=ord(ol_begin) to ord(ol_end) do
   begin
   { get a line and reset }
     s:=msg^.Get(idx);
     ident:=0;
     show:=false;
   { parse options }
     case s[1] of
{$ifdef i386}
      '3',
{$endif}
{$ifdef m68k}
      '6',
{$endif}
      '*' : show:=true;
     end;
     if show then
      begin
        case s[2] of
{$ifdef TP}
         't',
{$endif}
{$ifdef GDB}
         'g',
{$endif}
{$ifdef linux}
         'L',
{$endif}
{$ifdef os2}
         'O',
{$endif}
         '*' : show:=true;
        else
         show:=false;
        end;
      end;
   { now we may show the message or not }
     if show then
      begin
        case s[3] of
         '0' : begin
                 ident:=0;
                 outline:=0;
               end;
         '1' : begin
                 ident:=2;
                 outline:=7;
               end;
         '2' : begin
                 ident:=11;
                 outline:=11;
               end;
         '3' : begin
                 ident:=21;
                 outline:=6;
               end;
        end;
        j:=pos('_',s);
        opt:=Copy(s,4,j-4);
        if opt='*' then
         opt:=''
        else
         opt:=PadEnd('-'+opt,outline);
        if (ident=0) and (lastident<>0) then
         begin
           Comment(V_Normal,'');
           inc(Lines);
         end;
      { page full ? }
        if (lines>=page_size) then
         begin
           if not NoPressEnter then
            begin
              write('*** press enter ***');
              readln(input);
              if upper(input)='Q' then
               StopOptions;
            end;
           lines:=0;
         end;
        Comment(V_Normal,PadEnd('',ident)+opt+Copy(s,j+1,255));
        LastIdent:=Ident;
        inc(Lines);
      end;
   end;
  StopOptions;
end;


procedure Toption.QuickInfo(const s:string);
begin
  if source_os.newline=#13#10 then
    Write(s+#10)
  else
    Writeln(s);
  StopOptions;
end;


procedure Toption.IllegalPara(const opt:string);
begin
  Message1(option_illegal_para,opt);
  Message(option_help_pages_para);
  StopOptions;
end;


function Toption.Unsetbool(const opts:string; pos: Longint):boolean;
{ checks if the character after pos in Opts is a + or a - and returns resp.
  false or true. If it is another character (or none), it also returns false }
begin
  UnsetBool := (Length(Opts) > Pos) And (Opts[Succ(Pos)] = '-');
end;


procedure TOption.interpret_proc_specific_options(const opt:string);
begin
end;


procedure TOption.interpret_option(const opt:string;ispara:boolean);
var
  code : integer;
  c    : char;
  more : string;
  major,minor : longint;
  error : integer;
  j,l  : longint;
  d    : DirStr;
  e    : ExtStr;
begin
  if opt='' then
   exit;

  { only parse define,undef,target,verbosity and link options the firsttime }
  if firstpass and
     not((opt[1]='-') and (opt[2] in ['i','d','v','T','u','n','X'])) then
   exit;

  case opt[1] of
 '-' : begin
         more:=Copy(opt,3,255);
         case opt[2] of
              '!' : initlocalswitches:=initlocalswitches+[cs_ansistrings];
              '?' : WriteHelpPages;
              'a' : begin
                      initglobalswitches:=initglobalswitches+[cs_asm_leave];
                      for j:=1 to length(more) do
                       case more[j] of
                        'l' : initglobalswitches:=initglobalswitches+[cs_asm_source];
                        'r' : initglobalswitches:=initglobalswitches+[cs_asm_regalloc];
                        't' : initglobalswitches:=initglobalswitches+[cs_asm_tempalloc];
                        '-' : initglobalswitches:=initglobalswitches-[cs_asm_leave,cs_asm_source,cs_asm_regalloc];
                       else
                         IllegalPara(opt);
                       end;
                    end;
              'A' : begin
                      if set_string_asm(More) then
                       begin
                         initoutputformat:=target_asm.id;
                         asm_is_set:=true;
                       end
                      else
                       IllegalPara(opt);
                    end;
              'b' : begin
{$ifdef BrowserLog}
                      initglobalswitches:=initglobalswitches+[cs_browser_log];
{$endif}
                      if More<>'' then
                        if More='l' then
                          initmoduleswitches:=initmoduleswitches+[cs_local_browser]
                        else if More='-' then
                          begin
                            initmoduleswitches:=initmoduleswitches-[cs_browser,cs_local_browser];
{$ifdef BrowserLog}
                            initglobalswitches:=initglobalswitches-[cs_browser_log];
{$endif}
                          end
                        else if More<>'+' then
{$ifdef BrowserLog}
                          browserlog.elements_to_list^.insert(more);
{$else}
                          IllegalPara(opt);
{$endif}
                    end;
              'B' : if more='' then
                      do_build:=true
                    else
                      if more = '-' then
                        do_build := False
                      else
                        IllegalPara(opt);
              'C' : begin
                      j := 1;
                      while j <= length(more) Do
                        Begin
                          case more[j] of
                            'a' : Simplify_ppu:=true;
                            'h' :
                               begin
                                 val(copy(more,j+1,length(more)-j),heapsize,code);
                                 if (code<>0) or (heapsize>=67107840) or (heapsize<1024) then
                                  IllegalPara(opt);
                                 break;
                               end;
                            'i' : If UnsetBool(More, j) then
                                    Begin
                                      initlocalswitches:=initlocalswitches-[cs_check_io];
                                      inc(j)
                                    End
                                  else initlocalswitches:=initlocalswitches+[cs_check_io];
                            'n' : If UnsetBool(More, j) then
                                    Begin
                                      initglobalswitches:=initglobalswitches-[cs_link_extern];
                                      inc(j)
                                    End
                                  Else initglobalswitches:=initglobalswitches+[cs_link_extern];
                            'o' :
                              If UnsetBool(More, j) then
                                Begin
                                  initlocalswitches:=initlocalswitches-[cs_check_overflow];
                                  inc(j);
                                End
                              Else
                                initlocalswitches:=initlocalswitches+[cs_check_overflow];
                            'r' :
                              If UnsetBool(More, j) then
                                Begin
                                  initlocalswitches:=initlocalswitches-[cs_check_range];
                                  inc(j);
                                End
                              Else
                                initlocalswitches:=initlocalswitches+[cs_check_range];
                            's' :
                               begin
                                 val(copy(more,j+1,length(more)-j),stacksize,code);
                                 if (code<>0) or (stacksize>=67107840) or (stacksize<1024) then
                                  IllegalPara(opt);
                                 break;
                               end;
                            't' :
                               If UnsetBool(More, j) then
                                 Begin
                                   initlocalswitches:=initlocalswitches-[cs_check_stack];
                                   inc(j)
                                 End
                               Else
                                 initlocalswitches:=initlocalswitches+[cs_check_stack];
                            'D' :
                               If UnsetBool(More, j) then
                                 Begin
                                   initmoduleswitches:=initmoduleswitches-[cs_create_dynamic];
                                   inc(j)
                                 End
                               Else
                                 initmoduleswitches:=initmoduleswitches+[cs_create_dynamic];
                            'X' :
                               If UnsetBool(More, j) then
                                 Begin
                                   initmoduleswitches:=initmoduleswitches-[cs_create_smart];
                                   inc(j)
                                 End
                               Else
                                 initmoduleswitches:=initmoduleswitches+[cs_create_smart];
                            else
                               IllegalPara(opt);
                          end;
                          inc(j);
                        end;
                    end;
              'd' : def_symbol(more);
              'D' : begin
                      initglobalswitches:=initglobalswitches+[cs_link_deffile];
                      for j:=1 to length(more) do
                       case more[j] of
                        'd' : begin
                                description:=Copy(more,j+1,255);
                                break;
                              end;
                        'v' : begin
                                dllversion:=Copy(more,j+1,255);
                                l:=pos('.',dllversion);
                                dllminor:=0;
                                error:=0;
                                if l>0 then
                                  begin
                                    valint(copy(dllversion,l+1,255),minor,error);
                                    if (error=0) and
                                       (minor>=0) and (minor<=$ffff) then
                                      dllminor:=minor
                                    else if error=0 then
                                      error:=1;
                                  end;
                                if l=0 then l:=256;
                                dllmajor:=1;
                                if error=0 then
                                  valint(copy(dllversion,1,l-1),major,error);
                                if (error=0) and (major>=0) and (major<=$ffff) then
                                  dllmajor:=major
                                else if error=0 then
                                  error:=1;
                                if error<>0 then
                                  Message1(scan_w_wrong_version_ignored,dllversion);
                                break;
                              end;
                        'w' : usewindowapi:=true;
                       else
                         IllegalPara(opt);
                       end;
                    end;
              'e' : exepath:=FixPath(More,true);
              { Just used by RHIDE }
              'E' : if (length(more)=0) or (UnsetBool(More, 0)) then
                      initglobalswitches:=initglobalswitches+[cs_link_extern]
                    else
                      initglobalswitches:=initglobalswitches-[cs_link_extern];
              'F' : begin
                      c:=more[1];
                      Delete(more,1,1);
                      case c of
                       'D' : begin
                              if not ispara then
                               DefaultReplacements(More);
                              utilsdirectory:=FixPath(More,true);
                             end;
                       'e' : SetRedirectFile(More);
                       'E' : OutputExeDir:=FixPath(More,true);
                       'i' : if ispara then
                              ParaIncludePath.AddPath(More,false)
                             else
                              includesearchpath.AddPath(More,false);
                       'g' : Message2(option_obsolete_switch_use_new,'-Fg','-Fl');
                       'l' : if ispara then
                              ParaLibraryPath.AddPath(More,false)
                             else
                              LibrarySearchPath.AddPath(More,false);
                       'L' : if More<>'' then
                              ParaDynamicLinker:=More
                             else
                              IllegalPara(opt);
                       'o' : if ispara then
                              ParaObjectPath.AddPath(More,false)
                             else
                              ObjectSearchPath.AddPath(More,false);
                       'r' : Msgfilename:=More;
                       'u' : if ispara then
                              ParaUnitPath.AddPath(More,false)
                             else
                              unitsearchpath.AddPath(More,false);
                       'U' : OutputUnitDir:=FixPath(More,true);
                      else
                        IllegalPara(opt);
                      end;
                    end;
              'g' : begin
                      if UnsetBool(More, 0) then
                        initmoduleswitches:=initmoduleswitches-[cs_debuginfo]
                      else
                       begin
{$ifdef GDB}
                         initmoduleswitches:=initmoduleswitches+[cs_debuginfo];
                         if not RelocSectionSetExplicitly then
                           RelocSection:=false;
                         for j:=1 to length(more) do
                          case more[j] of
                           'd' : initglobalswitches:=initglobalswitches+[cs_gdb_dbx];
                           'g' : initglobalswitches:=initglobalswitches+[cs_gdb_gsym];
                           'h' : initglobalswitches:=initglobalswitches+[cs_gdb_heaptrc];
                           'c' : initglobalswitches:=initglobalswitches+[cs_checkpointer];
{$ifdef EXTDEBUG}
                           'p' : only_one_pass:=true;
{$endif EXTDEBUG}
                          else
                            IllegalPara(opt);
                          end;
{$else GDB}
                         Message(option_no_debug_support);
                         Message(option_no_debug_support_recompile_fpc);
{$endif GDB}
                       end;
                    end;
              'h' : begin
                      NoPressEnter:=true;
                      WriteHelpPages;
                    end;
              'i' : if more='' then
                     WriteInfo
                    else
                     begin
                        { Specific info, which can be used in Makefiles }
                        case More[1] of
                          'S' : begin
                                  case More[2] of
                                   'O' : QuickInfo(source_os.shortname);
{$ifdef Delphi !!!!!!!!!}
                                   'P' : QuickInfo('unknown');
{$else}
                                   'P' : QuickInfo(source_cpu_string);
{$endif}
                                  end;
                                end;
                          'T' : begin
                                  case More[2] of
                                   'O' : QuickInfo(target_os.shortname);
                                   'P' : QuickInfo(target_cpu_string);
                                  end;
                                end;
                          'V' : QuickInfo(version_string);
                          'D' : QuickInfo(date_string);
                        else
                          IllegalPara(Opt);
                        end;
                     end;
              'I' : if ispara then
                     ParaIncludePath.AddPath(More,false)
                    else
                     includesearchpath.AddPath(More,false);
              'k' : if more<>'' then
                     ParaLinkOptions:=ParaLinkOptions+' '+More
                    else
                     IllegalPara(opt);
              'l' : if more='' then
                      DoWriteLogo:=true
                    else
                      IllegalPara(opt);
              'm' : parapreprocess:=true;
              'n' : if More='' then
                     read_configfile:=false
                    else
                     IllegalPara(opt);
              'o' : if More<>'' then
                     Fsplit(More,d,OutputFile,e)
                    else
                     IllegalPara(opt);
              'p' : begin
                      if UnsetBool(More, 0) then
                        begin
                          initmoduleswitches:=initmoduleswitches-[cs_profile];
                          undef_symbol('FPC_PROFILE');
                        end
                      else
                        case more[1] of
                         'g' : if (length(opt)=3) and UnsetBool(more, 1) then
                                begin
                                  initmoduleswitches:=initmoduleswitches-[cs_profile];
                                  undef_symbol('FPC_PROFILE');
                                end
                               else
                                begin
                                  initmoduleswitches:=initmoduleswitches+[cs_profile];
                                  def_symbol('FPC_PROFILE');
                               end;
                        else
                          IllegalPara(opt);
                        end;
                    end;
{$ifdef linux}
              'P' : initglobalswitches:=initglobalswitches+[cs_asm_pipe];
{$endif}
              's' : initglobalswitches:=initglobalswitches+[cs_asm_extern,cs_link_extern];
              'S' : begin
                      for j:=1 to length(more) do
                       case more[j] of
                        '2' : initmodeswitches:=objfpcmodeswitches;
                        'c' : initmoduleswitches:=initmoduleswitches+[cs_support_c_operators];
                        'd' : initmodeswitches:=delphimodeswitches;
                        'e' : begin
                                val(copy(more,j+1,length(more)-j),l,code);
                                if (code<>0) then
                                 SetMaxErrorCount(1)
                                else
                                 begin
                                   SetMaxErrorCount(l);
                                   break;
                                 end;
                              end;
                        'g' : initmoduleswitches:=initmoduleswitches+[cs_support_goto];
                        'h' : initlocalswitches:=initlocalswitches+[cs_ansistrings];
                        'i' : initmoduleswitches:=initmoduleswitches+[cs_support_inline];
                        'm' : initmoduleswitches:=initmoduleswitches+[cs_support_macro];
                        'o':  initmodeswitches:=tpmodeswitches;
                        'p' : initmodeswitches:=gpcmodeswitches;
                        's' : initglobalswitches:=initglobalswitches+[cs_constructor_name];
                        't' : initmoduleswitches:=initmoduleswitches+[cs_static_keyword];
                        'v' : Message1(option_obsolete_switch,'-Sv');
                       else
                        IllegalPara(opt);
                       end;
                    end;
              'T' : begin
                      more:=Upper(More);
                      if not target_is_set then
                       begin
                       { remove old target define }
                         undef_symbol(target_info.short_name);
                       { load new target }
                         if not(set_string_target(More)) then
                           IllegalPara(opt);
                       { set new define }
                         def_symbol(target_info.short_name);
                         if not asm_is_set then
                           initoutputformat:=target_asm.id;
                         target_is_set:=true;
                       end
                      else
                       if More<>target_info.short_name then
                        Message1(option_target_is_already_set,target_info.short_name);
                    end;
              'u' : undef_symbol(upper(More));
              'U' : begin
                      for j:=1 to length(more) do
                       case more[j] of
{$ifdef UNITALIASES}
                        'a' : begin
                                AddUnitAlias(Copy(More,j+1,255));
                                break;
                              end;
{$endif UNITALIASES}
                        'n' : initglobalswitches:=initglobalswitches-[cs_check_unit_name];
                        'p' : begin
                                Message2(option_obsolete_switch_use_new,'-Up','-Fu');
                                break;
                              end;
                        's' : initmoduleswitches:=initmoduleswitches+[cs_compilesystem];
                       else
                         IllegalPara(opt);
                       end;
                    end;
              'v' : if not setverbosity(More) then
                     IllegalPara(opt);
              'W' : begin
                      for j:=1 to length(More) do
                       case More[j] of
                        'B': {bind_win32_dll:=true}
                             begin
                               {  -WB200000 means set prefered base address
                                 to $200000, but does not change relocsection boolean
                                 this way we can create both relocatble and
                                 non relocatable DLL at a specific base address PM }
                               if (length(More)>j) then
                                 begin
                                   if DLLImageBase=nil then
                                     DLLImageBase:=StringDup(Copy(More,j+1,255));
                                 end
                               else
                                 begin
                                   RelocSection:=true;
                                   RelocSectionSetExplicitly:=true;
                                 end;
                               break;
                             end;
                        'C': apptype:=at_cui;
                        'D': ForceDeffileForExport:=true;
                        'G': apptype:=at_gui;
                        'N': begin
                               RelocSection:=false;
                               RelocSectionSetExplicitly:=true;
                             end;

                        'R': begin
                               RelocSection:=true;
                               RelocSectionSetExplicitly:=true;
                             end;
                       else
                        IllegalPara(opt);
                       end;
                    end;
              'X' : begin
                      for j:=1 to length(More) do
                       case More[j] of
                        'c' : initglobalswitches:=initglobalswitches+[cs_link_toc];
                        's' : initglobalswitches:=initglobalswitches+[cs_link_strip];
                        'D' : begin
                                def_symbol('FPC_LINK_DYNAMIC');
                                undef_symbol('FPC_LINK_SMART');
                                undef_symbol('FPC_LINK_STATIC');
                                initglobalswitches:=initglobalswitches+[cs_link_shared];
                                initglobalswitches:=initglobalswitches-[cs_link_static,cs_link_smart];
                              end;
                        'S' : begin
                                def_symbol('FPC_LINK_STATIC');
                                undef_symbol('FPC_LINK_SMART');
                                undef_symbol('FPC_LINK_DYNAMIC');
                                initglobalswitches:=initglobalswitches+[cs_link_static];
                                initglobalswitches:=initglobalswitches-[cs_link_shared,cs_link_smart];
                              end;
                        'X' : begin
                                def_symbol('FPC_LINK_SMART');
                                undef_symbol('FPC_LINK_STATIC');
                                undef_symbol('FPC_LINK_DYNAMIC');
                                initglobalswitches:=initglobalswitches+[cs_link_smart];
                                initglobalswitches:=initglobalswitches-[cs_link_shared,cs_link_static];
                              end;
                       else
                         IllegalPara(opt);
                       end;
                    end;
       { give processor specific options a chance }
         else
          interpret_proc_specific_options(opt);
         end;
       end;
 '@' : begin
         Message(option_no_nested_response_file);
         StopOptions;
       end;
  else
   begin
     if (length(param_file)<>0) then
       Message(option_only_one_source_support);
     param_file:=opt;
   end;
  end;
end;


procedure Toption.Interpret_file(const filename : string);

  procedure RemoveSep(var fn:string);
  var
    i : longint;
  begin
    i:=0;
    while (i<length(fn)) and (fn[i+1] in [',',' ',#9]) do
      inc(i);
    Delete(fn,1,i);
    i:=length(fn);
    while (i>0) and (fn[i] in [',',' ',#9]) do
      dec(i);
    fn:=copy(fn,1,i);
  end;

  function GetName(var fn:string):string;
  var
    i : longint;
  begin
    i:=0;
    while (i<length(fn)) and (fn[i+1] in ['a'..'z','A'..'Z','0'..'9','_','-']) do
     inc(i);
    GetName:=Copy(fn,1,i);
    Delete(fn,1,i);
  end;

const
  maxlevel=16;
var
  f     : text;
  s,
  opts  : string;
  skip  : array[0..maxlevel-1] of boolean;
  level : longint;
  option_read : boolean;
begin
{ avoid infinite loop }
  Inc(FileLevel);
  Option_read:=false;
  If FileLevel>MaxLevel then
   Message(option_too_many_cfg_files);
{ open file }
  assign(f,filename);
{$ifdef extdebug}
  Comment(V_Info,'trying to open file: '+filename);
{$endif extdebug}
  {$I-}
  reset(f);
  {$I+}
  if ioresult<>0 then
   begin
     Message1(option_unable_open_file,filename);
     exit;
   end;
  fillchar(skip,sizeof(skip),0);
  level:=0;
  while not eof(f) do
   begin
     readln(f,opts);
     RemoveSep(opts);
     if (opts<>'') then
      begin
        if opts[1]='#' then
         begin
           Delete(opts,1,1);
           s:=upper(GetName(opts));
           if (s='SECTION') then
            begin
              RemoveSep(opts);
              s:=upper(GetName(opts));
              if level=0 then
               skip[level]:=not (check_symbol(s) or (s='COMMON'));
            end
           else
            if (s='IFDEF') then
             begin
               RemoveSep(opts);
               if Level>=maxlevel then
                begin
                  Message(option_too_many_ifdef);
                  stopOptions;
                end;
               inc(Level);
               skip[level]:=(skip[level-1] or (not check_symbol(upper(GetName(opts)))));
             end
           else
            if (s='IFNDEF') then
             begin
               RemoveSep(opts);
               if Level>=maxlevel then
                begin
                  Message(option_too_many_ifdef);
                  stopOptions;
                end;
               inc(Level);
               skip[level]:=(skip[level-1] or (check_symbol(upper(GetName(opts)))));
             end
           else
            if (s='ELSE') then
             skip[level]:=skip[level-1] or (not skip[level])
           else
            if (s='ENDIF') then
             begin
               skip[level]:=false;
               if Level=0 then
                begin
                  Message(option_too_many_endif);
                  stopOptions;
                end;
               dec(level);
             end
           else
            if (not skip[level]) then
             begin
               if (s='DEFINE') then
                begin
                  RemoveSep(opts);
                  def_symbol(upper(GetName(opts)));
                end
              else
               if (s='UNDEF') then
                begin
                  RemoveSep(opts);
                  undef_symbol(upper(GetName(opts)));
                end
              else
               if (s='WRITE') then
                begin
                  Delete(opts,1,1);
                  WriteLn(opts);
                end
              else
               if (s='INCLUDE') then
                begin
                  Delete(opts,1,1);
                  Interpret_file(opts);
                end;
            end;
         end
        else
         begin
           if (opts[1]='-') then
            begin
              if (not skip[level]) then
                interpret_option(opts,false);
              Option_read:=true;
            end
           else
             Message1(option_illegal_para,opts);
         end;
      end;
   end;
  if Level>0 then
   Message(option_too_less_endif);
  if Not Option_read then
    Message1(option_no_option_found,filename);
  Close(f);
  Dec(FileLevel);
end;


procedure Toption.Interpret_envvar(const envname : string);
var
  argstart,
  env,
  pc     : pchar;
  arglen : longint;
  quote  : set of char;
  hs     : string;
begin
  env:=GetEnvPChar(envname);
  pc:=env;
  repeat
    { skip leading spaces }
    while pc^ in [' ',#9,#13] do
     inc(pc);
    case pc^ of
      #0 : break;
     '"' : begin
             quote:=['"'];
             inc(pc);
           end;
    '''' : begin
             quote:=[''''];
             inc(pc);
           end;
    else
     quote:=[' ',#9,#13];
    end;
  { scan until the end of the argument }
    argstart:=pc;
    while (pc^<>#0) and not(pc^ in quote) do
     inc(pc);
  { create argument }
    arglen:=pc-argstart;
    hs[0]:=chr(arglen);
    move(argstart^,hs[1],arglen);
    interpret_option(hs,true);
  { skip quote }
    if pc^ in quote then
     inc(pc);
  until false;
  FreeEnvPChar(env);
end;


procedure toption.read_parameters;
var
  opts       : string;
  paramindex : longint;
begin
  paramindex:=0;
  while paramindex<paramcount do
   begin
     inc(paramindex);
     opts:=paramstr(paramindex);
     case opts[1] of
       '@' :
         begin
           Delete(opts,1,1);
           if not firstpass then
            Message1(option_reading_further_from,opts);
           interpret_file(opts);
         end;
       '!' :
         begin
           Delete(opts,1,1);
           if not firstpass then
            Message1(option_reading_further_from,'(env) '+opts);
           interpret_envvar(opts);
         end;
       else
         interpret_option(opts,true);
     end;
   end;
end;


procedure toption.parsecmd(cmd:string);
var
  i    : longint;
  opts : string;
begin
  while (cmd<>'') do
   begin
     while cmd[1]=' ' do
      delete(cmd,1,1);
     i:=pos(' ',cmd);
     if i=0 then
      i:=255;
     opts:=Copy(cmd,1,i-1);
     Delete(cmd,1,i);
     case opts[1] of
       '@' :
         begin
           Delete(opts,1,1);
           if not firstpass then
            Message1(option_reading_further_from,opts);
           interpret_file(opts);
         end;
       '!' :
         begin
           Delete(opts,1,1);
           if not firstpass then
            Message1(option_reading_further_from,'(env) '+opts);
           interpret_envvar(opts);
         end;
       else
         interpret_option(opts,true);
     end;
   end;
end;


constructor TOption.Init;
begin
  DoWriteLogo:=false;
  NoPressEnter:=false;
  FirstPass:=false;
  FileLevel:=0;
  ParaIncludePath.Init;
  ParaObjectPath.Init;
  ParaUnitPath.Init;
  ParaLibraryPath.Init;
end;


destructor TOption.Done;
begin
  ParaIncludePath.Done;
  ParaObjectPath.Done;
  ParaUnitPath.Done;
  ParaLibraryPath.Done;
end;


{****************************************************************************
                              Callable Routines
****************************************************************************}

procedure read_arguments(cmd:string);
var
  configpath : pathstr;
begin
{$ifdef Delphi}
  option:=new(poption386,Init);
{$endif Delphi}
{$ifdef i386}
  option:=new(poption386,Init);
{$endif}
{$ifdef m68k}
  option:=new(poption68k,Init);
{$endif}
{$ifdef alpha}
  option:=new(poption,Init);
{$endif}
{$ifdef powerpc}
  option:=new(poption,Init);
{$endif}
{ Load messages }
  if (cmd='') and (paramcount=0) then
   Option^.WriteHelpPages;

{ default defines }
  def_symbol(target_info.short_name);
  def_symbol('FPK');
  def_symbol('FPC');
  def_symbol('VER'+version_nr);
  def_symbol('VER'+version_nr+'_'+release_nr);
  def_symbol('VER'+version_nr+'_'+release_nr+'_'+patch_nr);
{$ifdef newcg}
  def_symbol('WITHNEWCG');
{$endif}

{ Temporary defines, until things settle down }
  def_symbol('INT64');
  def_symbol('HASRESOURCESTRINGS');
  def_symbol('HASSAVEREGISTERS');
  def_symbol('NEWVMTOFFSET');
  def_symbol('HASINTERNMATH');
  def_symbol('SYSTEMTVARREC');
  def_symbol('INCLUDEOK');
  def_symbol('NEWMM');
  def_symbol('HASWIDECHAR');
{$ifdef cardinalmulfix}
{ for the compiler }
  def_symbol('CARDINALMULFIX');
{ for the RTL }
  def_symbol('CARDINALMULFIXED');
{$endif cardinalmulfix}

{ some stuff for TP compatibility }
{$ifdef i386}
  def_symbol('CPU86');
  def_symbol('CPU87');
{$endif}
{$ifdef m68k}
  def_symbol('CPU68');
{$endif}

{ new processor stuff }
{$ifdef i386}
  def_symbol('CPUI386');
{$endif}
{$ifdef m68k}
  def_symbol('CPU68K');
{$endif}
{$ifdef ALPHA}
  def_symbol('CPUALPHA');
{$endif}
{$ifdef powerpc}
  def_symbol('CPUPOWERPC');
{$endif}

{ get default messagefile }
{$ifdef Delphi}
  msgfilename:=dmisc.getenv('PPC_ERROR_FILE');
{$else Delphi}
  msgfilename:=dos.getenv('PPC_ERROR_FILE');
{$endif Delphi}
{ default configfile }
  if (cmd<>'') and (cmd[1]='[') then
   begin
     ppccfg:=Copy(cmd,2,pos(']',cmd)-2);
     Delete(cmd,1,pos(']',cmd));
   end
  else
   begin
{$ifdef i386}
     ppccfg:='ppc386.cfg';
{$endif i386}
{$ifdef m68k}
     ppccfg:='ppc.cfg';
{$endif}
{$ifdef alpha}
     ppccfg:='ppcalpha.cfg';
{$endif}
{$ifdef powerpc}
     ppccfg:='ppcppc.cfg';
{$endif}
   end;

{ Order to read ppc386.cfg:
   1 - current dir
   2 - configpath
   3 - compiler path }
{$ifdef Delphi}
  configpath:=FixPath(dmisc.getenv('PPC_CONFIG_PATH'),false);
{$else Delphi}
  configpath:=FixPath(dos.getenv('PPC_CONFIG_PATH'),false);
{$endif Delphi}
{$ifdef linux}
  if configpath='' then
   configpath:='/etc/';
{$endif}
  if ppccfg<>'' then
   begin
     read_configfile:=true;
     if not FileExists(ppccfg) then
      begin
{$ifdef linux}
        if (dos.getenv('HOME')<>'') and FileExists(FixPath(dos.getenv('HOME'),false)+'.'+ppccfg) then
         ppccfg:=FixPath(dos.getenv('HOME'),false)+'.'+ppccfg
        else
{$endif}
         if FileExists(configpath+ppccfg) then
          ppccfg:=configpath+ppccfg
        else
{$ifndef linux}
         if FileExists(exepath+ppccfg) then
          ppccfg:=exepath+ppccfg
        else
{$endif}
         read_configfile:=false;
      end;
   end
  else
   read_configfile:=false;

{ Read commandline and configfile }
  target_is_set:=false;
  asm_is_set:=false;

  param_file:='';

  if read_configfile then
   begin
   { read the parameters quick, only -v -T }
     option^.firstpass:=true;
     if cmd<>'' then
       option^.parsecmd(cmd)
     else
       option^.read_parameters;
     option^.firstpass:=false;
     if read_configfile then
      begin
{$ifdef EXTDEBUG}
        Comment(V_Debug,'read config file: '+ppccfg);
{$endif EXTDEBUG}
        option^.interpret_file(ppccfg);
      end;
   end;
  if cmd<>'' then
    option^.parsecmd(cmd)
  else
    option^.read_parameters;

{ Stop if errors in options }
  if ErrorCount>0 then
   StopOptions;

{ write logo if set }
  if option^.DoWriteLogo then
   option^.WriteLogo;

{ Check file to compile }
  if param_file='' then
   begin
     Message(option_no_source_found);
     StopOptions;
   end;
{$ifndef linux}
  param_file:=FixFileName(param_file);
{$endif}
  fsplit(param_file,inputdir,inputfile,inputextension);
  if inputextension='' then
   begin
     if FileExists(inputdir+inputfile+target_os.sourceext) then
      inputextension:=target_os.sourceext
     else
      if FileExists(inputdir+inputfile+target_os.pasext) then
       inputextension:=target_os.pasext;
   end;

{ Add paths specified with parameters to the searchpaths }
  UnitSearchPath.AddList(Option^.ParaUnitPath,true);
  ObjectSearchPath.AddList(Option^.ParaObjectPath,true);
  IncludeSearchPath.AddList(Option^.ParaIncludePath,true);
  LibrarySearchPath.AddList(Option^.ParaLibraryPath,true);

{ add unit environment and exepath to the unit search path }
  if inputdir<>'' then
   Unitsearchpath.AddPath(inputdir,true);
{$ifdef Delphi}
  UnitSearchPath.AddPath(dmisc.getenv(target_info.unit_env),false);
{$else}
  UnitSearchPath.AddPath(dos.getenv(target_info.unit_env),false);
{$endif Delphi}
{$ifdef linux}
  UnitSearchPath.AddPath('/usr/lib/fpc/'+version_string+'/units/'+lower(target_info.short_name),false);
  UnitSearchPath.AddPath('/usr/lib/fpc/'+version_string+'/units/'+lower(target_info.short_name)+'/rtl',false);
{$else}
  UnitSearchPath.AddPath(ExePath+'../units/'+lower(target_info.short_name),false);
  UnitSearchPath.AddPath(ExePath+'../units/'+lower(target_info.short_name)+'/rtl',false);
{$endif}
  UnitSearchPath.AddPath(ExePath,false);
  { Add unit dir to the object and library path }
  objectsearchpath.AddList(unitsearchpath,false);
  librarysearchpath.AddList(unitsearchpath,false);

{ switch assembler if it's binary and we got -a on the cmdline }
  if (cs_asm_leave in initglobalswitches) and
     (target_asm.id in binassem) then
   begin
     Message(option_switch_bin_to_src_assembler);
     set_target_asm(target_info.assemsrc);
     initoutputformat:=target_asm.id;
   end;

{ turn off stripping if compiling with debuginfo or profile }
  if (cs_debuginfo in initmoduleswitches) or
     (cs_profile in initmoduleswitches) then
    initglobalswitches:=initglobalswitches-[cs_link_strip];

{ Set defines depending on the target }
  if (target_info.target in [target_i386_GO32V1,target_i386_GO32V2]) then
   def_symbol('DPMI'); { MSDOS is not defined in BP when target is DPMI }

  MaybeLoadMessageFile;

  dispose(option,Done);
  Option:=nil;
end;


end.
{
  $Log$
  Revision 1.50  2000-01-14 14:33:54  pierre
   + some warnings for wrong lines inside config files

  Revision 1.49  2000/01/10 11:14:19  peter
    * fixed memory leak with options, you must use StopOptions instead of
      Stop
    * fixed memory leak with forward resolving, make_ref is now false

  Revision 1.48  2000/01/07 22:22:02  marco
   * Added $target support for -FD

  Revision 1.47  2000/01/07 01:14:27  peter
    * updated copyright to 2000

  Revision 1.46  2000/01/06 15:48:59  peter
    * wildcard support for directory adding, this allows the use of units/*
      in ppc386.cfg

  Revision 1.45  1999/12/20 23:23:30  pierre
   + $description $version

  Revision 1.44  1999/12/20 21:42:36  pierre
    + dllversion global variable
    * FPC_USE_CPREFIX code removed, not necessary anymore
      as we use .edata direct writing by default now.

  Revision 1.43  1999/12/18 14:55:21  florian
    * very basic widestring support

  Revision 1.42  1999/12/11 18:53:31  jonas
    * fixed type conversions of results of operations with cardinals
      (between -dcardinalmulfix)

  Revision 1.41  1999/12/10 10:03:54  peter
    * fixed parameter orderning

  Revision 1.40  1999/12/08 10:40:01  pierre
    + allow use of unit var in exports of DLL for win32
      by using direct export writing by default instead of use of DEFFILE
      that does not allow assembler labels that do not
      start with an underscore.
      Use -WD to force use of Deffile for Win32 DLL

  Revision 1.39  1999/12/06 18:21:03  peter
    * support !ENVVAR for long commandlines
    * win32/go32v2 write short pathnames to link.res so c:\Program Files\ is
      finally supported as installdir.

  Revision 1.38  1999/12/02 17:34:34  peter
    * preprocessor support. But it fails on the caret in type blocks

  Revision 1.37  1999/11/20 01:22:19  pierre
    + cond FPC_USE_CPREFIX (needs also some RTL changes)
      this allows to use unit global vars as DLL exports
      (the underline prefix seems needed by dlltool)

  Revision 1.36  1999/11/15 17:42:40  pierre
   * -g disables reloc section for win32

  Revision 1.35  1999/11/12 11:03:50  peter
    * searchpaths changed to stringqueue object

  Revision 1.34  1999/11/09 23:06:45  peter
    * esi_offset -> selfpointer_offset to be newcg compatible
    * hcogegen -> cgbase fixes for newcg

  Revision 1.33  1999/11/06 14:34:21  peter
    * truncated log to 20 revs

  Revision 1.32  1999/11/04 23:13:25  peter
    * moved unit alias support into ifdef

  Revision 1.31  1999/11/04 10:54:03  peter
    + -Ua<oldname>=<newname> unit alias support

  Revision 1.30  1999/11/03 23:43:09  peter
    * default units/rtl paths

  Revision 1.29  1999/10/30 17:35:26  peter
    * fpc_freemem fpc_getmem new callings updated

  Revision 1.28  1999/10/28 11:13:36  pierre
   * fix for cygwin make problem with -iTP

  Revision 1.27  1999/10/26 13:13:47  peter
    * define INCLUDEOK, which seems to work correct

  Revision 1.26  1999/10/14 14:57:52  florian
    - removed the hcodegen use in the new cg, use cgbase instead

  Revision 1.25  1999/10/13 10:24:49  peter
    * dpmi can only be set after reading the options

  Revision 1.24  1999/10/03 19:44:41  peter
    * removed objpasunit reference, tvarrec is now searched in systemunit
      where it already was located

  Revision 1.23  1999/09/20 16:38:59  peter
    * cs_create_smart instead of cs_smartlink
    * -CX is create smartlink
    * -CD is create dynamic, but does nothing atm.

  Revision 1.22  1999/09/16 11:34:56  pierre
   * typo correction

  Revision 1.21  1999/09/15 20:35:40  florian
    * small fix to operator overloading when in MMX mode
    + the compiler uses now fldz and fld1 if possible
    + some fixes to floating point registers
    + some math. functions (arctan, ln, sin, cos, sqrt, sqr, pi) are now inlined
    * .... ???

  Revision 1.20  1999/09/03 09:31:22  peter
    * reading of search paths fixed to work as expected

  Revision 1.19  1999/09/01 22:07:20  peter
    * turn off stripping if profiling or debugging

  Revision 1.18  1999/08/28 17:46:10  peter
    * resources are working correct

  Revision 1.17  1999/08/28 15:34:19  florian
    * bug 519 fixed

  Revision 1.16  1999/08/27 10:45:03  pierre
   options -Ca sets simply_ppu to true

  Revision 1.15  1999/08/25 22:51:00  pierre
   * remove trailing space in cfg files

  Revision 1.14  1999/08/16 15:35:26  pierre
    * fix for DLL relocation problems
    * external bss vars had wrong stabs for pecoff
    + -WB11000000 to specify default image base, allows to
      load several DLLs with debugging info included
      (relocatable DLL are stripped because the relocation
       of the .Stab section is misplaced by ldw)

  Revision 1.13  1999/08/11 17:26:35  peter
    * tlinker object is now inherited for win32 and dos
    * postprocessexecutable is now a method of tlinker

}