{
    $Id$
    Copyright (c) 1998-2002 by Florian Klaempfl

    Compare definitions and parameter lists

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
unit defcmp;

{$i fpcdefs.inc}

interface

    uses
       cclasses,
       cpuinfo,
       globals,
       node,
       symconst,symbase,symtype,symdef;

     type
       { The order is from low priority to high priority,
         Note: the operators > and < are used on this list }
       tequaltype = (
         te_incompatible,
         te_convert_operator,
         te_convert_l2,     { compatible conversion with possible loss of data }
         te_convert_l1,     { compatible conversion     }
         te_equal,          { the definitions are equal }
         te_exact
       );

       { if acp is cp_all the var const or nothing are considered equal }
       compare_type = ( cp_none, cp_value_equal_const, cp_all,cp_procvar);

       tconverttype = (
          tc_equal,
          tc_not_possible,
          tc_string_2_string,
          tc_char_2_string,
          tc_char_2_chararray,
          tc_pchar_2_string,
          tc_cchar_2_pchar,
          tc_cstring_2_pchar,
          tc_ansistring_2_pchar,
          tc_string_2_chararray,
          tc_chararray_2_string,
          tc_array_2_pointer,
          tc_pointer_2_array,
          tc_int_2_int,
          tc_int_2_bool,
          tc_bool_2_bool,
          tc_bool_2_int,
          tc_real_2_real,
          tc_int_2_real,
          tc_proc_2_procvar,
          tc_arrayconstructor_2_set,
          tc_load_smallset,
          tc_cord_2_pointer,
          tc_intf_2_string,
          tc_intf_2_guid,
          tc_class_2_intf,
          tc_char_2_char,
          tc_normal_2_smallset,
          tc_dynarray_2_openarray,
          tc_pwchar_2_string,
          tc_variant_2_dynarray,
          tc_dynarray_2_variant
       );

    function compare_defs_ext(def_from,def_to : tdef;
                              fromtreetype : tnodetype;
                              explicit : boolean;
                              check_operator : boolean;
                              var doconv : tconverttype;
                              var operatorpd : tprocdef):tequaltype;

    { Returns if the type def_from can be converted to def_to or if both types are equal }
    function compare_defs(def_from,def_to:tdef;fromtreetype:tnodetype):tequaltype;

    { Returns true, if def1 and def2 are semantically the same }
    function equal_defs(def_from,def_to:tdef):boolean;

    { Checks for type compatibility (subgroups of type)
      used for case statements... probably missing stuff
      to use on other types }
    function is_subequal(def1, def2: tdef): boolean;

    function assignment_overloaded(from_def,to_def : tdef) : tprocdef;

     {# true, if two parameter lists are equal
      if acp is cp_none, all have to match exactly
      if acp is cp_value_equal_const call by value
      and call by const parameter are assumed as
      equal
      allowdefaults indicates if default value parameters
      are allowed (in this case, the search order will first
      search for a routine with default parameters, before
      searching for the same definition with no parameters)
    }
    function compare_paras(paralist1,paralist2 : TLinkedList; acp : compare_type;allowdefaults:boolean):tequaltype;

    { True if a function can be assigned to a procvar }
    { changed first argument type to pabstractprocdef so that it can also be }
    { used to test compatibility between two pprocvardefs (JM)               }
    function proc_to_procvar_equal(def1:tabstractprocdef;def2:tprocvardef):tequaltype;


implementation

    uses
      globtype,tokens,
      verbose,systems,
      symsym,symtable,
      defutil,symutil;


    function assignment_overloaded(from_def,to_def:tdef):tprocdef;
      begin
        if assigned(overloaded_operators[_ASSIGNMENT]) then
          assignment_overloaded:=overloaded_operators[_ASSIGNMENT].search_procdef_assignment_operator(from_def,to_def)
        else
          assignment_overloaded:=nil;
      end;


    function compare_defs_ext(def_from,def_to : tdef;
                              fromtreetype : tnodetype;
                              explicit : boolean;
                              check_operator : boolean;
                              var doconv : tconverttype;
                              var operatorpd : tprocdef):tequaltype;

      { Tbasetype:
           uvoid,
           u8bit,u16bit,u32bit,u64bit,
           s8bit,s16bit,s32bit,s64bit,
           bool8bit,bool16bit,bool32bit,
           uchar,uwidechar }

      type
        tbasedef=(bvoid,bchar,bint,bbool);
      const
        basedeftbl:array[tbasetype] of tbasedef =
          (bvoid,
           bint,bint,bint,bint,
           bint,bint,bint,bint,
           bbool,bbool,bbool,
           bchar,bchar);

        basedefconvertsimplicit : array[tbasedef,tbasedef] of tconverttype =
          { void, char, int, bool }
         ((tc_not_possible,tc_not_possible,tc_not_possible,tc_not_possible),
          (tc_not_possible,tc_char_2_char,tc_not_possible,tc_not_possible),
          (tc_not_possible,tc_not_possible,tc_int_2_int,tc_not_possible),
          (tc_not_possible,tc_not_possible,tc_bool_2_int,tc_bool_2_bool));
        basedefconvertsexplicit : array[tbasedef,tbasedef] of tconverttype =
          { void, char, int, bool }
         ((tc_not_possible,tc_not_possible,tc_not_possible,tc_not_possible),
          (tc_not_possible,tc_char_2_char,tc_int_2_int,tc_int_2_bool),
          (tc_not_possible,tc_int_2_int,tc_int_2_int,tc_int_2_bool),
          (tc_not_possible,tc_bool_2_int,tc_bool_2_int,tc_bool_2_bool));

      var
         subeq,eq : tequaltype;
         hd1,hd2 : tdef;
         hct : tconverttype;
         hd3 : tobjectdef;
         hpd : tprocdef;
      begin
         { safety check }
         if not(assigned(def_from) and assigned(def_to)) then
          begin
            compare_defs_ext:=te_incompatible;
            exit;
          end;

         { same def? then we've an exact match }
         if def_from=def_to then
          begin
            compare_defs_ext:=te_exact;
            exit;
          end;

         { we walk the wanted (def_to) types and check then the def_from
           types if there is a conversion possible }
         eq:=te_incompatible;
         doconv:=tc_not_possible;
         case def_to.deftype of
           orddef :
             begin
               case def_from.deftype of
                 orddef :
                   begin
                     if (torddef(def_from).typ=torddef(def_to).typ) then
                      begin
                        case torddef(def_from).typ of
                          u8bit,u16bit,u32bit,u64bit,
                          s8bit,s16bit,s32bit,s64bit:
                            begin
                              if (torddef(def_from).low=torddef(def_to).low) and
                                 (torddef(def_from).high=torddef(def_to).high) then
                                eq:=te_equal
                              else
                                eq:=te_convert_l1;
                            end;
                          uvoid,uchar,uwidechar,
                          bool8bit,bool16bit,bool32bit:
                            eq:=te_equal;
                          else
                            internalerror(200210061);
                        end;
                      end
                     else
                      begin
                        if explicit then
                         doconv:=basedefconvertsexplicit[basedeftbl[torddef(def_from).typ],basedeftbl[torddef(def_to).typ]]
                        else
                         doconv:=basedefconvertsimplicit[basedeftbl[torddef(def_from).typ],basedeftbl[torddef(def_to).typ]];
                        if (doconv=tc_not_possible) then
                          eq:=te_incompatible
                        else
                          { "punish" bad type conversions :) (JM) }
                          if (not is_in_limit(def_from,def_to)) and
                             (def_from.size > def_to.size) then
                            eq:=te_convert_l2
                        else
                          eq:=te_convert_l1;
                      end;
                   end;
                 enumdef :
                   begin
                     { needed for char(enum) }
                     if explicit then
                      begin
                        doconv:=tc_int_2_int;
                        eq:=te_convert_l1;
                      end;
                   end;
                 pointerdef :
                   begin
                     if explicit and
                        (fromtreetype=niln) then
                      begin
                        { will be handled by the constant folding }
                        doconv:=tc_equal;
                        eq:=te_convert_l1;
                      end;
                   end;
               end;
             end;

          stringdef :
             begin
               case def_from.deftype of
                 stringdef :
                   begin
                     { Constant string }
                     if (fromtreetype=stringconstn) then
                      begin
                        if (tstringdef(def_from).string_typ=tstringdef(def_to).string_typ) then
                          eq:=te_equal
                        else
                         begin
                           doconv:=tc_string_2_string;
                           { Don't prefer conversions from widestring to a
                             normal string as we can loose information }
                           if is_widestring(def_from) then
                            eq:=te_convert_l1
                           else
                            eq:=te_convert_l2;
                         end;
                      end
                     else
                     { Same string type, for shortstrings also the length must match }
                      if (tstringdef(def_from).string_typ=tstringdef(def_to).string_typ) and
                         ((tstringdef(def_from).string_typ<>st_shortstring) or
                          (tstringdef(def_from).len=tstringdef(def_to).len)) then
                        eq:=te_equal
                     else
                       begin
                         doconv:=tc_string_2_string;
                         { Prefer conversions to shortstring over other
                           conversions. This is compatible with Delphi (PFV) }
                         if tstringdef(def_to).string_typ=st_shortstring then
                           eq:=te_convert_l1
                         else
                           eq:=te_convert_l2;
                       end;
                   end;
                 orddef :
                   begin
                   { char to string}
                     if is_char(def_from) or
                        is_widechar(def_from) then
                      begin
                        doconv:=tc_char_2_string;
                        eq:=te_convert_l1;
                      end;
                   end;
                 arraydef :
                   begin
                   { array of char to string, the length check is done by the firstpass of this node }
                     if is_chararray(def_from) or
                        (is_char(tarraydef(def_from).elementtype.def) and
                         is_open_array(def_from)) then
                      begin
                        doconv:=tc_chararray_2_string;
                        if is_open_array(def_from) or
                           (is_shortstring(def_to) and
                            (def_from.size <= 255)) or
                           (is_ansistring(def_to) and
                            (def_from.size > 255)) then
                         eq:=te_convert_l1
                        else
                         eq:=te_convert_l2;
                      end;
                   end;
                 pointerdef :
                   begin
                   { pchar can be assigned to short/ansistrings,
                     but not in tp7 compatible mode }
                     if not(m_tp7 in aktmodeswitches) then
                       begin
                          if is_pchar(def_from) then
                           begin
                             doconv:=tc_pchar_2_string;
                             { trefer ansistrings because pchars can overflow shortstrings, }
                             { but only if ansistrings are the default (JM)                 }
                             if (is_shortstring(def_to) and
                                 not(cs_ansistrings in aktlocalswitches)) or
                                (is_ansistring(def_to) and
                                 (cs_ansistrings in aktlocalswitches)) then
                               eq:=te_convert_l1
                             else
                               eq:=te_convert_l2;
                           end
                          else if is_pwidechar(def_from) then
                           begin
                             doconv:=tc_pwchar_2_string;
                             { trefer ansistrings because pchars can overflow shortstrings, }
                             { but only if ansistrings are the default (JM)                 }
                             if is_widestring(def_to) then
                               eq:=te_convert_l1
                             else
                               eq:=te_convert_l2;
                           end;
                       end;
                   end;
               end;
             end;

           floatdef :
             begin
               case def_from.deftype of
                 orddef :
                   begin { ordinal to real }
                     if is_integer(def_from) then
                       begin
                         doconv:=tc_int_2_real;
                         eq:=te_convert_l1;
                       end;
                   end;
                 floatdef :
                   begin
                     if tfloatdef(def_from).typ=tfloatdef(def_to).typ then
                       eq:=te_equal
                     else
                       begin
                         doconv:=tc_real_2_real;
                         eq:=te_convert_l1;
                       end;
                   end;
               end;
             end;

           enumdef :
             begin
               case def_from.deftype of
                 enumdef :
                   begin
                     if explicit then
                      begin
                        eq:=te_convert_l1;
                        doconv:=tc_int_2_int;
                      end
                     else
                      begin
                        hd1:=def_from;
                        while assigned(tenumdef(hd1).basedef) do
                         hd1:=tenumdef(hd1).basedef;
                        hd2:=def_to;
                        while assigned(tenumdef(hd2).basedef) do
                         hd2:=tenumdef(hd2).basedef;
                        if (hd1=hd2) then
                         begin
                           eq:=te_convert_l1;
                           { because of packenum they can have different sizes! (JM) }
                           doconv:=tc_int_2_int;
                         end;
                      end;
                   end;
                 orddef :
                   begin
                     if explicit then
                      begin
                        eq:=te_convert_l1;
                        doconv:=tc_int_2_int;
                      end;
                   end;
               end;
             end;

           arraydef :
             begin
             { open array is also compatible with a single element of its base type }
               if is_open_array(def_to) and
                  equal_defs(def_from,tarraydef(def_to).elementtype.def) then
                begin
                  doconv:=tc_equal;
                  eq:=te_convert_l1;
                end
               else
                begin
                  case def_from.deftype of
                    arraydef :
                      begin
                        { to dynamic array }
                        if is_dynamic_array(def_to) then
                         begin
                           { dynamic array -> dynamic array }
                           if is_dynamic_array(def_from) and
                              equal_defs(tarraydef(def_from).elementtype.def,tarraydef(def_to).elementtype.def) then
                            eq:=te_equal;
                         end
                        else
                         { to open array }
                         if is_open_array(def_to) then
                          begin
                            { array constructor -> open array }
                            if is_array_constructor(def_from) then
                             begin
                               if is_void(tarraydef(def_from).elementtype.def) then
                                begin
                                  doconv:=tc_equal;
                                  eq:=te_convert_l1;
                                end
                               else
                                begin
                                  subeq:=compare_defs_ext(tarraydef(def_from).elementtype.def,
                                                       tarraydef(def_to).elementtype.def,
                                                       arrayconstructorn,false,true,hct,hpd);
                                  if (subeq>=te_equal) then
                                    begin
                                      doconv:=tc_equal;
                                      eq:=te_convert_l1;
                                    end
                                  else
                                   if (subeq>te_incompatible) then
                                    begin
                                      doconv:=hct;
                                      eq:=te_convert_l2;
                                    end;
                                end;
                             end
                            else
                             { dynamic array -> open array }
                             if is_dynamic_array(def_from) and
                                equal_defs(tarraydef(def_from).elementtype.def,tarraydef(def_to).elementtype.def) then
                               begin
                                 doconv:=tc_dynarray_2_openarray;
                                 eq:=te_convert_l2;
                               end
                            else
                             { array -> open array }
                             if equal_defs(tarraydef(def_from).elementtype.def,tarraydef(def_to).elementtype.def) then
                               eq:=te_equal;
                          end
                        else
                         { to array of const }
                         if is_array_of_const(def_to) then
                          begin
                            if is_array_of_const(def_from) or
                               is_array_constructor(def_from) then
                             begin
                               eq:=te_equal;
                             end
                            else
                             { array of tvarrec -> array of const }
                             if equal_defs(tarraydef(def_to).elementtype.def,tarraydef(def_from).elementtype.def) then
                              begin
                                doconv:=tc_equal;
                                eq:=te_convert_l1;
                              end;
                          end
                        else
                         { other arrays }
                          begin
                            { open array -> array }
                            if is_open_array(def_from) and
                               equal_defs(tarraydef(def_from).elementtype.def,tarraydef(def_to).elementtype.def) then
                              begin
                                eq:=te_equal
                              end
                            else
                            { array -> array }
                             if not(m_tp7 in aktmodeswitches) and
                                not(m_delphi in aktmodeswitches) and
                                (tarraydef(def_from).lowrange=tarraydef(def_to).lowrange) and
                                (tarraydef(def_from).highrange=tarraydef(def_to).highrange) and
                                equal_defs(tarraydef(def_from).elementtype.def,tarraydef(def_to).elementtype.def) and
                                equal_defs(tarraydef(def_from).rangetype.def,tarraydef(def_to).rangetype.def) then
                              begin
                                eq:=te_equal
                              end;
                          end;
                      end;
                    pointerdef :
                      begin
                        { nil is compatible with dyn. arrays }
                        if is_dynamic_array(def_to) and
                           (fromtreetype=niln) then
                         begin
                           doconv:=tc_equal;
                           eq:=te_convert_l1;
                         end
                        else
                         if is_zero_based_array(def_to) and
                            equal_defs(tpointerdef(def_from).pointertype.def,tarraydef(def_to).elementtype.def) then
                          begin
                            doconv:=tc_pointer_2_array;
                            eq:=te_convert_l1;
                          end;
                      end;
                    stringdef :
                      begin
                        { string to char array }
                        if (not is_special_array(def_to)) and
                           is_char(tarraydef(def_to).elementtype.def) then
                         begin
                           doconv:=tc_string_2_chararray;
                           eq:=te_convert_l1;
                         end;
                      end;
                    orddef:
                      begin
                        if is_chararray(def_to) and
                           is_char(def_from) then
                          begin
                            doconv:=tc_char_2_chararray;
                            eq:=te_convert_l2;
                          end;
                      end;
                    recorddef :
                      begin
                        { tvarrec -> array of const }
                         if is_array_of_const(def_to) and
                            equal_defs(def_from,tarraydef(def_to).elementtype.def) then
                          begin
                            doconv:=tc_equal;
                            eq:=te_convert_l1;
                          end;
                      end;
                    variantdef :
                      begin
                         if is_dynamic_array(def_to) then
                           begin
                              doconv:=tc_variant_2_dynarray;
                              eq:=te_convert_l1;
                           end;
                      end;
                  end;
                end;
             end;

           pointerdef :
             begin
               case def_from.deftype of
                 stringdef :
                   begin
                     { string constant (which can be part of array constructor)
                       to zero terminated string constant }
                     if (fromtreetype in [arrayconstructorn,stringconstn]) and
                        (is_pchar(def_to) or is_pwidechar(def_to)) then
                      begin
                        doconv:=tc_cstring_2_pchar;
                        eq:=te_convert_l1;
                      end
                     else
                      if explicit then
                       begin
                         { pchar(ansistring) }
                         if is_pchar(def_to) and
                            is_ansistring(def_from) then
                          begin
                            doconv:=tc_ansistring_2_pchar;
                            eq:=te_convert_l1;
                          end
                         else
                          { pwidechar(ansistring) }
                          if is_pwidechar(def_to) and
                             is_widestring(def_from) then
                           begin
                             doconv:=tc_ansistring_2_pchar;
                             eq:=te_convert_l1;
                           end;
                       end;
                   end;
                 orddef :
                   begin
                     { char constant to zero terminated string constant }
                     if (fromtreetype=ordconstn) then
                      begin
                        if is_char(def_from) and
                           is_pchar(def_to) then
                         begin
                           doconv:=tc_cchar_2_pchar;
                           eq:=te_convert_l1;
                         end
                        else
                         if is_integer(def_from) then
                          begin
                            doconv:=tc_cord_2_pointer;
                            eq:=te_convert_l1;
                          end;
                      end;
                     if (eq=te_incompatible) and
                        explicit and
                        (m_delphi in aktmodeswitches) then
                      begin
                        doconv:=tc_int_2_int;
                        eq:=te_convert_l1;
                      end;
                   end;
                 arraydef :
                   begin
                     { chararray to pointer }
                     if is_zero_based_array(def_from) and
                        equal_defs(tarraydef(def_from).elementtype.def,tpointerdef(def_to).pointertype.def) then
                      begin
                        doconv:=tc_array_2_pointer;
                        eq:=te_convert_l1;
                      end;
                   end;
                 pointerdef :
                   begin
                     { check for far pointers }
                     if (tpointerdef(def_from).is_far<>tpointerdef(def_to).is_far) then
                       begin
                         eq:=te_incompatible;
                       end
                     else
                      { the types can be forward type, handle before normal type check !! }
                      if assigned(def_to.typesym) and
                         (tpointerdef(def_to).pointertype.def.deftype=forwarddef) then
                       begin
                         if (def_from.typesym=def_to.typesym) then
                          eq:=te_equal
                       end
                     else
                      { same types }
                      if (tpointerdef(def_from).pointertype.def=tpointerdef(def_to).pointertype.def) then
                       begin
                         eq:=te_equal
                       end
                     else
                      { child class pointer can be assigned to anchestor pointers }
                      if (
                          (tpointerdef(def_from).pointertype.def.deftype=objectdef) and
                          (tpointerdef(def_to).pointertype.def.deftype=objectdef) and
                          tobjectdef(tpointerdef(def_from).pointertype.def).is_related(
                            tobjectdef(tpointerdef(def_to).pointertype.def))
                         ) or
                         { all pointers can be assigned to/from void-pointer }
                         is_void(tpointerdef(def_to).pointertype.def) or
                         is_void(tpointerdef(def_from).pointertype.def) then
                       begin
                         doconv:=tc_equal;
                         { give pwidechar a small penalty }
                         if is_pwidechar(def_to) then
                          eq:=te_convert_l2
                         else
                          eq:=te_convert_l1;
                       end;
                   end;
                 procvardef :
                   begin
                     { procedure variable can be assigned to an void pointer }
                     { Not anymore. Use the @ operator now.}
                     if not(m_tp_procvar in aktmodeswitches) and
                        (tpointerdef(def_to).pointertype.def.deftype=orddef) and
                        (torddef(tpointerdef(def_to).pointertype.def).typ=uvoid) then
                      begin
                        doconv:=tc_equal;
                        eq:=te_convert_l1;
                      end;
                   end;
                 classrefdef,
                 objectdef :
                   begin
                     { class types and class reference type
                       can be assigned to void pointers      }
                     if (
                         is_class_or_interface(def_from) or
                         (def_from.deftype=classrefdef)
                        ) and
                        (tpointerdef(def_to).pointertype.def.deftype=orddef) and
                        (torddef(tpointerdef(def_to).pointertype.def).typ=uvoid) then
                       begin
                         doconv:=tc_equal;
                         eq:=te_convert_l1;
                       end;
                   end;
               end;
             end;

           setdef :
             begin
               case def_from.deftype of
                 setdef :
                   begin
                     if assigned(tsetdef(def_from).elementtype.def) and
                        assigned(tsetdef(def_to).elementtype.def) then
                      begin
                        { sets with the same element base type are equal }
                        if is_subequal(tsetdef(def_from).elementtype.def,tsetdef(def_to).elementtype.def) then
                         eq:=te_equal;
                      end
                     else
                      { empty set is compatible with everything }
                      eq:=te_equal;
                   end;
                 arraydef :
                   begin
                     { automatic arrayconstructor -> set conversion }
                     if is_array_constructor(def_from) then
                      begin
                        doconv:=tc_arrayconstructor_2_set;
                        eq:=te_convert_l1;
                      end;
                   end;
               end;
             end;

           procvardef :
             begin
               case def_from.deftype of
                 procdef :
                   begin
                     { proc -> procvar }
                     if (m_tp_procvar in aktmodeswitches) then
                      begin
                        subeq:=proc_to_procvar_equal(tprocdef(def_from),tprocvardef(def_to));
                        if subeq>te_incompatible then
                         begin
                           doconv:=tc_proc_2_procvar;
                           eq:=te_convert_l1;
                         end;
                      end;
                   end;
                 procvardef :
                   begin
                     { procvar -> procvar }
                     eq:=proc_to_procvar_equal(tprocvardef(def_from),tprocvardef(def_to));
                   end;
                 pointerdef :
                   begin
                     { nil is compatible with procvars }
                     if (fromtreetype=niln) then
                      begin
                        doconv:=tc_equal;
                        eq:=te_convert_l1;
                      end
                     else
                      { for example delphi allows the assignement from pointers }
                      { to procedure variables                                  }
                      if (m_pointer_2_procedure in aktmodeswitches) and
                         (tpointerdef(def_from).pointertype.def.deftype=orddef) and
                         (torddef(tpointerdef(def_from).pointertype.def).typ=uvoid) then
                       begin
                         doconv:=tc_equal;
                         eq:=te_convert_l1;
                       end;
                   end;
               end;
             end;

           objectdef :
             begin
               { object pascal objects }
               if (def_from.deftype=objectdef) and
                 tobjectdef(def_from).is_related(tobjectdef(def_to)) then
                begin
                  doconv:=tc_equal;
                  eq:=te_convert_l1;
                end
               else
               { Class/interface specific }
                if is_class_or_interface(def_to) then
                 begin
                   { void pointer also for delphi mode }
                   if (m_delphi in aktmodeswitches) and
                      is_voidpointer(def_from) then
                    begin
                      doconv:=tc_equal;
                      eq:=te_convert_l1;
                    end
                   else
                   { nil is compatible with class instances and interfaces }
                    if (fromtreetype=niln) then
                     begin
                       doconv:=tc_equal;
                       eq:=te_convert_l1;
                     end
                   { classes can be assigned to interfaces }
                   else if is_interface(def_to) and
                     is_class(def_from) and
                     assigned(tobjectdef(def_from).implementedinterfaces) then
                     begin
                        { we've to search in parent classes as well }
                        hd3:=tobjectdef(def_from);
                        while assigned(hd3) do
                          begin
                             if hd3.implementedinterfaces.searchintf(def_to)<>-1 then
                               begin
                                  doconv:=tc_class_2_intf;
                                  eq:=te_convert_l1;
                                  break;
                               end;
                             hd3:=hd3.childof;
                          end;
                     end
                   { Interface 2 GUID handling }
                   else if (def_to=tdef(rec_tguid)) and
                           (fromtreetype=typen) and
                           is_interface(def_from) and
                           assigned(tobjectdef(def_from).iidguid) then
                     begin
                       eq:=te_convert_l1;
                       doconv:=tc_equal;
                     end;
                 end;
             end;

           classrefdef :
             begin
               { similar to pointerdef wrt forwards }
               if assigned(def_to.typesym) and
                  (tclassrefdef(def_to).pointertype.def.deftype=forwarddef) then
                 begin
                   if (def_from.typesym=def_to.typesym) then
                    eq:=te_equal;
                 end
               else
                { class reference types }
                if (def_from.deftype=classrefdef) then
                 begin
                   if equal_defs(tclassrefdef(def_from).pointertype.def,tclassrefdef(def_to).pointertype.def) then
                    begin
                      eq:=te_equal;
                    end
                   else
                    begin
                      doconv:=tc_equal;
                      if tobjectdef(tclassrefdef(def_from).pointertype.def).is_related(
                           tobjectdef(tclassrefdef(def_to).pointertype.def)) then
                        eq:=te_convert_l1;
                    end;
                 end
               else
                { nil is compatible with class references }
                if (fromtreetype=niln) then
                 begin
                   doconv:=tc_equal;
                   eq:=te_convert_l1;
                 end;
             end;

           filedef :
             begin
               { typed files are all equal to the abstract file type
               name TYPEDFILE in system.pp in is_equal in types.pas
               the problem is that it sholud be also compatible to FILE
               but this would leed to a problem for ASSIGN RESET and REWRITE
               when trying to find the good overloaded function !!
               so all file function are doubled in system.pp
               this is not very beautiful !!}
               if (def_from.deftype=filedef) then
                begin
                  if (tfiledef(def_from).filetyp=tfiledef(def_to).filetyp) then
                   begin
                     if
                        (
                         (tfiledef(def_from).typedfiletype.def=nil) and
                         (tfiledef(def_to).typedfiletype.def=nil)
                        ) or
                        (
                         (tfiledef(def_from).typedfiletype.def<>nil) and
                         (tfiledef(def_to).typedfiletype.def<>nil) and
                         equal_defs(tfiledef(def_from).typedfiletype.def,tfiledef(def_to).typedfiletype.def)
                        ) or
                        (
                         (tfiledef(def_from).filetyp = ft_typed) and
                         (tfiledef(def_to).filetyp = ft_typed) and
                         (
                          (tfiledef(def_from).typedfiletype.def = tdef(voidtype.def)) or
                          (tfiledef(def_to).typedfiletype.def = tdef(voidtype.def))
                         )
                        ) then
                      begin
                        eq:=te_equal;
                      end;
                   end
                  else
                   if ((tfiledef(def_from).filetyp = ft_untyped) and
                       (tfiledef(def_to).filetyp = ft_typed)) or
                      ((tfiledef(def_from).filetyp = ft_typed) and
                       (tfiledef(def_to).filetyp = ft_untyped)) then
                    begin
                      doconv:=tc_equal;
                      eq:=te_convert_l1;
                    end;
                end;
             end;

           recorddef :
             begin
               { interface -> guid }
               if is_interface(def_from) and
                  (def_to=rec_tguid) then
                begin
                  doconv:=tc_intf_2_guid;
                  eq:=te_convert_l1;
                end
               else
                begin
                  { assignment overwritten ?? }
                  if check_operator then
                   begin
                     operatorpd:=assignment_overloaded(def_from,def_to);
                     if assigned(operatorpd) then
                      eq:=te_convert_operator;
                   end;
                end;
             end;

           formaldef :
             begin
               if (def_from.deftype=formaldef) then
                 eq:=te_equal
               else
                { Just about everything can be converted to a formaldef...}
                if not (def_from.deftype in [abstractdef,errordef]) then
                  eq:=te_convert_l1
               else
                 begin
                   { assignment overwritten ?? }
                   if check_operator then
                    begin
                      operatorpd:=assignment_overloaded(def_from,def_to);
                      if assigned(operatorpd) then
                       eq:=te_convert_operator;
                    end;
                 end;
             end;
        end;

        { if we didn't find an appropriate type conversion yet and
          there is a variant involved then we search also the := operator }
        if (eq=te_incompatible) and
           check_operator and
           ((def_from.deftype=variantdef) or
            (def_to.deftype=variantdef)) then
          begin
            operatorpd:=assignment_overloaded(def_from,def_to);
            if assigned(operatorpd) then
             eq:=te_convert_operator;
          end;
        compare_defs_ext:=eq;
      end;


    function equal_defs(def_from,def_to:tdef):boolean;
      var
        convtyp : tconverttype;
        pd : tprocdef;
      begin
        { Compare defs with nothingn and no explicit typecasts and
          searching for overloaded operators is not needed }
        equal_defs:=(compare_defs_ext(def_from,def_to,nothingn,false,false,convtyp,pd)>=te_equal);
      end;


    function compare_defs(def_from,def_to:tdef;fromtreetype:tnodetype):tequaltype;
      var
        doconv : tconverttype;
        pd : tprocdef;
      begin
        compare_defs:=compare_defs_ext(def_from,def_to,fromtreetype,false,true,doconv,pd);
      end;


    function is_subequal(def1, def2: tdef): boolean;
      var
         basedef1,basedef2 : tenumdef;

      Begin
        is_subequal := false;
        if assigned(def1) and assigned(def2) then
         Begin
           if (def1.deftype = orddef) and (def2.deftype = orddef) then
            Begin
              { see p.47 of Turbo Pascal 7.01 manual for the separation of types }
              { range checking for case statements is done with testrange        }
              case torddef(def1).typ of
                u8bit,u16bit,u32bit,u64bit,
                s8bit,s16bit,s32bit,s64bit :
                  is_subequal:=(torddef(def2).typ in [s64bit,u64bit,s32bit,u32bit,u8bit,s8bit,s16bit,u16bit]);
                bool8bit,bool16bit,bool32bit :
                  is_subequal:=(torddef(def2).typ in [bool8bit,bool16bit,bool32bit]);
                uchar :
                  is_subequal:=(torddef(def2).typ=uchar);
                uwidechar :
                  is_subequal:=(torddef(def2).typ=uwidechar);
              end;
            end
           else
            Begin
              { Check if both basedefs are equal }
              if (def1.deftype=enumdef) and (def2.deftype=enumdef) then
                Begin
                   { get both basedefs }
                   basedef1:=tenumdef(def1);
                   while assigned(basedef1.basedef) do
                     basedef1:=basedef1.basedef;
                   basedef2:=tenumdef(def2);
                   while assigned(basedef2.basedef) do
                     basedef2:=basedef2.basedef;
                   is_subequal:=(basedef1=basedef2);
                end;
            end;
         end;
      end;


    function compare_paras(paralist1,paralist2 : TLinkedList; acp : compare_type;allowdefaults:boolean):tequaltype;
      var
        def1,def2 : TParaItem;
        eq,lowesteq : tequaltype;
        hpd : tprocdef;
        convtype : tconverttype;
      begin
         compare_paras:=te_incompatible;
         { we need to parse the list from left-right so the
           not-default parameters are checked first }
         lowesteq:=high(tequaltype);
         def1:=TParaItem(paralist1.last);
         def2:=TParaItem(paralist2.last);
         while (assigned(def1)) and (assigned(def2)) do
           begin
             eq:=te_incompatible;
             case acp of
               cp_value_equal_const :
                 begin
                    if (
                        (def1.paratyp<>def2.paratyp) and
                        ((def1.paratyp in [vs_var,vs_out]) or
                         (def2.paratyp in [vs_var,vs_out]))
                       ) then
                      exit;
                    eq:=compare_defs(def1.paratype.def,def2.paratype.def,nothingn);
                 end;
               cp_all :
                 begin
                    if (def1.paratyp<>def2.paratyp) then
                      exit;
                    eq:=compare_defs(def1.paratype.def,def2.paratype.def,nothingn);
                 end;
               cp_procvar :
                 begin
                    if (def1.paratyp<>def2.paratyp) then
                      exit;
                    eq:=compare_defs_ext(def1.paratype.def,def2.paratype.def,nothingn,
                                         false,true,convtype,hpd);
                    if (eq>te_incompatible) and
                       (eq<te_equal) and
                       not(convtype in [tc_equal,tc_int_2_int]) then
                     begin
                       eq:=te_incompatible;
                     end;
                 end;
               else
                 eq:=compare_defs(def1.paratype.def,def2.paratype.def,nothingn);
              end;
              { check type }
              if eq=te_incompatible then
                exit;
              if eq<lowesteq then
                lowesteq:=eq;
              { also check default value if both have it declared }
              if assigned(def1.defaultvalue) and
                 assigned(def2.defaultvalue) then
               begin
                 if not equal_constsym(tconstsym(def1.defaultvalue),tconstsym(def2.defaultvalue)) then
                   exit;
               end;
              def1:=TParaItem(def1.previous);
              def2:=TParaItem(def2.previous);
           end;
         { when both lists are empty then the parameters are equal. Also
           when one list is empty and the other has a parameter with default
           value assigned then the parameters are also equal }
         if ((def1=nil) and (def2=nil)) or
            (allowdefaults and
             ((assigned(def1) and assigned(def1.defaultvalue)) or
              (assigned(def2) and assigned(def2.defaultvalue)))) then
           compare_paras:=lowesteq;
      end;


    function proc_to_procvar_equal(def1:tabstractprocdef;def2:tprocvardef):tequaltype;
      const
        po_comp = po_compatibility_options-[po_methodpointer,po_classmethod];
      var
        ismethod : boolean;
        eq : tequaltype;
      begin
         proc_to_procvar_equal:=te_incompatible;
         if not(assigned(def1)) or not(assigned(def2)) then
           exit;
         { check for method pointer }
         if def1.deftype=procvardef then
          begin
            ismethod:=(po_methodpointer in def1.procoptions);
          end
         else
          begin
            ismethod:=assigned(def1.owner) and
                      (def1.owner.symtabletype=objectsymtable);
          end;
         if (ismethod and not (po_methodpointer in def2.procoptions)) or
            (not(ismethod) and (po_methodpointer in def2.procoptions)) then
          begin
            Message(type_e_no_method_and_procedure_not_compatible);
            exit;
          end;
         { check return value and options, methodpointer is already checked }
         if ((po_comp * def1.procoptions)= (po_comp * def2.procoptions)) and
            equal_defs(def1.rettype.def,def2.rettype.def) and
            (def1.para_size(target_info.alignment.paraalign)=def2.para_size(target_info.alignment.paraalign)) then
          begin
            { return equal type based on the parameters, but a proc->procvar
              is never exact, so map an exact match of the parameters to
              te_equal }
            eq:=compare_paras(def1.para,def2.para,cp_procvar,false);
            if eq=te_exact then
             eq:=te_equal;
            proc_to_procvar_equal:=eq;
          end;
      end;


    function is_equal(def1,def2 : tdef) : boolean;
      var
        doconv : tconverttype;
        hpd : tprocdef;
      begin
        is_equal:=(compare_defs_ext(def1,def2,nothingn,false,true,doconv,hpd)>=te_equal);
      end;


    function equal_paras(paralist1,paralist2 : TLinkedList; acp : compare_type;allowdefaults:boolean) : boolean;
      begin
        equal_paras:=(compare_paras(paralist1,paralist2,acp,allowdefaults)>=te_equal);
      end;

end.
{
  $Log$
  Revision 1.8  2002-12-15 22:37:53  peter
    * give conversions from pointer to pwidechar a penalty (=prefer pchar)

  Revision 1.7  2002/12/11 22:40:12  peter
    * proc->procvar is never an exact match, convert exact parameters
      to equal for the whole proc to procvar conversion level

  Revision 1.6  2002/12/06 17:49:44  peter
    * prefer string-shortstring over other string-string conversions

  Revision 1.5  2002/12/05 14:27:26  florian
    * some variant <-> dyn. array stuff

  Revision 1.4  2002/12/01 22:07:41  carl
    * warning of portabilitiy problems with parasize / localsize
    + some added documentation

  Revision 1.3  2002/11/27 15:33:46  peter
    * the never ending story of tp procvar hacks

  Revision 1.2  2002/11/27 02:32:14  peter
    * fix cp_procvar compare

  Revision 1.1  2002/11/25 17:43:16  peter
    * splitted defbase in defutil,symutil,defcmp
    * merged isconvertable and is_equal into compare_defs(_ext)
    * made operator search faster by walking the list only once

}
