{$mode objfpc}
{$h+}
unit pkgglobals;

interface

uses
  SysUtils,
  Classes;

Const
{$ifdef unix}
  ExeExt = '';
  AllFiles='*';
{$else unix}
  ExeExt = '.exe';
  AllFiles='*.*';
{$endif unix}

Type
  TVerbosity = (vError,vWarning,vInfo,vCommands,vDebug);
  TVerbosities = Set of TVerbosity;

  EPackagerError = class(Exception);

// Logging
Function StringToVerbosity (S : String) : TVerbosity;
Function VerbosityToString (V : TVerbosity): String;
Procedure Log(Level: TVerbosity;Msg : String);
Procedure Log(Level: TVerbosity;Fmt : String; const Args : array of const);
Procedure Error(Msg : String);
Procedure Error(Fmt : String; const Args : array of const);

// Utils
function maybequoted(const s:string):string;
Function FixPath(const S : String) : string;
Procedure DeleteDir(const ADir:string);
Procedure SearchFiles(SL:TStringList;const APattern:string);
Function GetCompilerInfo(const ACompiler,AOptions:string):string;

var
  Verbosity : TVerbosities;


Implementation

// define use_shell to use sysutils.executeprocess
//  as alternate to using 'process' in getcompilerinfo
{$IFDEF GO32v2}
 {$DEFINE USE_SHELL}
{$ENDIF GO32v2}

{$IFDEF WATCOM}
 {$DEFINE USE_SHELL}
{$ENDIF WATCOM}

{$IFDEF OS2}
 {$DEFINE USE_SHELL}
{$ENDIF OS2}

uses
  typinfo,
{$IFNDEF USE_SHELL}
  process,
{$ENDIF USE_SHELL}
  contnrs,
  uriparser,
  pkgmessages;

function StringToVerbosity(S: String): TVerbosity;
Var
  I : integer;
begin
  I:=GetEnumValue(TypeInfo(TVerbosity),'v'+S);
  If (I<>-1) then
    Result:=TVerbosity(I)
  else
    Raise EPackagerError.CreateFmt(SErrInvalidVerbosity,[S]);
end;

Function VerbosityToString (V : TVerbosity): String;
begin
  Result:=GetEnumName(TypeInfo(TVerbosity),Integer(V));
  Delete(Result,1,1);// Delete 'v'
end;


procedure Log(Level:TVerbosity;Msg: String);
var
  Prefix : string;
begin
  if not(Level in Verbosity) then
    exit;
  Prefix:='';
  if Level=vWarning then
    Prefix:=SWarning;
  Writeln(stdErr,Prefix,Msg);
end;


Procedure Log(Level:TVerbosity; Fmt:String; const Args:array of const);
begin
  Log(Level,Format(Fmt,Args));
end;


procedure Error(Msg: String);
begin
  Raise EPackagerError.Create(Msg);
end;


procedure Error(Fmt: String; const Args: array of const);
begin
  Raise EPackagerError.CreateFmt(Fmt,Args);
end;


function maybequoted(const s:string):string;
const
  {$IFDEF MSWINDOWS}
    FORBIDDEN_CHARS = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')',
                       '{', '}', '''', '`', '~'];
  {$ELSE}
    FORBIDDEN_CHARS = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')',
                       '{', '}', '''', ':', '\', '`', '~'];
  {$ENDIF}
var
  s1 : string;
  i  : integer;
  quoted : boolean;
begin
  quoted:=false;
  s1:='"';
  for i:=1 to length(s) do
   begin
     case s[i] of
       '"' :
         begin
           quoted:=true;
           s1:=s1+'\"';
         end;
       ' ',
       #128..#255 :
         begin
           quoted:=true;
           s1:=s1+s[i];
         end;
       else begin
         if s[i] in FORBIDDEN_CHARS then
           quoted:=True;
         s1:=s1+s[i];
       end;
     end;
   end;
  if quoted then
    maybequoted:=s1+'"'
  else
    maybequoted:=s;
end;


Function FixPath(const S : String) : string;
begin
  If (S<>'') then
    Result:=IncludeTrailingPathDelimiter(S)
  else
    Result:='';
end;


Procedure DeleteDir(const ADir:string);
var
  Info : TSearchRec;
begin
  if FindFirst(ADir+PathDelim+AllFiles,faAnyFile, Info)=0 then
    try
      repeat
        if (Info.Attr and faDirectory)=faDirectory then
          begin
            if (Info.Name<>'.') and (Info.Name<>'..') then
              DeleteDir(ADir+PathDelim+Info.Name)
          end
        else
          DeleteFile(ADir+PathDelim+Info.Name);
      until FindNext(Info)<>0;
    finally
      FindClose(Info);
    end;
end;


Procedure SearchFiles(SL:TStringList;const APattern:string);
var
  Info : TSearchRec;
  ADir : string;
begin
  ADir:=ExtractFilePath(APattern);
  if FindFirst(APattern,faAnyFile, Info)=0 then
    try
      repeat
        if (Info.Attr and faDirectory)=faDirectory then
          begin
            if (Info.Name<>'.') and (Info.Name<>'..') then
              SearchFiles(SL,ADir+Info.Name+PathDelim+ExtractFileName(APattern))
          end;
        SL.Add(ADir+Info.Name);
      until FindNext(Info)<>0;
    finally
      FindClose(Info);
    end;
end;


//
// if use_shell defined uses sysutils.executeprocess else uses 'process'
//
function GetCompilerInfo(const ACompiler,AOptions:string):string;
const
  BufSize = 1024;
var
{$IFDEF USE_SHELL}
  TmpFileName, ProcIDStr: shortstring;
  TmpFile: file;
  CmdLine2: string;
{$ELSE USE_SHELL}
  S: TProcess;
{$ENDIF USE_SHELL}
  Buf: array [0..BufSize - 1] of char;
  Count: longint;
begin
{$IFDEF USE_SHELL}
  Str (GetProcessID, ProcIDStr);
  TmpFileName := GetEnvironmentVariable ('TEMP');
  if TmpFileName <> '' then
   TmpFileName := TmpFileName + DirectorySeparator + 'fppkgout.' + ProcIDStr
  else
   TmpfileName := 'fppkgout.' + ProcIDStr;
  CmdLine2 := '/C ' + ACompiler + ' ' + AOptions + ' > ' + TmpFileName;
  SysUtils.ExecuteProcess (GetEnvironmentVariable ('COMSPEC'), CmdLine2);
  Assign (TmpFile, TmpFileName);
  Reset (TmpFile, 1);
  BlockRead (TmpFile, Buf, BufSize, Count);
  Close (TmpFile);
{$ELSE USE_SHELL}
  S:=TProcess.Create(Nil);
  S.Commandline:=ACompiler+' '+AOptions;
  S.Options:=[poUsePipes];
  S.execute;
  Count:=s.output.read(buf,BufSize);
  S.Free;
{$ENDIF USE_SHELL}
  SetLength(Result,Count);
  Move(Buf,Result[1],Count);
end;

end.
