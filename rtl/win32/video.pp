{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by Florian Klaempfl
    member of the Free Pascal development team

    Video unit for Win32

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit Video;
interface

{$i videoh.inc}

implementation

uses
  windows,dos;

{$i video.inc}

var
  OldVideoBuf : PVideoBuf;
  ConsoleInfo : TConsoleScreenBufferInfo;
  ConsoleCursorInfo : TConsoleCursorInfo;
  MaxVideoBufSize : DWord;

const
  VideoInitialized : boolean = false;

procedure InitVideo;
begin
  if VideoInitialized then
    DoneVideo;
  ScreenColor:=true;
  GetConsoleScreenBufferInfo(TextRec(Output).Handle, ConsoleInfo);
  GetConsoleCursorInfo(TextRec(Output).Handle, ConsoleCursorInfo);

  with ConsoleInfo.srWindow do
    begin
       ScreenWidth:=right-left+1;
       ScreenHeight:=bottom-top+1;
    end;

  { srWindow is sometimes bigger then dwMaximumWindowSize
    this led to wrong ScreenWidth and ScreenHeight values PM }
  { damned: its also sometimes less !! PM }
  with ConsoleInfo.dwMaximumWindowSize do
    begin
       {if ScreenWidth>X then}
         ScreenWidth:=X;
       {if ScreenHeight>Y then}
         ScreenHeight:=Y;
    end;

  { TDrawBuffer only has FVMaxWidth elements
    larger values lead to crashes }
  if ScreenWidth> FVMaxWidth then
    ScreenWidth:=FVMaxWidth;

  CursorX:=ConsoleInfo.dwCursorPosition.x;
  CursorY:=ConsoleInfo.dwCursorPosition.y;
  if not ConsoleCursorInfo.bvisible then
    CursorLines:=0
  else
    CursorLines:=ConsoleCursorInfo.dwSize;

  { allocate back buffer }
  MaxVideoBufSize:= ScreenWidth * ScreenHeight * 2;
  VideoBufSize:=ScreenWidth*ScreenHeight*2;

  GetMem(VideoBuf,MaxVideoBufSize);
  GetMem(OldVideoBuf,MaxVideoBufSize);
  VideoInitialized:=true;
end;


procedure DoneVideo;
begin
  SetCursorType(crUnderLine);
  if VideoInitialized then
    begin
      FreeMem(VideoBuf,MaxVideoBufSize);
      FreeMem(OldVideoBuf,MaxVideoBufSize);
    end;
  VideoBufSize:=0;
  VideoInitialized:=false;
end;


function GetCapabilities: Word;
begin
  GetCapabilities:=cpColor or cpChangeCursor;
end;


procedure SetCursorPos(NewCursorX, NewCursorY: Word);
var
  pos : COORD;
begin
   pos.x:=NewCursorX;
   pos.y:=NewCursorY;
   SetConsoleCursorPosition(TextRec(Output).Handle,pos);
   CursorX:=pos.x;
   CursorY:=pos.y;
end;


function GetCursorType: Word;
begin
   GetConsoleCursorInfo(TextRec(Output).Handle,ConsoleCursorInfo);
   if not ConsoleCursorInfo.bvisible then
     GetCursorType:=crHidden
   else
     case ConsoleCursorInfo.dwSize of
        1..30:
          GetCursorType:=crUnderline;
        31..70:
          GetCursorType:=crHalfBlock;
        71..100:
          GetCursorType:=crBlock;
     end;
end;


procedure SetCursorType(NewType: Word);
begin
   GetConsoleCursorInfo(TextRec(Output).Handle,ConsoleCursorInfo);
   if newType=crHidden then
     ConsoleCursorInfo.bvisible:=false
   else
     begin
        ConsoleCursorInfo.bvisible:=true;
        case NewType of
           crUnderline:
             ConsoleCursorInfo.dwSize:=10;

           crHalfBlock:
             ConsoleCursorInfo.dwSize:=50;

           crBlock:
             ConsoleCursorInfo.dwSize:=99;
        end
     end;
   SetConsoleCursorInfo(TextRec(Output).Handle,ConsoleCursorInfo);
end;


function DefaultVideoModeSelector(const VideoMode: TVideoMode; Params: Longint): Boolean;
begin
  DefaultVideoModeSelector:=true;
end;


procedure ClearScreen;
begin
  FillWord(VideoBuf^,VideoBufSize div 2,$0720);
  UpdateScreen(true);
end;


{$IFDEF FPC}
function WriteConsoleOutput(hConsoleOutput:HANDLE; lpBuffer:pointer; dwBufferSize:COORD; dwBufferCoord:COORD;
   var lpWriteRegion:SMALL_RECT):WINBOOL; external 'kernel32' name 'WriteConsoleOutputA';
{$ENDIF}

procedure UpdateScreen(Force: Boolean);
type TmpRec = Array[0..(1024*32) - 1] of TCharInfo;

type WordRec = record
                  One, Two: Byte;
               end; { wordrec }

var
   BufSize,
   BufCoord    : COORD;
   WriteRegion : SMALL_RECT;
   LineBuf     : ^TmpRec;
   BufCounter  : Longint;
   LineCounter,
   ColCounter  : Longint;
   smallforce  : boolean;
(*
begin
  if LockUpdateScreen<>0 then
   exit;
  if not force then
   begin
     asm
        movl    VideoBuf,%esi
        movl    OldVideoBuf,%edi
        movl    VideoBufSize,%ecx
        shrl    $2,%ecx
        repe
        cmpsl
        setne   force
     end;
   end;
  if Force then
   begin
      BufSize.X := ScreenWidth;
      BufSize.Y := ScreenHeight;

      BufCoord.X := 0;
      BufCoord.Y := 0;
      with WriteRegion do
        begin
           Top :=0;
           Left :=0;
           Bottom := ScreenHeight-1;
           Right := ScreenWidth-1;
        end;
      New(LineBuf);
      BufCounter := 0;

      for LineCounter := 1 to ScreenHeight do
        begin
           for ColCounter := 1 to ScreenWidth do
             begin
               LineBuf^[BufCounter].UniCodeChar := Widechar(WordRec(VideoBuf^[BufCounter]).One);
               LineBuf^[BufCounter].Attributes := WordRec(VideoBuf^[BufCounter]).Two;

               Inc(BufCounter);
             end; { for }
        end; { for }

      WriteConsoleOutput(TextRec(Output).Handle, LineBuf, BufSize, BufCoord, WriteRegion);
      Dispose(LineBuf);

      move(VideoBuf^,OldVideoBuf^,VideoBufSize);
   end;
end;
*)
var
   x1,y1,x2,y2 : longint;

begin
  if LockUpdateScreen<>0 then
   exit;
  if force then
   smallforce:=true
  else
   begin
     asm
        movl    VideoBuf,%esi
        movl    OldVideoBuf,%edi
        movl    VideoBufSize,%ecx
        shrl    $2,%ecx
        repe
        cmpsl
        orl     %ecx,%ecx
        jz      .Lno_update
        movb    $1,smallforce
.Lno_update:
     end;
   end;
  if SmallForce then
   begin
      BufSize.X := ScreenWidth;
      BufSize.Y := ScreenHeight;

      BufCoord.X := 0;
      BufCoord.Y := 0;
      with WriteRegion do
        begin
           Top :=0;
           Left :=0;
           Bottom := ScreenHeight-1;
           Right := ScreenWidth-1;
        end;
      New(LineBuf);
      BufCounter := 0;
      x1:=ScreenWidth+1;
      x2:=-1;
      y1:=ScreenHeight+1;
      y2:=-1;
      for LineCounter := 1 to ScreenHeight do
        begin
           for ColCounter := 1 to ScreenWidth do
             begin
               if (WordRec(VideoBuf^[BufCounter]).One<>WordRec(OldVideoBuf^[BufCounter]).One) or
                 (WordRec(VideoBuf^[BufCounter]).Two<>WordRec(OldVideoBuf^[BufCounter]).Two) then
                 begin
                    if ColCounter<x1 then
                      x1:=ColCounter;
                    if ColCounter>x2 then
                      x2:=ColCounter;
                    if LineCounter<y1 then
                      y1:=LineCounter;
                    if LineCounter>y2 then
                      y2:=LineCounter;
                 end;
               LineBuf^[BufCounter].UniCodeChar := Widechar(WordRec(VideoBuf^[BufCounter]).One);
               { If (WordRec(VideoBuf^[BufCounter]).Two and $80)<>0 then
                 LineBuf^[BufCounter].Attributes := $100+WordRec(VideoBuf^[BufCounter]).Two
               else }
                 LineBuf^[BufCounter].Attributes := WordRec(VideoBuf^[BufCounter]).Two;

               Inc(BufCounter);
             end; { for }
        end; { for }
      BufSize.X := ScreenWidth;
      BufSize.Y := ScreenHeight;

      with WriteRegion do
        begin
           if force then
             begin
               Top := 0;
               Left :=0;
               Bottom := ScreenHeight-1;
               Right := ScreenWidth-1;
               BufCoord.X := 0;
               BufCoord.Y := 0;
             end
           else
             begin
               Top := y1-1;
               Left :=x1-1;
               Bottom := y2-1;
               Right := x2-1;
               BufCoord.X := x1-1;
               BufCoord.Y := y1-1;
             end;
        end;
      {
      writeln('X1: ',x1);
      writeln('Y1: ',y1);
      writeln('X2: ',x2);
      writeln('Y2: ',y2);
      }
      WriteConsoleOutput(TextRec(Output).Handle, LineBuf, BufSize, BufCoord, WriteRegion);
      Dispose(LineBuf);

      move(VideoBuf^,OldVideoBuf^,VideoBufSize);
   end;
end;

procedure RegisterVideoModes;
begin
  { don't know what to do for win32 (FK) }
  RegisterVideoMode(80, 25, True, @DefaultVideoModeSelector, $00000003);
end;


initialization
  RegisterVideoModes;

finalization
  UnRegisterVideoModes;
end.
{
  $Log$
  Revision 1.4  2001-07-30 15:01:12  marco
   * Fixed wchar=word to widechar conversion

  Revision 1.3  2001/06/13 18:32:55  peter
    * fixed crash within donevideo (merged)

  Revision 1.2  2001/04/10 21:28:36  peter
    * removed warnigns

  Revision 1.1  2001/01/13 11:03:59  peter
    * API 2 RTL commit

}

