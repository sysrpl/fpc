{$mode objfpc}
{$H+}
{
    $Id$
    This file is part of Free Pascal Build tools
    Copyright (c) 2005 by Michael Van Canneyt

    Create a configuration file

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
program fpcmkcfg;

uses usubst,SysUtils,Classes;

{
  The fpccfg.inc file must be built from a template with the bin2obj
  command.  it needs options:
  bin2obj -a -o fpccfg.inc -c DefaultConfig fpc.cft
  where fpc.cft is the template file.
}

{$i fpccfg.inc}

Const
  BuildVersion={$I %FPCVERSION%};
  BuildTarget={$I %FPCTARGET%};


Resourcestring
  SUsage00 = 'Usage: %s [options]';
  SUsage10 = 'Where options is one or more of';
  SUSage20 = '  -t filename   Template file name. Default is built-in';
  SUSage30 = '  -o filename   Set output file. Default is standard output.';
  SUsage40 = '  -d name=value define name=value pair.';
  SUsage50 = '  -h            show this help and exit.';
  SUsage60 = '  -u name       remove name from list of name/value pairs.';
  SUsage70 = '  -l filename   read name/value pairs from filename';
  SUsage80 = '  -b            show builtin template and exit.';
  SUsage90 = '  -v            be verbose.';
  SErrUnknownOption   = 'Error: Unknown option.';
  SErrArgExpected     = 'Error: Option "%s" requires an argument.';
  SErrNoSuchFile      = 'Error: File "%s" does not exist.';
  SErrBackupFailed    = 'Error: Backup of file "%s" to "%s" failed.';
  SErrDelBackupFailed = 'Error: Delete of old backup file "%s" failed.';
  SWarnIgnoringFile   = 'Warning: Ignoring non-existent file: ';
  SWarnIgnoringPair   = 'Warning: ignoring wrong name/value pair: ';
  SStats              = 'Replaced %d placeholders in %d lines.';
  SSubstInLine        = 'Replaced %s placeholders in line %d.';


Var
  Verbose : Boolean;
  SkipBackup : Boolean;
  List,Cfg : TStringList;
  TemplateFileName,
  OutputFileName : String;




procedure Init;

begin
  Verbose:=False;
  List:=TStringList.Create;
  AddToList(List,'FPCVERSION',BuildVersion);
  AddToList(List,'FPCTARGET',BuildTarget);
  AddToList(List,'PWD',GetCurrentDir);
  AddToList(List,'BUILDDATE',DateToStr(Date));
  AddToList(List,'BUILDTIME',TimeToStr(Time));
  Cfg:=TStringList.Create;
  Cfg.Text:=StrPas(Addr(DefaultConfig));
end;

Procedure Done;

begin
  FreeAndNil(List);
  FreeAndNil(Cfg);
end;

Procedure Usage;

begin
  Writeln(Format(SUsage00,[ExtractFileName(Paramstr(0))]));
  Writeln(SUsage10);
  Writeln(SUsage20);
  Writeln(SUsage30);
  Writeln(SUsage40);
  Writeln(SUsage50);
  Writeln(SUsage60);
  Writeln(SUsage70);
  Writeln(SUsage80);
  Writeln(SUsage90);
  Halt(1);
end;

Procedure UnknownOption(Const S : String);

begin
  Writeln(SErrUnknownOption,S);
  Usage;
end;

Procedure ShowBuiltIn;

Var
  I : Integer;


begin
  For I:=0 to Cfg.Count-1 do
    Writeln(Cfg[I]);
end;


Procedure ProcessCommandline;

Var
  I : Integer;
  S : String;

  Function GetOptArg : String;

  begin
    If I=ParamCount then
      begin
      Writeln(StdErr,Format(SErrArgExpected,[S]));
      Halt(1);
      end;
    inc(I);
    Result:=ParamStr(I);
  end;

begin
  I:=1;
  While( I<=ParamCount) do
    begin
    S:=Paramstr(i);
    If Length(S)<=1 then
      UnknownOption(S)
    else
      case S[2] of
        'v' : Verbose:=True;
        'h' : Usage;
        'b' : begin
              ShowBuiltin;
              halt(0);
              end;
        't' : TemplateFileName:=GetOptArg;
        'd' : AddPair(List,GetOptArg);
        'u' : AddPair(List,GetOptArg+'=');
        'o' : OutputFileName:=GetoptArg;
        's' : SkipBackup:=True;
      else
        UnknownOption(S);
      end;
    Inc(I);
    end;
  If (TemplateFileName<>'') then
    begin
    If Not FileExists(TemplateFileName) then
      begin
      Writeln(StdErr,Format(SErrNoSuchFile,[TemplateFileName]));
      Halt(1);
      end;
    Cfg.LoadFromFile(TemplateFileName);
    AddToList(List,'TEMPLATEFILE',TemplateFileName);
    end
  else
    AddToList(List,'TEMPLATEFILE','builtin');
end;


Procedure CreateFile;

Var
  Fout : Text;
  S,BFN : String;
  I,RCount : INteger;

begin
  If (OutputFileName<>'')
     and FileExists(OutputFileName)
     and not SkipBackup then
    begin
    BFN:=ChangeFileExt(OutputFileName,'.bak');
    If FileExists(BFN) and not DeleteFile(BFN) then
      begin
      Writeln(StdErr,Format(SErrDelBackupFailed,[BFN]));
      Halt(1);
      end;
    If not RenameFile(OutputFileName,BFN) then
      begin
      Writeln(StdErr,Format(SErrBackupFailed,[OutputFileName,BFN]));
      Halt(1);
      end;
    end;
  Assign(Fout,OutputFileName);
  Rewrite(FOut);
  Try
    RCount:=0;
    For I:=0 to Cfg.Count-1 do
      begin
      S:=Cfg[i];
      Inc(RCount,DoSubstitutions(List,S));
      Writeln(FOut,S);
      end;
    If Verbose then
      Writeln(StdErr,Format(SStats,[RCount,Cfg.Count]));
  Finally
    Close(Fout);
  end;
end;

begin
  Init;
  Try
    ProcessCommandLine;
    CreateFile;
  Finally
    Done;
  end;
end.
{
  $Log$
  Revision 1.3  2005-03-25 21:21:30  jonas
    * fixeed uninitialised variable
    - removed unused local variables

  Revision 1.2  2005/02/14 17:13:10  peter
    * truncate log

  Revision 1.1  2005/02/05 10:25:30  peter
    * move tools to compiler/utils/

  Revision 1.1  2005/01/09 13:36:12  michael
  + Initial implementation of installer tools

}

