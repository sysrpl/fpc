{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 1993,98 by Florian Klaempfl
    member of the Free Pascal development team

    Printer unit for BP7 compatible RTL

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit printer;
interface

var
  lst : text;

implementation

var
  old_exit : pointer;

procedure printer_exit;
begin
  close(lst);
  exitproc:=old_exit;
end;


begin
  assign(lst,'prt:');
  rewrite(lst);
  old_exit:=exitproc;
  exitproc:=@printer_exit;
end.
