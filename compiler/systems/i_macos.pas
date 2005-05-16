{
    $Id: i_macos.pas,v 1.20 2005/03/20 22:36:45 olle Exp $
    Copyright (c) 1998-2002 by Peter Vreman

    This unit implements support information structures for MacOS

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
{ This unit implements support information structures for MacOS. }
unit i_macos;

  interface

    uses
       systems;
     const
       system_powerpc_macos_info : tsysteminfo =
          (
            system       : system_powerpc_MACOS;
            name         : 'Mac OS for PowerPC';
            shortname    : 'MacOS';
            flags        : [];
            cpu          : cpu_powerpc;
            unit_env     : '';
            extradefines : '';
            exeext       : '';
            defext       : '';
            scriptext    : '';
            smartext     : '.sl';
            unitext      : '.ppu';
            unitlibext   : '.ppl';
            asmext       : '.s';
            objext       : '.o';
            resext       : '.res';
            resobjext    : '.or';
            sharedlibext : 'Lib';
            staticlibext : 'Lib';
            staticlibprefix : '';
            sharedlibprefix : '';
            sharedClibext : 'Lib';
            staticClibext : 'Lib';
            staticClibprefix : '';
            sharedClibprefix : '';
            p_ext_support : true;
            Cprefix      : '';
            newline      : #13;
            dirsep       : ':';
            files_case_relevent : false;
            assem        : as_powerpc_mpw;
            assemextern  : as_powerpc_mpw;
            link         : nil;
            linkextern   : nil;
            ar           : ar_mpw_ar;
            res          : res_powerpc_mpw;
            script       : script_mpw;
            endian       : endian_big;
            alignment    :
              (
                procalign       : 4;
                loopalign       : 4;
                jumpalign       : 0;
                constalignmin   : 0;
                constalignmax   : 4;
                varalignmin     : 0;
                varalignmax     : 4;
                localalignmin   : 8;
                localalignmax   : 8;
                recordalignmin  : 0;
                recordalignmax  : 2;
                maxCrecordalign : 16
              );
            first_parm_offset : 8;
            stacksize    : 262144;
            DllScanSupported:false;
            use_function_relative_addresses : true;
            abi : abi_powerpc_aix;
          );

  implementation

initialization
{$ifdef cpupowerpc}
  {$ifdef macos}
    set_source_info(system_powerpc_macos_info);
  {$endif macos}
{$endif cpupowerpc}
end.
{
  $Log: i_macos.pas,v $
  Revision 1.20  2005/03/20 22:36:45  olle
    * Cleaned up handling of source file extension.
    + Added support for .p extension for macos and darwin

  Revision 1.19  2005/02/14 17:13:10  peter
    * truncate log

}
