{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by the Free Pascal development team

    Interface and OS-dependent part of variant support

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$MODE ObjFPC}

{$ifndef NO_SMART_LINK}
{$smartlink on}
{$endif}

Unit varutils;

Interface

Uses sysutils;

{$i varutilh.inc}

Implementation

{$i cvarutil.inc}

{ ---------------------------------------------------------------------
    Windows external definitions.
  ---------------------------------------------------------------------}

{$ifdef HASVARIANT}
const
  oleaut = 'oleaut32.dll';

{ Variant functions }

function VariantChangeTypeEx(var VargDest: TVarData; const VargSrc: TVarData; LCID: Integer; Flags: Word; VarType: Word): HRESULT; stdcall;external oleaut;
function VariantClear(var Varg: TVarData): HRESULT; stdcall;external oleaut;
function VariantCopy(var VargDest: TVarData; const VargSrc: TVarData): HRESULT; stdcall;external oleaut;
function VariantCopyInd(var VargDest: TVarData;  const VargSrc: TVarData): HRESULT; stdcall;external oleaut;
function VariantInit(var Varg: TVarData): HRESULT; stdcall;external oleaut;

{  Variant array functions }

function SafeArrayAccessData(psa: PVarArray; var ppvData: Pointer): HRESULT; stdcall;external oleaut;
function SafeArrayAllocData(psa: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayAllocDescriptor(DimCount: Integer; var psa: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayCopy(psa: PVarArray; var psaOut: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayCopyData(psa, psaOut: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayCreate(VarType, Dim: Integer; const Bounds: TVarArrayBoundArray): PVarArray; stdcall;external oleaut;
function SafeArrayDestroy(psa: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayDestroyData(psa: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayDestroyDescriptor(psa: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayGetDim(psa: PVarArray): Integer; stdcall;external oleaut;
function SafeArrayGetElemsize(psa: PVarArray): LongWord; stdcall;external oleaut;
function SafeArrayGetElement(psa: PVarArray; Indices: PVarArrayCoorArray;  Data: Pointer): HRESULT; stdcall;external oleaut;
function SafeArrayGetLBound(psa: PVarArray; Dim: Integer;  var LBound: Integer): HRESULT; stdcall;external oleaut;
function SafeArrayGetUBound(psa: PVarArray; Dim: Integer;  var UBound: Integer): HRESULT; stdcall;external oleaut;
function SafeArrayLock(psa: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayPtrOfIndex(psa: PVarArray; Indices: PVarArrayCoorArray;  var Address: Pointer): HRESULT; stdcall;external oleaut;
function SafeArrayPutElement(psa: PVarArray; Indices: PVarArrayCoorArray;  const Data: Pointer): HRESULT; stdcall;external oleaut;
function SafeArrayRedim(psa: PVarArray; const NewBound: TVarArrayBound): HRESULT; stdcall;external oleaut;
function SafeArrayUnaccessData(psa: PVarArray): HRESULT; stdcall;external oleaut;
function SafeArrayUnlock(psa: PVarArray): HRESULT; stdcall;external oleaut;
{$endif HASVARIANT}

end.

{
  $Log$
  Revision 1.5  2004-04-16 10:07:44  michael
  + Case change (bug 3050)

  Revision 1.4  2002/10/10 19:20:02  florian
    * unit is now smartlinked by default to avoid problems with an old oleauth.dll

  Revision 1.3  2002/09/07 16:01:29  peter
    * old logs removed and tabs fixed

}