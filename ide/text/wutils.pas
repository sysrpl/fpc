{
    $Id$
    This file is part of the Free Pascal Integrated Development Environment
    Copyright (c) 1998 by Berczi Gabor

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit WUtils;

interface

{$ifndef FPC}
  {$define TPUNIXLF}
{$endif}


uses
  Objects;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..65520] of byte;

  PNoDisposeCollection = ^TNoDisposeCollection;
  TNoDisposeCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PUnsortedStringCollection = ^TUnsortedStringCollection;
  TUnsortedStringCollection = object(TCollection)
    function  At(Index: Integer): PString;
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PSubStream = ^TSubStream;
  TSubStream = object(TStream)
    constructor Init(AStream: PStream; AStartPos, ASize: longint);
    function    GetPos: Longint; virtual;
    function    GetSize: Longint; virtual;
    procedure   Read(var Buf; Count: Word); virtual;
    procedure   Seek(Pos: Longint); virtual;
    procedure   Write(var Buf; Count: Word); virtual;
  private
    StartPos: longint;
    Size    : longint;
    S       : PStream;
  end;

{$ifdef TPUNIXLF}
  procedure readln(var t:text;var s:string);
{$endif}


function Min(A,B: longint): longint;
function Max(A,B: longint): longint;

function CharStr(C: char; Count: byte): string;
function UpcaseStr(const S: string): string;
function LowCase(C: char): char;
function LowcaseStr(S: string): string;
function RExpand(const S: string; MinLen: byte): string;
function LTrim(const S: string): string;
function RTrim(const S: string): string;
function Trim(const S: string): string;
function IntToStr(L: longint): string;
function StrToInt(const S: string): longint;
function GetStr(P: PString): string;

function DirOf(const S: string): string;
function ExtOf(const S: string): string;
function NameOf(const S: string): string;
function NameAndExtOf(const S: string): string;
function DirAndNameOf(const S: string): string;

function EatIO: integer;

const LastStrToIntResult : integer = 0;
      DirSep             : char    = {$ifdef Linux}'/'{$else}'\'{$endif};

implementation

uses
  Dos;

{$ifdef TPUNIXLF}
  procedure readln(var t:text;var s:string);
  var
    c : char;
    i : longint;
  begin
    if TextRec(t).UserData[1]=2 then
      system.readln(t,s)
    else
     begin
      c:=#0;
      i:=0;
      while (not eof(t)) and (c<>#10) do
       begin
         read(t,c);
         if c<>#10 then
          begin
            inc(i);
            s[i]:=c;
          end;
       end;
      if (i>0) and (s[i]=#13) then
       begin
         dec(i);
         TextRec(t).UserData[1]:=2;
       end;
      s[0]:=chr(i);
     end;
  end;
{$endif}


function Max(A,B: longint): longint;
begin
  if A>B then Max:=A else Max:=B;
end;

function Min(A,B: longint): longint;
begin
  if A<B then Min:=A else Min:=B;
end;

function CharStr(C: char; Count: byte): string;
{$ifndef FPC}
var S: string;
{$endif}
begin
{$ifdef FPC}
  CharStr[0]:=chr(Count);
  FillChar(CharStr[1],Count,C);
{$else}
  S[0]:=chr(Count);
  FillChar(S[1],Count,C);
  CharStr:=S;
{$endif}
end;

function UpcaseStr(const S: string): string;
var
  I: Longint;
begin
  for I:=1 to length(S) do
    if S[I] in ['a'..'z'] then
      UpCaseStr[I]:=chr(ord(S[I])-32)
    else
      UpCaseStr[I]:=S[I];
  UpcaseStr[0]:=S[0];
end;

function LowerCaseStr(S: string): string;
var
  I: Longint;
begin
  for I:=1 to length(S) do
    if S[I] in ['A'..'Z'] then
      LowerCaseStr[I]:=chr(ord(S[I])+32)
    else
      LowerCaseStr[I]:=S[I];
  LowercaseStr[0]:=S[0];
end;

function RExpand(const S: string; MinLen: byte): string;
begin
  if length(S)<MinLen then
    RExpand:=S+CharStr(' ',MinLen-length(S))
  else
    RExpand:=S;
end;

function LTrim(const S: string): string;
var
  i : longint;
begin
  i:=1;
  while (i<length(s)) and (s[i]=' ') do
   inc(i);
  LTrim:=Copy(s,i,255);
end;

function RTrim(const S: string): string;
var
  i : longint;
begin
  i:=length(s);
  while (i>0) and (s[i]=' ') do
   dec(i);
  RTrim:=Copy(s,1,i);
end;

function Trim(const S: string): string;
begin
  Trim:=RTrim(LTrim(S));
end;

function IntToStr(L: longint): string;
var S: string;
begin
  Str(L,S);
  IntToStr:=S;
end;


function StrToInt(const S: string): longint;
var L: longint;
    C: integer;
begin
  Val(S,L,C); if C<>0 then L:=-1;
  LastStrToIntResult:=C;
  StrToInt:=L;
end;

function GetStr(P: PString): string;
begin
  if P=nil then GetStr:='' else GetStr:=P^;
end;


function DirOf(const S: string): string;
var D: DirStr; E: ExtStr; N: NameStr;
begin
  FSplit(S,D,N,E);
  if (D<>'') and (D[Length(D)]<>DirSep) then
   DirOf:=D+DirSep
  else
   DirOf:=D;
end;


function ExtOf(const S: string): string;
var D: DirStr; E: ExtStr; N: NameStr;
begin
  FSplit(S,D,N,E);
  ExtOf:=E;
end;


function NameOf(const S: string): string;
var D: DirStr; E: ExtStr; N: NameStr;
begin
  FSplit(S,D,N,E);
  NameOf:=N;
end;

function NameAndExtOf(const S: string): string;
var D: DirStr; E: ExtStr; N: NameStr;
begin
  FSplit(S,D,N,E);
  NameAndExtOf:=N+E;
end;

function DirAndNameOf(const S: string): string;
var D: DirStr; E: ExtStr; N: NameStr;
begin
  FSplit(S,D,N,E);
  DirAndNameOf:=D+N;
end;


function EatIO: integer;
begin
  EatIO:=IOResult;
end;


function LowCase(C: char): char;
begin
  if ('A'<=C) and (C<='Z') then C:=chr(ord(C)+32);
  LowCase:=C;
end;


function LowcaseStr(S: string): string;
var I: Longint;
begin
  for I:=1 to length(S) do
      S[I]:=Lowcase(S[I]);
  LowcaseStr:=S;
end;


procedure TNoDisposeCollection.FreeItem(Item: Pointer);
begin
  { don't do anything here }
end;

function TUnsortedStringCollection.At(Index: Integer): PString;
begin
  At:=inherited At(Index);
end;

procedure TUnsortedStringCollection.FreeItem(Item: Pointer);
begin
  if Item<>nil then DisposeStr(Item);
end;

constructor TSubStream.Init(AStream: PStream; AStartPos, ASize: longint);
begin
  inherited Init;
  S:=AStream; StartPos:=AStartPos; Size:=ASize;
  inherited Seek(StartPos);
end;

function TSubStream.GetPos: Longint;
var Pos: longint;
begin
  Pos:=inherited GetPos; Dec(Pos,StartPos);
  GetPos:=Pos;
end;

function TSubStream.GetSize: Longint;
begin
  GetSize:=Size;
end;

procedure TSubStream.Read(var Buf; Count: Word);
var Pos: longint;
    RCount: word;
begin
  Pos:=GetPos;
  if Pos+Count>Size then RCount:=Size-Pos else RCount:=Count;
  inherited Read(Buf,RCount);
  if RCount<Count then
    Error(stReadError,0);
end;

procedure TSubStream.Seek(Pos: Longint);
var RPos: longint;
begin
  if (Pos<=Size) then RPos:=Pos else RPos:=Size;
  inherited Seek(StartPos+RPos);
end;

procedure TSubStream.Write(var Buf; Count: Word);
begin
  inherited Write(Buf,Count);
end;

END.
{
  $Log$
  Revision 1.4  1999-04-07 21:56:06  peter
    + object support for browser
    * html help fixes
    * more desktop saving things
    * NODEBUG directive to exclude debugger

  Revision 1.2  1999/03/08 14:58:22  peter
    + prompt with dialogs for tools

  Revision 1.1  1999/03/01 15:51:43  peter
    + Log

}
