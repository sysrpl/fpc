{
    $Id$
    Copyright (c) 1998-2000 by Peter Vreman

    Contains the base stuff for writing for object files to disk

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
unit owbase;

{$i fpcdefs.inc}

interface
uses
  cstreams,
  cclasses;

type
  tobjectwriter=class
  private
    f      : TCFileStream;
    opened : boolean;
    buf    : pchar;
    bufidx : longint;
    size   : longint;
    procedure writebuf;
  public
    constructor create;
    destructor  destroy;override;
    function  createfile(const fn:string):boolean;virtual;
    procedure closefile;virtual;
    procedure writesym(const sym:string);virtual;
    procedure write(const b;len:longint);virtual;
  end;

  tobjectreader=class
  private
    f      : TCFileStream;
    opened : boolean;
    buf    : pchar;
    bufidx,
    bufmax : longint;
    function readbuf:boolean;
  public
    constructor create;
    destructor  destroy;override;
    function  openfile(const fn:string):boolean;virtual;
    procedure closefile;virtual;
    procedure seek(len:longint);
    function  read(var b;len:longint):boolean;virtual;
    function  readarray(a:TDynamicArray;len:longint):boolean;
  end;

implementation

uses
   cutils,
   verbose;

const
  bufsize = 32768;


{****************************************************************************
                              TObjectWriter
****************************************************************************}

constructor tobjectwriter.create;
begin
  getmem(buf,bufsize);
  bufidx:=0;
  opened:=false;
  size:=0;
end;


destructor tobjectwriter.destroy;
begin
  if opened then
   closefile;
  freemem(buf,bufsize);
end;


function tobjectwriter.createfile(const fn:string):boolean;
begin
  createfile:=false;
  f:=TCFileStream.Create(fn,fmCreate);
  if CStreamError<>0 then
    begin
       Message1(exec_e_cant_create_objectfile,fn);
       exit;
    end;
  bufidx:=0;
  size:=0;
  opened:=true;
  createfile:=true;
end;


procedure tobjectwriter.closefile;
var
  fn : string;
begin
  if bufidx>0 then
   writebuf;
  fn:=f.filename;
  f.free;
{ Remove if size is 0 }
  if size=0 then
   DeleteFile(fn);
  opened:=false;
  size:=0;
end;


procedure tobjectwriter.writebuf;
begin
  f.write(buf^,bufidx);
  bufidx:=0;
end;


procedure tobjectwriter.writesym(const sym:string);
begin
end;


procedure tobjectwriter.write(const b;len:longint);
var
  p   : pchar;
  left,
  idx : longint;
begin
  inc(size,len);
  p:=pchar(@b);
  idx:=0;
  while len>0 do
   begin
     left:=bufsize-bufidx;
     if len>left then
      begin
        move(p[idx],buf[bufidx],left);
        dec(len,left);
        inc(idx,left);
        inc(bufidx,left);
        writebuf;
      end
     else
      begin
        move(p[idx],buf[bufidx],len);
        inc(bufidx,len);
        exit;
      end;
   end;
end;


{****************************************************************************
                              TObjectReader
****************************************************************************}

constructor tobjectreader.create;
begin
  getmem(buf,bufsize);
  bufidx:=0;
  bufmax:=0;
  opened:=false;
end;


destructor tobjectreader.destroy;
begin
  if opened then
   closefile;
  freemem(buf,bufsize);
end;


function tobjectreader.openfile(const fn:string):boolean;
begin
  openfile:=false;
  f:=TCFileStream.Create(fn,fmOpenRead);
  if CStreamError<>0 then
    begin
       Message1(exec_e_cant_create_objectfile,fn);
       exit;
    end;
  bufidx:=0;
  bufmax:=0;
  opened:=true;
  openfile:=true;
end;


procedure tobjectreader.closefile;
begin
  f.free;
  opened:=false;
  bufidx:=0;
  bufmax:=0;
end;


function tobjectreader.readbuf:boolean;
begin
  bufmax:=f.read(buf^,bufsize);
  bufidx:=0;
  readbuf:=(bufmax>0);
end;


procedure tobjectreader.seek(len:longint);
begin
  f.seek(len,soFromBeginning);
  bufidx:=0;
  bufmax:=0;
end;


function tobjectreader.read(var b;len:longint):boolean;
var
  p   : pchar;
  left,
  idx : longint;
begin
  read:=false;
  if bufmax=0 then
   if not readbuf then
    exit;
  p:=pchar(@b);
  idx:=0;
  while len>0 do
   begin
     left:=bufmax-bufidx;
     if len>left then
      begin
        move(buf[bufidx],p[idx],left);
        dec(len,left);
        inc(idx,left);
        inc(bufidx,left);
        if not readbuf then
         exit;
      end
     else
      begin
        move(buf[bufidx],p[idx],len);
        inc(bufidx,len);
        inc(idx,len);
        break;
      end;
   end;
  read:=(idx=len);
end;


function tobjectreader.readarray(a:TDynamicArray;len:longint):boolean;
var
  left,
  idx : longint;
begin
  readarray:=false;
  if bufmax=0 then
   if not readbuf then
    exit;
  idx:=0;
  while len>0 do
   begin
     left:=bufmax-bufidx;
     if len>left then
      begin
        a.Write(buf[bufidx],left);
        dec(len,left);
        inc(idx,left);
        inc(bufidx,left);
        if not readbuf then
         exit;
      end
     else
      begin
        a.Write(buf[bufidx],len);
        inc(bufidx,len);
        inc(idx,len);
        break;
      end;
   end;
  readarray:=(idx=len);
end;


end.
{
  $Log$
  Revision 1.9  2002-05-16 19:46:42  carl
  + defines.inc -> fpcdefs.inc to avoid conflicts if compiling by hand
  + try to fix temp allocation (still in ifdef)
  + generic constructor calls
  + start of tassembler / tmodulebase class cleanup

  Revision 1.7  2001/03/05 21:40:39  peter
    * more things for tcoffobjectinput

  Revision 1.6  2000/12/24 12:25:32  peter
    + cstreams unit
    * dynamicarray object to class

  Revision 1.4  2000/09/24 15:06:20  peter
    * use defines.inc

  Revision 1.3  2000/08/19 18:44:27  peter
    * new tdynamicarray implementation using blocks instead of
      reallocmem (merged)

  Revision 1.2  2000/07/13 11:32:44  michael
  + removed logs

}
