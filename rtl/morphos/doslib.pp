{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 2004 Karoly Balogh for Genesi S.a.r.l. <www.genesi.lu>

    dos.library interface unit for MorphOS/PowerPC

    MorphOS port was done on a free Pegasos II/G4 machine 
    provided by Genesi S.a.r.l. <www.genesi.lu>

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit doslib;

interface

uses Exec, Timer;

var
  DosBase: Pointer;


{$include doslibd.inc}
{$include doslibf.inc}


{ * dos global definitions (V50)
  *********************************************************************
  * }

function BADDR(x: LongInt): Pointer; Inline;
function MKBADDR(x: Pointer): LongInt; Inline;


{ * dos stdio definitions
  *********************************************************************
  * }

function ReadChar: LongInt; Inline;
function WriteChar(ch: Char): LongInt; Inline;
function UnReadChar(ch: Char): LongInt; Inline;
function ReadChars(buf: Pointer; num: LongInt): LongInt; Inline;
function dosReadLn(buf: PChar; num: LongInt): PChar; Inline;
function WriteStr(str: PChar): LongInt; Inline;
procedure VWritef(format: PChar; argv: Pointer); Inline;



implementation


{ * dos stdio definitions
  *********************************************************************
  * }

function ReadChar: LongInt; Inline;
begin
  ReadChar:=FGetC(dosInput);
end;

function WriteChar(ch: Char): LongInt; Inline;
begin
  WriteChar:=FPutC(dosOutput,Byte(ch));
end;

function UnReadChar(ch: Char): LongInt; Inline;
begin
  UnReadChar:=UnGetC(dosInput,Byte(ch));
end;

function ReadChars(buf: Pointer; num: LongInt): LongInt; Inline;
begin
  ReadChars:=FRead(dosInput,buf,1,num);
end;

function dosReadLn(buf: PChar; num: LongInt): PChar; Inline;
begin
  dosReadLn:=FGets(dosInput,buf,num);
end;

function WriteStr(str: PChar): LongInt; Inline;
begin
  WriteStr:=FPuts(dosOutput,str);
end;

procedure VWritef(format: PChar; argv: Pointer); Inline;
begin
  VFWritef(dosOutput,format,argv);
end;



{ * dos global definitions (V50)
  *********************************************************************
  * }


function BADDR(x: LongInt): Pointer; Inline;
begin
 BADDR:=Pointer(x Shl 2);
end;

function MKBADDR(x: Pointer): LongInt; Inline;
begin
 MKBADDR:=LongInt(x) Shr 2;
end;



begin
  DosBase:=MOS_DOSBase;
end.

{
  $Log$
  Revision 1.2  2004-08-09 00:10:19  karoly
    + added most of missing stuff

  Revision 1.1  2004/06/26 20:46:17  karoly
    * initial revision

}
