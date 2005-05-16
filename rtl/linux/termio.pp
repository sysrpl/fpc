{
    $Id: termio.pp,v 1.2 2005/02/14 17:13:30 peter Exp $
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by Peter Vreman
    member of the Free Pascal development team.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This file contains the termios interface.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit termio;

interface

Uses BaseUnix;          // load base unix typing

// load types + consts

{$i termios.inc}

// load default prototypes from unix dir.

{$i termiosh.inc}

implementation

{$i textrec.inc}

// load implementation for prototypes from current dir.
{$i termiosproc.inc}

// load ttyname from unix dir.
{$i ttyname.inc}

end.

{
  $Log: termio.pp,v $
  Revision 1.2  2005/02/14 17:13:30  peter
    * truncate log

}
