{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl

    This unit implements the first loading and searching of the modules

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
unit fmodule;

{$i fpcdefs.inc}

{$ifdef go32v2}
  {$define shortasmprefix}
{$endif}
{$ifdef tos}
  {$define shortasmprefix}
{$endif}
{$ifdef OS2}
  { Allthough OS/2 supports long filenames I play it safe and
    use 8.3 filenames, because this allows the compiler to run
    on a FAT partition. (DM) }
  {$define shortasmprefix}
{$endif}

interface

    uses
       cutils,cclasses,
       globals,finput,
       symbase,symsym,aasmbase;


    type
      trecompile_reason = (rr_unknown,
        rr_noppu,rr_sourcenewer,rr_build,rr_crcchanged
      );

      TExternalsItem=class(TLinkedListItem)
      public
        found : longbool;
        data  : pstring;
        constructor Create(const s:string);
        Destructor Destroy;override;
      end;

      tlinkcontaineritem=class(tlinkedlistitem)
      public
         data : pstring;
         needlink : cardinal;
         constructor Create(const s:string;m:cardinal);
         destructor Destroy;override;
      end;

      tlinkcontainer=class(tlinkedlist)
         procedure add(const s : string;m:cardinal);
         function get(var m:cardinal) : string;
         function getusemask(mask:cardinal) : string;
         function find(const s:string):boolean;
      end;

      tmodule = class;
      tused_unit = class;

      tunitmaprec = record
        u : tmodule;
        unitsym : tunitsym;
      end;
      punitmap = ^tunitmaprec;

      tmodule = class(tmodulebase)
        do_reload,                { force reloading of the unit }
        do_compile,               { need to compile the sources }
        sources_avail,            { if all sources are reachable }
        interface_compiled,       { if the interface section has been parsed/compiled/loaded }
        is_unit,
        in_interface,             { processing the implementation part? }
        in_global     : boolean;  { allow global settings }
        recompile_reason : trecompile_reason;  { the reason why the unit should be recompiled }
        crc,
        interface_crc : cardinal;
        flags         : cardinal;  { the PPU flags }
        islibrary     : boolean;  { if it is a library (win32 dll) }
        map           : punitmap; { mapping of all used units }
        mapsize       : longint;  { number of units in the map }
        globalsymtable,           { pointer to the global symtable of this unit }
        localsymtable : tsymtable;{ pointer to the local symtable of this unit }
        scanner       : pointer;  { scanner object used }
        procinfo      : pointer;  { current procedure being compiled }
        loaded_from   : tmodule;
        uses_imports  : boolean;  { Set if the module imports from DLL's.}
        imports       : tlinkedlist;
        _exports      : tlinkedlist;
        externals     : tlinkedlist; {Only for DLL scanners by using Unix-style $LINKLIB }
        resourcefiles : tstringlist;
        linkunitofiles,
        linkunitstaticlibs,
        linkunitsharedlibs,
        linkotherofiles,           { objects,libs loaded from the source }
        linkothersharedlibs,       { using $L or $LINKLIB or import lib (for linux) }
        linkotherstaticlibs  : tlinkcontainer;

        used_units           : tlinkedlist;
        dependent_units      : tlinkedlist;

        localunitsearchpath,           { local searchpaths }
        localobjectsearchpath,
        localincludesearchpath,
        locallibrarysearchpath : TSearchPathList;

        asmprefix     : pstring;  { prefix for the smartlink asmfiles }
        librarydata   : tasmlibrarydata;   { librarydata for this module }
        {create creates a new module which name is stored in 's'. LoadedFrom
        points to the module calling it. It is nil for the first compiled
        module. This allow inheritence of all path lists. MUST pay attention
        to that when creating link.res!!!!(mazen)}
        constructor create(LoadedFrom:TModule;const s:string;_is_unit:boolean);
        destructor destroy;override;
        procedure reset;virtual;
        procedure adddependency(callermodule:tmodule);
        procedure flagdependent(callermodule:tmodule);
        function  addusedunit(hp:tmodule;inuses:boolean;usym:tunitsym):tused_unit;
        procedure numberunits;
        procedure allunitsused;
        procedure setmodulename(const s:string);
      end;

       tused_unit = class(tlinkedlistitem)
          unitid          : longint;
          checksum,
          interface_checksum : cardinal;
          in_uses,
          in_interface,
          is_stab_written : boolean;
          u               : tmodule;
          unitsym         : tunitsym;
          constructor create(_u : tmodule;intface,inuses:boolean;usym:tunitsym);
       end;

       tdependent_unit = class(tlinkedlistitem)
          u : tmodule;
          constructor create(_u : tmodule);
       end;

    var
       main_module       : tmodule;     { Main module of the program }
       current_module    : tmodule;     { Current module which is compiled or loaded }
       compiled_module   : tmodule;     { Current module which is compiled }
       usedunits         : tlinkedlist; { Used units for this program }
       loaded_units      : tlinkedlist; { All loaded units }
       SmartLinkOFiles   : TStringList; { List of .o files which are generated,
                                          used to delete them after linking }

function get_source_file(moduleindex,fileindex : longint) : tinputfile;


implementation

    uses
    {$ifdef delphi}
      dmisc,
    {$else}
      dos,
    {$endif}
      verbose,systems,
      scanner,
      procinfo;


{*****************************************************************************
                             Global Functions
*****************************************************************************}

    function get_source_file(moduleindex,fileindex : longint) : tinputfile;
      var
         hp : tmodule;
      begin
         hp:=tmodule(loaded_units.first);
         while assigned(hp) and (hp.unit_index<>moduleindex) do
           hp:=tmodule(hp.next);
         if assigned(hp) then
          get_source_file:=hp.sourcefiles.get_file(fileindex)
         else
          get_source_file:=nil;
      end;


{****************************************************************************
                             TLinkContainerItem
 ****************************************************************************}

    constructor TLinkContainerItem.Create(const s:string;m:cardinal);
      begin
        inherited Create;
        data:=stringdup(s);
        needlink:=m;
      end;


    destructor TLinkContainerItem.Destroy;
      begin
        stringdispose(data);
      end;


{****************************************************************************
                           TLinkContainer
 ****************************************************************************}

    procedure TLinkContainer.add(const s : string;m:cardinal);
      begin
        inherited concat(TLinkContainerItem.Create(s,m));
      end;


    function TLinkContainer.get(var m:cardinal) : string;
      var
        p : tlinkcontaineritem;
      begin
        p:=tlinkcontaineritem(inherited getfirst);
        if p=nil then
         begin
           get:='';
           m:=0;
         end
        else
         begin
           get:=p.data^;
           m:=p.needlink;
           p.free;
         end;
      end;


    function TLinkContainer.getusemask(mask:cardinal) : string;
      var
         p : tlinkcontaineritem;
         found : boolean;
      begin
        found:=false;
        repeat
          p:=tlinkcontaineritem(inherited getfirst);
          if p=nil then
           begin
             getusemask:='';
             exit;
           end;
          getusemask:=p.data^;
          found:=(p.needlink and mask)<>0;
          p.free;
        until found;
      end;


    function TLinkContainer.find(const s:string):boolean;
      var
        newnode : tlinkcontaineritem;
      begin
        find:=false;
        newnode:=tlinkcontaineritem(First);
        while assigned(newnode) do
         begin
           if newnode.data^=s then
            begin
              find:=true;
              exit;
            end;
           newnode:=tlinkcontaineritem(newnode.next);
         end;
      end;


{****************************************************************************
                              TExternalsItem
 ****************************************************************************}

    constructor tExternalsItem.Create(const s:string);
      begin
        inherited Create;
        found:=false;
        data:=stringdup(s);
      end;


    destructor tExternalsItem.Destroy;
      begin
        stringdispose(data);
        inherited;
      end;


{****************************************************************************
                              TUSED_UNIT
 ****************************************************************************}

    constructor tused_unit.create(_u : tmodule;intface,inuses:boolean;usym:tunitsym);
      begin
        u:=_u;
        in_interface:=intface;
        in_uses:=inuses;
        is_stab_written:=false;
        unitid:=0;
        unitsym:=usym;
        if _u.state=ms_compiled then
         begin
           checksum:=u.crc;
           interface_checksum:=u.interface_crc;
         end
        else
         begin
           checksum:=0;
           interface_checksum:=0;
         end;
      end;


{****************************************************************************
                            TDENPENDENT_UNIT
 ****************************************************************************}

    constructor tdependent_unit.create(_u : tmodule);
      begin
         u:=_u;
      end;


{****************************************************************************
                                  TMODULE
 ****************************************************************************}

    constructor tmodule.create(LoadedFrom:TModule;const s:string;_is_unit:boolean);
      var
        p : dirstr;
        n : namestr;
        e : extstr;
      begin
        FSplit(s,p,n,e);
        { Programs have the name 'Program' to don't conflict with dup id's }
        if _is_unit then
         inherited create(n)
        else
         inherited create('Program');
        mainsource:=stringdup(s);
        { Dos has the famous 8.3 limit :( }
{$ifdef shortasmprefix}
        asmprefix:=stringdup(FixFileName('as'));
{$else}
        asmprefix:=stringdup(FixFileName(n));
{$endif}
        setfilename(p+n,true);
        localunitsearchpath:=TSearchPathList.Create;
        localobjectsearchpath:=TSearchPathList.Create;
        localincludesearchpath:=TSearchPathList.Create;
        locallibrarysearchpath:=TSearchPathList.Create;
        used_units:=TLinkedList.Create;
        dependent_units:=TLinkedList.Create;
        resourcefiles:=TStringList.Create;
        linkunitofiles:=TLinkContainer.Create;
        linkunitstaticlibs:=TLinkContainer.Create;
        linkunitsharedlibs:=TLinkContainer.Create;
        linkotherofiles:=TLinkContainer.Create;
        linkotherstaticlibs:=TLinkContainer.Create;
        linkothersharedlibs:=TLinkContainer.Create;
        crc:=0;
        interface_crc:=0;
        flags:=0;
        scanner:=nil;
        map:=nil;
        mapsize:=0;
        globalsymtable:=nil;
        localsymtable:=nil;
        loaded_from:=LoadedFrom;
        do_reload:=false;
        do_compile:=false;
        sources_avail:=true;
        recompile_reason:=rr_unknown;
        in_interface:=true;
        in_global:=true;
        is_unit:=_is_unit;
        islibrary:=false;
        uses_imports:=false;
        imports:=TLinkedList.Create;
        _exports:=TLinkedList.Create;
        externals:=TLinkedList.Create;
        librarydata:=tasmlibrarydata.create(realmodulename^);
      end;


    destructor tmodule.Destroy;
      var
{$ifdef MEMDEBUG}
        d : tmemdebug;
{$endif}
        hpi : tprocinfo;
      begin
        dispose(map);
        if assigned(imports) then
         imports.free;
        if assigned(_exports) then
         _exports.free;
        if assigned(externals) then
         externals.free;
        if assigned(scanner) then
         begin
            { also update current_scanner if it was pointing
              to this module }
            if current_scanner=tscannerfile(scanner) then
             current_scanner:=nil;
            tscannerfile(scanner).free;
         end;
        if assigned(procinfo) then
          begin
            if current_procinfo=tprocinfo(procinfo) then
             current_procinfo:=nil;
            { release procinfo tree }
            while assigned(procinfo) do
             begin
               hpi:=tprocinfo(procinfo).parent;
               tprocinfo(procinfo).free;
               procinfo:=hpi;
             end;
          end;
        used_units.free;
        dependent_units.free;
        resourcefiles.Free;
        linkunitofiles.Free;
        linkunitstaticlibs.Free;
        linkunitsharedlibs.Free;
        linkotherofiles.Free;
        linkotherstaticlibs.Free;
        linkothersharedlibs.Free;
        stringdispose(objfilename);
        stringdispose(newfilename);
        stringdispose(ppufilename);
        stringdispose(staticlibfilename);
        stringdispose(sharedlibfilename);
        stringdispose(exefilename);
        stringdispose(outputpath);
        stringdispose(path);
        stringdispose(realmodulename);
        stringdispose(mainsource);
        stringdispose(asmprefix);
        localunitsearchpath.Free;
        localobjectsearchpath.free;
        localincludesearchpath.free;
        locallibrarysearchpath.free;
{$ifdef MEMDEBUG}
        d:=tmemdebug.create(modulename^+' - symtable');
{$endif}
        if assigned(globalsymtable) then
          globalsymtable.free;
        if assigned(localsymtable) then
          localsymtable.free;
{$ifdef MEMDEBUG}
        d.free;
{$endif}
{$ifdef MEMDEBUG}
        d:=tmemdebug.create(modulename^+' - librarydata');
{$endif}
        librarydata.free;
{$ifdef MEMDEBUG}
        d.free;
{$endif}
        stringdispose(modulename);
        inherited Destroy;
      end;


    procedure tmodule.reset;
      var
        hpi : tprocinfo;
      begin
        if assigned(scanner) then
          begin
            { also update current_scanner if it was pointing
              to this module }
            if current_scanner=tscannerfile(scanner) then
             current_scanner:=nil;
            tscannerfile(scanner).free;
            scanner:=nil;
          end;
        if assigned(procinfo) then
          begin
            if current_procinfo=tprocinfo(procinfo) then
             current_procinfo:=nil;
            { release procinfo tree }
            while assigned(procinfo) do
             begin
               hpi:=tprocinfo(procinfo).parent;
               tprocinfo(procinfo).free;
               procinfo:=hpi;
             end;
          end;
        if assigned(globalsymtable) then
          begin
            globalsymtable.free;
            globalsymtable:=nil;
          end;
        if assigned(localsymtable) then
          begin
            localsymtable.free;
            localsymtable:=nil;
          end;
        if assigned(map) then
          begin
            freemem(map);
            map:=nil;
          end;
        mapsize:=0;
        sourcefiles.free;
        sourcefiles:=tinputfilemanager.create;
        librarydata.free;
        librarydata:=tasmlibrarydata.create(realmodulename^);
        imports.free;
        imports:=tlinkedlist.create;
        _exports.free;
        _exports:=tlinkedlist.create;
        externals.free;
        externals:=tlinkedlist.create;
        used_units.free;
        used_units:=TLinkedList.Create;
        dependent_units.free;
        dependent_units:=TLinkedList.Create;
        resourcefiles.Free;
        resourcefiles:=TStringList.Create;
        linkunitofiles.Free;
        linkunitofiles:=TLinkContainer.Create;
        linkunitstaticlibs.Free;
        linkunitstaticlibs:=TLinkContainer.Create;
        linkunitsharedlibs.Free;
        linkunitsharedlibs:=TLinkContainer.Create;
        linkotherofiles.Free;
        linkotherofiles:=TLinkContainer.Create;
        linkotherstaticlibs.Free;
        linkotherstaticlibs:=TLinkContainer.Create;
        linkothersharedlibs.Free;
        linkothersharedlibs:=TLinkContainer.Create;
        uses_imports:=false;
        do_compile:=false;
        interface_compiled:=false;
        in_interface:=true;
        in_global:=true;
        crc:=0;
        interface_crc:=0;
        flags:=0;
        recompile_reason:=rr_unknown;
        {
          The following fields should not
          be reset:
           mainsource
           loaded_from
           state
           sources_avail
        }
      end;


    procedure tmodule.adddependency(callermodule:tmodule);
      begin
        { This is not needed for programs }
        if not callermodule.is_unit then
          exit;
        Message2(unit_u_add_depend_to,callermodule.modulename^,modulename^);
        dependent_units.concat(tdependent_unit.create(callermodule));
      end;


    procedure tmodule.flagdependent(callermodule:tmodule);
      var
        pm : tdependent_unit;
      begin
        { flag all units that depend on this unit for reloading }
        pm:=tdependent_unit(current_module.dependent_units.first);
        while assigned(pm) do
         begin
           { We do not have to reload the unit that wants to load
             this unit, unless this unit is already compiled during
             the loading }
           if (pm.u=callermodule) and
              (pm.u.state<>ms_compiled) then
             Message1(unit_u_no_reload_is_caller,pm.u.modulename^)
           else
            if pm.u.state=ms_second_compile then
              Message1(unit_u_no_reload_in_second_compile,pm.u.modulename^)
           else
            begin
              pm.u.do_reload:=true;
              Message1(unit_u_flag_for_reload,pm.u.modulename^);
            end;
           pm:=tdependent_unit(pm.next);
         end;
      end;


    function tmodule.addusedunit(hp:tmodule;inuses:boolean;usym:tunitsym):tused_unit;
      var
        pu : tused_unit;
      begin
        pu:=tused_unit.create(hp,in_interface,inuses,usym);
        used_units.concat(pu);
        addusedunit:=pu;
      end;


    procedure tmodule.numberunits;
      var
        pu : tused_unit;
        hp : tmodule;
        i  : integer;
      begin
        { Reset all numbers to -1 }
        hp:=tmodule(loaded_units.first);
        while assigned(hp) do
         begin
           if assigned(hp.globalsymtable) then
             hp.globalsymtable.unitid:=$ffff;
           hp:=tmodule(hp.next);
         end;
        { Allocate map }
        mapsize:=used_units.count+1;
        reallocmem(map,mapsize*sizeof(tunitmaprec));
        { Our own symtable gets unitid 0, for a program there is
          no globalsymtable }
        if assigned(globalsymtable) then
          globalsymtable.unitid:=0;
        map[0].u:=self;
        map[0].unitsym:=nil;
        { number units and map }
        i:=1;
        pu:=tused_unit(used_units.first);
        while assigned(pu) do
          begin
            if assigned(pu.u.globalsymtable) then
              begin
                tsymtable(pu.u.globalsymtable).unitid:=i;
                map[i].u:=pu.u;
                map[i].unitsym:=pu.unitsym;
                inc(i);
              end;
            pu:=tused_unit(pu.next);
          end;
      end;


    procedure tmodule.allunitsused;
      var
        i : longint;
      begin
        for i:=0 to mapsize-1 do
          begin
            if assigned(map[i].unitsym) and
               (map[i].unitsym.refs=0) then
              MessagePos2(map[i].unitsym.fileinfo,sym_n_unit_not_used,map[i].u.modulename^,modulename^);
          end;
      end;


    procedure tmodule.setmodulename(const s:string);
      begin
        stringdispose(modulename);
        stringdispose(realmodulename);
        modulename:=stringdup(upper(s));
        realmodulename:=stringdup(s);
        { also update asmlibrary names }
        librarydata.name:=modulename^;
        librarydata.realname:=realmodulename^;
      end;

end.
{
  $Log$
  Revision 1.39  2003-10-22 15:22:33  peter
    * fixed unitsym-globalsymtable relation so the uses of a unit
      is counted correctly

  Revision 1.38  2003/10/01 20:34:48  peter
    * procinfo unit contains tprocinfo
    * cginfo renamed to cgbase
    * moved cgmessage to verbose
    * fixed ppc and sparc compiles

  Revision 1.37  2003/08/23 22:31:42  peter
    * reload also caller module when it is already compiled

  Revision 1.36  2003/06/07 20:26:32  peter
    * re-resolving added instead of reloading from ppu
    * tderef object added to store deref info for resolving

  Revision 1.35  2003/05/25 10:27:12  peter
    * moved Comment calls to messge file

  Revision 1.34  2003/05/23 14:27:35  peter
    * remove some unit dependencies
    * current_procinfo changes to store more info

  Revision 1.33  2003/04/27 11:21:32  peter
    * aktprocdef renamed to current_procdef
    * procinfo renamed to current_procinfo
    * procinfo will now be stored in current_module so it can be
      cleaned up properly
    * gen_main_procsym changed to create_main_proc and release_main_proc
      to also generate a tprocinfo structure
    * fixed unit implicit initfinal

  Revision 1.32  2002/12/29 14:57:50  peter
    * unit loading changed to first register units and load them
      afterwards. This is needed to support uses xxx in yyy correctly
    * unit dependency check fixed

  Revision 1.31  2002/12/07 14:27:07  carl
    * 3% memory optimization
    * changed some types
    + added type checking with different size for call node and for
       parameters

  Revision 1.30  2002/11/24 18:19:56  carl
    + tos also has short filenames

  Revision 1.29  2002/11/20 12:36:23  mazen
  * $UNITPATH directive is now working

  Revision 1.28  2002/09/05 19:29:42  peter
    * memdebug enhancements

  Revision 1.27  2002/08/16 15:31:08  peter
    * fixed possible crashes with current_scanner

  Revision 1.26  2002/08/12 16:46:04  peter
    * tscannerfile is now destroyed in tmodule.reset and current_scanner
      is updated accordingly. This removes all the loading and saving of
      the old scanner and the invalid flag marking

  Revision 1.25  2002/08/11 14:28:19  peter
    * TScannerFile.SetInvalid added that will also reset inputfile

  Revision 1.24  2002/08/11 13:24:11  peter
    * saving of asmsymbols in ppu supported
    * asmsymbollist global is removed and moved into a new class
      tasmlibrarydata that will hold the info of a .a file which
      corresponds with a single module. Added librarydata to tmodule
      to keep the library info stored for the module. In the future the
      objectfiles will also be stored to the tasmlibrarydata class
    * all getlabel/newasmsymbol and friends are moved to the new class

  Revision 1.23  2002/05/16 19:46:36  carl
  + defines.inc -> fpcdefs.inc to avoid conflicts if compiling by hand
  + try to fix temp allocation (still in ifdef)
  + generic constructor calls
  + start of tassembler / tmodulebase class cleanup

  Revision 1.22  2002/05/14 19:34:41  peter
    * removed old logs and updated copyright year

  Revision 1.21  2002/04/04 19:05:55  peter
    * removed unused units
    * use tlocation.size in cg.a_*loc*() routines

  Revision 1.20  2002/03/28 20:46:59  carl
  - remove go32v1 support

}
