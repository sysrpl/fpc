{
    $Id$
    Copyright (c) 1998-2000 by Florian Klaempfl

    Generate i386 assembler for in call nodes

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published bymethodpointer
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
unit n386cal;

{$i defines.inc}

interface

{ $define AnsiStrRef}

    uses
      symdef,node,ncal;

    type
       ti386callparanode = class(tcallparanode)
          procedure secondcallparan(defcoll : pparaitem;
                   push_from_left_to_right,inlined,is_cdecl : boolean;
                   para_alignment,para_offset : longint);override;
       end;

       ti386callnode = class(tcallnode)
          procedure pass_2;override;
       end;

       ti386procinlinenode = class(tprocinlinenode)
          procedure pass_2;override;
       end;

implementation

    uses
{$ifdef delphi}
      sysutils,
{$else}
      strings,
{$endif}
      globtype,systems,
      cutils,cobjects,verbose,globals,
      symconst,symbase,symtype,symsym,symtable,aasm,types,
{$ifdef GDB}
      gdb,
{$endif GDB}
      hcodegen,temp_gen,pass_2,
      cpubase,cpuasm,
      nmem,nld,
      cgai386,tgeni386,n386ld,n386util;

{*****************************************************************************
                             TI386CALLPARANODE
*****************************************************************************}

    procedure ti386callparanode.secondcallparan(defcoll : pparaitem;
                push_from_left_to_right,inlined,is_cdecl : boolean;para_alignment,para_offset : longint);

      procedure maybe_push_high;
        begin
           { open array ? }
           { defcoll^.data can be nil for read/write }
           if assigned(defcoll^.paratype.def) and
              push_high_param(defcoll^.paratype.def) then
             begin
               if assigned(hightree) then
                begin
                  secondpass(hightree);
                  { this is a longint anyway ! }
                  push_value_para(hightree,inlined,false,para_offset,4);
                end
               else
                internalerror(432645);
             end;
        end;

      var
         otlabel,oflabel : pasmlabel;
         { temporary variables: }
         tempdeftype : tdeftype;
         r : preference;

      begin
         { set default para_alignment to target_os.stackalignment }
         if para_alignment=0 then
          para_alignment:=target_os.stackalignment;

         { push from left to right if specified }
         if push_from_left_to_right and assigned(right) then
           tcallparanode(right).secondcallparan(pparaitem(defcoll^.next),push_from_left_to_right,
             inlined,is_cdecl,para_alignment,para_offset);
         otlabel:=truelabel;
         oflabel:=falselabel;
         getlabel(truelabel);
         getlabel(falselabel);
         secondpass(left);
         { filter array constructor with c styled args }
         if is_array_constructor(left.resulttype) and (nf_cargs in left.flags) then
           begin
             { nothing, everything is already pushed }
           end
         { in codegen.handleread.. defcoll^.data is set to nil }
         else if assigned(defcoll^.paratype.def) and
           (defcoll^.paratype.def^.deftype=formaldef) then
           begin
              { allow @var }
              inc(pushedparasize,4);
              if (left.nodetype=addrn) and
                 (not(nf_procvarload in left.flags)) then
                begin
                { always a register }
                  if inlined then
                    begin
                       r:=new_reference(procinfo^.framepointer,para_offset-pushedparasize);
                       emit_reg_ref(A_MOV,S_L,
                         left.location.register,r);
                    end
                  else
                    emit_reg(A_PUSH,S_L,left.location.register);
                  ungetregister32(left.location.register);
                end
              else
                begin
                   if not(left.location.loc in [LOC_MEM,LOC_REFERENCE]) then
                     CGMessage(type_e_mismatch)
                   else
                     begin
                       if inlined then
                         begin
                           getexplicitregister32(R_EDI);
                           emit_ref_reg(A_LEA,S_L,
                             newreference(left.location.reference),R_EDI);
                           r:=new_reference(procinfo^.framepointer,para_offset-pushedparasize);
                           emit_reg_ref(A_MOV,S_L,R_EDI,r);
                           ungetregister32(R_EDI);
                         end
                      else
                        emitpushreferenceaddr(left.location.reference);
                        del_reference(left.location.reference);
                     end;
                end;
           end
         { handle call by reference parameter }
         else if (defcoll^.paratyp in [vs_var,vs_out]) then
           begin
              if (left.location.loc<>LOC_REFERENCE) then
                CGMessage(cg_e_var_must_be_reference);
              maybe_push_high;
              if (defcoll^.paratyp=vs_out) and
                 assigned(defcoll^.paratype.def) and
                 not is_class(defcoll^.paratype.def) and
                 defcoll^.paratype.def^.needs_inittable then
                finalize(defcoll^.paratype.def,left.location.reference,false);
              inc(pushedparasize,4);
              if inlined then
                begin
                   getexplicitregister32(R_EDI);
                   emit_ref_reg(A_LEA,S_L,
                     newreference(left.location.reference),R_EDI);
                   r:=new_reference(procinfo^.framepointer,para_offset-pushedparasize);
                   emit_reg_ref(A_MOV,S_L,R_EDI,r);
                   ungetregister32(R_EDI);
                end
              else
                emitpushreferenceaddr(left.location.reference);
              del_reference(left.location.reference);
           end
         else
           begin
              tempdeftype:=resulttype^.deftype;
              if tempdeftype=filedef then
               CGMessage(cg_e_file_must_call_by_reference);
              { open array must always push the address, this is needed to
                also push addr of small open arrays and with cdecl functions (PFV) }
              if (
                  assigned(defcoll^.paratype.def) and
                  (is_open_array(defcoll^.paratype.def) or
                   is_array_of_const(defcoll^.paratype.def))
                 ) or
                 (
                  push_addr_param(resulttype) and
                  not is_cdecl
                 ) then
                begin
                   maybe_push_high;
                   inc(pushedparasize,4);
                   if inlined then
                     begin
                        getexplicitregister32(R_EDI);
                        emit_ref_reg(A_LEA,S_L,
                          newreference(left.location.reference),R_EDI);
                        r:=new_reference(procinfo^.framepointer,para_offset-pushedparasize);
                        emit_reg_ref(A_MOV,S_L,R_EDI,r);
                        ungetregister32(R_EDI);
                     end
                   else
                     emitpushreferenceaddr(left.location.reference);
                   del_reference(left.location.reference);
                end
              else
                begin
                   push_value_para(left,inlined,is_cdecl,
                     para_offset,para_alignment);
                end;
           end;
         truelabel:=otlabel;
         falselabel:=oflabel;
         { push from right to left }
         if not push_from_left_to_right and assigned(right) then
           tcallparanode(right).secondcallparan(pparaitem(defcoll^.next),push_from_left_to_right,
             inlined,is_cdecl,para_alignment,para_offset);
      end;


{*****************************************************************************
                             TI386CALLNODE
*****************************************************************************}

    procedure ti386callnode.pass_2;
      var
         unusedregisters : tregisterset;
         usablecount : byte;
         pushed : tpushed;
         hr,funcretref : treference;
         hregister,hregister2 : tregister;
         oldpushedparasize : longint;
         { true if ESI must be loaded again after the subroutine }
         loadesi : boolean;
         { true if a virtual method must be called directly }
         no_virtual_call : boolean;
         { true if we produce a con- or destrutor in a call }
         is_con_or_destructor : boolean;
         { true if a constructor is called again }
         extended_new : boolean;
         { adress returned from an I/O-error }
         iolabel : pasmlabel;
         { lexlevel count }
         i : longint;
         { help reference pointer }
         r : preference;
         hp : tnode;
         pp : tbinarynode;
         params : tnode;
         inlined : boolean;
         inlinecode : tprocinlinenode;
         para_alignment,
         para_offset : longint;
         { instruction for alignement correction }
{        corr : paicpu;}
         { we must pop this size also after !! }
{        must_pop : boolean; }
         pop_size : longint;
         pop_allowed : boolean;
         pop_esp : boolean;
         push_size : longint;


      label
         dont_call;

      begin
         reset_reference(location.reference);
         extended_new:=false;
         iolabel:=nil;
         inlinecode:=nil;
         inlined:=false;
         loadesi:=true;
         no_virtual_call:=false;
         unusedregisters:=unused;
         usablecount:=usablereg32;

         if ([pocall_cdecl,pocall_cppdecl,pocall_stdcall]*procdefinition^.proccalloptions)<>[] then
          para_alignment:=4
         else
          para_alignment:=target_os.stackalignment;

         if not assigned(procdefinition) then
          exit;

         { Deciding whether we may still need the parameters happens next (JM) }
         params:=left;

         if (pocall_inline in procdefinition^.proccalloptions) then
           begin
              { make a copy for the next time the procedure is inlined (JM) }
              if assigned(left) then
                left:=left.getcopy;
              inlined:=true;
              inlinecode:=tprocinlinenode(right);
              { set it to the same lexical level as the local symtable, becuase
                the para's are stored there }
              pprocdef(procdefinition)^.parast^.symtablelevel:=aktprocsym^.definition^.localst^.symtablelevel;
              if assigned(params) then
                inlinecode.para_offset:=gettempofsizepersistant(inlinecode.para_size);
              pprocdef(procdefinition)^.parast^.address_fixup:=inlinecode.para_offset;
{$ifdef extdebug}
             Comment(V_debug,
               'inlined parasymtable is at offset '
               +tostr(pprocdef(procdefinition)^.parast^.address_fixup));
             exprasmlist^.concat(new(pai_asm_comment,init(
               strpnew('inlined parasymtable is at offset '
               +tostr(pprocdef(procdefinition)^.parast^.address_fixup)))));
{$endif extdebug}
              { copy for the next time the procedure is inlined (JM) }
              if assigned(right) then
                right:=right.getcopy;
              { disable further inlining of the same proc
                in the args }
              exclude(procdefinition^.proccalloptions,pocall_inline);
           end
         else
           { parameters not necessary anymore (JM) }
           left := nil;
         { only if no proc var }
         if inlined or
            not(assigned(right)) then
           is_con_or_destructor:=(procdefinition^.proctypeoption in [potype_constructor,potype_destructor]);
         { proc variables destroy all registers }
         if (inlined or
            (right=nil)) and
            { virtual methods too }
            not(po_virtualmethod in procdefinition^.procoptions) then
           begin
              if (cs_check_io in aktlocalswitches) and
                 (po_iocheck in procdefinition^.procoptions) and
                 not(po_iocheck in aktprocsym^.definition^.procoptions) then
                begin
                   getaddrlabel(iolabel);
                   emitlab(iolabel);
                end
              else
                iolabel:=nil;

              { save all used registers }
              pushusedregisters(pushed,pprocdef(procdefinition)^.usedregisters);

              { give used registers through }
              usedinproc:=usedinproc or pprocdef(procdefinition)^.usedregisters;
           end
         else
           begin
              pushusedregisters(pushed,$ff);
              usedinproc:=$ff;
              { no IO check for methods and procedure variables }
              iolabel:=nil;
           end;

         { generate the code for the parameter and push them }
         oldpushedparasize:=pushedparasize;
         pushedparasize:=0;
         pop_size:=0;
         { no inc esp for inlined procedure
           and for objects constructors PM }
         if (inlined or
            (right=nil)) and
            (procdefinition^.proctypeoption=potype_constructor) and
            { quick'n'dirty check if it is a class or an object }
            (resulttype^.deftype=orddef) then
           pop_allowed:=false
         else
           pop_allowed:=true;
         if pop_allowed then
          begin
          { Old pushedsize aligned on 4 ? }
            i:=oldpushedparasize and 3;
            if i>0 then
             inc(pop_size,4-i);
          { This parasize aligned on 4 ? }
            i:=procdefinition^.para_size(para_alignment) and 3;
            if i>0 then
             inc(pop_size,4-i);
          { insert the opcode and update pushedparasize }
          { never push 4 or more !! }
            pop_size:=pop_size mod 4;
            if pop_size>0 then
             begin
               inc(pushedparasize,pop_size);
               emit_const_reg(A_SUB,S_L,pop_size,R_ESP);
{$ifdef GDB}
               if (cs_debuginfo in aktmoduleswitches) and
                  (exprasmlist^.first=exprasmlist^.last) then
                 exprasmlist^.concat(new(pai_force_line,init));
{$endif GDB}
             end;
          end;
         if pop_allowed and (cs_align in aktglobalswitches) then
           begin
              pop_esp:=true;
              push_size:=procdefinition^.para_size(para_alignment);
              { !!!! here we have to take care of return type, self
                and nested procedures
              }
              inc(push_size,12);
              emit_reg_reg(A_MOV,S_L,R_ESP,R_EDI);
              if (push_size mod 8)=0 then
                emit_const_reg(A_AND,S_L,$fffffff8,R_ESP)
              else
                begin
                   emit_const_reg(A_SUB,S_L,push_size,R_ESP);
                   emit_const_reg(A_AND,S_L,$fffffff8,R_ESP);
                   emit_const_reg(A_SUB,S_L,push_size,R_ESP);
                end;
              emit_reg(A_PUSH,S_L,R_EDI);
           end
         else
           pop_esp:=false;
         if (resulttype<>pdef(voiddef)) and
            ret_in_param(resulttype) then
           begin
              funcretref.symbol:=nil;
{$ifdef test_dest_loc}
              if dest_loc_known and (dest_loc_tree=p) and
                 (dest_loc.loc in [LOC_REFERENCE,LOC_MEM]) then
                begin
                   funcretref:=dest_loc.reference;
                   if assigned(dest_loc.reference.symbol) then
                     funcretref.symbol:=stringdup(dest_loc.reference.symbol^);
                   in_dest_loc:=true;
                end
              else
{$endif test_dest_loc}
                if inlined then
                  begin
                     reset_reference(funcretref);
                     funcretref.offset:=gettempofsizepersistant(procdefinition^.rettype.def^.size);
                     funcretref.base:=procinfo^.framepointer;
                  end
                else
                  gettempofsizereference(procdefinition^.rettype.def^.size,funcretref);
           end;
         if assigned(params) then
           begin
              { be found elsewhere }
              if inlined then
                para_offset:=pprocdef(procdefinition)^.parast^.address_fixup+
                  pprocdef(procdefinition)^.parast^.datasize
              else
                para_offset:=0;
              if not(inlined) and
                 assigned(right) then
                tcallparanode(params).secondcallparan(pparaitem(pabstractprocdef(right.resulttype)^.para^.first),
                  (pocall_leftright in procdefinition^.proccalloptions),inlined,
                  (([pocall_cdecl,pocall_cppdecl]*procdefinition^.proccalloptions)<>[]),
                  para_alignment,para_offset)
              else
                tcallparanode(params).secondcallparan(pparaitem(procdefinition^.para^.first),
                  (pocall_leftright in procdefinition^.proccalloptions),inlined,
                  (([pocall_cdecl,pocall_cppdecl]*procdefinition^.proccalloptions)<>[]),
                  para_alignment,para_offset);
           end;
         if inlined then
           inlinecode.retoffset:=gettempofsizepersistant(4);
         if ret_in_param(resulttype) then
           begin
              { This must not be counted for C code
                complex return address is removed from stack
                by function itself !   }
{$ifdef OLD_C_STACK}
              inc(pushedparasize,4); { lets try without it PM }
{$endif not OLD_C_STACK}
              if inlined then
                begin
{$ifndef noAllocEdi}
                   getexplicitregister32(R_EDI);
{$endif noAllocEdi}
                   emit_ref_reg(A_LEA,S_L,
                     newreference(funcretref),R_EDI);
                   r:=new_reference(procinfo^.framepointer,inlinecode.retoffset);
                   emit_reg_ref(A_MOV,S_L,R_EDI,r);
{$ifndef noAllocEdi}
                   ungetregister32(R_EDI);
{$endif noAllocEdi}
                end
              else
                emitpushreferenceaddr(funcretref);
           end;
         { procedure variable ? }
         if inlined or
           (right=nil) then
           begin
              { overloaded operator have no symtable }
              { push self }
              if assigned(symtableproc) and
                (symtableproc^.symtabletype=withsymtable) then
                begin
                   { dirty trick to avoid the secondcall below }
                   methodpointer:=ccallparanode.create(nil,nil);
                   methodpointer.location.loc:=LOC_REGISTER;
{$ifndef noAllocEDI}
                   getexplicitregister32(R_ESI);
{$endif noAllocEDI}
                   methodpointer.location.register:=R_ESI;
                   { ARGHHH this is wrong !!!
                     if we can init from base class for a child
                     class that the wrong VMT will be
                     transfered to constructor !! }
                   methodpointer.resulttype:=
                     twithnode(pwithsymtable(symtableproc)^.withnode).left.resulttype;
                   { make a reference }
                   new(r);
                   reset_reference(r^);
                   { if assigned(ptree(pwithsymtable(symtable)^.withnode)^.pref) then
                     begin
                        r^:=ptree(pwithsymtable(symtable)^.withnode)^.pref^;
                     end
                   else
                     begin
                        r^.offset:=symtable^.datasize;
                        r^.base:=procinfo^.framepointer;
                     end; }
                   r^:=twithnode(pwithsymtable(symtableproc)^.withnode).withreference^;
                   if ((not(nf_islocal in twithnode(pwithsymtable(symtableproc)^.withnode).flags)) and
                       (not pwithsymtable(symtableproc)^.direct_with)) or
                      is_class_or_interface(methodpointer.resulttype) then
                     emit_ref_reg(A_MOV,S_L,r,R_ESI)
                   else
                     emit_ref_reg(A_LEA,S_L,r,R_ESI);
                end;

              { push self }
              if assigned(symtableproc) and
                ((symtableproc^.symtabletype=objectsymtable) or
                (symtableproc^.symtabletype=withsymtable)) then
                begin
                   if assigned(methodpointer) then
                     begin
                        {
                        if methodpointer^.resulttype=classrefdef then
                          begin
                              two possibilities:
                               1. constructor
                               2. class method

                          end
                        else }
                          begin
                             case methodpointer.nodetype of
                               typen:
                                 begin
                                    { direct call to inherited method }
                                    if (po_abstractmethod in procdefinition^.procoptions) then
                                      begin
                                         CGMessage(cg_e_cant_call_abstract_method);
                                         goto dont_call;
                                      end;
                                    { generate no virtual call }
                                    no_virtual_call:=true;

                                    if (sp_static in symtableprocentry^.symoptions) then
                                      begin
                                         { well lets put the VMT address directly into ESI }
                                         { it is kind of dirty but that is the simplest    }
                                         { way to accept virtual static functions (PM)     }
                                         loadesi:=true;
                                         { if no VMT just use $0 bug0214 PM }
{$ifndef noAllocEDI}
                                         getexplicitregister32(R_ESI);
{$endif noAllocEDI}
                                         if not(oo_has_vmt in pobjectdef(methodpointer.resulttype)^.objectoptions) then
                                           emit_const_reg(A_MOV,S_L,0,R_ESI)
                                         else
                                           begin
                                             emit_sym_ofs_reg(A_MOV,S_L,
                                               newasmsymbol(pobjectdef(methodpointer.resulttype)^.vmt_mangledname),
                                               0,R_ESI);
                                           end;
                                         { emit_reg(A_PUSH,S_L,R_ESI);
                                           this is done below !! }
                                      end
                                    else
                                      { this is a member call, so ESI isn't modfied }
                                      loadesi:=false;

                                    { a class destructor needs a flag }
                                    if is_class(pobjectdef(methodpointer.resulttype)) and
                                       {assigned(aktprocsym) and
                                       (aktprocsym^.definition^.proctypeoption=potype_destructor)}
                                       (procdefinition^.proctypeoption=potype_destructor) then
                                      begin
                                        push_int(0);
                                        emit_reg(A_PUSH,S_L,R_ESI);
                                      end;

                                    if not(is_con_or_destructor and
                                           is_class(methodpointer.resulttype) and
                                           {assigned(aktprocsym) and
                                          (aktprocsym^.definition^.proctypeoption in [potype_constructor,potype_destructor])}
                                           (procdefinition^.proctypeoption in [potype_constructor,potype_destructor])
                                          ) then
                                      emit_reg(A_PUSH,S_L,R_ESI);
                                    { if an inherited con- or destructor should be  }
                                    { called in a con- or destructor then a warning }
                                    { will be made                                  }
                                    { con- and destructors need a pointer to the vmt }
                                    if is_con_or_destructor and
                                      is_object(methodpointer.resulttype) and
                                      assigned(aktprocsym) then
                                      begin
                                         if not(aktprocsym^.definition^.proctypeoption in
                                                [potype_constructor,potype_destructor]) then
                                          CGMessage(cg_w_member_cd_call_from_method);
                                      end;
                                    { class destructors get there flag above }
                                    { constructor flags ?                    }
                                    if is_con_or_destructor and
                                      not(
                                        is_class(methodpointer.resulttype) and
                                        assigned(aktprocsym) and
                                        (aktprocsym^.definition^.proctypeoption=potype_destructor)) then
                                      begin
                                         { a constructor needs also a flag }
                                         if is_class(methodpointer.resulttype) then
                                           push_int(0);
                                         push_int(0);
                                      end;
                                 end;
                               hnewn:
                                 begin
                                    { extended syntax of new }
                                    { ESI must be zero }
{$ifndef noAllocEDI}
                                    getexplicitregister32(R_ESI);
{$endif noAllocEDI}
                                    emit_reg_reg(A_XOR,S_L,R_ESI,R_ESI);
                                    emit_reg(A_PUSH,S_L,R_ESI);
                                    { insert the vmt }
                                    emit_sym(A_PUSH,S_L,
                                      newasmsymbol(pobjectdef(methodpointer.resulttype)^.vmt_mangledname));
                                    extended_new:=true;
                                 end;
                               hdisposen:
                                 begin
                                    secondpass(methodpointer);

                                    { destructor with extended syntax called from dispose }
                                    { hdisposen always deliver LOC_REFERENCE          }
{$ifndef noAllocEDI}
                                    getexplicitregister32(R_ESI);
{$endif noAllocEDI}
                                    emit_ref_reg(A_LEA,S_L,
                                      newreference(methodpointer.location.reference),R_ESI);
                                    del_reference(methodpointer.location.reference);
                                    emit_reg(A_PUSH,S_L,R_ESI);
                                    emit_sym(A_PUSH,S_L,
                                      newasmsymbol(pobjectdef(methodpointer.resulttype)^.vmt_mangledname));
                                 end;
                               else
                                 begin
                                    { call to an instance member }
                                    if (symtableproc^.symtabletype<>withsymtable) then
                                      begin
                                         secondpass(methodpointer);
{$ifndef noAllocEDI}
                                         getexplicitregister32(R_ESI);
{$endif noAllocEDI}
                                         case methodpointer.location.loc of
                                            LOC_CREGISTER,
                                            LOC_REGISTER:
                                              begin
                                                 emit_reg_reg(A_MOV,S_L,methodpointer.location.register,R_ESI);
                                                 ungetregister32(methodpointer.location.register);
                                              end;
                                            else
                                              begin
                                                 if (methodpointer.resulttype^.deftype=classrefdef) or
                                                    is_class_or_interface(methodpointer.resulttype) then
                                                   emit_ref_reg(A_MOV,S_L,
                                                     newreference(methodpointer.location.reference),R_ESI)
                                                 else
                                                   emit_ref_reg(A_LEA,S_L,
                                                     newreference(methodpointer.location.reference),R_ESI);
                                                 del_reference(methodpointer.location.reference);
                                              end;
                                         end;
                                      end;
                                    { when calling a class method, we have to load ESI with the VMT !
                                      But, not for a class method via self }
                                    if not(po_containsself in procdefinition^.procoptions) then
                                      begin
                                        if (po_classmethod in procdefinition^.procoptions) and
                                           not(methodpointer.resulttype^.deftype=classrefdef) then
                                          begin
                                             { class method needs current VMT }
                                             getexplicitregister32(R_ESI);
                                             new(r);
                                             reset_reference(r^);
                                             r^.base:=R_ESI;
                                             r^.offset:= pprocdef(procdefinition)^._class^.vmt_offset;
                                             emit_ref_reg(A_MOV,S_L,r,R_ESI);
                                          end;

                                        { direct call to destructor: remove data }
                                        if (procdefinition^.proctypeoption=potype_destructor) and
                                           is_class(methodpointer.resulttype) then
                                          emit_const(A_PUSH,S_L,1);

                                        { direct call to class constructor, don't allocate memory }
                                        if (procdefinition^.proctypeoption=potype_constructor) and
                                           is_class(methodpointer.resulttype) then
                                          begin
                                             emit_const(A_PUSH,S_L,0);
                                             emit_const(A_PUSH,S_L,0);
                                          end
                                        else
                                          begin
                                             { constructor call via classreference => allocate memory }
                                             if (procdefinition^.proctypeoption=potype_constructor) and
                                                (methodpointer.resulttype^.deftype=classrefdef) and
                                                is_class(pclassrefdef(methodpointer.resulttype)^.pointertype.def) then
                                                emit_const(A_PUSH,S_L,1);
                                             emit_reg(A_PUSH,S_L,R_ESI);
                                          end;
                                      end;

                                    if is_con_or_destructor then
                                      begin
                                         { classes don't get a VMT pointer pushed }
                                         if is_object(methodpointer.resulttype) then
                                           begin
                                              if (procdefinition^.proctypeoption=potype_constructor) then
                                                begin
                                                   { it's no bad idea, to insert the VMT }
                                                   emit_sym(A_PUSH,S_L,newasmsymbol(
                                                     pobjectdef(methodpointer.resulttype)^.vmt_mangledname));
                                                end
                                              { destructors haven't to dispose the instance, if this is }
                                              { a direct call                                           }
                                              else
                                                push_int(0);
                                           end;
                                      end;
                                 end;
                             end;
                          end;
                     end
                   else
                     begin
                        if (po_classmethod in procdefinition^.procoptions) and
                          not(
                            assigned(aktprocsym) and
                            (po_classmethod in aktprocsym^.definition^.procoptions)
                          ) then
                          begin
                             { class method needs current VMT }
                             getexplicitregister32(R_ESI);
                             new(r);
                             reset_reference(r^);
                             r^.base:=R_ESI;
                             r^.offset:= pprocdef(procdefinition)^._class^.vmt_offset;
                             emit_ref_reg(A_MOV,S_L,r,R_ESI);
                          end
                        else
                          begin
                             { member call, ESI isn't modified }
                             loadesi:=false;
                          end;
                        { direct call to destructor: don't remove data! }
                        if is_class(procinfo^._class) then
                          begin
                             if (procdefinition^.proctypeoption=potype_destructor) then
                               begin
                                  emit_const(A_PUSH,S_L,0);
                                  emit_reg(A_PUSH,S_L,R_ESI);
                               end
                             else if (procdefinition^.proctypeoption=potype_constructor) then
                               begin
                                  emit_const(A_PUSH,S_L,0);
                                  emit_const(A_PUSH,S_L,0);
                               end
                             else
                               emit_reg(A_PUSH,S_L,R_ESI);
                          end
                        else if is_object(procinfo^._class) then
                          begin
                             emit_reg(A_PUSH,S_L,R_ESI);
                             if is_con_or_destructor then
                               begin
                                  if (procdefinition^.proctypeoption=potype_constructor) then
                                    begin
                                       { it's no bad idea, to insert the VMT }
                                       emit_sym(A_PUSH,S_L,newasmsymbol(
                                         procinfo^._class^.vmt_mangledname));
                                    end
                                  { destructors haven't to dispose the instance, if this is }
                                  { a direct call                                           }
                                  else
                                    push_int(0);
                               end;
                          end
                        else
                          Internalerror(200006165);
                     end;
                end;

                { call to BeforeDestruction? }
                if (procdefinition^.proctypeoption=potype_destructor) and
                   assigned(methodpointer) and
                   (methodpointer.nodetype<>typen) and
                   is_class(pobjectdef(methodpointer.resulttype)) and
                   (inlined or
                   (right=nil)) then
                  begin
                     emit_reg(A_PUSH,S_L,R_ESI);
                     new(r);
                     reset_reference(r^);
                     r^.base:=R_ESI;
                     getexplicitregister32(R_EDI);
                     emit_ref_reg(A_MOV,S_L,r,R_EDI);
                     new(r);
                     reset_reference(r^);
                     r^.offset:=72;
                     r^.base:=R_EDI;
                     emit_ref(A_CALL,S_NO,r);
                     ungetregister32(R_EDI);
                  end;

              { push base pointer ?}
              if (lexlevel>=normal_function_level) and assigned(pprocdef(procdefinition)^.parast) and
                ((pprocdef(procdefinition)^.parast^.symtablelevel)>normal_function_level) then
                begin
                   { if we call a nested function in a method, we must      }
                   { push also SELF!                                    }
                   { THAT'S NOT TRUE, we have to load ESI via frame pointer }
                   { access                                              }
                   {
                     begin
                        loadesi:=false;
                        emit_reg(A_PUSH,S_L,R_ESI);
                     end;
                   }
                   if lexlevel=(pprocdef(procdefinition)^.parast^.symtablelevel) then
                     begin
                        new(r);
                        reset_reference(r^);
                        r^.offset:=procinfo^.framepointer_offset;
                        r^.base:=procinfo^.framepointer;
                        emit_ref(A_PUSH,S_L,r)
                     end
                     { this is only true if the difference is one !!
                       but it cannot be more !! }
                   else if (lexlevel=pprocdef(procdefinition)^.parast^.symtablelevel-1) then
                     begin
                        emit_reg(A_PUSH,S_L,procinfo^.framepointer)
                     end
                   else if (lexlevel>pprocdef(procdefinition)^.parast^.symtablelevel) then
                     begin
                        hregister:=getregister32;
                        new(r);
                        reset_reference(r^);
                        r^.offset:=procinfo^.framepointer_offset;
                        r^.base:=procinfo^.framepointer;
                        emit_ref_reg(A_MOV,S_L,r,hregister);
                        for i:=(pprocdef(procdefinition)^.parast^.symtablelevel) to lexlevel-1 do
                          begin
                             new(r);
                             reset_reference(r^);
                             {we should get the correct frame_pointer_offset at each level
                             how can we do this !!! }
                             r^.offset:=procinfo^.framepointer_offset;
                             r^.base:=hregister;
                             emit_ref_reg(A_MOV,S_L,r,hregister);
                          end;
                        emit_reg(A_PUSH,S_L,hregister);
                        ungetregister32(hregister);
                     end
                   else
                     internalerror(25000);
                end;

              if (po_virtualmethod in procdefinition^.procoptions) and
                 not(no_virtual_call) then
                begin
                   { static functions contain the vmt_address in ESI }
                   { also class methods                       }
                   { Here it is quite tricky because it also depends }
                   { on the methodpointer                        PM }
                   getexplicitregister32(R_ESI);
                   if assigned(aktprocsym) then
                     begin
                       if (((sp_static in aktprocsym^.symoptions) or
                        (po_classmethod in aktprocsym^.definition^.procoptions)) and
                        ((methodpointer=nil) or (methodpointer.nodetype=typen)))
                        or
                        (po_staticmethod in procdefinition^.procoptions) or
                        ((procdefinition^.proctypeoption=potype_constructor) and
                        { esi contains the vmt if we call a constructor via a class ref }
                         assigned(methodpointer) and
                         (methodpointer.resulttype^.deftype=classrefdef)
                        ) or
                        { is_interface(pprocdef(procdefinition)^._class) or }
                        { ESI is loaded earlier }
                        (po_classmethod in procdefinition^.procoptions) then
                         begin
                            new(r);
                            reset_reference(r^);
                            r^.base:=R_ESI;
                         end
                       else
                         begin
                            new(r);
                            reset_reference(r^);
                            r^.base:=R_ESI;
                            { this is one point where we need vmt_offset (PM) }
                            r^.offset:= pprocdef(procdefinition)^._class^.vmt_offset;
                            getexplicitregister32(R_EDI);
                            emit_ref_reg(A_MOV,S_L,r,R_EDI);
                            new(r);
                            reset_reference(r^);
                            r^.base:=R_EDI;
                         end;
                     end
                   else
                     { aktprocsym should be assigned, also in main program }
                     internalerror(12345);
                   {
                     begin
                       new(r);
                       reset_reference(r^);
                       r^.base:=R_ESI;
                       emit_ref_reg(A_MOV,S_L,r,R_EDI);
                       new(r);
                       reset_reference(r^);
                       r^.base:=R_EDI;
                     end;
                   }
                   if pprocdef(procdefinition)^.extnumber=-1 then
                     internalerror(44584);
                   r^.offset:=pprocdef(procdefinition)^._class^.vmtmethodoffset(pprocdef(procdefinition)^.extnumber);
                   if not(is_interface(pprocdef(procdefinition)^._class)) and
                     not(is_cppclass(pprocdef(procdefinition)^._class)) then
                     begin
                        if (cs_check_object_ext in aktlocalswitches) then
                          begin
                             emit_sym(A_PUSH,S_L,
                               newasmsymbol(pprocdef(procdefinition)^._class^.vmt_mangledname));
                             emit_reg(A_PUSH,S_L,r^.base);
                             emitcall('FPC_CHECK_OBJECT_EXT');
                          end
                        else if (cs_check_range in aktlocalswitches) then
                          begin
                             emit_reg(A_PUSH,S_L,r^.base);
                             emitcall('FPC_CHECK_OBJECT');
                          end;
                     end;
                   emit_ref(A_CALL,S_NO,r);
{$ifndef noAllocEdi}
                   ungetregister32(R_EDI);
{$endif noAllocEdi}
                end
              else if not inlined then
                begin
                  { We can call interrupts from within the smae code
                    by just pushing the flags and CS PM }
                  if (po_interrupt in procdefinition^.procoptions) then
                    begin
                        emit_none(A_PUSHF,S_L);
                        emit_reg(A_PUSH,S_L,R_CS);
                    end;
                  emitcall(pprocdef(procdefinition)^.mangledname);
                end
              else { inlined proc }
                { inlined code is in inlinecode }
                begin
                   { set poinline again }
                   include(procdefinition^.proccalloptions,pocall_inline);
                   { process the inlinecode }
                   secondpass(inlinecode);
                   { free the args }
                   if pprocdef(procdefinition)^.parast^.datasize>0 then
                     ungetpersistanttemp(pprocdef(procdefinition)^.parast^.address_fixup);
                end;
           end
         else
           { now procedure variable case }
           begin
              secondpass(right);
              if (po_interrupt in procdefinition^.procoptions) then
                begin
                    emit_none(A_PUSHF,S_L);
                    emit_reg(A_PUSH,S_L,R_CS);
                end;
              { procedure of object? }
              if (po_methodpointer in procdefinition^.procoptions) then
                begin
                   { method pointer can't be in a register }
                   hregister:=R_NO;

                   { do some hacking if we call a method pointer }
                   { which is a class member                 }
                   { else ESI is overwritten !             }
                   if (right.location.reference.base=R_ESI) or
                      (right.location.reference.index=R_ESI) then
                     begin
                        del_reference(right.location.reference);
                        getexplicitregister32(R_EDI);
                        emit_ref_reg(A_MOV,S_L,
                          newreference(right.location.reference),R_EDI);
                        hregister:=R_EDI;
                     end;

                   { load self, but not if it's already explicitly pushed }
                   if not(po_containsself in procdefinition^.procoptions) then
                     begin
                       { load ESI }
                       inc(right.location.reference.offset,4);
                       getexplicitregister32(R_ESI);
                       emit_ref_reg(A_MOV,S_L,
                         newreference(right.location.reference),R_ESI);
                       dec(right.location.reference.offset,4);
                       { push self pointer }
                       emit_reg(A_PUSH,S_L,R_ESI);
                     end;

                   if hregister=R_NO then
                     emit_ref(A_CALL,S_NO,newreference(right.location.reference))
                   else
                     begin
{$ifndef noAllocEdi}
                       ungetregister32(hregister);
{$else noAllocEdi}
                       { the same code, the previous line is just to       }
                       { indicate EDI actually is deallocated if allocated }
                       { above (JM)                                        }
                       ungetregister32(hregister);
{$endif noAllocEdi}
                       emit_reg(A_CALL,S_NO,hregister);
                     end;

                   del_reference(right.location.reference);
                end
              else
                begin
                   case right.location.loc of
                      LOC_REGISTER,LOC_CREGISTER:
                         begin
                             emit_reg(A_CALL,S_NO,right.location.register);
                             ungetregister32(right.location.register);
                         end
                      else
                         emit_ref(A_CALL,S_NO,newreference(right.location.reference));
                         del_reference(right.location.reference);
                   end;
                end;
           end;

           { this was only for normal functions
             displaced here so we also get
             it to work for procvars PM }
           if (not inlined) and (pocall_clearstack in procdefinition^.proccalloptions) then
             begin
                { we also add the pop_size which is included in pushedparasize }
                pop_size:=0;
                { better than an add on all processors }
                if pushedparasize=4 then
                  begin
                    getexplicitregister32(R_EDI);
                    emit_reg(A_POP,S_L,R_EDI);
                    ungetregister32(R_EDI);
                  end
                { the pentium has two pipes and pop reg is pairable }
                { but the registers must be different!        }
                else if (pushedparasize=8) and
                  not(cs_littlesize in aktglobalswitches) and
                  (aktoptprocessor=ClassP5) and
                  (procinfo^._class=nil) then
                    begin
                       getexplicitregister32(R_EDI);
                       emit_reg(A_POP,S_L,R_EDI);
                       ungetregister32(R_EDI);
                       exprasmlist^.concat(new(pairegalloc,alloc(R_ESI)));
                       emit_reg(A_POP,S_L,R_ESI);
                       exprasmlist^.concat(new(pairegalloc,alloc(R_ESI)));
                    end
                else if pushedparasize<>0 then
                  emit_const_reg(A_ADD,S_L,pushedparasize,R_ESP);
             end;
         if pop_esp then
           emit_reg(A_POP,S_L,R_ESP);
      dont_call:
         pushedparasize:=oldpushedparasize;
         unused:=unusedregisters;
         usablereg32:=usablecount;
{$ifdef TEMPREGDEBUG}
         testregisters32;
{$endif TEMPREGDEBUG}

         { a constructor could be a function with boolean result }
         { if calling constructor called fail we
           must jump directly to quickexitlabel  PM
           but only if it is a call of an inherited constructor }
         if (inlined or
             (right=nil)) and
            (procdefinition^.proctypeoption=potype_constructor) and
            assigned(methodpointer) and
            (methodpointer.nodetype=typen) and
            (aktprocsym^.definition^.proctypeoption=potype_constructor) then
           begin
             emitjmp(C_Z,faillabel);
           end;

         { call to AfterConstruction? }
         if is_class(resulttype) and
           (inlined or
           (right=nil)) and
           (procdefinition^.proctypeoption=potype_constructor) and
           assigned(methodpointer) and
           (methodpointer.nodetype<>typen) then
           begin
              emit_reg(A_PUSH,S_L,R_ESI);
              new(r);
              reset_reference(r^);
              r^.base:=R_ESI;
              getexplicitregister32(R_EDI);
              emit_ref_reg(A_MOV,S_L,r,R_EDI);
              new(r);
              reset_reference(r^);
              r^.offset:=68;
              r^.base:=R_EDI;
              emit_ref(A_CALL,S_NO,r);
              ungetregister32(R_EDI);
              exprasmlist^.concat(new(pairegalloc,alloc(R_EAX)));
              emit_reg_reg(A_MOV,S_L,R_ESI,R_EAX);
           end;

         { handle function results }
         { structured results are easy to handle.... }
         { needed also when result_no_used !! }
         if (resulttype<>pdef(voiddef)) and ret_in_param(resulttype) then
           begin
              location.loc:=LOC_MEM;
              location.reference.symbol:=nil;
              location.reference:=funcretref;
           end;
         { we have only to handle the result if it is used, but }
         { ansi/widestrings must be registered, so we can dispose them }
         if (resulttype<>pdef(voiddef)) and ((nf_return_value_used in flags) or
           is_ansistring(resulttype) or is_widestring(resulttype)) then
           begin
              { a contructor could be a function with boolean result }
              if (inlined or
                  (right=nil)) and
                 (procdefinition^.proctypeoption=potype_constructor) and
                 { quick'n'dirty check if it is a class or an object }
                 (resulttype^.deftype=orddef) then
                begin
                   { this fails if popsize > 0 PM }
                   location.loc:=LOC_FLAGS;
                   location.resflags:=F_NE;


                   if extended_new then
                     begin
{$ifdef test_dest_loc}
                        if dest_loc_known and (dest_loc_tree=p) then
                          mov_reg_to_dest(p,S_L,R_EAX)
                        else
{$endif test_dest_loc}
                          begin
                             hregister:=getexplicitregister32(R_EAX);
                             emit_reg_reg(A_MOV,S_L,R_EAX,hregister);
                             location.register:=hregister;
                          end;
                     end;
                end
               { structed results are easy to handle.... }
              else if ret_in_param(resulttype) then
                begin
                   {location.loc:=LOC_MEM;
                   stringdispose(location.reference.symbol);
                   location.reference:=funcretref;
                   already done above (PM) }
                end
              else
                begin
                   if (resulttype^.deftype in [orddef,enumdef]) then
                     begin
                        location.loc:=LOC_REGISTER;
                        case resulttype^.size of
                          4 :
                            begin
{$ifdef test_dest_loc}
                               if dest_loc_known and (dest_loc_tree=p) then
                                 mov_reg_to_dest(p,S_L,R_EAX)
                               else
{$endif test_dest_loc}
                                 begin
                                    hregister:=getexplicitregister32(R_EAX);
                                    emit_reg_reg(A_MOV,S_L,R_EAX,hregister);
                                    location.register:=hregister;
                                 end;
                            end;
                          1 :
                            begin
{$ifdef test_dest_loc}
                                 if dest_loc_known and (dest_loc_tree=p) then
                                   mov_reg_to_dest(p,S_B,R_AL)
                                 else
{$endif test_dest_loc}
                                   begin
                                      hregister:=getexplicitregister32(R_EAX);
                                      emit_reg_reg(A_MOV,S_B,R_AL,reg32toreg8(hregister));
                                      location.register:=reg32toreg8(hregister);
                                   end;
                              end;
                          2 :
                            begin
{$ifdef test_dest_loc}
                               if dest_loc_known and (dest_loc_tree=p) then
                                 mov_reg_to_dest(p,S_W,R_AX)
                               else
{$endif test_dest_loc}
                                 begin
                                    hregister:=getexplicitregister32(R_EAX);
                                    emit_reg_reg(A_MOV,S_W,R_AX,reg32toreg16(hregister));
                                    location.register:=reg32toreg16(hregister);
                                 end;
                            end;
                           8 :
                             begin
{$ifdef test_dest_loc}
{$error Don't know what to do here}
{$endif test_dest_loc}
                                hregister:=getexplicitregister32(R_EAX);
                                hregister2:=getexplicitregister32(R_EDX);
                                emit_reg_reg(A_MOV,S_L,R_EAX,hregister);
                                emit_reg_reg(A_MOV,S_L,R_EDX,hregister2);
                                location.registerlow:=hregister;
                                location.registerhigh:=hregister2;
                             end;
                        else internalerror(7);
                     end

                end
              else if (resulttype^.deftype=floatdef) then
                case pfloatdef(resulttype)^.typ of
                  f32bit:
                    begin
                       location.loc:=LOC_REGISTER;
{$ifdef test_dest_loc}
                       if dest_loc_known and (dest_loc_tree=p) then
                         mov_reg_to_dest(p,S_L,R_EAX)
                       else
{$endif test_dest_loc}
                         begin
                            hregister:=getexplicitregister32(R_EAX);
                            emit_reg_reg(A_MOV,S_L,R_EAX,hregister);
                            location.register:=hregister;
                         end;
                    end;
                  else
                    begin
                       location.loc:=LOC_FPU;
                       inc(fpuvaroffset);
                    end;
                end
              else if is_ansistring(resulttype) or
                is_widestring(resulttype) then
                begin
                   hregister:=getexplicitregister32(R_EAX);
                   emit_reg_reg(A_MOV,S_L,R_EAX,hregister);
                   gettempansistringreference(hr);
                   decrstringref(resulttype,hr);
                   emit_reg_ref(A_MOV,S_L,hregister,
                     newreference(hr));
                   ungetregister32(hregister);
                   location.loc:=LOC_MEM;
                   location.reference:=hr;
                end
              else
                begin
                   location.loc:=LOC_REGISTER;
{$ifdef test_dest_loc}
                   if dest_loc_known and (dest_loc_tree=p) then
                     mov_reg_to_dest(p,S_L,R_EAX)
                   else
{$endif test_dest_loc}
                    begin
                       hregister:=getexplicitregister32(R_EAX);
                       emit_reg_reg(A_MOV,S_L,R_EAX,hregister);
                       location.register:=hregister;
                    end;
                end;
             end;
           end;

         { perhaps i/o check ? }
         if iolabel<>nil then
           begin
              emit_sym(A_PUSH,S_L,iolabel);
              emitcall('FPC_IOCHECK');
           end;
         if pop_size>0 then
           emit_const_reg(A_ADD,S_L,pop_size,R_ESP);

         { restore registers }
         popusedregisters(pushed);

         { at last, restore instance pointer (SELF) }
         if loadesi then
           maybe_loadesi;
         pp:=tbinarynode(params);
         while assigned(pp) do
           begin
              if assigned(pp.left) then
                begin
                  if (pp.left.location.loc in [LOC_REFERENCE,LOC_MEM]) then
                    ungetiftemp(pp.left.location.reference);
                { process also all nodes of an array of const }
                  if pp.left.nodetype=arrayconstructorn then
                    begin
                      if assigned(tarrayconstructornode(pp.left).left) then
                       begin
                         hp:=pp.left;
                         while assigned(hp) do
                          begin
                            if (tarrayconstructornode(tunarynode(hp).left).location.loc in [LOC_REFERENCE,LOC_MEM]) then
                              ungetiftemp(tarrayconstructornode(hp).left.location.reference);
                            hp:=tbinarynode(hp).right;
                          end;
                       end;
                    end;
                end;
              pp:=tbinarynode(pp.right);
           end;
         if inlined then
           ungetpersistanttemp(inlinecode.retoffset);
         inlinecode.free;
         params.free;


         { from now on the result can be freed normally }
         if inlined and ret_in_param(resulttype) then
           persistanttemptonormal(funcretref.offset);

         { if return value is not used }
         if (not(nf_return_value_used in flags)) and (resulttype<>pdef(voiddef)) then
           begin
              if location.loc in [LOC_MEM,LOC_REFERENCE] then
                begin
                   { data which must be finalized ? }
                   if (resulttype^.needs_inittable) then
                      finalize(resulttype,location.reference,false);
                   { release unused temp }
                   ungetiftemp(location.reference)
                end
              else if location.loc=LOC_FPU then
                begin
                  { release FPU stack }
                  emit_reg(A_FSTP,S_NO,R_ST0);
                  {
                    dec(fpuvaroffset);
                    do NOT decrement as the increment before
                    is not called for unused results PM }
                end;
           end;
      end;



{*****************************************************************************
                             TI386PROCINLINENODE
*****************************************************************************}


    procedure ti386procinlinenode.pass_2;
       var st : psymtable;
           oldprocsym : pprocsym;
           ps, i : longint;
           tmpreg: tregister;
           oldprocinfo : pprocinfo;
           oldinlining_procedure,
           nostackframe,make_global : boolean;
           proc_names : tstringcontainer;
           inlineentrycode,inlineexitcode : paasmoutput;
           oldexitlabel,oldexit2label,oldquickexitlabel:Pasmlabel;
           oldunused,oldusableregs : tregisterset;
           oldc_usableregs : longint;
           oldreg_pushes : regvar_longintarray;
           oldis_reg_var : regvar_booleanarray;
{$ifdef TEMPREGDEBUG}
           oldreg_user   : regvar_ptreearray;
           oldreg_releaser : regvar_ptreearray;
{$endif TEMPREGDEBUG}
{$ifdef GDB}
           startlabel,endlabel : pasmlabel;
           pp : pchar;
           mangled_length  : longint;
{$endif GDB}
       begin
          { deallocate the registers used for the current procedure's regvars }
          if assigned(aktprocsym^.definition^.regvarinfo) then
            begin
              with pregvarinfo(aktprocsym^.definition^.regvarinfo)^ do
                for i := 1 to maxvarregs do
                  if assigned(regvars[i]) then
                    begin
                      case regsize(regvars[i]^.reg) of
                        S_B: tmpreg := reg8toreg32(regvars[i]^.reg);
                        S_W: tmpreg := reg16toreg32(regvars[i]^.reg);
                        S_L: tmpreg := regvars[i]^.reg;
                      end;
                      exprasmlist^.concat(new(pairegalloc,dealloc(tmpreg)));
                    end;
              oldunused := unused;
              oldusableregs := usableregs;
              oldc_usableregs := c_usableregs;
              oldreg_pushes := reg_pushes;
              oldis_reg_var := is_reg_var;
{$ifdef TEMPREGDEBUG}
              oldreg_user := reg_user;
              oldreg_releaser := reg_releaser;
{$endif TEMPREGDEBUG}
              { make sure the register allocator knows what the regvars in the }
              { inlined code block are (JM)                                    }
              resetusableregisters;
              clearregistercount;
              cleartempgen;
              if assigned(inlineprocsym^.definition^.regvarinfo) then
                with pregvarinfo(inlineprocsym^.definition^.regvarinfo)^ do
                 for i := 1 to maxvarregs do
                  if assigned(regvars[i]) then
                    begin
                      case regsize(regvars[i]^.reg) of
                        S_B: tmpreg := reg8toreg32(regvars[i]^.reg);
                        S_W: tmpreg := reg16toreg32(regvars[i]^.reg);
                        S_L: tmpreg := regvars[i]^.reg;
                      end;
                      usableregs:=usableregs-[tmpreg];
                      is_reg_var[tmpreg]:=true;
                      dec(c_usableregs);
                    end;
            end;
          oldinlining_procedure:=inlining_procedure;
          oldexitlabel:=aktexitlabel;
          oldexit2label:=aktexit2label;
          oldquickexitlabel:=quickexitlabel;
          getlabel(aktexitlabel);
          getlabel(aktexit2label);
          oldprocsym:=aktprocsym;
          { we're inlining a procedure }
          inlining_procedure:=true;
          { save old procinfo }
          getmem(oldprocinfo,sizeof(tprocinfo));
          move(procinfo^,oldprocinfo^,sizeof(tprocinfo));
          { set the return value }
          aktprocsym:=inlineprocsym;
          procinfo^.returntype:=aktprocsym^.definition^.rettype;
          procinfo^.return_offset:=retoffset;
          procinfo^.para_offset:=para_offset;
          { arg space has been filled by the parent secondcall }
          st:=aktprocsym^.definition^.localst;
          { set it to the same lexical level }
          st^.symtablelevel:=oldprocsym^.definition^.localst^.symtablelevel;
          if st^.datasize>0 then
            begin
              st^.address_fixup:=gettempofsizepersistant(st^.datasize)+st^.datasize;
{$ifdef extdebug}
              Comment(V_debug,'local symtable is at offset '+tostr(st^.address_fixup));
              exprasmlist^.concat(new(pai_asm_comment,init(strpnew(
                'local symtable is at offset '+tostr(st^.address_fixup)))));
{$endif extdebug}
            end;
          exprasmlist^.concat(new(Pai_Marker, Init(InlineStart)));
{$ifdef extdebug}
          exprasmlist^.concat(new(pai_asm_comment,init(strpnew('Start of inlined proc'))));
{$endif extdebug}
{$ifdef GDB}
          if (cs_debuginfo in aktmoduleswitches) then
            begin
              getaddrlabel(startlabel);
              getaddrlabel(endlabel);
              emitlab(startlabel);
              inlineprocsym^.definition^.localst^.symtabletype:=inlinelocalsymtable;
              inlineprocsym^.definition^.parast^.symtabletype:=inlineparasymtable;

              { Here we must include the para and local symtable info }
              inlineprocsym^.concatstabto(withdebuglist);

              { set it back for savety }
              inlineprocsym^.definition^.localst^.symtabletype:=localsymtable;
              inlineprocsym^.definition^.parast^.symtabletype:=parasymtable;

              mangled_length:=length(oldprocsym^.definition^.mangledname);
              getmem(pp,mangled_length+50);
              strpcopy(pp,'192,0,0,'+startlabel^.name);
              if (target_os.use_function_relative_addresses) then
                begin
                  strpcopy(strend(pp),'-');
                  strpcopy(strend(pp),oldprocsym^.definition^.mangledname);
                end;
              withdebuglist^.concat(new(pai_stabn,init(strnew(pp))));
            end;
{$endif GDB}
          { takes care of local data initialization }
          inlineentrycode:=new(paasmoutput,init);
          inlineexitcode:=new(paasmoutput,init);
          proc_names.init;
          ps:=para_size;
          make_global:=false; { to avoid warning }
          genentrycode(inlineentrycode,proc_names,make_global,0,ps,nostackframe,true);
          exprasmlist^.concatlist(inlineentrycode);
          secondpass(inlinetree);
          genexitcode(inlineexitcode,0,false,true);
          exprasmlist^.concatlist(inlineexitcode);

          dispose(inlineentrycode,done);
          dispose(inlineexitcode,done);
{$ifdef extdebug}
          exprasmlist^.concat(new(pai_asm_comment,init(strpnew('End of inlined proc'))));
{$endif extdebug}
          exprasmlist^.concat(new(Pai_Marker, Init(InlineEnd)));

          {we can free the local data now, reset also the fixup address }
          if st^.datasize>0 then
            begin
              ungetpersistanttemp(st^.address_fixup-st^.datasize);
              st^.address_fixup:=0;
            end;
          { restore procinfo }
          move(oldprocinfo^,procinfo^,sizeof(tprocinfo));
          freemem(oldprocinfo,sizeof(tprocinfo));
{$ifdef GDB}
          if (cs_debuginfo in aktmoduleswitches) then
            begin
              emitlab(endlabel);
              strpcopy(pp,'224,0,0,'+endlabel^.name);
             if (target_os.use_function_relative_addresses) then
               begin
                 strpcopy(strend(pp),'-');
                 strpcopy(strend(pp),oldprocsym^.definition^.mangledname);
               end;
              withdebuglist^.concat(new(pai_stabn,init(strnew(pp))));
              freemem(pp,mangled_length+50);
            end;
{$endif GDB}
          { restore }
          aktprocsym:=oldprocsym;
          aktexitlabel:=oldexitlabel;
          aktexit2label:=oldexit2label;
          quickexitlabel:=oldquickexitlabel;
          inlining_procedure:=oldinlining_procedure;

          { reallocate the registers used for the current procedure's regvars, }
          { since they may have been used and then deallocated in the inlined  }
          { procedure (JM)                                                     }
          if assigned(aktprocsym^.definition^.regvarinfo) then
            begin
              with pregvarinfo(aktprocsym^.definition^.regvarinfo)^ do
                for i := 1 to maxvarregs do
                  if assigned(regvars[i]) then
                    begin
                      case regsize(regvars[i]^.reg) of
                        S_B: tmpreg := reg8toreg32(regvars[i]^.reg);
                        S_W: tmpreg := reg16toreg32(regvars[i]^.reg);
                        S_L: tmpreg := regvars[i]^.reg;
                      end;
                      exprasmlist^.concat(new(pairegalloc,alloc(tmpreg)));
                    end;
              oldunused := oldunused;
              oldusableregs := oldusableregs;
              oldc_usableregs := oldc_usableregs;
              oldreg_pushes := oldreg_pushes;
              oldis_reg_var := oldis_reg_var;
{$ifdef TEMPREGDEBUG}
              oldreg_user := oldreg_user;
              oldreg_releaser := oldreg_releaser;
{$endif TEMPREGDEBUG}
            end;
       end;


begin
   ccallparanode:=ti386callparanode;
   ccallnode:=ti386callnode;
   cprocinlinenode:=ti386procinlinenode;
end.
{
  $Log$
  Revision 1.8  2000-11-17 09:54:58  florian
    * INT_CHECK_OBJECT_* isn't applied to interfaces anymore

  Revision 1.7  2000/11/12 23:24:14  florian
    * interfaces are basically running

  Revision 1.6  2000/11/07 23:40:49  florian
    + AfterConstruction and BeforeDestruction impemented

  Revision 1.5  2000/11/06 23:15:01  peter
    * added copyvaluepara call again

  Revision 1.4  2000/11/04 14:25:23  florian
    + merged Attila's changes for interfaces, not tested yet

  Revision 1.3  2000/11/04 13:12:14  jonas
    * check for nil pointers before calling getcopy

  Revision 1.2  2000/10/31 22:02:56  peter
    * symtable splitted, no real code changes

  Revision 1.1  2000/10/15 09:33:31  peter
    * moved n386*.pas to i386/ cpu_target dir

  Revision 1.2  2000/10/14 10:14:48  peter
    * moehrendorf oct 2000 rewrite

  Revision 1.1  2000/10/10 17:31:56  florian
    * initial revision

}