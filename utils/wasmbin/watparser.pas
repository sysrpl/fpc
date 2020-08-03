unit watparser;

{$mode delphi}{$H+}

interface

uses
  SysUtils, Classes, parseutils, wasmtext, wasmmodule, wasmbin;

type
  TWatToken = (weNone, weError,
     weIdent,
     weString, weNumber, weOpenBrace, weCloseBrace,
     weAsmSymbol,

     weInstr,
     weFunc,
     weParam, weResult,
     weModule, weMut, weFuncRef,
     wei32, wei64,
     wef32, wef64,
     weType,
     weImport, weGlobal, weTable, weMemory, weLocal, weExport,
     weElem, weData, weOffset
   );

  { TWatScanner }

  TWatScanner = class(TObject)
  protected
    procedure DoComment(const cmt: string);
    function CommentIsSymbol(const cmt: string): Boolean;
  public
    buf       : string;
    idx       : integer;

    instrCode : byte;
    ofs       : integer;
    token     : TWatToken;
    resText   : string;
    procedure SetSource(const abuf: string);
    function Next: Boolean;

    function GetInt32: Integer;
  end;

const
  // see Identifiers of Textual format
  IdStart  = '$';
  IdBody   = AlphaNumChars
             + [ '!' ,'#' ,'$' ,'%' ,'&' ,'''' ,'*'
                ,'+' ,'-' ,'.' ,'/' ,':' ,'<' ,'='
                ,'>' ,'?' ,'@' ,'\' ,'^' ,'_' ,'`'
                ,'|' ,'~'];
  GrammarChars  = AlphaNumChars+['.','_'];

procedure GetGrammar(const txt: string; out entity: TWatToken; out instByte: byte);

const
  KEY_MODULE = 'module';
  KEY_FUNC   = 'func';
  KEY_FUNCREF = 'funcref';
  KEY_I32    = 'i32';
  KEY_I64    = 'i64';
  KEY_F32    = 'f32';
  KEY_F64    = 'f64';
  KEY_PARAM  = 'param';
  KEY_RESULT = 'result';
  KEY_MUT    = 'mut';
  KEY_TYPE   = 'type';

  KEY_IMPORT = 'import';
  KEY_GLOBAL = 'global';
  KEY_TABLE  = 'table';
  KEY_MEMORY = 'memory';
  KEY_LOCAL  = 'local';
  KEY_EXPORT = 'export';
  KEY_ELEM   = 'elem';
  KEY_DATA   = 'data';
  KEY_OFFSET = 'offset';

function ScanString(const buf: string; var idx: integer): string;


type
  TParseResult = record
    error : string;
  end;

//function ConsumeToken(sc: TWatScanner; tk: TWatToken): Boolean;
function ParseModule(sc: TWatScanner; dst: TWasmModule; var res: TParseResult): Boolean;
procedure ErrorUnexpected(var res: TParseResult; const tokenstr: string = '');
procedure ErrorExpectButFound(var res: TParseResult; const expected: string; const butfound: string = '');
procedure ErrorUnexpectedEof(var res: TParseResult);

implementation

procedure GetGrammar(const txt: string; out entity: TWatToken; out instByte: byte);
begin
  instByte:=0;
  entity:=weError;
  if txt='' then Exit;
  case txt[1] of
    'a':
      if txt='anyfunc' then entity:=weFuncRef
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'd':
      if txt=KEY_DATA then entity:=weData
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'e':
      if txt=KEY_EXPORT then entity:=weExport
      else if txt=KEY_ELEM then entity:=weElem
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'i':
      if txt=KEY_I32 then entity:=wei32
      else if txt=KEY_I64 then entity:=wei64
      else if txt=KEY_IMPORT then entity:=weImport
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'g':
      if txt=KEY_GLOBAL then entity:=weGlobal
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'f':
      if txt=KEY_FUNC then entity:=weFunc
      else if txt=KEY_FUNCREF then entity:=weFuncRef
      else if txt=KEY_F32 then entity:=wef32
      else if txt=KEY_F64 then entity:=wef64
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'l':
      if txt=KEY_LOCAL then entity:=weLocal
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'm':
      if txt=KEY_MODULE then entity:=weModule
      else if txt = KEY_MUT then entity:=weMut
      else if txt = KEY_MEMORY then entity:=weMemory
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'o':
      if txt=KEY_OFFSET then entity:=weOffset
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'p':
      if txt=KEY_PARAM then entity:=weParam
      else if TextToInst(txt, instByte) then entity:=weInstr;
    'r':
      if txt=KEY_RESULT then entity:=weResult
      else if TextToInst(txt, instByte) then entity:=weInstr;
    't':
      if txt=KEY_TYPE then entity:=weType
      else if txt=KEY_TABLE then entity:=weTable
      else if TextToInst(txt, instByte) then entity:=weInstr;
  else
    if TextToInst(txt, instByte) then entity:=weInstr;
  end;
end;


{ TWatScanner }

procedure TWatScanner.DoComment(const cmt: string);
begin

end;

function TWatScanner.CommentIsSymbol(const cmt: string): Boolean;
begin
  Result := false;
end;

procedure TWatScanner.SetSource(const abuf: string);
begin
  buf:=abuf;
  idx:=1;
end;

function ScanString(const buf: string; var idx: integer): string;
var
  j : integer;
begin
  if buf[idx]<>'"' then begin
    Result:='';
    Exit;
  end;
  j:=idx;
  inc(idx);
  while (buf[idx]<>'"') and (idx<length(buf)) do begin
    if buf[idx]='\' then inc(idx);
    inc(idx);
  end;
  inc(idx);
  Result:=Copy(buf, j, idx-j);
end;

function TWatScanner.Next: Boolean;
var
  has2chars: Boolean;
  cmt : string;
  done: boolean;
begin
  Result := idx<=length(buf);
  if not Result then Exit;

  done:=false;
  resText:='';
  while not done do begin
    ScanWhile(buf, idx, SpaceEolnChars);
    Result := idx<=length(buf);
    if not Result then Exit;
    ofs:=idx;
    has2chars := idx<length(buf);
    if has2chars then begin
      if (buf[idx]=';') and (buf[idx+1]=';') then begin
        // comment until the end of the line
        cmt := ScanTo(buf, idx, EoLnChars);
        ScanWhile(buf, idx, EoLnChars);
      end else if (buf[idx]='(') and (buf[idx+1]=';') then
        // comment until the ;)
        cmt := ScanToSubstr(buf, idx, ';)');

      if CommentIsSymbol(cmt) then begin
        token:=weAsmSymbol;
        done:=true;
      end else
        DoComment(cmt);
    end;

    if not done then begin
      done:=true;
      if buf[idx] = '(' then begin
        token:=weOpenBrace;
        inc(idx);
      end else if buf[idx]=')' then begin
        token:=weCloseBrace;
        inc(idx);
      end else if buf[idx]='"' then begin
        token:=weString;
        resText:=ScanString(buf, idx);
      end else if buf[idx] = IdStart then begin
        token:=weIdent;
        resText:=ScanWhile(buf, idx, IdBody);
      end else if buf[idx] in AlphaNumChars then begin
        resText:=ScanWhile(buf, idx, GrammarChars);
        GetGrammar(resText, token, instrCode);
        done:=true;
      end else if buf[idx] in NumericChars then begin
        token:=weNumber;
        resText:=ScanWhile(buf, idx, NumericChars);
      end else begin
        token:=weError;
        inc(idx);
        done:=true;
      end;
    end;
  end;

  if resText='' then
    resText := Copy(buf, ofs, idx-ofs);
end;

function TWatScanner.GetInt32: Integer;
var
  err: integer;
begin
  Val(resText, Result, err);
  if err<>0 then Result:=0;
end;

function ConsumeOpenToken(sc: TWatScanner; tk: TWatToken): Boolean;
begin
  sc.Next;
  Result := (sc.token=weOpenBrace) or (sc.Token=tk);
  if Result and (sc.token=weOpenBrace) then begin
    sc.Next;
    Result := (sc.Token=tk);
  end;
end;

function ConsumeToken(sc: TWatScanner; tk: TWatToken; var res: TParseResult): Boolean;
begin
  Result:=sc.token =tk;
  if not Result then
    ErrorExpectButFound(res, 'some token','?')
  else
    sc.Next;
end;

function ParseNumOfId(sc: TWatScanner; out num: integer; out id: string; var res: TParseResult): Boolean;
begin
  num:=-1;
  id:='';
  Result := sc.Next;
  if not Result then begin
    ErrorUnexpectedEof(res);
    Exit;
  end;

  case sc.token of
    weNumber: num:=sc.GetInt32;
    weIdent: id:=sc.resText;
  else
    ErrorExpectButFound(res, 'index');
    Result := false;
  end;
  Result := true;
  if Result then sc.Next;
end;

function TokenTypeToValType(t: TWatToken; out tp: byte): Boolean;
begin
  Result:=true;
  case t of
    wei32: tp:=valtype_i32;
    wei64: tp:=valtype_i64;
    wef32: tp:=valtype_f32;
    wef64: tp:=valtype_f64;
  else
    tp:=0;
    Result:=false;
  end;
end;

function ParseParam(sc: TWatScanner; out id: string; out tp: byte; var res: TParseResult): Boolean;
begin
  tp:=0;
  id:='';
  if sc.token=weParam then sc.Next;

  if sc.token=weIdent then begin
    id:=sc.resText;
    sc.Next;
  end;

  if not TokenTypeToValType(sc.token, tp) then begin
    ErrorExpectButFound(res, 'type');
    Result:=false;
    Exit;
  end else
    Result:=true;
  sc.Next;
  Result := sc.token=weCloseBrace;
  if Result then sc.Next
  else ErrorExpectButFound(res, ')');
end;

function ParseFunc(sc: TWatScanner; dst: TWasmFunc; var res: TParseResult): Boolean;
var
  nm : integer;
  id : string;
  p  : TWasmParam;
begin
  if sc.token=weFunc then sc.Next;
  repeat
    if sc.token=weIdent then begin
      dst.id:=sc.resText;
      sc.Next;
    end;

    Result:=false;
    if sc.token=weOpenBrace then begin
      sc.Next;
      case sc.token of
        weType: begin
          if not ParseNumOfId(sc, nm, id, res) then Exit;
          if nm>=0 then dst.typeIdx:=nm
          else dst.typeId:=id;
        end;
        weParam: begin
          sc.Next;
          p:=dst.GetInlineType.AddParam;
          if not ParseParam(sc, p.id, p.tp, res) then Exit;
        end;
        weResult: begin
          sc.Next;
          p:=dst.GetInlineType.AddResult;
          if not ParseParam(sc, p.id, p.tp, res) then Exit;
        end;
        weLocal: begin
          sc.Next;
          p:=dst.AddLocal;
          if not ParseParam(sc, p.id, p.tp, res) then Exit;
        end;
      else
        ErrorUnexpected(res, 'booh');
        Exit;
      end;
      if not ConsumeToken(sc, weCloseBrace, res) then Exit;
    end;

  until sc.token=weCloseBrace;
  sc.Next;
end;

function ParseModule(sc: TWatScanner; dst: TWasmModule; var res: TParseResult): Boolean;
begin
  if not ConsumeOpenToken(sc, weModule) then begin
    Result := false;
    Exit;
  end;

  repeat
    sc.Next;
    if sc.token=weOpenBrace then begin
      sc.Next;

      if sc.token = weFunc then begin
        Result := ParseFunc(sc, dst.AddFunc, res);
        if not Result then Exit;
      end;

    end else if sc.token<>weCloseBrace then begin
      ErrorUnexpected(res);
      Result := false;
      exit;
    end;

  until sc.token=weCloseBrace;
  Result := true;
end;

procedure ErrorUnexpected(var res: TParseResult; const tokenstr: string);
begin
  res.error:='unexpected token '+tokenstr;
end;

procedure ErrorUnexpectedEof(var res: TParseResult);
begin
  res.error:='unexpected end of file';
end;

procedure ErrorExpectButFound(var res: TParseResult; const expected, butfound: string);
begin
  res.error:=expected +' is expected';
  if butfound<>'' then
    res.error:=res.error+', but '+butfound+ ' found';
end;

end.
