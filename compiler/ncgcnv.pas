{
    $Id$
    Copyright (c) 2000-2002 by Florian Klaempfl

    Generate assembler for nodes that handle type conversions which are
    the same for all (most) processors

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
unit ncgcnv;

{$i fpcdefs.inc}

interface

    uses
       node,ncnv,defutil,defcmp;

    type
       tcgtypeconvnode = class(ttypeconvnode)
         procedure second_int_to_int;override;
         procedure second_cstring_to_pchar;override;
         procedure second_string_to_chararray;override;
         procedure second_array_to_pointer;override;
         procedure second_pointer_to_array;override;
         procedure second_char_to_string;override;
         procedure second_real_to_real;override;
         procedure second_cord_to_pointer;override;
         procedure second_proc_to_procvar;override;
         procedure second_bool_to_int;override;
         procedure second_bool_to_bool;override;
         procedure second_ansistring_to_pchar;override;
         procedure second_class_to_intf;override;
         procedure second_char_to_char;override;
         procedure second_nothing;override;
         procedure pass_2;override;
       end;

       tcgasnode = class(tasnode)
         procedure pass_2;override;
       end;

  implementation

    uses
      cutils,verbose,globtype,globals,
      aasmbase,aasmtai,aasmcpu,symconst,symdef,paramgr,
      ncon,ncal,
      cpubase,cpuinfo,systems,
      pass_2,
      procinfo,cgbase,
      cgutils,cgobj,
      ncgutil,
      tgobj
      ;


    procedure tcgtypeconvnode.second_int_to_int;
      var
        newsize : tcgsize;
        ressize,
        leftsize : longint;
      begin
        newsize:=def_cgsize(resulttype.def);

        { insert range check if not explicit conversion }
        if not(nf_explicit in flags) then
          cg.g_rangecheck(exprasmlist,left.location,left.resulttype.def,resulttype.def);

        { is the result size smaller? when typecasting from void
          we always reuse the current location, because there is
          nothing that we can load in a register }
        ressize := resulttype.def.size;
        leftsize := left.resulttype.def.size;
        if (ressize<>leftsize) and
           not is_void(left.resulttype.def) then
          begin
            location_copy(location,left.location);
            { reuse a loc_reference when the newsize is smaller than
              than the original, else load it to a register }
            if (location.loc in [LOC_REFERENCE,LOC_CREFERENCE]) and
               (ressize<leftsize) then
             begin
               location.size:=newsize;
               if (target_info.endian = ENDIAN_BIG) then
                 inc(location.reference.offset,leftsize-ressize);
             end
            else
             location_force_reg(exprasmlist,location,newsize,false);
          end
        else
          begin
            { no special loading is required, reuse current location }
            location_copy(location,left.location);
            location.size:=newsize;
          end;
      end;


    procedure tcgtypeconvnode.second_cstring_to_pchar;

      var
        hr : treference;

      begin
         location_release(exprasmlist,left.location);
         location_reset(location,LOC_REGISTER,OS_ADDR);
         case tstringdef(left.resulttype.def).string_typ of
           st_shortstring :
             begin
               inc(left.location.reference.offset);
               location.register:=cg.getaddressregister(exprasmlist);
               cg.a_loadaddr_ref_reg(exprasmlist,left.location.reference,location.register);
             end;
         {$ifdef ansistring_bits}
           st_ansistring16,st_ansistring32,st_ansistring64 :
         {$else}
           st_ansistring :
         {$endif}
             begin
               if (left.nodetype=stringconstn) and
                  (str_length(left)=0) then
                begin
                  reference_reset(hr);
                  hr.symbol:=objectlibrary.newasmsymbol('FPC_EMPTYCHAR',AB_EXTERNAL,AT_DATA);
                  location.register:=cg.getaddressregister(exprasmlist);
                  cg.a_loadaddr_ref_reg(exprasmlist,hr,location.register);
                end
               else
                begin
                  location.register:=cg.getaddressregister(exprasmlist);
                  cg.a_load_ref_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.reference,location.register);
                end;
             end;
           st_longstring:
             begin
               {!!!!!!!}
               internalerror(8888);
             end;
           st_widestring:
             begin
               if (left.nodetype=stringconstn) and
                  (str_length(left)=0) then
                begin
                  reference_reset(hr);
                  hr.symbol:=objectlibrary.newasmsymbol('FPC_EMPTYCHAR',AB_EXTERNAL,AT_DATA);
                  location.register:=cg.getaddressregister(exprasmlist);
                  cg.a_loadaddr_ref_reg(exprasmlist,hr,location.register);
                end
               else
                begin
                  location.register:=cg.getintregister(exprasmlist,OS_INT);
{$ifdef fpc}
{$warning Todo: convert widestrings to ascii when typecasting them to pchars}
{$endif}
                  cg.a_load_ref_reg(exprasmlist,OS_ADDR,OS_INT,left.location.reference,
                    location.register);
                end;
             end;
         end;
      end;


    procedure tcgtypeconvnode.second_string_to_chararray;

      var
        arrsize: longint;

      begin
         with tarraydef(resulttype.def) do
           arrsize := highrange-lowrange+1;
         if (left.nodetype = stringconstn) and
            { left.length+1 since there's always a terminating #0 character (JM) }
            (tstringconstnode(left).len+1 >= arrsize) and
            (tstringdef(left.resulttype.def).string_typ=st_shortstring) then
           begin
             location_copy(location,left.location);
             inc(location.reference.offset);
             exit;
           end
         else
           { should be handled already in resulttype pass (JM) }
           internalerror(200108292);
      end;


    procedure tcgtypeconvnode.second_array_to_pointer;

      begin
         location_release(exprasmlist,left.location);
         location_reset(location,LOC_REGISTER,OS_ADDR);
         location.register:=cg.getaddressregister(exprasmlist);
         cg.a_loadaddr_ref_reg(exprasmlist,left.location.reference,location.register);
      end;


    procedure tcgtypeconvnode.second_pointer_to_array;

      begin
        location_reset(location,LOC_REFERENCE,OS_NO);
        case left.location.loc of
          LOC_REGISTER :
            begin
            {$ifdef cpu_uses_separate_address_registers}
              if getregtype(left.location.register)<>R_ADDRESSREGISTER then
                begin
                  location_release(exprasmlist,left.location);
                  location.reference.base:=rg.getaddressregister(exprasmlist);
                  cg.a_load_reg_reg(exprasmlist,OS_ADDR,OS_ADDR,
                          left.location.register,location.reference.base);
                end
              else
            {$endif}
                location.reference.base := left.location.register;
            end;
          LOC_CREGISTER :
            begin
              location.reference.base:=cg.getaddressregister(exprasmlist);
              cg.a_load_reg_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.register,
                location.reference.base);
            end;
          LOC_REFERENCE,
          LOC_CREFERENCE :
            begin
              location_release(exprasmlist,left.location);
              location.reference.base:=cg.getaddressregister(exprasmlist);
              cg.a_load_ref_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.reference,
                location.reference.base);
              location_freetemp(exprasmlist,left.location);
            end;
          else
            internalerror(2002032216);
        end;
      end;


    procedure tcgtypeconvnode.second_char_to_string;
      begin
         location_reset(location,LOC_REFERENCE,OS_NO);
         case tstringdef(resulttype.def).string_typ of
           st_shortstring :
             begin
               location_release(exprasmlist,left.location);
               tg.GetTemp(exprasmlist,256,tt_normal,location.reference);
               cg.a_load_loc_ref(exprasmlist,left.location.size,left.location,
                 location.reference);
               location_freetemp(exprasmlist,left.location);
             end;
           { the rest is removed in the resulttype pass and converted to compilerprocs }
           else
            internalerror(4179);
        end;
      end;


    procedure tcgtypeconvnode.second_real_to_real;
      begin
         location_reset(location,LOC_FPUREGISTER,def_cgsize(resulttype.def));
         case left.location.loc of
            LOC_FPUREGISTER,
            LOC_CFPUREGISTER:
              begin
                location_copy(location,left.location);
                location.size:=def_cgsize(resulttype.def);
                case expectloc of
                  LOC_FPUREGISTER:
                    ;
                  LOC_MMREGISTER:
                    location_force_mmregscalar(exprasmlist,location,false);
                  else
                    internalerror(2003012262);
                end;
                exit
              end;
            LOC_CREFERENCE,
            LOC_REFERENCE:
              begin
                 location_release(exprasmlist,left.location);
                 location.register:=cg.getfpuregister(exprasmlist,left.location.size);
                 cg.a_loadfpu_loc_reg(exprasmlist,left.location,location.register);
                 location_freetemp(exprasmlist,left.location);
              end;
            LOC_MMREGISTER,
            LOC_CMMREGISTER:
              begin
                location_copy(location,left.location);
                case expectloc of
                  LOC_FPUREGISTER:
                    begin
                      location_force_fpureg(exprasmlist,location,false);
                      location.size:=def_cgsize(resulttype.def);
                    end;
                  LOC_MMREGISTER:
                    ;
                  else
                    internalerror(2003012261);
                end;
              end;
            else
              internalerror(2002032215);
         end;
      end;


    procedure tcgtypeconvnode.second_cord_to_pointer;
      begin
        { this can't happen because constants are already processed in
          pass 1 }
        internalerror(47423985);
      end;


    procedure tcgtypeconvnode.second_proc_to_procvar;

      begin
        { method pointer ? }
        if tabstractprocdef(left.resulttype.def).is_methodpointer and
           not(tabstractprocdef(left.resulttype.def).is_addressonly) then
          begin
             location_copy(location,left.location);
          end
        else
          begin
             location_release(exprasmlist,left.location);
             location_reset(location,LOC_REGISTER,OS_ADDR);
             location.register:=cg.getaddressregister(exprasmlist);
             cg.a_loadaddr_ref_reg(exprasmlist,left.location.reference,location.register);
          end;
      end;


    procedure tcgtypeconvnode.second_bool_to_int;
      var
         oldtruelabel,oldfalselabel : tasmlabel;
      begin
         oldtruelabel:=truelabel;
         oldfalselabel:=falselabel;
         objectlibrary.getlabel(truelabel);
         objectlibrary.getlabel(falselabel);
         secondpass(left);
         location_copy(location,left.location);
         { byte(boolean) or word(wordbool) or longint(longbool) must }
         { be accepted for var parameters                            }
         if not((nf_explicit in flags) and
                (left.resulttype.def.size=resulttype.def.size) and
                (left.location.loc in [LOC_REFERENCE,LOC_CREFERENCE,LOC_CREGISTER])) then
           location_force_reg(exprasmlist,location,def_cgsize(resulttype.def),false);
         truelabel:=oldtruelabel;
         falselabel:=oldfalselabel;
      end;


    procedure tcgtypeconvnode.second_bool_to_bool;
      begin
        { we can reuse the conversion already available
          in bool_to_int to resize the value. But when the
          size of the new boolean is smaller we need to calculate
          the value as is done in int_to_bool. This is needed because
          the bits that define the true status can be outside the limits
          of the new size and truncating the register can result in a 0
          value }
        if resulttype.def.size<left.resulttype.def.size then
          second_int_to_bool
        else
          second_bool_to_int;
      end;


    procedure tcgtypeconvnode.second_ansistring_to_pchar;
      var
         l1 : tasmlabel;
         hr : treference;
      begin
         location_reset(location,LOC_REGISTER,OS_ADDR);
         objectlibrary.getlabel(l1);
         case left.location.loc of
            LOC_CREGISTER,LOC_REGISTER:
              begin
               {$ifdef cpu_uses_separate_address_registers}
                 if getregtype(left.location.register)<>R_ADDRESSREGISTER then
                   begin
                     location_release(exprasmlist,left.location);
                     location.register:=cg.getaddressregister(exprasmlist);
                     cg.a_load_reg_reg(exprasmlist,OS_ADDR,OS_ADDR,
                              left.location.register,location.register);
                   end
                 else
               {$endif}
                    location.register := left.location.register;
              end;
            LOC_CREFERENCE,LOC_REFERENCE:
              begin
                location_release(exprasmlist,left.location);
                location.register:=cg.getaddressregister(exprasmlist);
                cg.a_load_ref_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.reference,location.register);
                location_freetemp(exprasmlist,left.location);
              end;
            else
              internalerror(2002032214);
         end;
         cg.a_cmp_const_reg_label(exprasmlist,OS_ADDR,OC_NE,0,location.register,l1);
         reference_reset(hr);
         hr.symbol:=objectlibrary.newasmsymbol('FPC_EMPTYCHAR',AB_EXTERNAL,AT_DATA);
         cg.a_loadaddr_ref_reg(exprasmlist,hr,location.register);
         cg.a_label(exprasmlist,l1);
      end;


    procedure tcgtypeconvnode.second_class_to_intf;
      var
         l1 : tasmlabel;
         hd : tobjectdef;
      begin
         location_reset(location,LOC_REGISTER,OS_ADDR);
         case left.location.loc of
            LOC_CREFERENCE,
            LOC_REFERENCE:
              begin
                 location_release(exprasmlist,left.location);
                 location.register:=cg.getaddressregister(exprasmlist);
                 cg.a_load_ref_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.reference,location.register);
                 location_freetemp(exprasmlist,left.location);
              end;
            LOC_CREGISTER:
              begin
                 location.register:=cg.getaddressregister(exprasmlist);
                 cg.a_load_reg_reg(exprasmlist,OS_ADDR,OS_ADDR,left.location.register,location.register);
              end;
            LOC_REGISTER:
              location.register:=left.location.register;
            else
              internalerror(121120001);
         end;
         objectlibrary.getlabel(l1);
         cg.a_cmp_const_reg_label(exprasmlist,OS_ADDR,OC_EQ,0,location.register,l1);
         hd:=tobjectdef(left.resulttype.def);
         while assigned(hd) do
           begin
              if hd.implementedinterfaces.searchintf(resulttype.def)<>-1 then
                begin
                   cg.a_op_const_reg(exprasmlist,OP_ADD,OS_ADDR,
                     hd.implementedinterfaces.ioffsets(
                       hd.implementedinterfaces.searchintf(resulttype.def))^,location.register);
                   break;
                end;
              hd:=hd.childof;
           end;
         if hd=nil then
           internalerror(2002081301);
         cg.a_label(exprasmlist,l1);
      end;


    procedure tcgtypeconvnode.second_char_to_char;
      begin
{$ifdef fpc}
        {$warning todo: add RTL routine for widechar-char conversion }
{$endif}
        { Quick hack to at least generate 'working' code (PFV) }
        second_int_to_int;
      end;


    procedure tcgtypeconvnode.second_nothing;
      begin
        { we reuse the old value }
        location_copy(location,left.location);

        { Floats should never be returned as LOC_CONSTANT, do the
          moving to memory before the new size is set }
        if (resulttype.def.deftype=floatdef) and
           (location.loc=LOC_CONSTANT) then
         location_force_mem(exprasmlist,location);

        { but use the new size, but we don't know the size of all arrays }
        location.size:=def_cgsize(resulttype.def);
      end;


{$ifdef TESTOBJEXT2}
    procedure tcgtypeconvnode.checkobject;
      begin
        { no checking by default }
      end;
{$endif TESTOBJEXT2}


    procedure tcgtypeconvnode.pass_2;
      begin
        { the boolean routines can be called with LOC_JUMP and
          call secondpass themselves in the helper }
        if not(convtype in [tc_bool_2_int,tc_bool_2_bool,tc_int_2_bool]) then
         begin
           secondpass(left);
           if codegenerror then
            exit;
         end;

        second_call_helper(convtype);

{$ifdef TESTOBJEXT2}
         { Check explicit conversions to objects pointers !! }
         if p^.explizit and
            (p^.resulttype.def.deftype=pointerdef) and
            (tpointerdef(p^.resulttype.def).definition.deftype=objectdef) and not
            (tobjectdef(tpointerdef(p^.resulttype.def).definition).isclass) and
            ((tobjectdef(tpointerdef(p^.resulttype.def).definition).options and oo_hasvmt)<>0) and
            (cs_check_range in aktlocalswitches) then
           checkobject;
{$endif TESTOBJEXT2}
      end;


    procedure tcgasnode.pass_2;
      begin
        secondpass(call);
        location_copy(location,call.location);
      end;


begin
  ctypeconvnode := tcgtypeconvnode;
  casnode := tcgasnode;
end.

{
  $Log$
  Revision 1.59  2004-06-20 08:55:29  florian
    * logs truncated

  Revision 1.58  2004/06/16 20:07:08  florian
    * dwarf branch merged

  Revision 1.57  2004/04/29 19:56:37  daniel
    * Prepare compiler infrastructure for multiple ansistring types

  Revision 1.56.2.1  2004/04/27 18:18:25  peter
    * aword -> aint

  Revision 1.56  2004/03/02 00:36:33  olle
    * big transformation of Tai_[const_]Symbol.Create[data]name*

  Revision 1.55  2004/02/27 10:21:05  florian
    * top_symbol killed
    + refaddr to treference added
    + refsymbol to treference added
    * top_local stuff moved to an extra record to save memory
    + aint introduced
    * tppufile.get/putint64/aint implemented

}
