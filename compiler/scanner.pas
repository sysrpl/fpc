{
    $Id$
    Copyright (c) 1993,97 by Florian Klaempfl

    This unit implements the scanner part and handling of the switches

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
  {$F+,N+,E+,R-}
{$endif}
unit scanner;

  interface

    uses
       cobjects,globals,verbose,files;

    const
{$ifdef TP}
       maxmacrolen=1024;
       InputFileBufSize=1024;
{$else}
       maxmacrolen=16*1024;
       InputFileBufSize=32*1024;
{$endif}

       id_len = 14;
       Newline = #10;

    type
       ident = string[id_len];

    const
      max_keywords = 70;
      anz_keywords : longint = max_keywords;

      { the following keywords are no keywords in TP, they
        are internal procedures

      CONTINUE, DISPOSE, EXIT, FAIL, FALSE, NEW, SELF
      TRUE
      }
      { INLINE is a keyword in TP, but only an modifier in FPC }
      keyword : array[1..max_keywords] of ident = (
{        'ABSOLUTE',}
         'AND',
         'ARRAY','AS','ASM',
{        'ASSEMBLER',}
         'BEGIN',
         'CASE','CLASS',
         'CONST','CONSTRUCTOR',
         'DESTRUCTOR','DISPOSE','DIV','DO','DOWNTO','ELSE','END',
         'EXCEPT',
         'EXIT',
{        'EXPORT',}
         'EXPORTS',
{        'EXTERNAL',}
         'FAIL','FALSE',
{        'FAR',}
         'FILE','FINALIZATION','FINALLY','FOR',
{        'FORWARD',}
         'FUNCTION','GOTO','IF','IMPLEMENTATION','IN',
         'INHERITED','INITIALIZATION',
{        'INLINE',} {INLINE is a reserved word in TP. Why?}
         'INTERFACE',
{        'INTERRUPT',}
         'IS',
         'LABEL','LIBRARY','MOD',
{        'NEAR',}
         'NEW','NIL','NOT','OBJECT',
         'OF','ON','OPERATOR','OR','OTHERWISE','PACKED',
         'PROCEDURE','PROGRAM','PROPERTY',
         'RAISE','RECORD','REPEAT','SELF',
         'SET','SHL','SHR','STRING','THEN','TO',
         'TRUE','TRY','TYPE','UNIT','UNTIL',
         'USES','VAR',
{        'VIRTUAL',}
         'WHILE','WITH','XOR');

       keyword_token : array[1..max_keywords] of ttoken = (
{        _ABSOLUTE,}
         _AND,
         _ARRAY,_AS,_ASM,
{        _ASSEMBLER,}
         _BEGIN,
         _CASE,_CLASS,
         _CONST,_CONSTRUCTOR,
         _DESTRUCTOR,_DISPOSE,_DIV,_DO,_DOWNTO,
         _ELSE,_END,_EXCEPT,
         _EXIT,
{        _EXPORT,}
         _EXPORTS,
{        _EXTERNAL,}
         _FAIL,_FALSE,
{        _FAR,}
         _FILE,_FINALIZATION,_FINALLY,_FOR,
{        _FORWARD,}
         _FUNCTION,_GOTO,_IF,_IMPLEMENTATION,_IN,
         _INHERITED,_INITIALIZATION,
{        _INLINE,}
         _INTERFACE,
{        _INTERRUPT,}
         _IS,
         _LABEL,_LIBRARY,_MOD,
{        _NEAR,}
         _NEW,_NIL,_NOT,_OBJECT,
         _OF,_ON,_OPERATOR,_OR,_OTHERWISE,_PACKED,
         _PROCEDURE,_PROGRAM,_PROPERTY,
         _RAISE,_RECORD,_REPEAT,_SELF,
         _SET,_SHL,_SHR,_STRING,_THEN,_TO,
         _TRUE,_TRY,_TYPE,_UNIT,_UNTIL,
         _USES,_VAR,
{        _VIRTUAL,}
         _WHILE,_WITH,_XOR);

    type
       pmacrobuffer = ^tmacrobuffer;
       tmacrobuffer = array[0..maxmacrolen-1] of char;

       ppreprocstack = ^tpreprocstack;
       tpreprocstack = object
          accept  : boolean;
          next    : ppreprocstack;
          name    : stringid;
          line_nb : longint;
          constructor init(a:boolean;n:ppreprocstack);
          destructor done;
       end;

{$ifdef NEWINPUT}
       pscannerfile = ^tscannerfile;
       tscannerfile = object
          inputfile    : pinputfile; { current inputfile list }

          f            : file;       { current file handle }
          filenotatend,              { still bytes left to read }
          closed       : boolean;    { is the file closed }

          inputbufsize : longint;    { max size of the input buffer }

          inputbuffer,
          inputpointer : pchar;

          bufstart,
          bufidx,
          bufsize      : longint;

          line_no,
          lasttokenpos,
          lastlinepos  : longint;

          s_point        : boolean;
          comment_level,
          yylexcount     : longint;
          lastasmgetchar : char;
          preprocstack   : ppreprocstack;

          constructor init(const fn:string);
          destructor done;
        { File buffer things }
          function  open:boolean;
          procedure close;
          function  reopen:boolean;
          procedure readbuf;
          procedure saveinputfile;
          procedure restoreinputfile;
          procedure nextfile;
          procedure addfile(hp:pinputfile);
          procedure reload;
          procedure setbuf(p:pchar;l:longint);
        { Scanner things }
          procedure gettokenpos;
          procedure inc_comment_level;
          procedure dec_comment_level;
          procedure poppreprocstack;
          procedure addpreprocstack(a:boolean;const s:string;w:tmsgconst);
          procedure elsepreprocstack;
          procedure linebreak;
          procedure readchar;
          procedure readstring;
          procedure readnumber;
          function  readid:string;
          function  readval:longint;
          function  readcomment:string;
          procedure skipspace;
          procedure skipuntildirective;
          procedure skipcomment;
          procedure skipdelphicomment;
          procedure skipoldtpcomment;
          function  yylex:ttoken;
          function  readpreproc:ttoken;
          function  asmgetchar:char;
       end;
{$endif NEWINPUT}

    var
        c              : char;
        orgpattern,
        pattern        : string;
{$ifdef NEWINPUT}
        current_scanner : pscannerfile;
{$else}
        currlinepos,
        lastlinepos,
        lasttokenpos,
        inputbuffer,
        inputpointer   : pchar;
        s_point        : boolean;
        comment_level,
        yylexcount,
        macropos       : longint;
        lastasmgetchar : char;
        preprocstack   : ppreprocstack;
{$endif NEWINPUT}

{$ifndef NEWINPUT}
    procedure poppreprocstack;
    procedure addpreprocstack(a:boolean;const s:string;w:tmsgconst);
    procedure elsepreprocstack;
    procedure gettokenpos;
    function yylex : ttoken;
    function asmgetchar : char;
    { column position of last token }
    function get_current_col : longint;
    { column position of file }
    function get_file_col : longint;
    procedure get_cur_file_pos(var fileinfo : tfileposinfo);
    procedure set_cur_file_pos(const fileinfo : tfileposinfo);
    procedure InitScanner(const fn: string);
    procedure DoneScanner(testendif:boolean);
{$endif}

    { changes to keywords to be tp compatible }
    procedure change_to_tp_keywords;

implementation

    uses
      dos,systems,symtable,switches;

{*****************************************************************************
                              Helper routines
*****************************************************************************}

    function is_keyword(var token : ttoken) : boolean;
      var
         high,low,mid : longint;
      begin
         low:=1;
         high:=anz_keywords;
         while low<high do
          begin
            mid:=(high+low+1) shr 1;
            if pattern<keyword[mid] then
             high:=mid-1
            else
             low:=mid;
          end;
         if pattern=keyword[high] then
          begin
            token:=keyword_token[high];
            is_keyword:=true;
          end
         else
          is_keyword:=false;
      end;


    procedure remove_keyword(const s : string);
      var
         i,j : longint;
      begin
         for i:=1 to anz_keywords do
           begin
              if keyword[i]=s then
                begin
                   for j:=i to anz_keywords-1 do
                     begin
                        keyword[j]:=keyword[j+1];
                        keyword_token[j]:=keyword_token[j+1];
                     end;
                   dec(anz_keywords);
                   break;
                end;
           end;
      end;


    procedure change_to_tp_keywords;
      const
        non_tp : array[0..14] of string[id_len] = (
           'AS','CLASS','EXCEPT','FINALLY','INITIALIZATION','IS',
           'ON','OPERATOR','OTHERWISE','PROPERTY','RAISE','TRY',
           'EXPORTS','LIBRARY','FINALIZATION');
      var
        i : longint;
      begin
        for i:=0 to 13 do
         remove_keyword(non_tp[i]);
      end;


{$ifndef NEWINPUT}

    const
       current_column : longint = 1;

    function get_current_col : longint;

      begin
         get_current_col:=current_column;
      end;

    function get_file_col : longint;
      begin
        get_file_col:=lasttokenpos-lastlinepos;
      end;


    procedure inc_comment_level;
      begin
         inc(comment_level);
         if (comment_level>1) then
          Message1(scan_w_comment_level,tostr(comment_level));
      end;


    procedure dec_comment_level;
      begin
         if cs_tp_compatible in aktswitches then
           comment_level:=0
         else
           dec(comment_level);
      end;

{$endif NEWINPUT}


{*****************************************************************************
                              TPreProcStack
*****************************************************************************}

    constructor tpreprocstack.init(a:boolean;n:ppreprocstack);
      begin
        accept:=a;
        next:=n;
      end;


    destructor tpreprocstack.done;
      begin
      end;



{$ifdef NEWINPUT}

{****************************************************************************
                                TSCANNERFILE
 ****************************************************************************}

    constructor tscannerfile.init(const fn:string);
      begin
        inputfile:=new(pinputfile,init(fn));
        current_module^.sourcefiles.register_file(inputfile);
        current_module^.current_index:=inputfile^.ref_index;
      { reset scanner }
        preprocstack:=nil;
        comment_level:=0;
        s_point:=false;
        block_type:=bt_general;
      { reset buf }
        closed:=true;
        filenotatend:=true;
        inputbufsize:=InputFileBufSize;
        inputbuffer:=nil;
        inputpointer:=nil;
        bufstart:=0;
        bufsize:=0;
      { line }
        line_no:=0;
        lastlinepos:=0;
        lasttokenpos:=0;
      { load block }
        if not open then
         Message(scan_f_cannot_open_input);
        reload;
      end;


    destructor tscannerfile.done;
      begin
      { check for missing ifdefs }
        while assigned(preprocstack) do
         begin
           Message3(scan_e_endif_expected,'$IF(N)(DEF)',preprocstack^.name,tostr(preprocstack^.line_nb));
           poppreprocstack;
         end;
      { close file }
        if not closed then
         close;
      end;


    procedure tscannerfile.readbuf;
    {$ifdef TP}
      var
        w : word;
    {$endif}
      begin
        if closed then
         exit;
        inc(bufstart,bufsize);
      {$ifdef TP}
        blockread(f,inputbuffer^,inputbufsize-1,w);
        bufsize:=w;
      {$else}
        blockread(f,inputbuffer^,inputbufsize-1,bufsize);
      {$endif}
        inputbuffer[bufsize]:=#0;
        Filenotatend:=(bufsize=inputbufsize-1);
      end;


    function tscannerfile.open:boolean;
      var
        ofm : byte;
      begin
        open:=false;
        if not closed then
         exit;
        ofm:=filemode;
        filemode:=0;
        Assign(f,inputfile^.path^+inputfile^.name^);
        {$I-}
         reset(f,1);
        {$I+}
        filemode:=ofm;
        if ioresult<>0 then
         exit;
      { file }
        closed:=false;
        filenotatend:=true;
        Getmem(inputbuffer,inputbufsize);
        inputpointer:=inputbuffer;
        bufstart:=0;
        bufsize:=0;
      { line }
        line_no:=0;
        lastlinepos:=0;
        lasttokenpos:=0;
        open:=true;
      end;


    procedure tscannerfile.close;
      var
        i : word;
      begin
        inc(bufstart,inputpointer-inputbuffer);
        if not closed then
         begin
           {$I-}
            system.close(f);
           {$I+}
           i:=ioresult;
           Freemem(inputbuffer,InputFileBufSize);
           inputbuffer:=nil;
           inputpointer:=nil;
           closed:=true;
         end;
      end;


    function tscannerfile.reopen:boolean;
      var
        ofm : byte;
      begin
        reopen:=false;
        if not closed then
         exit;
        ofm:=filemode;
        filemode:=0;
        Assign(f,inputfile^.path^+inputfile^.name^);
        {$I-}
         reset(f,1);
        {$I+}
        filemode:=ofm;
        if ioresult<>0 then
         exit;
        closed:=false;
      { get new mem }
        Getmem(inputbuffer,inputbufsize);
        inputpointer:=inputbuffer;
      { restore state }
        seek(f,BufStart);
        bufsize:=0;
        readbuf;
        reopen:=true;
      end;


    procedure tscannerfile.saveinputfile;
      begin
        inputfile^.savebufstart:=bufstart;
        inputfile^.savebufsize:=bufsize;
        inputfile^.savelastlinepos:=lastlinepos;
        inputfile^.saveline_no:=line_no;
        inputfile^.saveinputbuffer:=inputbuffer;
        inputfile^.saveinputpointer:=inputpointer;
      end;


    procedure tscannerfile.restoreinputfile;
      begin
        bufstart:=inputfile^.savebufstart;
        bufsize:=inputfile^.savebufsize;
        lastlinepos:=inputfile^.savelastlinepos;
        line_no:=inputfile^.saveline_no;
        inputbuffer:=inputfile^.saveinputbuffer;
        inputpointer:=inputfile^.saveinputpointer;
      end;


    procedure tscannerfile.nextfile;
      begin
        if assigned(inputfile^.next) then
         begin
           inputfile:=inputfile^.next;
           restoreinputfile;
         end;
      end;


    procedure tscannerfile.addfile(hp:pinputfile);
      begin
        saveinputfile;
      { add to list }
        hp^.next:=inputfile;
        inputfile:=hp;
      { load new inputfile }
        restoreinputfile;
      end;


    procedure tscannerfile.reload;
      begin
      { safety check }
        if closed then
         exit;
        repeat
        { still more to read, then we have an illegal char }
          if (bufsize>0) and (inputpointer-inputbuffer<bufsize) then
           begin
             gettokenpos;
             Message(scan_f_illegal_char);
           end;
        { can we read more from this file ? }
          if filenotatend then
           begin
             readbuf;
  {           fixbuf; }
             if line_no=0 then
              line_no:=1;
             inputpointer:=inputbuffer;
           end
          else
           begin
             close;
           { no next module, than EOF }
             if not assigned(inputfile^.next) then
              begin
                c:=#26;
                exit;
              end;
           { load next file and reopen it }
             nextfile;
             reopen;
           { status }
             Comment(V_Debug,'back in '+inputfile^.name^);
           { load some current_module fields }
             current_module^.current_index:=inputfile^.ref_index;
           end;
        { load next char }
          c:=inputpointer^;
          inc(longint(inputpointer));
        until c<>#0; { if also end, then reload again }
      end;


    procedure tscannerfile.setbuf(p:pchar;l:longint);
      begin
        inputbuffer:=p;
        inputbufsize:=l;
        inputpointer:=inputbuffer;
      end;


    procedure tscannerfile.gettokenpos;
    { load the values of tokenpos and lasttokenpos }
      begin
        lasttokenpos:=bufstart+(inputpointer-inputbuffer);
        tokenpos.line:=line_no;
        tokenpos.column:=lasttokenpos-lastlinepos+1;
        tokenpos.fileindex:=current_module^.current_index;
        aktfilepos:=tokenpos;
      end;


    procedure tscannerfile.inc_comment_level;
      begin
         inc(comment_level);
         if (comment_level>1) then
          Message1(scan_w_comment_level,tostr(comment_level));
      end;


    procedure tscannerfile.dec_comment_level;
      begin
         if cs_tp_compatible in aktswitches then
           comment_level:=0
         else
           dec(comment_level);
      end;


    procedure tscannerfile.linebreak;
      var
         cur : char;
      begin
        if (byte(inputpointer^)=0) and
           filenotatend then
          begin
             cur:=c;
             reload;
             if byte(cur)+byte(c)<>23 then
               dec(longint(inputpointer));
          end
        else
         begin
         { Fix linebreak to be only newline (=#10) for all types of linebreaks }
           if (byte(inputpointer^)+byte(c)=23) then
             inc(longint(inputpointer));
         end;
        c:=newline;
      { increase line counters }
        lastlinepos:=bufstart+(inputpointer-inputbuffer);
        inc(line_no);
      { update for status }
        inc(status.compiledlines);
        Comment(V_Status,'');
      end;

{$else NEWINPUT}

    procedure gettokenpos;
    { load the values of tokenpos and lasttokenpos }
      begin
        tokenpos.line:=current_module^.current_inputfile^.true_line;
        tokenpos.column:=get_file_col;
        tokenpos.fileindex:=current_module^.current_index;
      end;

    procedure reload;
      var
         readsize   : word;
         i,saveline : longint;
      begin
        if not assigned(current_module^.current_inputfile) then
          internalerror(14);
        if current_module^.current_inputfile^.filenotatend then
         begin
         { load the next piece of source }
           blockread(current_module^.current_inputfile^.f,inputbuffer^,
             current_module^.current_inputfile^.bufsize-1,readsize);
         { Scan the buffer for #0 chars, which are not alllowed }
           if readsize > 0 then
            begin
            { force proper line counting }
              saveline:=current_module^.current_inputfile^.true_line;
              i:=0;
              inputpointer:=inputbuffer;
              while i<readsize do
               begin
                 c:=inputpointer^;
                 case c of
                  #0 : Message(scan_f_illegal_char);
             #10,#13 : begin
                         if (byte(c)+byte(inputpointer[1])=23) then
                          begin
                            inc(longint(inputpointer));
                            inc(i);
                          end;
                         inc(current_module^.current_inputfile^.true_line);
                       end;
                 end;
                 inc(i);
                 inc(longint(inputpointer));
               end;
              current_module^.current_inputfile^.true_line:=saveline;
            end;
           inputbuffer[readsize]:=#0;
           inputpointer:=inputbuffer;
           currlinepos:=inputpointer;
         { Set EOF when main source and at endoffile }
           if eof(current_module^.current_inputfile^.f) then
            begin
              current_module^.current_inputfile^.filenotatend:=false;
              if current_module^.current_inputfile^.next=nil then
               inputbuffer[readsize]:=#26;
            end;
         end
        else
         begin
           current_module^.current_inputfile^.close;
         { load next module }
           current_module^.current_inputfile:=current_module^.current_inputfile^.next;
           current_module^.current_index:=current_module^.current_inputfile^.ref_index;
           status.currentsource:=current_module^.current_inputfile^.name^+current_module^.current_inputfile^.ext^;
           inputbuffer:=current_module^.current_inputfile^.buf;
           inputpointer:=inputbuffer+current_module^.current_inputfile^.bufpos;
           currlinepos:=inputpointer;
         end;
        lastlinepos:=currlinepos;
      { load next char }
        c:=inputpointer^;
        inc(longint(inputpointer));
      end;

    procedure linebreak;
      var
         cur : char;
      begin
        if (byte(inputpointer^)=0) and
           current_module^.current_inputfile^.filenotatend then
          begin
             cur:=c;
             reload;
             if byte(cur)+byte(c)<>23 then
               dec(longint(inputpointer));
          end
        else
          begin
          { Fix linebreak to be only newline (=#10) for all types of linebreaks }
            if (byte(inputpointer^)+byte(c)=23) then
              inc(longint(inputpointer));
          end;
        c:=newline;
      { status }
        Comment(V_Status,'');
      { increase line counters }
        inc(current_module^.current_inputfile^.true_line);
        currlinepos:=inputpointer;
        inc(status.compiledlines);
      end;

{$endif NEWINPUT}


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}poppreprocstack;
      var
         hp : ppreprocstack;
      begin
        if assigned(preprocstack) then
         begin
           hp:=preprocstack^.next;
           dispose(preprocstack,done);
           preprocstack:=hp;
         end
        else
         Message(scan_e_endif_without_if);
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}addpreprocstack(a:boolean;const s:string;w:tmsgconst);
      begin
        preprocstack:=new(ppreprocstack,init(((preprocstack=nil) or preprocstack^.accept) and a,preprocstack));
        preprocstack^.name:=s;
        preprocstack^.line_nb:={$ifndef NEWINPUT}current_module^.current_inputfile^.{$endif}line_no;
        if preprocstack^.accept then
         Message2(w,preprocstack^.name,'accepted')
        else
         Message2(w,preprocstack^.name,'rejected');
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}elsepreprocstack;
      begin
        if assigned(preprocstack) then
         begin
           if not(assigned(preprocstack^.next)) or (preprocstack^.next^.accept) then
            preprocstack^.accept:=not preprocstack^.accept;
           if preprocstack^.accept then
            Message2(scan_c_else_found,preprocstack^.name,'accepted')
           else
            Message2(scan_c_else_found,preprocstack^.name,'rejected');
         end
        else
         Message(scan_e_endif_without_if);
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}readchar;
      begin
        c:=inputpointer^;
        if c=#0 then
         reload
        else
         inc(longint(inputpointer));
        if c in [#10,#13] then
         linebreak;
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}readstring;
      var
        i : longint;
      begin
        i:=0;
        repeat
          case c of
                 '_',
            '0'..'9',
            'A'..'Z' : begin
                         if i<255 then
                          begin
                            inc(i);
                            orgpattern[i]:=c;
                            pattern[i]:=c;
                          end;
                         c:=inputpointer^;
                         inc(longint(inputpointer));
                       end;
            'a'..'z' : begin
                         if i<255 then
                          begin
                            inc(i);
                            orgpattern[i]:=c;
                            pattern[i]:=chr(ord(c)-32)
                          end;
                         c:=inputpointer^;
                         inc(longint(inputpointer));
                       end;

                  #0 : reload;
             #13,#10 : begin

                         linebreak;
                         break;
                       end;
          else
           break;
          end;
        until false;

        orgpattern[0]:=chr(i);
        pattern[0]:=chr(i);
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}readnumber;
      var
        base,
        i  : longint;
      begin
        case c of
         '%' : begin
                 readchar;
                 base:=2;
                 pattern[1]:='%';
                 i:=1;
               end;
         '$' : begin
                 readchar;
                 base:=16;
                 pattern[1]:='$';
                 i:=1;
               end;
        else
         begin
           base:=10;
           i:=0;
         end;
        end;
        while ((base>=10) and (c in ['0'..'9'])) or
              ((base=16) and (c in ['A'..'F','a'..'f'])) or
              ((base=2) and (c in ['0'..'1'])) do
         begin
           if i<255 then
            begin
              inc(i);
              pattern[i]:=c;
            end;
        { get next char }
           c:=inputpointer^;
           if c=#0 then
            reload
           else
            inc(longint(inputpointer));
         end;
      { was the next char a linebreak ? }
        if c in [#10,#13] then
         linebreak;
        pattern[0]:=chr(i);
      end;


    function {$ifdef NEWINPUT}tscannerfile.{$endif}readid:string;
      begin
        readstring;
        readid:=pattern;
      end;


    function {$ifdef NEWINPUT}tscannerfile.{$endif}readval:longint;
      var
        l : longint;
        w : word;
      begin
        readnumber;
        valint(pattern,l,w);
        readval:=l;
      end;


    function {$ifdef NEWINPUT}tscannerfile.{$endif}readcomment:string;
      var
        i : longint;
      begin
        i:=0;
        repeat
          case c of
           '}' : begin
                   readchar;
                   dec_comment_level;
                   break;
                 end;
           #26 : Message(scan_f_end_of_file);
          else
            begin
              if (i<255) then
               begin
                 inc(i);
                 readcomment[i]:=c;
               end;
            end;
          end;
          c:=inputpointer^;
          if c=#0 then
           reload
          else
           inc(longint(inputpointer));
          if c in [#10,#13] then
           linebreak;
        until false;
        readcomment[0]:=chr(i);
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}skipspace;
      begin
        while c in [' ',#9..#13] do
         begin
           c:=inputpointer^;
           if c=#0 then
            reload
           else
            inc(longint(inputpointer));
           if c in [#10,#13] then
            linebreak;
         end;
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}skipuntildirective;
      var
        found : longint;
      begin
         found:=0;
         repeat
           case c of
            #26 : Message(scan_f_end_of_file);
            '{' : begin
                    if comment_level=0 then
                     found:=1;
                    inc_comment_level;
                  end;
            '}' : begin
                    dec_comment_level;
                    found:=0;
                  end;
            '$' : begin
                    if found=1 then
                     found:=2;
                  end;
           else
            found:=0;
           end;
           c:=inputpointer^;
           if c=#0 then
            reload
           else
            inc(longint(inputpointer));
           if c in [#10,#13] then
            linebreak;
         until (found=2);
      end;

{$i scandir.inc}

    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}skipcomment;
      begin
        readchar;
        inc_comment_level;
      { handle compiler switches }
        if (c='$') then
         handledirectives;
      { handle_switches can dec comment_level,  }
        while (comment_level>0) do
         begin
           case c of
            '{' : inc_comment_level;
            '}' : dec_comment_level;
            #26 : Message(scan_f_end_of_file);
           end;
           c:=inputpointer^;
           if c=#0 then
            reload
           else
            inc(longint(inputpointer));
           if c in [#10,#13] then
            linebreak;
         end;
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}skipdelphicomment;
      begin
        inc_comment_level;
        readchar;
      { this is currently not supported }
        if c='$' then
          Message(scan_e_wrong_styled_switch);
      { skip comment }
        while c<>newline do
         begin
           if c=#26 then
             Message(scan_f_end_of_file);
           readchar;
         end;
        dec_comment_level;
      end;


    procedure {$ifdef NEWINPUT}tscannerfile.{$endif}skipoldtpcomment;
      var
        found : longint;
      begin
        inc_comment_level;
        readchar;
      { this is currently not supported }
        if c='$' then
         Message(scan_e_wrong_styled_switch);
      { skip comment }
        while (comment_level>0) do
         begin
           found:=0;
           repeat
             case c of
              #26 : Message(scan_f_end_of_file);
              '*' : begin
                      if found=3 then
                       inc_comment_level
                      else
                       found:=1;
                    end;
              ')' : begin
                      if found=1 then
                       begin
                         dec_comment_level;
                         if comment_level=0 then
                          found:=2;
                       end;
                    end;
              '(' : found:=3;
             else
              found:=0;
             end;
             c:=inputpointer^;
             if c=#0 then
              reload
             else
              inc(longint(inputpointer));
             if c in [#10,#13] then
              linebreak;
           until (found=2);
         end;
      end;


    function {$ifdef NEWINPUT}tscannerfile.{$endif}yylex : ttoken;
      var
        y       : ttoken;
        code    : word;
        l       : longint;
        mac     : pmacrosym;
        hp      : pinputfile;
        macbuf  : pchar;
        asciinr : string[3];
      label
         exit_label;
      begin
        { was the last character a point ? }
        { this code is needed because the scanner if there is a 1. found if  }
        { this is a floating point number or range like 1..3                 }
        if s_point then
          begin
             gettokenpos;
             s_point:=false;
             if c='.' then
               begin
                  readchar;
                  yylex:=POINTPOINT;
                  goto exit_label;
               end;
             yylex:=POINT;
             goto exit_label;
          end;

      { Skip all spaces and comments }
        repeat
          case c of
           '{' : skipcomment;
   ' ',#9..#13 : skipspace;
          else
           break;
          end;
        until false;

      { Save current token position }
        gettokenpos;
{$ifndef NEWINPUT}
        lastlinepos:=currlinepos;
        lasttokenpos:=inputpointer;
{$endif}

      { Check first for a identifier/keyword, this is 20+% faster (PFV) }
        if c in ['_','A'..'Z','a'..'z'] then
         begin
           readstring;
           if (length(pattern) in [2..id_len]) and is_keyword(y) then
            yylex:=y
           else
            begin
            { this takes some time ... }
              if support_macros then
               begin
                 mac:=pmacrosym(macros^.search(pattern));
                 if assigned(mac) and (assigned(mac^.buftext)) then
                  begin
                  { don't forget the last char }
                    dec(longint(inputpointer));
{$ifdef NEWINPUT}
                    hp:=new(pinputfile,init('Macro '+pattern));
                    addfile(hp);
                    getmem(macbuf,mac^.buflen+1);
                    setbuf(macbuf,mac^.buflen+1);
{$else}
                    current_module^.current_inputfile^.bufpos:=inputpointer-inputbuffer;
                    hp:=new(pinputfile,init('','Macro '+pattern,''));
                  { this isn't a proper way, but ... }
                    hp^.next:=current_module^.current_inputfile;
                    current_module^.current_inputfile:=hp;
                    status.currentsource:=current_module^.current_inputfile^.name^;
                    { I don't think that we should do that
                      because otherwise the file will be searched !! (PM)
                      but there is the problem of index !! }
                    current_module^.sourcefiles.register_file(hp);
                    current_module^.current_index:=hp^.ref_index;
                  { set an own buffer }
                    getmem(macbuf,mac^.buflen+1);
                    current_module^.current_inputfile^.setbuf(macbuf,mac^.buflen+1);
                    inputbuffer:=current_module^.current_inputfile^.buf;
{$endif NEWINPUT}
                  { copy text }
                    move(mac^.buftext^,inputbuffer^,mac^.buflen);
                  { put end sign }
                    inputbuffer[mac^.buflen+1]:=#0;
                  { load c }
                    c:=inputbuffer^;
                    inputpointer:=inputbuffer+1;
                  { handle empty macros }
                    if c=#0 then
                     reload;
                  { play it again ... }
                    inc(yylexcount);
                    if yylexcount>16 then
                     Message(scan_w_macro_deep_ten);
                  {$ifdef TP}
                    yylex:=yylex;
                  {$else}
                    yylex:=yylex();
                  {$endif}
                  { that's all folks }
                    dec(yylexcount);
                    exit;
                  end;
               end;
              yylex:=ID;
            end;
           goto exit_label;
         end
        else
         begin
           case c of
                '$' : begin
                         readnumber;
                         yylex:=INTCONST;
                         goto exit_label;
                      end;
                '%' : begin
                         readnumber;
                         yylex:=INTCONST;
                         goto exit_label;
                      end;
           '0'..'9' : begin
                        readnumber;
                        if (c in ['.','e','E']) then
                         begin
                         { first check for a . }
                           if c='.' then
                            begin
                              readchar;
                              if not(c in ['0'..'9']) then
                               begin
                                 s_point:=true;
                                 yylex:=INTCONST;
                                 goto exit_label;
                               end;
                              pattern:=pattern+'.';
                              while c in ['0'..'9'] do
                               begin
                                 pattern:=pattern+c;
                                 readchar;
                               end;
                            end;
                         { E can also follow after a point is scanned }

                           if c in ['e','E'] then

                            begin
                              pattern:=pattern+'E';
                              readchar;
                              if c in ['-','+'] then
                               begin
                                 pattern:=pattern+c;
                                 readchar;
                               end;
                              if not(c in ['0'..'9']) then
                               Message(scan_f_illegal_char);
                              while c in ['0'..'9'] do
                               begin
                                 pattern:=pattern+c;
                                 readchar;
                               end;
                            end;
                           yylex:=REALNUMBER;
                           goto exit_label;
                         end;
                        yylex:=INTCONST;
                        goto exit_label;
                      end;
                ';' : begin
                        readchar;
                        yylex:=SEMICOLON;
                        goto exit_label;
                      end;
                '[' : begin
                        readchar;
                        yylex:=LECKKLAMMER;
                        goto exit_label;
                      end;
                ']' : begin
                        readchar;
                        yylex:=RECKKLAMMER;
                        goto exit_label;
                      end;
                '(' : begin
                        readchar;
                        if c='*' then
                         begin
                           skipoldtpcomment;
                        {$ifndef TP}
                           yylex:=yylex();
                        {$else}
                           yylex:=yylex;
                        {$endif}
                           exit;
                         end;
                        yylex:=LKLAMMER;
                        goto exit_label;
                      end;
                ')' : begin
                        readchar;
                        yylex:=RKLAMMER;
                        goto exit_label;
                      end;
                '+' : begin
                        readchar;
                        if (c='=') and support_c_operators then
                         begin
                           readchar;
                           yylex:=_PLUSASN;
                           goto exit_label;
                         end;
                        yylex:=PLUS;
                        goto exit_label;
                      end;
                '-' : begin
                        readchar;
                        if (c='=') and support_c_operators then
                         begin
                           readchar;
                           yylex:=_MINUSASN;
                           goto exit_label;
                         end;
                        yylex:=MINUS;
                        goto exit_label;
                      end;
                ':' : begin
                        readchar;
                        if c='=' then
                         begin
                           readchar;
                           yylex:=ASSIGNMENT;
                           goto exit_label;
                         end;
                        yylex:=COLON;
                        goto exit_label;
                      end;
                '*' : begin
                        readchar;
                        if (c='=') and support_c_operators then
                         begin
                           readchar;
                           yylex:=_STARASN;
                         end
                        else
                         if c='*' then
                          begin
                            readchar;
                            yylex:=STARSTAR;
                          end
                        else
                         yylex:=STAR;
                        goto exit_label;
                      end;
                '/' : begin
                        readchar;
                        case c of
                         '=' : begin
                                 if support_c_operators then
                                  begin
                                    readchar;
                                    yylex:=_SLASHASN;
                                    goto exit_label;
                                  end;
                               end;
                         '/' : begin
                                 skipdelphicomment;
                               {$ifndef TP}
                                 yylex:=yylex();
                               {$else TP}
                                 yylex:=yylex;
                               {$endif TP}
                                 exit;
                               end;
                        end;
                        yylex:=SLASH;
                        goto exit_label;
                      end;
           '='      : begin
                        readchar;
                        yylex:=EQUAL;
                        goto exit_label;
                      end;
           '.'      : begin
                        readchar;
                        if c='.' then
                         begin
                           readchar;
                           yylex:=POINTPOINT;
                           goto exit_label;
                         end
                        else
                         yylex:=POINT;
                        goto exit_label;
                      end;
                '@' : begin
                        readchar;
                        if c='@' then
                         begin
                           readchar;
                           yylex:=DOUBLEADDR;
                         end
                        else
                         yylex:=KLAMMERAFFE;
                        goto exit_label;
                      end;
                ',' : begin
                        readchar;
                        yylex:=COMMA;
                        goto exit_label;
                      end;
      '''','#','^' :  begin
                        if c='^' then
                         begin
                           readchar;
                           c:=upcase(c);
                           if not(block_type=bt_type) and (c in ['A'..'Z']) then
                            begin
                              pattern:=chr(ord(c)-64);
                              readchar;
                            end
                           else
                            begin
                              yylex:=CARET;
                              goto exit_label;
                            end;
                         end
                        else
                         pattern:='';
                        repeat
                          case c of
                           '#' : begin
                                   readchar; { read # }
                                   asciinr:='';
                                   while (c in ['0'..'9']) and (length(asciinr)<3) do
                                    begin
                                      asciinr:=asciinr+c;
                                      readchar;
                                    end;
                                   valint(asciinr,l,code);
                                   if (asciinr='') or (code<>0) or
                                      (l<0) or (l>255) then
                                    Message(scan_e_illegal_char_const);
                                   pattern:=pattern+chr(l);
                                 end;
                          '''' : begin
                                   repeat
                                     readchar;
                                     case c of
                                    #26 : Message(scan_f_end_of_file);
                                newline : Message(scan_f_string_exceeds_line);
                                   '''' : begin
                                            readchar;
                                            if c<>'''' then
                                             break;
                                          end;
                                     end;
                                     pattern:=pattern+c;
                                   until false;
                                 end;
                           '^' : begin
                                   readchar;
                                   if c<#64 then
                                    c:=chr(ord(c)+64)
                                   else
                                    c:=chr(ord(c)-64);
                                   pattern:=pattern+c;
                                   readchar;
                                 end;
                          else
                           break;
                          end;
                        until false;
                      { strings with length 1 become const chars }
                        if length(pattern)=1 then
                         yylex:=CCHAR
                        else
                         yylex:=CSTRING;
                        goto exit_label;
                      end;
                '>' : begin
                        readchar;
                        case c of
                         '=' : begin
                                 readchar;
                                 yylex:=GTE;
                                 goto exit_label;
                               end;
                         '>' : begin
                                 readchar;
                                 yylex:=_SHR;
                                 goto exit_label;
                               end;
                         '<' : begin { >< is for a symetric diff for sets }
                                 readchar;
                                 yylex:=SYMDIF;
                                 goto exit_label;
                               end;
                        end;
                        yylex:=GT;
                        goto exit_label;
                      end;
                '<' : begin
                        readchar;
                        case c of
                         '>' : begin
                                 readchar;
                                 yylex:=UNEQUAL;
                                 goto exit_label;
                               end;
                         '=' : begin
                                 readchar;
                                 yylex:=LTE;
                                 goto exit_label;
                               end;
                         '<' : begin
                                 readchar;
                                 yylex:=_SHL;
                                 goto exit_label;
                               end;
                        end;
                        yylex:=LT;
                        goto exit_label;
                      end;
                #26 : begin
                        yylex:=_EOF;
                        goto exit_label;
                      end;
           else
            begin
              Message(scan_f_illegal_char);
            end;
           end;
        end;
exit_label:
      { don't change the file : too risky !! }
{$ifndef NEWINPUT}
        if current_module^.current_index=tokenpos.fileindex then
          begin
             current_module^.current_inputfile^.line_no:=tokenpos.line;
             current_module^.current_inputfile^.column:=tokenpos.column;
             current_column:=tokenpos.column;
          end;
{$endif NEWINPUT}
      end;


{$ifdef NEWINPUT}
    function tscannerfile.readpreproc:ttoken;
      begin
         skipspace;
         case c of
        'A'..'Z',
        'a'..'z',
    '_','0'..'9' : begin
                     preprocpat:=readid;
                     readpreproc:=ID;
                   end;
             '(' : begin
                     readchar;
                     readpreproc:=LKLAMMER;
                   end;
             ')' : begin
                     readchar;
                     readpreproc:=RKLAMMER;
                   end;
             '+' : begin
                     readchar;
                     readpreproc:=PLUS;
                   end;
             '-' : begin
                     readchar;
                     readpreproc:=MINUS;
                   end;
             '*' : begin
                     readchar;
                     readpreproc:=STAR;
                   end;
             '/' : begin
                     readchar;
                     readpreproc:=SLASH;
                   end;
             '=' : begin
                     readchar;
                     readpreproc:=EQUAL;
                   end;
             '>' : begin
                     readchar;
                     if c='=' then
                      begin
                        readchar;
                        readpreproc:=GTE;
                      end
                     else
                      readpreproc:=GT;
                   end;
             '<' : begin
                     readchar;
                     case c of
                      '>' : begin
                              readchar;
                              readpreproc:=UNEQUAL;
                            end;
                      '=' : begin
                              readchar;
                              readpreproc:=LTE;
                            end;
                     else   readpreproc:=LT;
                     end;
                   end;
             #26 : Message(scan_f_end_of_file);
         else
          begin
            readpreproc:=_EOF;
          end;
         end;
      end;
{$endif}


    function {$ifdef NEWINPUT}tscannerfile.{$endif}asmgetchar : char;
      begin
         if lastasmgetchar<>#0 then
          begin
            c:=lastasmgetchar;
            lastasmgetchar:=#0;
          end
         else
          readchar;
         case c of
          '{' : begin
                  skipcomment;
                  lastasmgetchar:=c;
                  asmgetchar:=';';
                  exit;
                end;
          '/' : begin
                  readchar;
                  if c='/' then
                   begin
                     skipdelphicomment;
                     asmgetchar:=';';
                   end
                  else
                   asmgetchar:='/';
                  lastasmgetchar:=c;
                  exit;
                end;
          '(' : begin
                  readchar;
                  if c='*' then
                   begin
                     skipoldtpcomment;
                     asmgetchar:=';';
                   end
                  else
                   asmgetchar:='(';
                  lastasmgetchar:=c;
                  exit;
                end;
         else
          begin
            asmgetchar:=c;
          end;
         end;
      end;

{$ifdef NEWINPUT}

{$else NEWPPU}

   procedure InitScanner(const fn: string);
     var
       d:dirstr;
       n:namestr;
       e:extstr;
     begin
        fsplit(fn,d,n,e);
        current_module^.current_inputfile:=new(pinputfile,init(d,n,e));
        if not current_module^.current_inputfile^.reset then
         Message(scan_f_cannot_open_input);
        current_module^.sourcefiles.register_file(current_module^.current_inputfile);
        current_module^.current_index:=current_module^.current_inputfile^.ref_index;
        status.currentsource:=current_module^.current_inputfile^.name^+current_module^.current_inputfile^.ext^;
        inputbuffer:=current_module^.current_inputfile^.buf;
        reload;
        preprocstack:=nil;
        comment_level:=0;
        lasttokenpos:=inputpointer;
        lastlinepos:=inputpointer;
        currlinepos:=inputpointer;
        s_point:=false;
        block_type:=bt_general;
     end;

   procedure get_cur_file_pos(var fileinfo : tfileposinfo);
     begin
        with fileinfo do
         begin
           line:=current_module^.current_inputfile^.line_no;
           fileindex:=current_module^.current_index;
           column:=get_current_col;
         end;
     end;


   procedure set_cur_file_pos(const fileinfo : tfileposinfo);
     begin
        if current_module^.current_index<>fileinfo.fileindex then
          begin
             current_module^.current_index:=fileinfo.fileindex;
             current_module^.current_inputfile:=
               pinputfile(current_module^.sourcefiles.get_file(fileinfo.fileindex));
          end;
        if assigned(current_module^.current_inputfile) then
          begin
             current_module^.current_inputfile^.line_no:=fileinfo.line;
             current_module^.current_inputfile^.column:=fileinfo.column;
             current_column:=fileinfo.column;
          end;
     end;

   procedure DoneScanner(testendif:boolean);
     begin
       if (not testendif) then
        begin
          while assigned(preprocstack) do
           begin
             Message3(scan_e_endif_expected,'$IF(N)(DEF)',preprocstack^.name,tostr(preprocstack^.line_nb));
             poppreprocstack;
           end;
        end;
     end;


{$endif NEWINPUT}



end.
{
  $Log$
  Revision 1.33  1998-07-10 10:48:40  peter
    * fixed realnumber scanning
    * [] after asmblock was not uppercased anymore

  Revision 1.31  1998/07/07 17:39:38  peter
    * fixed $I  with following eof

  Revision 1.30  1998/07/07 12:32:55  peter
    * status.currentsource is now calculated in verbose (more accurated)

  Revision 1.29  1998/07/07 11:20:11  peter
    + NEWINPUT for a better inputfile and scanner object

  Revision 1.28  1998/07/01 15:26:57  peter
    * better bufferfile.reset error handling

  Revision 1.27  1998/06/25 08:48:19  florian
    * first version of rtti support

  Revision 1.26  1998/06/16 08:56:30  peter
    + targetcpu
    * cleaner pmodules for newppu

  Revision 1.25  1998/06/13 00:10:15  peter
    * working browser and newppu
    * some small fixes against crashes which occured in bp7 (but not in
      fpc?!)

  Revision 1.24  1998/06/12 10:32:36  pierre
    * column problem hopefully solved
    + C vars declaration changed

  Revision 1.23  1998/06/03 22:49:02  peter
    + wordbool,longbool
    * rename bis,von -> high,low
    * moved some systemunit loading/creating to psystem.pas

  Revision 1.21  1998/05/27 00:20:32  peter
    * some scanner optimizes
    * automaticly aout2exe for go32v1
    * fixed dynamiclinker option which was added at the wrong place

  Revision 1.20  1998/05/23 01:21:30  peter
    + aktasmmode, aktoptprocessor, aktoutputformat
    + smartlink per module $SMARTLINK-/+ (like MMX) and moved to aktswitches
    + $LIBNAME to set the library name where the unit will be put in
    * splitted cgi386 a bit (codeseg to large for bp7)
    * nasm, tasm works again. nasm moved to ag386nsm.pas

  Revision 1.19  1998/05/20 09:42:37  pierre
    + UseTokenInfo now default
    * unit in interface uses and implementation uses gives error now
    * only one error for unknown symbol (uses lastsymknown boolean)
      the problem came from the label code !
    + first inlined procedures and function work
      (warning there might be allowed cases were the result is still wrong !!)
    * UseBrower updated gives a global list of all position of all used symbols
      with switch -gb

  Revision 1.18  1998/05/12 10:47:00  peter
    * moved printstatus to verb_def
    + V_Normal which is between V_Error and V_Warning and doesn't have a
      prefix like error: warning: and is included in V_Default
    * fixed some messages
    * first time parameter scan is only for -v and -T
    - removed old style messages

  Revision 1.17  1998/05/06 08:38:47  pierre
    * better position info with UseTokenInfo
      UseTokenInfo greatly simplified
    + added check for changed tree after first time firstpass
      (if we could remove all the cases were it happen
      we could skip all firstpass if firstpasscount > 1)
      Only with ExtDebug

  Revision 1.16  1998/05/04 17:54:28  peter
    + smartlinking works (only case jumptable left todo)
    * redesign of systems.pas to support assemblers and linkers
    + Unitname is now also in the PPU-file, increased version to 14

  Revision 1.15  1998/05/01 16:38:46  florian
    * handling of private and protected fixed
    + change_keywords_to_tp implemented to remove
      keywords which aren't supported by tp
    * break and continue are now symbols of the system unit
    + widestring, longstring and ansistring type released

  Revision 1.14  1998/04/30 15:59:42  pierre
    * GDB works again better :
      correct type info in one pass
    + UseTokenInfo for better source position
    * fixed one remaining bug in scanner for line counts
    * several little fixes

  Revision 1.13  1998/04/29 13:42:27  peter
    + $IOCHECKS and $ALIGN to test already, other will follow soon
    * fixed the wrong linecounting with comments

  Revision 1.12  1998/04/29 10:34:04  pierre
    + added some code for ansistring (not complete nor working yet)
    * corrected operator overloading
    * corrected nasm output
    + started inline procedures
    + added starstarn : use ** for exponentiation (^ gave problems)
    + started UseTokenInfo cond to get accurate positions

  Revision 1.11  1998/04/27 23:10:29  peter
    + new scanner
    * $makelib -> if smartlink
    * small filename fixes pmodule.setfilename
    * moved import from files.pas -> import.pas

}
