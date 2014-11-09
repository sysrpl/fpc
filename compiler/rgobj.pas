{
    Copyright (c) 1998-2012 by the Free Pascal team

    This unit implements the base class for the register allocator

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

{$i fpcdefs.inc}

{ Allow duplicate allocations, can be used to get the .s file written }
{ $define ALLOWDUPREG}

unit rgobj;

  interface

    uses
      cutils, cpubase,
      aasmbase,aasmtai,aasmdata,aasmcpu,
      cclasses,globtype,cgbase,cgutils,
      cpuinfo
      ;

    type
      {
        The interference bitmap contains of 2 layers:
          layer 1 - 256*256 blocks with pointers to layer 2 blocks
          layer 2 - blocks of 32*256 (32 bytes = 256 bits)
      }
      Tinterferencebitmap2 = array[byte] of set of byte;
      Pinterferencebitmap2 = ^Tinterferencebitmap2;
      Tinterferencebitmap1 = array[byte] of Pinterferencebitmap2;
      pinterferencebitmap1 = ^tinterferencebitmap1;

      Tinterferencebitmap=class
      private
        maxx1,
        maxy1    : byte;
        fbitmap  : pinterferencebitmap1;
        function getbitmap(x,y:tsuperregister):boolean;
        procedure setbitmap(x,y:tsuperregister;b:boolean);
      public
        constructor create;
        destructor destroy;override;
        property bitmap[x,y:tsuperregister]:boolean read getbitmap write setbitmap;default;
      end;

      Tmovelistheader=record
        count,
        maxcount,
        sorted_until : cardinal;
      end;

      Tmovelist=record
        header : Tmovelistheader;
        data : array[tsuperregister] of Tlinkedlistitem;
      end;
      Pmovelist=^Tmovelist;

      {In the register allocator we keep track of move instructions.
       These instructions are moved between five linked lists. There
       is also a linked list per register to keep track about the moves
       it is associated with. Because we need to determine quickly in
       which of the five lists it is we add anu enumeradtion to each
       move instruction.}

      Tmoveset=(ms_coalesced_moves,ms_constrained_moves,ms_frozen_moves,
                ms_worklist_moves,ms_active_moves);
      Tmoveins=class(Tlinkedlistitem)
        moveset:Tmoveset;
        x,y:Tsuperregister;
      end;

      Treginfoflag=(ri_coalesced,ri_selected);
      Treginfoflagset=set of Treginfoflag;

      Treginfo=record
        live_start,
        live_end   : Tai;
        subreg   : tsubregister;
        alias    : Tsuperregister;
        { The register allocator assigns each register a colour }
        colour   : Tsuperregister;
        movelist : Pmovelist;
        adjlist  : Psuperregisterworklist;
        degree   : TSuperregister;
        flags    : Treginfoflagset;
        weight   : longint;
      end;
      Preginfo=^TReginfo;

      tspillreginfo = record
        { a single register may appear more than once in an instruction,
          but with different subregister types -> store all subregister types
          that occur, so we can add the necessary constraints for the inline
          register that will have to replace it }
        spillregconstraints : set of TSubRegister;
        orgreg : tsuperregister;
        tempreg : tregister;
        regread,regwritten, mustbespilled: boolean;
      end;
      tspillregsinfo = array[0..3] of tspillreginfo;

      Tspill_temp_list=array[tsuperregister] of Treference;

      {#------------------------------------------------------------------

      This class implements the default register allocator. It is used by the
      code generator to allocate and free registers which might be valid
      across nodes. It also contains utility routines related to registers.

      Some of the methods in this class should be overridden
      by cpu-specific implementations.

      --------------------------------------------------------------------}

       { trgobj }

       trgobj=class
        preserved_by_proc : tcpuregisterset;
        used_in_proc : tcpuregisterset;

        constructor create(Aregtype:Tregistertype;
                           Adefaultsub:Tsubregister;
                           const Ausable:array of tsuperregister;
                           Afirst_imaginary:Tsuperregister;
                           Apreserved_by_proc:Tcpuregisterset);
        destructor destroy;override;

        procedure define_class(asubclass:TSubRegister;const Aregs:array of TSuperRegister);
        procedure define_alias(aregister:TSuperRegister;const Aregs:array of TSuperRegister);

        { Allocate a register. An internalerror will be generated if there is
         no more free registers which can be allocated.}
        function getregister(list:TAsmList;subreg:Tsubregister):Tregister;virtual;
        { Get the register specified.}
        procedure getcpuregister(list:TAsmList;r:Tregister);virtual;
        procedure ungetcpuregister(list:TAsmList;r:Tregister);virtual;
        { Get multiple registers specified.}
        procedure alloccpuregisters(list:TAsmList;const r:Tcpuregisterset);virtual;
        { Free multiple registers specified.}
        procedure dealloccpuregisters(list:TAsmList;const r:Tcpuregisterset);virtual;
        function uses_registers:boolean;virtual;
        procedure add_reg_instruction(instr:Tai;r:tregister;aweight:longint);
        procedure add_move_instruction(instr:Taicpu);
        { Do the register allocation.}
        procedure do_register_allocation(list:TAsmList;headertai:tai);virtual;
        { Adds an interference edge.
          don't move this to the protected section, the arm cg requires to access this (FK) }
        procedure add_edge(u,v:Tsuperregister);
        { translates a single given imaginary register to it's real register }
        procedure translate_register(var reg : tregister);
      protected
        maxreginfo,
        maxreginfoinc,
        maxreg            : Tsuperregister;

        regtype           : Tregistertype;
        { default subregister used }
        defaultsub        : tsubregister;
        live_registers:Tsuperregisterworklist;
        { can be overridden to add cpu specific interferences }
        procedure add_cpu_interferences(p : tai);virtual;
        procedure add_constraints(reg:Tregister);virtual;
        procedure add_class_constraints(reg:Tregister);
        procedure add_alias_constraints(reg:Tregister);
        function  getregisterinline(list:TAsmList;const subregconstraints:Tsubregisterset):Tregister;
        procedure ungetregisterinline(list:TAsmList;r:Tregister);
        function  get_spill_subreg(r : tregister) : tsubregister;virtual;
        function  do_spill_replace(list:TAsmList;instr:taicpu;orgreg:tsuperregister;const spilltemp:treference):boolean;virtual;
        procedure do_spill_read(list:TAsmList;pos:tai;const spilltemp:treference;tempreg:tregister);virtual;
        procedure do_spill_written(list:TAsmList;pos:tai;const spilltemp:treference;tempreg:tregister);virtual;

        function instr_spill_register(list:TAsmList;
                                      instr:taicpu;
                                      const r:Tsuperregisterset;
                                      const spilltemplist:Tspill_temp_list): boolean;virtual;
        procedure insert_regalloc_info_all(list:TAsmList);
      private
        int_live_range_direction: TRADirection;
        { First imaginary register.}
        first_imaginary   : Tsuperregister;
        { Highest register allocated until now.}
        reginfo           : PReginfo;
        usable_registers_cnt : word;
        usable_registers  : array[0..maxcpuregister] of tsuperregister;
        usable_register_set : tcpuregisterset;

        alias_registers_cnt : word;
        alias_register_def  : array[0..maxcpuregister] of tsuperregister;
        alias_registers     : array[0..maxcpuregister] of tsuperregisterset;

        reg_class           : array[TSubRegister] of tsuperregisterset;

        ibitmap           : Tinterferencebitmap;
        spillednodes,
        simplifyworklist,
        freezeworklist,
        spillworklist,
        coalescednodes,
        selectstack       : tsuperregisterworklist;
        worklist_moves,
        active_moves,
        frozen_moves,
        coalesced_moves,
        constrained_moves : Tlinkedlist;
        extended_backwards,
        backwards_was_first : tbitset;

        { Disposes of the reginfo array.}
        procedure dispose_reginfo;
        { Prepare the register colouring.}
        procedure prepare_colouring;
        { Clean up after register colouring.}
        procedure epilogue_colouring;
        { Colour the registers; that is do the register allocation.}
        procedure colour_registers;
        procedure insert_regalloc_info(list:TAsmList;u:tsuperregister);
        procedure generate_interference_graph(list:TAsmList;headertai:tai);
        function squeeze(n_class, S_class: TSubRegister): longint;
        { translates the registers in the given assembler list }
        procedure translate_registers(list:TAsmList);
        function  spill_registers(list:TAsmList;headertai:tai):boolean;virtual;
        function  getnewreg(subreg:tsubregister):tsuperregister;
        procedure add_edges_used(u:Tsuperregister);
        procedure add_to_movelist(u:Tsuperregister;data:Tlinkedlistitem);
        function move_related(n:Tsuperregister):boolean;
        procedure make_work_list;
        procedure sort_simplify_worklist;
        procedure enable_moves(n:Tsuperregister);
        procedure decrement_degree(m:Tsuperregister);
        procedure simplify;
        procedure add_worklist(u:Tsuperregister);
        function adjacent_ok(u,v:Tsuperregister):boolean;
        function conservative(u,v:Tsuperregister):boolean;
        procedure coalesce;
        procedure freeze_moves(u:Tsuperregister);
        procedure freeze;
        procedure select_spill;
        procedure assign_colours;
        procedure clear_interferences(u:Tsuperregister);
        procedure set_live_range_direction(dir: TRADirection);
        procedure set_live_start(reg : tsuperregister;t : tai);
        function get_live_start(reg : tsuperregister) : tai;
        procedure set_live_end(reg : tsuperregister;t : tai);
        function get_live_end(reg : tsuperregister) : tai;
       public
{$ifdef EXTDEBUG}
        procedure writegraph(loopidx:longint);
{$endif EXTDEBUG}
        procedure combine(u,v:Tsuperregister);

        function reg_count(subreg:TSubRegister):integer;
        { set v as an alias for u }
        procedure set_alias(u,v:Tsuperregister);
        function  get_alias(n:Tsuperregister):Tsuperregister;
        property live_range_direction: TRADirection read int_live_range_direction write set_live_range_direction;
        property live_start[reg : tsuperregister]: tai read get_live_start write set_live_start;
        property live_end[reg : tsuperregister]: tai read get_live_end write set_live_end;
      end;

    const
      first_reg = 0;
      last_reg = high(tsuperregister)-1;
      maxspillingcounter = 20;


  implementation

    uses
       systems,fmodule,globals,
       verbose,tgobj,procinfo;


    procedure sort_movelist(ml:Pmovelist);

    {Ok, sorting pointers is silly, but it does the job to make Trgobj.combine
     faster.}

    var h,i,p:longword;
        t:Tlinkedlistitem;

    begin
      with ml^ do
        begin
          if header.count<2 then
            exit;
          p:=1;
          while 2*cardinal(p)<header.count do
            p:=2*p;
          while p<>0 do
            begin
              for h:=p to header.count-1 do
                begin
                  i:=h;
                  t:=data[i];
                  repeat
                    if ptruint(data[i-p])<=ptruint(t) then
                      break;
                    data[i]:=data[i-p];
                    dec(i,p);
                  until i<p;
                  data[i]:=t;
                end;
              p:=p shr 1;
            end;
          header.sorted_until:=header.count-1;
        end;
    end;

{******************************************************************************
                              tinterferencebitmap
******************************************************************************}

    constructor tinterferencebitmap.create;
      begin
        inherited create;
        maxx1:=1;
        fbitmap:=AllocMem(sizeof(tinterferencebitmap1)*2);
      end;


    destructor tinterferencebitmap.destroy;

    var i,j:byte;

    begin
      for i:=0 to maxx1 do
        for j:=0 to maxy1 do
          if assigned(fbitmap[i,j]) then
            dispose(fbitmap[i,j]);
      freemem(fbitmap);
    end;


    function tinterferencebitmap.getbitmap(x,y:tsuperregister):boolean;
      var
        page : pinterferencebitmap2;
      begin
        result:=false;
        if (x shr 8>maxx1) then
          exit;
        page:=fbitmap[x shr 8,y shr 8];
        result:=assigned(page) and
          ((x and $ff) in page^[y and $ff]);
      end;


    procedure tinterferencebitmap.setbitmap(x,y:tsuperregister;b:boolean);
      var
        x1,y1 : byte;
      begin
        x1:=x shr 8;
        y1:=y shr 8;
        if x1>maxx1 then
          begin
            reallocmem(fbitmap,sizeof(tinterferencebitmap1)*(x1+1));
            fillchar(fbitmap[maxx1+1],sizeof(tinterferencebitmap1)*(x1-maxx1),0);
            maxx1:=x1;
          end;
        if not assigned(fbitmap[x1,y1]) then
          begin
            if y1>maxy1 then
              maxy1:=y1;
            new(fbitmap[x1,y1]);
            fillchar(fbitmap[x1,y1]^,sizeof(tinterferencebitmap2),0);
          end;
        if b then
          include(fbitmap[x1,y1]^[y and $ff],(x and $ff))
        else
          exclude(fbitmap[x1,y1]^[y and $ff],(x and $ff));
      end;


{******************************************************************************
                                trgobj
******************************************************************************}

    constructor trgobj.create(Aregtype:Tregistertype;
                              Adefaultsub:Tsubregister;
                              const Ausable:array of tsuperregister;
                              Afirst_imaginary:Tsuperregister;
                              Apreserved_by_proc:Tcpuregisterset);
       var
         i : cardinal;
       begin
         { empty super register sets can cause very strange problems }
         if high(Ausable)=-1 then
           internalerror(200210181);
         live_range_direction:=rad_forward;
         first_imaginary:=Afirst_imaginary;
         maxreg:=Afirst_imaginary;
         regtype:=Aregtype;
         defaultsub:=Adefaultsub;
         preserved_by_proc:=Apreserved_by_proc;
         // default value set by newinstance
         // used_in_proc:=[];
         live_registers.init;
         { Get reginfo for CPU registers }
         maxreginfo:=first_imaginary;
         maxreginfoinc:=16;
         worklist_moves:=Tlinkedlist.create;
         reginfo:=allocmem(first_imaginary*sizeof(treginfo));
         for i:=0 to first_imaginary-1 do
           begin
             reginfo[i].degree:=high(tsuperregister);
             reginfo[i].alias:=RS_INVALID;
           end;
         { Usable registers }
         // default value set by constructor
         // fillchar(usable_registers,sizeof(usable_registers),0);
         for i:=low(Ausable) to high(Ausable) do
           begin
             usable_registers[i]:=Ausable[i];
             include(usable_register_set,Ausable[i]);
           end;
         usable_registers_cnt:=high(Ausable)+1;
         { Initialize Worklists }
         spillednodes.init;
         simplifyworklist.init;
         freezeworklist.init;
         spillworklist.init;
         coalescednodes.init;
         selectstack.init;
      end;

    destructor trgobj.destroy;

    begin
      spillednodes.done;
      simplifyworklist.done;
      freezeworklist.done;
      spillworklist.done;
      coalescednodes.done;
      selectstack.done;
      live_registers.done;
      worklist_moves.free;
      dispose_reginfo;
      extended_backwards.free;
      backwards_was_first.free;
    end;

    procedure trgobj.define_class(asubclass: TSubRegister; const Aregs: array of TSuperRegister);
      var
        reg: TSuperRegister;
      begin
        supregset_reset(reg_class[asubclass],false,first_imaginary);

        for reg in aregs do
          supregset_include(reg_class[asubclass],reg);
      end;

    procedure trgobj.define_alias(aregister: TSuperRegister; const Aregs: array of TSuperRegister);
      var
        reg: TSuperRegister;
      begin
        alias_register_def[aregister]:=aregister;
        supregset_reset(alias_registers[aregister],false,first_imaginary);
        for reg in aregs do
          supregset_include(alias_registers[aregister],reg);
        inc(alias_registers_cnt);
      end;

    procedure trgobj.dispose_reginfo;
      var
        i:cardinal;
      begin
        if reginfo<>nil then
          begin
            for i:=0 to maxreg-1 do
              with reginfo[i] do
                begin
                  if adjlist<>nil then
                    dispose(adjlist,done);
                  if movelist<>nil then
                    dispose(movelist);
                end;
            freemem(reginfo);
            reginfo:=nil;
          end;
      end;

    function trgobj.getnewreg(subreg:tsubregister):tsuperregister;
      var
        oldmaxreginfo : tsuperregister;
      begin
        result:=maxreg;
        inc(maxreg);
        if maxreg>=last_reg then
          Message(parser_f_too_complex_proc);
        if maxreg>=maxreginfo then
          begin
            oldmaxreginfo:=maxreginfo;
            { Prevent overflow }
            if maxreginfoinc>last_reg-maxreginfo then
              maxreginfo:=last_reg
            else
              begin
                inc(maxreginfo,maxreginfoinc);
                if maxreginfoinc<256 then
                  maxreginfoinc:=maxreginfoinc*2;
              end;
            reallocmem(reginfo,maxreginfo*sizeof(treginfo));
            { Do we really need it to clear it ? At least for 1.0.x (PFV) }
            fillchar(reginfo[oldmaxreginfo],(maxreginfo-oldmaxreginfo)*sizeof(treginfo),0);
          end;
        reginfo[result].subreg:=subreg;
      end;


    function trgobj.getregister(list:TAsmList;subreg:Tsubregister):Tregister;
      begin
        {$ifdef EXTDEBUG}
        if reginfo=nil then
          InternalError(2004020901);
        {$endif EXTDEBUG}
        if defaultsub=R_SUBNONE then
          result:=newreg(regtype,getnewreg(R_SUBNONE),R_SUBNONE)
        else
          result:=newreg(regtype,getnewreg(subreg),subreg);
      end;


    function trgobj.uses_registers:boolean;
      begin
        result:=(maxreg>first_imaginary);
      end;


    procedure trgobj.ungetcpuregister(list:TAsmList;r:Tregister);
      begin
        if (getsupreg(r)>=first_imaginary) then
          InternalError(2004020901);
        list.concat(Tai_regalloc.dealloc(r,nil));
      end;


    procedure trgobj.getcpuregister(list:TAsmList;r:Tregister);
      var
        supreg:Tsuperregister;
      begin
        supreg:=getsupreg(r);
        if supreg>=first_imaginary then
          internalerror(2003121503);
        include(used_in_proc,supreg);
        list.concat(Tai_regalloc.alloc(r,nil));
      end;


    procedure trgobj.alloccpuregisters(list:TAsmList;const r:Tcpuregisterset);

    var i:cardinal;

    begin
      for i:=0 to first_imaginary-1 do
        if i in r then
          getcpuregister(list,newreg(regtype,i,defaultsub));
    end;


    procedure trgobj.dealloccpuregisters(list:TAsmList;const r:Tcpuregisterset);

    var i:cardinal;

    begin
      for i:=0 to first_imaginary-1 do
        if i in r then
          ungetcpuregister(list,newreg(regtype,i,defaultsub));
    end;

    const
      rtindex : longint = 0;
    procedure trgobj.do_register_allocation(list:TAsmList;headertai:tai);
      var
        spillingcounter:byte;
        endspill:boolean;
      begin
        { Insert regalloc info for imaginary registers }
        insert_regalloc_info_all(list);
        ibitmap:=tinterferencebitmap.create;
        generate_interference_graph(list,headertai);
{$ifdef DEBUG_SSA}
        writegraph(rtindex);
{$endif DEBUG_SSA}
        inc(rtindex);
        { Don't do the real allocation when -sr is passed }
        if (cs_no_regalloc in current_settings.globalswitches) then
          exit;
        {Do register allocation.}
        spillingcounter:=0;
        repeat
          prepare_colouring;
          colour_registers;
          epilogue_colouring;
          endspill:=true;
          if spillednodes.length<>0 then
            begin
              inc(spillingcounter);
              if spillingcounter>maxspillingcounter then
                begin
{$ifdef EXTDEBUG}
                  { Only exit here so the .s file is still generated. Assembling
                    the file will still trigger an error }
                  exit;
{$else}
                  internalerror(200309041);
{$endif}
                end;
              endspill:=not spill_registers(list,headertai);
            end;
        until endspill;
        ibitmap.free;
        translate_registers(list);
        { we need the translation table for debugging info and verbose assembler output (FK)
          dispose_reginfo;
        }
      end;


    procedure trgobj.add_constraints(reg:Tregister);
      begin
      end;


    procedure trgobj.add_class_constraints(reg: Tregister);
      var
        supreg: TSuperRegister;
        subreg: TSubRegister;
      begin
        {subreg:=getsubreg(reg);
        for supreg:=0 to first_imaginary-1 do
          if not supregset_in(reg_class[subreg],supreg) then
            add_edge(supreg,getsupreg(reg));}
      end;


    procedure trgobj.add_alias_constraints(reg: Tregister);
      var
        r,supreg: TSuperRegister;
        subreg: TSubRegister;
      begin
        add_class_constraints(reg);

        subreg:=getsubreg(reg);

        {for supreg:=0 to first_imaginary-1 do
          if supregset_in(reg_class[subreg],supreg) then
            for r:=0 to first_imaginary-1 do
              if supregset_in(alias_registers[supreg],r) then
                add_edge(supreg,r);}
      end;


    procedure trgobj.add_edge(u,v:Tsuperregister);

    {This procedure will add an edge to the virtual interference graph.}

      procedure addadj(u,v:Tsuperregister);

      begin
{$ifdef EXTDEBUG}
        if (u>=maxreginfo) then
          internalerror(2012101901);
{$endif}
        with reginfo[u] do
          begin
            if adjlist=nil then
              new(adjlist,init);
            adjlist^.add(v);
          end;
      end;

    begin
      if (u<>v) and not(ibitmap[v,u]) then
        begin
          ibitmap[v,u]:=true;
          ibitmap[u,v]:=true;
          {Precoloured nodes are not stored in the interference graph.}
          if (u>=first_imaginary) then
            addadj(u,v);
          if (v>=first_imaginary) then
            addadj(v,u);
        end;
    end;


    procedure trgobj.add_edges_used(u:Tsuperregister);

    var i:cardinal;

    begin
      with live_registers do
        if length>0 then
          for i:=0 to length-1 do
            add_edge(u,get_alias(buf^[i]));
    end;

{$ifdef EXTDEBUG}
    procedure trgobj.writegraph(loopidx:longint);

    {This procedure writes out the current interference graph in the
    register allocator.}


    var f:text;
        i,j:cardinal;

    begin
      assign(f,'igraph'+tostr(loopidx));
      rewrite(f);
      writeln(f,'Interference graph');
      writeln(f);
      write(f,'    ');
      for i:=0 to maxreg div 16 do
        for j:=0 to 15 do
          write(f,hexstr(i,1));
      writeln(f);
      write(f,'    ');
      for i:=0 to maxreg div 16 do
        write(f,'0123456789ABCDEF');
      writeln(f);
      for i:=0 to maxreg-1 do
        begin
          write(f,hexstr(i,2):4);
          for j:=0 to maxreg-1 do
            if ibitmap[i,j] then
              write(f,'*')
            else
              write(f,'-');
          writeln(f);
        end;
      close(f);
    end;
{$endif EXTDEBUG}

    procedure trgobj.add_to_movelist(u:Tsuperregister;data:Tlinkedlistitem);
    begin
{$ifdef EXTDEBUG}
        if (u>=maxreginfo) then
          internalerror(2012101902);
{$endif}
      with reginfo[u] do
        begin
          if movelist=nil then
            begin
              { don't use sizeof(tmovelistheader), because that ignores alignment }
              getmem(movelist,ptruint(@movelist^.data)-ptruint(movelist)+60*sizeof(pointer));
              movelist^.header.maxcount:=60;
              movelist^.header.count:=0;
              movelist^.header.sorted_until:=0;
            end
          else
            begin
              if movelist^.header.count>=movelist^.header.maxcount then
                begin
                  movelist^.header.maxcount:=movelist^.header.maxcount*2;
                  { don't use sizeof(tmovelistheader), because that ignores alignment }
                  reallocmem(movelist,ptruint(@movelist^.data)-ptruint(movelist)+movelist^.header.maxcount*sizeof(pointer));
                end;
            end;
          movelist^.data[movelist^.header.count]:=data;
          inc(movelist^.header.count);
        end;
    end;


    procedure trgobj.set_live_range_direction(dir: TRADirection);
      begin
        if (dir in [rad_backwards,rad_backwards_reinit]) then
          begin
            if not assigned(extended_backwards) then
              begin
                { create expects a "size", not a "max bit" parameter -> +1 }
                backwards_was_first:=tbitset.create(maxreg+1);
                extended_backwards:=tbitset.create(maxreg+1);
              end
            else
              begin
                if (dir=rad_backwards_reinit) then
                  extended_backwards.clear;
                backwards_was_first.clear;
              end;
            int_live_range_direction:=rad_backwards;
          end
        else
          int_live_range_direction:=rad_forward;
      end;


    procedure trgobj.set_live_start(reg: tsuperregister; t: tai);
      begin
        reginfo[reg].live_start:=t;
      end;


    function trgobj.get_live_start(reg: tsuperregister): tai;
      begin
        result:=reginfo[reg].live_start;
      end;


    procedure trgobj.set_live_end(reg: tsuperregister; t: tai);
      begin
        reginfo[reg].live_end:=t;
      end;


    function trgobj.get_live_end(reg: tsuperregister): tai;
      begin
        result:=reginfo[reg].live_end;
      end;


    procedure trgobj.add_reg_instruction(instr:Tai;r:tregister;aweight:longint);
      var
        supreg : tsuperregister;
      begin
        supreg:=getsupreg(r);
{$ifdef extdebug}
        if not (cs_no_regalloc in current_settings.globalswitches) and
           (supreg>=maxreginfo) then
          internalerror(200411061);
{$endif extdebug}
        if supreg>=first_imaginary then
          with reginfo[supreg] do
            begin
              // if aweight>weight then
              inc(weight,aweight);
              if (live_range_direction=rad_forward) then
                begin
                  if not assigned(live_start) then
                    live_start:=instr;
                  live_end:=instr;
                end
               else
                 begin
                   if not extended_backwards.isset(supreg) then
                     begin
                       extended_backwards.include(supreg);
                       live_start := instr;
                       if not assigned(live_end) then
                         begin
                           backwards_was_first.include(supreg);
                           live_end := instr;
                         end;
                     end
                   else
                     begin
                       if backwards_was_first.isset(supreg) then
                         live_end := instr;
                     end
                 end
            end;
      end;


  procedure trgobj.add_move_instruction(instr:Taicpu);

    {This procedure notifies a certain as a move instruction so the
     register allocator can try to eliminate it.}

    var i:Tmoveins;
        sreg, dreg : Tregister;
        ssupreg,dsupreg:Tsuperregister;

    begin
    {$ifdef extdebug}
      if (instr.oper[O_MOV_SOURCE]^.typ<>top_reg) or
         (instr.oper[O_MOV_DEST]^.typ<>top_reg) then
        internalerror(200311291);
    {$endif}
      sreg:=instr.oper[O_MOV_SOURCE]^.reg;
      dreg:=instr.oper[O_MOV_DEST]^.reg;
      { How should we handle m68k move %d0,%a0? }
      if (getregtype(sreg)<>getregtype(dreg)) then
        exit;
      i:=Tmoveins.create;
      i.moveset:=ms_worklist_moves;
      worklist_moves.insert(i);
      ssupreg:=getsupreg(sreg);
      add_to_movelist(ssupreg,i);
      dsupreg:=getsupreg(dreg);
      { On m68k move can mix address and integer registers,
        this leads to problems ... PM }
      if (ssupreg<>dsupreg) {and (getregtype(sreg)=getregtype(dreg))} then
        {Avoid adding the same move instruction twice to a single register.}
        add_to_movelist(dsupreg,i);
      i.x:=ssupreg;
      i.y:=dsupreg;
    end;

  function trgobj.move_related(n:Tsuperregister):boolean;

    var i:cardinal;

    begin
      move_related:=false;
      with reginfo[n] do
        if movelist<>nil then
          with movelist^ do
            for i:=0 to header.count-1 do
              if Tmoveins(data[i]).moveset in [ms_worklist_moves,ms_active_moves] then
                begin
                  move_related:=true;
                  break;
                end;
    end;

  procedure trgobj.sort_simplify_worklist;

    {Sorts the simplifyworklist by the number of interferences the
     registers in it cause. This allows simplify to execute in
     constant time.}

    var p,h,i,leni,lent:longword;
        t:Tsuperregister;
        adji,adjt:Psuperregisterworklist;

    begin
      with simplifyworklist do
        begin
          if length<2 then
            exit;
          p:=1;
          while 2*p<length do
            p:=2*p;
          while p<>0 do
            begin
              for h:=p to length-1 do
                begin
                  i:=h;
                  t:=buf^[i];
                  adjt:=reginfo[buf^[i]].adjlist;
                  lent:=0;
                  if adjt<>nil then
                    lent:=adjt^.length;
                  repeat
                    adji:=reginfo[buf^[i-p]].adjlist;
                    leni:=0;
                    if adji<>nil then
                      leni:=adji^.length;
                    if leni<=lent then
                      break;
                    buf^[i]:=buf^[i-p];
                    dec(i,p)
                  until i<p;
                  buf^[i]:=t;
                end;
              p:=p shr 1;
            end;
        end;
    end;


  function trgobj.squeeze(n_class,S_class:TSubRegister):longint;
    var
      r,r2:tsuperregister;
      rs:tsuperregisterset;
      t:integer;
    begin
      result:=0;

      rs:=reg_class[n_class];

      for r:=0 to usable_registers_cnt-1 do
        if supregset_in(reg_class[S_class],r) then
          begin
            t:=0;
            for r2:=0 to usable_registers_cnt-1 do
              if supregset_in(alias_registers[r],r2) then
                supregset_exclude(rs,r2);

            for r2:=0 to usable_registers_cnt-1 do
              if supregset_in(rs,r2) then
                inc(t);

            result:=max(result,t);
          end;
    end;

  procedure trgobj.make_work_list;

    var n:cardinal;
      i: Integer;

    begin
      {If we have 7 cpu registers, and the degree of a node is 7, we cannot
       assign it to any of the registers, thus it is significant.}
      for n:=first_imaginary to maxreg-1 do
        with reginfo[n] do
          begin
            if adjlist=nil then
              degree:=0
            else
              begin
                //degree:=adjlist^.length;
                degree:=0;
                for i:=0 to adjlist^.length-1 do
                  begin
                    degree:=max(degree,
                      squeeze(reginfo[n].subreg,reginfo[adjlist^.buf^[i]].subreg));
                  end;
              end;
            if degree>=reg_count(reginfo[n].subreg) then
              spillworklist.add(n)
            else if move_related(n) then
              freezeworklist.add(n)
            else if not(ri_coalesced in flags) then
              simplifyworklist.add(n);
          end;
      sort_simplify_worklist;
    end;


    procedure trgobj.prepare_colouring;
    begin
      make_work_list;
      active_moves:=Tlinkedlist.create;
      frozen_moves:=Tlinkedlist.create;
      coalesced_moves:=Tlinkedlist.create;
      constrained_moves:=Tlinkedlist.create;
      selectstack.clear;
    end;

    procedure trgobj.enable_moves(n:Tsuperregister);

    var m:Tlinkedlistitem;
        i:cardinal;

    begin
      with reginfo[n] do
        if movelist<>nil then
          for i:=0 to movelist^.header.count-1 do
            begin
              m:=movelist^.data[i];
              if Tmoveins(m).moveset in [ms_worklist_moves,ms_active_moves] then
                if Tmoveins(m).moveset=ms_active_moves then
                  begin
                    {Move m from the set active_moves to the set worklist_moves.}
                    active_moves.remove(m);
                    Tmoveins(m).moveset:=ms_worklist_moves;
                    worklist_moves.concat(m);
                  end;
          end;
    end;

  procedure trgobj.decrement_degree(m: Tsuperregister);

    var adj : Psuperregisterworklist;
        n : tsuperregister;
        d,i : cardinal;

    begin
      with reginfo[m] do
        begin
          {d:=degree;
          if d=0 then
            internalerror(200312151);
          dec(degree);}

          //degree:=0;

          if assigned(adjlist) then
            for i:=0 to adjlist^.length-1 do
              begin
                degree:=max(degree,
                  squeeze(reginfo[m].subreg,reginfo[adjlist^.buf^[i]].subreg));
              end;
          d:=degree;

          if d=reg_count(subreg) then
            begin
              {Enable moves for m.}
              enable_moves(m);
              {Enable moves for adjacent.}
              adj:=adjlist;
              if adj<>nil then
                for i:=1 to adj^.length do
                  begin
                    n:=adj^.buf^[i-1];
                    if reginfo[n].flags*[ri_selected,ri_coalesced]<>[] then
                      enable_moves(n);
                  end;
              {Remove the node from the spillworklist.}
              if not spillworklist.delete(m) then
                internalerror(200310145);

              if move_related(m) then
                freezeworklist.add(m)
              else
                simplifyworklist.add(m);
            end;
        end;
    end;

    procedure trgobj.simplify;

    var adj : Psuperregisterworklist;
        m,n : Tsuperregister;
        i : cardinal;
    begin
      {We take the element with the least interferences out of the
       simplifyworklist. Since the simplifyworklist is now sorted, we
       no longer need to search, but we can simply take the first element.}
      m:=simplifyworklist.get;

      {Push it on the selectstack.}
      selectstack.add(m);
      with reginfo[m] do
        begin
          include(flags,ri_selected);
          adj:=adjlist;
        end;
      if adj<>nil then
        for i:=1 to adj^.length do
          begin
            n:=adj^.buf^[i-1];
            if (n>=first_imaginary) and
               (reginfo[n].flags*[ri_selected,ri_coalesced]=[]) then
              decrement_degree(n);
          end;
    end;

    function trgobj.get_alias(n:Tsuperregister):Tsuperregister;

    begin
      while ri_coalesced in reginfo[n].flags do
        n:=reginfo[n].alias;
      get_alias:=n;
    end;

    procedure trgobj.add_worklist(u:Tsuperregister);
      begin
        if (u>=first_imaginary) and
           (not move_related(u)) and
           (reginfo[u].degree<reg_count(reginfo[u].subreg)) then
          begin
            if not freezeworklist.delete(u) then
              internalerror(200308161); {must be found}
            simplifyworklist.add(u);
          end;
      end;


    function trgobj.adjacent_ok(u,v:Tsuperregister):boolean;

    {Check wether u and v should be coalesced. u is precoloured.}

      function ok(t,r:Tsuperregister):boolean;

      begin
        ok:=(t<first_imaginary) or
            // disabled for now, see issue #22405
            // ((r<first_imaginary) and (r in usable_register_set)) or
            (reginfo[t].degree<reg_count(reginfo[t].subreg)) or
            ibitmap[r,t];
      end;

    var adj : Psuperregisterworklist;
        i : cardinal;
        n : tsuperregister;

    begin
      with reginfo[v] do
        begin
          adjacent_ok:=true;
          adj:=adjlist;
          if adj<>nil then
            for i:=1 to adj^.length do
              begin
                n:=adj^.buf^[i-1];
                if (flags*[ri_coalesced,ri_selected]=[]) and not ok(n,u) then
                  begin
                    adjacent_ok:=false;
                    break;
                  end;
              end;
        end;
    end;

  function trgobj.conservative(u,v:Tsuperregister):boolean;

    var adj : Psuperregisterworklist;
        done : Tsuperregisterset; {To prevent that we count nodes twice.}
        i,k:cardinal;
        n : tsuperregister;

    begin
      k:=0;
      supregset_reset(done,false,maxreg);
      with reginfo[u] do
        begin
          adj:=adjlist;
          if adj<>nil then
            for i:=1 to adj^.length do
              begin
                n:=adj^.buf^[i-1];
                if flags*[ri_coalesced,ri_selected]=[] then
                  begin
                    supregset_include(done,n);
                    if reginfo[n].degree>=reg_count(reginfo[n].subreg) then
                      inc(k);
                  end;
              end;
        end;
      adj:=reginfo[v].adjlist;
      if adj<>nil then
        for i:=1 to adj^.length do
          begin
            n:=adj^.buf^[i-1];
            if not supregset_in(done,n) and
               (reginfo[n].degree>=reg_count(reginfo[n].subreg)) and
               (reginfo[u].flags*[ri_coalesced,ri_selected]=[]) then
              inc(k);
          end;
      conservative:=(k<max(reg_count(reginfo[u].subreg),reg_count(reginfo[v].subreg)));
    end;

    procedure trgobj.set_alias(u,v:Tsuperregister);

    begin
      { don't make registers that the register allocator shouldn't touch (such
        as stack and frame pointers) be aliases for other registers, because
        then it can propagate them and even start changing them if the aliased
        register gets changed }
      if ((u<first_imaginary) and
          not(u in usable_register_set)) or
         ((v<first_imaginary) and
          not(v in usable_register_set)) then
        exit;
      include(reginfo[v].flags,ri_coalesced);
      if reginfo[v].alias<>0 then
        internalerror(200712291);
      reginfo[v].alias:=get_alias(u);
      coalescednodes.add(v);
    end;


    procedure trgobj.combine(u,v:Tsuperregister);

    var adj : Psuperregisterworklist;
        i,n,p,q:cardinal;
        t : tsuperregister;
        searched:Tlinkedlistitem;
        found : boolean;

    begin
      if not freezeworklist.delete(v) then
        spillworklist.delete(v);
      coalescednodes.add(v);
      include(reginfo[v].flags,ri_coalesced);
      reginfo[v].alias:=u;

      {Combine both movelists. Since the movelists are sets, only add
       elements that are not already present. The movelists cannot be
       empty by definition; nodes are only coalesced if there is a move
       between them. To prevent quadratic time blowup (movelists of
       especially machine registers can get very large because of moves
       generated during calls) we need to go into disgusting complexity.

       (See webtbs/tw2242 for an example that stresses this.)

       We want to sort the movelist to be able to search logarithmically.
       Unfortunately, sorting the movelist every time before searching
       is counter-productive, since the movelist usually grows with a few
       items at a time. Therefore, we split the movelist into a sorted
       and an unsorted part and search through both. If the unsorted part
       becomes too large, we sort.}
      if assigned(reginfo[u].movelist) then
        begin
          {We have to weigh the cost of sorting the list against searching
           the cost of the unsorted part. I use factor of 8 here; if the
           number of items is less than 8 times the numer of unsorted items,
           we'll sort the list.}
          with reginfo[u].movelist^ do
            if header.count<8*(header.count-header.sorted_until) then
              sort_movelist(reginfo[u].movelist);
          if assigned(reginfo[v].movelist) then
            begin
              for n:=0 to reginfo[v].movelist^.header.count-1 do
                begin
                  {Binary search the sorted part of the list.}
                  searched:=reginfo[v].movelist^.data[n];
                  p:=0;
                  q:=reginfo[u].movelist^.header.sorted_until;
                  i:=0;
                  if q<>0 then
                    repeat
                      i:=(p+q) shr 1;
                      if ptruint(searched)>ptruint(reginfo[u].movelist^.data[i]) then
                        p:=i+1
                      else
                        q:=i;
                    until p=q;
                  with reginfo[u].movelist^ do
                    if searched<>data[i] then
                      begin
                        {Linear search the unsorted part of the list.}
                        found:=false;
                        for i:=header.sorted_until+1 to header.count-1 do
                          if searched=data[i] then
                            begin
                              found:=true;
                              break;
                            end;
                        if not found then
                          add_to_movelist(u,searched);
                      end;
                end;
            end;
        end;

      enable_moves(v);

      adj:=reginfo[v].adjlist;
      if adj<>nil then
        for i:=1 to adj^.length do
          begin
            t:=adj^.buf^[i-1];
            with reginfo[t] do
              if not(ri_coalesced in flags) then
                begin
                  {t has a connection to v. Since we are adding v to u, we
                   need to connect t to u. However, beware if t was already
                   connected to u...}
                  if (ibitmap[t,u]) and not (ri_selected in flags) then
                    {... because in that case, we are actually removing an edge
                     and the degree of t decreases.}
                    decrement_degree(t)
                  else
                    begin
                      add_edge(t,u);
                      {We have added an edge to t and u. So their degree increases.
                       However, v is added to u. That means its neighbours will
                       no longer point to v, but to u instead. Therefore, only the
                       degree of u increases.}
                      if (u>=first_imaginary) and not (ri_selected in flags) then
                        inc(reginfo[u].degree);
                    end;
                end;
          end;
      if (reginfo[u].degree>=reg_count(reginfo[u].subreg)) and freezeworklist.delete(u) then
        spillworklist.add(u);
    end;


  function trgobj.reg_count(subreg: TSubRegister): integer;
    var
      r:TSuperRegister;
    begin
      result:=0;

      for r:=0 to first_imaginary-1 do
        if supregset_in(reg_class[subreg],r) then
          inc(result);
    end;


  procedure trgobj.coalesce;

    var m:Tmoveins;
        x,y,u,v:cardinal;

    begin
      m:=Tmoveins(worklist_moves.getfirst);
      x:=get_alias(m.x);
      y:=get_alias(m.y);
      if (y<first_imaginary) then
        begin
          u:=y;
          v:=x;
        end
      else
        begin
          u:=x;
          v:=y;
        end;
      if (u=v) then
        begin
          m.moveset:=ms_coalesced_moves;  {Already coalesced.}
          coalesced_moves.insert(m);
          add_worklist(u);
        end
      {Do u and v interfere? In that case the move is constrained. Two
       precoloured nodes interfere allways. If v is precoloured, by the above
       code u is precoloured, thus interference...}
      else if (v<first_imaginary) or ibitmap[u,v] then
        begin
          m.moveset:=ms_constrained_moves;  {Cannot coalesce yet...}
          constrained_moves.insert(m);
          add_worklist(u);
          add_worklist(v);
        end
      {Next test: is it possible and a good idea to coalesce?? Note: don't
       coalesce registers that should not be touched by the register allocator,
       such as stack/framepointers, because otherwise they can be changed }
      else if (((u<first_imaginary) and adjacent_ok(u,v)) or
               conservative(u,v)) and
              ((u>first_imaginary) or
               (u in usable_register_set)) and
              ((v>first_imaginary) or
               (v in usable_register_set)) then
        begin
          m.moveset:=ms_coalesced_moves;  {Move coalesced!}
          coalesced_moves.insert(m);
          combine(u,v);
          add_worklist(u);
        end
      else
        begin
          m.moveset:=ms_active_moves;
          active_moves.insert(m);
        end;
    end;

    procedure trgobj.freeze_moves(u:Tsuperregister);

    var i:cardinal;
        m:Tlinkedlistitem;
        v,x,y:Tsuperregister;

    begin
      if reginfo[u].movelist<>nil then
        for i:=0 to reginfo[u].movelist^.header.count-1 do
          begin
            m:=reginfo[u].movelist^.data[i];
            if Tmoveins(m).moveset in [ms_worklist_moves,ms_active_moves] then
              begin
                x:=Tmoveins(m).x;
                y:=Tmoveins(m).y;
                if get_alias(y)=get_alias(u) then
                  v:=get_alias(x)
                else
                  v:=get_alias(y);
                {Move m from active_moves/worklist_moves to frozen_moves.}
                if Tmoveins(m).moveset=ms_active_moves then
                  active_moves.remove(m)
                else
                  worklist_moves.remove(m);
                Tmoveins(m).moveset:=ms_frozen_moves;
                frozen_moves.insert(m);

                if (v>=first_imaginary) and not(move_related(v)) and
                   (reginfo[v].degree<reg_count(reginfo[v].subreg)) then
                  begin
                    freezeworklist.delete(v);
                    simplifyworklist.add(v);
                  end;
              end;
          end;
    end;

    procedure trgobj.freeze;

    var n:Tsuperregister;

    begin
      { We need to take a random element out of the freezeworklist. We take
        the last element. Dirty code! }
      n:=freezeworklist.get;
      {Add it to the simplifyworklist.}
      simplifyworklist.add(n);
      freeze_moves(n);
    end;

    procedure trgobj.select_spill;
    var
      n : tsuperregister;
      adj : psuperregisterworklist;
      max,p,i:word;
      minweight: longint;
    begin
      { We must look for the element with the most interferences in the
        spillworklist. This is required because those registers are creating
        the most conflicts and keeping them in a register will not reduce the
        complexity and even can cause the help registers for the spilling code
        to get too much conflicts with the result that the spilling code
        will never converge (PFV) }
      max:=0;
      minweight:=high(longint);
      p:=0;
      with spillworklist do
        begin
          {Safe: This procedure is only called if length<>0}
          for i:=0 to length-1 do
            begin
              adj:=reginfo[buf^[i]].adjlist;
              if assigned(adj) and
                 (
                  (adj^.length>max) or
                  ((adj^.length=max) and (reginfo[buf^[i]].weight<minweight))
                 ) then
                begin
                  p:=i;
                  max:=adj^.length;
                  minweight:=reginfo[buf^[i]].weight;
                end;
            end;
          n:=buf^[p];
          deleteidx(p);
        end;

      simplifyworklist.add(n);
      freeze_moves(n);
    end;

    procedure trgobj.assign_colours;

    {Assign_colours assigns the actual colours to the registers.}

    var adj : Psuperregisterworklist;
        i,j,k : cardinal;
        n,a,c : Tsuperregister;
        colourednodes : Tsuperregisterset;
        adj_colours:set of 0..255;
        found : boolean;
        tmpr: tregister;
        r: Integer;
    begin
      spillednodes.clear;
      {Reset colours}
      for n:=0 to maxreg-1 do
        reginfo[n].colour:=n;
      {Colour the cpu registers...}
      supregset_reset(colourednodes,false,maxreg);
      for n:=0 to first_imaginary-1 do
        supregset_include(colourednodes,n);
      {Now colour the imaginary registers on the select-stack.}
      for i:=selectstack.length downto 1 do
        begin
          n:=selectstack.buf^[i-1];
          {Create a list of colours that we cannot assign to n.}
          adj_colours:=[];
          adj:=reginfo[n].adjlist;
          if adj<>nil then
            for j:=0 to adj^.length-1 do
              begin
                a:=get_alias(adj^.buf^[j]);
                if supregset_in(colourednodes,a) and (reginfo[a].colour<=255) then
                  begin
                    include(adj_colours,reginfo[a].colour);

                    for r:=0 to usable_registers_cnt-1 do
                      if supregset_in(alias_registers[reginfo[a].colour],r) then
                        Include(adj_colours,r);
                  end;
              end;
          { FIXME: temp variable r is needed here to avoid Internal error 20060521 }
          {        while compiling the compiler. }
          tmpr:=NR_STACK_POINTER_REG;
          if regtype=getregtype(tmpr) then
            include(adj_colours,RS_STACK_POINTER_REG);
          {Assume a spill by default...}
          found:=false;
          {Search for a colour not in this list.}
          for k:=0 to usable_registers_cnt-1 do
            begin
              c:=usable_registers[k];
              if supregset_in(reg_class[reginfo[n].subreg],c) and
                 not(c in adj_colours) then
                begin
                  reginfo[n].colour:=c;
                  found:=true;
                  supregset_include(colourednodes,n);
                  include(used_in_proc,c);
                  break;
                end;
            end;
          if not found then
            spillednodes.add(n);
        end;
      {Finally colour the nodes that were coalesced.}
      for i:=1 to coalescednodes.length do
        begin
          n:=coalescednodes.buf^[i-1];
          k:=get_alias(n);
          reginfo[n].colour:=reginfo[k].colour;
          if reginfo[k].colour<first_imaginary then
            include(used_in_proc,reginfo[k].colour);
        end;
    end;

    procedure trgobj.colour_registers;

    begin
      repeat
        if simplifyworklist.length<>0 then
          simplify
        else if not(worklist_moves.empty) then
          coalesce
        else if freezeworklist.length<>0 then
          freeze
        else if spillworklist.length<>0 then
          select_spill;
      until (simplifyworklist.length=0) and
            worklist_moves.empty and
            (freezeworklist.length=0) and
            (spillworklist.length=0);
      assign_colours;
    end;

    procedure trgobj.epilogue_colouring;
    var
      i : cardinal;
    begin
      worklist_moves.clear;
      active_moves.destroy;
      active_moves:=nil;
      frozen_moves.destroy;
      frozen_moves:=nil;
      coalesced_moves.destroy;
      coalesced_moves:=nil;
      constrained_moves.destroy;
      constrained_moves:=nil;
      for i:=0 to maxreg-1 do
        with reginfo[i] do
          if movelist<>nil then
            begin
              dispose(movelist);
              movelist:=nil;
            end;
    end;


    procedure trgobj.clear_interferences(u:Tsuperregister);

    {Remove node u from the interference graph and remove all collected
     move instructions it is associated with.}

    var i : word;
        v : Tsuperregister;
        adj,adj2 : Psuperregisterworklist;

    begin
      adj:=reginfo[u].adjlist;
      if adj<>nil then
        begin
          for i:=1 to adj^.length do
            begin
              v:=adj^.buf^[i-1];
              {Remove (u,v) and (v,u) from bitmap.}
              ibitmap[u,v]:=false;
              ibitmap[v,u]:=false;
              {Remove (v,u) from adjacency list.}
              adj2:=reginfo[v].adjlist;
              if adj2<>nil then
                begin
                  adj2^.delete(u);
                  if adj2^.length=0 then
                    begin
                      dispose(adj2,done);
                      reginfo[v].adjlist:=nil;
                    end;
                end;
            end;
          {Remove ( u,* ) from adjacency list.}
          dispose(adj,done);
          reginfo[u].adjlist:=nil;
        end;
    end;


    function trgobj.getregisterinline(list:TAsmList;const subregconstraints:Tsubregisterset):Tregister;
      var
        p : Tsuperregister;
        subreg: tsubregister;
      begin
        for subreg:=high(tsubregister) downto low(tsubregister) do
          if subreg in subregconstraints then
            break;
        p:=getnewreg(subreg);
        live_registers.add(p);
        result:=newreg(regtype,p,subreg);
        add_edges_used(p);
        add_constraints(result);
        add_alias_constraints(result);
        { also add constraints for other sizes used for this register }
        if subreg<>low(tsubregister) then
          for subreg:=pred(subreg) downto low(tsubregister) do
            if subreg in subregconstraints then
              begin
                add_constraints(newreg(regtype,getsupreg(result),subreg));
                add_alias_constraints(newreg(regtype,getsupreg(result),subreg));
              end;
      end;


    procedure trgobj.ungetregisterinline(list:TAsmList;r:Tregister);
      var
        supreg:Tsuperregister;
      begin
        supreg:=getsupreg(r);
        live_registers.delete(supreg);
        insert_regalloc_info(list,supreg);
      end;


    procedure trgobj.insert_regalloc_info(list:TAsmList;u:tsuperregister);
      var
        p : tai;
        r : tregister;
        palloc,
        pdealloc : tai_regalloc;
      begin
        { Insert regallocs for all imaginary registers }
        with reginfo[u] do
          begin
            r:=newreg(regtype,u,subreg);
            if assigned(live_start) then
              begin
                { Generate regalloc and bind it to an instruction, this
                  is needed to find all live registers belonging to an
                  instruction during the spilling }
                if live_start.typ=ait_instruction then
                  palloc:=tai_regalloc.alloc(r,live_start)
                else
                  palloc:=tai_regalloc.alloc(r,nil);
                if live_end.typ=ait_instruction then
                  pdealloc:=tai_regalloc.dealloc(r,live_end)
                else
                  pdealloc:=tai_regalloc.dealloc(r,nil);
                { Insert live start allocation before the instruction/reg_a_sync }
                list.insertbefore(palloc,live_start);
                { Insert live end deallocation before reg allocations
                  to reduce conflicts }
                p:=live_end;
                while assigned(p) and
                      assigned(p.previous) and
                      (tai(p.previous).typ=ait_regalloc) and
                      (tai_regalloc(p.previous).ratype=ra_alloc) and
                      (tai_regalloc(p.previous).reg<>r) do
                  p:=tai(p.previous);
                { , but add release after a reg_a_sync }
                if assigned(p) and
                   (p.typ=ait_regalloc) and
                   (tai_regalloc(p).ratype=ra_sync) then
                  p:=tai(p.next);
                if assigned(p) then
                  list.insertbefore(pdealloc,p)
                else
                  list.concat(pdealloc);
              end;
          end;
      end;


    procedure trgobj.insert_regalloc_info_all(list:TAsmList);
      var
        supreg : tsuperregister;
      begin
        { Insert regallocs for all imaginary registers }
        for supreg:=first_imaginary to maxreg-1 do
          insert_regalloc_info(list,supreg);
      end;


    procedure trgobj.add_cpu_interferences(p : tai);
      begin
      end;


    procedure trgobj.generate_interference_graph(list:TAsmList;headertai:tai);
      var
        p : tai;
{$if defined(EXTDEBUG) or defined(DEBUG_REGISTERLIFE)}
        i : integer;
{$endif defined(EXTDEBUG) or defined(DEBUG_REGISTERLIFE)}
        r,
        supreg : tsuperregister;
      begin
        { All allocations are available. Now we can generate the
          interference graph. Walk through all instructions, we can
          start with the headertai, because before the header tai is
          only symbols. }
        live_registers.clear;
        p:=headertai;
        while assigned(p) do
          begin
            prefetch(pointer(p.next)^);
            if p.typ=ait_regalloc then
              with Tai_regalloc(p) do
                begin
                  if (getregtype(reg)=regtype) then
                    begin
                      supreg:=getsupreg(reg);
                      case ratype of
                        ra_alloc :
                          begin
                            live_registers.add(supreg);
{$ifdef DEBUG_REGISTERLIFE}
                            write(live_registers.length,'  ');
                            for i:=0 to live_registers.length-1 do
                              write(std_regname(newreg(regtype,live_registers.buf^[i],defaultsub)),' ');
                            writeln;
{$endif DEBUG_REGISTERLIFE}
                            add_edges_used(supreg);
                          end;
                        ra_dealloc :
                          begin
                            live_registers.delete(supreg);
{$ifdef DEBUG_REGISTERLIFE}
                            write(live_registers.length,'  ');
                            for i:=0 to live_registers.length-1 do
                              write(std_regname(newreg(regtype,live_registers.buf^[i],defaultsub)),' ');
                            writeln;
{$endif DEBUG_REGISTERLIFE}
                            add_edges_used(supreg);
                          end;
                      end;
                      { constraints needs always to be updated }
                      add_constraints(reg);
                      add_alias_constraints(reg);
                    end;
                end;
            add_cpu_interferences(p);
            p:=Tai(p.next);
          end;

{$ifdef EXTDEBUG}
        if live_registers.length>0 then
          begin
            for i:=0 to live_registers.length-1 do
              begin
                { Only report for imaginary registers }
                if live_registers.buf^[i]>=first_imaginary then
                  Comment(V_Warning,'Register '+std_regname(newreg(regtype,live_registers.buf^[i],defaultsub))+' not released');
              end;
          end;
{$endif}
      end;


    procedure trgobj.translate_register(var reg : tregister);
      begin
        if (getregtype(reg)=regtype) then
          setsupreg(reg,reginfo[getsupreg(reg)].colour);
        //else
          //internalerror(200602021);
      end;


    procedure trgobj.translate_registers(list: TAsmList);
      var
        hp,p,q:Tai;
        i:shortint;
        u:longint;
{$ifdef arm}
        so:pshifterop;
{$endif arm}

      begin
        { Leave when no imaginary registers are used }
        if maxreg<=first_imaginary then
          exit;
        p:=Tai(list.first);
        while assigned(p) do
          begin
            prefetch(pointer(p.next)^);
            case p.typ of
              ait_regalloc:
                with Tai_regalloc(p) do
                  begin
                    if (getregtype(reg)=regtype) then
                      begin
                        { Only alloc/dealloc is needed for the optimizer, remove
                          other regalloc }
                        if not(ratype in [ra_alloc,ra_dealloc]) then
                          begin
                            q:=Tai(next);
                            list.remove(p);
                            p.free;
                            p:=q;
                            continue;
                          end
                        else
                          begin
                            translate_register(reg);
                            {
                              Remove sequences of release and
                              allocation of the same register like. Other combinations
                              of release/allocate need to stay in the list.

                                 # Register X released
                                 # Register X allocated
                            }
                            if assigned(previous) and
                               (ratype=ra_alloc) and
                               (Tai(previous).typ=ait_regalloc) and
                               (Tai_regalloc(previous).reg=reg) and
                               (Tai_regalloc(previous).ratype=ra_dealloc) then
                              begin
                                q:=Tai(next);
                                hp:=tai(previous);
                                list.remove(hp);
                                hp.free;
                                list.remove(p);
                                p.free;
                                p:=q;
                                continue;
                              end;
                          end;
                      end;
                  end;
              ait_varloc:
                begin
                  if (getregtype(tai_varloc(p).newlocation)=regtype) then
                    begin
                      if (cs_asm_source in current_settings.globalswitches) then
                        begin
                          translate_register(tai_varloc(p).newlocation);
                          if tai_varloc(p).newlocationhi<>NR_NO then
                            begin
                              translate_register(tai_varloc(p).newlocationhi);
                                hp:=Tai_comment.Create(strpnew('Var '+tai_varloc(p).varsym.realname+' located in register '+
                                  std_regname(tai_varloc(p).newlocationhi)+':'+std_regname(tai_varloc(p).newlocation)));
                            end
                          else
                            hp:=Tai_comment.Create(strpnew('Var '+tai_varloc(p).varsym.realname+' located in register '+
                              std_regname(tai_varloc(p).newlocation)));
                          list.insertafter(hp,p);
                        end;
                      q:=tai(p.next);
                      list.remove(p);
                      p.free;
                      p:=q;
                      continue;
                    end;
                end;

              ait_instruction:
                with Taicpu(p) do
                  begin
                    current_filepos:=fileinfo;
                    {For speed reasons, get_alias isn't used here, instead,
                     assign_colours will also set the colour of coalesced nodes.
                     If there are registers with colour=0, then the coalescednodes
                     list probably doesn't contain these registers, causing
                     assign_colours not to do this properly.}
                    for i:=0 to ops-1 do
                      with oper[i]^ do
                        case typ of
                          Top_reg:
                             translate_register(reg);
                          Top_ref:
                            begin
                              if regtype in [R_INTREGISTER,R_ADDRESSREGISTER] then
                                with ref^ do
                                  begin
                                    if (base<>NR_NO) then
                                      translate_register(base);
                                    if (index<>NR_NO) then
                                      translate_register(index);
{$if defined(x86)}
                                    if (segment<>NR_NO) then
                                      translate_register(segment);
{$endif defined(x86)}
                                  end;
                            end;
{$ifdef arm}
                          Top_shifterop:
                            begin
                              if regtype=R_INTREGISTER then
                                if (shifterop^.rs<>NR_NO) then
                                  translate_register(shifterop^.rs);
                            end;
{$endif arm}
                        end;

                    { Maybe the operation can be removed when
                      it is a move and both arguments are the same }
                    if is_same_reg_move(regtype) then
                      begin
                        q:=Tai(p.next);
                        list.remove(p);
                        p.free;
                        p:=q;
                        continue;
                      end;
                  end;
            end;
            p:=Tai(p.next);
          end;
        current_filepos:=current_procinfo.exitpos;
      end;


    function trgobj.spill_registers(list:TAsmList;headertai:tai):boolean;
    { Returns true if any help registers have been used }
      var
        i : cardinal;
        t : tsuperregister;
        p,q : Tai;
        regs_to_spill_set:Tsuperregisterset;
        spill_temps : ^Tspill_temp_list;
        supreg : tsuperregister;
        templist : TAsmList;
        size: ptrint;
      begin
        spill_registers:=false;
        live_registers.clear;
        for i:=first_imaginary to maxreg-1 do
          exclude(reginfo[i].flags,ri_selected);
        spill_temps:=allocmem(sizeof(treference)*maxreg);
        supregset_reset(regs_to_spill_set,false,$ffff);
        { Allocate temps and insert in front of the list }
        templist:=TAsmList.create;
        {Safe: this procedure is only called if there are spilled nodes.}
        with spillednodes do
          for i:=0 to length-1 do
            begin
              t:=buf^[i];
              {Alternative representation.}
              supregset_include(regs_to_spill_set,t);
              {Clear all interferences of the spilled register.}
              clear_interferences(t);
              {Get a temp for the spilled register, the size must at least equal a complete register,
               take also care of the fact that subreg can be larger than a single register like doubles
               that occupy 2 registers }
              { only force the whole register in case of integers. Storing a register that contains
                a single precision value as a double can cause conversion errors on e.g. ARM VFP }
              if (regtype=R_INTREGISTER) then
                size:=max(tcgsize2size[reg_cgsize(newreg(regtype,t,R_SUBWHOLE))],
                               tcgsize2size[reg_cgsize(newreg(regtype,t,reginfo[t].subreg))])
              else
                size:=tcgsize2size[reg_cgsize(newreg(regtype,t,reginfo[t].subreg))];
              tg.gettemp(templist,
                         size,size,
                         tt_noreuse,spill_temps^[t]);
            end;
        list.insertlistafter(headertai,templist);
        templist.free;
        { Walk through all instructions, we can start with the headertai,
          because before the header tai is only symbols }
        p:=headertai;
        while assigned(p) do
          begin
            case p.typ of
              ait_regalloc:
                with Tai_regalloc(p) do
                  begin
                    if (getregtype(reg)=regtype) then
                      begin
                        {A register allocation of a spilled register can be removed.}
                        supreg:=getsupreg(reg);
                        if supregset_in(regs_to_spill_set,supreg) then
                          begin
                            q:=Tai(p.next);
                            list.remove(p);
                            p.free;
                            p:=q;
                            continue;
                          end
                        else
                          begin
                            case ratype of
                              ra_alloc :
                               live_registers.add(supreg);
                              ra_dealloc :
                               live_registers.delete(supreg);
                            end;
                          end;
                      end;
                  end;
              ait_instruction:
                with Taicpu(p) do
                  begin
//                    writeln(gas_op2str[taicpu(p).opcode]);
                    current_filepos:=fileinfo;
                    if instr_spill_register(list,taicpu(p),regs_to_spill_set,spill_temps^) then
                      spill_registers:=true;
                  end;
            end;
            p:=Tai(p.next);
          end;
        current_filepos:=current_procinfo.exitpos;
        {Safe: this procedure is only called if there are spilled nodes.}
        with spillednodes do
          for i:=0 to length-1 do
            tg.ungettemp(list,spill_temps^[buf^[i]]);
        freemem(spill_temps);
      end;


    function trgobj.do_spill_replace(list:TAsmList;instr:taicpu;orgreg:tsuperregister;const spilltemp:treference):boolean;
      begin
        result:=false;
      end;


    procedure trgobj.do_spill_read(list:TAsmList;pos:tai;const spilltemp:treference;tempreg:tregister);
      var
        ins:Taicpu;
      begin
        ins:=spilling_create_load(spilltemp,tempreg);
        add_cpu_interferences(ins);
        list.insertafter(ins,pos);
        {$ifdef DEBUG_SPILLING}
        list.Insertbefore(tai_comment.Create(strpnew('Spilling: Spill Read')),ins);
        {$endif}
      end;


        procedure trgobj.do_spill_written(list: TAsmList; pos: tai; const spilltemp: treference; tempreg: tregister);
      var
        ins:Taicpu;
      begin
        ins:=spilling_create_store(tempreg,spilltemp);
        add_cpu_interferences(ins);
        list.insertafter(ins,pos);
        {$ifdef DEBUG_SPILLING}
        list.Insertbefore(tai_comment.Create(strpnew('Spilling: Spill Write')),ins);
        {$endif}
      end;


    function trgobj.get_spill_subreg(r : tregister) : tsubregister;
      begin
        result:=defaultsub;
      end;


    function trgobj.instr_spill_register(list:TAsmList;
                                         instr:taicpu;
                                         const r:Tsuperregisterset;
                                         const spilltemplist:Tspill_temp_list): boolean;
      var
        counter, regindex: longint;
        regs: tspillregsinfo;
        spilled: boolean;

      procedure addreginfo(reg: tregister; operation: topertype);
        var
          i, tmpindex: longint;
          supreg : tsuperregister;
        begin
          tmpindex := regindex;
          supreg:=get_alias(getsupreg(reg));
          { did we already encounter this register? }
          for i := 0 to pred(regindex) do
            if (regs[i].orgreg = supreg) then
              begin
                tmpindex := i;
                break;
              end;
          if tmpindex > high(regs) then
            internalerror(2003120301);
          regs[tmpindex].orgreg := supreg;
          include(regs[tmpindex].spillregconstraints,get_spill_subreg(reg));
          if supregset_in(r,supreg) then
            begin
              { add/update info on this register }
              regs[tmpindex].mustbespilled := true;
              case operation of
                operand_read:
                  regs[tmpindex].regread := true;
                operand_write:
                  regs[tmpindex].regwritten := true;
                operand_readwrite:
                  begin
                    regs[tmpindex].regread := true;
                    regs[tmpindex].regwritten := true;
                  end;
              end;
              spilled := true;
            end;
          inc(regindex,ord(regindex=tmpindex));
        end;


      procedure tryreplacereg(var reg: tregister);
        var
          i: longint;
          supreg: tsuperregister;
        begin
          supreg:=get_alias(getsupreg(reg));
          for i:=0 to pred(regindex) do
            if (regs[i].mustbespilled) and
               (regs[i].orgreg=supreg) then
              begin
                { Only replace supreg }
                setsupreg(reg,getsupreg(regs[i].tempreg));
                break;
              end;
        end;


      var
        loadpos,
        storepos : tai;
        oldlive_registers : tsuperregisterworklist;
      begin
        result := false;
        fillchar(regs,sizeof(regs),0);
        for counter := low(regs) to high(regs) do
          regs[counter].orgreg := RS_INVALID;
        spilled := false;
        regindex := 0;

        { check whether and if so which and how (read/written) this instructions contains
          registers that must be spilled }
        for counter := 0 to instr.ops-1 do
         with instr.oper[counter]^ do
          begin
            case typ of
              top_reg:
                begin
                  if (getregtype(reg) = regtype) then
                    addreginfo(reg,instr.spilling_get_operation_type(counter));
                end;
              top_ref:
                begin
                  if regtype in [R_INTREGISTER,R_ADDRESSREGISTER] then
                    with ref^ do
                      begin
                        if (base <> NR_NO) and
                            (getregtype(base)=regtype) then
                          addreginfo(base,instr.spilling_get_operation_type_ref(counter,base));
                        if (index <> NR_NO) and
                            (getregtype(index)=regtype) then
                          addreginfo(index,instr.spilling_get_operation_type_ref(counter,index));
{$if defined(x86)}
                        if (segment <> NR_NO) and
                            (getregtype(segment)=regtype) then
                          addreginfo(segment,instr.spilling_get_operation_type_ref(counter,segment));
{$endif defined(x86)}
                      end;
                end;
{$ifdef ARM}
              top_shifterop:
                begin
                  if regtype in [R_INTREGISTER,R_ADDRESSREGISTER] then
                    if shifterop^.rs<>NR_NO then
                      addreginfo(shifterop^.rs,operand_read);
                end;
{$endif ARM}
            end;
          end;

        { if no spilling for this instruction we can leave }
        if not spilled then
          exit;

{$if defined(x86) or defined(mips) or defined(sparc) or defined(arm) or defined(m68k)}
        { Try replacing the register with the spilltemp. This is useful only
          for the i386,x86_64 that support memory locations for several instructions

          For non-x86 it is nevertheless possible to replace moves to/from the register
          with loads/stores to spilltemp (Sergei) }
        for counter := 0 to pred(regindex) do
          with regs[counter] do
            begin
              if mustbespilled then
                begin
                  if do_spill_replace(list,instr,orgreg,spilltemplist[orgreg]) then
                    mustbespilled:=false;
                end;
            end;
{$endif defined(x86) or defined(mips) or defined(sparc) or defined(arm) or defined(m68k)}

        {
          There are registers that need are spilled. We generate the
          following code for it. The used positions where code need
          to be inserted are marked using #. Note that code is always inserted
          before the positions using pos.previous. This way the position is always
          the same since pos doesn't change, but pos.previous is modified everytime
          new code is inserted.

          [
            - reg_allocs load spills
            - load spills
          ]
          [#loadpos
            - reg_deallocs
            - reg_allocs
          ]
          [
            - reg_deallocs for load-only spills
            - reg_allocs for store-only spills
          ]
          [#instr
            - original instruction
          ]
          [
            - store spills
            - reg_deallocs store spills
          ]
          [#storepos
          ]
        }

        result := true;
        oldlive_registers.copyfrom(live_registers);

        { Process all tai_regallocs belonging to this instruction, ignore explicit
          inserted regallocs. These can happend for example in i386:
             mov ref,ireg26
             <regdealloc ireg26, instr=taicpu of lea>
             <regalloc edi, insrt=nil>
             lea [ireg26+ireg17],edi
          All released registers are also added to the live_registers because
          they can't be used during the spilling }
        loadpos:=tai(instr.previous);
        while assigned(loadpos) and
              (loadpos.typ=ait_regalloc) and
              ((tai_regalloc(loadpos).instr=nil) or
               (tai_regalloc(loadpos).instr=instr)) do
          begin
            { Only add deallocs belonging to the instruction. Explicit inserted deallocs
              belong to the previous instruction and not the current instruction }
            if (tai_regalloc(loadpos).instr=instr) and
               (tai_regalloc(loadpos).ratype=ra_dealloc) then
              live_registers.add(getsupreg(tai_regalloc(loadpos).reg));
            loadpos:=tai(loadpos.previous);
          end;
        loadpos:=tai(loadpos.next);

        { Load the spilled registers }
        for counter := 0 to pred(regindex) do
          with regs[counter] do
            begin
              if mustbespilled and regread then
                begin
                  tempreg:=getregisterinline(list,regs[counter].spillregconstraints);
                  do_spill_read(list,tai(loadpos.previous),spilltemplist[orgreg],tempreg);
                end;
            end;

        { Release temp registers of read-only registers, and add reference of the instruction
          to the reginfo }
        for counter := 0 to pred(regindex) do
          with regs[counter] do
            begin
              if mustbespilled and regread and (not regwritten) then
                begin
                  { The original instruction will be the next that uses this register

                    set weigth of the newly allocated register higher than the old one,
                    so it will selected for spilling with a lower priority than
                    the original one, this prevents an endless spilling loop if orgreg
                    is short living, see e.g. tw25164.pp }
                  add_reg_instruction(instr,tempreg,reginfo[orgreg].weight+1);
                  ungetregisterinline(list,tempreg);
                end;
            end;

        { Allocate temp registers of write-only registers, and add reference of the instruction
          to the reginfo }
        for counter := 0 to pred(regindex) do
          with regs[counter] do
            begin
              if mustbespilled and regwritten then
                begin
                  { When the register is also loaded there is already a register assigned }
                  if (not regread) then
                    tempreg:=getregisterinline(list,regs[counter].spillregconstraints);
                  { The original instruction will be the next that uses this register, this
                    also needs to be done for read-write registers,

                    set weigth of the newly allocated register higher than the old one,
                    so it will selected for spilling with a lower priority than
                    the original one, this prevents an endless spilling loop if orgreg
                    is short living, see e.g. tw25164.pp }
                  add_reg_instruction(instr,tempreg,reginfo[orgreg].weight+1);
                end;
            end;

        { store the spilled registers }
        storepos:=tai(instr.next);
        for counter := 0 to pred(regindex) do
          with regs[counter] do
            begin
              if mustbespilled and regwritten then
                begin
                  do_spill_written(list,tai(storepos.previous),spilltemplist[orgreg],tempreg);
                  ungetregisterinline(list,tempreg);
                end;
            end;

        { now all spilling code is generated we can restore the live registers. This
          must be done after the store because the store can need an extra register
          that also needs to conflict with the registers of the instruction }
        live_registers.done;
        live_registers:=oldlive_registers;

        { substitute registers }
        for counter:=0 to instr.ops-1 do
          with instr.oper[counter]^ do
            case typ of
              top_reg:
                begin
                  if (getregtype(reg) = regtype) then
                    tryreplacereg(reg);
                end;
              top_ref:
                begin
                  if regtype in [R_INTREGISTER,R_ADDRESSREGISTER] then
                    begin
                      if (ref^.base <> NR_NO) and
                          (getregtype(ref^.base)=regtype) then
                        tryreplacereg(ref^.base);
                      if (ref^.index <> NR_NO) and
                          (getregtype(ref^.index)=regtype) then
                        tryreplacereg(ref^.index);
{$if defined(x86)}
                      if (ref^.segment <> NR_NO) and
                          (getregtype(ref^.segment)=regtype) then
                        tryreplacereg(ref^.segment);
{$endif defined(x86)}
                    end;
                end;
{$ifdef ARM}
              top_shifterop:
                begin
                  if regtype in [R_INTREGISTER,R_ADDRESSREGISTER] then
                    tryreplacereg(shifterop^.rs);
                end;
{$endif ARM}
            end;
         {We have modified the instruction; perhaps the new instruction has
          certain constraints regarding which imaginary registers interfere
          with certain physical registers.}
         add_cpu_interferences(instr);
      end;

end.
