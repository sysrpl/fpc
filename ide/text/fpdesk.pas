{
    $Id$
    This file is part of the Free Pascal Integrated Development Environment
    Copyright (c) 1998 by Berczi Gabor

    Desktop loading/saving routines

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit FPDesk;

interface

procedure InitDesktopFile;
function  LoadDesktop: boolean;
function  SaveDesktop: boolean;
procedure DoneDesktopFile;

implementation

uses Dos,
     WResource,
     FPConst,FPVars,FPUtils;

procedure InitDesktopFile;
begin
  if DesktopLocation=dlCurrentDir then
    DesktopPath:=FExpand(DesktopName)
  else
    DesktopPath:=FExpand(DirOf(INIPath)+DesktopName);
end;

procedure DoneDesktopFile;
begin
end;

function WriteHistory(F: PResourceFile): boolean;
begin
end;

function WriteClipboard(F: PResourceFile): boolean;
begin
end;

function WriteWatches(F: PResourceFile): boolean;
begin
end;

function WriteBreakpoints(F: PResourceFile): boolean;
begin
end;

function WriteOpenWindows(F: PResourceFile): boolean;
begin
end;

function WriteSymbols(F: PResourceFile): boolean;
begin
end;

function LoadDesktop: boolean;
begin
end;

function SaveDesktop: boolean;
var OK: boolean;
    F: PSimpleResourceFile;
begin
  New(F, Create(DesktopPath));
  OK:=true;
  if OK and ((DesktopFileFlags and dfHistoryLists)<>0) then
    OK:=WriteHistory(F);
  if OK and ((DesktopFileFlags and dfClipboardContent)<>0) then
    OK:=WriteClipboard(F);
  if OK and ((DesktopFileFlags and dfWatches)<>0) then
    OK:=WriteWatches(F);
  if OK and ((DesktopFileFlags and dfBreakpoints)<>0) then
    OK:=WriteBreakpoints(F);
  if OK and ((DesktopFileFlags and dfOpenWindows)<>0) then
    OK:=WriteOpenWindows(F);
  if OK and ((DesktopFileFlags and dfSymbolInformation)<>0) then
    OK:=WriteSymbols(F);
  Dispose(F, Done);
  SaveDesktop:=OK;
end;

END.
{
  $Log$
  Revision 1.1  1999-03-23 15:11:28  peter
    * desktop saving things
    * vesa mode
    * preferences dialog

}

