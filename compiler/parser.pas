{
    $Id$
    Copyright (c) 1993-98 by Florian Klaempfl

    This unit does the parsing process

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
{$ifdef tp}
  {$E+,N+,D+,F+}
{$endif}
unit parser;

  interface

    procedure compile(const filename:string;compile_system:boolean);
    procedure initparser;

  implementation

    uses
      systems,cobjects,globals,verbose,
      symtable,files,aasm,hcodegen,
      assemble,link,script,gendef,
{$ifdef UseBrowser}
      browser,
{$endif UseBrowser}
      scanner,pbase,pdecl,psystem,pmodules;


    procedure initparser;
      begin
         forwardsallowed:=false;

         { ^M means a string or a char, because we don't parse a }
         { type declaration                                      }
         ignore_equal:=false;

         { we didn't parse a object or class declaration }
         { and no function header                        }
         testcurobject:=0;

         { a long time, this was forgotten }
         aktprocsym:=nil;

         current_module:=nil;

         loaded_units.init;

         usedunits.init;

         { memory sizes }
         if heapsize=0 then
          heapsize:=target_info.heapsize;
         if stacksize=0 then
          stacksize:=target_info.stacksize;
      end;


    procedure default_macros;
      var
        hp : pstring_item;
      begin
      { commandline }
        hp:=pstring_item(initdefines.first);
        while assigned(hp) do
         begin
           def_macro(hp^.str^);
           hp:=pstring_item(hp^.next);
         end;
      { set macros for version checking }
        set_macro('FPC_VERSION',version_nr);
        set_macro('FPC_RELEASE',release_nr);
        set_macro('FPC_PATCH',patch_nr);
      end;


    procedure compile(const filename:string;compile_system:boolean);
      var
       { scanner }
         oldtoken       : ttoken;
         oldtokenpos    : tfileposinfo;
         oldc           : char;
         oldpattern,
         oldorgpattern  : string;
         old_block_type : tblock_type;
         oldcurrent_scanner : pscannerfile;
       { symtable }
         oldmacros,
         oldrefsymtable,
         oldsymtablestack : psymtable;
         oldprocprefix    : string;
         oldaktprocsym    : pprocsym;
       { cg }
         oldnextlabelnr : longint;
         oldparse_only  : boolean;
       { asmlists }
         oldimports,
         oldexports,
         oldresource,
         oldrttilist,
         oldbsssegment,
         olddatasegment,
         oldcodesegment,
         oldexprasmlist,
         olddebuglist,
         oldinternals,
         oldexternals,
         oldconsts     : paasmoutput;
       { akt.. things }
         oldaktswitches     : tcswitches;
         oldaktfilepos      : tfileposinfo;
         oldaktpackrecords  : word;
         oldaktoutputformat : tasm;
         oldaktoptprocessor : tprocessors;
         oldaktasmmode      : tasmmode;

      label
         done;

      begin
         inc(compile_level);
       { save symtable state }
         oldsymtablestack:=symtablestack;
         oldrefsymtable:=refsymtable;
         oldmacros:=macros;
         oldprocprefix:=procprefix;
         oldaktprocsym:=aktprocsym;
       { save scanner state }
         oldc:=c;
         oldpattern:=pattern;
         oldorgpattern:=orgpattern;
         oldtoken:=token;
         old_block_type:=block_type;
         oldtokenpos:=tokenpos;
         oldcurrent_scanner:=current_scanner;
       { save cg }
         oldnextlabelnr:=nextlabelnr;
         oldparse_only:=parse_only;
       { save assembler lists }
         olddatasegment:=datasegment;
         oldbsssegment:=bsssegment;
         oldcodesegment:=codesegment;
         olddebuglist:=debuglist;
         oldexternals:=externals;
         oldinternals:=internals;
         oldconsts:=consts;
         oldrttilist:=rttilist;
         oldexprasmlist:=exprasmlist;
         oldimports:=importssection;
         oldexports:=exportssection;
         oldresource:=resourcesection;
       { save akt... state }
         oldaktswitches:=aktswitches;
         oldaktpackrecords:=aktpackrecords;
         oldaktoutputformat:=aktoutputformat;
         oldaktoptprocessor:=aktoptprocessor;
         oldaktasmmode:=aktasmmode;
         oldaktfilepos:=aktfilepos;

       { show info }
         Message1(parser_i_compiling,filename);

       { reset symtable }
         symtablestack:=nil;
         refsymtable:=nil;
         procprefix:='';
         aktprocsym:=nil;
         { macros }
         macros:=new(psymtable,init(macrosymtable));
         macros^.name:=stringdup('Conditionals for '+filename);
         default_macros;

       { reset the unit or create a new program }
         if assigned(current_module) then
          begin
            current_module^.sourcefiles.done;
            current_module^.sourcefiles.init;
            current_module^.used_units.done;
            current_module^.used_units.init;
          end
         else
          begin
            current_module:=new(pmodule,init(filename,false));
            main_module:=current_module;
          end;

       { Load current state from the init values }
         aktswitches:=initswitches;
         aktpackrecords:=initpackrecords;
         aktoutputformat:=initoutputformat;
         aktoptprocessor:=initoptprocessor;
         aktasmmode:=initasmmode;
         { we need this to make the system unit }
         if compile_system then
          aktswitches:=aktswitches+[cs_compilesystem];

       { startup scanner }
         current_scanner:=new(pscannerfile,Init(filename));
         token:=current_scanner^.yylex;
         { global switches are read, so further changes aren't allowed }
         current_module^.in_main:=true;

       { init code generator for a new module }
         codegen_newmodule;
{$ifdef GDB}
         reset_gdb_info;
{$endif GDB}

       { Handle things which need to be once }
         if (compile_level=1) then
          begin
          { open assembler response }
            AsmRes.Init('ppas');
          end;

         { load system unit always }
         loadsystemunit;

         registerdef:=true;
         make_ref:=true;

         { current return type is void }
         procinfo.retdef:=voiddef;

         { reset lexical level }
         lexlevel:=0;

         { parse source }
         if (token=_UNIT) or (compile_level>1) then
           begin
             current_module^.is_unit:=true;
           { If the compile level > 1 we get a nice "unit expected" error
             message if we are trying to use a program as unit.}
             proc_unit;
             if current_module^.compiled then
               goto done;
           end
         else
           begin
             proc_program(token=_LIBRARY);
           end;

         if status.errorcount=0 then
           begin
             GenerateAsm(filename);

             if (cs_smartlink in aktswitches) then
              begin
                Linker.SetLibName(current_module^.libfilename^);
                Linker.MakeStaticLibrary(SmartLinkPath(FileName),SmartLinkFilesCnt);
              end;

           { add the files for the linker from current_module, this must be
             after the makestaticlibrary, because it will add the library
             name (PFV) }
             addlinkerfiles(current_module);

           { Check linking  => we are at first level in compile }
             if (compile_level=1) then
              begin
                if gendeffile then
                 deffile.writefile;
                if (not current_module^.is_unit) then
                 begin
                   if (cs_no_linking in initswitches) then
                     externlink:=true;
                   if Linker.ExeName='' then
                     Linker.SetExeName(FileName);
                   Linker.MakeExecutable;
                 end;
              end;
           end
         else
           Message1(unit_f_errors_in_unit,tostr(status.errorcount));
done:
         { clear memory }
{$ifdef Splitheap}
         if testsplit then
           begin
           { temp heap should be empty after that !!!}
             codegen_donemodule;
             Releasetempheap;
           end;
{$endif Splitheap}

         { restore old state, close trees }
{$ifndef go32v2}
  {$ifndef linux}
         if dispose_asm_lists then
  {$endif}
{$endif}
           codegen_donemodule;

{$ifdef GDB}
         reset_gdb_info;
{$endif GDB}

       { free ppu }
         if assigned(current_module^.ppufile) then
          begin
            dispose(current_module^.ppufile,done);
            current_module^.ppufile:=nil;
          end;
       { free scanner }
         dispose(current_scanner,done);
       { free macros }
{!!! No check for unused macros yet !!! }
         dispose(macros,done);

       { restore scanner }
         c:=oldc;
         pattern:=oldpattern;
         orgpattern:=oldorgpattern;
         token:=oldtoken;
         tokenpos:=oldtokenpos;
         block_type:=old_block_type;
         current_scanner:=oldcurrent_scanner;
       { restore cg }
         nextlabelnr:=oldnextlabelnr;
         parse_only:=oldparse_only;
       { restore asmlists }
         exprasmlist:=oldexprasmlist;
         datasegment:=olddatasegment;
         bsssegment:=oldbsssegment;
         codesegment:=oldcodesegment;
         consts:=oldconsts;
         debuglist:=olddebuglist;
         externals:=oldexternals;
         internals:=oldinternals;
         importssection:=oldimports;
         exportssection:=oldexports;
         resourcesection:=oldresource;
         rttilist:=oldrttilist;
       { restore symtable state }
         if (compile_level>1) then
           begin
             refsymtable:=oldrefsymtable;
             symtablestack:=oldsymtablestack;
           end;
         macros:=oldmacros;
         aktprocsym:=oldaktprocsym;
         procprefix:=oldprocprefix;
       { restore current state }
         aktswitches:=oldaktswitches;
         aktpackrecords:=oldaktpackrecords;
         aktoutputformat:=oldaktoutputformat;
         aktoptprocessor:=oldaktoptprocessor;
         aktasmmode:=oldaktasmmode;
         aktfilepos:=oldaktfilepos;

       { Shut down things when the last file is compiled }
         if (compile_level=1) then
          begin
          { Close script }
            if (not AsmRes.Empty) then
             begin
               Message1(exec_i_closing_script,AsmRes.Fn);
               AsmRes.WriteToDisk;
             end;
{$ifdef UseBrowser}
          { Write Browser }
            if cs_browser in initswitches then
             begin
               Message1(parser_i_writing_browser_log,Browse.Fname);
               Browse.CreateLog;
               write_browser_log;
               Browse.CloseLog;
             end;
{$endif UseBrowser}
          end;

         dec(compile_level);
      end;

end.
{
  $Log$
  Revision 1.31  1998-07-14 21:46:46  peter
    * updated messages file

  Revision 1.30  1998/07/14 14:46:49  peter
    * released NEWINPUT

  Revision 1.29  1998/07/07 11:19:59  peter
    + NEWINPUT for a better inputfile and scanner object

  Revision 1.28  1998/06/25 11:15:33  pierre
    * ppu files where not closed in newppu !!
      second compilation was impossible due to too many opened files
      (not visible in 'make cycle' as we remove all the ppu files)

  Revision 1.27  1998/06/17 14:10:15  peter
    * small os2 fixes
    * fixed interdependent units with newppu (remake3 under linux works now)

  Revision 1.26  1998/06/16 08:56:23  peter
    + targetcpu
    * cleaner pmodules for newppu

  Revision 1.25  1998/06/15 15:38:07  pierre
    * small bug in systems.pas corrected
    + operators in different units better hanlded

  Revision 1.24  1998/06/13 00:10:08  peter
    * working browser and newppu
    * some small fixes against crashes which occured in bp7 (but not in
      fpc?!)

  Revision 1.23  1998/06/08 22:59:48  peter
    * smartlinking works for win32
    * some defines to exclude some compiler parts

  Revision 1.22  1998/06/05 17:47:28  peter
    * some better uses clauses

  Revision 1.21  1998/06/04 23:51:49  peter
    * m68k compiles
    + .def file creation moved to gendef.pas so it could also be used
      for win32

  Revision 1.20  1998/06/03 22:48:55  peter
    + wordbool,longbool
    * rename bis,von -> high,low
    * moved some systemunit loading/creating to psystem.pas

  Revision 1.19  1998/05/27 19:45:04  peter
    * symtable.pas splitted into includefiles
    * symtable adapted for $ifdef NEWPPU

  Revision 1.18  1998/05/23 01:21:15  peter
    + aktasmmode, aktoptprocessor, aktoutputformat
    + smartlink per module $SMARTLINK-/+ (like MMX) and moved to aktswitches
    + $LIBNAME to set the library name where the unit will be put in
    * splitted cgi386 a bit (codeseg to large for bp7)
    * nasm, tasm works again. nasm moved to ag386nsm.pas

  Revision 1.17  1998/05/20 09:42:34  pierre
    + UseTokenInfo now default
    * unit in interface uses and implementation uses gives error now
    * only one error for unknown symbol (uses lastsymknown boolean)
      the problem came from the label code !
    + first inlined procedures and function work
      (warning there might be allowed cases were the result is still wrong !!)
    * UseBrower updated gives a global list of all position of all used symbols
      with switch -gb

  Revision 1.16  1998/05/12 10:47:00  peter
    * moved printstatus to verb_def
    + V_Normal which is between V_Error and V_Warning and doesn't have a
      prefix like error: warning: and is included in V_Default
    * fixed some messages
    * first time parameter scan is only for -v and -T
    - removed old style messages

  Revision 1.15  1998/05/11 13:07:54  peter
    + $ifdef NEWPPU for the new ppuformat
    + $define GDB not longer required
    * removed all warnings and stripped some log comments
    * no findfirst/findnext anymore to remove smartlink *.o files

  Revision 1.14  1998/05/06 18:36:53  peter
    * tai_section extended with code,data,bss sections and enumerated type
    * ident 'compiled by FPC' moved to pmodules
    * small fix for smartlink

  Revision 1.13  1998/05/06 08:38:42  pierre
    * better position info with UseTokenInfo
      UseTokenInfo greatly simplified
    + added check for changed tree after first time firstpass
      (if we could remove all the cases were it happen
      we could skip all firstpass if firstpasscount > 1)
      Only with ExtDebug

  Revision 1.12  1998/05/04 17:54:28  peter
    + smartlinking works (only case jumptable left todo)
    * redesign of systems.pas to support assemblers and linkers
    + Unitname is now also in the PPU-file, increased version to 14

  Revision 1.11  1998/05/01 16:38:45  florian
    * handling of private and protected fixed
    + change_keywords_to_tp implemented to remove
      keywords which aren't supported by tp
    * break and continue are now symbols of the system unit
    + widestring, longstring and ansistring type released

  Revision 1.10  1998/05/01 07:43:56  florian
    + basics for rtti implemented
    + switch $m (generate rtti for published sections)

  Revision 1.9  1998/04/30 15:59:40  pierre
    * GDB works again better :
      correct type info in one pass
    + UseTokenInfo for better source position
    * fixed one remaining bug in scanner for line counts
    * several little fixes

  Revision 1.8  1998/04/29 10:33:55  pierre
    + added some code for ansistring (not complete nor working yet)
    * corrected operator overloading
    * corrected nasm output
    + started inline procedures
    + added starstarn : use ** for exponentiation (^ gave problems)
    + started UseTokenInfo cond to get accurate positions

  Revision 1.7  1998/04/27 23:10:28  peter
    + new scanner
    * $makelib -> if smartlink
    * small filename fixes pmodule.setfilename
    * moved import from files.pas -> import.pas

  Revision 1.6  1998/04/21 10:16:48  peter
    * patches from strasbourg
    * objects is not used anymore in the fpc compiled version

  Revision 1.5  1998/04/10 14:41:43  peter
    * removed some Hints
    * small speed optimization for AsmLn

  Revision 1.4  1998/04/08 16:58:03  pierre
    * several bugfixes
      ADD ADC and AND are also sign extended
      nasm output OK (program still crashes at end
      and creates wrong assembler files !!)
      procsym types sym in tdef removed !!

  Revision 1.3  1998/04/07 22:45:04  florian
    * bug0092, bug0115 and bug0121 fixed
    + packed object/class/array
}


