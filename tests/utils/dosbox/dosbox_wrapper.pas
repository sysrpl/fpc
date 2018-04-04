{$MODE objfpc}{$H+}

uses
  SysUtils, StrUtils,
{$ifdef UseSignals}
  signals,
{$endif def UseSignals}
  testu, classes,
  Process;

const
  use_temp_dir : boolean = true;
  need_cwsdpmi : boolean = false;
  cwsdpmi_file : string = '';
  hide_execution : boolean = true;
  do_exit : boolean = true;
  verbose : boolean = false;
  DosBoxProcess: TProcess = nil;
  dosbox_timeout : integer = 400;  { default timeout in seconds }
var
  OutputFileName : String;
  SourceFileName : String;
  StartDir, DosBoxDir: string;
  ExitCode: Integer = 255;
  DosBoxBinaryPath: string;
  TmpFileList : TStringList;

function GenerateTempDir: string;
var
  FileName: string;
  TempDir: string;
  Done: Boolean = False;
begin
  TempDir := GetTempDir(False);
  repeat
    try
      FileName := TempDir + 'dosboxwrappertmp_' + IntToStr(Random(100000));
      if verbose then
        writeln('Trying to create directory ',Filename);
      MkDir(FileName);
      Done := True;
    except
      on E: EInOutError do
      begin
        { 5 = Access Denied, returned when a file is duplicated }
        if E.ErrorCode <> 5 then
          begin
            Writeln('Directory creation failed');
            raise;
          end;
      end;
    end;
  until Done;
  Result := FileName + DirectorySeparator;
end;

procedure GenerateDosBoxConf(const ADosBoxDir: string);
var
  SourceConfFileName, TargetConfFileName: string;
  SourceFile, TargetFile: TextFile;
  OrigS, S: string;
begin
  SourceConfFileName := ExtractFilePath(ParamStr(0)) + 'dosbox.conf';
  TargetConfFileName := ADosBoxDir + 'dosbox.conf';
  OutputFileName := ADosBoxDir + 'dosbox.out';
  if verbose then
    Writeln('Using target dosbox.conf ',TargetConfFileName);
  AssignFile(SourceFile, SourceConfFileName);
  AssignFile(TargetFile, TargetConfFileName);
  Reset(SourceFile);
  try
    Rewrite(TargetFile);
    try
      while not EoF(SourceFile) do
      begin
        Readln(SourceFile, S);
        OrigS:=S;
        S := AnsiReplaceStr(S, '$DosBoxDir', ADosBoxDir);
        S := AnsiReplaceStr(S, '$wrapper_output', OutputFileName);
        if do_exit then
          S := AnsiReplaceStr(S, '$exit', 'exit')
        else
          S := AnsiReplaceStr(S, '$exit', '');
        If verbose and (OrigS <> S) then
          Writeln('"',OrigS,'" transformed into "',S,'"');
        Writeln(TargetFile, S);
      end;
    finally
      CloseFile(TargetFile);
    end;
  finally
    CloseFile(SourceFile);
  end;
end;

procedure CopyFile(ASrcFileName, ADestFileName: string);
var
  SrcF, DestF: File;
  OldFileMode: Integer;
  Buf: array [0..4095] of Byte;
  BytesRead: Integer;
begin
  if not AnsiEndsText('.exe', ASrcFileName) and AnsiEndsText('.exe',ADestFileName) then
    ASrcFileName := ASrcFileName + '.exe';
  if verbose then
    Writeln('CopyFile ', ASrcFileName, '->', ADestFileName);
  OldFileMode := FileMode;
  try
    AssignFile(SrcF, ASrcFileName);
    AssignFile(DestF, ADestFileName);
    FileMode := fmOpenRead;
    Reset(SrcF, 1);
    try
      FileMode := fmOpenWrite;
      try
        Rewrite(DestF, 1);
        repeat
          BlockRead(SrcF, Buf, SizeOf(Buf), BytesRead);
          BlockWrite(DestF, Buf, BytesRead);
        until BytesRead < SizeOf(Buf);
      finally
        CloseFile(DestF);
      end;
    finally
      CloseFile(SrcF);
    end;
  finally
    FileMode := OldFileMode;
  end;
end;

function ForceExtension(Const HStr,ext:String):String;
{
  Return a filename which certainly has the extension ext
}
var
  j : longint;
begin
  j:=length(Hstr);
  while (j>0) and (Hstr[j]<>'.') do
    dec(j);
  if j=0 then
    j:=length(Hstr)+1;
  if Ext<>'' then
   begin
     if Ext[1]='.' then
       ForceExtension:=Copy(Hstr,1,j-1)+Ext
     else
       ForceExtension:=Copy(Hstr,1,j-1)+'.'+Ext
   end
  else
   ForceExtension:=Copy(Hstr,1,j-1);
end;

procedure CopyNeededFiles;
var
  Config : TConfig;
  LocalFile, RemoteFile, s: string;
  LocalPath: string;
  i       : integer;
  FileList   : TStringList;
  RelativeToConfigMarker : TObject;

  function SplitPath(const s:string):string;
  var
    i : longint;
  begin
    i:=Length(s);
    while (i>0) and not(s[i] in ['/','\'{$IFDEF MACOS},':'{$ENDIF}]) do
     dec(i);
    SplitPath:=Copy(s,1,i);
  end;

  function BuildFileList: TStringList;
    var
      s      : string;
      index  : longint;
    begin
      s:=Config.Files;
      if (length(s) = 0) and (Config.ConfigFileSrc='') then
        begin
          Result:=nil;
          exit;
        end;
      Result:=TStringList.Create;
      if s<>'' then
        repeat
          index:=pos(' ',s);
          if index=0 then
            LocalFile:=s
          else
            LocalFile:=copy(s,1,index-1);
          Result.Add(LocalFile);
          if index=0 then
            break;
          s:=copy(s,index+1,length(s)-index);
        until false;
      if Config.ConfigFileSrc<>'' then
        begin
          if Config.ConfigFileSrc=Config.ConfigFileDst then
            Result.AddObject(Config.ConfigFileSrc,RelativeToConfigMarker)
          else
            Result.AddObject(Config.ConfigFileSrc+'='+Config.ConfigFileDst,RelativeToConfigMarker);
        end;
    end;

var
  ddir : string;
begin
  if not IsAbsolute(SourceFileName) and not FileExists(SourceFileName) then
    begin
      ddir:=GetEnvironmentVariable('BASEDIR');
      if ddir='' then
        GetDir(0,ddir);
      writeln('Start ddir=',ddir);
      while (ddir<>'') do
        begin
          if FileExists(ddir+DirectorySeparator+SourceFileName) then
            begin
              SourceFileName:=ddir+DirectorySeparator+SourceFileName;
              break;
            end
          else
            begin
              if ddir=splitpath(ddir) then
                break
              else
                ddir:=splitpath(ddir);
              if ddir[length(ddir)]=DirectorySeparator then
                ddir:=copy(ddir,1,length(ddir)-1);
              writeln('Next ddir=',ddir);
            end;
        end;
     end;
  if not FileExists(SourceFileName) then
    begin
      writeln('File ',SourceFileName,' not found');
      exit;
    end;
  if not GetConfig(SourceFileName,config) then
    exit;

  RelativeToConfigMarker:=TObject.Create;
  FileList:=BuildFileList;
  TmpFileList:=TStringList.Create;
  if assigned(FileList) then
    begin
      LocalPath:=SplitPath(SourceFileName);
      if (Length(LocalPath) > 0) and (LocalPath[Length(LocalPath)]<>DirectorySeparator) then
        LocalPath:=LocalPath+DirectorySeparator;
      for i:=0 to FileList.count-1 do
        begin
          if FileList.Names[i]<>'' then
            begin
              LocalFile:=FileList.Names[i];
              RemoteFile:=FileList.ValueFromIndex[i];
            end
          else
            begin
              LocalFile:=FileList[i];
              RemoteFile:=LocalFile;
            end;
          if FileList.Objects[i]=RelativeToConfigMarker then
            s:='config/'+LocalFile
          else
            s:=LocalPath+LocalFile;
          CopyFile(s,DosBoxDir+DirectorySeparator+RemoteFile);
          TmpFileList.Add(RemoteFile);
        end;
      FileList.Free;
    end;
  RelativeToConfigMarker.Free;
end;

{ On modified dosbox executable it is possible to get
  a copy of all output to CON into a file, simply write it
  back to output, so it ends up into testname.elg file.
  Skip all until line beginning with 'Drive C is mounted as' }
procedure EchoOutput;
const
  SkipUntilText = 'Drive C is mounted as ';
var
  StdText : TextFile;
  st : string;
  line : longint;
  SkipUntilSeen : boolean;
begin
  if FileExists(OutputFileName) then
    begin
      if verbose then
        Writeln('Trying to open ',OutputFileName);
      try
        AssignFile(StdText, OutputFileName);
        Reset(StdText);
        if verbose then
          Writeln('Successfully opened ',OutputFileName,', copying content to output');
        try
          line:=0;
          SkipUntilSeen:=false;
          while not eof(StdText) do
            begin
              Readln(StdText,st);
              inc(line);
	      if not SkipUntilSeen then
                SkipUntilSeen:=pos(SkipUntilText,st)>0;
              if SkipUntilSeen then
                Writeln(line,': ',st);
            end;
        finally
	  if not SkipUntilSeen then
            Writeln('Could not find "',SkipUntilText,'" in file ',OutputFilename);
          Flush(output);
          CloseFile(StdText);
        end;
      finally
        if use_temp_dir then
          DeleteFile(OutputFileName);
      end;
    end;
end;

function ReadExitCode(const ADosBoxDir: string): Integer;
var
  F: TextFile;
begin
  AssignFile(F, ADosBoxDir + 'EXITCODE.TXT');
  try
    Reset(F);
    Readln(F, Result);
    if Result <> 0 then
      Writeln('ExitCode=',Result);
    CloseFile(F);
  except
    Writeln('Unable to read exitcode value');
    ReadExitCode:=127*256;
  end;
end;

procedure ExecuteDosBox(const ADosBoxBinaryPath, ADosBoxDir: string);
var
  Time: Integer = 0;
begin
  DosBoxProcess := TProcess.Create(nil);
  try
    DosBoxProcess.Executable := ADosBoxBinaryPath;
    DosBoxProcess.Parameters.Add('-conf');
    DosBoxProcess.Parameters.Add(ADosBoxDir + 'dosbox.conf');
    if hide_execution then
      DosBoxProcess.ShowWindow := swoHIDE;
    DosBoxProcess.Execute;
    repeat
      Inc(Time);
      if (Time > 10*dosbox_timeout) and do_exit then
        break;
      Sleep(100);
    until not DosBoxProcess.Running;
    if DosBoxProcess.Running then
    begin
      Writeln('Timeout exceeded. Killing dosbox...');
      DosBoxProcess.Terminate(254);
      Sleep(100);
    end;
  finally
    DosBoxProcess.Free;
    DosBoxProcess:=nil;
    EchoOutput;
  end;
end;


procedure DeleteIfExists(const AFileName: string);
begin
  if FileExists(AFileName) then
    DeleteFile(AFileName);
end;

procedure Cleanup(const ADosBoxDir: string);
var
   i : longint;
begin
  DeleteIfExists(ADosBoxDir + 'dosbox.conf');
  DeleteIfExists(ADosBoxDir + 'EXITCODE.TXT');
  DeleteIfExists(ADosBoxDir + 'EXITCODE.EXE');
  DeleteIfExists(ADosBoxDir + 'CWSDPMI.EXE');
  DeleteIfExists(ADosBoxDir + 'TEST.EXE');
  if Assigned(TmpFileList) then
    begin
      for i:=0 to TmpFileList.count-1 do
        if TmpFileList[i]<>'' then
          DeleteIfExists(ADosBoxDir + TmpFileList[i]);
    end;
  TmpFileList.Free;
  ChDir(StartDir);
  RmDir(ADosBoxDir);
end;


{$ifdef UseSignals}
const
  SignalCalled : boolean = false;
  SignalNb : longint = 0;

function DosBoxSignal(signal:longint):longint; cdecl;

begin
  SignalCalled:=true;
  SignalNb:=signal;
end;
{$endif def UseSignals}

procedure ExitProc;
var
  count : longint;
begin
  if assigned(DosBoxProcess) and (DosBoxProcess.Running) then
    begin
      Writeln('In ExitProc. Killing dosbox...');
      DosBoxProcess.Terminate(254*1024);
      Sleep(100);
      count:=1;
      while (DosBoxProcess.Running) do
        begin
          Sleep(100);
          inc(count);
          if (count mod 20=0) then
            DosBoxProcess.Terminate(254*1024+count);
        end;
      if count>1 then
        Writeln('In ExitProc. Wait for termination dosbox..., time=',count/10);
      EchoOutput;
    end;
end;

begin
  Randomize;


  if GetEnvironmentVariable('DOSBOX_NO_TEMPDIR')<>'' then
    begin
      use_temp_dir:=false;
      Writeln('use_temp_dir set to false');
    end;
  if GetEnvironmentVariable('DOSBOX_NO_HIDE')<>'' then
    begin
      hide_execution:=false;
      Writeln('hide_execution set to false');
    end;
  if GetEnvironmentVariable('DOSBOX_NO_EXIT')<>'' then
    begin
      do_exit:=false;
      Writeln('do_exit set to false');
    end;
  if GetEnvironmentVariable('DOSBOX_VERBOSE')<>'' then
    begin
      verbose:=true;
      Writeln('verbose set to true');
    end;
  if (GetEnvironmentVariable('DOSBOX_NEEDS_CWSDPMI')<>'') or
     (GetEnvironmentVariable('TEST_OS_TARGET')='go32v2') then
    begin
      need_cwsdpmi:=true;
      Writeln('need_cwsdpmi set to true');
    end;
  if GetEnvironmentVariable('DOSBOX_TIMEOUT')<>'' then
    begin
      dosbox_timeout:=StrToInt(GetEnvironmentVariable('DOSBOX_TIMEOUT'));
      Writeln('dosbox_timeout set to ', dosbox_timeout, ' seconds');
    end;
  if ParamCount = 0 then
  begin
    Writeln('Usage: ' + ParamStr(0) + ' <executable> (-Ssourcename)');
    Writeln('Set DOSBOX_NO_TEMPDIR env variable to 1 to avoid using a temporary directory');
    Writeln('Set DOSBOX_NO_HIDE to avoid running dosbox in an hidden window');
    Writeln('Set DOSBOX_NO_EXIT to avoid exiting dosbox after test has been run');
    Writeln('Set DOSBOX_TIMEOUT to set the timeout in seconds before killing the dosbox process, assuming the test has hanged');
    halt(1);
  end;
  DosBoxBinaryPath := GetEnvironmentVariable('DOSBOX');
  if DosBoxBinaryPath = '' then
  begin
    Writeln('Please set the DOSBOX environment variable to the dosbox executable');
    halt(1);
  end
  else
  begin
    Writeln('Using DOSBOX executable: ',DosBoxBinaryPath);
  end;

  { DosBoxDir is used inside dosbox.conf as a MOUNT parameter }
  if use_temp_dir then
    begin
      GetDir(0,StartDir);
      DosBoxDir := GenerateTempDir;
      { All executable test have t.*.pp pattern }
      if (paramcount>1) and (copy(paramstr(2),1,2)='-S') then
        SourceFileName:=copy(paramstr(2),3,length(paramstr(2)))
      else
        SourceFileName:=ForceExtension(Paramstr(1),'.pp');
      CopyNeededFiles;
    end
  else
    begin
      Writeln('Using ',ParamStr(1));
      DosBoxDir:=ExtractFilePath(ParamStr(1));
      if DosBoxDir='' then
        DosBoxDir:=GetCurrentDir+DirectorySeparator;
      Writeln('Using DosBoxDir=',DosBoxDir);
      { Get rid of previous exicode.txt file }
      DeleteIfExists(DosBoxDir + 'EXITCODE.TXT');
    end;
  try
{$ifdef UseSignals}
    Signal(SIGINT,@DosBoxSignal);
    Signal(SIGQUIT,@DosBoxSignal);
    Signal(SIGTERM,@DosBoxSignal);
{$endif def UseSignals}
    GenerateDosBoxConf(DosBoxDir);
    CopyFile(ExtractFilePath(ParamStr(0)) + 'exitcode.exe', DosBoxDir + 'EXITCODE.EXE');
    CopyFile(ParamStr(1), DosBoxDir + 'TEST.EXE');
    if need_cwsdpmi then
      begin
        cwsdpmi_file:=FileSearch('cwsdpmi.exe',GetEnvironmentVariable('PATH'));
        if cwsdpmi_file<>'' then
          CopyFile(cwsdpmi_file, DosBoxDir + 'CWSDPMI.EXE')
        else if verbose then
          writeln('cwsdpmi executable missing');
      end;
    ExecuteDosBox(DosBoxBinaryPath, DosBoxDir);
  finally
    ExitProc;
  end;
{$ifdef UseSignals}
  if SignalCalled then
    begin
      Writeln('Signal ',SignalNb,' called');
    end;
{$endif def UseSignals}
  ExitProc;
  ExitCode:=ReadExitCode(DosBoxDir);
  if use_temp_dir then
    Cleanup(DosBoxDir);
  halt(ExitCode);
end.
