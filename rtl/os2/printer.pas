{
    $Id: printer.pas,v 1.4 2005/02/14 17:13:31 peter Exp $
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by Florian Klaempfl
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

{$I printerh.inc}

implementation

{$I printer.inc}

begin
  InitPrinter ('PRN');
  SetPrinterExit;
end.
{
  $Log: printer.pas,v $
  Revision 1.4  2005/02/14 17:13:31  peter
    * truncate log

}
