{
    $Id$
    Copyright (C) 1998-2000 by Florian Klaempfl

    This unit implements some support functions and global variables

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
unit globals;

{$i defines.inc}

interface

    uses
{$ifdef win32}
      windows,
{$endif}
{$ifdef unix}
  {$ifdef ver1_0}
      linux,
  {$else}
      unix,
  {$endif}
{$endif}
{$ifdef os2}
      doscalls,
{$endif}
{$ifdef Delphi}
      SysUtils,
      dmisc,
{$else}
      strings,
      dos,
{$endif}
      cutils,cclasses,
      globtype,version,systems;

    const
{$ifdef unix}
       DirSep = '/';
{$else}
  {$ifdef amiga}
       DirSep = '/';
  {$else}
       DirSep = '\';
  {$endif}
{$endif}

{$ifdef Splitheap}
       testsplit : boolean = false;
{$endif Splitheap}

       delphimodeswitches : tmodeswitches=
         [m_delphi,m_tp,m_all,m_class,m_objpas,m_result,m_string_pchar,
          m_pointer_2_procedure,m_autoderef,m_tp_procvar,m_initfinal,m_default_ansistring,
          m_out,m_default_para,m_hintdirective];
       fpcmodeswitches    : tmodeswitches=
         [m_fpc,m_all,m_string_pchar,m_nested_comment,m_repeat_forward,
          m_cvar_support,m_initfinal,m_add_pointer];
       objfpcmodeswitches : tmodeswitches=
         [m_objfpc,m_fpc,m_all,m_class,m_objpas,m_result,m_string_pchar,m_nested_comment,
          m_repeat_forward,m_cvar_support,m_initfinal,m_add_pointer,m_out,m_default_para];
       tpmodeswitches     : tmodeswitches=
         [m_tp7,m_tp,m_all,m_tp_procvar];
       gpcmodeswitches    : tmodeswitches=
         [m_gpc,m_all];

    type
       pfileposinfo = ^tfileposinfo;
       tfileposinfo = record
         line      : longint;
         column    : word;
         fileindex : word;
       end;

       TSearchPathList = class(TStringList)
         procedure AddPath(s:string;addfirst:boolean);
         procedure AddList(list:TSearchPathList;addfirst:boolean);
         function  FindFile(const f : string;var foundfile:string):boolean;
       end;

    var
       { specified inputfile }
       inputdir       : dirstr;
       inputfile      : namestr;
       inputextension : extstr;
       { specified outputfile with -o parameter }
       outputfile     : namestr;
       { specified with -FE or -FU }
       outputexedir   : dirstr;
       outputunitdir  : dirstr;

       { things specified with parameters }
       paralinkoptions,
       paradynamiclinker : string;
       parapreprocess    : boolean;

       { directory where the utils can be found (options -FD) }
       utilsdirectory : dirstr;

       { some flags for global compiler switches }
       do_build,
       do_release,
       do_make       : boolean;
       not_unit_proc : boolean;
       { path for searching units, different paths can be seperated by ; }
       exepath            : dirstr;  { Path to ppc }
       librarysearchpath,
       unitsearchpath,
       objectsearchpath,
       includesearchpath  : TSearchPathList;

       { deffile }
       usewindowapi  : boolean;
       description   : string;
       dllversion    : string;
       dllmajor,dllminor,dllrevision : word;  { revision only for netware }

       akttokenpos,                  { position of the last token }
       aktfilepos : tfileposinfo;    { current position }

       { ad 18.05.2001: Screen and Threadname for Netware }
       nwscreenname : string;
       nwthreadname : string;
       nwcopyright  : string;


       { type of currently parsed block }
       { isn't full implemented (FK)    }
       block_type : tblock_type;

       in_args : boolean;                { arguments must be checked especially }
       parsing_para_level : integer;     { parameter level, used to convert
                                           proc calls to proc loads in firstcalln }
       compile_level : word;
       make_ref : boolean;
       resolving_forward : boolean;      { used to add forward reference as second ref }
       use_esp_stackframe : boolean;     { to test for call with ESP as stack frame }
       inlining_procedure : boolean;     { are we inlining a procedure }
       statement_level : integer;
       aktexceptblock : integer;         { each except block gets a number check gotos }

     { commandline values }
       initdefines        : tstringlist;
       initglobalswitches : tglobalswitches;
       initmoduleswitches : tmoduleswitches;
       initlocalswitches  : tlocalswitches;
       initmodeswitches   : tmodeswitches;
       {$IFDEF testvarsets}
        Initsetalloc,                            {0=fixed, 1 =var}
       {$ENDIF}
       initpackenum       : longint;
       initpackrecords    : tpackrecords;
       initoptprocessor,
       initspecificoptprocessor : tprocessors;
       initasmmode        : tasmmode;
       initinterfacetype  : tinterfacetypes;
       initoutputformat   : tasm;
     { current state values }
       aktglobalswitches  : tglobalswitches;
       aktmoduleswitches  : tmoduleswitches;
       aktlocalswitches   : tlocalswitches;
       nextaktlocalswitches : tlocalswitches;
       localswitcheschanged : boolean;
       aktmodeswitches    : tmodeswitches;
       {$IFDEF testvarsets}
        aktsetalloc,
       {$ENDIF}
       aktpackenum        : longint;
       aktmaxfpuregisters : longint;
       aktpackrecords     : tpackrecords;
       aktoptprocessor,
       aktspecificoptprocessor : tprocessors;
       aktasmmode         : tasmmode;
       aktinterfacetype   : tinterfacetypes;
       aktoutputformat    : tasm;

     { Memory sizes }
       heapsize,
       maxheapsize,
       stacksize    : longint;

{$Ifdef EXTDEBUG}
       total_of_firstpass,
       firstpass_several : longint;
{$ifdef FPC}
       EntryMemUsed : longint;
{$endif FPC}
     { parameter switches }
       debugstop,
       only_one_pass : boolean;
{$EndIf EXTDEBUG}
       { windows / OS/2 application type }
       apptype : tapptype;

    const
       RelocSection : boolean = true;
       RelocSectionSetExplicitly : boolean = false;
       LinkTypeSetExplicitly : boolean = false;
       IsExe : boolean = false;
       DLLsource : boolean = false;
       DLLImageBase : pstring = nil;
       UseDeffileForExport : boolean = true;
       ForceDeffileForExport : boolean = false;

       { used to set all registers used for each global function
         this should dramatically decrease the number of
         recompilations needed PM }
       simplify_ppu : boolean = true;

       { should we allow non static members ? }
       allow_only_static : boolean = false;

       Inside_asm_statement : boolean = false;

       global_unit_count : word = 0;

       { for error info in pp.pas }
       parser_current_file : string = '';


    procedure abstract;

    function bstoslash(const s : string) : string;

    function getdatestr:string;
    function gettimestr:string;
    function filetimestring( t : longint) : string;

    procedure DefaultReplacements(var s:string);
    function  GetCurrentDir:string;
    function  path_absolute(const s : string) : boolean;
    Function  PathExists ( F : String) : Boolean;
    Function  FileExists ( Const F : String) : Boolean;
    Function  RemoveFile(const f:string):boolean;
    Function  RemoveDir(d:string):boolean;
    Function  GetFileTime ( Var F : File) : Longint;
    Function  GetNamedFileTime ( Const F : String) : Longint;
    Function  SplitPath(const s:string):string;
    Function  SplitFileName(const s:string):string;
    Function  SplitName(const s:string):string;
    Function  SplitExtension(Const HStr:String):String;
    Function  AddExtension(Const HStr,ext:String):String;
    Function  ForceExtension(Const HStr,ext:String):String;
    Function  FixPath(s:string;allowdot:boolean):string;
    function  FixFileName(const s:string):string;
    procedure SplitBinCmd(const s:string;var bstr,cstr:string);
    function  FindFile(const f : string;path : string;var foundfile:string):boolean;
    function  FindExe(const bin:string;var foundfile:string):boolean;
    function  GetShortName(const n:string):string;

    Procedure Shell(const command:string);
    function  GetEnvPChar(const envname:string):pchar;
    procedure FreeEnvPChar(p:pchar);

    Function SetCompileMode(const s:string; changeInit: boolean):boolean;

    procedure InitGlobals;
    procedure DoneGlobals;

    function  string2guid(const s: string; var GUID: TGUID): boolean;
    function  guid2string(const GUID: TGUID): string;


implementation

    uses
      comphook;

    procedure abstract;
      begin
        do_internalerror(255);
      end;


    function bstoslash(const s : string) : string;
    {
      return string s with all \ changed into /
    }
      var
         i : longint;
      begin
        for i:=1to length(s) do
         if s[i]='\' then
          bstoslash[i]:='/'
         else
          bstoslash[i]:=s[i];
         bstoslash[0]:=s[0];
      end;


{****************************************************************************
                               Time Handling
****************************************************************************}

    Function L0(l:longint):string;
    {
      return the string of value l, if l<10 then insert a zero, so
      the string is always at least 2 chars '01','02',etc
    }
      var
        s : string;
      begin
        Str(l,s);
        if l<10 then
         s:='0'+s;
        L0:=s;
      end;


   function gettimestr:string;
   {
     get the current time in a string HH:MM:SS
   }
      var
        hour,min,sec,hsec : word;
      begin
{$ifdef delphi}
        dmisc.gettime(hour,min,sec,hsec);
{$else delphi}
        dos.gettime(hour,min,sec,hsec);
{$endif delphi}
        gettimestr:=L0(Hour)+':'+L0(min)+':'+L0(sec);
      end;


   function getdatestr:string;
   {
     get the current date in a string YY/MM/DD
   }
      var
        Year,Month,Day,Wday : Word;
      begin
{$ifdef delphi}
        dmisc.getdate(year,month,day,wday);
{$else}
        dos.getdate(year,month,day,wday);
{$endif}
        getdatestr:=L0(Year)+'/'+L0(Month)+'/'+L0(Day);
      end;


   function  filetimestring( t : longint) : string;
   {
     convert dos datetime t to a string YY/MM/DD HH:MM:SS
   }
     var
       DT : DateTime;
     begin
       if t=-1 then
        begin
          FileTimeString:='Not Found';
          exit;
        end;
       unpacktime(t,DT);
       filetimestring:=L0(dt.Year)+'/'+L0(dt.Month)+'/'+L0(dt.Day)+' '+L0(dt.Hour)+':'+L0(dt.min)+':'+L0(dt.sec);
     end;


{****************************************************************************
                          Default Macro Handling
****************************************************************************}

     procedure DefaultReplacements(var s:string);
       begin
         { Replace some macro's }
         Replace(s,'$FPCVER',version_string);
         Replace(s,'$VERSION',version_string);
         Replace(s,'$FULLVERSION',full_version_string);
         Replace(s,'$FPCDATE',date_string);
         Replace(s,'$FPCTARGET',target_cpu_string);
         Replace(s,'$FPCCPU',target_cpu_string);
         Replace(s,'$TARGET',target_path);
         Replace(s,'$FPCOS',target_path);
       end;


{****************************************************************************
                               File Handling
****************************************************************************}

   function GetCurrentDir:string;
     var
       CurrentDir : string;
     begin
       GetDir(0,CurrentDir);
       GetCurrentDir:=FixPath(CurrentDir,false);
     end;


   function path_absolute(const s : string) : boolean;
   {
     is path s an absolute path?
   }
     begin
        path_absolute:=false;
{$ifdef unix}
        if (length(s)>0) and (s[1]='/') then
          path_absolute:=true;
{$else unix}
  {$ifdef amiga}
        if ((length(s)>0) and ((s[1]='\') or (s[1]='/'))) or (Pos(':',s) = length(s)) then
          path_absolute:=true;
  {$else}
        if ((length(s)>0) and ((s[1]='\') or (s[1]='/'))) or
           ((length(s)>2) and (s[2]=':') and ((s[3]='\') or (s[3]='/'))) then
          path_absolute:=true;
  {$endif amiga}
{$endif unix}
     end;

{$ifndef FPC}
    Procedure FindClose(var Info : SearchRec);
      Begin
      End;
{$endif not FPC}


    Function FileExists ( Const F : String) : Boolean;
{$ifndef delphi}
      Var
         Info : SearchRec;
{$endif}
      begin
{$ifdef delphi}
        FileExists:=sysutils.FileExists(f);
{$else}
        findfirst(F,readonly+archive+hidden,info);
        FileExists:=(doserror=0);
        findclose(Info);
{$endif delphi}
      end;


    Function PathExists ( F : String) : Boolean;
      Var
        Info : SearchRec;
      begin
        if F[Length(f)] in ['/','\'] then
         Delete(f,length(f),1);
        findfirst(F,readonly+archive+hidden+directory,info);
        PathExists:=(doserror=0) and ((info.attr and directory)=directory);
        findclose(Info);
      end;


    Function RemoveFile(const f:string):boolean;
      var
        g : file;
      begin
        assign(g,f);
        {$I-}
         erase(g);
        {$I+}
        RemoveFile:=(ioresult=0);
      end;


    Function RemoveDir(d:string):boolean;
      begin
        if d[length(d)]=DirSep then
         Delete(d,length(d),1);
        {$I-}
         rmdir(d);
        {$I+}
        RemoveDir:=(ioresult=0);
      end;


    Function SplitPath(const s:string):string;
      var
        i : longint;
      begin
        i:=Length(s);
        while (i>0) and not(s[i] in ['/','\']) do
         dec(i);
        SplitPath:=Copy(s,1,i);
      end;


    Function SplitFileName(const s:string):string;
      var
        p : dirstr;
        n : namestr;
        e : extstr;
      begin
        FSplit(s,p,n,e);
        SplitFileName:=n+e;
      end;


    Function SplitName(const s:string):string;
      var
        i,j : longint;
      begin
        i:=Length(s);
        j:=Length(s);
        while (i>0) and not(s[i] in ['/','\']) do
         dec(i);
        while (j>0) and (s[j]<>'.') do
         dec(j);
        if j<=i then
         j:=255;
        SplitName:=Copy(s,i+1,j-(i+1));
      end;


    Function SplitExtension(Const HStr:String):String;
      var
        j : longint;
      begin
        j:=length(Hstr);
        while (j>0) and (Hstr[j]<>'.') do
         begin
           if hstr[j]=DirSep then
            j:=0
           else
            dec(j);
         end;
        if j=0 then
         j:=254;
        SplitExtension:=Copy(Hstr,j,255);
      end;


    Function AddExtension(Const HStr,ext:String):String;
      begin
        if (Ext<>'') and (SplitExtension(HStr)='') then
         AddExtension:=Hstr+Ext
        else
         AddExtension:=Hstr;
      end;


    Function ForceExtension(Const HStr,ext:String):String;
      var
        j : longint;
      begin
        j:=length(Hstr);
        while (j>0) and (Hstr[j]<>'.') do
         dec(j);
        if j=0 then
         j:=255;
        ForceExtension:=Copy(Hstr,1,j-1)+Ext;
      end;


    Function FixPath(s:string;allowdot:boolean):string;
      var
        i : longint;
      begin
        { Fix separator }
        for i:=1 to length(s) do
         if s[i] in ['/','\'] then
          s[i]:=DirSep;
        { Fix ending / }
        if (length(s)>0) and (s[length(s)]<>DirSep) and
           (s[length(s)]<>':') then
         s:=s+DirSep;
        { Remove ./ }
        if (not allowdot) and (s='.'+DirSep) then
         s:='';
        { return }
{$ifdef unix}
        FixPath:=s;
{$else}
        FixPath:=Lower(s);
{$endif}
      end;


   function FixFileName(const s:string):string;
     var
       i      : longint;
     begin
       for i:=length(s) downto 1 do
        begin
          case s[i] of
{$ifdef Unix}
            '/','\' :
              FixFileName[i]:='/';
{$else Unix}
           '/' :
              FixFileName[i]:='\';
           'A'..'Z' :
              FixFileName[i]:=char(byte(s[i])+32);
{$endif Unix}
          else
           FixFileName[i]:=s[i];
          end;
        end;
       FixFileName[0]:=s[0];
     end;


   procedure SplitBinCmd(const s:string;var bstr,cstr:string);
     var
       i : longint;
     begin
       i:=pos(' ',s);
       if i>0 then
        begin
          bstr:=Copy(s,1,i-1);
          cstr:=Copy(s,i+1,length(s)-i);
        end
       else
        begin
          bstr:='';
          cstr:='';
        end;
     end;



   procedure TSearchPathList.AddPath(s:string;addfirst:boolean);
     var
       j        : longint;
       hs,hsd,
       CurrentDir,
       CurrPath : string;
       dir      : searchrec;
       hp       : TStringListItem;

       procedure addcurrpath;
       begin
         if addfirst then
          begin
            Remove(currPath);
            Insert(currPath);
          end
         else
          begin
            { Check if already in path, then we don't add it }
            hp:=Find(currPath);
            if not assigned(hp) then
             Concat(currPath);
          end;
       end;

     begin
       if s='' then
        exit;
     { Support default macro's }
       DefaultReplacements(s);
     { get current dir }
       CurrentDir:=GetCurrentDir;
       repeat
         { get currpath }
         if addfirst then
          begin
            j:=length(s);
            while (j>0) and (s[j]<>';') do
             dec(j);
            CurrPath:=FixPath(Copy(s,j+1,length(s)-j),false);
            if j=0 then
             s:=''
            else
             System.Delete(s,j,length(s)-j+1);
          end
         else
          begin
            j:=Pos(';',s);
            if j=0 then
             j:=255;
            CurrPath:=FixPath(Copy(s,1,j-1),false);
            System.Delete(s,1,j);
          end;
         { fix pathname }
         if CurrPath='' then
          CurrPath:='.'+DirSep
         else
          begin
            CurrPath:=FixPath(FExpand(CurrPath),false);
            if (CurrentDir<>'') and (Copy(CurrPath,1,length(CurrentDir))=CurrentDir) then
             CurrPath:='.'+DirSep+Copy(CurrPath,length(CurrentDir)+1,255);
          end;
         { wildcard adding ? }
         if pos('*',currpath)>0 then
          begin
            if currpath[length(currpath)]=dirsep then
             hs:=Copy(currpath,1,length(CurrPath)-1)
            else
             hs:=currpath;
            hsd:=SplitPath(hs);
            findfirst(hs,directory,dir);
            while doserror=0 do
             begin
               if (dir.name<>'.') and
                  (dir.name<>'..') and
                  ((dir.attr and directory)<>0) then
                begin
                  currpath:=hsd+dir.name+dirsep;
                  hp:=Find(currPath);
                  if not assigned(hp) then
                   AddCurrPath;
                end;
               findnext(dir);
             end;
            FindClose(dir);
          end
         else
          begin
            if PathExists(currpath) then
             addcurrpath;
          end;
       until (s='');
     end;


   procedure TSearchPathList.AddList(list:TSearchPathList;addfirst:boolean);
     var
       s : string;
       hl : TSearchPathList;
       hp,hp2 : TStringListItem;
     begin
       if list.empty then
        exit;
       { create temp and reverse the list }
       if addfirst then
        begin
          hl:=TSearchPathList.Create;
          hp:=TStringListItem(list.first);
          while assigned(hp) do
           begin
             hl.insert(hp.Str);
             hp:=TStringListItem(hp.next);
           end;
          while not hl.empty do
           begin
             s:=hl.GetFirst;
             Remove(s);
             Insert(s);
           end;
          hl.Free;
        end
       else
        begin
          hp:=TStringListItem(list.first);
          while assigned(hp) do
           begin
             hp2:=Find(hp.Str);
             { Check if already in path, then we don't add it }
             if not assigned(hp2) then
              Concat(hp.Str);
             hp:=TStringListItem(hp.next);
           end;
        end;
     end;


   function TSearchPathList.FindFile(const f : string;var foundfile:string):boolean;
     Var
       p : TStringListItem;
     begin
       FindFile:=false;
       p:=TStringListItem(first);
       while assigned(p) do
        begin
          {
            Search order for case sensitive systems:
             1. lowercase
             2. NormalCase
             3. UPPERCASE
            None case sensitive only lowercase
          }
          FoundFile:=p.Str+Lower(f);
          If FileExists(FoundFile) then
           begin
             FindFile:=true;
             exit;
           end;
{$ifdef UNIX}
          FoundFile:=p.Str+f;
          If FileExists(FoundFile) then
           begin
             FindFile:=true;
             exit;
           end;
          FoundFile:=p.Str+Upper(f);
          If FileExists(FoundFile) then
           begin
             FindFile:=true;
             exit;
           end;
{$endif UNIX}
          p:=TStringListItem(p.next);
        end;
       { Return original filename if not found }
       FoundFile:=f;
     end;


   Function GetFileTime ( Var F : File) : Longint;
     Var
     {$ifdef unix}
       Info : Stat;
     {$endif}
       L : longint;
     begin
     {$ifdef unix}
       FStat (F,Info);
       L:=Info.Mtime;
     {$else}
       GetFTime(f,l);
     {$endif}
       GetFileTime:=L;
     end;


   Function GetNamedFileTime (Const F : String) : Longint;
     begin
       GetNamedFileTime:=do_getnamedfiletime(F);
     end;


   function FindFile(const f : string;path : string;var foundfile:string):boolean;
      Var
        singlepathstring : string;
        i : longint;
     begin
{$ifdef Unix}
       for i:=1 to length(path) do
        if path[i]=':' then
         path[i]:=';';
{$endif Unix}
       FindFile:=false;
       repeat
          i:=pos(';',path);
          if i=0 then
           i:=256;
          singlepathstring:=FixPath(copy(path,1,i-1),false);
          delete(path,1,i);
          {
            Search order for case sensitive systems:
             1. lowercase
             2. NormalCase
             3. UPPERCASE
            None case sensitive only lowercase
          }
          FoundFile:=singlepathstring+Lower(f);
          If FileExists(FoundFile) then
           begin
             FindFile:=true;
             exit;
           end;
{$ifdef UNIX}
          FoundFile:=singlepathstring+f;
          If FileExists(FoundFile) then
           begin
             FindFile:=true;
             exit;
           end;
          FoundFile:=singlepathstring+Upper(f);
          If FileExists(FoundFile) then
           begin
             FindFile:=true;
             exit;
           end;
{$endif UNIX}
       until path='';
       FoundFile:=f;
     end;


   function  FindExe(const bin:string;var foundfile:string):boolean;
     begin
{$ifdef delphi}
       FindExe:=FindFile(FixFileName(AddExtension(bin,source_info.exeext)),'.;'+exepath+';'+dmisc.getenv('PATH'),foundfile);
{$else delphi}
       FindExe:=FindFile(FixFileName(AddExtension(bin,source_info.exeext)),'.;'+exepath+';'+dos.getenv('PATH'),foundfile);
{$endif delphi}
     end;


    function GetShortName(const n:string):string;
{$ifdef win32}
      var
        hs,hs2 : string;
        i : longint;
{$endif}
{$ifdef go32v2}
      var
        hs : string;
{$endif}
      begin
        GetShortName:=n;
{$ifdef win32}
        hs:=n+#0;
        i:=Windows.GetShortPathName(@hs[1],@hs2[1],high(hs2));
        if (i>0) and (i<=high(hs2)) then
          begin
            hs2[0]:=chr(strlen(@hs2[1]));
            GetShortName:=hs2;
          end;
{$endif}
{$ifdef go32v2}
        hs:=n;
        if Dos.GetShortName(hs) then
         GetShortName:=hs;
{$endif}
      end;


 {****************************************************************************
                               OS Dependent things
 ****************************************************************************}

    function GetEnvPChar(const envname:string):pchar;
      {$ifdef win32}
      var
        s     : string;
        i,len : longint;
        hp,p,p2 : pchar;
      {$endif}
      {$ifdef os2}
      var
        P1, P2: PChar;
      {$endif}
      begin
      {$ifdef unix}
        GetEnvPchar:={$ifdef ver1_0}Linux{$else}Unix{$endif}.Getenv(envname);
        {$define GETENVOK}
      {$endif}
      {$ifdef win32}
        GetEnvPchar:=nil;
        p:=GetEnvironmentStrings;
        hp:=p;
        while hp^<>#0 do
         begin
           s:=strpas(hp);
           i:=pos('=',s);
           len:=strlen(hp);
           if upper(copy(s,1,i-1))=upper(envname) then
            begin
              GetMem(p2,len-length(envname));
              Move(hp[i],p2^,len-length(envname));
              GetEnvPchar:=p2;
              break;
            end;
           { next string entry}
           hp:=hp+len+1;
         end;
        FreeEnvironmentStrings(p);
        {$define GETENVOK}
      {$endif}
      {$ifdef os2}
        P1 := StrPNew (EnvName);
        if Assigned (P1) then
        begin
         if DosCalls.DosScanEnv (P1, P2) = 0 then
          GetEnvPChar := P2
         else
          GetEnvPChar := nil;
         StrDispose (P1);
        end else GetEnvPChar := nil;
        {$define GETENVOK}
      {$endif}
      {$ifdef GETENVOK}
        {$undef GETENVOK}
      {$else}
        GetEnvPchar:=StrPNew({$ifdef delphi}DMisc{$else}Dos{$endif}.Getenv(envname));
      {$endif}
      end;


    procedure FreeEnvPChar(p:pchar);
      begin
      {$ifndef unix}
       {$ifndef os2}
        StrDispose(p);
       {$endif}
      {$endif}
      end;


    Procedure Shell(const command:string);
      { This is already defined in the linux.ppu for linux, need for the *
        expansion under linux }
      {$ifdef unix}
      begin
        {$ifdef ver1_0}Linux{$else}Unix{$endif}.Shell(command);
      end;
      {$else}
      var
        comspec : string;
      begin
        comspec:=getenv('COMSPEC');
        Exec(comspec,' /C '+command);
      end;
      {$endif}


    Function SetCompileMode(const s:string; changeInit: boolean):boolean;
      var
        b : boolean;
      begin
        b:=true;
        if s='DEFAULT' then
          aktmodeswitches:=initmodeswitches
        else
         if s='DELPHI' then
          aktmodeswitches:=delphimodeswitches
        else
         if s='TP' then
          aktmodeswitches:=tpmodeswitches
        else
         if s='FPC' then
          aktmodeswitches:=fpcmodeswitches
        else
         if s='OBJFPC' then
          aktmodeswitches:=objfpcmodeswitches
        else
         if s='GPC' then
          aktmodeswitches:=gpcmodeswitches
        else
         b:=false;

        if b and changeInit then
          initmodeswitches := aktmodeswitches;

        if b then
         begin
           { turn ansistrings on by default ? }
           if (m_delphi in aktmodeswitches) then
            begin
              include(aktlocalswitches,cs_ansistrings);
              if changeinit then
               include(initlocalswitches,cs_ansistrings);
            end
           else
            begin
              exclude(aktlocalswitches,cs_ansistrings);
              if changeinit then
               exclude(initlocalswitches,cs_ansistrings);
            end;
           { enum packing }
           if (m_tp7 in aktmodeswitches) then
            aktpackenum:=1
           else
            aktpackenum:=4;
           if changeinit then
            initpackenum:=aktpackenum;
         end;

        SetCompileMode:=b;
      end;

    { '('D1:'00000000-'D2:'0000-'D3:'0000-'D4:'0000-000000000000)' }
    function string2guid(const s: string; var GUID: TGUID): boolean;
        function ishexstr(const hs: string): boolean;
          var
            i: integer;
          begin
            ishexstr:=false;
            for i:=1 to Length(hs) do begin
              if not (hs[i] in ['0'..'9','A'..'F','a'..'f']) then
                exit;
            end;
            ishexstr:=true;
          end;
        function hexstr2longint(const hexs: string): longint;
          var
            i: integer;
            rl: longint;
          begin
            rl:=0;
            for i:=1 to length(hexs) do begin
              rl:=rl shl 4;
              case hexs[i] of
                '0'..'9' : inc(rl,ord(hexs[i])-ord('0'));
                'A'..'F' : inc(rl,ord(hexs[i])-ord('A')+10);
                'a'..'f' : inc(rl,ord(hexs[i])-ord('a')+10);
              end
            end;
            hexstr2longint:=rl;
          end;
      var
        i: integer;
      begin
        if (Length(s)=38) and (s[1]='{') and (s[38]='}') and
           (s[10]='-') and (s[15]='-') and (s[20]='-') and (s[25]='-') and
           ishexstr(copy(s,2,8)) and ishexstr(copy(s,11,4)) and
           ishexstr(copy(s,16,4)) and ishexstr(copy(s,21,4)) and
           ishexstr(copy(s,26,12)) then begin
          GUID.D1:=dword(hexstr2longint(copy(s,2,8)));
          GUID.D2:=hexstr2longint(copy(s,11,4));
          GUID.D3:=hexstr2longint(copy(s,16,4));
          for i:=0 to 1 do
            GUID.D4[i]:=hexstr2longint(copy(s,21+i*2,2));
          for i:=2 to 7 do
            GUID.D4[i]:=hexstr2longint(copy(s,22+i*2,2));
          string2guid:=true;
        end
        else
          string2guid:=false;
      end;

    function guid2string(const GUID: TGUID): string;
        function long2hex(l, len: longint): string;
          const
            hextbl: array[0..15] of char = '0123456789ABCDEF';
          var
            rs: string;
            i: integer;
          begin
            rs[0]:=chr(len);
            for i:=len downto 1 do begin
              rs[i]:=hextbl[l and $F];
              l:=l shr 4;
            end;
            long2hex:=rs;
          end;
      begin
        guid2string:=
          '{'+long2hex(GUID.D1,8)+
          '-'+long2hex(GUID.D2,4)+
          '-'+long2hex(GUID.D3,4)+
          '-'+long2hex(GUID.D4[0],2)+long2hex(GUID.D4[1],2)+
          '-'+long2hex(GUID.D4[2],2)+long2hex(GUID.D4[3],2)+
              long2hex(GUID.D4[4],2)+long2hex(GUID.D4[5],2)+
              long2hex(GUID.D4[6],2)+long2hex(GUID.D4[7],2)+
          '}';
      end;



{****************************************************************************
                                    Init
****************************************************************************}

{$ifdef unix}
  {$define need_path_search}
{$endif unix}
{$ifdef os2}
  {$define need_path_search}
{$endif os2}

   procedure get_exepath;
     var
       hs1 : namestr;
       hs2 : extstr;
     begin
{$ifdef delphi}
       exepath:=dmisc.getenv('PPC_EXEC_PATH');
{$else delphi}
       exepath:=dos.getenv('PPC_EXEC_PATH');
{$endif delphi}
       if exepath='' then
        fsplit(FixFileName(system.paramstr(0)),exepath,hs1,hs2);
{$ifdef need_path_search}
       if exepath='' then
        begin
          if pos(source_info.exeext,hs1) <>
               (length(hs1) - length(source_info.exeext)+1) then
            hs1 := hs1 + source_info.exeext;
      {$ifdef delphi}
          findfile(hs1,dmisc.getenv('PATH'),exepath);
      {$else delphi}
          findfile(hs1,dos.getenv('PATH'),exepath);
      {$endif delphi}
          exepath:=SplitPath(exepath);
        end;
{$endif need_path_search}
       exepath:=FixPath(exepath,false);
     end;



   procedure DoneGlobals;
     begin
       initdefines.free;
       if assigned(DLLImageBase) then
         StringDispose(DLLImageBase);
       RelocSection:=true;
       RelocSectionSetExplicitly:=false;
       UseDeffileForExport:=true;
       librarysearchpath.Free;
       unitsearchpath.Free;
       objectsearchpath.Free;
       includesearchpath.Free;
     end;

   procedure InitGlobals;
     begin
      { set global switches }
        do_build:=false;
        do_release:=false;
        do_make:=true;
        compile_level:=0;
        { these two should not be cleared in
          DoneGlobals as the IDE might need their value }
        IsExe:=false;
        DLLsource:=false;

      { Output }
        OutputFile:='';
        OutputExeDir:='';
        OutputUnitDir:='';

      { Utils directory }
        utilsdirectory:='';

      { Search Paths }
        librarysearchpath:=TSearchPathList.Create;
        unitsearchpath:=TSearchPathList.Create;
        includesearchpath:=TSearchPathList.Create;
        objectsearchpath:=TSearchPathList.Create;

      { Def file }
        usewindowapi:=false;
        description:='Compiled by FPC '+version_string+' - '+target_cpu_string;
        dllversion:='';
        nwscreenname := '';
        nwthreadname := '';
        nwcopyright  := '';

      { Init values }
        initmodeswitches:=fpcmodeswitches;
        initlocalswitches:=[cs_check_io];
        initmoduleswitches:=[cs_extsyntax,cs_browser];
        initglobalswitches:=[cs_check_unit_name,cs_link_static];
        initoutputformat:=as_none;
{$ifdef i386}
        initoptprocessor:=Class386;
        initspecificoptprocessor:=Class386;
        initpackenum:=4;
        {$IFDEF testvarsets}
        initsetalloc:=0;
        {$ENDIF}
        initpackrecords:=packrecord_2;
        initasmmode:=asmmode_i386_att;
{$else not i386}
  {$ifdef m68k}
        initoptprocessor:=MC68000;
        include(initmoduleswitches,cs_fp_emulation);
        initpackenum:=4;
        {$IFDEF testvarsets}
         initsetalloc:=0;
        {$ENDIF}
        initpackrecords:=packrecord_2;
        initoutputformat:=as_m68k_as;
        initasmmode:=asmmode_m68k_mot;
  {$endif m68k}
{$endif i386}
        initinterfacetype:=it_interfacecom;
        initdefines:=TStringList.Create;

      { memory sizes, will be overriden by parameter or default for target
        in options or init_parser }
        stacksize:=0;
        heapsize:=0;
        maxheapsize:=0;

      { compile state }
        in_args:=false;
        { must_be_valid:=true; obsolete PM }
        not_unit_proc:=true;

        apptype:=app_cui;
     end;

begin
  get_exepath;
{$ifdef EXTDEBUG}
  {$ifdef FPC}
    EntryMemUsed:=system.HeapSize-MemAvail;
  {$endif FPC}
{$endif}
end.
{
  $Log$
  Revision 1.38  2001-06-18 20:36:24  peter
    * -Ur switch (merged)
    * masm fixes (merged)
    * quoted filenames for go32v2 and win32

  Revision 1.37  2001/06/03 21:57:35  peter
    + hint directive parsing support

  Revision 1.36  2001/06/03 20:21:08  peter
    * Kylix fixes, mostly case names of units

  Revision 1.35  2001/05/30 21:35:48  peter
    * netware patches for copyright, screenname, threadname directives

  Revision 1.34  2001/05/12 12:11:31  peter
    * simplify_ppu is now the default, a recompile of the compiler now
      only compiles pp.pas

  Revision 1.33  2001/05/06 14:49:17  peter
    * ppu object to class rewrite
    * move ppu read and write stuff to fppu

  Revision 1.32  2001/04/18 22:01:53  peter
    * registration of targets and assemblers

  Revision 1.31  2001/04/15 09:48:29  peter
    * fixed crash in labelnode
    * easier detection of goto and label in try blocks

  Revision 1.30  2001/04/13 01:22:07  peter
    * symtable change to classes
    * range check generation and errors fixed, make cycle DEBUG=1 works
    * memory leaks fixed

  Revision 1.29  2001/04/04 21:30:42  florian
    * applied several fixes to get the DD8 Delphi Unit compiled
     e.g. "forward"-interfaces are working now

  Revision 1.28  2001/02/20 21:41:16  peter
    * new fixfilename, findfile for unix. Look first for lowercase, then
      NormalCase and last for UPPERCASE names.

  Revision 1.27  2001/02/09 23:05:45  peter
    * default packenum=1 for tp7 mode

  Revision 1.26  2001/02/05 20:47:00  peter
    * support linux unit for ver1_0 compilers

  Revision 1.25  2001/01/21 20:32:45  marco
   * Renamefest. Compiler part. Not that hard.

  Revision 1.24  2001/01/20 18:32:52  hajny
    + APPTYPE support under OS/2, app_fs, GetEnvPChar for OS/2

  Revision 1.23  2001/01/13 00:03:41  peter
    * fixed findexe to also support already extension in name

  Revision 1.22  2000/12/26 15:57:25  peter
    * use system.paramstr()

  Revision 1.21  2000/12/25 00:07:26  peter
    + new tlinkedlist class (merge of old tstringqueue,tcontainer and
      tlinkedlist objects)

  Revision 1.20  2000/11/13 15:26:12  marco
   * Renamefest

  Revision 1.19  2000/11/12 22:20:37  peter
    * create generic toutputsection for binary writers

  Revision 1.18  2000/11/04 14:25:19  florian
    + merged Attila's changes for interfaces, not tested yet

  Revision 1.17  2000/10/31 22:02:46  peter
    * symtable splitted, no real code changes

  Revision 1.16  2000/10/04 14:51:08  pierre
   * IsExe restored

  Revision 1.15  2000/09/27 21:20:56  peter
    * also set initlocalswitches in setcompilemode (merged)

  Revision 1.14  2000/09/26 10:50:41  jonas
    * initmodeswitches is changed is you change the compiler mode from the
      command line (the -S<x> switches didn't work anymore for changing the
      compiler mode) (merged from fixes branch)

  Revision 1.13  2000/09/24 21:33:46  peter
    * message updates merges

  Revision 1.12  2000/09/24 21:19:50  peter
    * delphi compile fixes

  Revision 1.11  2000/09/24 15:12:40  peter
    * fixed typo

  Revision 1.10  2000/09/24 15:06:16  peter
    * use defines.inc

  Revision 1.9  2000/09/24 10:33:07  peter
    * searching of exe in path also for OS/2
    * fixed searching of exe in path.

  Revision 1.8  2000/09/11 17:00:22  florian
    + first implementation of Netware Module support, thanks to
      Armin Diehl (diehl@nordrhein.de) for providing the patches

  Revision 1.7  2000/08/27 16:11:51  peter
    * moved some util functions from globals,cobjects to cutils
    * splitted files into finput,fmodule

  Revision 1.6  2000/08/12 19:14:58  peter
    * ELF writer works now also with -g
    * ELF writer is default again for linux

  Revision 1.5  2000/08/12 15:30:44  peter
    * IDE patch for stream reading (merged)

  Revision 1.4  2000/08/02 19:49:59  peter
    * first things for default parameters

  Revision 1.3  2000/07/13 12:08:25  michael
  + patched to 1.1.0 with former 1.09patch from peter

  Revision 1.2  2000/07/13 11:32:41  michael
  + removed logs

}
