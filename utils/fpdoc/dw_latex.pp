{
    $Id: dw_latex.pp,v 1.11 2005/03/10 20:32:16 michael Exp $

    FPDoc  -  Free Pascal Documentation Tool
    Copyright (C) 2000 - 2003 by
      Areca Systems GmbH / Sebastian Guenther, sg@freepascal.org

    * LaTeX output generator

    See the file COPYING, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
{$mode objfpc}
{$H+}
unit dw_LaTeX;

interface

uses DOM, dGlobals, PasTree;

const
  LateXHighLight : Boolean = False;
  TexExtension   : String = '.tex';

Procedure CreateLaTeXDocForPackage(APackage: TPasPackage; AEngine: TFPDocEngine);

implementation

uses SysUtils, Classes, dwLinear, dwriter;


Type
 { TLaTeXWriter }

  TLaTeXWriter = class(TLinearWriter)
  protected
    FLink: String;
    FTableCount : Integer;
    FInVerbatim : Boolean;
    Inlist,
    TableRowStartFlag,
    TableCaptionWritten: Boolean;
    // Linear documentation methods overrides;
    procedure WriteLabel(Const S : String); override;
    procedure WriteIndex(Const S : String); override;
    Procedure WriteExampleFile(FN : String); override;
    Procedure StartProcedure; override;
    Procedure EndProcedure; override;
    Procedure StartProperty; override;
    Procedure EndProperty; override;
    Procedure StartSynopsis; override;
    Procedure StartDeclaration; override;
    Procedure StartVisibility; override;
    Procedure StartDescription; override;
    Procedure StartAccess; override;
    Procedure StartErrors; override;
    Procedure StartSeealso; override;
    Procedure EndSeealso; override;
    procedure StartUnitOverview(AModuleName,AModuleLabel : String);override;
    procedure WriteUnitEntry(UnitRef : TPasType); override;
    Procedure EndUnitOverview; override;
    function  GetLabel(AElement: TPasElement): String; override;
    procedure StartListing(Frames: Boolean; const name: String); override;
    procedure EndListing; override;
    Function  EscapeText(S : String) : String; override;
    Function  StripText(S : String) : String; override;
    procedure WriteCommentLine; override;
    procedure WriteComment(Comment : String);override;
    procedure StartSection(SectionName : String);override;
    procedure StartSubSection(SubSectionName : String);override;
    procedure StartSubSubSection(SubSubSectionName : String);override;
    procedure StartChapter(ChapterName : String); override;
    procedure StartOverview(WithAccess : Boolean); override;
    procedure EndOverview; override;
    procedure WriteOverviewMember(ALabel,AName,Access,ADescr : String); override;
    procedure WriteOverviewMember(ALabel,AName,ADescr : String); override;
    Class Function FileNameExtension : String; override;
    // Description node conversion
    procedure DescrBeginBold; override;
    procedure DescrEndBold; override;
    procedure DescrBeginItalic; override;
    procedure DescrEndItalic; override;
    procedure DescrBeginEmph; override;
    procedure DescrEndEmph; override;
    procedure DescrWriteFileEl(const AText: DOMString); override;
    procedure DescrWriteKeywordEl(const AText: DOMString); override;
    procedure DescrWriteVarEl(const AText: DOMString); override;
    procedure DescrBeginLink(const AId: DOMString); override;
    procedure DescrEndLink; override;
    procedure DescrWriteLinebreak; override;
    procedure DescrBeginParagraph; override;
    procedure DescrBeginCode(HasBorder: Boolean; const AHighlighterName: String); override;
    procedure DescrWriteCodeLine(const ALine: String); override;
    procedure DescrEndCode; override;
    procedure DescrEndParagraph; override;
    procedure DescrBeginOrderedList; override;
    procedure DescrEndOrderedList; override;
    procedure DescrBeginUnorderedList; override;
    procedure DescrEndUnorderedList; override;
    procedure DescrBeginDefinitionList; override;
    procedure DescrEndDefinitionList; override;
    procedure DescrBeginListItem; override;
    procedure DescrEndListItem; override;
    procedure DescrBeginDefinitionTerm; override;
    procedure DescrEndDefinitionTerm; override;
    procedure DescrBeginDefinitionEntry; override;
    procedure DescrEndDefinitionEntry; override;
    procedure DescrBeginSectionTitle; override;
    procedure DescrBeginSectionBody; override;
    procedure DescrEndSection; override;
    procedure DescrBeginRemark; override;
    procedure DescrEndRemark; override;
    procedure DescrBeginTable(ColCount: Integer; HasBorder: Boolean); override;
    procedure DescrEndTable; override;
    procedure DescrBeginTableCaption; override;
    procedure DescrEndTableCaption; override;
    procedure DescrBeginTableHeadRow; override;
    procedure DescrEndTableHeadRow; override;
    procedure DescrBeginTableRow; override;
    procedure DescrEndTableRow; override;
    procedure DescrBeginTableCell; override;
    procedure DescrEndTableCell; override;
    // TFPDocWriter class methods
    Function InterPretOption(Const Cmd,Arg : String) : boolean; override;
  end;




function TLaTeXWriter.GetLabel(AElement: TPasElement): String;
var
  i: Integer;
begin
  if AElement.ClassType = TPasUnresolvedTypeRef then
    Result := Engine.ResolveLink(Module, AElement.Name)
  else
  begin
    Result := AElement.PathName;
    Result := LowerCase(Copy(Result, 2, Length(Result) - 1));
  end;
  for i := 1 to Length(Result) do
    if Result[i] = '.' then
      Result[i] := ':';
end;


Function TLatexWriter.EscapeText(S : String) : String;

var
  i: Integer;

begin
  if FInVerBatim=True then
    Result:=S
  else
    begin
    SetLength(Result, 0);
    for i := 1 to Length(S) do
      case S[i] of
        '&','{','}','#','_','$','%':            // Escape these characters
          Result := Result + '\' + S[i];
        '~','^':
          Result := Result + '\'+S[i]+' ';
        '\':
          Result:=Result+'$\backslash$'
        else
          Result := Result + S[i];
      end;
    end;
end;

Function TLatexWriter.StripText(S : String) : String;

var
  I: Integer;

begin
  SetLength(Result, 0);
  for i := 1 to Length(S) do
    If not (S[i] in ['&','{','}','#','_','$','%','''','~','^', '\']) then
      Result := Result + S[i];
end;


procedure TLaTeXWriter.DescrBeginBold;
begin
  Write('\textbf{');
end;

procedure TLaTeXWriter.DescrEndBold;
begin
  Write('}');
end;

procedure TLaTeXWriter.DescrBeginItalic;
begin
  Write('\textit{');
end;

procedure TLaTeXWriter.DescrEndItalic;
begin
  Write('}');
end;

procedure TLaTeXWriter.DescrBeginEmph;
begin
  Write('\emph{');
end;

procedure TLaTeXWriter.DescrEndEmph;
begin
  Write('}');
end;

procedure TLaTeXWriter.DescrWriteFileEl(const AText: DOMString);
begin
  Write('\file{');
  DescrWriteText(AText);
  Write('}');
end;

procedure TLaTeXWriter.DescrWriteKeywordEl(const AText: DOMString);
begin
  Write('\textbf{\\ttfamily ');
  DescrWriteText(AText);
  Write('}');
end;

procedure TLaTeXWriter.DescrWriteVarEl(const AText: DOMString);
begin
  Write('\var{');
  DescrWriteText(AText);
  Write('}');
end;

procedure TLaTeXWriter.DescrBeginLink(const AId: DOMString);
begin
  FLink := Engine.ResolveLink(Module, AId);
//  System.WriteLn('Link "', AId, '" => ', FLink);
end;

procedure TLaTeXWriter.DescrEndLink;
begin
  WriteF(' (\pageref{%s})',[StripText(Flink)]);
end;

procedure TLaTeXWriter.DescrWriteLinebreak;
begin
  WriteLn('\\');
end;

procedure TLaTeXWriter.DescrBeginParagraph;
begin
  // Do nothing
end;

procedure TLaTeXWriter.DescrEndParagraph;
begin
  WriteLn('');
  WriteLn('');
end;

procedure TLaTeXWriter.DescrBeginCode(HasBorder: Boolean;
  const AHighlighterName: String);
begin
  StartListing(HasBorder,'');
end;

procedure TLaTeXWriter.DescrWriteCodeLine(const ALine: String);
begin
  WriteLn(ALine);
end;

procedure TLaTeXWriter.DescrEndCode;
begin
  EndListing
end;

procedure TLaTeXWriter.DescrBeginOrderedList;
begin
  WriteLn('\begin{enumerate}');
end;

procedure TLaTeXWriter.DescrEndOrderedList;
begin
  WriteLn('\end{enumerate}');
end;

procedure TLaTeXWriter.DescrBeginUnorderedList;
begin
  WriteLn('\begin{itemize}');
end;

procedure TLaTeXWriter.DescrEndUnorderedList;
begin
  WriteLn('\end{itemize}');
end;

procedure TLaTeXWriter.DescrBeginDefinitionList;
begin
  WriteLn('\begin{description}');
end;

procedure TLaTeXWriter.DescrEndDefinitionList;
begin
  WriteLn('\end{description}');
end;

procedure TLaTeXWriter.DescrBeginListItem;
begin
  Write('\item ');
end;

procedure TLaTeXWriter.DescrEndListItem;
begin
  WriteLn('');
end;

procedure TLaTeXWriter.DescrBeginDefinitionTerm;
begin
  Write('\item[');
end;

procedure TLaTeXWriter.DescrEndDefinitionTerm;
begin
  WriteLn(']');
end;

procedure TLaTeXWriter.DescrBeginDefinitionEntry;
begin
  // Do nothing
end;

procedure TLaTeXWriter.DescrEndDefinitionEntry;
begin
  WriteLn('');
end;

procedure TLaTeXWriter.DescrBeginSectionTitle;
begin
  Write('\subsection{');
end;

procedure TLaTeXWriter.DescrBeginSectionBody;
begin
  WriteLn('}');
end;

procedure TLaTeXWriter.DescrEndSection;
begin
  // Do noting
end;

procedure TLaTeXWriter.DescrBeginRemark;
begin
  WriteLn('\begin{remark}');
end;

procedure TLaTeXWriter.DescrEndRemark;
begin
  WriteLn('\end{remark}');
end;

procedure TLaTeXWriter.DescrBeginTable(ColCount: Integer; HasBorder: Boolean);
var
  i: Integer;
begin
  // !!!: How do we set the border?
  Write('\begin{FPCltable}{');
  for i := 1 to ColCount do
    Write('l');
  write('}{');
  TableCaptionWritten:=False;
end;

procedure TLaTeXWriter.DescrEndTable;
begin
  WriteLn('\end{FPCltable}');
end;

procedure TLaTeXWriter.DescrBeginTableCaption;
begin
  // Do nothing.
end;

procedure TLaTeXWriter.DescrEndTableCaption;
begin
  Write('}{table');
  Inc(FTableCount);
  Write(IntToStr(FTableCount));
  Writeln('}');
  TableCaptionWritten := True;
end;

procedure TLaTeXWriter.DescrBeginTableHeadRow;
begin
  if not TableCaptionWritten then
    DescrEndTableCaption;
  TableRowStartFlag := True;
end;

procedure TLaTeXWriter.DescrEndTableHeadRow;
begin
  WriteLn('\\ \hline');
end;

procedure TLaTeXWriter.DescrBeginTableRow;
begin
  if not TableCaptionWritten then
    DescrEndTableCaption;
  TableRowStartFlag := True;
end;

procedure TLaTeXWriter.DescrEndTableRow;
begin
  WriteLn('\\');
end;

procedure TLaTeXWriter.DescrBeginTableCell;
begin
  if TableRowStartFlag then
    TableRowStartFlag := False
  else
    Write(' & ');
end;

procedure TLaTeXWriter.DescrEndTableCell;
begin
  // Do nothing
end;

procedure TLaTeXWriter.WriteLabel(const s: String);
begin
  WriteLnF('\label{%s}', [LowerCase(StripText(s))]);
end;

procedure TLaTeXWriter.WriteIndex(const s : String);
begin
  Write('\index{');
  Write(EscapeText(s));
  Writeln('}');
end;

procedure TLaTeXWriter.StartListing(Frames: Boolean; const name: String);
begin
  FInVerbatim:=True;
  if Not LaTexHighLight then
    begin
    Writeln('');
    Writeln('\begin{verbatim}');
    end
  else
    if Frames then
      Writelnf('\begin{lstlisting}{%s}',[StripText(Name)])
    else
      Writelnf('\begin{lstlisting}[frame=]{%s}',[StripText(Name)]);
end;

procedure TLaTeXWriter.EndListing;
begin
  FInVerbatim:=False;
  If LaTexHighLight then
    Writeln('\end{lstlisting}')
  else
    Writeln('\end{verbatim}')
end;

procedure TLatexWriter.WriteCommentLine;
const
  CommentLine =
    '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
begin
  Writeln(CommentLine);
end;

procedure TLatexWriter.WriteComment(Comment : String);
begin
  Write('% ');
  Writeln(Comment);
end;

procedure TLatexWriter.StartChapter(ChapterName : String);
begin
  WriteCommentLine;
  WriteComment(ChapterName);
  WriteCommentLine;
  Writeln('\chapter{'+EscapeText(ChapterName)+'}');
end;

procedure TLatexWriter.StartSection(SectionName : String);
begin
  WriteCommentLine;
  WriteComment(SectionName);
  Writeln('\section{'+EscapeText(SectionName)+'}');
end;

procedure TLatexWriter.StartSubSection(SubSectionName : String);
begin
  WriteComment(SubSectionName);
  Writeln('\subsection{'+EscapeText(SubSectionName)+'}');
end;

procedure TLatexWriter.StartSubSubSection(SubSubSectionName : String);
begin
  Writeln('\subsubsection{'+EscapeText(SubSubSectionName)+'}');
end;

procedure CreateLaTeXDocForPackage(APackage: TPasPackage; AEngine: TFPDocEngine);
var
  Writer: TLaTeXWriter;
begin
  Writer := TLaTeXWriter.Create(APackage, AEngine);
  try
    Writer.WriteDoc;
  finally
    Writer.Free;
  end;
end;

Procedure TLatexWriter.StartProcedure;

begin
  Writeln('\begin{FPCList}');
  InList:=True;
end;

Procedure TLatexWriter.StartSynopsis;

begin
  Writeln('\Synopsis');
end;

Procedure TLatexWriter.StartDeclaration;

begin
  Writeln('\Declaration ');
end;

Procedure TLatexWriter.StartVisibility;

begin
  Writeln('\Visibility');
end;

Procedure TLatexWriter.StartDescription;

begin
  Writeln('\Description');
end;

Procedure TLatexWriter.StartErrors;

begin
  Writeln('\Errors');
end;

Procedure TLatexWriter.StartAccess;

begin
  Writeln('\Access')
end;

Procedure TLatexWriter.EndProcedure;

begin
  InList:=False;
  Writeln('\end{FPCList}');
end;
Procedure TLatexWriter.StartProperty;

begin
  Writeln('\begin{FPCList}');
  InList:=True;
end;

Procedure TLatexWriter.EndProperty;

begin
  InList:=False;
  Writeln('\end{FPCList}');
end;

procedure TLateXWriter.WriteExampleFile(FN : String);

begin
  If (FN<>'') then
    WritelnF('\FPCexample{%s}', [ChangeFileExt(FN,'')]);
end;

procedure TLatexWriter.StartOverview(WithAccess : Boolean);

begin
  If WithAccess then
    begin
    WriteLn('\begin{tabularx}{\textwidth}{lllX}');
    WriteLnF('%s & %s & %s & %s \\ \hline',[EscapeText(SDocPage), EscapeText(SDocProperty), EscapeText(SDocAccess), EscapeText(SDocDescription)])
    end
  else
    begin
    WriteLn('\begin{tabularx}{\textwidth}{llX}');
    WriteLnF('%s & %s & %s  \\ \hline',[EscapeText(SDocPage), EscapeText(SDocProperty), EscapeText(SDocDescription)])
    end;
end;

procedure TLatexWriter.EndOverview;

begin
  WriteLn('\hline');
  WriteLn('\end{tabularx}');
end;

procedure TLatexWriter.WriteOverviewMember(ALabel,AName,Access,ADescr : String);

begin
  WriteLnF('\pageref{%s} & %s & %s & %s \\',[ALabel,AName,Access,ADescr]);
end;

procedure TLatexWriter.WriteOverviewMember(ALabel,AName,ADescr : String);

begin
  WriteLnF('\pageref{%s} & %s  & %s \\',[ALabel,AName,ADescr]);
end;

function TLaTeXWriter.FileNameExtension: String;
begin
  Result:=TexExtension;
end;

Procedure TLatexWriter.StartSeeAlso;

begin
  If not InList then
    begin
    Writeln('');
    Writeln('\begin{FPCList}');
    end;
  Writeln('\SeeAlso');
end;

procedure TLaTeXWriter.EndSeealso;
begin
  If Not InList then
    Writeln('\end{FPCList}');
end;

procedure TLatexWriter.StartUnitOverview(AModuleName,AModuleLabel : String);

begin
  WriteLnF('\begin{FPCltable}{lr}{%s}{%s:0units}',
    [Format(SDocUsedUnitsByUnitXY, [AModuleName]), AModuleName]);
  WriteLn('Name & Page \\ \hline');
end;

procedure TLatexWriter.WriteUnitEntry(UnitRef : TPasType);

begin
  WriteLnF('%s\index{unit!%s} & \pageref{%s} \\',
     [UnitRef.Name, UnitRef.Name, StripText(GetLabel(UnitRef))]);
end;

procedure TLatexWriter.EndUnitOverview;

begin
  WriteLn('\end{FPCltable}');
end;

Function TLatexWriter.InterPretOption(Const Cmd,Arg : String) : boolean;

begin
  Result:=True;
  if (cmd= '--latex-highlight') then
    LatexHighLight:=True
  else if Cmd = '--latex-extension' then
     TexExtension:=Arg
  else
    Result:=False;
end;

initialization
  // Do not localize.
  RegisterWriter(TLaTeXWriter,'latex','Latex output using fpc.sty class.');
finalization
  UnRegisterWriter('latex');
end.


{
  $Log: dw_latex.pp,v $
  Revision 1.11  2005/03/10 20:32:16  michael
  + Fixed subsection/section writing

  Revision 1.10  2005/02/14 17:13:39  peter
    * truncate log

  Revision 1.9  2005/01/12 21:11:41  michael
  + New structure for writers. Implemented TXT writer

  Revision 1.8  2005/01/09 15:59:50  michael
  + Split out latex writer to linear and latex writer

  Revision 1.7  2004/11/15 18:01:16  michael
  + Example fixes, and more escape seqences

  Revision 1.6  2004/07/23 23:39:48  michael
  + Some fixes in verbatim writing

  Revision 1.5  2004/06/06 10:53:02  michael
  + Added Topic support

  Revision 1.4  2003/03/18 19:28:44  michael
  + Some changes to output handling, more suitable for tex output

  Revision 1.3  2003/03/18 19:12:29  michael
  + More EscapeText calls needed

  Revision 1.2  2003/03/18 01:11:51  michael
  + Some fixes to deal with illegal tex characters

  Revision 1.1  2003/03/17 23:03:20  michael
  + Initial import in CVS

  Revision 1.13  2003/03/13 22:02:13  sg
  * New version with many bugfixes and our own parser (now independent of the
    compiler source)

  Revision 1.12  2002/10/20 22:49:31  michael
  + Sorted all overviews. Added table with enumeration values for enumerated types.

  Revision 1.11  2002/05/24 00:13:22  sg
  * much improved new version, including many linking and output fixes

  Revision 1.10  2002/03/12 10:58:36  sg
  * reworked linking engine and internal structure

  Revision 1.9  2002/01/20 11:19:55  michael
  + Added link attribute and property to TFPElement

  Revision 1.8  2002/01/08 13:00:06  michael
  + Added correct array handling and syntax highlighting is now optional

  Revision 1.7  2002/01/08 08:22:40  michael
  + Implemented latex writer

  Revision 1.6  2001/12/17 14:41:42  michael
  + Split out of latex writer

  Revision 1.5  2001/12/17 13:41:18  jonas
    * OsPathSeparator -> PathDelim
}
