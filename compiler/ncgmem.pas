{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl

    Generate assembler for memory related nodes which are
    the same for all (most?) processors

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
{ This unit generate assembler for memory related nodes.
}
unit ncgmem;

{$i fpcdefs.inc}

interface

    uses
      cpuinfo,cpubase,
      node,nmem;

    type
       tcgloadvmtnode = class(tloadvmtnode)
          procedure pass_2;override;
       end;

       tcghnewnode = class(thnewnode)
          procedure pass_2;override;
       end;

       tcghdisposenode = class(thdisposenode)
          procedure pass_2;override;
       end;

       tcgaddrnode = class(taddrnode)
          procedure pass_2;override;
       end;

       tcgdoubleaddrnode = class(tdoubleaddrnode)
          procedure pass_2;override;
       end;

       tcgderefnode = class(tderefnode)
          procedure pass_2;override;
       end;

       tcgsubscriptnode = class(tsubscriptnode)
          procedure pass_2;override;
       end;

       tcgselfnode = class(tselfnode)
          procedure pass_2;override;
       end;

       tcgwithnode = class(twithnode)
          procedure pass_2;override;
       end;

       tcgvecnode = class(tvecnode)
       protected
         function get_mul_size : aword;
         procedure update_reference_reg_mul(reg:tregister;l:aword);virtual;
         procedure second_wideansistring;virtual;
         procedure second_dynamicarray;virtual;
       public
         procedure pass_2;override;
       end;

implementation

    uses
{$ifdef delphi}
      sysutils,
{$else}
      strings,
{$endif}
{$ifdef GDB}
      gdb,
{$endif GDB}
      globtype,systems,
      cutils,verbose,globals,
      symconst,symtype,symdef,symsym,symtable,defbase,paramgr,
      aasmbase,aasmtai,aasmcpu,
      cginfo,cgbase,pass_2,
      pass_1,nld,ncon,nadd,
      cgobj,tgobj,rgobj,ncgutil,symbase
      ;


{*****************************************************************************
                            TCGLOADNODE
*****************************************************************************}

    procedure tcgloadvmtnode.pass_2;
      var
       href : treference;

      begin
         location_reset(location,LOC_REGISTER,OS_ADDR);
         location.register:=rg.getaddressregister(exprasmlist);
         { on 80386, LEA is the same as mov imm32 }
         reference_reset_symbol(href,
           objectlibrary.newasmsymbol(tobjectdef(tclassrefdef(resulttype.def).pointertype.def).vmt_mangledname),0);
         cg.a_loadaddr_ref_reg(exprasmlist,href,location.register);
      end;


{*****************************************************************************
                            TCGHNEWNODE
*****************************************************************************}

    procedure tcghnewnode.pass_2;
      begin
         { completely resolved in first pass now }
      end;


{*****************************************************************************
                         TCGHDISPOSENODE
*****************************************************************************}

    procedure tcghdisposenode.pass_2;
      begin
         location_reset(location,LOC_REFERENCE,def_cgsize(resulttype.def));

         secondpass(left);
         if codegenerror then
           exit;

         case left.location.loc of
            LOC_REGISTER:
              begin
                if not rg.isaddressregister(left.location.register) then
                  begin
                    location_release(exprasmlist,left.location);
                    location.reference.base := rg.getaddressregister(exprasmlist);
                    cg.a_load_reg_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.register,
                      location.reference.base);
                  end
                else
                  location.reference.base := left.location.register;
              end;
            LOC_CREGISTER,
            LOC_CREFERENCE,
            LOC_REFERENCE:
              begin
                 location_release(exprasmlist,left.location);
                 location.reference.base:=rg.getaddressregister(exprasmlist);
                 cg.a_load_loc_reg(exprasmlist,left.location,location.reference.base);
              end;
            else
              internalerror(2002032217);
         end;
      end;


{*****************************************************************************
                             TCGADDRNODE
*****************************************************************************}

    procedure tcgaddrnode.pass_2;
      begin
         secondpass(left);

         { when loading procvar we do nothing with this node, so load the
           location of left }
         if nf_procvarload in flags then
          begin
            location_copy(location,left.location);
            exit;
          end;

         location_release(exprasmlist,left.location);
         location_reset(location,LOC_REGISTER,OS_ADDR);
         location.register:=rg.getaddressregister(exprasmlist);
         {@ on a procvar means returning an address to the procedure that
           is stored in it.}
         { yes but left.symtableentry can be nil
           for example on self !! }
         { symtableentry can be also invalid, if left is no tree node }
         if (m_tp_procvar in aktmodeswitches) and
            (left.nodetype=loadn) and
            assigned(tloadnode(left).symtableentry) and
            (tloadnode(left).symtableentry.typ=varsym) and
            (tvarsym(tloadnode(left).symtableentry).vartype.def.deftype=procvardef) then
           cg.a_load_ref_reg(exprasmlist,OS_ADDR,left.location.reference,
             location.register)
         else
          begin
           cg.a_loadaddr_ref_reg(exprasmlist,left.location.reference,
             location.register);
          end;
      end;


{*****************************************************************************
                         TCGDOUBLEADDRNODE
*****************************************************************************}

    procedure tcgdoubleaddrnode.pass_2;
      begin
         secondpass(left);

         location_release(exprasmlist,left.location);
         location_reset(location,LOC_REGISTER,OS_ADDR);
         location.register:=rg.getaddressregister(exprasmlist);

         cg.a_loadaddr_ref_reg(exprasmlist,left.location.reference,
           location.register);
      end;


{*****************************************************************************
                           TCGDEREFNODE
*****************************************************************************}

    procedure tcgderefnode.pass_2;

      begin
         secondpass(left);
         location_reset(location,LOC_REFERENCE,def_cgsize(resulttype.def));
         case left.location.loc of
            LOC_REGISTER:
              begin
                if not rg.isaddressregister(left.location.register) then
                  begin
                    location_release(exprasmlist,left.location);
                    location.reference.base := rg.getaddressregister(exprasmlist);
                    cg.a_load_reg_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.register,
                      location.reference.base);
                  end
                else
                  location.reference.base := left.location.register;
              end;
            LOC_CREGISTER,
            LOC_CREFERENCE,
            LOC_REFERENCE:
              begin
                 location_release(exprasmlist,left.location);
                 location.reference.base:=rg.getaddressregister(exprasmlist);
                 cg.a_load_loc_reg(exprasmlist,left.location,location.reference.base);
              end;
         end;
         if (cs_gdb_heaptrc in aktglobalswitches) and
            (cs_checkpointer in aktglobalswitches) then
          begin
            cg.a_param_reg(exprasmlist, OS_ADDR,location.reference.base,paramanager.getintparaloc(1));
            cg.a_call_name(exprasmlist,'FPC_CHECKPOINTER');
          end;
      end;


{*****************************************************************************
                          TCGSUBSCRIPTNODE
*****************************************************************************}

    procedure tcgsubscriptnode.pass_2;

      begin
         secondpass(left);
         if codegenerror then
           exit;
         { classes and interfaces must be dereferenced implicit }
         if is_class_or_interface(left.resulttype.def) then
           begin
             location_reset(location,LOC_REFERENCE,def_cgsize(resulttype.def));
             case left.location.loc of
                LOC_REGISTER:
                  begin
                    if not rg.isaddressregister(left.location.register) then
                      begin
                        location_release(exprasmlist,left.location);
                        location.reference.base:=rg.getaddressregister(exprasmlist);
                        cg.a_load_reg_reg(exprasmlist,OS_ADDR,OS_ADDR,
                          left.location.register,location.reference.base);
                      end
                    else
                      location.reference.base := left.location.register;
                  end;
                LOC_CREGISTER,
                LOC_CREFERENCE,
                LOC_REFERENCE:
                  begin
                     location_release(exprasmlist,left.location);
                     location.reference.base:=rg.getaddressregister(exprasmlist);
                     cg.a_load_loc_reg(exprasmlist,left.location,location.reference.base);
                  end;
             end;
           end
         else if is_interfacecom(left.resulttype.def) then
           begin
              tg.GetTemp(exprasmlist,pointer_size,tt_interfacecom,location.reference);
              cg.a_load_loc_ref(exprasmlist,left.location,location.reference);
           end
         else
           location_copy(location,left.location);

         inc(location.reference.offset,vs.address);
         { also update the size of the location }
         location.size:=def_cgsize(resulttype.def);
      end;

{*****************************************************************************
                            TCGSELFNODE
*****************************************************************************}

    procedure tcgselfnode.pass_2;
      begin
         rg.getexplicitregisterint(exprasmlist,SELF_POINTER_REG);
         if (resulttype.def.deftype=classrefdef) or
            is_class(resulttype.def) then
          begin
            location_reset(location,LOC_CREGISTER,OS_ADDR);
            location.register:=SELF_POINTER_REG;
          end
         else
           begin
             location_reset(location,LOC_CREFERENCE,OS_ADDR);
             location.reference.base:=SELF_POINTER_REG;
           end;
      end;


{*****************************************************************************
                            TCGWITHNODE
*****************************************************************************}

    procedure tcgwithnode.pass_2;
      var
        tmpreg: tregister;
        usetemp,with_expr_in_temp : boolean;
{$ifdef GDB}
        withstartlabel,withendlabel : tasmlabel;
        pp : pchar;
        mangled_length  : longint;

      const
        withlevel : longint = 0;
{$endif GDB}
      begin
         if assigned(left) then
            begin
               secondpass(left);
{$ifdef i386}
               if (left.location.loc in [LOC_REFERENCE,LOC_CREFERENCE]) and
                  (left.location.reference.segment<>R_NO) then
                 message(parser_e_no_with_for_variable_in_other_segments);
{$endif i386}

               reference_reset(withreference);

               usetemp:=false;
               if (left.nodetype=loadn) and
                  (tloadnode(left).symtable=aktprocdef.localst) then
                 begin
                    { for locals use the local storage }
                    withreference:=left.location.reference;
                    include(flags,nf_islocal);
                 end
               else
                { call can have happend with a property }
                begin
                  usetemp:=true;
                  if is_class_or_interface(left.resulttype.def) then
                    begin
                      tmpreg := cg.get_scratch_reg_int(exprasmlist);
                      cg.a_load_loc_reg(exprasmlist,left.location,tmpreg)
                    end
                  else
                    begin
                      tmpreg := cg.get_scratch_reg_address(exprasmlist);
                      cg.a_loadaddr_ref_reg(exprasmlist,
                        left.location.reference,tmpreg);
                    end;
                end;

               location_release(exprasmlist,left.location);

               { if the with expression is stored in a temp    }
               { area we must make it persistent and shouldn't }
               { release it (FK)                               }
               if (left.location.loc in [LOC_CREFERENCE,LOC_REFERENCE]) and
                  tg.istemp(left.location.reference) then
                 begin
                    tg.ChangeTempType(left.location.reference,tt_persistant);
                    with_expr_in_temp:=true;
                 end
               else
                 with_expr_in_temp:=false;

               { if usetemp is set the value must be in tmpreg }
               if usetemp then
                begin
                  tg.GetTemp(exprasmlist,pointer_size,tt_persistant,withreference);
                  { move to temp reference }
                  cg.a_load_reg_ref(exprasmlist,OS_ADDR,tmpreg,withreference);
                  cg.free_scratch_reg(exprasmlist,tmpreg);
{$ifdef GDB}
                  if (cs_debuginfo in aktmoduleswitches) then
                    begin
                      inc(withlevel);
                      objectlibrary.getaddrlabel(withstartlabel);
                      objectlibrary.getaddrlabel(withendlabel);
                      cg.a_label(exprasmlist,withstartlabel);
                      withdebugList.concat(Tai_stabs.Create(strpnew(
                         '"with'+tostr(withlevel)+':'+tostr(symtablestack.getnewtypecount)+
                         '=*'+tstoreddef(left.resulttype.def).numberstring+'",'+
                         tostr(N_LSYM)+',0,0,'+tostr(withreference.offset))));
                      mangled_length:=length(aktprocdef.mangledname);
                      getmem(pp,mangled_length+50);
                      strpcopy(pp,'192,0,0,'+withstartlabel.name);
                      if (target_info.use_function_relative_addresses) then
                        begin
                          strpcopy(strend(pp),'-');
                          strpcopy(strend(pp),aktprocdef.mangledname);
                        end;
                      withdebugList.concat(Tai_stabn.Create(strnew(pp)));
                    end;
{$endif GDB}
                end;

               { right can be optimize out !!! }
               if assigned(right) then
                 secondpass(right);

               if usetemp then
                 begin
                   tg.UnGetTemp(exprasmlist,withreference);
{$ifdef GDB}
                   if (cs_debuginfo in aktmoduleswitches) then
                     begin
                       cg.a_label(exprasmlist,withendlabel);
                       strpcopy(pp,'224,0,0,'+withendlabel.name);
                      if (target_info.use_function_relative_addresses) then
                        begin
                          strpcopy(strend(pp),'-');
                          strpcopy(strend(pp),aktprocdef.mangledname);
                        end;
                       withdebugList.concat(Tai_stabn.Create(strnew(pp)));
                       freemem(pp,mangled_length+50);
                       dec(withlevel);
                     end;
{$endif GDB}
                 end;

               if with_expr_in_temp then
                 tg.UnGetTemp(exprasmlist,left.location.reference);

               reference_reset(withreference);
            end;
       end;


{*****************************************************************************
                            TCGVECNODE
*****************************************************************************}

     function tcgvecnode.get_mul_size : aword;
       begin
         if nf_memindex in flags then
          get_mul_size:=1
         else
          begin
            if (left.resulttype.def.deftype=arraydef) then
             get_mul_size:=tarraydef(left.resulttype.def).elesize
            else
             get_mul_size:=resulttype.def.size;
          end
       end;


     procedure tcgvecnode.update_reference_reg_mul(reg:tregister;l:aword);
       begin
         if location.reference.base=R_NO then
          begin
            cg.a_op_const_reg(exprasmlist,OP_IMUL,l,reg);
            location.reference.base:=reg;
          end
         else if location.reference.index=R_NO then
          begin
            cg.a_op_const_reg(exprasmlist,OP_IMUL,l,reg);
            location.reference.index:=reg;
          end
         else
          begin
            cg.a_loadaddr_ref_reg(exprasmlist,location.reference,location.reference.index);
            rg.ungetregisterint(exprasmlist,location.reference.base);
            reference_reset_base(location.reference,location.reference.index,0);
            { insert new index register }
            cg.a_op_const_reg(exprasmlist,OP_IMUL,l,reg);
            location.reference.index:=reg;
          end;
       end;


     procedure tcgvecnode.second_wideansistring;
       begin
       end;

     procedure tcgvecnode.second_dynamicarray;
       begin
       end;

    procedure tcgvecnode.pass_2;

      var
         extraoffset : longint;
         { rl stores the resulttype.def of the left node, this is necessary }
         { to detect if it is an ansistring                          }
         { because in constant nodes which constant index              }
         { the left tree is removed                                  }
         t   : tnode;
         href : treference;
         srsym : tsym;
         pushed : tpushedsaved;
         hightree : tnode;
         isjump  : boolean;
         otl,ofl : tasmlabel;
         newsize : tcgsize;
         pushedregs : tmaybesave;
      begin
         newsize:=def_cgsize(resulttype.def);
         location_reset(location,LOC_REFERENCE,newsize);

         secondpass(left);
         { we load the array reference to location }

         { an ansistring needs to be dereferenced }
         if is_ansistring(left.resulttype.def) or
            is_widestring(left.resulttype.def) then
           begin
              if nf_callunique in flags then
                begin
                   if left.location.loc<>LOC_REFERENCE then
                     begin
                        CGMessage(cg_e_illegal_expression);
                        exit;
                     end;
                   rg.saveusedregisters(exprasmlist,pushed,all_registers);
                   cg.a_paramaddr_ref(exprasmlist,left.location.reference,paramanager.getintparaloc(1));
                   rg.saveregvars(exprasmlist,all_registers);
                   cg.a_call_name(exprasmlist,'FPC_'+Upper(tstringdef(left.resulttype.def).stringtypname)+'_UNIQUE');
                   cg.g_maybe_loadself(exprasmlist);
                   rg.restoreusedregisters(exprasmlist,pushed);
                end;

              case left.location.loc of
                LOC_REGISTER,
                LOC_CREGISTER :
                  location.reference.base:=left.location.register;
                LOC_CREFERENCE,
                LOC_REFERENCE :
                  begin
                    location_release(exprasmlist,left.location);
                    location.reference.base:=rg.getregisterint(exprasmlist);
                    cg.a_load_ref_reg(exprasmlist,OS_ADDR,left.location.reference,location.reference.base);
                  end;
                else
                  internalerror(2002032218);
              end;

              { check for a zero length string,
                we can use the ansistring routine here }
              if (cs_check_range in aktlocalswitches) then
                begin
                   rg.saveusedregisters(exprasmlist,pushed,all_registers);
                   cg.a_param_reg(exprasmlist,OS_ADDR,location.reference.base,paramanager.getintparaloc(1));
                   rg.saveregvars(exprasmlist,all_registers);
                   cg.a_call_name(exprasmlist,'FPC_'+Upper(tstringdef(left.resulttype.def).stringtypname)+'_CHECKZERO');
                   cg.g_maybe_loadself(exprasmlist);
                   rg.restoreusedregisters(exprasmlist,pushed);
                end;

              { in ansistrings/widestrings S[1] is p<w>char(S)[0] !! }
              if is_ansistring(left.resulttype.def) then
                dec(location.reference.offset)
              else
                dec(location.reference.offset,2);
           end
         else if is_dynamic_array(left.resulttype.def) then
         { ... also a dynamic string }
           begin
              case left.location.loc of
                LOC_REGISTER,
                LOC_CREGISTER :
                  location.reference.base:=left.location.register;
                LOC_REFERENCE,
                LOC_CREFERENCE :
                  begin
                     location_release(exprasmlist,left.location);
                     location.reference.base:=rg.getaddressregister(exprasmlist);
                     cg.a_load_ref_reg(exprasmlist,OS_ADDR,
                      left.location.reference,location.reference.base);
                  end;
                else
                  internalerror(2002032219);
              end;
{$ifdef fpc}
{$warning FIXME}
{$endif}
              { check for a zero length string,
                we can use the ansistring routine here }
              if (cs_check_range in aktlocalswitches) then
                begin
                   rg.saveusedregisters(exprasmlist,pushed,all_registers);
                   cg.a_param_reg(exprasmlist,OS_ADDR,location.reference.base,paramanager.getintparaloc(1));
                   rg.saveregvars(exprasmlist,all_registers);
                   cg.a_call_name(exprasmlist,'FPC_ANSISTR_CHECKZERO');
                   cg.g_maybe_loadself(exprasmlist);
                   rg.restoreusedregisters(exprasmlist,pushed);
                end;
           end
         else
           location_copy(location,left.location);

         { offset can only differ from 0 if arraydef }
         if (left.resulttype.def.deftype=arraydef) and
            not(is_dynamic_array(left.resulttype.def)) then
           dec(location.reference.offset,get_mul_size*tarraydef(left.resulttype.def).lowrange);

         if right.nodetype=ordconstn then
           begin
              { offset can only differ from 0 if arraydef }
              case left.resulttype.def.deftype of
                arraydef :
                  begin
                     if not(is_open_array(left.resulttype.def)) and
                        not(is_array_of_const(left.resulttype.def)) and
                        not(is_dynamic_array(left.resulttype.def)) then
                       begin
                          if (tordconstnode(right).value>tarraydef(left.resulttype.def).highrange) or
                             (tordconstnode(right).value<tarraydef(left.resulttype.def).lowrange) then
                            begin
                              { this should be caught in the resulttypepass! (JM) }
                              if (cs_check_range in aktlocalswitches) then
                                CGMessage(parser_e_range_check_error)
                              else
                                CGMessage(parser_w_range_check_error);
                            end;
                       end
                     else
                       begin
                          { range checking for open and dynamic arrays !!!! }
{$ifdef fpc}
{$warning FIXME}
{$endif}
                          {!!!!!!!!!!!!!!!!!}
                       end;
                  end;
                stringdef :
                  begin
                    if (cs_check_range in aktlocalswitches) then
                     begin
                       case tstringdef(left.resulttype.def).string_typ of
                         { it's the same for ansi- and wide strings }
                         st_widestring,
                         st_ansistring:
                           begin
                              rg.saveusedregisters(exprasmlist,pushed,all_registers);
                              cg.a_param_const(exprasmlist,OS_INT,tordconstnode(right).value,paramanager.getintparaloc(2));
                              href:=location.reference;
                              dec(href.offset,7);
                              cg.a_param_ref(exprasmlist,OS_INT,href,paramanager.getintparaloc(1));
                              rg.saveregvars(exprasmlist,all_registers);
                              cg.a_call_name(exprasmlist,'FPC_'+Upper(tstringdef(left.resulttype.def).stringtypname)+'_RANGECHECK');
                              rg.restoreusedregisters(exprasmlist,pushed);
                              cg.g_maybe_loadself(exprasmlist);
                           end;

                         st_shortstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                           end;

                         st_longstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                           end;
                       end;
                     end;
                   end;
              end;
              inc(location.reference.offset,
                  get_mul_size*tordconstnode(right).value);
           end
         else
         { not nodetype=ordconstn }
           begin
              if (cs_regalloc in aktglobalswitches) and
                 { if we do range checking, we don't }
                 { need that fancy code (it would be }
                 { buggy)                            }
                 not(cs_check_range in aktlocalswitches) and
                 (left.resulttype.def.deftype=arraydef) then
                begin
                   extraoffset:=0;
                   if (right.nodetype=addn) then
                     begin
                        if taddnode(right).right.nodetype=ordconstn then
                          begin
                             extraoffset:=tordconstnode(taddnode(right).right).value;
                             t:=taddnode(right).left;
                             { First pass processed this with the assumption   }
                             { that there was an add node which may require an }
                             { extra register. Fake it or die with IE10 (JM)   }
                             t.registers32 := taddnode(right).registers32;
                             taddnode(right).left:=nil;
                             right.free;
                             right:=t;
                          end
                        else if taddnode(right).left.nodetype=ordconstn then
                          begin
                             extraoffset:=tordconstnode(taddnode(right).left).value;
                             t:=taddnode(right).right;
                             t.registers32 :=  right.registers32;
                             taddnode(right).right:=nil;
                             right.free;
                             right:=t;
                          end;
                     end
                   else if (right.nodetype=subn) then
                     begin
                        if taddnode(right).right.nodetype=ordconstn then
                          begin
                             extraoffset:=-tordconstnode(taddnode(right).right).value;
                             t:=taddnode(right).left;
                             t.registers32 :=  right.registers32;
                             taddnode(right).left:=nil;
                             right.free;
                             right:=t;
                          end
{ You also have to negate right.right in this case! I can't add an
  unaryminusn without causing a crash, so I've disabled it (JM)
                        else if right.left.nodetype=ordconstn then
                          begin
                             extraoffset:=right.left.value;
                             t:=right.right;
                             t^.registers32 :=  right.registers32;
                             putnode(right);
                             putnode(right.left);
                             right:=t;
                         end;}
                     end;
                   inc(location.reference.offset,
                       get_mul_size*extraoffset);
                end;
              { calculate from left to right }
              if not(location.loc in [LOC_CREFERENCE,LOC_REFERENCE]) then
                { should be internalerror! (JM) }
                CGMessage(cg_e_illegal_expression);
              isjump:=(right.location.loc=LOC_JUMP);
              if isjump then
               begin
                 otl:=truelabel;
                 objectlibrary.getlabel(truelabel);
                 ofl:=falselabel;
                 objectlibrary.getlabel(falselabel);
               end;
              maybe_save(exprasmlist,right.registers32,location,pushedregs);
              secondpass(right);
              maybe_restore(exprasmlist,location,pushedregs);
              { here we change the location of right
                and the update was forgotten so it
                led to wrong code in emitrangecheck later PM
                so make range check before }

              if cs_check_range in aktlocalswitches then
               begin
                 if left.resulttype.def.deftype=arraydef then
                   begin
                     if is_open_array(left.resulttype.def) or
                        is_array_of_const(left.resulttype.def) then
                      begin
                        tarraydef(left.resulttype.def).genrangecheck;
                        srsym:=searchsymonlyin(tloadnode(left).symtable,
                          'high'+tvarsym(tloadnode(left).symtableentry).name);
                        hightree:=cloadnode.create(tvarsym(srsym),tloadnode(left).symtable);
                        firstpass(hightree);
                        secondpass(hightree);
                        location_release(exprasmlist,hightree.location);
                        reference_reset_symbol(href,objectlibrary.newasmsymbol(tarraydef(left.resulttype.def).getrangecheckstring),4);
                        cg.a_load_loc_ref(exprasmlist,hightree.location,href);
                        hightree.free;
                        hightree:=nil;
                      end;
                     cg.g_rangecheck(exprasmlist,right,left.resulttype.def);
                   end;
               end;

              location_force_reg(exprasmlist,right.location,OS_32,false);

              if isjump then
               begin
                 truelabel:=otl;
                 falselabel:=ofl;
               end;

            { produce possible range check code: }
              if cs_check_range in aktlocalswitches then
               begin
                 if left.resulttype.def.deftype=arraydef then
                   begin
                     { done defore (PM) }
                   end
                 else if (left.resulttype.def.deftype=stringdef) then
                   begin
                      case tstringdef(left.resulttype.def).string_typ of
                         { it's the same for ansi- and wide strings }
                         st_widestring,
                         st_ansistring:
                           begin
                              rg.saveusedregisters(exprasmlist,pushed,all_registers);
                              cg.a_param_reg(exprasmlist,OS_INT,right.location.register,paramanager.getintparaloc(1));
                              href:=location.reference;
                              dec(href.offset,7);
                              cg.a_param_ref(exprasmlist,OS_INT,href,paramanager.getintparaloc(1));
                              rg.saveregvars(exprasmlist,all_registers);
                              cg.a_call_name(exprasmlist,'FPC_'+Upper(tstringdef(left.resulttype.def).stringtypname)+'_RANGECHECK');
                              rg.restoreusedregisters(exprasmlist,pushed);
                              cg.g_maybe_loadself(exprasmlist);
                           end;
                         st_shortstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                           end;
                         st_longstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                           end;
                      end;
                   end;
               end;

              { insert the register and the multiplication factor in the
                reference }
              update_reference_reg_mul(right.location.register,get_mul_size);
           end;

        location.size:=newsize;
      end;


begin
   cloadvmtnode:=tcgloadvmtnode;
   chnewnode:=tcghnewnode;
   chdisposenode:=tcghdisposenode;
   caddrnode:=tcgaddrnode;
   cdoubleaddrnode:=tcgdoubleaddrnode;
   cderefnode:=tcgderefnode;
   csubscriptnode:=tcgsubscriptnode;
   cselfnode:=tcgselfnode;
   cwithnode:=tcgwithnode;
   cvecnode:=tcgvecnode;
end.
{
  $Log$
  Revision 1.29  2002-10-05 12:43:25  carl
    * fixes for Delphi 6 compilation
     (warning : Some features do not work under Delphi)

  Revision 1.28  2002/09/17 18:54:02  jonas
    * a_load_reg_reg() now has two size parameters: source and dest. This
      allows some optimizations on architectures that don't encode the
      register size in the register name.

  Revision 1.27  2002/09/07 15:25:03  peter
    * old logs removed and tabs fixed

  Revision 1.26  2002/09/01 18:46:01  peter
    * fixed generic tcgvecnode
    * move code that updates a reference with index register and multiplier
      to separate method so it can be overriden for scaled indexing
    * i386 uses generic tcgvecnode

  Revision 1.25  2002/08/23 16:14:48  peter
    * tempgen cleanup
    * tt_noreuse temp type added that will be used in genentrycode

  Revision 1.24  2002/08/15 08:13:54  carl
    - a_load_sym_ofs_reg removed
    * loadvmt now calls loadaddr_ref_reg instead

  Revision 1.23  2002/08/11 14:32:26  peter
    * renamed current_library to objectlibrary

  Revision 1.22  2002/08/11 13:24:12  peter
    * saving of asmsymbols in ppu supported
    * asmsymbollist global is removed and moved into a new class
      tasmlibrarydata that will hold the info of a .a file which
      corresponds with a single module. Added librarydata to tmodule
      to keep the library info stored for the module. In the future the
      objectfiles will also be stored to the tasmlibrarydata class
    * all getlabel/newasmsymbol and friends are moved to the new class

  Revision 1.21  2002/08/11 11:36:57  jonas
    * always first try to use base and only then index

  Revision 1.20  2002/08/11 06:14:40  florian
    * fixed powerpc compilation problems

  Revision 1.19  2002/08/10 14:46:29  carl
    + moved target_cpu_string to cpuinfo
    * renamed asmmode enum.
    * assembler reader has now less ifdef's
    * move from nppcmem.pas -> ncgmem.pas vec. node.

  Revision 1.18  2002/07/28 21:34:31  florian
    * more powerpc fixes
    + dummy tcgvecnode

  Revision 1.17  2002/07/11 14:41:28  florian
    * start of the new generic parameter handling

  Revision 1.16  2002/07/07 09:52:32  florian
    * powerpc target fixed, very simple units can be compiled
    * some basic stuff for better callparanode handling, far from being finished

  Revision 1.15  2002/07/01 18:46:23  peter
    * internal linker
    * reorganized aasm layer

  Revision 1.14  2002/07/01 16:23:53  peter
    * cg64 patch
    * basics for currency
    * asnode updates for class and interface (not finished)

  Revision 1.13  2002/05/20 13:30:40  carl
  * bugfix of hdisponen (base must be set, not index)
  * more portability fixes

  Revision 1.12  2002/05/18 13:34:09  peter
    * readded missing revisions

  Revision 1.11  2002/05/16 19:46:37  carl
  + defines.inc -> fpcdefs.inc to avoid conflicts if compiling by hand
  + try to fix temp allocation (still in ifdef)
  + generic constructor calls
  + start of tassembler / tmodulebase class cleanup

  Revision 1.9  2002/05/12 16:53:07  peter
    * moved entry and exitcode to ncgutil and cgobj
    * foreach gets extra argument for passing local data to the
      iterator function
    * -CR checks also class typecasts at runtime by changing them
      into as
    * fixed compiler to cycle with the -CR option
    * fixed stabs with elf writer, finally the global variables can
      be watched
    * removed a lot of routines from cga unit and replaced them by
      calls to cgobj
    * u32bit-s32bit updates for and,or,xor nodes. When one element is
      u32bit then the other is typecasted also to u32bit without giving
      a rangecheck warning/error.
    * fixed pascal calling method with reversing also the high tree in
      the parast, detected by tcalcst3 test

  Revision 1.8  2002/04/20 21:32:23  carl
  + generic FPC_CHECKPOINTER
  + first parameter offset in stack now portable
  * rename some constants
  + move some cpu stuff to other units
  - remove unused constents
  * fix stacksize for some targets
  * fix generic size problems which depend now on EXTEND_SIZE constant

  Revision 1.7  2002/04/15 18:58:47  carl
  + target_info.size_of_pointer -> pointer_Size

  Revision 1.6  2002/04/04 19:05:57  peter
    * removed unused units
    * use tlocation.size in cg.a_*loc*() routines

}
