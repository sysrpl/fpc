{
    $Id$
    Copyright (c) 2000 by Florian Klaempfl

    Type checking and register allocation for constants

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
unit ncon;

{$i defines.inc}

interface

    uses
      globtype,widestr,
      node,
      aasm,cpuinfo,globals,
      symconst,symtype,symdef,symsym;

    type
       trealconstnode = class(tnode)
          restype : ttype;
          value_real : bestreal;
          lab_real : tasmlabel;
          constructor create(v : bestreal;const t:ttype);virtual;
          function getcopy : tnode;override;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          function docompare(p: tnode) : boolean; override;
       end;
       trealconstnodeclass = class of trealconstnode;

       tordconstnode = class(tnode)
          restype : ttype;
          value : TConstExprInt;
          constructor create(v : tconstexprint;const t:ttype);virtual;
          function getcopy : tnode;override;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          function docompare(p: tnode) : boolean; override;
       end;
       tordconstnodeclass = class of tordconstnode;

       tpointerconstnode = class(tnode)
          restype : ttype;
          value   : TConstPtrUInt;
          constructor create(v : TConstPtrUInt;const t:ttype);virtual;
          function getcopy : tnode;override;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          function docompare(p: tnode) : boolean; override;
       end;
       tpointerconstnodeclass = class of tpointerconstnode;

       tstringconstnode = class(tnode)
          value_str : pchar;
          len : longint;
          lab_str : tasmlabel;
          st_type : tstringtype;
          constructor createstr(const s : string;st:tstringtype);virtual;
          constructor createpchar(s : pchar;l : longint);virtual;
          constructor createwstr(w : pcompilerwidestring);virtual;
          destructor destroy;override;
          function getcopy : tnode;override;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          function getpcharcopy : pchar;
          function docompare(p: tnode) : boolean; override;
       end;
       tstringconstnodeclass = class of tstringconstnode;

       tsetconstnode = class(tunarynode)
          restype : ttype;
          value_set : pconstset;
          lab_set : tasmlabel;
          constructor create(s : pconstset;const t:ttype);virtual;
          destructor destroy;override;
          function getcopy : tnode;override;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          function docompare(p: tnode) : boolean; override;
       end;
       tsetconstnodeclass = class of tsetconstnode;

       tnilnode = class(tnode)
          constructor create;virtual;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
       end;
       tnilnodeclass = class of tnilnode;

       tguidconstnode = class(tnode)
          value : tguid;
          constructor create(const g:tguid);virtual;
          function getcopy : tnode;override;
          function pass_1 : tnode;override;
          function det_resulttype:tnode;override;
          function docompare(p: tnode) : boolean; override;
       end;
       tguidconstnodeclass = class of tguidconstnode;

    var
       crealconstnode : trealconstnodeclass;
       cordconstnode : tordconstnodeclass;
       cpointerconstnode : tpointerconstnodeclass;
       cstringconstnode : tstringconstnodeclass;
       csetconstnode : tsetconstnodeclass;
       cguidconstnode : tguidconstnodeclass;
       cnilnode : tnilnodeclass;

    function genintconstnode(v : TConstExprInt) : tordconstnode;
    function genenumnode(v : tenumsym) : tordconstnode;

    { some helper routines }
{$ifdef INT64FUNCRESOK}
    function get_ordinal_value(p : tnode) : TConstExprInt;
{$else INT64FUNCRESOK}
    function get_ordinal_value(p : tnode) : longint;
{$endif INT64FUNCRESOK}
    function is_constnode(p : tnode) : boolean;
    function is_constintnode(p : tnode) : boolean;
    function is_constcharnode(p : tnode) : boolean;
    function is_constrealnode(p : tnode) : boolean;
    function is_constboolnode(p : tnode) : boolean;
    function is_constresourcestringnode(p : tnode) : boolean;
    function is_constwidecharnode(p : tnode) : boolean;
    function str_length(p : tnode) : longint;
    function is_emptyset(p : tnode):boolean;
    function genconstsymtree(p : tconstsym) : tnode;

implementation

    uses
      cutils,verbose,systems,
      types,cpubase,nld;

    function genintconstnode(v : TConstExprInt) : tordconstnode;

      var
         i,i2 : TConstExprInt;

      begin
         { we need to bootstrap this code, so it's a little bit messy }
         i:=2147483647;
         { maxcardinal }
         i2 := i+i+1;
         if (v<=i) and (v>=-i-1) then
           genintconstnode:=cordconstnode.create(v,s32bittype)
         else if (v > i) and (v <= i2) then
           genintconstnode:=cordconstnode.create(v,u32bittype)
         else
           genintconstnode:=cordconstnode.create(v,cs64bittype);
      end;


    function genenumnode(v : tenumsym) : tordconstnode;
      var
        htype : ttype;
      begin
         htype.setdef(v.definition);
         genenumnode:=cordconstnode.create(v.value,htype);
      end;


{$ifdef INT64FUNCRESOK}
    function get_ordinal_value(p : tnode) : TConstExprInt;
{$else INT64FUNCRESOK}
    function get_ordinal_value(p : tnode) : longint;
{$endif INT64FUNCRESOK}
      begin
         if p.nodetype=ordconstn then
           get_ordinal_value:=tordconstnode(p).value
         else
           begin
             Message(type_e_ordinal_expr_expected);
             get_ordinal_value:=0;
           end;
      end;


    function is_constnode(p : tnode) : boolean;
      begin
        is_constnode:=(p.nodetype in [ordconstn,realconstn,stringconstn,setconstn,guidconstn]);
      end;


    function is_constintnode(p : tnode) : boolean;
      begin
         is_constintnode:=(p.nodetype=ordconstn) and is_integer(p.resulttype.def);
      end;


    function is_constcharnode(p : tnode) : boolean;

      begin
         is_constcharnode:=(p.nodetype=ordconstn) and is_char(p.resulttype.def);
      end;


    function is_constwidecharnode(p : tnode) : boolean;

      begin
         is_constwidecharnode:=(p.nodetype=ordconstn) and is_widechar(p.resulttype.def);
      end;


    function is_constrealnode(p : tnode) : boolean;

      begin
         is_constrealnode:=(p.nodetype=realconstn);
      end;


    function is_constboolnode(p : tnode) : boolean;

      begin
         is_constboolnode:=(p.nodetype=ordconstn) and is_boolean(p.resulttype.def);
      end;


    function is_constresourcestringnode(p : tnode) : boolean;
      begin
        is_constresourcestringnode:=(p.nodetype=loadn) and
          (tloadnode(p).symtableentry.typ=constsym) and
          (tconstsym(tloadnode(p).symtableentry).consttyp=constresourcestring);
      end;


    function str_length(p : tnode) : longint;

      begin
         str_length:=tstringconstnode(p).len;
      end;


    function is_emptyset(p : tnode):boolean;

      var
        i : longint;
      begin
        i:=0;
        if p.nodetype=setconstn then
         begin
           while (i<32) and (tsetconstnode(p).value_set^[i]=0) do
            inc(i);
         end;
        is_emptyset:=(i=32);
      end;


    function genconstsymtree(p : tconstsym) : tnode;
      var
        p1  : tnode;
        len : longint;
        pc  : pchar;
      begin
        p1:=nil;
        case p.consttyp of
          constint :
            p1:=genintconstnode(p.valueord);
          conststring :
            begin
              len:=p.len;
              if not(cs_ansistrings in aktlocalswitches) and (len>255) then
               len:=255;
              getmem(pc,len+1);
              move(pchar(p.valueptr)^,pc^,len);
              pc[len]:=#0;
              p1:=cstringconstnode.createpchar(pc,len);
            end;
          constchar :
            p1:=cordconstnode.create(p.valueord,cchartype);
          constreal :
            p1:=crealconstnode.create(pbestreal(p.valueptr)^,pbestrealtype^);
          constbool :
            p1:=cordconstnode.create(p.valueord,booltype);
          constset :
            p1:=csetconstnode.create(pconstset(p.valueptr),p.consttype);
          constord :
            p1:=cordconstnode.create(p.valueord,p.consttype);
          constpointer :
            p1:=cpointerconstnode.create(p.valueordptr,p.consttype);
          constnil :
            p1:=cnilnode.create;
          constresourcestring:
            begin
              p1:=cloadnode.create(tvarsym(p),tvarsym(p).owner);
              p1.resulttype:=cansistringtype;
            end;
        end;
        genconstsymtree:=p1;
      end;

{*****************************************************************************
                             TREALCONSTNODE
*****************************************************************************}

    { generic code     }
    { overridden by:   }
    {   i386           }
    constructor trealconstnode.create(v : bestreal;const t:ttype);
      begin
         inherited create(realconstn);
         restype:=t;
         value_real:=v;
         lab_real:=nil;
      end;

    function trealconstnode.getcopy : tnode;

      var
         n : trealconstnode;

      begin
         n:=trealconstnode(inherited getcopy);
         n.value_real:=value_real;
         n.lab_real:=lab_real;
         getcopy:=n;
      end;

    function trealconstnode.det_resulttype:tnode;
      begin
        result:=nil;
        resulttype:=restype;
      end;

    function trealconstnode.pass_1 : tnode;
      begin
         result:=nil;
         location.loc:=LOC_CREFERENCE;
         { needs to be loaded into an FPU register }
         registersfpu:=1;
      end;

    function trealconstnode.docompare(p: tnode): boolean;
      begin
        docompare :=
          inherited docompare(p) and
          (value_real = trealconstnode(p).value_real);
      end;

{*****************************************************************************
                              TORDCONSTNODE
*****************************************************************************}

    constructor tordconstnode.create(v : tconstexprint;const t:ttype);

      begin
         inherited create(ordconstn);
         value:=v;
         restype:=t;
      end;

    function tordconstnode.getcopy : tnode;

      var
         n : tordconstnode;

      begin
         n:=tordconstnode(inherited getcopy);
         n.value:=value;
         n.restype := restype;
         getcopy:=n;
      end;

    function tordconstnode.det_resulttype:tnode;
      begin
        result:=nil;
        resulttype:=restype;
        testrange(resulttype.def,value,false);
      end;

    function tordconstnode.pass_1 : tnode;
      begin
         result:=nil;
         if is_64bitint(resulttype.def) then
          location.loc:=LOC_CREFERENCE
         else
          location.loc:=LOC_CONSTANT;
      end;

    function tordconstnode.docompare(p: tnode): boolean;
      begin
        docompare :=
          inherited docompare(p) and
          (value = tordconstnode(p).value);
      end;

{*****************************************************************************
                            TPOINTERCONSTNODE
*****************************************************************************}

    constructor tpointerconstnode.create(v : TConstPtrUInt;const t:ttype);

      begin
         inherited create(pointerconstn);
         value:=v;
         restype:=t;
      end;

    function tpointerconstnode.getcopy : tnode;

      var
         n : tpointerconstnode;

      begin
         n:=tpointerconstnode(inherited getcopy);
         n.value:=value;
         n.restype := restype;
         getcopy:=n;
      end;

    function tpointerconstnode.det_resulttype:tnode;
      begin
        result:=nil;
        resulttype:=restype;
      end;

    function tpointerconstnode.pass_1 : tnode;
      begin
         result:=nil;
         location.loc:=LOC_CONSTANT;
      end;

    function tpointerconstnode.docompare(p: tnode): boolean;
      begin
        docompare :=
          inherited docompare(p) and
          (value = tpointerconstnode(p).value);
      end;


{*****************************************************************************
                             TSTRINGCONSTNODE
*****************************************************************************}

    constructor tstringconstnode.createstr(const s : string;st:tstringtype);

      var
         l : longint;

      begin
         inherited create(stringconstn);
         l:=length(s);
         len:=l;
         { stringdup write even past a #0 }
         getmem(value_str,l+1);
         move(s[1],value_str^,l);
         value_str[l]:=#0;
         lab_str:=nil;
         if st=st_default then
          begin
            if cs_ansistrings in aktlocalswitches then
              st_type:=st_ansistring
            else
              st_type:=st_shortstring;
          end
         else
          st_type:=st;
      end;

    constructor tstringconstnode.createwstr(w : pcompilerwidestring);

      begin
         inherited create(stringconstn);
         len:=getlengthwidestring(w);
         initwidestring(pcompilerwidestring(value_str));
         copywidestring(w,pcompilerwidestring(value_str));
         lab_str:=nil;
         st_type:=st_widestring;
      end;

    constructor tstringconstnode.createpchar(s : pchar;l : longint);

      begin
         inherited create(stringconstn);
         len:=l;
         value_str:=s;
         if (cs_ansistrings in aktlocalswitches) or
            (len>255) then
          st_type:=st_ansistring
         else
          st_type:=st_shortstring;
         lab_str:=nil;
      end;

    destructor tstringconstnode.destroy;
      begin
        if st_type=st_widestring then
         donewidestring(pcompilerwidestring(value_str))
        else
         ansistringdispose(value_str,len);
        inherited destroy;
      end;

    function tstringconstnode.getcopy : tnode;

      var
         n : tstringconstnode;

      begin
         n:=tstringconstnode(inherited getcopy);
         n.st_type:=st_type;
         n.len:=len;
         n.lab_str:=lab_str;
         if st_type=st_widestring then
           begin
             initwidestring(pcompilerwidestring(n.value_str));
             copywidestring(pcompilerwidestring(value_str),pcompilerwidestring(n.value_str));
           end
         else
           n.value_str:=getpcharcopy;
         getcopy:=n;
      end;

    function tstringconstnode.det_resulttype:tnode;
      begin
        result:=nil;
        case st_type of
          st_shortstring :
            resulttype:=cshortstringtype;
          st_ansistring :
            resulttype:=cansistringtype;
          st_widestring :
            resulttype:=cwidestringtype;
          st_longstring :
            resulttype:=clongstringtype;
        end;
      end;

    function tstringconstnode.pass_1 : tnode;
      begin
        result:=nil;
        location.loc:=LOC_CREFERENCE;
      end;

    function tstringconstnode.getpcharcopy : pchar;
      var
         pc : pchar;
      begin
         pc:=nil;
         getmem(pc,len+1);
         if pc=nil then
           Message(general_f_no_memory_left);
         move(value_str^,pc^,len+1);
         getpcharcopy:=pc;
      end;

    function tstringconstnode.docompare(p: tnode): boolean;
      begin
        docompare :=
          inherited docompare(p) and
          (len = tstringconstnode(p).len) and
          { Don't compare the pchars, since they may contain null chars }
          { Since all equal constant strings are replaced by the same   }
          { label, the following compare should be enough (JM)          }
          (lab_str = tstringconstnode(p).lab_str);
      end;

{*****************************************************************************
                             TSETCONSTNODE
*****************************************************************************}

    constructor tsetconstnode.create(s : pconstset;const t:ttype);

      begin
         inherited create(setconstn,nil);
         restype:=t;
         if assigned(s) then
           begin
              new(value_set);
              value_set^:=s^;
           end
         else
           value_set:=nil;
      end;

    destructor tsetconstnode.destroy;
      begin
        if assigned(value_set) then
         dispose(value_set);
        inherited destroy;
      end;

    function tsetconstnode.getcopy : tnode;

      var
         n : tsetconstnode;

      begin
         n:=tsetconstnode(inherited getcopy);
         if assigned(value_set) then
           begin
              new(n.value_set);
              n.value_set^:=value_set^
           end
         else
           n.value_set:=nil;
         n.restype := restype;
         n.lab_set:=lab_set;
         getcopy:=n;
      end;

    function tsetconstnode.det_resulttype:tnode;
      begin
        result:=nil;
        resulttype:=restype;
      end;

    function tsetconstnode.pass_1 : tnode;
      begin
         result:=nil;
         if tsetdef(resulttype.def).settype=smallset then
          location.loc:=LOC_CONSTANT
         else
          location.loc:=LOC_CREFERENCE;
      end;

    function tsetconstnode.docompare(p: tnode): boolean;
      var
        i: 0..31;
      begin
        if inherited docompare(p) then
          begin
            for i := 0 to 31 do
              if (value_set^[i] <> tsetconstnode(p).value_set^[i]) then
                begin
                  docompare := false;
                  exit
                end;
            docompare := true;
          end
        else
          docompare := false;
      end;

{*****************************************************************************
                               TNILNODE
*****************************************************************************}

    constructor tnilnode.create;

      begin
        inherited create(niln);
      end;

    function tnilnode.det_resulttype:tnode;
      begin
        result:=nil;
        resulttype:=voidpointertype;
      end;

    function tnilnode.pass_1 : tnode;
      begin
        result:=nil;
        location.loc:=LOC_CONSTANT;
      end;

{*****************************************************************************
                            TGUIDCONSTNODE
*****************************************************************************}

    constructor tguidconstnode.create(const g:tguid);

      begin
         inherited create(guidconstn);
         value:=g;
      end;

    function tguidconstnode.getcopy : tnode;

      var
         n : tguidconstnode;

      begin
         n:=tguidconstnode(inherited getcopy);
         n.value:=value;
         getcopy:=n;
      end;

    function tguidconstnode.det_resulttype:tnode;
      begin
        result:=nil;
        resulttype.setdef(rec_tguid);
      end;

    function tguidconstnode.pass_1 : tnode;
      begin
         result:=nil;
         location.loc:=LOC_CREFERENCE;
      end;

    function tguidconstnode.docompare(p: tnode): boolean;
      begin
        docompare :=
          inherited docompare(p) and
          (guid2string(value) = guid2string(tguidconstnode(p).value));
      end;


begin
   crealconstnode:=trealconstnode;
   cordconstnode:=tordconstnode;
   cpointerconstnode:=tpointerconstnode;
   cstringconstnode:=tstringconstnode;
   csetconstnode:=tsetconstnode;
   cnilnode:=tnilnode;
   cguidconstnode:=tguidconstnode;
end.
{
  $Log$
  Revision 1.28  2002-04-07 13:25:20  carl
  + change unit use

  Revision 1.27  2002/04/04 19:05:58  peter
    * removed unused units
    * use tlocation.size in cg.a_*loc*() routines

  Revision 1.26  2002/04/02 17:11:29  peter
    * tlocation,treference update
    * LOC_CONSTANT added for better constant handling
    * secondadd splitted in multiple routines
    * location_force_reg added for loading a location to a register
      of a specified size
    * secondassignment parses now first the right and then the left node
      (this is compatible with Kylix). This saves a lot of push/pop especially
      with string operations
    * adapted some routines to use the new cg methods

  Revision 1.25  2002/03/04 19:10:11  peter
    * removed compiler warnings

  Revision 1.24  2001/10/20 19:28:38  peter
    * interface 2 guid support
    * guid constants support

  Revision 1.23  2001/09/17 21:29:12  peter
    * merged netbsd, fpu-overflow from fixes branch

  Revision 1.22  2001/09/02 21:12:06  peter
    * move class of definitions into type section for delphi

  Revision 1.21  2001/08/26 13:36:40  florian
    * some cg reorganisation
    * some PPC updates

  Revision 1.20  2001/08/06 10:18:39  jonas
    * restype wasn't copied for some constant nodetypes in getcopy

  Revision 1.19  2001/07/08 21:00:15  peter
    * various widestring updates, it works now mostly without charset
      mapping supported

  Revision 1.18  2001/05/08 21:06:30  florian
    * some more support for widechars commited especially
      regarding type casting and constants

  Revision 1.17  2001/04/13 01:22:09  peter
    * symtable change to classes
    * range check generation and errors fixed, make cycle DEBUG=1 works
    * memory leaks fixed

  Revision 1.16  2001/04/02 21:20:30  peter
    * resulttype rewrite

  Revision 1.15  2000/12/31 11:14:10  jonas
    + implemented/fixed docompare() mathods for all nodes (not tested)
    + nopt.pas, nadd.pas, i386/n386opt.pas: optimized nodes for adding strings
      and constant strings/chars together
    * n386add.pas: don't copy temp strings (of size 256) to another temp string
      when adding

  Revision 1.14  2000/12/16 15:58:48  jonas
    * genintconstnode now returns cardinals instead of int64 constants if possible

  Revision 1.13  2000/12/15 13:26:01  jonas
    * only return int64's from functions if it int64funcresok is defined
    + added int64funcresok define to options.pas

  Revision 1.12  2000/12/07 17:19:42  jonas
    * new constant handling: from now on, hex constants >$7fffffff are
      parsed as unsigned constants (otherwise, $80000000 got sign extended
      and became $ffffffff80000000), all constants in the longint range
      become longints, all constants >$7fffffff and <=cardinal($ffffffff)
      are cardinals and the rest are int64's.
    * added lots of longint typecast to prevent range check errors in the
      compiler and rtl
    * type casts of symbolic ordinal constants are now preserved
    * fixed bug where the original resulttype.def wasn't restored correctly
      after doing a 64bit rangecheck

  Revision 1.11  2000/11/29 00:30:32  florian
    * unused units removed from uses clause
    * some changes for widestrings

  Revision 1.10  2000/10/31 22:02:48  peter
    * symtable splitted, no real code changes

  Revision 1.9  2000/10/14 21:52:55  peter
    * fixed memory leaks

  Revision 1.8  2000/10/14 10:14:50  peter
    * moehrendorf oct 2000 rewrite

  Revision 1.7  2000/09/28 19:49:52  florian
  *** empty log message ***

  Revision 1.6  2000/09/27 20:25:44  florian
    * more stuff fixed

  Revision 1.5  2000/09/27 18:14:31  florian
    * fixed a lot of syntax errors in the n*.pas stuff

  Revision 1.4  2000/09/26 14:59:34  florian
    * more conversion work done

  Revision 1.3  2000/09/24 21:15:34  florian
    * some errors fix to get more stuff compilable

  Revision 1.2  2000/09/24 15:06:19  peter
    * use defines.inc

  Revision 1.1  2000/09/22 21:44:48  florian
    + initial revision

}
