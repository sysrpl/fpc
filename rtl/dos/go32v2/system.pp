{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 1993,97 by the Free Pascal development team.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{ no stack check in system }
{$S-}
unit system;

{$I os.inc}

  interface

    { include system-independent routine headers }

    {$I systemh.inc}

    {$I heaph.inc}

    var
       mem  : array[0..$7fffffff] of byte absolute $0;
       memw : array[0..$7fffffff] of word absolute $0;
       meml : array[0..$7fffffff] of longint absolute $0;

const
  UnusedHandle=$ffff;
  StdInputHandle=0;
  StdOutputHandle=1;
  StdErrorHandle=2;

type
       t_stub_info   = record
       magic         : array[0..15] of char;
       size          : longint;
       minstack      : longint;
       memory_handle : longint;
       initial_size  : longint;
       minkeep       : word;
       ds_selector   : word;
       ds_segment    : word;
       psp_selector  : word;
       cs_selector   : word;
       env_size      : word;
       basename      : array[0..7] of char;
       argv0         : array [0..15] of char;
       dpmi_server   : array [0..15] of char;
       end;
       p_stub_info   = ^t_stub_info;

    var    stub_info : p_stub_info;

{$PACKRECORDS 1}
type
       t_go32_info_block = record
       size_of_this_structure_in_bytes : longint; {offset 0}
       linear_address_of_primary_screen : longint; {offset 4}
       linear_address_of_secondary_screen : longint; {offset 8}
       linear_address_of_transfer_buffer : longint; {offset 12}
       size_of_transfer_buffer : longint; {offset 16}
       pid : longint; {offset 20}
       master_interrupt_controller_base : byte; {offset 24}
       slave_interrupt_controller_base : byte; {offset 25}
       selector_for_linear_memory : word; {offset 26}
       linear_address_of_stub_info_structure : longint; {offset 28}
       linear_address_of_original_psp : longint; {offset 32}
       run_mode : word; {offset 36}
       run_mode_info : word; {offset 38}
       end;

var go32_info_block : t_go32_info_block;

    type
       trealregs=record
          realedi,realesi,realebp,realres,
          realebx,realedx,realecx,realeax : longint;
          realflags,
          reales,realds,realfs,realgs,
          realip,realcs,realsp,realss : word;
       end;
var
         dos_argv0 : pchar;
         environ : ppchar;

    function do_write(h,addr,len : longint) : longint;
    function do_read(h,addr,len : longint) : longint;
    procedure syscopyfromdos(addr : longint; len : longint);
    procedure syscopytodos(addr : longint; len : longint);
    function tb : longint;
    procedure sysrealintr(intnr : word;var regs : trealregs);

  implementation

    { include system independent routines }

    {$I system.inc}

    type
       plongint = ^longint;

    const carryflag = 1;

    var
      Win95 : boolean;  {Running under Win95?}

{$S-}
    procedure st1(stack_size : longint);[public,alias: 'STACKCHECK'];

      begin
         { called when trying to get local stack }
         { if the compiler directive $S is set   }
         { this function must preserve esi !!!!  }
         { because esi is set by the calling     }
         { proc for methods                      }
         { it must preserve all registers !!     }

         asm
            pushl %eax
            pushl %ebx
            movl stack_size,%ebx
            movl %esp,%eax
            subl %ebx,%eax
{$ifdef SYSTEMDEBUG}
            movl U_SYSTEM_LOWESTSTACK,%ebx
            cmpl %eax,%ebx
            jb   _is_not_lowest
            movl %eax,U_SYSTEM_LOWESTSTACK
            _is_not_lowest:
{$endif SYSTEMDEBUG}
            movl __stkbottom,%ebx
            cmpl %eax,%ebx
            jae  __short_on_stack
            popl %ebx
            popl %eax
            leave
            ret  $4
            __short_on_stack:
            { can be usefull for error recovery !! }
            popl %ebx
            popl %eax
         end['EAX','EBX'];
         RunError(202);
         { this needs a local variable }
         { so the function called itself !! }
         { Writeln('low in stack ');
         RunError(202);             }
      end;

    function tb : longint;
    begin
    tb := go32_info_block.linear_address_of_transfer_buffer;
    {   asm
       leal __go32_info_block,%ebx
       movl 12(%ebx),%eax
       leave
       ret
       end ['EAX','EBX'];}
    end;

    function tb_size : longint;
    begin
    tb_size := go32_info_block.size_of_transfer_buffer;
{       asm
       leal __go32_info_block,%ebx
       movl 16(%ebx),%eax
       leave
       ret
       end ['EAX','EBX'];}
    end;

    function dos_selector : word;
    begin
       dos_selector:=go32_info_block.selector_for_linear_memory;
{       asm
       leal __go32_info_block,%ebx
       movw 26(%ebx),%ax
       movw %ax,__RESULT
       end ['EAX','EBX'];}
    end;

    function get_ds : word;

      begin
         asm
            movw %ds,%ax
            movw %ax,__RESULT;
         end;
      end;


    procedure sysseg_move(sseg : word;source : longint;dseg : word;dest : longint;count : longint);

      begin
         if count=0 then
           exit;
         if (sseg<>dseg) or ((sseg=dseg) and (source>dest)) then
           asm
              pushw %es
              pushw %ds
              cld
              movl count,%ecx
              movl source,%esi
              movl dest,%edi
              movw dseg,%ax
              movw %ax,%es
              movw sseg,%ax
              movw %ax,%ds
              movl %ecx,%eax
              shrl $2,%ecx
              rep
              movsl
              movl %eax,%ecx
              andl $3,%ecx
              rep
              movsb
              popw %ds
              popw %es
           end ['ESI','EDI','ECX','EAX']
         else if (source<dest) then
           { copy backward for overlapping }
           asm
              pushw %es
              pushw %ds
              std
              movl count,%ecx
              movl source,%esi
              movl dest,%edi
              movw dseg,%ax
              movw %ax,%es
              movw sseg,%ax
              movw %ax,%ds
              addl %ecx,%esi
              addl %ecx,%edi
              movl %ecx,%eax
              andl $3,%ecx
              orl %ecx,%ecx
              jz .LSEG_MOVE1

              { calculate esi and edi}
              decl %esi
              decl %edi
              rep
              movsb
              incl %esi
              incl %edi
           .LSEG_MOVE1:
              subl $4,%esi
              subl $4,%edi
              movl %eax,%ecx
              shrl $2,%ecx
              rep
              movsl
              cld
              popw %ds
              popw %es
           end ['ESI','EDI','ECX'];
      end;


{ included directly old file sargs.inc }

var argc : longint;
    doscmd : string;
    args : ^pchar;

function far_strlen(selector : word;linear_address : longint) : longint;
begin
asm
        movl linear_address,%edx
        movl %edx,%ecx
        movw selector,%gs
.Larg19:
        movb %gs:(%edx),%al
        testb %al,%al
        je .Larg20
        incl %edx
        jmp .Larg19
.Larg20:
        movl %edx,%eax
        subl %ecx,%eax
        movl %eax,__RESULT
end;
end;

function atohex(s : pchar) : longint;
var rv : longint;
    v : byte;
begin
rv := 0;
while (s^ <>#0) do
  begin
  v := ord(s^) - ord('0');
  if (v > 9) then v := v - 7;
  v := v and 15; { in case it's lower case }
  rv := rv*16 + v;
  inc(longint(s));
  end;
atohex := rv;
end;

procedure setup_arguments;
type  arrayword = array [0..0] of word;
var psp : word;
    i,j : byte;
    quote : char;
    proxy_s : string[7];
    al,proxy_argc,proxy_seg,proxy_ofs,lin : longint;
    largs : array[0..127] of pchar;
    rm_argv : ^arrayword;
begin
for i := 1 to 127  do
   largs[i] := nil;
psp:=stub_info^.psp_selector;
largs[0]:=dos_argv0;
argc := 1;
sysseg_move(psp, 128, get_ds, longint(@doscmd), 128);
{$IfDef SYSTEMDEBUG}
Writeln('Dos command line is #',doscmd,'# size = ',length(doscmd));
{$EndIf SYSTEMDEBUG}
j := 1;
quote := #0;
for i:=1 to length(doscmd) do
  Begin
  if doscmd[i] = quote then
    begin
    quote := #0;
    doscmd[i] := #0;
    largs[argc]:=@doscmd[j];
    inc(argc);
    j := i+1;
    end else
  if (quote = #0) and ((doscmd[i] = '''') or (doscmd[i]='"')) then
    begin
    quote := doscmd[i];
    j := i + 1;
    end else
  if (quote = #0) and ((doscmd[i] = ' ')
    or (doscmd[i] = #9) or (doscmd[i] = #10) or
    (doscmd[i] = #12) or (doscmd[i] = #9)) then
    begin
    doscmd[i]:=#0;
    if j<i then
      begin
      largs[argc]:=@doscmd[j];
      inc(argc);
      j := i+1;
      end else inc(j);
    end else
  if (i = length(doscmd)) then
    begin
    doscmd[i+1]:=#0;
    largs[argc]:=@doscmd[j];
    inc(argc);
    end;
  end;

if (argc > 1) and (far_strlen(get_ds,longint(largs[1])) = 6)  then
  begin
  move(largs[1]^,proxy_s[1],6);
  proxy_s[0] := #6;
  if (proxy_s = '!proxy') then
    begin
{$IfDef SYSTEMDEBUG}
    Writeln('proxy command line ');
{$EndIf SYSTEMDEBUG}
    proxy_argc := atohex(largs[2]);
    proxy_seg  := atohex(largs[3]);
    proxy_ofs := atohex(largs[4]);
    getmem(rm_argv,proxy_argc*sizeof(word));
    sysseg_move(dos_selector,proxy_seg*16+proxy_ofs, get_ds,longint(rm_argv),proxy_argc*sizeof(word));
    for i:=0 to proxy_argc - 1 do
      begin
      lin := proxy_seg*16 + rm_argv^[i];
      al :=far_strlen(dos_selector, lin);
      getmem(largs[i],al+1);
      sysseg_move(dos_selector, lin, get_ds,longint(largs[i]), al+1);
{$IfDef SYSTEMDEBUG}
      Writeln('arg ',i,' #',largs[i],'#');
{$EndIf SYSTEMDEBUG}
      end;
    argc := proxy_argc;
    end;
  end;
getmem(args,argc*SizeOf(pchar));
for i := 0 to argc-1  do
   args[i] := largs[i];
  asm
     movl _ARGS,%eax
     movl %eax,_args
  end;
end;

function strcopy(dest,source : pchar) : pchar;

      begin
         asm
            cld
            movl 12(%ebp),%edi
            movl $0xffffffff,%ecx
            xorb %al,%al
            repne
            scasb
            not %ecx
            movl 8(%ebp),%edi
            movl 12(%ebp),%esi
            movl %ecx,%eax
            shrl $2,%ecx
            rep
            movsl
            movl %eax,%ecx
            andl $3,%ecx
            rep
            movsb
            movl 8(%ebp),%eax
            leave
            ret $8
         end;
      end;


procedure setup_environment;
var env_selector : word;
    env_count : longint;
    dos_env,cp : pchar;
    stubaddr : p_stub_info;
begin
   asm
   movl __stubinfo,%eax
   movl %eax,stubaddr
   end;
   stub_info:=stubaddr;
   getmem(dos_env,stub_info^.env_size);
   env_count:=0;
   sysseg_move(stub_info^.psp_selector,$2c, get_ds, longint(@env_selector), 2);
   sysseg_move(env_selector, 0, get_ds, longint(dos_env), stub_info^.env_size);
  cp:=dos_env;
  while cp ^ <> #0 do
    begin
    inc(env_count);
    while (cp^ <> #0) do inc(longint(cp)); { skip to NUL }
    inc(longint(cp)); { skip to next character }
    end;
  getmem(environ,(env_count+1) * sizeof(pchar));
  if (environ = nil) then exit;
  cp:=dos_env;
  env_count:=0;
  while cp^ <> #0 do
    begin
    getmem(environ[env_count],strlen(cp)+1);
    strcopy(environ[env_count], cp);
{$IfDef SYSTEMDEBUG}
      Writeln('env ',env_count,' = "',environ[env_count],'"');
{$EndIf SYSTEMDEBUG}
    inc(env_count);
    while (cp^ <> #0) do inc(longint(cp)); { skip to NUL }
    inc(longint(cp)); { skip to next character }
    end;
  environ[env_count]:=nil;
  inc(longint(cp),3);
  getmem(dos_argv0,strlen(cp)+1);
  if (dos_argv0 = nil) then halt;
  strcopy(dos_argv0, cp);
end;
     procedure syscopytodos(addr : longint; len : longint);
     begin
        if len > tb_size then runerror(200);
        sysseg_move(get_ds,addr,dos_selector,tb,len);
     end;

     procedure syscopyfromdos(addr : longint; len : longint);
     begin
        if len > tb_size then runerror(200);
        sysseg_move(dos_selector,tb,get_ds,addr,len);
     end;

    procedure sysrealintr(intnr : word;var regs : trealregs);

      begin
         regs.realsp:=0;
         regs.realss:=0;
         asm
            movw  intnr,%bx
            xorl  %ecx,%ecx
            movl  regs,%edi

            // es is always equal ds
            movw  $0x300,%ax
            int   $0x31
         end;
      end;

    procedure halt(errnum : byte);

    var regs : trealregs;
      begin
         do_exit;
         flush(stderr);
         {regs.realeax:=$4c00+errnum;
         sysrealintr($21,regs);}
         asm
         movzbw errnum,%ax
         pushw  %ax
         call   ___exit
         {call ___exit frees all dpmi memory !!}
         end;
      end;

    function paramcount : longint;

      begin
      paramcount := argc - 1;
      {   asm
            movl _argc,%eax
            decl %eax
            leave
            ret
         end ['EAX'];}
      end;

    function paramstr(l : longint) : string;

{      function args : pointer;

        begin
           asm
              movl _args,%eax
              leave
              ret
           end ['EAX'];
        end;}

      var
         p : ^pchar;

      begin
         if (l>=0) and (l<=paramcount) then
           begin
              p:=args;
              paramstr:=strpas(p[l]);
           end
         else paramstr:='';
      end;

    procedure randomize;

      var
         hl : longint;
         regs : trealregs;

      begin
         regs.realeax:=$2c00;
         sysrealintr($21,regs);
         hl:=regs.realedx and $ffff;
         randseed:=hl*$10000+ (regs.realecx and $ffff);
      end;

{ use standard heap management }

  function Sbrk(size : longint) : longint;

    begin
       asm
         movl size,%eax
         pushl %eax
         call ___sbrk
         addl $4,%esp
         movl %eax,__RESULT
       end;
    end;

{$i heap.inc}

{****************************************************************************
                        Low level File Routines
 ****************************************************************************}

procedure AllowSlash(p:pchar);
var
  i : longint;
begin
{ allow slash as backslash }
  for i:=0 to strlen(p) do
   if p[i]='/' then p[i]:='\';
end;


procedure do_close(handle : longint);
var
  regs : trealregs;
begin
  regs.realebx:=handle;
  regs.realeax:=$3e00;
  sysrealintr($21,regs);
end;


procedure do_erase(p : pchar);
var
  regs : trealregs;
begin
  AllowSlash(p);
  syscopytodos(longint(p),strlen(p)+1);
  regs.realedx:=tb and 15;
  regs.realds:=tb shr 4;
  if Win95 then
   regs.realeax:=$7141
  else
   regs.realeax:=$4100;
  regs.realesi:=0;
  regs.realecx:=0;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   InOutRes:=lo(regs.realeax);
end;


procedure do_rename(p1,p2 : pchar);
var
  regs : trealregs;
begin
  AllowSlash(p1);
  AllowSlash(p2);
  if strlen(p1)+strlen(p2)+3>tb_size then
   RunError(217);
  sysseg_move(get_ds,longint(p2),dos_selector,tb,strlen(p2)+1);
  sysseg_move(get_ds,longint(p1),dos_selector,tb+strlen(p2)+2,strlen(p1)+1);
  regs.realedi:=tb and 15;
  regs.realedx:=tb and 15 + strlen(p2)+2;
  regs.realds:=tb shr 4;
  regs.reales:=regs.realds;
  if Win95 then
   regs.realeax:=$7156
  else
   regs.realeax:=$5600;
  regs.realecx:=$ff;            { attribute problem here ! }
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   InOutRes:=lo(regs.realeax);
end;


function do_write(h,addr,len : longint) : longint;
var
  regs      : trealregs;
  size,
  writesize : longint;
begin
  writesize:=0;
  while len > 0 do
   begin
     if len>tb_size then
      size:=tb_size
     else
      size:=len;
     syscopytodos(addr+writesize,size);
     regs.realecx:=size;
     regs.realedx:=tb and 15;
     regs.realds:=tb shr 4;
     regs.realebx:=h;
     regs.realeax:=$4000;
     sysrealintr($21,regs);
     if (regs.realflags and carryflag) <> 0 then
      begin
        InOutRes:=lo(regs.realeax);
        exit(writesize);
      end;
     len:=len-size;
     writesize:=writesize+size;
   end;
  Do_Write:=WriteSize
end;


function do_read(h,addr,len : longint) : longint;
var
  regs     : trealregs;
  size,
  readsize : longint;
begin
  readsize:=0;
  while len > 0 do
   begin
     if len>tb_size then
      size:=tb_size
     else
      size:=len;
     regs.realecx:=size;
     regs.realedx:=tb and 15;
     regs.realds:=tb shr 4;
     regs.realebx:=h;
     regs.realeax:=$3f00;
     sysrealintr($21,regs);
     if (regs.realflags and carryflag) <> 0 then
      begin
        InOutRes:=lo(regs.realeax);
        do_read:=0;
        exit;
      end
     else
      if regs.realeax<size then
       begin
         syscopyfromdos(addr+readsize,regs.realeax);
         do_read:=readsize+regs.realeax;
         exit;
       end;
     syscopyfromdos(addr+readsize,regs.realeax);
     readsize:=readsize+regs.realeax;
     len:=len-regs.realeax;
   end;
  do_read:=readsize;
end;


function do_filepos(handle : longint) : longint;
var
  regs : trealregs;
begin
  regs.realebx:=handle;
  regs.realecx:=0;
  regs.realedx:=0;
  regs.realeax:=$4201;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   Begin
     InOutRes:=lo(regs.realeax);
     do_filepos:=0;
   end
  else
   do_filepos:=lo(regs.realedx) shl 16+lo(regs.realeax);
end;


procedure do_seek(handle,pos : longint);
var
  regs : trealregs;
begin
  regs.realebx:=handle;
  regs.realecx:=pos shr 16;
  regs.realedx:=pos and $ffff;
  regs.realeax:=$4200;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   InOutRes:=lo(regs.realeax);
end;



function do_seekend(handle:longint):longint;
var
  regs : trealregs;
begin
  regs.realebx:=handle;
  regs.realecx:=0;
  regs.realedx:=0;
  regs.realeax:=$4202;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   Begin
     InOutRes:=lo(regs.realeax);
     do_seekend:=0;
   end
  else
   do_seekend:=lo(regs.realedx) shl 16+lo(regs.realeax);
end;



function do_filesize(handle : longint) : longint;
var
  aktfilepos : longint;
begin
  aktfilepos:=do_filepos(handle);
  do_filesize:=do_seekend(handle);
  do_seek(handle,aktfilepos);
end;


procedure do_truncate (handle,pos:longint);
var
  regs : trealregs;
begin
  do_seek(handle,pos);
  regs.realecx:=0;
  regs.realedx:=tb and 15;
  regs.realds:=tb shr 4;
  regs.realebx:=handle;
  regs.realeax:=$4000;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   InOutRes:=lo(regs.realeax);
end;


procedure do_open(var f;p:pchar;flags:longint);
{
  filerec and textrec have both handle and mode as the first items so
  they could use the same routine for opening/creating.
  when (flags and $10)   the file will be append
  when (flags and $100)  the file will be truncate/rewritten
  when (flags and $1000) there is no check for close (needed for textfiles)
}
var
  regs   : trealregs;
  action : longint;
begin
  AllowSlash(p);
{ close first if opened }
  if ((flags and $1000)=0) then
   begin
     case filerec(f).mode of
      fminput,fmoutput,fminout : Do_Close(filerec(f).handle);
      fmclosed : ;
     else
      begin
        inoutres:=102; {not assigned}
        exit;
      end;
     end;
   end;
{ reset file handle }
  filerec(f).handle:=UnusedHandle;
  action:=$1;
{ convert filemode to filerec modes }
  case (flags and 3) of
   0 : filerec(f).mode:=fminput;
   1 : filerec(f).mode:=fmoutput;
   2 : filerec(f).mode:=fminout;
  end;
  if (flags and $100)<>0 then
   begin
     filerec(f).mode:=fmoutput;
     action:=$12; {create file function}
   end;
{ empty name is special }
  if p[0]=#0 then
   begin
     case filerec(f).mode of
       fminput : filerec(f).handle:=StdInputHandle;
      fmappend,
      fmoutput : begin
                   filerec(f).handle:=StdOutputHandle;
                   filerec(f).mode:=fmoutput; {fool fmappend}
                 end;
     end;
     exit;
   end;
{ real dos call }
  syscopytodos(longint(p),strlen(p)+1);
  if Win95 then
   regs.realeax:=$716c
  else
   regs.realeax:=$6c00;
  regs.realedx:=action;
  regs.realds:=tb shr 4;
  regs.realesi:=tb and 15;
  regs.realebx:=$2000+(flags and $ff);
  regs.realecx:=$20;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   begin
     InOutRes:=lo(regs.realeax);
     exit;
   end
  else
   filerec(f).handle:=regs.realeax;
{ append mode }
  if (flags and $10)<>0 then
   begin
     do_seekend(filerec(f).handle);
     filerec(f).mode:=fmoutput; {fool fmappend}
   end;
end;

{*****************************************************************************
                           UnTyped File Handling
*****************************************************************************}

{$i file.inc}

{*****************************************************************************
                           Typed File Handling
*****************************************************************************}

{$i typefile.inc}

{*****************************************************************************
                           Text File Handling
*****************************************************************************}

{$DEFINE EOF_CTRLZ}

{$i text.inc}

{*****************************************************************************
                           Directory Handling
*****************************************************************************}

procedure DosDir(func:byte;const s:string);
var
  buffer : array[0..255] of char;
  regs   : trealregs;
begin
  move(s[1],buffer,length(s));
  buffer[length(s)]:=#0;
  AllowSlash(pchar(@buffer));
  syscopytodos(longint(@buffer),length(s)+1);
  regs.realedx:=tb and 15;
  regs.realds:=tb shr 4;
  if Win95 then
   regs.realeax:=$7100+func
  else
   regs.realeax:=func shl 8;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   InOutRes:=lo(regs.realeax);
end;


procedure mkdir(const s : string);
begin
  DosDir($39,s);
end;


procedure rmdir(const s : string);
begin
  DosDir($3a,s);
end;


procedure chdir(const s : string);
begin
  DosDir($3b,s);
end;


procedure getdir(drivenr : byte;var dir : string);
var
  temp : array[0..255] of char;
  i    : longint;
  regs : trealregs;
begin
  regs.realedx:=drivenr;
  regs.realesi:=tb and 15;
  regs.realds:=tb shr 4;
  if Win95 then
   regs.realeax:=$7147
  else
   regs.realeax:=$4700;
  sysrealintr($21,regs);
  if (regs.realflags and carryflag) <> 0 then
   Begin
     InOutRes:=lo(regs.realeax);
     exit;
   end
  else
   syscopyfromdos(longint(@temp),251);
{ conversation to Pascal string }
  i:=0;
  while (temp[i]<>#0) do
   begin
     if temp[i]='/' then
      temp[i]:='\';
     dir[i+4]:=temp[i];
     inc(i);
   end;
  dir[2]:=':';
  dir[3]:='\';
  dir[0]:=chr(i+3);
{ upcase the string (FPKPascal function) }
  dir:=upcase(dir);
  if drivenr<>0 then   { Drive was supplied. We know it }
   dir[1]:=chr(65+drivenr-1)
  else
   begin
   { We need to get the current drive from DOS function 19H  }
   { because the drive was the default, which can be unknown }
     regs.realeax:=$1900;
     sysrealintr($21,regs);
     i:= (regs.realeax and $ff) + ord('A');
     dir[1]:=chr(i);
   end;
end;


{*****************************************************************************
                         SystemUnit Initialization
*****************************************************************************}

function CheckWin95:boolean;
var
  regs : TRealRegs;
begin
  regs.realeax:=$160a;
  sysrealintr($2f,regs);
  CheckWin95:=(regs.realeax=0) and ((regs.realebx and $ff00)=$400);
end;  


procedure OpenStdIO(var f:text;mode:word;hdl:longint);
begin
  Assign(f,'');
  TextRec(f).Handle:=hdl;
  TextRec(f).Mode:=mode;
  TextRec(f).InOutFunc:=@FileInOutFunc;
  TextRec(f).FlushFunc:=@FileInOutFunc;
  TextRec(f).Closefunc:=@fileclosefunc;
end;

     
Begin
{ Initialize ExitProc }
  ExitProc:=Nil;
{ to test stack depth }
  loweststack:=maxlongint;
{ Setup heap }
  InitHeap;
{ Setup stdin, stdout and stderr }
  OpenStdIO(Input,fmInput,StdInputHandle);
  OpenStdIO(Output,fmOutput,StdOutputHandle);
  OpenStdIO(StdErr,fmOutput,StdErrorHandle);
{ Setup environment and arguments }
  Setup_Environment;
  Setup_Arguments;
{ Use Win95 LFN }
  Win95:=CheckWin95;
{ Reset IO Error }  
  InOutRes:=0;
End.
{
  $Log$
  Revision 1.1  1998-03-25 11:18:42  root
  Initial revision

  Revision 1.18  1998/03/24 21:48:47  florian
    * extended to support mem*

  Revision 1.17  1998/02/06 18:10:21  pierre
    * replaced -1 by UnusedHandle (caused error)

  Revision 1.16  1998/01/28 22:56:02  peter
    + Win95 LFN Support
    * double log entries removed

  Revision 1.15  1998/01/26 11:57:21  michael
  + Added log at the end

  Revision 1.14  1998/01/25 21:53:23  peter
    + Universal Handles support for StdIn/StdOut/StdErr
    * Updated layout of sysamiga.pas

  Revision 1.13  1998/01/21 10:19:37  pierre
    * bug with _args not being set fixed
      version 1.12 removed (based on 1.8!!)

  Revision 1.11  1998/01/20 00:19:36  peter
    * uses now again the new rtl layout

  Revision 1.10  1998/01/19 09:14:17  michael
  * Getdir bug fixed (by Peter Vreman)

  Revision 1.9  1998/01/16 23:10:51  florian
    + some tobject stuff

  Revision 1.8  1998/01/16 16:54:23  pierre
    + logs added at end
    + dxeload and emu387 added in makefile
  
  revision 1.7
  date: 1998/01/11 02:47:32;  author: michael;  state: Exp;  lines: +390 -515
  * Changed files to use the new filestructure in /inc directory.
    (By Peter Vreman)
  ----------------------------
  revision 1.6
  date: 1998/01/07 09:11:03;  author: michael;  state: Exp;  lines: +14 -14
  Final adjustments for uniform file handling system (From Peter Vreman)
  ----------------------------
  revision 1.5
  date: 1998/01/06 00:29:31;  author: michael;  state: Exp;  lines: +92 -114
  Implemented a system independent sequence of reset/rewrite/append fileopenfunc etc system \n (from Peter Vreman)
  ----------------------------
  revision 1.4
  date: 1998/01/05 16:51:20;  author: michael;  state: Exp;  lines: +11 -33
  + Moved init of heap to heap.inc: INITheap() (From Peter Vreman)
  ----------------------------
  revision 1.3
  date: 1998/01/03 00:47:15;  author: michael;  state: Exp;  lines: +86 -96
  * Implemented a uniform file opening system. (From Peter Vreman)
  ----------------------------
  revision 1.2
  date: 1997/12/01 12:26:09;  author: michael;  state: Exp;  lines: +10 -5
  + added copyright reference in header.
  ----------------------------
  revision 1.1
  date: 1997/11/27 08:33:52;  author: michael;  state: Exp;
  Initial revision
  ----------------------------
  revision 1.1.1.1
  date: 1997/11/27 08:33:52;  author: michael;  state: Exp;  lines: +0 -0
  FPC RTL CVS start
  =============================================================================
}
