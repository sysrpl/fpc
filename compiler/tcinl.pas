{
    $Id$
    Copyright (c) 1993-98 by Florian Klaempfl

    Type checking and register allocation for inline nodes

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
unit tcinl;
interface

    uses
      tree;

    procedure firstinline(var p : ptree);


implementation

    uses
      cobjects,verbose,globals,systems,
      symtable,aasm,types,
      hcodegen,htypechk,pass_1,
      tccal,tcld
{$ifdef i386}
      ,i386,tgeni386
{$endif}
{$ifdef m68k}
      ,m68k,tgen68k
{$endif}
      ;

{*****************************************************************************
                             FirstInLine
*****************************************************************************}

    procedure firstinline(var p : ptree);
      var
         vl      : longint;
         vr      : bestreal;
         hp,hpp  : ptree;
         store_count_ref,
         isreal,
         dowrite,
         store_valid,
         file_is_typed : boolean;

      procedure do_lowhigh(adef : pdef);

        var
           v : longint;
           enum : penumsym;

        begin
           case Adef^.deftype of
             orddef:
               begin
                  if p^.inlinenumber=in_low_x then
                    v:=porddef(Adef)^.low
                  else
                    v:=porddef(Adef)^.high;
                  hp:=genordinalconstnode(v,adef);
                  firstpass(hp);
                  disposetree(p);
                  p:=hp;
               end;
             enumdef:
               begin
                  enum:=Penumdef(Adef)^.first;
                  if p^.inlinenumber=in_high_x then
                    while enum^.next<>nil do
                      enum:=enum^.next;
                  hp:=genenumnode(enum);
                  disposetree(p);
                  p:=hp;
               end
           end;
        end;

      begin
         store_valid:=must_be_valid;
         store_count_ref:=count_ref;
         count_ref:=false;
         if not (p^.inlinenumber in [in_read_x,in_readln_x,in_sizeof_x,
            in_typeof_x,in_ord_x,in_str_x_string,
            in_reset_typedfile,in_rewrite_typedfile]) then
           must_be_valid:=true
         else
           must_be_valid:=false;
         { if we handle writeln; p^.left contains no valid address }
         if assigned(p^.left) then
           begin
              if p^.left^.treetype=callparan then
                firstcallparan(p^.left,nil)
              else
                firstpass(p^.left);
              left_right_max(p);
              set_location(p^.location,p^.left^.location);
           end;
         { handle intern constant functions in separate case }
         if p^.inlineconst then
          begin
            { no parameters? }
            if not assigned(p^.left) then
             begin
               case p^.inlinenumber of
            in_const_pi : begin
                            hp:=genrealconstnode(pi);
                          end;
               else
                 internalerror(89);
               end;
             end
            else
            { process constant expression with parameter }
             begin
               if not(p^.left^.treetype in [realconstn,ordconstn]) then
                begin
                  CGMessage(cg_e_illegal_expression);
                  vl:=0;
                  vr:=0;
                  isreal:=false;
                end
               else
                begin
                  isreal:=(p^.left^.treetype=realconstn);
                  vl:=p^.left^.value;
                  vr:=p^.left^.value_real;
                end;
               case p^.inlinenumber of
         in_const_trunc : begin
                            if isreal then
                             hp:=genordinalconstnode(trunc(vr),s32bitdef)
                            else
                             hp:=genordinalconstnode(trunc(vl),s32bitdef);
                          end;
         in_const_round : begin
                            if isreal then
                             hp:=genordinalconstnode(round(vr),s32bitdef)
                            else
                             hp:=genordinalconstnode(round(vl),s32bitdef);
                          end;
          in_const_frac : begin
                            if isreal then
                             hp:=genrealconstnode(frac(vr))
                            else
                             hp:=genrealconstnode(frac(vl));
                          end;
           in_const_int : begin
                            if isreal then
                             hp:=genrealconstnode(int(vr))
                            else
                             hp:=genrealconstnode(int(vl));
                          end;
           in_const_abs : begin
                            if isreal then
                             hp:=genrealconstnode(abs(vr))
                            else
                             hp:=genordinalconstnode(abs(vl),p^.left^.resulttype);
                          end;
           in_const_sqr : begin
                            if isreal then
                             hp:=genrealconstnode(sqr(vr))
                            else
                             hp:=genordinalconstnode(sqr(vl),p^.left^.resulttype);
                          end;
           in_const_odd : begin
                            if isreal then
                             CGMessage(type_e_integer_expr_expected)
                            else
                             hp:=genordinalconstnode(byte(odd(vl)),booldef);
                          end;
     in_const_swap_word : begin
                            if isreal then
                             CGMessage(type_e_integer_expr_expected)
                            else
                             hp:=genordinalconstnode((vl and $ff) shl 8+(vl shr 8),p^.left^.resulttype);
                          end;
     in_const_swap_long : begin
                            if isreal then
                             CGMessage(type_e_mismatch)
                            else
                             hp:=genordinalconstnode((vl and $ffff) shl 16+(vl shr 16),p^.left^.resulttype);
                          end;
           in_const_ptr : begin
                            if isreal then
                             CGMessage(type_e_mismatch)
                            else
                             hp:=genordinalconstnode(vl,voidpointerdef);
                          end;
          in_const_sqrt : begin
                            if isreal then
                             hp:=genrealconstnode(sqrt(vr))
                            else
                             hp:=genrealconstnode(sqrt(vl));
                          end;
        in_const_arctan : begin
                            if isreal then
                             hp:=genrealconstnode(arctan(vr))
                            else
                             hp:=genrealconstnode(arctan(vl));
                          end;
           in_const_cos : begin
                            if isreal then
                             hp:=genrealconstnode(cos(vr))
                            else
                             hp:=genrealconstnode(cos(vl));
                          end;
           in_const_sin : begin
                            if isreal then
                             hp:=genrealconstnode(sin(vr))
                            else
                             hp:=genrealconstnode(sin(vl));
                          end;
           in_const_exp : begin
                            if isreal then
                             hp:=genrealconstnode(exp(vr))
                            else
                             hp:=genrealconstnode(exp(vl));
                          end;
            in_const_ln : begin
                            if isreal then
                             hp:=genrealconstnode(ln(vr))
                            else
                             hp:=genrealconstnode(ln(vl));
                          end;
               else
                 internalerror(88);
               end;
             end;
            disposetree(p);
            firstpass(hp);
            p:=hp;
          end
         else
          begin
            case p^.inlinenumber of
             in_lo_long,in_hi_long,
             in_lo_word,in_hi_word:
               begin
                  if p^.registers32<1 then
                    p^.registers32:=1;
                  if p^.inlinenumber in [in_lo_word,in_hi_word] then
                    p^.resulttype:=u8bitdef
                  else
                    p^.resulttype:=u16bitdef;
                  p^.location.loc:=LOC_REGISTER;
                  if not is_integer(p^.left^.resulttype) then
                    CGMessage(type_e_mismatch)
                  else
                    begin
                      if p^.left^.treetype=ordconstn then
                       begin
                         case p^.inlinenumber of
                          in_lo_word : hp:=genordinalconstnode(p^.left^.value and $ff,p^.left^.resulttype);
                          in_hi_word : hp:=genordinalconstnode(p^.left^.value shr 8,p^.left^.resulttype);
                          in_lo_long : hp:=genordinalconstnode(p^.left^.value and $ffff,p^.left^.resulttype);
                          in_hi_long : hp:=genordinalconstnode(p^.left^.value shr 16,p^.left^.resulttype);
                         end;
                         disposetree(p);
                         firstpass(hp);
                         p:=hp;
                       end;
                    end;
               end;
             in_sizeof_x:
               begin
                  if p^.registers32<1 then
                    p^.registers32:=1;
                  p^.resulttype:=s32bitdef;
                  p^.location.loc:=LOC_REGISTER;
               end;
             in_typeof_x:
               begin
                  if p^.registers32<1 then
                    p^.registers32:=1;
                  p^.location.loc:=LOC_REGISTER;
                  p^.resulttype:=voidpointerdef;
               end;
             in_ord_x:
               begin
                  if (p^.left^.treetype=ordconstn) then
                    begin
                       hp:=genordinalconstnode(p^.left^.value,s32bitdef);
                       disposetree(p);
                       p:=hp;
                       firstpass(p);
                    end
                  else
                    begin
                       if (p^.left^.resulttype^.deftype=orddef) then
                         if (porddef(p^.left^.resulttype)^.typ in [uchar,bool8bit]) then
                           begin
                              if porddef(p^.left^.resulttype)^.typ=bool8bit then
                                begin
                                   hp:=gentypeconvnode(p^.left,u8bitdef);
                                   putnode(p);
                                   p:=hp;
                                   p^.convtyp:=tc_bool_2_int;
                                   p^.explizit:=true;
                                   firstpass(p);
                                end
                              else
                                begin
                                   hp:=gentypeconvnode(p^.left,u8bitdef);
                                   putnode(p);
                                   p:=hp;
                                   p^.explizit:=true;
                                   firstpass(p);
                                end;
                           end
                         { can this happen ? }
                         else if (porddef(p^.left^.resulttype)^.typ=uvoid) then
                           CGMessage(type_e_mismatch)
                         else
                           { all other orddef need no transformation }
                           begin
                              hp:=p^.left;
                              putnode(p);
                              p:=hp;
                           end
                       else if (p^.left^.resulttype^.deftype=enumdef) then
                         begin
                            hp:=gentypeconvnode(p^.left,s32bitdef);
                            putnode(p);
                            p:=hp;
                            p^.explizit:=true;
                            firstpass(p);
                         end
                       else
                         begin
                            { can anything else be ord() ?}
                            CGMessage(type_e_mismatch);
                         end;
                    end;
               end;
             in_chr_byte:
               begin
                  hp:=gentypeconvnode(p^.left,cchardef);
                  putnode(p);
                  p:=hp;
                  p^.explizit:=true;
                  firstpass(p);
               end;
             in_length_string:
               begin
{$ifdef UseAnsiString}
                  if is_ansistring(p^.left^.resulttype) then
                    p^.resulttype:=s32bitdef
                  else
{$endif UseAnsiString}
                    p^.resulttype:=u8bitdef;
                  { wer don't need string conversations here }
                  if (p^.left^.treetype=typeconvn) and
                     (p^.left^.left^.resulttype^.deftype=stringdef) then
                    begin
                       hp:=p^.left^.left;
                       putnode(p^.left);
                       p^.left:=hp;
                    end;

                  { evalutes length of constant strings direct }
                  if (p^.left^.treetype=stringconstn) then
                    begin
{$ifdef UseAnsiString}
                       hp:=genordinalconstnode(p^.left^.length,s32bitdef);
{$else UseAnsiString}
                       hp:=genordinalconstnode(length(p^.left^.value_str^),s32bitdef);
{$endif UseAnsiString}
                       disposetree(p);
                       firstpass(hp);
                       p:=hp;
                    end;
               end;
             in_assigned_x:
               begin
                  p^.resulttype:=booldef;
                  p^.location.loc:=LOC_FLAGS;
               end;
             in_pred_x,
             in_succ_x:
               begin
                  inc(p^.registers32);
                  p^.resulttype:=p^.left^.resulttype;
                  p^.location.loc:=LOC_REGISTER;
                  if not is_ordinal(p^.resulttype) then
                    CGMessage(type_e_ordinal_expr_expected)
                  else
                    begin
                      if (p^.resulttype^.deftype=enumdef) and
                         (penumdef(p^.resulttype)^.has_jumps) then
                        CGMessage(type_e_succ_and_pred_enums_with_assign_not_possible)
                      else
                        if p^.left^.treetype=ordconstn then
                         begin
                           if p^.inlinenumber=in_succ_x then
                             hp:=genordinalconstnode(p^.left^.value+1,p^.left^.resulttype)
                           else
                             hp:=genordinalconstnode(p^.left^.value-1,p^.left^.resulttype);
                           disposetree(p);
                           firstpass(hp);
                           p:=hp;
                         end;
                    end;
               end;
            in_inc_x,
            in_dec_x:
              begin
                 p^.resulttype:=voiddef;
                 if assigned(p^.left) then
                   begin
                      firstcallparan(p^.left,nil);
                      if codegenerror then
                       exit;
                      { first param must be var }
                      if is_constnode(p^.left^.left) then
                        CGMessage(type_e_variable_id_expected);
                      { check type }
                      if (p^.left^.resulttype^.deftype in [enumdef,pointerdef]) or
                         is_ordinal(p^.left^.resulttype) then
                        begin
                           { two paras ? }
                           if assigned(p^.left^.right) then
                             begin
                                { insert a type conversion         }
                                { the second param is always longint }
                                p^.left^.right^.left:=gentypeconvnode(p^.left^.right^.left,s32bitdef);
                                { check the type conversion }
                                firstpass(p^.left^.right^.left);

                                { need we an additional register ? }
                                if not(is_constintnode(p^.left^.right^.left)) and
                                  (p^.left^.right^.left^.location.loc in [LOC_MEM,LOC_REFERENCE]) and
                                  (p^.left^.right^.left^.registers32<1) then
                                  inc(p^.registers32);

                                if assigned(p^.left^.right^.right) then
                                  CGMessage(cg_e_illegal_expression);
                             end;
                        end
                      else
                        CGMessage(type_e_ordinal_expr_expected);
                   end
                 else
                   CGMessage(type_e_mismatch);
              end;
             in_read_x,
             in_readln_x,
             in_write_x,
             in_writeln_x :
               begin
                  { needs a call }
                  procinfo.flags:=procinfo.flags or pi_do_call;
                  p^.resulttype:=voiddef;
                  { we must know if it is a typed file or not }
                  { but we must first do the firstpass for it }
                  file_is_typed:=false;
                  if assigned(p^.left) then
                    begin
                       firstcallparan(p^.left,nil);
                       { now we can check }
                       hp:=p^.left;
                       while assigned(hp^.right) do
                         hp:=hp^.right;
                       { if resulttype is not assigned, then automatically }
                       { file is not typed.                                }
                       if assigned(hp) and assigned(hp^.resulttype) then
                         Begin
                           if (hp^.resulttype^.deftype=filedef) and
                              (pfiledef(hp^.resulttype)^.filetype=ft_typed) then
                            begin
                              file_is_typed:=true;
                              { test the type }
                              hpp:=p^.left;
                              while (hpp<>hp) do
                               begin
                                 if (hpp^.left^.treetype=typen) then
                                   CGMessage(type_e_cant_read_write_type);
                                 if not is_equal(hpp^.resulttype,pfiledef(hp^.resulttype)^.typed_as) then
                                   CGMessage(type_e_mismatch);
                                 hpp:=hpp^.right;
                               end;
                            end;
                         end; { endif assigned(hp) }

                       { insert type conversions for write(ln) }
                       if (not file_is_typed) then
                         begin
                            dowrite:=(p^.inlinenumber in [in_write_x,in_writeln_x]);
                            hp:=p^.left;
                            while assigned(hp) do
                              begin
                                if (hp^.left^.treetype=typen) then
                                  CGMessage(type_e_cant_read_write_type);
                                if assigned(hp^.left^.resulttype) then
                                  begin
                                    isreal:=false;
                                    case hp^.left^.resulttype^.deftype of
                                      filedef : begin
                                                { only allowed as first parameter }
                                                  if assigned(hp^.right) then
                                                   CGMessage(type_e_cant_read_write_type);
                                                end;
                                    stringdef : ;
                                   pointerdef : begin
                                                  if not is_equal(ppointerdef(hp^.left^.resulttype)^.definition,cchardef) then
                                                    CGMessage(type_e_cant_read_write_type);
                                                end;
                                     floatdef : begin
                                                  isreal:=true;
                                                end;
                                       orddef : begin
                                                  case porddef(hp^.left^.resulttype)^.typ of
                                                     uchar,
                                             u32bit,s32bit : ;
                                               u8bit,s8bit,
                                             u16bit,s16bit : if dowrite then
                                                              hp^.left:=gentypeconvnode(hp^.left,s32bitdef);
                                                  bool8bit,
                                       bool16bit,bool32bit : if dowrite then
                                                              hp^.left:=gentypeconvnode(hp^.left,booldef)
                                                             else
                                                              CGMessage(type_e_cant_read_write_type);
                                                  else
                                                    CGMessage(type_e_cant_read_write_type);
                                                  end;
                                                end;
                                     arraydef : begin
                                                  if not((parraydef(hp^.left^.resulttype)^.lowrange=0) and
                                                         is_equal(parraydef(hp^.left^.resulttype)^.definition,cchardef)) then
                                                   begin
                                                   { but we convert only if the first index<>0,
                                                     because in this case we have a ASCIIZ string }
                                                     if dowrite and
                                                        (parraydef(hp^.left^.resulttype)^.lowrange<>0) and
                                                        (parraydef(hp^.left^.resulttype)^.definition^.deftype=orddef) and
                                                        (porddef(parraydef(hp^.left^.resulttype)^.definition)^.typ=uchar) then
                                                       hp^.left:=gentypeconvnode(hp^.left,cstringdef)
                                                     else
                                                       CGMessage(type_e_cant_read_write_type);
                                                   end;
                                                end;
                                    else
                                      CGMessage(type_e_cant_read_write_type);
                                    end;

                                    { some format options ? }
                                    (* commented
                                       because supposes reverse order of parameters
                                          PM
                                    hpp:=hp^.right;
                                    if assigned(hpp) and hpp^.is_colon_para then
                                      begin
                                        if (not is_integer(hpp^.resulttype)) then
                                          CGMessage(type_e_integer_expr_expected)
                                        else
                                          hpp^.left:=gentypeconvnode(hpp^.left,s32bitdef);
                                        hpp:=hpp^.right;
                                        if assigned(hpp) and hpp^.is_colon_para then
                                          begin
                                            if isreal then
                                             begin
                                               if (not is_integer(hpp^.resulttype)) then
                                                 CGMessage(type_e_integer_expr_expected)
                                               else
                                                 hpp^.left:=gentypeconvnode(hpp^.left,s32bitdef);
                                             end
                                            else
                                             CGMessage(parser_e_illegal_colon_qualifier);
                                          end;
                                      end;  *)

                                  end;
                                 hp:=hp^.right;
                              end;
                         end;
                       { pass all parameters again for the typeconversions }
                       if codegenerror then
                         exit;
                       must_be_valid:=true;
                       firstcallparan(p^.left,nil);
                       { calc registers }
                       left_right_max(p);
                    end;
               end;
            in_settextbuf_file_x :
              begin
                 { warning here p^.left is the callparannode
                   not the argument directly }
                 { p^.left^.left is text var }
                 { p^.left^.right^.left is the buffer var }
                 { firstcallparan(p^.left,nil);
                   already done in firstcalln }
                 { now we know the type of buffer }
                 getsymonlyin(systemunit,'SETTEXTBUF');
                 hp:=gencallnode(pprocsym(srsym),systemunit);
                 hp^.left:=gencallparanode(
                   genordinalconstnode(p^.left^.left^.resulttype^.size,s32bitdef),p^.left);
                 putnode(p);
                 p:=hp;
                 firstpass(p);
              end;
             { the firstpass of the arg has been done in firstcalln ? }
             in_reset_typedfile,in_rewrite_typedfile :
               begin
                  procinfo.flags:=procinfo.flags or pi_do_call;
                  { to be sure the right definition is loaded }
                  p^.left^.resulttype:=nil;
                  firstload(p^.left);
                  p^.resulttype:=voiddef;
               end;
             in_str_x_string :
               begin
                  procinfo.flags:=procinfo.flags or pi_do_call;
                  p^.resulttype:=voiddef;
                  if assigned(p^.left) then
                    begin
                       hp:=p^.left^.right;
                       { first pass just the string for first local use }
                       must_be_valid:=false;
                       count_ref:=true;
                       p^.left^.right:=nil;
                       firstcallparan(p^.left,nil);
                       must_be_valid:=true;
                       p^.left^.right:=hp;
                       firstcallparan(p^.left^.right,nil);
                       hp:=p^.left;
                       { valid string ? }
                       if not assigned(hp) or
                          (hp^.left^.resulttype^.deftype<>stringdef) or
                          (hp^.right=nil) or
                          (hp^.left^.location.loc<>LOC_REFERENCE) then
                         CGMessage(cg_e_illegal_expression);
                       { !!!! check length of string }

                       while assigned(hp^.right) do
                         hp:=hp^.right;
                       { check and convert the first param }
                       if hp^.is_colon_para then
                         CGMessage(cg_e_illegal_expression);

                       isreal:=false;
                       case hp^.resulttype^.deftype of
                        orddef : begin
                                   case porddef(hp^.left^.resulttype)^.typ of
                              u32bit,s32bit : ;
                                u8bit,s8bit,
                              u16bit,s16bit : hp^.left:=gentypeconvnode(hp^.left,s32bitdef);
                                   else
                                     CGMessage(type_e_integer_or_real_expr_expected);
                                   end;
                                 end;
                      floatdef : begin
                                   isreal:=true;
                                 end;
                       else
                         CGMessage(type_e_integer_or_real_expr_expected);
                       end;

                       { some format options ? }
                       hpp:=p^.left^.right;
                       if assigned(hpp) and hpp^.is_colon_para then
                         begin
                           if (not is_integer(hpp^.resulttype)) then
                             CGMessage(type_e_integer_expr_expected)
                           else
                             hpp^.left:=gentypeconvnode(hpp^.left,s32bitdef);
                           hpp:=hpp^.right;
                           if assigned(hpp) and hpp^.is_colon_para then
                             begin
                               if isreal then
                                begin
                                  if (not is_integer(hpp^.resulttype)) then
                                    CGMessage(type_e_integer_expr_expected)
                                  else
                                    hpp^.left:=gentypeconvnode(hpp^.left,s32bitdef);
                                end
                               else
                                CGMessage(parser_e_illegal_colon_qualifier);
                             end;
                         end;

                       { for first local use }
                       must_be_valid:=false;
                       count_ref:=true;
                    end
                  else
                    CGMessage(parser_e_illegal_parameter_list);
                  { pass all parameters again for the typeconversions }
                  if codegenerror then
                    exit;
                  must_be_valid:=true;
                  firstcallparan(p^.left,nil);
                  { calc registers }
                  left_right_max(p);
               end;
            in_include_x_y,
            in_exclude_x_y:
              begin
                 p^.resulttype:=voiddef;
                 if assigned(p^.left) then
                   begin
                      firstcallparan(p^.left,nil);
                      p^.registers32:=p^.left^.registers32;
                      p^.registersfpu:=p^.left^.registersfpu;
{$ifdef SUPPORT_MMX}
                      p^.registersmmx:=p^.left^.registersmmx;
{$endif SUPPORT_MMX}
                      { first param must be var }
                      if (p^.left^.left^.location.loc<>LOC_REFERENCE) and
                         (p^.left^.left^.location.loc<>LOC_CREGISTER) then
                        CGMessage(cg_e_illegal_expression);
                      { check type }
                      if (p^.left^.resulttype^.deftype=setdef) then
                        begin
                           { two paras ? }
                           if assigned(p^.left^.right) then
                             begin
                                { insert a type conversion         }
                                { to the type of the set elements  }
                                p^.left^.right^.left:=gentypeconvnode(
                                  p^.left^.right^.left,
                                  psetdef(p^.left^.resulttype)^.setof);
                                { check the type conversion }
                                firstpass(p^.left^.right^.left);
                                { only three parameters are allowed }
                                if assigned(p^.left^.right^.right) then
                                  CGMessage(cg_e_illegal_expression);
                             end;
                        end
                      else
                        CGMessage(type_e_mismatch);
                   end
                 else
                   CGMessage(type_e_mismatch);
              end;
             in_low_x,in_high_x:
               begin
                  if p^.left^.treetype in [typen,loadn] then
                    begin
                       case p^.left^.resulttype^.deftype of
                          orddef,enumdef:
                            begin
                               do_lowhigh(p^.left^.resulttype);
                               firstpass(p);
                            end;
                          setdef:
                            begin
                               do_lowhigh(Psetdef(p^.left^.resulttype)^.setof);
                               firstpass(p);
                            end;
                         arraydef:
                            begin
                              if is_open_array(p^.left^.resulttype) then
                                begin
                                   if p^.inlinenumber=in_low_x then
                                     begin
                                        hp:=genordinalconstnode(Parraydef(p^.left^.resulttype)^.lowrange,s32bitdef);
                                        disposetree(p);
                                        p:=hp;
                                        firstpass(p);
                                     end
                                   else
                                     begin
                                        p^.resulttype:=s32bitdef;
                                        p^.registers32:=max(1,
                                          p^.registers32);
                                        p^.location.loc:=LOC_REGISTER;
                                     end;
                                end
                              else
                                begin
                                   if p^.inlinenumber=in_low_x then
                                     hp:=genordinalconstnode(Parraydef(p^.left^.resulttype)^.lowrange,s32bitdef)
                                   else
                                     hp:=genordinalconstnode(Parraydef(p^.left^.resulttype)^.highrange,s32bitdef);
                                   disposetree(p);
                                   p:=hp;
                                   firstpass(p);
                                end;
                           end;
                         stringdef:
                           begin
                              if p^.inlinenumber=in_low_x then
                                hp:=genordinalconstnode(0,u8bitdef)
                              else
                                hp:=genordinalconstnode(Pstringdef(p^.left^.resulttype)^.len,u8bitdef);
                              disposetree(p);
                              p:=hp;
                              firstpass(p);
                           end;
                         else
                           CGMessage(type_e_mismatch);
                         end;
                    end
                  else
                    CGMessage(type_e_varid_or_typeid_expected);
               end;

            in_assert_x_y :
               begin
                 p^.resulttype:=voiddef;
                 if assigned(p^.left) then
                   begin
                      firstcallparan(p^.left,nil);
                      p^.registers32:=p^.left^.registers32;
                      p^.registersfpu:=p^.left^.registersfpu;
{$ifdef SUPPORT_MMX}
                      p^.registersmmx:=p^.left^.registersmmx;
{$endif SUPPORT_MMX}
                      { check type }
                      if is_boolean(p^.left^.resulttype) then
                        begin
                           { must always be a string }
                           p^.left^.right^.left:=gentypeconvnode(p^.left^.right^.left,cstringdef);
                           firstpass(p^.left^.right^.left);
                        end
                      else
                        CGMessage(type_e_mismatch);
                   end
                 else
                   CGMessage(type_e_mismatch);
               end;

              else
                internalerror(8);
              end;
            end;
           must_be_valid:=store_valid;
           count_ref:=store_count_ref;
       end;


end.
{
  $Log$
  Revision 1.4  1998-10-06 20:49:11  peter
    * m68k compiler compiles again

  Revision 1.3  1998/10/05 12:32:49  peter
    + assert() support

  Revision 1.2  1998/10/02 09:24:23  peter
    * more constant expression evaluators

  Revision 1.1  1998/09/23 20:42:24  peter
    * splitted pass_1

}

