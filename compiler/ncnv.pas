{
    $Id$
    Copyright (c) 2000-2002 by Florian Klaempfl

    Type checking and register allocation for type converting nodes

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
unit ncnv;

{$i fpcdefs.inc}

interface

    uses
       node,
       symtype,
       defutil,defcmp,
       nld
       ;

    type
       ttypeconvnode = class(tunarynode)
          totype   : ttype;
          convtype : tconverttype;
          constructor create(node : tnode;const t : ttype);virtual;
          constructor create_explicit(node : tnode;const t : ttype);
          constructor create_internal(node : tnode;const t : ttype);
          constructor create_proc_to_procvar(node : tnode);
          constructor ppuload(t:tnodetype;ppufile:tcompilerppufile);override;
          procedure ppuwrite(ppufile:tcompilerppufile);override;
          procedure buildderefimpl;override;
          procedure derefimpl;override;
          function getcopy : tnode;override;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          procedure mark_write;override;
          function docompare(p: tnode) : boolean; override;
          function assign_allowed:boolean;
          procedure second_call_helper(c : tconverttype);
       private
          function resulttype_int_to_int : tnode;
          function resulttype_cord_to_pointer : tnode;
          function resulttype_chararray_to_string : tnode;
          function resulttype_string_to_chararray : tnode;
          function resulttype_string_to_string : tnode;
          function resulttype_char_to_string : tnode;
          function resulttype_char_to_chararray : tnode;
          function resulttype_int_to_real : tnode;
          function resulttype_real_to_real : tnode;
          function resulttype_real_to_currency : tnode;
          function resulttype_cchar_to_pchar : tnode;
          function resulttype_cstring_to_pchar : tnode;
          function resulttype_char_to_char : tnode;
          function resulttype_arrayconstructor_to_set : tnode;
          function resulttype_pchar_to_string : tnode;
          function resulttype_interface_to_guid : tnode;
          function resulttype_dynarray_to_openarray : tnode;
          function resulttype_pwchar_to_string : tnode;
          function resulttype_variant_to_dynarray : tnode;
          function resulttype_dynarray_to_variant : tnode;
          function resulttype_call_helper(c : tconverttype) : tnode;
          function resulttype_variant_to_enum : tnode;
          function resulttype_enum_to_variant : tnode;
          function resulttype_proc_to_procvar : tnode;
       protected
          function first_int_to_int : tnode;virtual;
          function first_cstring_to_pchar : tnode;virtual;
          function first_string_to_chararray : tnode;virtual;
          function first_char_to_string : tnode;virtual;
          function first_nothing : tnode;virtual;
          function first_array_to_pointer : tnode;virtual;
          function first_int_to_real : tnode;virtual;
          function first_real_to_real : tnode;virtual;
          function first_pointer_to_array : tnode;virtual;
          function first_cchar_to_pchar : tnode;virtual;
          function first_bool_to_int : tnode;virtual;
          function first_int_to_bool : tnode;virtual;
          function first_bool_to_bool : tnode;virtual;
          function first_proc_to_procvar : tnode;virtual;
          function first_load_smallset : tnode;virtual;
          function first_cord_to_pointer : tnode;virtual;
          function first_ansistring_to_pchar : tnode;virtual;
          function first_arrayconstructor_to_set : tnode;virtual;
          function first_class_to_intf : tnode;virtual;
          function first_char_to_char : tnode;virtual;
          function first_call_helper(c : tconverttype) : tnode;

          { these wrapper are necessary, because the first_* stuff is called }
          { through a table. Without the wrappers override wouldn't have     }
          { any effect                                                       }
          function _first_int_to_int : tnode;
          function _first_cstring_to_pchar : tnode;
          function _first_string_to_chararray : tnode;
          function _first_char_to_string : tnode;
          function _first_nothing : tnode;
          function _first_array_to_pointer : tnode;
          function _first_int_to_real : tnode;
          function _first_real_to_real: tnode;
          function _first_pointer_to_array : tnode;
          function _first_cchar_to_pchar : tnode;
          function _first_bool_to_int : tnode;
          function _first_int_to_bool : tnode;
          function _first_bool_to_bool : tnode;
          function _first_proc_to_procvar : tnode;
          function _first_load_smallset : tnode;
          function _first_cord_to_pointer : tnode;
          function _first_ansistring_to_pchar : tnode;
          function _first_arrayconstructor_to_set : tnode;
          function _first_class_to_intf : tnode;
          function _first_char_to_char : tnode;

          procedure _second_int_to_int;virtual;
          procedure _second_string_to_string;virtual;
          procedure _second_cstring_to_pchar;virtual;
          procedure _second_string_to_chararray;virtual;
          procedure _second_array_to_pointer;virtual;
          procedure _second_pointer_to_array;virtual;
          procedure _second_chararray_to_string;virtual;
          procedure _second_char_to_string;virtual;
          procedure _second_int_to_real;virtual;
          procedure _second_real_to_real;virtual;
          procedure _second_cord_to_pointer;virtual;
          procedure _second_proc_to_procvar;virtual;
          procedure _second_bool_to_int;virtual;
          procedure _second_int_to_bool;virtual;
          procedure _second_bool_to_bool;virtual;
          procedure _second_load_smallset;virtual;
          procedure _second_ansistring_to_pchar;virtual;
          procedure _second_class_to_intf;virtual;
          procedure _second_char_to_char;virtual;
          procedure _second_nothing; virtual;

          procedure second_int_to_int;virtual;abstract;
          procedure second_string_to_string;virtual;abstract;
          procedure second_cstring_to_pchar;virtual;abstract;
          procedure second_string_to_chararray;virtual;abstract;
          procedure second_array_to_pointer;virtual;abstract;
          procedure second_pointer_to_array;virtual;abstract;
          procedure second_chararray_to_string;virtual;abstract;
          procedure second_char_to_string;virtual;abstract;
          procedure second_int_to_real;virtual;abstract;
          procedure second_real_to_real;virtual;abstract;
          procedure second_cord_to_pointer;virtual;abstract;
          procedure second_proc_to_procvar;virtual;abstract;
          procedure second_bool_to_int;virtual;abstract;
          procedure second_int_to_bool;virtual;abstract;
          procedure second_bool_to_bool;virtual;abstract;
          procedure second_load_smallset;virtual;abstract;
          procedure second_ansistring_to_pchar;virtual;abstract;
          procedure second_class_to_intf;virtual;abstract;
          procedure second_char_to_char;virtual;abstract;
          procedure second_nothing; virtual;abstract;
       end;
       ttypeconvnodeclass = class of ttypeconvnode;

       tasnode = class(tbinarynode)
          constructor create(l,r : tnode);virtual;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          function getcopy: tnode;override;
          destructor destroy; override;
         protected
          call: tnode;
       end;
       tasnodeclass = class of tasnode;

       tisnode = class(tbinarynode)
          constructor create(l,r : tnode);virtual;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          procedure pass_2;override;
       end;
       tisnodeclass = class of tisnode;

    var
       ctypeconvnode : ttypeconvnodeclass;
       casnode : tasnodeclass;
       cisnode : tisnodeclass;

    procedure inserttypeconv(var p:tnode;const t:ttype);
    procedure inserttypeconv_internal(var p:tnode;const t:ttype);
    procedure arrayconstructor_to_set(var p : tnode);


implementation

   uses
      cclasses,globtype,systems,
      cutils,verbose,globals,widestr,
      symconst,symdef,symsym,symbase,symtable,
      ncon,ncal,nset,nadd,ninl,nmem,nmat,nutils,
      cgbase,procinfo,
      htypechk,pass_1,cpuinfo;


{*****************************************************************************
                                   Helpers
*****************************************************************************}

    procedure inserttypeconv(var p:tnode;const t:ttype);

      begin
        if not assigned(p.resulttype.def) then
         begin
           resulttypepass(p);
           if codegenerror then
            exit;
         end;

        { don't insert obsolete type conversions }
        if equal_defs(p.resulttype.def,t.def) and
           not ((p.resulttype.def.deftype=setdef) and
                (tsetdef(p.resulttype.def).settype <>
                 tsetdef(t.def).settype)) then
         begin
           p.resulttype:=t;
         end
        else
         begin
           p:=ctypeconvnode.create(p,t);
           resulttypepass(p);
         end;
      end;


    procedure inserttypeconv_internal(var p:tnode;const t:ttype);

      begin
        if not assigned(p.resulttype.def) then
         begin
           resulttypepass(p);
           if codegenerror then
            exit;
         end;

        { don't insert obsolete type conversions }
        if equal_defs(p.resulttype.def,t.def) and
           not ((p.resulttype.def.deftype=setdef) and
                (tsetdef(p.resulttype.def).settype <>
                 tsetdef(t.def).settype)) then
         begin
           p.resulttype:=t;
         end
        else
         begin
           p:=ctypeconvnode.create_internal(p,t);
           resulttypepass(p);
         end;
      end;


{*****************************************************************************
                    Array constructor to Set Conversion
*****************************************************************************}

    procedure arrayconstructor_to_set(var p : tnode);

      var
        constp      : tsetconstnode;
        buildp,
        p2,p3,p4    : tnode;
        htype       : ttype;
        constset    : Pconstset;
        constsetlo,
        constsethi  : TConstExprInt;

        procedure update_constsethi(t:ttype);
          begin
            if ((t.def.deftype=orddef) and
                (torddef(t.def).high>=constsethi)) then
              begin
                if torddef(t.def).typ=uwidechar then
                  begin
                    constsethi:=255;
                    if htype.def=nil then
                      htype:=t;
                  end
                else
                  begin
                    constsethi:=torddef(t.def).high;
                    if htype.def=nil then
                      begin
                         if (constsethi>255) or
                            (torddef(t.def).low<0) then
                           htype:=u8inttype
                         else
                           htype:=t;
                      end;
                    if constsethi>255 then
                      constsethi:=255;
                  end;
              end
            else if ((t.def.deftype=enumdef) and
                    (tenumdef(t.def).max>=constsethi)) then
              begin
                 if htype.def=nil then
                   htype:=t;
                 constsethi:=tenumdef(t.def).max;
              end;
          end;

        procedure do_set(pos : longint);
          begin
            if (pos and not $ff)<>0 then
             Message(parser_e_illegal_set_expr);
            if pos>constsethi then
             constsethi:=pos;
            if pos<constsetlo then
             constsetlo:=pos;
            if pos in constset^ then
              Message(parser_e_illegal_set_expr);
            include(constset^,pos);
          end;

      var
        l : Longint;
        lr,hr : TConstExprInt;
        hp : tarrayconstructornode;
      begin
        if p.nodetype<>arrayconstructorn then
          internalerror(200205105);
        new(constset);
        constset^:=[];
        htype.reset;
        constsetlo:=0;
        constsethi:=0;
        constp:=csetconstnode.create(nil,htype);
        constp.value_set:=constset;
        buildp:=constp;
        hp:=tarrayconstructornode(p);
        if assigned(hp.left) then
         begin
           while assigned(hp) do
            begin
              p4:=nil; { will contain the tree to create the set }
            {split a range into p2 and p3 }
              if hp.left.nodetype=arrayconstructorrangen then
               begin
                 p2:=tarrayconstructorrangenode(hp.left).left;
                 p3:=tarrayconstructorrangenode(hp.left).right;
                 tarrayconstructorrangenode(hp.left).left:=nil;
                 tarrayconstructorrangenode(hp.left).right:=nil;
               end
              else
               begin
                 p2:=hp.left;
                 hp.left:=nil;
                 p3:=nil;
               end;
              resulttypepass(p2);
              if assigned(p3) then
               resulttypepass(p3);
              if codegenerror then
               break;
              case p2.resulttype.def.deftype of
                 enumdef,
                 orddef:
                   begin
                      getrange(p2.resulttype.def,lr,hr);
                      if assigned(p3) then
                       begin
                         { this isn't good, you'll get problems with
                           type t010 = 0..10;
                                ts = set of t010;
                           var  s : ts;b : t010
                           begin  s:=[1,2,b]; end.
                         if is_integer(p3^.resulttype.def) then
                          begin
                            inserttypeconv(p3,u8bitdef);
                          end;
                         }
                         if assigned(htype.def) and not(equal_defs(htype.def,p3.resulttype.def)) then
                           begin
                              aktfilepos:=p3.fileinfo;
                              CGMessage(type_e_typeconflict_in_set);
                           end
                         else
                           begin
                             if (p2.nodetype=ordconstn) and (p3.nodetype=ordconstn) then
                              begin
                                 if not(is_integer(p3.resulttype.def)) then
                                   htype:=p3.resulttype
                                 else
                                   begin
                                     inserttypeconv(p3,u8inttype);
                                     inserttypeconv(p2,u8inttype);
                                   end;

                                for l:=tordconstnode(p2).value to tordconstnode(p3).value do
                                  do_set(l);
                                p2.free;
                                p3.free;
                              end
                             else
                              begin
                                update_constsethi(p2.resulttype);
                                inserttypeconv(p2,htype);

                                update_constsethi(p3.resulttype);
                                inserttypeconv(p3,htype);

                                if assigned(htype.def) then
                                  inserttypeconv(p3,htype)
                                else
                                  inserttypeconv(p3,u8inttype);
                                p4:=csetelementnode.create(p2,p3);
                              end;
                           end;
                       end
                      else
                       begin
                      { Single value }
                         if p2.nodetype=ordconstn then
                          begin
                            if not(is_integer(p2.resulttype.def)) then
                              update_constsethi(p2.resulttype)
                            else
                              inserttypeconv(p2,u8inttype);

                            do_set(tordconstnode(p2).value);
                            p2.free;
                          end
                         else
                          begin
                            update_constsethi(p2.resulttype);

                            if assigned(htype.def) then
                              inserttypeconv(p2,htype)
                            else
                              inserttypeconv(p2,u8inttype);

                            p4:=csetelementnode.create(p2,nil);
                          end;
                       end;
                    end;

                  stringdef :
                    begin
                        { if we've already set elements which are constants }
                        { throw an error                                    }
                        if ((htype.def=nil) and assigned(buildp)) or
                          not(is_char(htype.def)) then
                          CGMessage(type_e_typeconflict_in_set)
                        else
                         for l:=1 to length(pstring(tstringconstnode(p2).value_str)^) do
                          do_set(ord(pstring(tstringconstnode(p2).value_str)^[l]));
                        if htype.def=nil then
                         htype:=cchartype;
                        p2.free;
                      end;

                    else
                      CGMessage(type_e_ordinal_expr_expected);
              end;
              { insert the set creation tree }
              if assigned(p4) then
               buildp:=caddnode.create(addn,buildp,p4);
              { load next and dispose current node }
              p2:=hp;
              hp:=tarrayconstructornode(tarrayconstructornode(p2).right);
              tarrayconstructornode(p2).right:=nil;
              p2.free;
            end;
           if (htype.def=nil) then
            htype:=u8inttype;
         end
        else
         begin
           { empty set [], only remove node }
           p.free;
         end;
        { set the initial set type }
        constp.resulttype.setdef(tsetdef.create(htype,constsethi));
        { determine the resulttype for the tree }
        resulttypepass(buildp);
        { set the new tree }
        p:=buildp;
      end;


{*****************************************************************************
                           TTYPECONVNODE
*****************************************************************************}


    constructor ttypeconvnode.create(node : tnode;const t:ttype);

      begin
         inherited create(typeconvn,node);
         convtype:=tc_none;
         totype:=t;
         if t.def=nil then
          internalerror(200103281);
         fileinfo:=node.fileinfo;
      end;


    constructor ttypeconvnode.create_explicit(node : tnode;const t:ttype);

      begin
         self.create(node,t);
         include(flags,nf_explicit);
      end;


    constructor ttypeconvnode.create_internal(node : tnode;const t:ttype);

      begin
         self.create(node,t);
         { handle like explicit conversions }
         include(flags,nf_explicit);
         include(flags,nf_internal);
      end;


    constructor ttypeconvnode.create_proc_to_procvar(node : tnode);

      begin
         self.create(node,voidtype);
         convtype:=tc_proc_2_procvar;
      end;


    constructor ttypeconvnode.ppuload(t:tnodetype;ppufile:tcompilerppufile);
      begin
        inherited ppuload(t,ppufile);
        ppufile.gettype(totype);
        convtype:=tconverttype(ppufile.getbyte);
      end;


    procedure ttypeconvnode.ppuwrite(ppufile:tcompilerppufile);
      begin
        inherited ppuwrite(ppufile);
        ppufile.puttype(totype);
        ppufile.putbyte(byte(convtype));
      end;


    procedure ttypeconvnode.buildderefimpl;
      begin
        inherited buildderefimpl;
        totype.buildderef;
      end;


    procedure ttypeconvnode.derefimpl;
      begin
        inherited derefimpl;
        totype.resolve;
      end;


    function ttypeconvnode.getcopy : tnode;

      var
         n : ttypeconvnode;

      begin
         n:=ttypeconvnode(inherited getcopy);
         n.convtype:=convtype;
         n.totype:=totype;
         getcopy:=n;
      end;


    function ttypeconvnode.resulttype_cord_to_pointer : tnode;

      var
        t : tnode;

      begin
        result:=nil;
        if left.nodetype=ordconstn then
          begin
            { check if we have a valid pointer constant (JM) }
            if (sizeof(pointer) > sizeof(TConstPtrUInt)) then
              if (sizeof(TConstPtrUInt) = 4) then
                begin
                  if (tordconstnode(left).value < low(longint)) or
                     (tordconstnode(left).value > high(cardinal)) then
                  CGMessage(parser_e_range_check_error);
                end
              else if (sizeof(TConstPtrUInt) = 8) then
                begin
                  if (tordconstnode(left).value < low(int64)) or
                     (tordconstnode(left).value > high(qword)) then
                  CGMessage(parser_e_range_check_error);
                end
              else
                internalerror(2001020801);
            t:=cpointerconstnode.create(TConstPtrUInt(tordconstnode(left).value),resulttype);
            result:=t;
          end
         else
          internalerror(200104023);
      end;

    function ttypeconvnode.resulttype_chararray_to_string : tnode;

      begin
        result := ccallnode.createinternres(
          'fpc_chararray_to_'+tstringdef(resulttype.def).stringtypname,
          ccallparanode.create(left,nil),resulttype);
        left := nil;
      end;

    function ttypeconvnode.resulttype_string_to_chararray : tnode;

      var
        arrsize : aint;

      begin
         with tarraydef(resulttype.def) do
          begin
            if highrange<lowrange then
             internalerror(75432653);
            arrsize := highrange-lowrange+1;
          end;
         if (left.nodetype = stringconstn) and
            { left.length+1 since there's always a terminating #0 character (JM) }
            (tstringconstnode(left).len+1 >= arrsize) and
            (tstringdef(left.resulttype.def).string_typ=st_shortstring) then
           begin
             { handled separately }
             result := nil;
             exit;
           end;
        result := ccallnode.createinternres(
          'fpc_'+tstringdef(left.resulttype.def).stringtypname+
          '_to_chararray',ccallparanode.create(left,ccallparanode.create(
          cordconstnode.create(arrsize,s32inttype,true),nil)),resulttype);
        left := nil;
      end;


    function ttypeconvnode.resulttype_string_to_string : tnode;

      var
        procname: string[31];
        stringpara : tcallparanode;
        pw : pcompilerwidestring;
        pc : pchar;

      begin
         result:=nil;
         if left.nodetype=stringconstn then
          begin
             { convert ascii 2 unicode }
           {$ifdef ansistring_bits}
             if (tstringdef(resulttype.def).string_typ=st_widestring) and
                (tstringconstnode(left).st_type in [st_ansistring16,st_ansistring32,
                       st_ansistring64,st_shortstring,st_longstring]) then
           {$else}
             if (tstringdef(resulttype.def).string_typ=st_widestring) and
                (tstringconstnode(left).st_type in [st_ansistring,st_shortstring,st_longstring]) then
           {$endif}
              begin
                initwidestring(pw);
                ascii2unicode(tstringconstnode(left).value_str,tstringconstnode(left).len,pw);
                ansistringdispose(tstringconstnode(left).value_str,tstringconstnode(left).len);
                pcompilerwidestring(tstringconstnode(left).value_str):=pw;
              end
             else
             { convert unicode 2 ascii }
           {$ifdef ansistring_bits}
             if (tstringconstnode(left).st_type=st_widestring) and
                (tstringdef(resulttype.def).string_typ in [st_ansistring16,st_ansistring32,
                           st_ansistring64,st_shortstring,st_longstring]) then
           {$else}
             if (tstringconstnode(left).st_type=st_widestring) and
                (tstringdef(resulttype.def).string_typ in [st_ansistring,st_shortstring,st_longstring]) then
           {$endif}
              begin
                pw:=pcompilerwidestring(tstringconstnode(left).value_str);
                getmem(pc,getlengthwidestring(pw)+1);
                unicode2ascii(pw,pc);
                donewidestring(pw);
                tstringconstnode(left).value_str:=pc;
              end;
             tstringconstnode(left).st_type:=tstringdef(resulttype.def).string_typ;
             tstringconstnode(left).resulttype:=resulttype;
             result:=left;
             left:=nil;
          end
         else
           begin
             { get the correct procedure name }
             procname := 'fpc_'+tstringdef(left.resulttype.def).stringtypname+
                         '_to_'+tstringdef(resulttype.def).stringtypname;

             { create parameter (and remove left node from typeconvnode }
             { since it's reused as parameter)                          }
             stringpara := ccallparanode.create(left,nil);
             left := nil;

             { when converting to shortstrings, we have to pass high(destination) too }
             if (tstringdef(resulttype.def).string_typ = st_shortstring) then
               stringpara.right := ccallparanode.create(cinlinenode.create(
                 in_high_x,false,self.getcopy),nil);

             { and create the callnode }
             result := ccallnode.createinternres(procname,stringpara,resulttype);
           end;
      end;


    function ttypeconvnode.resulttype_char_to_string : tnode;

      var
         procname: string[31];
         para : tcallparanode;
         hp : tstringconstnode;
         ws : pcompilerwidestring;

      begin
         result:=nil;
         if left.nodetype=ordconstn then
           begin
              if tstringdef(resulttype.def).string_typ=st_widestring then
               begin
                 initwidestring(ws);
                 concatwidestringchar(ws,tcompilerwidechar(chr(tordconstnode(left).value)));
                 hp:=cstringconstnode.createwstr(ws);
                 donewidestring(ws);
               end
              else
               hp:=cstringconstnode.createstr(chr(tordconstnode(left).value),tstringdef(resulttype.def).string_typ);
              result:=hp;
           end
         else
           { shortstrings are handled 'inline' }
           if tstringdef(resulttype.def).string_typ <> st_shortstring then
             begin
               { create the parameter }
               para := ccallparanode.create(left,nil);
               left := nil;

               { and the procname }
               procname := 'fpc_char_to_' +tstringdef(resulttype.def).stringtypname;

               { and finally the call }
               result := ccallnode.createinternres(procname,para,resulttype);
             end
           else
             begin
               { create word(byte(char) shl 8 or 1) for litte endian machines }
               { and word(byte(char) or 256) for big endian machines          }
               left := ctypeconvnode.create_internal(left,u8inttype);
               if (target_info.endian = endian_little) then
                 left := caddnode.create(orn,
                   cshlshrnode.create(shln,left,cordconstnode.create(8,s32inttype,false)),
                   cordconstnode.create(1,s32inttype,false))
               else
                 left := caddnode.create(orn,left,
                   cordconstnode.create(1 shl 8,s32inttype,false));
               left := ctypeconvnode.create_internal(left,u16inttype);
               resulttypepass(left);
             end;
      end;


    function ttypeconvnode.resulttype_char_to_chararray : tnode;

      begin
        if resulttype.def.size <> 1 then
          begin
            { convert first to string, then to chararray }
            inserttypeconv(left,cshortstringtype);
            inserttypeconv(left,resulttype);
            result:=left;
            left := nil;
            exit;
          end;
        result := nil;
      end;


    function ttypeconvnode.resulttype_char_to_char : tnode;

      var
         hp : tordconstnode;

      begin
         result:=nil;
         if left.nodetype=ordconstn then
           begin
             if (torddef(resulttype.def).typ=uchar) and
                (torddef(left.resulttype.def).typ=uwidechar) then
              begin
                hp:=cordconstnode.create(
                      ord(unicode2asciichar(tcompilerwidechar(tordconstnode(left).value))),
                      cchartype,true);
                result:=hp;
              end
             else if (torddef(resulttype.def).typ=uwidechar) and
                     (torddef(left.resulttype.def).typ=uchar) then
              begin
                hp:=cordconstnode.create(
                      asciichar2unicode(chr(tordconstnode(left).value)),
                      cwidechartype,true);
                result:=hp;
              end
             else
              internalerror(200105131);
             exit;
           end;
      end;


    function ttypeconvnode.resulttype_int_to_int : tnode;
      var
        v : TConstExprInt;
      begin
        result:=nil;
        if left.nodetype=ordconstn then
         begin
           v:=tordconstnode(left).value;
           if is_currency(resulttype.def) then
             v:=v*10000;
           if (resulttype.def.deftype=pointerdef) then
             result:=cpointerconstnode.create(TConstPtrUInt(v),resulttype)
           else
             begin
               if is_currency(left.resulttype.def) then
                 v:=v div 10000;
               result:=cordconstnode.create(v,resulttype,false);
             end;
         end
        else if left.nodetype=pointerconstn then
         begin
           v:=tpointerconstnode(left).value;
           if (resulttype.def.deftype=pointerdef) then
             result:=cpointerconstnode.create(v,resulttype)
           else
             begin
               if is_currency(resulttype.def) then
                 v:=v*10000;
               result:=cordconstnode.create(v,resulttype,false);
             end;
         end
        else
         begin
           { multiply by 10000 for currency. We need to use getcopy to pass
             the argument because the current node is always disposed. Only
             inserting the multiply in the left node is not possible because
             it'll get in an infinite loop to convert int->currency }
           if is_currency(resulttype.def) then
            begin
              result:=caddnode.create(muln,getcopy,cordconstnode.create(10000,resulttype,false));
              include(result.flags,nf_is_currency);
            end
           else if is_currency(left.resulttype.def) then
            begin
              result:=cmoddivnode.create(divn,getcopy,cordconstnode.create(10000,resulttype,false));
              include(result.flags,nf_is_currency);
            end;
         end;
      end;


    function ttypeconvnode.resulttype_int_to_real : tnode;
      var
        rv : bestreal;
      begin
        result:=nil;
        if left.nodetype=ordconstn then
         begin
           rv:=tordconstnode(left).value;
           if is_currency(resulttype.def) then
             rv:=rv*10000.0
           else if is_currency(left.resulttype.def) then
             rv:=rv/10000.0;
           result:=crealconstnode.create(rv,resulttype);
         end
        else
         begin
           { multiply by 10000 for currency. We need to use getcopy to pass
             the argument because the current node is always disposed. Only
             inserting the multiply in the left node is not possible because
             it'll get in an infinite loop to convert int->currency }
           if is_currency(resulttype.def) then
            begin
              result:=caddnode.create(muln,getcopy,crealconstnode.create(10000.0,resulttype));
              include(result.flags,nf_is_currency);
            end
           else if is_currency(left.resulttype.def) then
            begin
              result:=caddnode.create(slashn,getcopy,crealconstnode.create(10000.0,resulttype));
              include(result.flags,nf_is_currency);
            end;
         end;
      end;


    function ttypeconvnode.resulttype_real_to_currency : tnode;
      begin
        if not is_currency(resulttype.def) then
          internalerror(200304221);
        result:=nil;
        left:=caddnode.create(muln,left,crealconstnode.create(10000.0,left.resulttype));
        include(left.flags,nf_is_currency);
        resulttypepass(left);
        { Convert constants directly, else call Round() }
        if left.nodetype=realconstn then
          result:=cordconstnode.create(round(trealconstnode(left).value_real),resulttype,false)
        else
          result:=ccallnode.createinternres('fpc_round_real',
            ccallparanode.create(left,nil),resulttype);
        left:=nil;
      end;


    function ttypeconvnode.resulttype_real_to_real : tnode;
      begin
         result:=nil;
         if is_currency(left.resulttype.def) and not(is_currency(resulttype.def)) then
           begin
             left:=caddnode.create(slashn,left,crealconstnode.create(10000.0,left.resulttype));
             include(left.flags,nf_is_currency);
             resulttypepass(left);
           end
         else
           if is_currency(resulttype.def) and not(is_currency(left.resulttype.def)) then
             begin
               left:=caddnode.create(muln,left,crealconstnode.create(10000.0,left.resulttype));
               include(left.flags,nf_is_currency);
               resulttypepass(left);
             end;
         if left.nodetype=realconstn then
           result:=crealconstnode.create(trealconstnode(left).value_real,resulttype);
      end;


    function ttypeconvnode.resulttype_cchar_to_pchar : tnode;

      begin
         result:=nil;
         if is_pwidechar(resulttype.def) then
          inserttypeconv(left,cwidestringtype)
         else
          inserttypeconv(left,cshortstringtype);
         { evaluate again, reset resulttype so the convert_typ
           will be calculated again and cstring_to_pchar will
           be used for futher conversion }
         convtype:=tc_none;
         result:=det_resulttype;
      end;


    function ttypeconvnode.resulttype_cstring_to_pchar : tnode;

      begin
         result:=nil;
         if is_pwidechar(resulttype.def) then
           inserttypeconv(left,cwidestringtype);
      end;


    function ttypeconvnode.resulttype_arrayconstructor_to_set : tnode;

      var
        hp : tnode;

      begin
        result:=nil;
        if left.nodetype<>arrayconstructorn then
         internalerror(5546);
        { remove typeconv node }
        hp:=left;
        left:=nil;
        { create a set constructor tree }
        arrayconstructor_to_set(hp);
        result:=hp;
      end;


    function ttypeconvnode.resulttype_pchar_to_string : tnode;

      begin
        result := ccallnode.createinternres(
          'fpc_pchar_to_'+tstringdef(resulttype.def).stringtypname,
          ccallparanode.create(left,nil),resulttype);
        left := nil;
      end;


    function ttypeconvnode.resulttype_interface_to_guid : tnode;

      begin
        if assigned(tobjectdef(left.resulttype.def).iidguid) then
          result:=cguidconstnode.create(tobjectdef(left.resulttype.def).iidguid^);
      end;


    function ttypeconvnode.resulttype_dynarray_to_openarray : tnode;

      begin
        { a dynamic array is a pointer to an array, so to convert it to }
        { an open array, we have to dereference it (JM)                 }
        result := ctypeconvnode.create_internal(left,voidpointertype);
        resulttypepass(result);
        { left is reused }
        left := nil;
        result := cderefnode.create(result);
        include(result.flags,nf_no_checkpointer);
        result.resulttype := resulttype;
      end;


    function ttypeconvnode.resulttype_pwchar_to_string : tnode;

      begin
        result := ccallnode.createinternres(
          'fpc_pwidechar_to_'+tstringdef(resulttype.def).stringtypname,
          ccallparanode.create(left,nil),resulttype);
        left := nil;
      end;


    function ttypeconvnode.resulttype_variant_to_dynarray : tnode;

      begin
        result := ccallnode.createinternres(
          'fpc_variant_to_dynarray',
          ccallparanode.create(caddrnode.create_internal(crttinode.create(tstoreddef(resulttype.def),initrtti)),
            ccallparanode.create(left,nil)
          ),resulttype);
        resulttypepass(result);
        left:=nil;
      end;


    function ttypeconvnode.resulttype_dynarray_to_variant : tnode;

      begin
        result := ccallnode.createinternres(
          'fpc_dynarray_to_variant',
          ccallparanode.create(caddrnode.create_internal(crttinode.create(tstoreddef(resulttype.def),initrtti)),
            ccallparanode.create(ctypeconvnode.create_explicit(left,voidpointertype),nil)
          ),resulttype);
        resulttypepass(result);
        left:=nil;
      end;


    function ttypeconvnode.resulttype_variant_to_enum : tnode;

      begin
        result := ctypeconvnode.create_internal(left,sinttype);
        result := ctypeconvnode.create_internal(result,resulttype);
        resulttypepass(result);
        { left is reused }
        left := nil;
      end;


    function ttypeconvnode.resulttype_enum_to_variant : tnode;

      begin
        result := ctypeconvnode.create_internal(left,sinttype);
        result := ctypeconvnode.create_internal(result,cvarianttype);
        resulttypepass(result);
        { left is reused }
        left := nil;
      end;


    procedure copyparasym(p:TNamedIndexItem;arg:pointer);
      var
        newparast : tsymtable absolute arg;
        vs : tparavarsym;
      begin
        if tsym(p).typ<>paravarsym then
          exit;
        with tparavarsym(p) do
          begin
            vs:=tparavarsym.create(realname,paranr,varspez,vartype,varoptions);
            vs.defaultconstsym:=defaultconstsym;
            newparast.insert(vs);
          end;
      end;


    function ttypeconvnode.resulttype_proc_to_procvar : tnode;
      var
        pd : tabstractprocdef;
      begin
        result:=nil;
        pd:=tabstractprocdef(left.resulttype.def);

        { create procvardef }
        resulttype.setdef(tprocvardef.create(pd.parast.symtablelevel));
        tprocvardef(resulttype.def).proctypeoption:=pd.proctypeoption;
        tprocvardef(resulttype.def).proccalloption:=pd.proccalloption;
        tprocvardef(resulttype.def).procoptions:=pd.procoptions;
        tprocvardef(resulttype.def).rettype:=pd.rettype;

        { method ? then set the methodpointer flag }
        if (pd.owner.symtabletype=objectsymtable) then
          include(tprocvardef(resulttype.def).procoptions,po_methodpointer);

        { only need the address of the method? this is needed
          for @tobject.create. In this case there will be a loadn without
          a methodpointer. }
        if (left.nodetype=loadn) and
           not assigned(tloadnode(left).left) then
          include(tprocvardef(resulttype.def).procoptions,po_addressonly);

        { Add parameters use only references, we don't need to keep the
          parast. We use the parast from the original function to calculate
          our parameter data and reset it afterwards }
        pd.parast.foreach_static(@copyparasym,tprocvardef(resulttype.def).parast);
        tprocvardef(resulttype.def).calcparas;
      end;


    function ttypeconvnode.resulttype_call_helper(c : tconverttype) : tnode;
{$ifdef fpc}
      const
         resulttypeconvert : array[tconverttype] of pointer = (
          {none} nil,
          {equal} nil,
          {not_possible} nil,
          { string_2_string } @ttypeconvnode.resulttype_string_to_string,
          { char_2_string } @ttypeconvnode.resulttype_char_to_string,
          { char_2_chararray } @ttypeconvnode.resulttype_char_to_chararray,
          { pchar_2_string } @ttypeconvnode.resulttype_pchar_to_string,
          { cchar_2_pchar } @ttypeconvnode.resulttype_cchar_to_pchar,
          { cstring_2_pchar } @ttypeconvnode.resulttype_cstring_to_pchar,
          { ansistring_2_pchar } nil,
          { string_2_chararray } @ttypeconvnode.resulttype_string_to_chararray,
          { chararray_2_string } @ttypeconvnode.resulttype_chararray_to_string,
          { array_2_pointer } nil,
          { pointer_2_array } nil,
          { int_2_int } @ttypeconvnode.resulttype_int_to_int,
          { int_2_bool } nil,
          { bool_2_bool } nil,
          { bool_2_int } nil,
          { real_2_real } @ttypeconvnode.resulttype_real_to_real,
          { int_2_real } @ttypeconvnode.resulttype_int_to_real,
          { real_2_currency } @ttypeconvnode.resulttype_real_to_currency,
          { proc_2_procvar } @ttypeconvnode.resulttype_proc_to_procvar,
          { arrayconstructor_2_set } @ttypeconvnode.resulttype_arrayconstructor_to_set,
          { load_smallset } nil,
          { cord_2_pointer } @ttypeconvnode.resulttype_cord_to_pointer,
          { intf_2_string } nil,
          { intf_2_guid } @ttypeconvnode.resulttype_interface_to_guid,
          { class_2_intf } nil,
          { char_2_char } @ttypeconvnode.resulttype_char_to_char,
          { normal_2_smallset} nil,
          { dynarray_2_openarray} @ttypeconvnode.resulttype_dynarray_to_openarray,
          { pwchar_2_string} @ttypeconvnode.resulttype_pwchar_to_string,
          { variant_2_dynarray} @ttypeconvnode.resulttype_variant_to_dynarray,
          { dynarray_2_variant} @ttypeconvnode.resulttype_dynarray_to_variant,
          { variant_2_enum} @ttypeconvnode.resulttype_variant_to_enum,
          { enum_2_variant} @ttypeconvnode.resulttype_enum_to_variant
         );
      type
         tprocedureofobject = function : tnode of object;
      var
         r : packed record
                proc : pointer;
                obj : pointer;
             end;
      begin
         result:=nil;
         { this is a little bit dirty but it works }
         { and should be quite portable too        }
         r.proc:=resulttypeconvert[c];
         r.obj:=self;
         if assigned(r.proc) then
          result:=tprocedureofobject(r)();
      end;
{$else}
      begin
        case c of
          tc_string_2_string: resulttype_string_to_string;
          tc_char_2_string : resulttype_char_to_string;
          tc_char_2_chararray: resulttype_char_to_chararray;
          tc_pchar_2_string : resulttype_pchar_to_string;
          tc_cchar_2_pchar : resulttype_cchar_to_pchar;
          tc_cstring_2_pchar : resulttype_cstring_to_pchar;
          tc_string_2_chararray : resulttype_string_to_chararray;
          tc_chararray_2_string : resulttype_chararray_to_string;
          tc_real_2_real : resulttype_real_to_real;
          tc_int_2_real : resulttype_int_to_real;
          tc_real_2_currency : resulttype_real_to_currency;
          tc_arrayconstructor_2_set : resulttype_arrayconstructor_to_set;
          tc_cord_2_pointer : resulttype_cord_to_pointer;
          tc_intf_2_guid : resulttype_interface_to_guid;
          tc_char_2_char : resulttype_char_to_char;
          tc_dynarray_2_openarray : resulttype_dynarray_to_openarray;
          tc_pwchar_2_string : resulttype_pwchar_to_string;
          tc_variant_2_dynarray : resulttype_variant_to_dynarray;
          tc_dynarray_2_variant : resulttype_dynarray_to_variant;
        end;
      end;
{$Endif fpc}


    function ttypeconvnode.det_resulttype:tnode;

      var
        htype : ttype;
        hp : tnode;
        currprocdef : tabstractprocdef;
        aprocdef : tprocdef;
        eq : tequaltype;
        cdoptions : tcompare_defs_options;
      begin
        result:=nil;
        resulttype:=totype;

        resulttypepass(left);
        if codegenerror then
         exit;

        { When absolute force tc_equal }
        if (nf_absolute in flags) then
          begin
            convtype:=tc_equal;
            if not(tstoreddef(resulttype.def).is_intregable) and
               not(tstoreddef(resulttype.def).is_fpuregable) then
              make_not_regable(left);
            exit;
          end;

        { tp procvar support. Skip typecasts to procvar, record or set. Those
          convert on the procvar value. This is used to access the
          fields of a methodpointer }
        if not(nf_load_procvar in flags) and
           not(resulttype.def.deftype in [procvardef,recorddef,setdef]) then
          maybe_call_procvar(left,true);

        { convert array constructors to sets, because there is no conversion
          possible for array constructors }
        if (resulttype.def.deftype<>arraydef) and
           is_array_constructor(left.resulttype.def) then
          begin
            arrayconstructor_to_set(left);
            resulttypepass(left);
          end;

        if convtype=tc_none then
          begin
            cdoptions:=[cdo_check_operator,cdo_allow_variant];
            if nf_explicit in flags then
              include(cdoptions,cdo_explicit);
            if nf_internal in flags then
              include(cdoptions,cdo_internal);
            eq:=compare_defs_ext(left.resulttype.def,resulttype.def,left.nodetype,convtype,aprocdef,cdoptions);
            case eq of
              te_exact,
              te_equal :
                begin
                  { because is_equal only checks the basetype for sets we need to
                    check here if we are loading a smallset into a normalset }
                  if (resulttype.def.deftype=setdef) and
                     (left.resulttype.def.deftype=setdef) and
                     ((tsetdef(resulttype.def).settype = smallset) xor
                      (tsetdef(left.resulttype.def).settype = smallset)) then
                    begin
                      { constant sets can be converted by changing the type only }
                      if (left.nodetype=setconstn) then
                       begin
                         left.resulttype:=resulttype;
                         result:=left;
                         left:=nil;
                         exit;
                       end;

                      if (tsetdef(resulttype.def).settype <> smallset) then
                       convtype:=tc_load_smallset
                      else
                       convtype := tc_normal_2_smallset;
                      exit;
                    end
                  else
                   begin
                     { Only leave when there is no conversion to do.
                       We can still need to call a conversion routine,
                       like the routine to convert a stringconstnode }
                     if convtype in [tc_equal,tc_not_possible] then
                      begin
                        left.resulttype:=resulttype;
                        result:=left;
                        left:=nil;
                        exit;
                      end;
                   end;
                end;

              te_convert_l1,
              te_convert_l2,
              te_convert_l3 :
                begin
                  { nothing to do }
                end;

              te_convert_operator :
                begin
                  include(current_procinfo.flags,pi_do_call);
                  inc(aprocdef.procsym.refs);
                  hp:=ccallnode.create(ccallparanode.create(left,nil),Tprocsym(aprocdef.procsym),nil,nil,[]);
                  { tell explicitly which def we must use !! (PM) }
                  tcallnode(hp).procdefinition:=aprocdef;
                  left:=nil;
                  result:=hp;
                  exit;
                end;

              te_incompatible :
                begin
                  { Procedures have a resulttype.def of voiddef and functions of their
                    own resulttype.def. They will therefore always be incompatible with
                    a procvar. Because isconvertable cannot check for procedures we
                    use an extra check for them.}
                  if (m_tp_procvar in aktmodeswitches) and
                     (resulttype.def.deftype=procvardef) then
                   begin
                      if (left.nodetype=calln) and
                         (tcallnode(left).para_count=0) then
                       begin
                         if assigned(tcallnode(left).right) then
                          begin
                            { this is already a procvar, if it is really equal
                              is checked below }
                            convtype:=tc_equal;
                            hp:=tcallnode(left).right.getcopy;
                            currprocdef:=tabstractprocdef(hp.resulttype.def);
                          end
                         else
                          begin
                            convtype:=tc_proc_2_procvar;
                            currprocdef:=Tprocsym(Tcallnode(left).symtableprocentry).search_procdef_byprocvardef(Tprocvardef(resulttype.def));
                            hp:=cloadnode.create_procvar(tprocsym(tcallnode(left).symtableprocentry),
                                tprocdef(currprocdef),tcallnode(left).symtableproc);
                            if (tcallnode(left).symtableprocentry.owner.symtabletype=objectsymtable) then
                             begin
                               if assigned(tcallnode(left).methodpointer) then
                                 begin
                                   { Under certain circumstances the methodpointer is a loadvmtaddrn
                                     which isn't possible if it is used as a method pointer, so
                                     fix this.
                                     If you change this, ensure that tests/tbs/tw2669.pp still works }
                                   if tcallnode(left).methodpointer.nodetype=loadvmtaddrn then
                                     tloadnode(hp).set_mp(tloadvmtaddrnode(tcallnode(left).methodpointer).left.getcopy)
                                   else
                                     tloadnode(hp).set_mp(tcallnode(left).methodpointer.getcopy);
                                 end
                               else
                                 tloadnode(hp).set_mp(load_self_node);
                             end;
                            resulttypepass(hp);
                          end;
                         left.free;
                         left:=hp;
                         { Now check if the procedure we are going to assign to
                           the procvar, is compatible with the procvar's type }
                         if not(nf_explicit in flags) and
                            (proc_to_procvar_equal(currprocdef,
                                                   tprocvardef(resulttype.def),true)=te_incompatible) then
                           IncompatibleTypes(left.resulttype.def,resulttype.def);
                         exit;
                       end;
                   end;

                  { Handle explicit type conversions }
                  if nf_explicit in flags then
                   begin
                     { do common tc_equal cast }
                     convtype:=tc_equal;

                     { ordinal constants can be resized to 1,2,4,8 bytes }
                     if (left.nodetype=ordconstn) then
                       begin
                         { Insert typeconv for ordinal to the correct size first on left, after
                           that the other conversion can be done }
                         htype.reset;
                         case longint(resulttype.def.size) of
                           1 :
                             htype:=s8inttype;
                           2 :
                             htype:=s16inttype;
                           4 :
                             htype:=s32inttype;
                           8 :
                             htype:=s64inttype;
                         end;
                         { we need explicit, because it can also be an enum }
                         if assigned(htype.def) then
                           inserttypeconv_internal(left,htype)
                         else
                           CGMessage2(type_e_illegal_type_conversion,left.resulttype.def.gettypename,resulttype.def.gettypename);
                       end;

                     { check if the result could be in a register }
                     if (not(tstoreddef(resulttype.def).is_intregable) and
                         not(tstoreddef(resulttype.def).is_fpuregable)) or
                        ((left.resulttype.def.deftype = floatdef) and
                         (resulttype.def.deftype <> floatdef))  then
                       make_not_regable(left);

                     { class to class or object to object, with checkobject support }
                     if (resulttype.def.deftype=objectdef) and
                        (left.resulttype.def.deftype=objectdef) then
                       begin
                         if (cs_check_object in aktlocalswitches) then
                          begin
                            if is_class_or_interface(resulttype.def) then
                             begin
                               { we can translate the typeconvnode to 'as' when
                                 typecasting to a class or interface }
                               hp:=casnode.create(left,cloadvmtaddrnode.create(ctypenode.create(resulttype)));
                               left:=nil;
                               result:=hp;
                               exit;
                             end;
                          end
                         else
                          begin
                            { check if the types are related }
                            if not(nf_internal in flags) and
                               (not(tobjectdef(left.resulttype.def).is_related(tobjectdef(resulttype.def)))) and
                               (not(tobjectdef(resulttype.def).is_related(tobjectdef(left.resulttype.def)))) then
                              begin
                                { Give an error when typecasting class to interface, this is compatible
                                  with delphi }
                                if is_interface(resulttype.def) and
                                   not is_interface(left.resulttype.def) then
                                  CGMessage2(type_e_classes_not_related,
                                    FullTypeName(left.resulttype.def,resulttype.def),
                                    FullTypeName(resulttype.def,left.resulttype.def))
                                else
                                  CGMessage2(type_w_classes_not_related,
                                    FullTypeName(left.resulttype.def,resulttype.def),
                                    FullTypeName(resulttype.def,left.resulttype.def))
                              end;
                          end;
                       end

                      else
                       begin
                         { only if the same size or formal def }
                         if not(
                                (left.resulttype.def.deftype=formaldef) or
                                (
                                 not(is_open_array(left.resulttype.def)) and
                                 (left.resulttype.def.size=resulttype.def.size)
                                ) or
                                (
                                 is_void(left.resulttype.def)  and
                                 (left.nodetype=derefn)
                                )
                               ) then
                           CGMessage2(type_e_illegal_type_conversion,left.resulttype.def.gettypename,resulttype.def.gettypename);
                       end;
                   end
                  else
                   IncompatibleTypes(left.resulttype.def,resulttype.def);
                end;

              else
                internalerror(200211231);
            end;
          end;
        { Give hint or warning for unportable code, exceptions are
           - typecasts from constants
           - void }
        if not(nf_internal in flags) and
           (left.nodetype<>ordconstn) and
           not(is_void(left.resulttype.def)) and
           (((left.resulttype.def.deftype=orddef) and
             (resulttype.def.deftype in [pointerdef,procvardef,classrefdef])) or
            ((resulttype.def.deftype=orddef) and
             (left.resulttype.def.deftype in [pointerdef,procvardef,classrefdef]))) then
          begin
            { Give a warning when sizes don't match, because then info will be lost }
            if left.resulttype.def.size=resulttype.def.size then
              CGMessage(type_h_pointer_to_longint_conv_not_portable)
            else
              CGMessage(type_w_pointer_to_longint_conv_not_portable);
          end;

        { Constant folding and other node transitions to
          remove the typeconv node }
        case left.nodetype of
          niln :
            begin
              { nil to ordinal node }
              if (resulttype.def.deftype=orddef) then
               begin
                 hp:=cordconstnode.create(0,resulttype,true);
                 result:=hp;
                 exit;
               end
              else
               { fold nil to any pointer type }
               if (resulttype.def.deftype=pointerdef) then
                begin
                  hp:=cnilnode.create;
                  hp.resulttype:=resulttype;
                  result:=hp;
                  exit;
                end
              else
               { remove typeconv after niln, but not when the result is a
                 methodpointer. The typeconv of the methodpointer will then
                 take care of updateing size of niln to OS_64 }
               if not((resulttype.def.deftype=procvardef) and
                      (po_methodpointer in tprocvardef(resulttype.def).procoptions)) then
                 begin
                   left.resulttype:=resulttype;
                   result:=left;
                   left:=nil;
                   exit;
                 end;
            end;

          ordconstn :
            begin
              { ordinal contants can be directly converted }
              { but not char to char because it is a widechar to char or via versa }
              { which needs extra code to do the code page transistion             }
              { constant ordinal to pointer }
              if (resulttype.def.deftype=pointerdef) and
                 (convtype<>tc_cchar_2_pchar) then
                begin
                   hp:=cpointerconstnode.create(TConstPtrUInt(tordconstnode(left).value),resulttype);
                   result:=hp;
                   exit;
                end
              else if is_ordinal(resulttype.def) and
                      not(convtype=tc_char_2_char) then
                begin
                   { replace the resulttype and recheck the range }
                   left.resulttype:=resulttype;
                   testrange(left.resulttype.def,tordconstnode(left).value,(nf_explicit in flags));
                   result:=left;
                   left:=nil;
                   exit;
                end;
            end;

          pointerconstn :
            begin
              { pointerconstn to any pointer is folded too }
              if (resulttype.def.deftype=pointerdef) then
                begin
                   left.resulttype:=resulttype;
                   result:=left;
                   left:=nil;
                   exit;
                end
              { constant pointer to ordinal }
              else if is_ordinal(resulttype.def) then
                begin
                   hp:=cordconstnode.create(TConstExprInt(tpointerconstnode(left).value),
                     resulttype,true);
                   result:=hp;
                   exit;
                end;
            end;
        end;

        { check if the result could be in a register }
        if not(tstoreddef(resulttype.def).is_intregable) and
           not(tstoreddef(resulttype.def).is_fpuregable) then
          make_not_regable(left);

        { now call the resulttype helper to do constant folding }
        result:=resulttype_call_helper(convtype);
      end;

      procedure Ttypeconvnode.mark_write;

      begin
        left.mark_write;
      end;

    function ttypeconvnode.first_cord_to_pointer : tnode;

      begin
        result:=nil;
        internalerror(200104043);
      end;


    function ttypeconvnode.first_int_to_int : tnode;

      begin
        first_int_to_int:=nil;
        expectloc:=left.expectloc;
        if not is_void(left.resulttype.def) then
          begin
            if (left.expectloc<>LOC_REGISTER) and
               (resulttype.def.size>left.resulttype.def.size) then
              expectloc:=LOC_REGISTER
            else
              if (left.expectloc=LOC_CREGISTER) and
                 (resulttype.def.size<left.resulttype.def.size) then
                expectloc:=LOC_REGISTER;
          end;
{$ifndef cpu64bit}
        if is_64bit(resulttype.def) then
          registersint:=max(registersint,2)
        else
{$endif cpu64bit}
          registersint:=max(registersint,1);
      end;


    function ttypeconvnode.first_cstring_to_pchar : tnode;

      begin
         first_cstring_to_pchar:=nil;
         registersint:=1;
         expectloc:=LOC_REGISTER;
      end;


    function ttypeconvnode.first_string_to_chararray : tnode;

      begin
         first_string_to_chararray:=nil;
         expectloc:=left.expectloc;
      end;


    function ttypeconvnode.first_char_to_string : tnode;

      begin
         first_char_to_string:=nil;
         expectloc:=LOC_REFERENCE;
      end;


    function ttypeconvnode.first_nothing : tnode;
      begin
         first_nothing:=nil;
      end;


    function ttypeconvnode.first_array_to_pointer : tnode;

      begin
         first_array_to_pointer:=nil;
         if registersint<1 then
           registersint:=1;
         expectloc:=LOC_REGISTER;
      end;


    function ttypeconvnode.first_int_to_real: tnode;
      var
        fname: string[32];
        typname : string[12];
      begin
        { Get the type name  }
        {  Normally the typename should be one of the following:
            single, double - carl
        }
        typname := lower(pbestrealtype^.def.gettypename);
        { converting a 64bit integer to a float requires a helper }
        if is_64bit(left.resulttype.def) then
          begin
            if is_signed(left.resulttype.def) then
              fname := 'fpc_int64_to_'+typname
            else
{$warning generic conversion from int to float does not support unsigned integers}
              fname := 'fpc_int64_to_'+typname;
            result := ccallnode.createintern(fname,ccallparanode.create(
              left,nil));
            left:=nil;
            firstpass(result);
            exit;
          end
        else
          { other integers are supposed to be 32 bit }
          begin
{$warning generic conversion from int to float does not support unsigned integers}
            if is_signed(left.resulttype.def) then
              fname := 'fpc_longint_to_'+typname
            else
              fname := 'fpc_longint_to_'+typname;
            result := ccallnode.createintern(fname,ccallparanode.create(
              left,nil));
            left:=nil;
            firstpass(result);
            exit;
          end;
      end;


    function ttypeconvnode.first_real_to_real : tnode;
      begin
         first_real_to_real:=nil;
        { comp isn't a floating type }
         if registersfpu<1 then
           registersfpu:=1;
         expectloc:=LOC_FPUREGISTER;
      end;


    function ttypeconvnode.first_pointer_to_array : tnode;

      begin
         first_pointer_to_array:=nil;
         if registersint<1 then
           registersint:=1;
         expectloc:=LOC_REFERENCE;
      end;


    function ttypeconvnode.first_cchar_to_pchar : tnode;

      begin
         first_cchar_to_pchar:=nil;
         internalerror(200104021);
      end;


    function ttypeconvnode.first_bool_to_int : tnode;

      begin
         first_bool_to_int:=nil;
         { byte(boolean) or word(wordbool) or longint(longbool) must
         be accepted for var parameters }
         if (nf_explicit in flags) and
            (left.resulttype.def.size=resulttype.def.size) and
            (left.expectloc in [LOC_REFERENCE,LOC_CREFERENCE,LOC_CREGISTER]) then
           exit;
         { when converting to 64bit, first convert to a 32bit int and then   }
         { convert to a 64bit int (only necessary for 32bit processors) (JM) }
         if resulttype.def.size > sizeof(aint) then
           begin
             result := ctypeconvnode.create_internal(left,u32inttype);
             result := ctypeconvnode.create(result,resulttype);
             left := nil;
             firstpass(result);
             exit;
           end;
         expectloc:=LOC_REGISTER;
         if registersint<1 then
           registersint:=1;
      end;


    function ttypeconvnode.first_int_to_bool : tnode;

      begin
         first_int_to_bool:=nil;
         { byte(boolean) or word(wordbool) or longint(longbool) must
         be accepted for var parameters }
         if (nf_explicit in flags) and
            (left.resulttype.def.size=resulttype.def.size) and
            (left.expectloc in [LOC_REFERENCE,LOC_CREFERENCE,LOC_CREGISTER]) then
           exit;
         expectloc:=LOC_REGISTER;
         { need if bool to bool !!
           not very nice !!
         insertypeconv(left,s32inttype);
         left.explizit:=true;
         firstpass(left);  }
         if registersint<1 then
           registersint:=1;
      end;


    function ttypeconvnode.first_bool_to_bool : tnode;
      begin
         first_bool_to_bool:=nil;
         expectloc:=LOC_REGISTER;
         if registersint<1 then
           registersint:=1;
      end;


    function ttypeconvnode.first_char_to_char : tnode;

      begin
         first_char_to_char:=first_int_to_int;
      end;


    function ttypeconvnode.first_proc_to_procvar : tnode;
      begin
         first_proc_to_procvar:=nil;
         if tabstractprocdef(resulttype.def).is_addressonly then
          begin
            registersint:=left.registersint;
            if registersint<1 then
              registersint:=1;
            expectloc:=LOC_REGISTER;
          end
         else
          begin
            if not(left.expectloc in [LOC_CREFERENCE,LOC_REFERENCE]) then
              CGMessage(parser_e_illegal_expression);
            registersint:=left.registersint;
            expectloc:=left.expectloc
          end
      end;


    function ttypeconvnode.first_load_smallset : tnode;

      var
        srsym: ttypesym;
        p: tcallparanode;

      begin
        if not searchsystype('FPC_SMALL_SET',srsym) then
          internalerror(200108313);
        p := ccallparanode.create(left,nil);
        { reused }
        left := nil;
        { convert parameter explicitely to fpc_small_set }
        p.left := ctypeconvnode.create_internal(p.left,srsym.restype);
        { create call, adjust resulttype }
        result :=
          ccallnode.createinternres('fpc_set_load_small',p,resulttype);
        firstpass(result);
      end;


    function ttypeconvnode.first_ansistring_to_pchar : tnode;

      begin
         first_ansistring_to_pchar:=nil;
         expectloc:=LOC_REGISTER;
         if registersint<1 then
           registersint:=1;
      end;


    function ttypeconvnode.first_arrayconstructor_to_set : tnode;
      begin
        first_arrayconstructor_to_set:=nil;
        internalerror(200104022);
      end;

    function ttypeconvnode.first_class_to_intf : tnode;

      begin
         first_class_to_intf:=nil;
         expectloc:=LOC_REGISTER;
         if registersint<1 then
           registersint:=1;
      end;

    function ttypeconvnode._first_int_to_int : tnode;
      begin
         result:=first_int_to_int;
      end;

    function ttypeconvnode._first_cstring_to_pchar : tnode;
      begin
         result:=first_cstring_to_pchar;
      end;

    function ttypeconvnode._first_string_to_chararray : tnode;
      begin
         result:=first_string_to_chararray;
      end;

    function ttypeconvnode._first_char_to_string : tnode;
      begin
         result:=first_char_to_string;
      end;

    function ttypeconvnode._first_nothing : tnode;
      begin
         result:=first_nothing;
      end;

    function ttypeconvnode._first_array_to_pointer : tnode;
      begin
         result:=first_array_to_pointer;
      end;

    function ttypeconvnode._first_int_to_real : tnode;
      begin
         result:=first_int_to_real;
      end;

    function ttypeconvnode._first_real_to_real : tnode;
      begin
         result:=first_real_to_real;
      end;

    function ttypeconvnode._first_pointer_to_array : tnode;
      begin
         result:=first_pointer_to_array;
      end;

    function ttypeconvnode._first_cchar_to_pchar : tnode;
      begin
         result:=first_cchar_to_pchar;
      end;

    function ttypeconvnode._first_bool_to_int : tnode;
      begin
         result:=first_bool_to_int;
      end;

    function ttypeconvnode._first_int_to_bool : tnode;
      begin
         result:=first_int_to_bool;
      end;

    function ttypeconvnode._first_bool_to_bool : tnode;
      begin
         result:=first_bool_to_bool;
      end;

    function ttypeconvnode._first_proc_to_procvar : tnode;
      begin
         result:=first_proc_to_procvar;
      end;

    function ttypeconvnode._first_load_smallset : tnode;
      begin
         result:=first_load_smallset;
      end;

    function ttypeconvnode._first_cord_to_pointer : tnode;
      begin
         result:=first_cord_to_pointer;
      end;

    function ttypeconvnode._first_ansistring_to_pchar : tnode;
      begin
         result:=first_ansistring_to_pchar;
      end;

    function ttypeconvnode._first_arrayconstructor_to_set : tnode;
      begin
         result:=first_arrayconstructor_to_set;
      end;

    function ttypeconvnode._first_class_to_intf : tnode;
      begin
         result:=first_class_to_intf;
      end;

    function ttypeconvnode._first_char_to_char : tnode;
      begin
         result:=first_char_to_char;
      end;

    function ttypeconvnode.first_call_helper(c : tconverttype) : tnode;

      const
         firstconvert : array[tconverttype] of pointer = (
           nil, { none }
           @ttypeconvnode._first_nothing, {equal}
           @ttypeconvnode._first_nothing, {not_possible}
           nil, { removed in resulttype_string_to_string }
           @ttypeconvnode._first_char_to_string,
           @ttypeconvnode._first_nothing, { char_2_chararray, needs nothing extra }
           nil, { removed in resulttype_chararray_to_string }
           @ttypeconvnode._first_cchar_to_pchar,
           @ttypeconvnode._first_cstring_to_pchar,
           @ttypeconvnode._first_ansistring_to_pchar,
           @ttypeconvnode._first_string_to_chararray,
           nil, { removed in resulttype_chararray_to_string }
           @ttypeconvnode._first_array_to_pointer,
           @ttypeconvnode._first_pointer_to_array,
           @ttypeconvnode._first_int_to_int,
           @ttypeconvnode._first_int_to_bool,
           @ttypeconvnode._first_bool_to_bool,
           @ttypeconvnode._first_bool_to_int,
           @ttypeconvnode._first_real_to_real,
           @ttypeconvnode._first_int_to_real,
           nil, { removed in resulttype_real_to_currency }
           @ttypeconvnode._first_proc_to_procvar,
           @ttypeconvnode._first_arrayconstructor_to_set,
           @ttypeconvnode._first_load_smallset,
           @ttypeconvnode._first_cord_to_pointer,
           @ttypeconvnode._first_nothing,
           @ttypeconvnode._first_nothing,
           @ttypeconvnode._first_class_to_intf,
           @ttypeconvnode._first_char_to_char,
           @ttypeconvnode._first_nothing,
           @ttypeconvnode._first_nothing,
           nil,
           nil,
           nil,
           nil,
           nil
         );
      type
         tprocedureofobject = function : tnode of object;

      var
         r : packed record
                proc : pointer;
                obj : pointer;
             end;

      begin
         { this is a little bit dirty but it works }
         { and should be quite portable too        }
         r.proc:=firstconvert[c];
         r.obj:=self;
         if not assigned(r.proc) then
           internalerror(200312081);
         first_call_helper:=tprocedureofobject(r){$ifdef FPC}(){$endif FPC}
      end;


    function ttypeconvnode.pass_1 : tnode;
      begin
        result:=nil;
        firstpass(left);
        if codegenerror then
         exit;

        { load the value_str from the left part }
        registersint:=left.registersint;
        registersfpu:=left.registersfpu;
{$ifdef SUPPORT_MMX}
        registersmmx:=left.registersmmx;
{$endif}
        expectloc:=left.expectloc;

        result:=first_call_helper(convtype);
      end;


    function ttypeconvnode.assign_allowed:boolean;
      begin
        result:=(convtype=tc_equal) or
                { typecasting from void is always allowed }
                is_void(left.resulttype.def) or
                (left.resulttype.def.deftype=formaldef) or
                { int 2 int with same size reuses same location, or for
                  tp7 mode also allow size < orignal size }
                (
                 (convtype=tc_int_2_int) and
                 (
                  (resulttype.def.size=left.resulttype.def.size) or
                  ((m_tp7 in aktmodeswitches) and
                   (resulttype.def.size<left.resulttype.def.size))
                 )
                ) or
                { int 2 bool/bool 2 int, explicit typecast, see also nx86cnv }
                ((convtype in [tc_int_2_bool,tc_bool_2_int]) and
                 (nf_explicit in flags) and
                 (resulttype.def.size=left.resulttype.def.size));

        { When using only a part of the value it can't be in a register since
          that will load the value in a new register first }
        if (resulttype.def.size<left.resulttype.def.size) then
          make_not_regable(left);
      end;


    function ttypeconvnode.docompare(p: tnode) : boolean;
      begin
        docompare :=
          inherited docompare(p) and
          (convtype = ttypeconvnode(p).convtype);
      end;


    procedure ttypeconvnode._second_int_to_int;
      begin
        second_int_to_int;
      end;


    procedure ttypeconvnode._second_string_to_string;
      begin
        second_string_to_string;
      end;


    procedure ttypeconvnode._second_cstring_to_pchar;
      begin
        second_cstring_to_pchar;
      end;


    procedure ttypeconvnode._second_string_to_chararray;
      begin
        second_string_to_chararray;
      end;


    procedure ttypeconvnode._second_array_to_pointer;
      begin
        second_array_to_pointer;
      end;


    procedure ttypeconvnode._second_pointer_to_array;
      begin
        second_pointer_to_array;
      end;


    procedure ttypeconvnode._second_chararray_to_string;
      begin
        second_chararray_to_string;
      end;


    procedure ttypeconvnode._second_char_to_string;
      begin
        second_char_to_string;
      end;


    procedure ttypeconvnode._second_int_to_real;
      begin
        second_int_to_real;
      end;


    procedure ttypeconvnode._second_real_to_real;
      begin
        second_real_to_real;
      end;


    procedure ttypeconvnode._second_cord_to_pointer;
      begin
        second_cord_to_pointer;
      end;


    procedure ttypeconvnode._second_proc_to_procvar;
      begin
        second_proc_to_procvar;
      end;


    procedure ttypeconvnode._second_bool_to_int;
      begin
        second_bool_to_int;
      end;


    procedure ttypeconvnode._second_int_to_bool;
      begin
        second_int_to_bool;
      end;


    procedure ttypeconvnode._second_bool_to_bool;
      begin
        second_bool_to_bool;
      end;

    procedure ttypeconvnode._second_load_smallset;
      begin
        second_load_smallset;
      end;


    procedure ttypeconvnode._second_ansistring_to_pchar;
      begin
        second_ansistring_to_pchar;
      end;


    procedure ttypeconvnode._second_class_to_intf;
      begin
        second_class_to_intf;
      end;


    procedure ttypeconvnode._second_char_to_char;
      begin
        second_char_to_char;
      end;


    procedure ttypeconvnode._second_nothing;
      begin
        second_nothing;
      end;


    procedure ttypeconvnode.second_call_helper(c : tconverttype);
      const
         secondconvert : array[tconverttype] of pointer = (
           @ttypeconvnode._second_nothing, {none}
           @ttypeconvnode._second_nothing, {equal}
           @ttypeconvnode._second_nothing, {not_possible}
           @ttypeconvnode._second_nothing, {second_string_to_string, handled in resulttype pass }
           @ttypeconvnode._second_char_to_string,
           @ttypeconvnode._second_nothing, {char_to_charray}
           @ttypeconvnode._second_nothing, { pchar_to_string, handled in resulttype pass }
           @ttypeconvnode._second_nothing, {cchar_to_pchar}
           @ttypeconvnode._second_cstring_to_pchar,
           @ttypeconvnode._second_ansistring_to_pchar,
           @ttypeconvnode._second_string_to_chararray,
           @ttypeconvnode._second_nothing, { chararray_to_string, handled in resulttype pass }
           @ttypeconvnode._second_array_to_pointer,
           @ttypeconvnode._second_pointer_to_array,
           @ttypeconvnode._second_int_to_int,
           @ttypeconvnode._second_int_to_bool,
           @ttypeconvnode._second_bool_to_bool,
           @ttypeconvnode._second_bool_to_int,
           @ttypeconvnode._second_real_to_real,
           @ttypeconvnode._second_int_to_real,
           @ttypeconvnode._second_nothing, { real_to_currency, handled in resulttype pass }
           @ttypeconvnode._second_proc_to_procvar,
           @ttypeconvnode._second_nothing, { arrayconstructor_to_set }
           @ttypeconvnode._second_nothing, { second_load_smallset, handled in first pass }
           @ttypeconvnode._second_cord_to_pointer,
           @ttypeconvnode._second_nothing, { interface 2 string }
           @ttypeconvnode._second_nothing, { interface 2 guid   }
           @ttypeconvnode._second_class_to_intf,
           @ttypeconvnode._second_char_to_char,
           @ttypeconvnode._second_nothing,  { normal_2_smallset }
           @ttypeconvnode._second_nothing,  { dynarray_2_openarray }
           @ttypeconvnode._second_nothing,  { pwchar_2_string }
           @ttypeconvnode._second_nothing,  { variant_2_dynarray }
           @ttypeconvnode._second_nothing,  { dynarray_2_variant}
           @ttypeconvnode._second_nothing,  { variant_2_enum }
           @ttypeconvnode._second_nothing   { enum_2_variant }
         );
      type
         tprocedureofobject = procedure of object;

      var
         r : packed record
                proc : pointer;
                obj : pointer;
             end;

      begin
         { this is a little bit dirty but it works }
         { and should be quite portable too        }
         r.proc:=secondconvert[c];
         r.obj:=self;
         tprocedureofobject(r)();
      end;


{*****************************************************************************
                                TISNODE
*****************************************************************************}

    constructor tisnode.create(l,r : tnode);

      begin
         inherited create(isn,l,r);
      end;


    function tisnode.det_resulttype:tnode;
      var
        paras: tcallparanode;
      begin
         result:=nil;
         resulttypepass(left);
         resulttypepass(right);

         set_varstate(left,vs_used,true);
         set_varstate(right,vs_used,true);

         if codegenerror then
           exit;

         if (right.resulttype.def.deftype=classrefdef) then
          begin
            { left must be a class }
            if is_class(left.resulttype.def) then
             begin
               { the operands must be related }
               if (not(tobjectdef(left.resulttype.def).is_related(
                  tobjectdef(tclassrefdef(right.resulttype.def).pointertype.def)))) and
                  (not(tobjectdef(tclassrefdef(right.resulttype.def).pointertype.def).is_related(
                  tobjectdef(left.resulttype.def)))) then
                 CGMessage2(type_e_classes_not_related,left.resulttype.def.typename,
                            tclassrefdef(right.resulttype.def).pointertype.def.typename);
             end
            else
             CGMessage1(type_e_class_type_expected,left.resulttype.def.typename);

            { call fpc_do_is helper }
            paras := ccallparanode.create(
                         left,
                     ccallparanode.create(
                         right,nil));
            result := ccallnode.createintern('fpc_do_is',paras);
            left := nil;
            right := nil;
          end
         else if is_interface(right.resulttype.def) then
          begin
            { left is a class }
            if is_class(left.resulttype.def) then
             begin
               { the operands must be related }
               if not(assigned(tobjectdef(left.resulttype.def).implementedinterfaces) and
                      (tobjectdef(left.resulttype.def).implementedinterfaces.searchintf(right.resulttype.def)<>-1)) then
                 CGMessage2(type_e_classes_not_related,
                    FullTypeName(left.resulttype.def,right.resulttype.def),
                    FullTypeName(right.resulttype.def,left.resulttype.def))
             end
            { left is an interface }
            else if is_interface(left.resulttype.def) then
             begin
               { the operands must be related }
               if (not(tobjectdef(left.resulttype.def).is_related(tobjectdef(right.resulttype.def)))) and
                  (not(tobjectdef(right.resulttype.def).is_related(tobjectdef(left.resulttype.def)))) then
                 CGMessage2(type_e_classes_not_related,
                    FullTypeName(left.resulttype.def,right.resulttype.def),
                    FullTypeName(right.resulttype.def,left.resulttype.def));
             end
            else
             CGMessage1(type_e_class_type_expected,left.resulttype.def.typename);
            { call fpc_do_is helper }
            paras := ccallparanode.create(
                         left,
                     ccallparanode.create(
                         right,nil));
            result := ccallnode.createintern('fpc_do_is',paras);
            left := nil;
            right := nil;
          end
         else
          CGMessage1(type_e_class_or_interface_type_expected,right.resulttype.def.typename);

         resulttype:=booltype;
      end;


    function tisnode.pass_1 : tnode;
      begin
        internalerror(200204254);
        result:=nil;
      end;

    { dummy pass_2, it will never be called, but we need one since }
    { you can't instantiate an abstract class                      }
    procedure tisnode.pass_2;
      begin
      end;


{*****************************************************************************
                                TASNODE
*****************************************************************************}

    constructor tasnode.create(l,r : tnode);

      begin
         inherited create(asn,l,r);
         call := nil;
      end;


    destructor tasnode.destroy;

      begin
        call.free;
        inherited destroy;
      end;


    function tasnode.det_resulttype:tnode;
      var
        hp : tnode;
      begin
         result:=nil;
         resulttypepass(right);
         resulttypepass(left);

         set_varstate(right,vs_used,true);
         set_varstate(left,vs_used,true);

         if codegenerror then
           exit;

         if (right.resulttype.def.deftype=classrefdef) then
          begin
            { left must be a class }
            if is_class(left.resulttype.def) then
             begin
               { the operands must be related }
               if (not(tobjectdef(left.resulttype.def).is_related(
                  tobjectdef(tclassrefdef(right.resulttype.def).pointertype.def)))) and
                  (not(tobjectdef(tclassrefdef(right.resulttype.def).pointertype.def).is_related(
                  tobjectdef(left.resulttype.def)))) then
                 CGMessage2(type_e_classes_not_related,
                    FullTypeName(left.resulttype.def,tclassrefdef(right.resulttype.def).pointertype.def),
                    FullTypeName(tclassrefdef(right.resulttype.def).pointertype.def,left.resulttype.def));
             end
            else
             CGMessage1(type_e_class_type_expected,left.resulttype.def.typename);
            resulttype:=tclassrefdef(right.resulttype.def).pointertype;
          end
         else if is_interface(right.resulttype.def) then
          begin
            { left is a class }
            if not(is_class(left.resulttype.def) or
                   is_interface(left.resulttype.def)) then
              CGMessage1(type_e_class_type_expected,left.resulttype.def.typename);

            resulttype:=right.resulttype;

            { load the GUID of the interface }
            if (right.nodetype=typen) then
             begin
               if assigned(tobjectdef(right.resulttype.def).iidguid) then
                 begin
                   hp:=cguidconstnode.create(tobjectdef(right.resulttype.def).iidguid^);
                   right.free;
                   right:=hp;
                 end
               else
                 internalerror(200206282);
               resulttypepass(right);
             end;
          end
         else
          CGMessage1(type_e_class_or_interface_type_expected,right.resulttype.def.typename);
      end;


    function tasnode.getcopy: tnode;

      begin
        result := inherited getcopy;
        if assigned(call) then
          tasnode(result).call := call.getcopy
        else
          tasnode(result).call := nil;
      end;


    function tasnode.pass_1 : tnode;

      var
        procname: string;
      begin
        result:=nil;
        if not assigned(call) then
          begin
            if is_class(left.resulttype.def) and
               (right.resulttype.def.deftype=classrefdef) then
              call := ccallnode.createinternres('fpc_do_as',
                ccallparanode.create(left,ccallparanode.create(right,nil)),
                resulttype)
            else
              begin
                if is_class(left.resulttype.def) then
                  procname := 'fpc_class_as_intf'
                else
                  procname := 'fpc_intf_as';
                call := ccallnode.createinternres(procname,
                   ccallparanode.create(right,ccallparanode.create(left,nil)),
                   resulttype);
              end;
            left := nil;
            right := nil;
            firstpass(call);
            if codegenerror then
              exit;
           expectloc:=call.expectloc;
           registersint:=call.registersint;
           registersfpu:=call.registersfpu;
{$ifdef SUPPORT_MMX}
           registersmmx:=call.registersmmx;
{$endif SUPPORT_MMX}
         end;
      end;


begin
   ctypeconvnode:=ttypeconvnode;
   casnode:=tasnode;
   cisnode:=tisnode;
end.
{
  $Log$
  Revision 1.169  2004-12-27 16:54:29  peter
    * also don't call procvar when converting to procvar

  Revision 1.168  2004/12/26 16:22:01  peter
    * fix lineinfo for with blocks

  Revision 1.167  2004/12/07 16:11:52  peter
    * set vo_explicit_paraloc flag

  Revision 1.166  2004/12/05 12:28:11  peter
    * procvar handling for tp procvar mode fixed
    * proc to procvar moved from addrnode to typeconvnode
    * inlininginfo is now allocated only for inline routines that
      can be inlined, introduced a new flag po_has_inlining_info

  Revision 1.165  2004/12/05 12:15:11  florian
    * fixed compiler side of variant <-> dyn. array conversion

  Revision 1.164  2004/11/26 22:34:28  peter
    * internal flag for compare_defs_ext

  Revision 1.163  2004/11/21 15:35:23  peter
    * float routines all use internproc and compilerproc helpers

  Revision 1.162  2004/11/02 20:15:53  jonas
    * copy totype field in ttypeconvnode.getcopy()

  Revision 1.161  2004/11/02 12:55:16  peter
    * nf_internal flag for internal inserted typeconvs. This will
      supress the generation of warning/hints

  Revision 1.160  2004/11/01 23:30:11  peter
    * support > 32bit accesses for x86_64
    * rewrote array size checking to support 64bit

  Revision 1.159  2004/11/01 17:15:47  peter
    * no checkpointer code for dynarr to openarr

  Revision 1.158  2004/11/01 15:31:58  peter
    * -Or fix for absolute

  Revision 1.157  2004/10/24 11:44:28  peter
    * small regvar fixes
    * loadref parameter removed from concatcopy,incrrefcount,etc

  Revision 1.156  2004/10/15 09:14:17  mazen
  - remove $IFDEF DELPHI and related code
  - remove $IFDEF FPCPROCVAR and related code

  Revision 1.155  2004/10/12 14:33:41  peter
    * give error when converting class to interface are not related

  Revision 1.154  2004/10/11 15:48:15  peter
    * small regvar for para fixes
    * function tvarsym.is_regvar added
    * tvarsym.getvaluesize removed, use getsize instead

  Revision 1.153  2004/09/26 17:45:30  peter
    * simple regvar support, not yet finished

  Revision 1.152  2004/08/08 16:00:56  florian
    * constant floating point assignments etc. are now overflow checked
      if Q+ or R+ is turned on

  Revision 1.151  2004/06/29 20:57:50  peter
    * fix pchar:=char
    * fix longint(smallset)

  Revision 1.150  2004/06/23 16:22:45  peter
    * include unit name in error messages when types are the same

  Revision 1.149  2004/06/20 08:55:29  florian
    * logs truncated

  Revision 1.148  2004/06/16 20:07:08  florian
    * dwarf branch merged

  Revision 1.147  2004/05/23 18:28:41  peter
    * methodpointer is loaded into a temp when it was a calln

  Revision 1.146  2004/05/23 15:03:40  peter
    * some typeconvs don't allow assignment or passing to var para

  Revision 1.145  2004/05/23 14:14:18  florian
    + added set of widechar support (limited to 256 chars, is delphi compatible)

  Revision 1.144  2004/04/29 19:56:37  daniel
    * Prepare compiler infrastructure for multiple ansistring types

}
