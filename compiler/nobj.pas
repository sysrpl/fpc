{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl

    Routines for the code generation of data structures
    like VMT, Messages, VTables, Interfaces descs

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
unit nobj;

{$i fpcdefs.inc}

interface

    uses
{$ifdef Delphi}
       dmisc,
{$endif}
       cutils,cclasses,
       globtype,
       symdef,
       aasmbase,aasmtai,
       cpuinfo
       ;

    type
      pprocdeftree = ^tprocdeftree;
      tprocdeftree = record
         data : tprocdef;
         nl   : tasmlabel;
         l,r  : pprocdeftree;
      end;

      pprocdefcoll = ^tprocdefcoll;
      tprocdefcoll = record
         data    : tprocdef;
         hidden  : boolean;
         next    : pprocdefcoll;
      end;

      psymcoll = ^tsymcoll;
      tsymcoll = record
         speedvalue : cardinal;
         name : pstring;
         data : pprocdefcoll;
         next : psymcoll;
      end;

      tclassheader=class
      private
        _Class : tobjectdef;
        count  : integer;
      private
        { message tables }
        root : pprocdeftree;
        procedure disposeprocdeftree(p : pprocdeftree);
        procedure insertmsgint(p : tnamedindexitem;arg:pointer);
        procedure insertmsgstr(p : tnamedindexitem;arg:pointer);
        procedure insertint(p : pprocdeftree;var at : pprocdeftree);
        procedure insertstr(p : pprocdeftree;var at : pprocdeftree);
        procedure writenames(p : pprocdeftree);
        procedure writeintentry(p : pprocdeftree);
        procedure writestrentry(p : pprocdeftree);
{$ifdef WITHDMT}
      private
        { dmt }
        procedure insertdmtentry(p : tnamedindexitem;arg:pointer);
        procedure writedmtindexentry(p : pprocdeftree);
        procedure writedmtaddressentry(p : pprocdeftree);
{$endif}
      private
        { published methods }
        procedure do_count(p : tnamedindexitem;arg:pointer);
        procedure genpubmethodtableentry(p : tnamedindexitem;arg:pointer);
      private
        { vmt }
        wurzel : psymcoll;
        nextvirtnumber : integer;
        has_constructor,
        has_virtual_method : boolean;
        procedure eachsym(sym : tnamedindexitem;arg:pointer);
        procedure disposevmttree;
        procedure writevirtualmethods(List:TAAsmoutput);
      private
        { interface tables }
        function  gintfgetvtbllabelname(intfindex: integer): string;
        procedure gintfcreatevtbl(intfindex: integer; rawdata,rawcode: TAAsmoutput);
        procedure gintfgenentry(intfindex, contintfindex: integer; rawdata: TAAsmoutput);
        procedure gintfoptimizevtbls(implvtbl : plongintarray);
        procedure gintfwritedata;
        function  gintfgetcprocdef(proc: tprocdef;const name: string): tprocdef;
        procedure gintfdoonintf(intf: tobjectdef; intfindex: longint);
        procedure gintfwalkdowninterface(intf: tobjectdef; intfindex: longint);
      protected
        { adjusts the self value with ioffset when casting a interface
          to a class
        }
        procedure adjustselfvalue(procdef: tprocdef;ioffset: aint);virtual;
        { generates the wrapper for a call to a method via an interface }
        procedure cgintfwrapper(asmlist: TAAsmoutput; procdef: tprocdef; const labelname: string; ioffset: longint);virtual;abstract;
      public
        constructor create(c:tobjectdef);
        destructor destroy;override;
        { generates the message tables for a class }
        function  genstrmsgtab : tasmlabel;
        function  genintmsgtab : tasmlabel;
        function  genpublishedmethodstable : tasmlabel;
        { generates a VMT entries }
        procedure genvmt;
{$ifdef WITHDMT}
        { generates a DMT for _class }
        function  gendmt : tasmlabel;
{$endif WITHDMT}
        { interfaces }
        function  genintftable: tasmlabel;
        { write the VMT to datasegment }
        procedure writevmt;
        procedure writeinterfaceids;
      end;

      tclassheaderclass=class of tclassheader;

    var
      cclassheader : tclassheaderclass;


implementation

    uses
{$ifdef delphi}
       sysutils,
{$else}
       strings,
{$endif}
       globals,verbose,systems,
       symtable,symconst,symtype,symsym,defcmp,paramgr,
{$ifdef GDB}
       gdb,
{$endif GDB}
       aasmcpu,
       cpubase,cgbase,
       cgutils,cgobj
       ;


{*****************************************************************************
                                TClassHeader
*****************************************************************************}

    constructor tclassheader.create(c:tobjectdef);
      begin
        inherited Create;
        _Class:=c;
      end;


    destructor tclassheader.destroy;
      begin
        disposevmttree;
      end;


{**************************************
           Message Tables
**************************************}

    procedure tclassheader.disposeprocdeftree(p : pprocdeftree);
      begin
         if assigned(p^.l) then
           disposeprocdeftree(p^.l);
         if assigned(p^.r) then
           disposeprocdeftree(p^.r);
         dispose(p);
      end;


    procedure tclassheader.insertint(p : pprocdeftree;var at : pprocdeftree);

      begin
         if at=nil then
           begin
              at:=p;
              inc(count);
           end
         else
           begin
              if p^.data.messageinf.i<at^.data.messageinf.i then
                insertint(p,at^.l)
              else if p^.data.messageinf.i>at^.data.messageinf.i then
                insertint(p,at^.r)
              else
                Message1(parser_e_duplicate_message_label,tostr(p^.data.messageinf.i));
           end;
      end;

    procedure tclassheader.insertstr(p : pprocdeftree;var at : pprocdeftree);

      var
         i : integer;

      begin
         if at=nil then
           begin
              at:=p;
              inc(count);
           end
         else
           begin
              i:=strcomp(p^.data.messageinf.str,at^.data.messageinf.str);
              if i<0 then
                insertstr(p,at^.l)
              else if i>0 then
                insertstr(p,at^.r)
              else
                Message1(parser_e_duplicate_message_label,strpas(p^.data.messageinf.str));
           end;
      end;

    procedure tclassheader.insertmsgint(p : tnamedindexitem;arg:pointer);

      var
         i  : cardinal;
         def: Tprocdef;
         pt : pprocdeftree;

      begin
         if tsym(p).typ=procsym then
            for i:=1 to Tprocsym(p).procdef_count do
              begin
                def:=Tprocsym(p).procdef[i];
                if po_msgint in def.procoptions then
                  begin
                    new(pt);
                    pt^.data:=def;
                    pt^.l:=nil;
                    pt^.r:=nil;
                    insertint(pt,root);
                  end;
              end;
      end;

    procedure tclassheader.insertmsgstr(p : tnamedindexitem;arg:pointer);

      var
         i  : cardinal;
         def: Tprocdef;
         pt : pprocdeftree;

      begin
         if tsym(p).typ=procsym then
            for i:=1 to Tprocsym(p).procdef_count do
              begin
                def:=Tprocsym(p).procdef[i];
                if po_msgstr in def.procoptions then
                  begin
                    new(pt);
                    pt^.data:=def;
                    pt^.l:=nil;
                    pt^.r:=nil;
                    insertstr(pt,root);
                  end;
              end;
      end;

    procedure tclassheader.writenames(p : pprocdeftree);
      var
        ca : pchar;
        len : longint;
      begin
         objectlibrary.getdatalabel(p^.nl);
         if assigned(p^.l) then
           writenames(p^.l);
         datasegment.concat(tai_align.create(const_align(sizeof(aint))));
         dataSegment.concat(Tai_label.Create(p^.nl));
         len:=strlen(p^.data.messageinf.str);
         datasegment.concat(tai_const.create_8bit(len));
         getmem(ca,len+1);
         move(p^.data.messageinf.str^,ca^,len+1);
         dataSegment.concat(Tai_string.Create_pchar(ca));
         if assigned(p^.r) then
           writenames(p^.r);
      end;

    procedure tclassheader.writestrentry(p : pprocdeftree);

      begin
         if assigned(p^.l) then
           writestrentry(p^.l);

         { write name label }
         dataSegment.concat(Tai_const.Create_sym(p^.nl));
         dataSegment.concat(Tai_const.Createname(p^.data.mangledname,AT_FUNCTION,0));

         if assigned(p^.r) then
           writestrentry(p^.r);
     end;


    function tclassheader.genstrmsgtab : tasmlabel;
      var
         r : tasmlabel;
      begin
         root:=nil;
         count:=0;
         { insert all message handlers into a tree, sorted by name }
         _class.symtable.foreach({$ifdef FPCPROCVAR}@{$endif}insertmsgstr,nil);

         { write all names }
         if assigned(root) then
           writenames(root);

         { now start writing of the message string table }
         objectlibrary.getdatalabel(r);
         datasegment.concat(tai_align.create(const_align(sizeof(aint))));
         dataSegment.concat(Tai_label.Create(r));
         genstrmsgtab:=r;
         dataSegment.concat(Tai_const.Create_32bit(count));
         if assigned(root) then
           begin
              writestrentry(root);
              disposeprocdeftree(root);
           end;
      end;


    procedure tclassheader.writeintentry(p : pprocdeftree);
      begin
         if assigned(p^.l) then
           writeintentry(p^.l);

         { write name label }
         dataSegment.concat(Tai_const.Create_32bit(p^.data.messageinf.i));
         dataSegment.concat(Tai_const.Createname(p^.data.mangledname,AT_FUNCTION,0));

         if assigned(p^.r) then
           writeintentry(p^.r);
      end;


    function tclassheader.genintmsgtab : tasmlabel;
      var
         r : tasmlabel;
      begin
         root:=nil;
         count:=0;
         { insert all message handlers into a tree, sorted by name }
         _class.symtable.foreach({$ifdef FPCPROCVAR}@{$endif}insertmsgint,nil);

         { now start writing of the message string table }
         objectlibrary.getdatalabel(r);
         datasegment.concat(tai_align.create(const_align(sizeof(aint))));
         dataSegment.concat(Tai_label.Create(r));
         genintmsgtab:=r;
         dataSegment.concat(Tai_const.Create_32bit(count));
         if assigned(root) then
           begin
              writeintentry(root);
              disposeprocdeftree(root);
           end;
      end;

{$ifdef WITHDMT}

{**************************************
              DMT
**************************************}

    procedure tclassheader.insertdmtentry(p : tnamedindexitem;arg:pointer);

      var
         hp : tprocdef;
         pt : pprocdeftree;

      begin
         if tsym(p).typ=procsym then
           begin
              hp:=tprocsym(p).definition;
              while assigned(hp) do
                begin
                   if (po_msgint in hp.procoptions) then
                     begin
                        new(pt);
                        pt^.p:=hp;
                        pt^.l:=nil;
                        pt^.r:=nil;
                        insertint(pt,root);
                     end;
                   hp:=hp.nextoverloaded;
                end;
           end;
      end;

    procedure tclassheader.writedmtindexentry(p : pprocdeftree);

      begin
         if assigned(p^.l) then
           writedmtindexentry(p^.l);
         dataSegment.concat(Tai_const.Create_32bit(p^.data.messageinf.i));
         if assigned(p^.r) then
           writedmtindexentry(p^.r);
      end;

    procedure tclassheader.writedmtaddressentry(p : pprocdeftree);

      begin
         if assigned(p^.l) then
           writedmtaddressentry(p^.l);
         dataSegment.concat(Tai_const_symbol.Createname(p^.data.mangledname,AT_FUNCTION,0));
         if assigned(p^.r) then
           writedmtaddressentry(p^.r);
      end;

    function tclassheader.gendmt : tasmlabel;

      var
         r : tasmlabel;

      begin
         root:=nil;
         count:=0;
         gendmt:=nil;
         { insert all message handlers into a tree, sorted by number }
         _class.symtable.foreach({$ifdef FPCPROCVAR}@{$endif}insertdmtentry);

         if count>0 then
           begin
              objectlibrary.getdatalabel(r);
              gendmt:=r;
              datasegment.concat(tai_align.create(const_align(sizeof(aint))));
              dataSegment.concat(Tai_label.Create(r));
              { entries for caching }
              dataSegment.concat(Tai_const.Create_ptr(0));
              dataSegment.concat(Tai_const.Create_ptr(0));

              dataSegment.concat(Tai_const.Create_32bit(count));
              if assigned(root) then
                begin
                   writedmtindexentry(root);
                   writedmtaddressentry(root);
                   disposeprocdeftree(root);
                end;
           end;
      end;

{$endif WITHDMT}

{**************************************
        Published Methods
**************************************}

    procedure tclassheader.do_count(p : tnamedindexitem;arg:pointer);

      begin
         if (tsym(p).typ=procsym) and (sp_published in tsym(p).symoptions) then
           inc(count);
      end;

    procedure tclassheader.genpubmethodtableentry(p : tnamedindexitem;arg:pointer);

      var
         hp : tprocdef;
         l : tasmlabel;

      begin
         if (tsym(p).typ=procsym) and (sp_published in tsym(p).symoptions) then
           begin
              if Tprocsym(p).procdef_count>1 then
                internalerror(1209992);
              hp:=tprocsym(p).first_procdef;
              objectlibrary.getdatalabel(l);

              consts.concat(tai_align.create(const_align(sizeof(aint))));
              Consts.concat(Tai_label.Create(l));
              Consts.concat(Tai_const.Create_8bit(length(p.name)));
              Consts.concat(Tai_string.Create(p.name));

              dataSegment.concat(Tai_const.Create_sym(l));
              dataSegment.concat(Tai_const.Createname(hp.mangledname,AT_FUNCTION,0));
           end;
      end;

    function tclassheader.genpublishedmethodstable : tasmlabel;

      var
         l : tasmlabel;

      begin
         count:=0;
         _class.symtable.foreach({$ifdef FPCPROCVAR}@{$endif}do_count,nil);
         if count>0 then
           begin
              objectlibrary.getdatalabel(l);
              datasegment.concat(tai_align.create(const_align(sizeof(aint))));
              dataSegment.concat(Tai_label.Create(l));
              dataSegment.concat(Tai_const.Create_32bit(count));
              _class.symtable.foreach({$ifdef FPCPROCVAR}@{$endif}genpubmethodtableentry,nil);
              genpublishedmethodstable:=l;
           end
         else
           genpublishedmethodstable:=nil;
      end;


{**************************************
               VMT
**************************************}

    procedure tclassheader.eachsym(sym : tnamedindexitem;arg:pointer);

      var
         procdefcoll : pprocdefcoll;
         symcoll : psymcoll;
         _name : string;
         _speed : cardinal;

      procedure newdefentry(pd:tprocdef);
        begin
           new(procdefcoll);
           procdefcoll^.data:=pd;
           procdefcoll^.hidden:=false;
           procdefcoll^.next:=symcoll^.data;
           symcoll^.data:=procdefcoll;

           { if it's a virtual method }
           if (po_virtualmethod in pd.procoptions) then
             begin
                { then it gets a number ... }
                pd.extnumber:=nextvirtnumber;
                { and we inc the number }
                inc(nextvirtnumber);
                has_virtual_method:=true;
             end;

           if (pd.proctypeoption=potype_constructor) then
             has_constructor:=true;

           { check, if a method should be overridden }
           if (pd._class=_class) and
              (po_overridingmethod in pd.procoptions) then
             MessagePos1(pd.fileinfo,parser_e_nothing_to_be_overridden,pd.fullprocname(false));
        end;

      { creates a new entry in the procsym list }
      procedure newentry;

        var i:cardinal;

        begin
           { if not, generate a new symbol item }
           new(symcoll);
           symcoll^.speedvalue:=sym.speedvalue;
           symcoll^.name:=stringdup(sym.name);
           symcoll^.next:=wurzel;
           symcoll^.data:=nil;
           wurzel:=symcoll;

           { inserts all definitions }
           for i:=1 to Tprocsym(sym).procdef_count do
              newdefentry(Tprocsym(sym).procdef[i]);
        end;

      label
         handlenextdef;
      var
         pd : tprocdef;
         i : cardinal;
         is_visible,
         hasoverloads,
         pdoverload : boolean;
      begin
         { put only sub routines into the VMT, and routines
           that are visible to the current class. Skip private
           methods in other classes }
         if (tsym(sym).typ=procsym) then
           begin
              { is this symbol visible from the class that we are
                generating. This will be used to hide the other procdefs.
                When the symbol is not visible we don't hide the other
                procdefs, because they can be reused in the next class.
                The check to skip the invisible methods that are in the
                list is futher down in the code }
              is_visible:=tprocsym(sym).is_visible_for_object(_class);
              { check the current list of symbols }
              _name:=sym.name;
              _speed:=sym.speedvalue;
              symcoll:=wurzel;
              while assigned(symcoll) do
               begin
                 { does the symbol already exist in the list? First
                   compare speedvalue before doing the string compare to
                   speed it up a little }
                 if (_speed=symcoll^.speedvalue) and
                    (_name=symcoll^.name^) then
                  begin
                    hasoverloads:=(Tprocsym(sym).procdef_count>1);
                    { walk through all defs of the symbol }
                    for i:=1 to Tprocsym(sym).procdef_count do
                      begin
                       pd:=Tprocsym(sym).procdef[i];
                       if pd.procsym=sym then
                        begin
                          pdoverload:=(po_overload in pd.procoptions);

                          { compare with all stored definitions }
                          procdefcoll:=symcoll^.data;
                          while assigned(procdefcoll) do
                            begin
                               { compare only if the definition is not hidden }
                               if not procdefcoll^.hidden then
                                begin
                                  { check that all methods have overload directive }
                                  if not(m_fpc in aktmodeswitches) and
                                     (_class=pd._class) and
                                     (procdefcoll^.data._class=pd._class) and
                                     ((po_overload in pd.procoptions)<>(po_overload in procdefcoll^.data.procoptions)) then
                                    begin
                                      MessagePos1(pd.fileinfo,parser_e_no_overload_for_all_procs,pd.procsym.realname);
                                      { recover }
                                      include(procdefcoll^.data.procoptions,po_overload);
                                      include(pd.procoptions,po_overload);
                                    end;

                                  { check if one of the two methods has virtual }
                                  if (po_virtualmethod in procdefcoll^.data.procoptions) or
                                     (po_virtualmethod in pd.procoptions) then
                                   begin
                                     { if the current definition has no virtual then hide the
                                       old virtual if the new definition has the same arguments or
                                       when it has no overload directive and no overloads }
                                     if not(po_virtualmethod in pd.procoptions) then
                                      begin
                                        if tstoredsym(procdefcoll^.data.procsym).is_visible_for_object(pd._class) and
                                           (not(pdoverload or hasoverloads) or
                                            (compare_paras(procdefcoll^.data.para,pd.para,cp_all,[])>=te_equal)) then
                                         begin
                                           if is_visible then
                                             procdefcoll^.hidden:=true;
                                           if (_class=pd._class) and not(po_reintroduce in pd.procoptions) then
                                             MessagePos1(pd.fileinfo,parser_w_should_use_override,pd.fullprocname(false));
                                         end;
                                      end
                                     { if both are virtual we check the header }
                                     else if (po_virtualmethod in pd.procoptions) and
                                             (po_virtualmethod in procdefcoll^.data.procoptions) then
                                      begin
                                        { new one has not override }
                                        if is_class(_class) and
                                           not(po_overridingmethod in pd.procoptions) then
                                         begin
                                           { we start a new virtual tree, hide the old }
                                           if (not(pdoverload or hasoverloads) or
                                               (compare_paras(procdefcoll^.data.para,pd.para,cp_all,[])>=te_equal)) and
                                              (tstoredsym(procdefcoll^.data.procsym).is_visible_for_object(pd._class)) then
                                            begin
                                              if is_visible then
                                                procdefcoll^.hidden:=true;
                                              if (_class=pd._class) and not(po_reintroduce in pd.procoptions) then
                                                MessagePos1(pd.fileinfo,parser_w_should_use_override,pd.fullprocname(false));
                                            end;
                                         end
                                        { check if the method to override is visible, check is only needed
                                          for the current parsed class. Parent classes are already validated and
                                          need to include all virtual methods including the ones not visible in the
                                          current class }
                                        else if (_class=pd._class) and
                                                (po_overridingmethod in pd.procoptions) and
                                                (not tstoredsym(procdefcoll^.data.procsym).is_visible_for_object(pd._class)) then
                                         begin
                                           { do nothing, the error will follow when adding the entry }
                                         end
                                        { same parameters }
                                        else if (compare_paras(procdefcoll^.data.para,pd.para,cp_all,[])>=te_equal) then
                                         begin
                                           { overload is inherited }
                                           if (po_overload in procdefcoll^.data.procoptions) then
                                            include(pd.procoptions,po_overload);

                                           { inherite calling convention when it was force and the
                                             current definition has none force }
                                           if (po_hascallingconvention in procdefcoll^.data.procoptions) and
                                              not(po_hascallingconvention in pd.procoptions) then
                                             begin
                                               pd.proccalloption:=procdefcoll^.data.proccalloption;
                                               include(pd.procoptions,po_hascallingconvention);
                                             end;

                                           { the flags have to match except abstract and override }
                                           { only if both are virtual !!  }
                                           if (procdefcoll^.data.proccalloption<>pd.proccalloption) or
                                               (procdefcoll^.data.proctypeoption<>pd.proctypeoption) or
                                               ((procdefcoll^.data.procoptions-
                                                   [po_abstractmethod,po_overridingmethod,po_assembler,po_overload,po_public,po_reintroduce])<>
                                                (pd.procoptions-[po_abstractmethod,po_overridingmethod,po_assembler,po_overload,po_public,po_reintroduce])) then
                                              begin
                                                MessagePos1(pd.fileinfo,parser_e_header_dont_match_forward,pd.fullprocname(false));
                                                tprocsym(procdefcoll^.data.procsym).write_parameter_lists(pd);
                                              end;

                                           { error, if the return types aren't equal }
                                           if not(equal_defs(procdefcoll^.data.rettype.def,pd.rettype.def)) and
                                              not((procdefcoll^.data.rettype.def.deftype=objectdef) and
                                               (pd.rettype.def.deftype=objectdef) and
                                               is_class(procdefcoll^.data.rettype.def) and
                                               is_class(pd.rettype.def) and
                                               (tobjectdef(pd.rettype.def).is_related(
                                                   tobjectdef(procdefcoll^.data.rettype.def)))) then
                                             Message2(parser_e_overridden_methods_not_same_ret,pd.fullprocname(false),
                                                      procdefcoll^.data.fullprocname(false));

                                           { now set the number }
                                           pd.extnumber:=procdefcoll^.data.extnumber;
                                           { and exchange }
                                           procdefcoll^.data:=pd;
                                           goto handlenextdef;
                                         end
                                        { different parameters }
                                        else
                                         begin
                                           { when we got an override directive then can search futher for
                                             the procedure to override.
                                             If we are starting a new virtual tree then hide the old tree }
                                           if not(po_overridingmethod in pd.procoptions) and
                                              not pdoverload then
                                            begin
                                              if is_visible then
                                                procdefcoll^.hidden:=true;
                                              if (_class=pd._class) and not(po_reintroduce in pd.procoptions) then
                                                MessagePos1(pd.fileinfo,parser_w_should_use_override,pd.fullprocname(false));
                                            end;
                                         end;
                                      end
                                     else
                                      begin
                                        { the new definition is virtual and the old static, we hide the old one
                                          if the new defintion has not the overload directive }
                                        if is_visible and
                                           ((not(pdoverload or hasoverloads)) or
                                            (compare_paras(procdefcoll^.data.para,pd.para,cp_all,[])>=te_equal)) then
                                          procdefcoll^.hidden:=true;
                                      end;
                                   end
                                  else
                                   begin
                                     { both are static, we hide the old one if the new defintion
                                       has not the overload directive }
                                     if is_visible and
                                        ((not pdoverload) or
                                         (compare_paras(procdefcoll^.data.para,pd.para,cp_all,[])>=te_equal)) then
                                       procdefcoll^.hidden:=true;
                                   end;
                                end; { not hidden }
                               procdefcoll:=procdefcoll^.next;
                            end;

                          { if it isn't saved in the list we create a new entry }
                          newdefentry(pd);
                        end;
                     handlenextdef:
                     end;
                    exit;
                  end;
                 symcoll:=symcoll^.next;
               end;
             newentry;
           end;
      end;

     procedure tclassheader.disposevmttree;

       var
          symcoll : psymcoll;
          procdefcoll : pprocdefcoll;

       begin
          { disposes the above generated tree }
          symcoll:=wurzel;
          while assigned(symcoll) do
            begin
               wurzel:=symcoll^.next;
               stringdispose(symcoll^.name);
               procdefcoll:=symcoll^.data;
               while assigned(procdefcoll) do
                 begin
                    symcoll^.data:=procdefcoll^.next;
                    dispose(procdefcoll);
                    procdefcoll:=symcoll^.data;
                 end;
               dispose(symcoll);
               symcoll:=wurzel;
            end;
       end;


    procedure tclassheader.genvmt;

      procedure do_genvmt(p : tobjectdef);

        begin
           { start with the base class }
           if assigned(p.childof) then
             do_genvmt(p.childof);

           { walk through all public syms }
           p.symtable.foreach({$ifdef FPCPROCVAR}@{$endif}eachsym,nil);
        end;

      begin
         wurzel:=nil;
         nextvirtnumber:=0;

         has_constructor:=false;
         has_virtual_method:=false;

         { generates a tree of all used methods }
         do_genvmt(_class);

         if not(is_interface(_class)) and
            has_virtual_method and
            not(has_constructor) then
           Message1(parser_w_virtual_without_constructor,_class.objrealname^);
      end;


{**************************************
           Interface tables
**************************************}

    function  tclassheader.gintfgetvtbllabelname(intfindex: integer): string;
      begin
        gintfgetvtbllabelname:=make_mangledname('VTBL',_class.owner,_class.objname^+
                               '_$_'+_class.implementedinterfaces.interfaces(intfindex).objname^);
      end;


    procedure tclassheader.gintfcreatevtbl(intfindex: integer; rawdata,rawcode: TAAsmoutput);
      var
        implintf: timplementedinterfaces;
        curintf: tobjectdef;
        proccount: integer;
        tmps: string;
        i: longint;
      begin
        implintf:=_class.implementedinterfaces;
        curintf:=implintf.interfaces(intfindex);
        rawdata.concat(tai_align.create(const_align(sizeof(aint))));
        if maybe_smartlink_symbol then
         rawdata.concat(Tai_symbol.Createname_global(gintfgetvtbllabelname(intfindex),AT_DATA ,0))
        else
         rawdata.concat(Tai_symbol.Createname(gintfgetvtbllabelname(intfindex),AT_DATA,0));
        proccount:=implintf.implproccount(intfindex);
        for i:=1 to proccount do
          begin
            tmps:=make_mangledname('WRPR',_class.owner,_class.objname^+'_$_'+curintf.objname^+'_$_'+
              tostr(i)+'_$_'+
              implintf.implprocs(intfindex,i).mangledname);
            { create wrapper code }
            cgintfwrapper(rawcode,implintf.implprocs(intfindex,i),tmps,implintf.ioffsets(intfindex)^);
            { create reference }
            rawdata.concat(Tai_const.Createname(tmps,AT_FUNCTION,0));
          end;
      end;


    procedure tclassheader.gintfgenentry(intfindex, contintfindex: integer; rawdata: TAAsmoutput);
      var
        implintf: timplementedinterfaces;
        curintf: tobjectdef;
        tmplabel: tasmlabel;
        i: longint;
      begin
        implintf:=_class.implementedinterfaces;
        curintf:=implintf.interfaces(intfindex);
        { GUID }
        if curintf.objecttype in [odt_interfacecom] then
          begin
            { label for GUID }
            objectlibrary.getdatalabel(tmplabel);
            rawdata.concat(tai_align.create(const_align(sizeof(aint))));
            rawdata.concat(Tai_label.Create(tmplabel));
            rawdata.concat(Tai_const.Create_32bit(longint(curintf.iidguid^.D1)));
            rawdata.concat(Tai_const.Create_16bit(curintf.iidguid^.D2));
            rawdata.concat(Tai_const.Create_16bit(curintf.iidguid^.D3));
            for i:=Low(curintf.iidguid^.D4) to High(curintf.iidguid^.D4) do
              rawdata.concat(Tai_const.Create_8bit(curintf.iidguid^.D4[i]));
            dataSegment.concat(Tai_const.Create_sym(tmplabel));
          end
        else
          begin
            { nil for Corba interfaces }
            dataSegment.concat(Tai_const.Create_sym(nil));
          end;
        { VTable }
        dataSegment.concat(Tai_const.Createname(gintfgetvtbllabelname(contintfindex),AT_DATA,0));
        { IOffset field }
        dataSegment.concat(Tai_const.Create_32bit(implintf.ioffsets(contintfindex)^));
        { IIDStr }
        objectlibrary.getdatalabel(tmplabel);
        rawdata.concat(tai_align.create(const_align(sizeof(aint))));
        rawdata.concat(Tai_label.Create(tmplabel));
        rawdata.concat(Tai_const.Create_8bit(length(curintf.iidstr^)));
        if curintf.objecttype=odt_interfacecom then
          rawdata.concat(Tai_string.Create(upper(curintf.iidstr^)))
        else
          rawdata.concat(Tai_string.Create(curintf.iidstr^));
        dataSegment.concat(Tai_const.Create_sym(tmplabel));
      end;


    procedure tclassheader.gintfoptimizevtbls(implvtbl : plongintarray);
      type
        tcompintfentry = record
          weight: longint;
          compintf: longint;
        end;
        { Max 1000 interface in the class header interfaces it's enough imho }
        tcompintfs = packed array[1..1000] of tcompintfentry;
        pcompintfs = ^tcompintfs;
        tequals    = packed array[1..1000] of longint;
        pequals    = ^tequals;
      var
        max: longint;
        equals: pequals;
        compats: pcompintfs;
        i: longint;
        j: longint;
        w: longint;
        cij: boolean;
        cji: boolean;
      begin
        max:=_class.implementedinterfaces.count;
        if max>High(tequals) then
          Internalerror(200006135);
        getmem(compats,sizeof(tcompintfentry)*max);
        getmem(equals,sizeof(longint)*max);
        fillchar(compats^,sizeof(tcompintfentry)*max,0);
        fillchar(equals^,sizeof(longint)*max,0);
        { ismergepossible is a containing relation
          meaning of ismergepossible(a,b,w) =
          if implementorfunction map of a is contained implementorfunction map of b
          imp(a,b) and imp(b,c) => imp(a,c) ; imp(a,b) and imp(b,a) => a == b
        }
        { the order is very important for correct allocation }
        for i:=1 to max do
          begin
            for j:=i+1 to max do
              begin
                cij:=_class.implementedinterfaces.isimplmergepossible(i,j,w);
                cji:=_class.implementedinterfaces.isimplmergepossible(j,i,w);
                if cij and cji then { i equal j }
                  begin
                    { get minimum index of equal }
                    if equals^[j]=0 then
                      equals^[j]:=i;
                  end
                else if cij then
                  begin
                    { get minimum index of maximum weight  }
                    if compats^[i].weight<w then
                      begin
                        compats^[i].weight:=w;
                        compats^[i].compintf:=j;
                      end;
                  end
                else if cji then
                  begin
                    { get minimum index of maximum weight  }
                    if (compats^[j].weight<w) then
                      begin
                        compats^[j].weight:=w;
                        compats^[j].compintf:=i;
                      end;
                  end;
              end;
          end;
        for i:=1 to max do
          begin
            if compats^[i].compintf<>0 then
              implvtbl[i]:=compats^[i].compintf
            else if equals^[i]<>0 then
              implvtbl[i]:=equals^[i]
            else
              implvtbl[i]:=i;
          end;
        freemem(compats,sizeof(tcompintfentry)*max);
        freemem(equals,sizeof(longint)*max);
      end;


    procedure tclassheader.gintfwritedata;
      var
        rawdata,rawcode: taasmoutput;
        impintfindexes: plongintarray;
        max: longint;
        i: longint;
      begin
        max:=_class.implementedinterfaces.count;
        getmem(impintfindexes,(max+1)*sizeof(longint));

        gintfoptimizevtbls(impintfindexes);

        rawdata:=TAAsmOutput.Create;
        rawcode:=TAAsmOutput.Create;
        dataSegment.concat(Tai_const.Create_16bit(max));
        { Two pass, one for allocation and vtbl creation }
        for i:=1 to max do
          begin
            if impintfindexes[i]=i then { if implement itself }
              begin
                { allocate a pointer in the object memory }
                with tobjectsymtable(_class.symtable) do
                  begin
                    datasize:=align(datasize,min(sizeof(aint),fieldalignment));
                    _class.implementedinterfaces.ioffsets(i)^:=datasize;
                    inc(datasize,sizeof(aint));
                  end;
                { write vtbl }
                gintfcreatevtbl(i,rawdata,rawcode);
              end;
          end;
        { second pass: for fill interfacetable and remained ioffsets }
        for i:=1 to max do
          begin
            if i<>impintfindexes[i] then { why execute x:=x ? }
              with _class.implementedinterfaces do
                ioffsets(i)^:=ioffsets(impintfindexes[i])^;
            gintfgenentry(i,impintfindexes[i],rawdata);
          end;
        dataSegment.concatlist(rawdata);
        rawdata.free;
        codeSegment.concatlist(rawcode);
        rawcode.free;
        freemem(impintfindexes,(max+1)*sizeof(longint));
      end;


    function tclassheader.gintfgetcprocdef(proc: tprocdef;const name: string): tprocdef;
      var
        sym: tsym;
        implprocdef : Tprocdef;
        i: cardinal;
      begin
        gintfgetcprocdef:=nil;

        sym:=tsym(search_class_member(_class,name));
        if assigned(sym) and
           (sym.typ=procsym) then
          begin
            { when the definition has overload directive set, we search for
              overloaded definitions in the class, this only needs to be done once
              for class entries as the tree keeps always the same }
            if (not tprocsym(sym).overloadchecked) and
               (po_overload in tprocsym(sym).first_procdef.procoptions) and
               (tprocsym(sym).owner.symtabletype=objectsymtable) then
             search_class_overloads(tprocsym(sym));

            for i:=1 to tprocsym(sym).procdef_count do
              begin
                implprocdef:=tprocsym(sym).procdef[i];
                if (compare_paras(proc.para,implprocdef.para,cp_none,[])>=te_equal) and
                   (proc.proccalloption=implprocdef.proccalloption) then
                  begin
                    gintfgetcprocdef:=implprocdef;
                    exit;
                  end;
              end;
          end;
      end;


    procedure tclassheader.gintfdoonintf(intf: tobjectdef; intfindex: longint);
      var
        def: tdef;
        procname: string; { for error }
        mappedname: string;
        nextexist: pointer;
        implprocdef: tprocdef;
      begin
        def:=tdef(intf.symtable.defindex.first);
        while assigned(def) do
          begin
            if def.deftype=procdef then
              begin
                procname:='';
                implprocdef:=nil;
                nextexist:=nil;
                repeat
                  mappedname:=_class.implementedinterfaces.getmappings(intfindex,tprocdef(def).procsym.name,nextexist);
                  if procname='' then
                    procname:=tprocdef(def).procsym.name;
                    //mappedname; { for error messages }
                  if mappedname<>'' then
                    implprocdef:=gintfgetcprocdef(tprocdef(def),mappedname);
                until assigned(implprocdef) or not assigned(nextexist);
                if not assigned(implprocdef) then
                  implprocdef:=gintfgetcprocdef(tprocdef(def),tprocdef(def).procsym.name);
                if procname='' then
                  procname:=tprocdef(def).procsym.name;
                if assigned(implprocdef) then
                  _class.implementedinterfaces.addimplproc(intfindex,implprocdef)
                else
                  Message1(sym_e_no_matching_implementation_found,tprocdef(def).fullprocname(false));
              end;
            def:=tdef(def.indexnext);
          end;
      end;


    procedure tclassheader.gintfwalkdowninterface(intf: tobjectdef; intfindex: longint);
      begin
        if assigned(intf.childof) then
          gintfwalkdowninterface(intf.childof,intfindex);
        gintfdoonintf(intf,intfindex);
      end;


    function tclassheader.genintftable: tasmlabel;
      var
        intfindex: longint;
        curintf: tobjectdef;
        intftable: tasmlabel;
      begin
        { 1. step collect implementor functions into the implementedinterfaces.implprocs }
        for intfindex:=1 to _class.implementedinterfaces.count do
          begin
            curintf:=_class.implementedinterfaces.interfaces(intfindex);
            gintfwalkdowninterface(curintf,intfindex);
          end;
        { 2. step calc required fieldcount and their offsets in the object memory map
             and write data }
        objectlibrary.getdatalabel(intftable);
        dataSegment.concat(tai_align.create(const_align(sizeof(aint))));
        dataSegment.concat(Tai_label.Create(intftable));
        gintfwritedata;
        _class.implementedinterfaces.clearimplprocs; { release temporary information }
        genintftable:=intftable;
      end;


  { Write interface identifiers to the data section }
  procedure tclassheader.writeinterfaceids;
    var
      i : longint;
      s : string;
    begin
      if assigned(_class.iidguid) then
        begin
          s:=make_mangledname('IID',_class.owner,_class.objname^);
          maybe_new_object_file(dataSegment);
          new_section(dataSegment,sec_rodata,s,const_align(sizeof(aint)));
          dataSegment.concat(Tai_symbol.Createname_global(s,AT_DATA,0));
          dataSegment.concat(Tai_const.Create_32bit(longint(_class.iidguid^.D1)));
          dataSegment.concat(Tai_const.Create_16bit(_class.iidguid^.D2));
          dataSegment.concat(Tai_const.Create_16bit(_class.iidguid^.D3));
          for i:=Low(_class.iidguid^.D4) to High(_class.iidguid^.D4) do
            dataSegment.concat(Tai_const.Create_8bit(_class.iidguid^.D4[i]));
        end;
      maybe_new_object_file(dataSegment);
      s:=make_mangledname('IIDSTR',_class.owner,_class.objname^);
      new_section(dataSegment,sec_rodata,s,0);
      dataSegment.concat(Tai_symbol.Createname_global(s,AT_DATA,0));
      dataSegment.concat(Tai_const.Create_8bit(length(_class.iidstr^)));
      dataSegment.concat(Tai_string.Create(_class.iidstr^));
    end;


    procedure tclassheader.writevirtualmethods(List:TAAsmoutput);
      var
         symcoll : psymcoll;
         procdefcoll : pprocdefcoll;
         i : longint;
      begin
         { walk trough all numbers for virtual methods and search }
         { the method                                             }
         for i:=0 to nextvirtnumber-1 do
           begin
              symcoll:=wurzel;

              { walk trough all symbols }
              while assigned(symcoll) do
                begin

                   { walk trough all methods }
                   procdefcoll:=symcoll^.data;
                   while assigned(procdefcoll) do
                     begin
                        { writes the addresses to the VMT }
                        { but only this which are declared as virtual }
                        if procdefcoll^.data.extnumber=i then
                          begin
                             if (po_virtualmethod in procdefcoll^.data.procoptions) then
                               begin
                                  { if a method is abstract, then is also the }
                                  { class abstract and it's not allow to      }
                                  { generates an instance                     }
                                  if (po_abstractmethod in procdefcoll^.data.procoptions) then
                                    List.concat(Tai_const.Createname('FPC_ABSTRACTERROR',AT_FUNCTION,0))
                                  else
                                    List.concat(Tai_const.createname(procdefcoll^.data.mangledname,AT_FUNCTION,0));
                               end;
                          end;
                        procdefcoll:=procdefcoll^.next;
                     end;
                   symcoll:=symcoll^.next;
                end;
           end;
      end;

    { generates the vmt for classes as well as for objects }
    procedure tclassheader.writevmt;

      var
         methodnametable,intmessagetable,
         strmessagetable,classnamelabel,
         fieldtablelabel : tasmlabel;
{$ifdef WITHDMT}
         dmtlabel : tasmlabel;
{$endif WITHDMT}
         interfacetable : tasmlabel;
      begin
{$ifdef WITHDMT}
         dmtlabel:=gendmt;
{$endif WITHDMT}

         { write tables for classes, this must be done before the actual
           class is written, because we need the labels defined }
         if is_class(_class) then
          begin
            objectlibrary.getdatalabel(classnamelabel);
            maybe_new_object_file(dataSegment);
            new_section(dataSegment,sec_rodata,classnamelabel.name,const_align(sizeof(aint)));

            { interface table }
            if _class.implementedinterfaces.count>0 then
              interfacetable:=genintftable;

            methodnametable:=genpublishedmethodstable;
            fieldtablelabel:=_class.generate_field_table;
            { write class name }
            dataSegment.concat(Tai_label.Create(classnamelabel));
            dataSegment.concat(Tai_const.Create_8bit(length(_class.objrealname^)));
            dataSegment.concat(Tai_string.Create(_class.objrealname^));

            { generate message and dynamic tables }
            if (oo_has_msgstr in _class.objectoptions) then
              strmessagetable:=genstrmsgtab;
            if (oo_has_msgint in _class.objectoptions) then
              intmessagetable:=genintmsgtab;
          end;

        { write debug info }
        maybe_new_object_file(dataSegment);
        new_section(dataSegment,sec_rodata,_class.vmt_mangledname,const_align(sizeof(aint)));
{$ifdef GDB}
        if (cs_debuginfo in aktmoduleswitches) then
         begin
           do_count_dbx:=true;
           if assigned(_class.owner) and assigned(_class.owner.name) then
             dataSegment.concat(Tai_stabs.Create(strpnew('"vmt_'+_class.owner.name^+_class.name+':S'+
               tstoreddef(vmttype.def).numberstring+'",'+tostr(N_STSYM)+',0,0,'+_class.vmt_mangledname)));
         end;
{$endif GDB}
         dataSegment.concat(Tai_symbol.Createname_global(_class.vmt_mangledname,AT_DATA,0));

         { determine the size with symtable.datasize, because }
         { size gives back 4 for classes                    }
         dataSegment.concat(Tai_const.Create(ait_const_ptr,tobjectsymtable(_class.symtable).datasize));
         dataSegment.concat(Tai_const.Create(ait_const_ptr,-int64(tobjectsymtable(_class.symtable).datasize)));
{$ifdef WITHDMT}
         if _class.classtype=ct_object then
           begin
              if assigned(dmtlabel) then
                dataSegment.concat(Tai_const_symbol.Create(dmtlabel)))
              else
                dataSegment.concat(Tai_const.Create_ptr(0));
           end;
{$endif WITHDMT}
         { write pointer to parent VMT, this isn't implemented in TP }
         { but this is not used in FPC ? (PM) }
         { it's not used yet, but the delphi-operators as and is need it (FK) }
         { it is not written for parents that don't have any vmt !! }
         if assigned(_class.childof) and
            (oo_has_vmt in _class.childof.objectoptions) then
           dataSegment.concat(Tai_const.Createname(_class.childof.vmt_mangledname,AT_DATA,0))
         else
           dataSegment.concat(Tai_const.Create_sym(nil));

         { write extended info for classes, for the order see rtl/inc/objpash.inc }
         if is_class(_class) then
          begin
            { pointer to class name string }
            dataSegment.concat(Tai_const.Create_sym(classnamelabel));
            { pointer to dynamic table or nil }
            if (oo_has_msgint in _class.objectoptions) then
              dataSegment.concat(Tai_const.Create_sym(intmessagetable))
            else
              dataSegment.concat(Tai_const.Create_sym(nil));
            { pointer to method table or nil }
            dataSegment.concat(Tai_const.Create_sym(methodnametable));
            { pointer to field table }
            dataSegment.concat(Tai_const.Create_sym(fieldtablelabel));
            { pointer to type info of published section }
            if (oo_can_have_published in _class.objectoptions) then
              dataSegment.concat(Tai_const.Create_sym(_class.get_rtti_label(fullrtti)))
            else
              dataSegment.concat(Tai_const.Create_sym(nil));
            { inittable for con-/destruction }
            if _class.members_need_inittable then
              dataSegment.concat(Tai_const.Create_sym(_class.get_rtti_label(initrtti)))
            else
              dataSegment.concat(Tai_const.Create_sym(nil));
            { auto table }
            dataSegment.concat(Tai_const.Create_sym(nil));
            { interface table }
            if _class.implementedinterfaces.count>0 then
              dataSegment.concat(Tai_const.Create_sym(interfacetable))
            else
              dataSegment.concat(Tai_const.Create_sym(nil));
            { table for string messages }
            if (oo_has_msgstr in _class.objectoptions) then
              dataSegment.concat(Tai_const.Create_sym(strmessagetable))
            else
              dataSegment.concat(Tai_const.Create_sym(nil));
          end;
         { write virtual methods }
         writevirtualmethods(dataSegment);
         { write the size of the VMT }
         dataSegment.concat(Tai_symbol_end.Createname(_class.vmt_mangledname));
      end;


  procedure tclassheader.adjustselfvalue(procdef: tprocdef;ioffset: aint);
    var
      hsym : tsym;
      href : treference;
      locpara : tparalocation;
    begin
      { calculate the parameter info for the procdef }
      if not procdef.has_paraloc_info then
        begin
          procdef.requiredargarea:=paramanager.create_paraloc_info(procdef,callerside);
          procdef.has_paraloc_info:=true;
        end;
      hsym:=tsym(procdef.parast.search('self'));
      if not(assigned(hsym) and
             (hsym.typ=varsym) and
             assigned(tvarsym(hsym).paraitem)) then
        internalerror(200305251);
      locpara:=tvarsym(hsym).paraitem.paraloc[callerside];
      case locpara.loc of
        LOC_REGISTER:
          cg.a_op_const_reg(exprasmlist,OP_SUB,locpara.size,ioffset,locpara.register);
        LOC_REFERENCE:
          begin
             { offset in the wrapper needs to be adjusted for the stored
               return address }
             reference_reset_base(href,locpara.reference.index,locpara.reference.offset+sizeof(aint));
             cg.a_op_const_ref(exprasmlist,OP_SUB,locpara.size,ioffset,href);
          end
        else
          internalerror(200309189);
      end;
    end;


initialization
  cclassheader:=tclassheader;
end.
{
  $Log$
  Revision 1.74  2004-07-09 22:17:32  peter
    * revert has_localst patch
    * replace aktstaticsymtable/aktglobalsymtable with current_module

  Revision 1.73  2004/07/06 20:58:50  peter
    * ignore po_haslocalst

  Revision 1.72  2004/06/29 20:58:46  peter
    * fix writing of private virtual/overriden methods that aren't
      visibile in the current class, bug 3184

  Revision 1.71  2004/06/20 08:55:29  florian
    * logs truncated

  Revision 1.70  2004/06/16 20:07:09  florian
    * dwarf branch merged

  Revision 1.69.2.8  2004/05/10 21:28:34  peter
    * section_smartlink enabled for gas under linux

  Revision 1.69.2.7  2004/05/01 16:02:09  peter
    * POINTER_SIZE replaced with sizeof(aint)
    * aint,aword,tconst*int moved to globtype

  Revision 1.69.2.6  2004/04/28 20:36:13  florian
    * fixed writing of sizes in classes/object vmts

  Revision 1.69.2.5  2004/04/27 18:18:26  peter
    * aword -> aint

}
