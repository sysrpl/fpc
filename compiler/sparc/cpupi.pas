{
    $Id$
    Copyright (c) 2002 by Florian Klaempfl

    This unit contains the CPU specific part of tprocinfo

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
unit cpupi;

{$i fpcdefs.inc}

interface

  uses
    cutils,
    procinfo,cpuinfo,
    psub;

  type
    TSparcProcInfo=class(tcgprocinfo)
    public
      constructor create(aparent:tprocinfo);override;
      procedure allocate_push_parasize(size:longint);override;
      function calc_stackframe_size:longint;override;
    end;

implementation

    uses
      systems,globals,
      tgobj,paramgr,symconst;

    constructor tsparcprocinfo.create(aparent:tprocinfo);
      begin
        inherited create(aparent);
        maxpushedparasize:=0;
      end;


    procedure tsparcprocinfo.allocate_push_parasize(size:longint);
      begin
        if size>maxpushedparasize then
          maxpushedparasize:=size;
      end;


    function TSparcProcInfo.calc_stackframe_size:longint;
      begin
        {
          Stackframe layout:
          %fp
            <locals>
            <temp>
            <arguments 6-n for calling>
          %sp+92
            <space for arguments 0-5>                \
            <return pointer for calling>              | included in first_parm_offset
            <register window save area for calling>  /
          %sp

          Alignment must be the max available, as doubles require
          8 byte alignment
        }
        result:=Align(tg.direction*tg.lasttemp+maxpushedparasize+target_info.first_parm_offset,aktalignment.localalignmax);
      end;


begin
  cprocinfo:=TSparcProcInfo;
end.
{
  $Log$
  Revision 1.28  2004-06-20 08:55:32  florian
    * logs truncated

  Revision 1.27  2004/06/16 20:07:10  florian
    * dwarf branch merged

  Revision 1.26.2.1  2004/05/31 22:08:21  peter
    * fix passing of >6 arguments

  Revision 1.26  2004/03/12 08:18:11  mazen
  - revert '../' from include path

  Revision 1.25  2004/03/11 16:22:09  mazen
  + help lazarus analyze the file

  Revision 1.24  2004/02/25 14:25:47  mazen
  * fix compile problem for sparc

}
