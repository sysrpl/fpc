{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 1993,97 by Michael Van Canneyt,
    member of the Free Pascal development team.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{ These things are set in the makefile, }
{ But you can override them here.}

{ If you want to link to the C library, set the conditional crtlib }
{ $define crtlib}

{ If you use an aout system, set the conditional AOUT}
{ $Define AOUT}

Unit SysLinux;
Interface

{$ifdef m68k}
{ used for single computations }
const
  BIAS4 = $7f-1;
{$endif}

{$I systemh.inc}
{$I heaph.inc}

const
  UnusedHandle    = -1;
  StdInputHandle  = 0;
  StdOutputHandle = 1;
  StdErrorHandle  = 2;

var
  argc : longint;
  argv : ppchar;
  envp : ppchar;

Implementation

{$I system.inc}

{$ifdef crtlib}
  Procedure _rtl_exit(l: longint); cdecl;
  Function  _rtl_paramcount: longint; cdecl;
  Procedure _rtl_paramstr(st: pchar; l: longint); cdecl;
  Function  _rtl_open(f: pchar; flags: longint): longint; cdecl;
  Procedure _rtl_close(h: longint); cdecl;
  Procedure _rtl_write(h: longint; addr: longInt; len : longint); cdecl;
  Procedure _rtl_erase(p: pchar); cdecl;
  Procedure _rtl_rename(p1: pchar; p2 : pchar); cdecl;
  Function  _rtl_read(h: longInt; addr: longInt; len : longint) : longint; cdecl;
  Function  _rtl_filepos(Handle: longint): longint; cdecl;
  Procedure _rtl_seek(Handle: longint; pos:longint); cdecl;
  Function  _rtl_filesize(Handle:longint): longInt; cdecl;
  Procedure _rtl_rmdir(buffer: pchar); cdecl;
  Procedure _rtl_mkdir(buffer: pchar); cdecl;
  Procedure _rtl_chdir(buffer: pchar); cdecl;
{$else}
  { used in syscall to report errors.}
  var
    Errno : longint;

  { Include constant and type definitions }
  {$i errno.inc    }  { Error numbers                 }
  {$i sysnr.inc    }  { System call numbers           }
  {$i sysconst.inc }  { Miscellaneous constants       }
  {$i systypes.inc }  { Types needed for system calls }

  { Read actual system call definitions. }
  {$i syscalls.inc }
{$endif}

{*****************************************************************************
                       Misc. System Dependent Functions
*****************************************************************************}

{$ifdef i386}
  {$ASMMODE DIRECT}
{$endif}

Procedure Halt(ErrNum: Byte);
Begin
  ExitCode:=Errnum;
  Do_Exit;
{$ifdef i386}
  asm
        jmp     _haltproc
  end;
{$else}
  asm
        jmp     _haltproc
  end;
{$endif}
End;


Function ParamCount: Longint;
Begin
{$ifdef crtlib}
  ParamCount:=_rtl_paramcount;
{$else}
  Paramcount:=argc-1
{$endif}
End;


Function ParamStr(l: Longint): String;
Var
{$ifndef crtlib}
  i      : longint;
  pp     : ppchar;
{$else}
  b      : Array[0..255] of Char;
{$endif}
Begin
{$ifdef crtlib}
  _rtl_paramstr(@b, l);
  ParamStr:=StrPas(b);
{$else}
  if l>argc then
   begin
     paramstr:='';
     exit
   end;
  pp:=argv;
  i:=0;
  while (i<l) and (pp^<>nil) do
   begin
     inc(pp);
     inc(i);
   end;
  if pp^<>nil then
    Paramstr:=StrPas(pp^)
  else
    ParamStr:='';
{$endif}
End;


Procedure Randomize;
Begin
{$ifdef crtlib}
  _rtl_gettime(longint(@randseed));
{$else}
  randseed:=sys_time;
{$endif}
End;


{*****************************************************************************
                              Heap Management
*****************************************************************************}

function getheapstart:pointer;assembler;
{$ifdef i386}
asm
        leal    HEAP,%eax
end ['EAX'];
{$else}
asm
        lea.l   HEAP,a0
        move.l  a0,d0
end;
{$endif}


function getheapsize:longint;assembler;
{$ifdef i386}
asm
        movl    HEAPSIZE,%eax
end ['EAX'];
{$else}
asm
       move.l   HEAP_SIZE,d0
end ['D0'];
{$endif}


{ ___fpc_brk_addr is defined and allocated in prt1.as }

Function Get_Brk_addr : longint;assembler;
{$ifdef i386}
asm
        movl    ___fpc_brk_addr,%eax
end ['EAX'];
{$else}
asm
        move.l  ___fpc_brk_addr,d0
end ['D0'];
{$endif}


Procedure Set_brk_addr (NewAddr : longint);assembler;
{$ifdef i386}
asm
        movl    NewAddr,%eax
        movl    %eax,___fpc_brk_addr
end ['EAX'];
{$else}
asm
        move.l  NewAddr,d0
        move.l  d0,___fpc_brk_addr
end ['D0'];
{$endif}

{$ifdef i386}
  {$ASMMODE ATT}
{$endif}

Function brk(Location : longint) : Longint;
{ set end of data segment to location }
var
  t     : syscallregs;
  dummy : longint;
begin
  t.reg2:=Location;
  dummy:=syscall(syscall_nr_brk,t);
  set_brk_addr(dummy);
  brk:=dummy;
end;


Function init_brk : longint;
begin
  if Get_Brk_addr=0 then
   begin
     Set_brk_addr(brk(0));
     if Get_brk_addr=0 then
      exit(-1);
   end;
  init_brk:=0;
end;


Function sbrk(size : longint) : Longint;
var
  Temp  : longint;
begin
  if init_brk=0 then
   begin
     Temp:=Get_Brk_Addr+size;
     if brk(temp)=-1 then
      exit(-1);
     if Get_brk_addr=temp then
      exit(temp-size);
   end;
  exit(-1);
end;


{ include standard heap management }
{$I heap.inc}


{*****************************************************************************
                          Low Level File Routines
*****************************************************************************}

{
  The lowlevel file functions should take care of setting the InOutRes to the
  correct value if an error has occured, else leave it untouched
}

Procedure Errno2Inoutres;
{
  Convert ErrNo error to the correct Inoutres value
}

begin
  if ErrNo=0 then { Else it will go through all the cases }
   exit;
  case ErrNo of
   Sys_ENFILE,
   Sys_EMFILE : Inoutres:=4;
   Sys_ENOENT : Inoutres:=2;
    Sys_EBADF : Inoutres:=6;
   Sys_ENOMEM,
   Sys_EFAULT : Inoutres:=217;
   Sys_EINVAL : Inoutres:=218;
    Sys_EPIPE,
    Sys_EINTR,
      Sys_EIO,
   Sys_EAGAIN,
   Sys_ENOSPC : Inoutres:=101;
 Sys_ENAMETOOLONG,
    Sys_ELOOP,
  Sys_ENOTDIR : Inoutres:=3;
    Sys_EROFS,
   Sys_EEXIST,
   Sys_EACCES : Inoutres:=5;
  Sys_ETXTBSY : Inoutres:=162;
  end;
end;


Procedure Do_Close(Handle:Longint);
Begin
{$ifdef crtlib}
  _rtl_close(Handle);
{$else}
  sys_close(Handle);
{$endif}
End;


Procedure Do_Erase(p:pchar);
Begin
{$ifdef crtlib}
  _rtl_erase(p);
{$else}
  sys_unlink(p);
  Errno2Inoutres;
{$endif}
End;


Procedure Do_Rename(p1,p2:pchar);
Begin
{$ifdef crtlib}
  _rtl_rename(p1,p2);
{$else }
  sys_rename(p1,p2);
  Errno2Inoutres;
{$endif}
End;


Function Do_Write(Handle,Addr,Len:Longint):longint;
Begin
{$ifdef crtlib}
  _rtl_write(Handle,addr,len);
  Do_Write:=Len;
{$else}
  Do_Write:=sys_write(Handle,pchar(addr),len);
  Errno2Inoutres;
{$endif}
  if Do_Write<0 then
   Do_Write:=0;
End;


Function Do_Read(Handle,Addr,Len:Longint):Longint;
Begin
{$ifdef crtlib}
  Do_Read:=_rtl_read(Handle,addr,len);
{$else}
  Do_Read:=sys_read(Handle,pchar(addr),len);
  Errno2Inoutres;
{$endif}
  if Do_Read<0 then
   Do_Read:=0;
End;


Function Do_FilePos(Handle: Longint): Longint;
Begin
{$ifdef crtlib}
  Do_FilePos:=_rtl_filepos(Handle);
{$else}
  Do_FilePos:=sys_lseek(Handle, 0, Seek_Cur);
  Errno2Inoutres;
{$endif}
End;


Procedure Do_Seek(Handle,Pos:Longint);
Begin
{$ifdef crtlib}
  _rtl_seek(Handle, Pos);
{$else}
  sys_lseek(Handle, pos, Seek_set);
{$endif}
End;


Function Do_SeekEnd(Handle:Longint): Longint;
begin
{$ifdef crtlib}
  Do_SeekEnd:=_rtl_filesize(Handle);
{$else}
  Do_SeekEnd:=sys_lseek(Handle,0,Seek_End);
{$endif}
end;


Function Do_FileSize(Handle:Longint): Longint;
{$ifndef crtlib}
var
  regs : Syscallregs;
  Info : Stat;
{$endif}
Begin
{$ifdef crtlib}
  Do_FileSize:=_rtl_filesize(Handle);
{$else}
  regs.reg2:=Handle;
  regs.reg3:=longint(@Info);
  if SysCall(SysCall_nr_fstat,regs)=0 then
   Do_FileSize:=Info.Size
  else
   Do_FileSize:=0;
  Errno2Inoutres;
{$endif}
End;


Procedure Do_Truncate(Handle,Pos:longint);
{$ifndef crtlib}
var
  sr : syscallregs;
{$endif}
begin
{$ifndef crtlib}
  sr.reg2:=Handle;
  sr.reg3:=Pos;
  syscall(syscall_nr_ftruncate,sr);
  Errno2Inoutres;
{$endif}
end;


Procedure Do_Open(var f;p:pchar;flags:longint);
{
  FileRec and textrec have both Handle and mode as the first items so
  they could use the same routine for opening/creating.
  when (flags and $10)   the file will be append
  when (flags and $100)  the file will be truncate/rewritten
  when (flags and $1000) there is no check for close (needed for textfiles)
}
var
{$ifndef crtlib}
  oflags : longint;
{$endif}
Begin
{ close first if opened }
  if ((flags and $1000)=0) then
   begin
     case FileRec(f).mode of
      fminput,fmoutput,fminout : Do_Close(FileRec(f).Handle);
      fmclosed : ;
     else
      begin
        inoutres:=102; {not assigned}
        exit;
      end;
     end;
   end;
{ reset file Handle }
  FileRec(f).Handle:=UnusedHandle;
{ We do the conversion of filemodes here, concentrated on 1 place }
  case (flags and 3) of
   0 : begin
         oflags :=Open_RDONLY;
         FileRec(f).mode:=fminput;
       end;
   1 : begin
         oflags :=Open_WRONLY;
         FileRec(f).mode:=fmoutput;
       end;
   2 : begin
         oflags :=Open_RDWR;
         FileRec(f).mode:=fminout;
       end;
  end;
  if (flags and $100)=$100 then
   oflags:=oflags or (Open_CREAT or Open_TRUNC)
  else
   if (flags and $10)=$10 then
    oflags:=oflags or (Open_APPEND);
{ empty name is special }
  if p[0]=#0 then
   begin
     case FileRec(f).mode of
       fminput : FileRec(f).Handle:=StdInputHandle;
      fmoutput,
      fmappend : begin
                   FileRec(f).Handle:=StdOutputHandle;
                   FileRec(f).mode:=fmoutput; {fool fmappend}
                 end;
     end;
     exit;
   end;
{ real open call }
{$ifdef crtlib}
  FileRec(f).Handle:=_rtl_open(p, oflags);
  if FileRec(f).Handle<0 then
   InOutRes:=2
  else
   InOutRes:=0;
{$else}
  FileRec(f).Handle:=sys_open(p,oflags,438);
  if (ErrNo=Sys_EROFS) and ((OFlags and Open_RDWR)<>0) then
   begin
     Oflags:=Oflags and not(Open_RDWR);
     FileRec(f).Handle:=sys_open(p,oflags,438);
   end;

  Errno2Inoutres;
{$endif}
End;


Function Do_IsDevice(Handle:Longint):boolean;
{
  Interface to Unix ioctl call.
  Performs various operations on the filedescriptor Handle.
  Ndx describes the operation to perform.
  Data points to data needed for the Ndx function. The structure of this
  data is function-dependent.
}
var
  sr: SysCallRegs;
  Data : array[0..255] of byte; {Large enough for termios info}
begin
  sr.reg2:=Handle;
  sr.reg3:=$5401; {=TCGETS}
  sr.reg4:=Longint(@Data);
  Do_IsDevice:=(SysCall(Syscall_nr_ioctl,sr)=0);
end;


{*****************************************************************************
                           UnTyped File Handling
*****************************************************************************}

{$i file.inc}

{*****************************************************************************
                           Typed File Handling
*****************************************************************************}

{$i typefile.inc}

{*****************************************************************************
                           Text File Handling
*****************************************************************************}

{$DEFINE SHORT_LINEBREAK}
{$DEFINE EXTENDED_EOF}

{$i text.inc}

{*****************************************************************************
                           Directory Handling
*****************************************************************************}

Procedure MkDir(Const s: String);[IOCheck];
Var
  Buffer: Array[0..255] of Char;
Begin
  If InOutRes <> 0 then exit;
  Move(s[1], Buffer, Length(s));
  Buffer[Length(s)] := #0;
{$ifdef crtlib}
  _rtl_mkdir(@buffer);
{$else}
  sys_mkdir(@buffer, 511);
  Errno2Inoutres;
{$endif}
End;


Procedure RmDir(Const s: String);[IOCheck];
Var
  Buffer: Array[0..255] of Char;
Begin
  If InOutRes <> 0 then exit;
  Move(s[1], Buffer, Length(s));
  Buffer[Length(s)] := #0;
{$ifdef crtlib}
  _rtl_rmdir(@buffer);
{$else}
  sys_rmdir(@buffer);
  Errno2Inoutres;
{$endif}
End;


Procedure ChDir(Const s: String);[IOCheck];
Var
  Buffer: Array[0..255] of Char;
Begin
  If InOutRes <> 0 then exit;
  Move(s[1], Buffer, Length(s));
  Buffer[Length(s)] := #0;
{$ifdef crtlib}
  _rtl_chdir(@buffer);
{$else}
  sys_chdir(@buffer);
  Errno2Inoutres;
{$endif}
End;


procedure getdir(drivenr : byte;var dir : shortstring);
{$ifndef crtlib}
var
  thisdir      : stat;
  rootino,
  thisino,
  dotdotino    : longint;
  rootdev,
  thisdev,
  dotdotdev    : word;
  thedir,dummy : string[255];
  dirstream    : pdir;
  d            : pdirent;
  mountpoint   : boolean;
  predot       : string[255];
{$endif}
begin
  drivenr:=0;
  dir:='';
{$ifndef crtlib}
  thedir:='/'#0;
  if sys_stat(@thedir[1],thisdir)<0 then
   exit;
  rootino:=thisdir.ino;
  rootdev:=thisdir.dev;
  thedir:='.'#0;
  if sys_stat(@thedir[1],thisdir)<0 then
   exit;
  thisino:=thisdir.ino;
  thisdev:=thisdir.dev;
  { Now we can uniquely identify the current and root dir }
  thedir:='';
  predot:='';
  while not ((thisino=rootino) and (thisdev=rootdev)) do
   begin
   { Are we on a mount point ? }
     dummy:=predot+'..'#0;
     if sys_stat(@dummy[1],thisdir)<0 then
      exit;
     dotdotino:=thisdir.ino;
     dotdotdev:=thisdir.dev;
     mountpoint:=(thisdev<>dotdotdev);
   { Now, Try to find the name of this dir in the previous one }
     dirstream:=opendir (@dummy[1]);
     if dirstream=nil then
      exit;
     repeat
       d:=sys_readdir (dirstream);
       if (d<>nil) and
          (not ((d^.name[0]='.') and ((d^.name[1]=#0) or ((d^.name[1]='.') and (d^.name[2]=#0))))) and
          (mountpoint or (d^.ino=thisino)) then
        begin
          dummy:=predot+'../'+strpas(@(d^.name[0]))+#0;
          if sys_stat (@(dummy[1]),thisdir)<0 then
           d:=nil;
        end;
     until (d=nil) or ((thisdir.dev=thisdev) and (thisdir.ino=thisino) );
     if (closedir(dirstream)<0) or (d=nil) then
      exit;
   { At this point, d.name contains the name of the current dir}
     thedir:='/'+strpas(@(d^.name[0]))+thedir;
     thisdev:=dotdotdev;
     thisino:=dotdotino;
     predot:=predot+'../';
   end;
{ Now rootino=thisino and rootdev=thisdev so we've reached / }
  dir:=thedir
{$endif}
end;


{*****************************************************************************
                         System Dependent Exit code
*****************************************************************************}
Procedure system_exit;
begin
end;

{*****************************************************************************
                         SystemUnit Initialization
*****************************************************************************}

Procedure SignalToRunError(Sig:longint);
begin
  case sig of
    8 : HandleError(200);
   11 : HandleError(216);
  end;
end;


Procedure InstallSignals;
var
  sr : syscallregs;
begin
  sr.reg3:=longint(@SignalToRunError);
  { sigsegv }
  sr.reg2:=11;
  syscall(syscall_nr_signal,sr);
  { sigfpe }
  sr.reg2:=8;
  syscall(syscall_nr_signal,sr);
end;


Begin
{ Set up signals handlers }
  InstallSignals;
{ Setup heap }
  InitHeap;
  InitExceptions;
{ Setup stdin, stdout and stderr }
  OpenStdIO(Input,fmInput,StdInputHandle);
  OpenStdIO(Output,fmOutput,StdOutputHandle);
  OpenStdIO(StdOut,fmOutput,StdOutputHandle);
  OpenStdIO(StdErr,fmOutput,StdErrorHandle);
{ Reset IO Error }
  InOutRes:=0;
End.

{
  $Log$
  Revision 1.26  1999-09-08 16:14:43  peter
    * pointer fixes

  Revision 1.25  1999/07/28 23:18:36  peter
    * closedir fixes, which now disposes the pdir itself

  Revision 1.24  1999/05/17 21:52:42  florian
    * most of the Object Pascal stuff moved to the system unit

  Revision 1.23  1999/04/08 12:23:04  peter
    * removed os.inc

  Revision 1.22  1999/01/18 10:05:53  pierre
   + system_exit procedure added

  Revision 1.21  1998/12/28 15:50:49  peter
    + stdout, which is needed when you write something in the system unit
      to the screen. Like the runtime error

  Revision 1.20  1998/12/18 17:21:34  peter
    * fixed io-error handling

  Revision 1.19  1998/12/15 22:43:08  peter
    * removed temp symbols

  Revision 1.18  1998/11/16 10:21:32  peter
    * fixes for H+

  Revision 1.17  1998/10/15 08:30:00  peter
    + sigfpe -> runerror 200

  Revision 1.16  1998/09/14 10:48:27  peter
    * FPC_ names
    * Heap manager is now system independent

  Revision 1.15  1998/09/06 19:41:40  peter
    * fixed unusedhandle for 0.99.5

  Revision 1.14  1998/09/04 18:16:16  peter
    * uniform filerec/textrec (with recsize:longint and name:0..255)

  Revision 1.13  1998/08/14 11:59:41  carl
    + m68k fixes

  Revision 1.12  1998/08/12 14:01:37  michael
  + Small m68k fixes

  Revision 1.11  1998/08/11 08:30:37  michael
  + Fixed paramstr() - sometimes there are no 255 characters available.

  Revision 1.10  1998/07/30 13:26:15  michael
  + Added support for ErrorProc variable. All internal functions are required
    to call HandleError instead of runerror from now on.
    This is necessary for exception support.

  Revision 1.9  1998/07/20 23:40:20  michael
  changed sbrk to fc_sbrk, to avoid conflicts with C library.

  Revision 1.8  1998/07/13 21:19:14  florian
    * some problems with ansi string support fixed

  Revision 1.7  1998/07/02 12:36:21  carl
    * IOCheck/InOutRes check for mkdir, chdir and rmdir as in TP

  Revision 1.6  1998/07/01 15:30:01  peter
    * better readln/writeln

  Revision 1.4  1998/05/30 14:18:43  peter
    * fixed to remake with -Rintel in the ppc386.cfg

  Revision 1.3  1998/05/12 10:42:48  peter
    * moved getopts to inc/, all supported OS's need argc,argv exported
    + strpas, strlen are now exported in the systemunit
    * removed logs
    * removed $ifdef ver_above

  Revision 1.2  1998/05/06 12:35:26  michael
  + Removed log from before restored version.
}
