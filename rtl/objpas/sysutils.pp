{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 1998 by Florian Klaempfl
    member of the Free Pascal development team

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit sysutils;
interface

{$ifndef VER0_99_5}
  {$define USE_EXCEPTIONS}
{$endif}

    uses
    {$ifdef linux}
       linux,
    {$else}
       dos,
    {$endif}
       objpas; { should become platform independent }


    type
       { some helpful data types }

       tprocedure = procedure;

       tfilename = string;

       longrec = packed record
          lo,hi : word;
       end;

       wordrec = packed record
          lo,hi : byte;
       end;

{$ifdef USE_EXCEPIONS}
       { exceptions }
       exception = class(tobject)
        private
          fmessage : string;
          fhelpcontext : longint;
        public
          constructor create(const msg : string);
//!! No array of const yet.
//          constructor createfmt(const msg; const args : array of const);
          constructor createres(indent : longint);
          { !!!! }
          property helpcontext : longint read fhelpcontext write fhelpcontext;
          property message : string read fmessage write fmessage;
       end;

       exceptclass = class of exception;

       { math. exceptions }
       einterror = class(exception);
       edivbyzero = class(einterror);
       erangeerror = class(einterror);
       eintoverflow = class(einterror);

       ematherror = class(exception);
{$endif USE_EXCEPIONS}

  { Read date & Time function declarations }
  {$i datih.inc}


  { Read String Handling functions declaration }
  {$i sysstrh.inc}


  { Read pchar handling functions declration }
  {$i syspchh.inc}

  { Read filename handling functions declaration }

  {$i finah.inc}


  implementation

  { Read filename handling functions implementation }

  {$i fina.inc}

  { Read date & Time function implementations }
  {$i dati.inc}


  { Read String Handling functions implementation }
  {$i sysstr.inc}


  { Read pchar handling functions implementation }
  {$i syspch.inc}

{$ifdef USE_EXCEPIONS}
    constructor exception.create(const msg : string);

      begin
         inherited create;
         message:=msg;
         {!!!!!}
      end;

{
    constructor exception.createfmt(const msg; const args : array of const);

      begin
         inherited create;
      end;
}

    constructor exception.createres(indent : longint);

      begin
         inherited create;
         {!!!!!}
      end;
{$endif USE_EXCEPIONS}

end.

{
    $Log$
    Revision 1.6  1998-09-16 08:28:44  michael
    Update from gertjan Schouten, plus small fix for linux

    Revision 1.5  1998/09/04 08:49:07  peter
      * 0.99.5 doesn't compile a whole objpas anymore to overcome crashes

    Revision 1.4  1998/08/10 15:52:27  peter
      * fixed so 0.99.5 compiles it, but no exception class

    Revision 1.3  1998/07/29 15:44:32  michael
     included sysutils and math.pp as target. They compile now.

    Revision 1.2  1998/04/10 15:18:21  michael
    Added a lot of functions donated by GertJan Schouten

    Revision 1.1.1.1  1998/03/25 11:18:49  root
    * Restored version

    Revision 1.1  1998/02/05 11:11:32  michael
    + moved to objpas directory

    Revision 1.2  1998/02/03 15:27:25  florian
    *** empty log message ***

    Revision 1.1  1998/02/01 23:32:01  florian
      + initial revision

}

