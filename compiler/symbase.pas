{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl, Pierre Muller

    This unit handles the symbol tables

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
unit symbase;

{$i fpcdefs.inc}

interface

    uses
       { common }
       cutils,cclasses,
       { global }
       globtype,globals,
       { symtable }
       symconst
       ;

{************************************************
           Some internal constants
************************************************}

   const
       hasharraysize    = 256;
       indexgrowsize    = 64;

{$ifdef GDB}
       memsizeinc = 4096; { for long stabstrings }
{$endif GDB}


{************************************************
            Needed forward pointers
************************************************}

    type
       tsymtable = class;

{************************************************
               TSymtableEntry
************************************************}

      tsymtableentry = class(TNamedIndexItem)
         owner : tsymtable;
      end;


{************************************************
                 TDefEntry
************************************************}

      tdefentry = class(tsymtableentry)
         deftype : tdeftype;
      end;


{************************************************
                   TSymEntry
************************************************}

      { this object is the base for all symbol objects }
      tsymentry = class(tsymtableentry)
         typ : tsymtyp;
      end;


{************************************************
                 TSymtable
************************************************}

       tsearchhasharray = array[0..hasharraysize-1] of tsymentry;
       psearchhasharray = ^tsearchhasharray;

       tsymtable = class
{$ifdef EXTDEBUG}
       private
          procedure dumpsym(p : TNamedIndexItem;arg:pointer);
{$endif EXTDEBUG}
       public
          name      : pstring;
          realname  : pstring;
          symindex,
          defindex  : TIndexArray;
          symsearch : Tdictionary;
          next      : tsymtable;
          defowner  : tdefentry; { for records and objects }
          symtabletype  : tsymtabletype;
          { each symtable gets a number }
          unitid        : word;
          { level of symtable, used for nested procedures }
          symtablelevel : byte;
          refcount  : integer;
          constructor Create(const s:string);
          destructor  destroy;override;
          procedure freeinstance;override;
          function  getcopy:tsymtable;
          procedure clear;virtual;
          function  rename(const olds,news : stringid):tsymentry;
          procedure foreach(proc2call : tnamedindexcallback;arg:pointer);
          procedure foreach_static(proc2call : tnamedindexstaticcallback;arg:pointer);
          procedure insert(sym : tsymentry);virtual;
          procedure replace(oldsym,newsym:tsymentry);
          function  search(const s : stringid) : tsymentry;
          function  speedsearch(const s : stringid;speedvalue : cardinal) : tsymentry;virtual;
          procedure registerdef(p : tdefentry);
{$ifdef EXTDEBUG}
          procedure dump;
{$endif EXTDEBUG}
          function  getdefnr(l : longint) : tdefentry;
          function  getsymnr(l : longint) : tsymentry;
{$ifdef GDB}
          function getnewtypecount : word; virtual;
{$endif GDB}
       end;

    var
       registerdef : boolean;      { true, when defs should be registered }

       defaultsymtablestack : tsymtable;  { symtablestack after default units have been loaded }
       symtablestack     : tsymtable;     { linked list of symtables }

       aktrecordsymtable : tsymtable;     { current record symtable }
       aktparasymtable   : tsymtable;     { current proc para symtable }
       aktlocalsymtable  : tsymtable;     { current proc local symtable }


implementation

    uses
       verbose;

{****************************************************************************
                                TSYMTABLE
****************************************************************************}

    constructor tsymtable.Create(const s:string);
      begin
         if s<>'' then
          begin
            name:=stringdup(upper(s));
            realname:=stringdup(s);
          end
         else
          begin
            name:=nil;
            realname:=nil;
          end;
         symtabletype:=abstractsymtable;
         symtablelevel:=0;
         defowner:=nil;
         next:=nil;
         symindex:=tindexarray.create(indexgrowsize);
         defindex:=TIndexArray.create(indexgrowsize);
         symsearch:=tdictionary.create;
         symsearch.noclear:=true;
         unitid:=0;
         refcount:=1;
      end;


    destructor tsymtable.destroy;
      begin
        { freeinstance decreases refcount }
        if refcount>1 then
          exit;
        stringdispose(name);
        stringdispose(realname);
        symindex.destroy;
        defindex.destroy;
        { symsearch can already be disposed or set to nil for withsymtable }
        if assigned(symsearch) then
         begin
           symsearch.destroy;
           symsearch:=nil;
         end;
      end;


    procedure tsymtable.freeinstance;
      begin
        dec(refcount);
        if refcount=0 then
          inherited freeinstance;
      end;


    function tsymtable.getcopy:tsymtable;
      begin
        inc(refcount);
        result:=self;
      end;


{$ifdef EXTDEBUG}
    procedure tsymtable.dumpsym(p : TNamedIndexItem;arg:pointer);
      begin
        writeln(p.name);
      end;


    procedure tsymtable.dump;
      begin
        if assigned(name) then
          writeln('Symtable ',name^)
        else
          writeln('Symtable <not named>');
        symsearch.foreach({$ifdef FPCPROCVAR}@{$endif}dumpsym,nil);
      end;
{$endif EXTDEBUG}


    procedure tsymtable.registerdef(p : tdefentry);
      begin
         defindex.insert(p);
         { set def owner and indexnb }
         p.owner:=self;
      end;


    procedure tsymtable.foreach(proc2call : tnamedindexcallback;arg:pointer);
      begin
        symindex.foreach(proc2call,arg);
      end;


    procedure tsymtable.foreach_static(proc2call : tnamedindexstaticcallback;arg:pointer);
      begin
        symindex.foreach_static(proc2call,arg);
      end;


{***********************************************
                Table Access
***********************************************}

    procedure tsymtable.clear;
      begin
         symindex.clear;
         defindex.clear;
      end;


    procedure tsymtable.insert(sym:tsymentry);
      begin
         sym.owner:=self;
         { insert in index and search hash }
         symindex.insert(sym);
         symsearch.insert(sym);
      end;


    procedure tsymtable.replace(oldsym,newsym:tsymentry);
      begin
         { Replace the entry in the dictionary, this checks
           the name }
         if not symsearch.replace(oldsym,newsym) then
           internalerror(200209061);
         { replace in index }
         symindex.replace(oldsym,newsym);
         { set owner of new symb }
         newsym.owner:=self;
      end;


    function tsymtable.search(const s : stringid) : tsymentry;
      begin
        search:=speedsearch(s,getspeedvalue(s));
      end;


    function tsymtable.speedsearch(const s : stringid;speedvalue : cardinal) : tsymentry;
      begin
        speedsearch:=tsymentry(symsearch.speedsearch(s,speedvalue));
      end;


    function tsymtable.rename(const olds,news : stringid):tsymentry;
      begin
        rename:=tsymentry(symsearch.rename(olds,news));
      end;


    function tsymtable.getsymnr(l : longint) : tsymentry;
      var
        hp : tsymentry;
      begin
        hp:=tsymentry(symindex.search(l));
        if hp=nil then
         internalerror(10999);
        getsymnr:=hp;
      end;


    function tsymtable.getdefnr(l : longint) : tdefentry;
      var
        hp : tdefentry;
      begin
        hp:=tdefentry(defindex.search(l));
        if hp=nil then
         internalerror(10998);
        getdefnr:=hp;
      end;


{$ifdef GDB}
    function tsymtable.getnewtypecount : word;
      begin
        getnewtypecount:=0;
      end;
{$endif GDB}


end.
{
  $Log$
  Revision 1.22  2004-07-09 22:17:32  peter
    * revert has_localst patch
    * replace aktstaticsymtable/aktglobalsymtable with current_module

  Revision 1.21  2004/06/20 08:55:30  florian
    * logs truncated

  Revision 1.20  2004/03/02 17:32:12  florian
    * make cycle fixed
    + pic support for darwin
    + support of importing vars from shared libs on darwin implemented

  Revision 1.19  2004/02/04 22:15:15  daniel
    * Rtti generation moved to ncgutil
    * Assmtai usage of symsym removed
    * operator overloading cleanup up

  Revision 1.18  2004/01/15 15:16:18  daniel
    * Some minor stuff
    * Managed to eliminate speed effects of string compression

  Revision 1.17  2004/01/11 23:56:20  daniel
    * Experiment: Compress strings to save memory
      Did not save a single byte of mem; clearly the core size is boosted by
      temporary memory usage...

}
