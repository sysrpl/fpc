{
    $Id$
    This file is part of the Free Pascal run time library.
    Amiga exec.library include file
    Copyright (c) 1997 by Nils Sjoholm
    member of the Amiga RTL development team.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit Exec;

INTERFACE

TYPE

       STRPTR   = PChar;
       ULONG    = Longint;
       LONG     = longint;
       APTR     = Pointer;
       BPTR     = Longint;
       BSTR     = Longint;
       pWord    = ^Word;
       pLongint = ^Longint;
       pInteger = ^Integer;


TYPE

{$PACKRECORDS 4}

{ *  List Node Structure.  Each member in a list starts with a Node * }

  pNode = ^tNode;
  tNode = Record
    ln_Succ,                { * Pointer to next (successor) * }
    ln_Pred  : pNode;       { * Pointer to previous (predecessor) * }
    ln_Type  : Byte;
    ln_Pri   : Shortint;        { * Priority, for sorting * }
    ln_Name  : STRPTR;      { * ID string, null terminated * }
  End;  { * Note: Integer aligned * }

{$PACKRECORDS NORMAL}

{ * minimal node -- no type checking possible * }

  pMinNode = ^tMinNode;
  tMinNode = Record
    mln_Succ,
    mln_Pred  : pMinNode;
  End;



{ *
** Note: Newly initialized IORequests, and software interrupt structures
** used with Cause(), should have type NT_UNKNOWN.  The OS will assign a type
** when they are first used.
* }

{ *----- Node Types for LN_TYPE -----* }

Const

  NT_UNKNOWN      =  0;
  NT_TASK     =  1;  { * Exec task * }
  NT_INTERRUPT    =  2;
  NT_DEVICE   =  3;
  NT_MSGPORT      =  4;
  NT_MESSAGE      =  5;  { * Indicates message currently pending * }
  NT_FREEMSG      =  6;
  NT_REPLYMSG     =  7;  { * Message has been replied * }
  NT_RESOURCE     =  8;
  NT_LIBRARY      =  9;
  NT_MEMORY   = 10;
  NT_SOFTINT      = 11;  { * Internal flag used by SoftInits * }
  NT_FONT     = 12;
  NT_PROCESS      = 13;  { * AmigaDOS Process * }
  NT_SEMAPHORE    = 14;
  NT_SIGNALSEM    = 15;  { * signal semaphores * }
  NT_BOOTNODE     = 16;
  NT_KICKMEM      = 17;
  NT_GRAPHICS     = 18;
  NT_DEATHMESSAGE = 19;

  NT_USER     = 254;  { * User node types work down from here * }
  NT_EXTENDED     = 255;

{
    This file defines Exec system lists, which are used to link
    various things.  Exec provides several routines to handle list
    processing (defined at the bottom of this file), so you can
    use these routines to save yourself the trouble of writing a list
    package.
}


Type

{ normal, full featured list }

    pList = ^tList;
    tList = record
    lh_Head     : pNode;
    lh_Tail     : pNode;
    lh_TailPred : pNode;
    lh_Type     : Byte;
    l_pad       : Byte;
    end;

{ minimum list -- no type checking possible }

    pMinList = ^tMinList;
    tMinList = record
    mlh_Head        : pMinNode;
    mlh_Tail        : pMinNode;
    mlh_TailPred    : pMinNode;
    end;



{ ********************************************************************
*
*  Format of the alert error number:
*
*    +-+-------------+----------------+--------------------------------+
*    |D|  SubSysId   |  General Error |    SubSystem Specific Error    |
*    +-+-------------+----------------+--------------------------------+
*     1    7 bits          8 bits                  16 bits
*
*                    D:  DeadEnd alert
*             SubSysId:  indicates ROM subsystem number.
*        General Error:  roughly indicates what the error was
*       Specific Error:  indicates more detail
*********************************************************************}

const
{*********************************************************************
*
*  Hardware/CPU specific alerts:  They may show without the 8 at the
*  front of the number.  These are CPU/68000 specific.  See 68$0
*  programmer's manuals for more details.
*
*********************************************************************}
    ACPU_BusErr     = $80000002;      { Hardware bus fault/access error }
    ACPU_AddressErr = $80000003;      { Illegal address access (ie: odd) }
    ACPU_InstErr    = $80000004;      { Illegal instruction }
    ACPU_DivZero    = $80000005;      { Divide by zero }
    ACPU_CHK        = $80000006;      { Check instruction error }
    ACPU_TRAPV      = $80000007;      { TrapV instruction error }
    ACPU_PrivErr    = $80000008;      { Privilege violation error }
    ACPU_Trace      = $80000009;      { Trace error }
    ACPU_LineA      = $8000000A;      { Line 1010 Emulator error }
    ACPU_LineF      = $8000000B;      { Line 1111 Emulator error }
    ACPU_Format     = $8000000E;      { Stack frame format error }
    ACPU_Spurious   = $80000018;      { Spurious interrupt error }
    ACPU_AutoVec1   = $80000019;      { AutoVector Level 1 interrupt error }
    ACPU_AutoVec2   = $8000001A;      { AutoVector Level 2 interrupt error }
    ACPU_AutoVec3   = $8000001B;      { AutoVector Level 3 interrupt error }
    ACPU_AutoVec4   = $8000001C;      { AutoVector Level 4 interrupt error }
    ACPU_AutoVec5   = $8000001D;      { AutoVector Level 5 interrupt error }
    ACPU_AutoVec6   = $8000001E;      { AutoVector Level 6 interrupt error }
    ACPU_AutoVec7   = $8000001F;      { AutoVector Level 7 interrupt error }


{ ********************************************************************
*
*  General Alerts
*
*  For example: timer.device cannot open math.library would be $05038015
*
*       Alert(AN_TimerDev|AG_OpenLib|AO_MathLib);
*
********************************************************************}


CONST

{ ------ alert types }
  AT_DeadEnd    = $80000000;
  AT_Recovery   = $00000000;


{ ------ general purpose alert codes }
  AG_NoMemory   = $00010000;
  AG_MakeLib    = $00020000;
  AG_OpenLib    = $00030000;
  AG_OpenDev    = $00040000;
  AG_OpenRes    = $00050000;
  AG_IOError    = $00060000;
  AG_NoSignal   = $00070000;
  AG_BadParm    = $00080000;
  AG_CloseLib   = $00090000;    { usually too many closes }
  AG_CloseDev   = $000A0000;    { or a mismatched close }
  AG_ProcCreate = $000B0000;    { Process creation failed }


{ ------ alert objects: }
  AO_ExecLib      = $00008001;
  AO_GraphicsLib  = $00008002;
  AO_LayersLib    = $00008003;
  AO_Intuition    = $00008004;
  AO_MathLib      = $00008005;
  AO_DOSLib       = $00008007;
  AO_RAMLib       = $00008008;
  AO_IconLib      = $00008009;
  AO_ExpansionLib = $0000800A;
  AO_DiskfontLib  = $0000800B;
  AO_UtilityLib   = $0000800C;
  AO_KeyMapLib    = $0000800D;

  AO_AudioDev     = $00008010;
  AO_ConsoleDev   = $00008011;
  AO_GamePortDev  = $00008012;
  AO_KeyboardDev  = $00008013;
  AO_TrackDiskDev = $00008014;
  AO_TimerDev     = $00008015;

  AO_CIARsrc    = $00008020;
  AO_DiskRsrc   = $00008021;
  AO_MiscRsrc   = $00008022;

  AO_BootStrap  = $00008030;
  AO_Workbench  = $00008031;
  AO_DiskCopy   = $00008032;
  AO_GadTools   = $00008033;
  AO_Unknown    = $00008035;



{ ********************************************************************
*
*   Specific Alerts:
*
********************************************************************}

{ ------ exec.library }

  AN_ExecLib    = $01000000;
  AN_ExcptVect  = $01000001; {  68000 exception vector checksum (obs.) }
  AN_BaseChkSum = $01000002; {  Execbase checksum (obs.) }
  AN_LibChkSum  = $01000003; {  Library checksum failure }

  AN_MemCorrupt = $81000005; {  Corrupt memory list detected in FreeMem }
  AN_IntrMem    = $81000006; {  No memory for interrupt servers }
  AN_InitAPtr   = $01000007; {  InitStruct() of an APTR source (obs.) }
  AN_SemCorrupt = $01000008; {  A semaphore is in an illegal state
                                      at ReleaseSempahore() }
  AN_FreeTwice    = $01000009; {  Freeing memory already freed }
  AN_BogusExcpt   = $8100000A; {  illegal 68k exception taken (obs.) }
  AN_IOUsedTwice  = $0100000B; {  Attempt to reuse active IORequest }
  AN_MemoryInsane = $0100000C; {  Sanity check on memory list failed
                                      during AvailMem(MEMF_LARGEST) }
  AN_IOAfterClose = $0100000D; {  IO attempted on closed IORequest }
  AN_StackProbe   = $0100000E; {  Stack appears to extend out of range }
  AN_BadFreeAddr  = $0100000F; {  Memory header not located. [ Usually an
                                  invalid address passed to FreeMem() ] }
  AN_BadSemaphore = $01000010; { An attempt was made to use the old
                                      message semaphores. }

{ ------ graphics.library }

  AN_GraphicsLib  = $02000000;
  AN_GfxNoMem     = $82010000;  {  graphics out of memory }
  AN_GfxNoMemMspc = $82010001;  {  MonitorSpec alloc, no memory }
  AN_LongFrame    = $82010006;  {  long frame, no memory }
  AN_ShortFrame   = $82010007;  {  short frame, no memory }
  AN_TextTmpRas   = $02010009;  {  text, no memory for TmpRas }
  AN_BltBitMap    = $8201000A;  {  BltBitMap, no memory }
  AN_RegionMemory = $8201000B;  {  regions, memory not available }
  AN_MakeVPort    = $82010030;  {  MakeVPort, no memory }
  AN_GfxNewError  = $0200000C;
  AN_GfxFreeError = $0200000D;

  AN_GfxNoLCM     = $82011234;  {  emergency memory not available }

  AN_ObsoleteFont = $02000401;  {  unsupported font description used }

{ ------ layers.library }

  AN_LayersLib    = $03000000;
  AN_LayersNoMem  = $83010000;  {  layers out of memory }

{ ------ intuition.library }
  AN_Intuition    = $04000000;
  AN_GadgetType   = $84000001;  {  unknown gadget type }
  AN_BadGadget    = $04000001;  {  Recovery form of AN_GadgetType }
  AN_CreatePort   = $84010002;  {  create port, no memory }
  AN_ItemAlloc    = $04010003;  {  item plane alloc, no memory }
  AN_SubAlloc     = $04010004;  {  sub alloc, no memory }
  AN_PlaneAlloc   = $84010005;  {  plane alloc, no memory }
  AN_ItemBoxTop   = $84000006;  {  item box top < RelZero }
  AN_OpenScreen   = $84010007;  {  open screen, no memory }
  AN_OpenScrnRast = $84010008;  {  open screen, raster alloc, no memory }
  AN_SysScrnType  = $84000009;  {  open sys screen, unknown type }
  AN_AddSWGadget  = $8401000A;  {  add SW gadgets, no memory }
  AN_OpenWindow   = $8401000B;  {  open window, no memory }
  AN_BadState     = $8400000C;  {  Bad State Return entering Intuition }
  AN_BadMessage   = $8400000D;  {  Bad Message received by IDCMP }
  AN_WeirdEcho    = $8400000E;  {  Weird echo causing incomprehension }
  AN_NoConsole    = $8400000F;  {  couldn't open the Console Device }
  AN_NoISem       = $04000010;  { Intuition skipped obtaining a sem }
  AN_ISemOrder    = $04000011;  { Intuition obtained a sem in bad order }

{ ------ math.library }

  AN_MathLib      = $05000000;

{ ------ dos.library }

  AN_DOSLib       = $07000000;
  AN_StartMem     = $07010001; {  no memory at startup }
  AN_EndTask      = $07000002; {  EndTask didn't }
  AN_QPktFail     = $07000003; {  Qpkt failure }
  AN_AsyncPkt     = $07000004; {  Unexpected packet received }
  AN_FreeVec      = $07000005; {  Freevec failed }
  AN_DiskBlkSeq   = $07000006; {  Disk block sequence error }
  AN_BitMap       = $07000007; {  Bitmap corrupt }
  AN_KeyFree      = $07000008; {  Key already free }
  AN_BadChkSum    = $07000009; {  Invalid checksum }
  AN_DiskError    = $0700000A; {  Disk Error }
  AN_KeyRange     = $0700000B; {  Key out of range }
  AN_BadOverlay   = $0700000C; {  Bad overlay }
  AN_BadInitFunc  = $0700000D; {  Invalid init packet for cli/shell }
  AN_FileReclosed = $0700000E; {  A filehandle was closed more than once }

{ ------ ramlib.library }

  AN_RAMLib       = $08000000;
  AN_BadSegList   = $08000001;  {  no overlays in library seglists }

{ ------ icon.library }

  AN_IconLib      = $09000000;

{ ------ expansion.library }

  AN_ExpansionLib       = $0A000000;
  AN_BadExpansionFree   = $0A000001; {  freeed free region }

{ ------ diskfont.library }

  AN_DiskfontLib        = $0B000000;

{ ------ audio.device }

  AN_AudioDev   = $10000000;

{ ------ console.device }

  AN_ConsoleDev = $11000000;
  AN_NoWindow   = $11000001;    {  Console can't open initial window }

{ ------ gameport.device }

  AN_GamePortDev        = $12000000;

{ ------ keyboard.device }

  AN_KeyboardDev        = $13000000;

{ ------ trackdisk.device }

  AN_TrackDiskDev = $14000000;
  AN_TDCalibSeek  = $14000001;  {  calibrate: seek error }
  AN_TDDelay      = $14000002;  {  delay: error on timer wait }

{ ------ timer.device }

  AN_TimerDev     = $15000000;
  AN_TMBadReq     = $15000001; {  bad request }
  AN_TMBadSupply  = $15000002; {  power supply -- no 50/60Hz ticks }

{ ------ cia.resource }

  AN_CIARsrc      = $20000000;

{ ------ disk.resource }

  AN_DiskRsrc   = $21000000;
  AN_DRHasDisk  = $21000001;    {  get unit: already has disk }
  AN_DRIntNoAct = $21000002;    {  interrupt: no active unit }

{ ------ misc.resource }

  AN_MiscRsrc   = $22000000;

{ ------ bootstrap }

  AN_BootStrap  = $30000000;
  AN_BootError  = $30000001;    {  boot code returned an error }

{ ------ Workbench }

  AN_Workbench          = $31000000;
  AN_NoFonts            = $B1000001;
  AN_WBBadStartupMsg1   = $31000001;
  AN_WBBadStartupMsg2   = $31000002;
  AN_WBBadIOMsg         = $31000003;

  AN_WBReLayoutToolMenu          = $B1010009;

{ ------ DiskCopy }

  AN_DiskCopy   = $32000000;

{ ------ toolkit for Intuition }

  AN_GadTools   = $33000000;

{ ------ System utility library }

  AN_UtilityLib = $34000000;

{ ------ For use by any application that needs it }

  AN_Unknown    = $35000000;



CONST

  IOERR_OPENFAIL   = -1;    {  device/unit failed to open  }
  IOERR_ABORTED    = -2;    {  request terminated early [after AbortIO()]  }
  IOERR_NOCMD      = -3;    {  command not supported by device  }
  IOERR_BADLENGTH  = -4;    {  not a valid length (usually IO_LENGTH)  }
  IOERR_BADADDRESS = -5;    {  invalid address (misaligned or bad range)  }
  IOERR_UNITBUSY   = -6;    {  device opens ok, but requested unit is busy  }
  IOERR_SELFTEST   = -7;    {  hardware failed self-test  }



type
    pResident = ^tResident;
    tResident = record
    rt_MatchWord  : Word;        { Integer to match on (ILLEGAL)  }
    rt_MatchTag   : pResident;    { pointer to the above        }
    rt_EndSkip    : Pointer;      { address to continue scan    }
    rt_Flags      : Byte;        { various tag flags           }
    rt_Version    : Byte;        { release version number      }
    rt_Type       : Byte;        { type of module (NT_mumble)  }
    rt_Pri        : Shortint;         { initialization priority     }
    rt_Name       : STRPTR;       { pointer to node name        }
    rt_IdString   : STRPTR;       { pointer to ident string     }
    rt_Init       : Pointer;      { pointer to init code        }
    end;

const


    RTC_MATCHWORD   = $4AFC;

    RTF_AUTOINIT    = $80;
    RTF_AFTERDOS    = $04;
    RTF_SINGLETASK  = $02;
    RTF_COLDSTART   = $01;


{ Compatibility: }

    RTM_WHEN        = $03;
    RTW_COLDSTART   = $01;
    RTW_NEVER       = $00;



TYPE

{ ****** MemChunk **************************************************** }

  pMemChunk = ^tMemChunk;
  tMemChunk = Record
    mc_Next  : pMemChunk;       { * pointer to next chunk * }
    mc_Bytes : ULONG;           { * chunk byte size     * }
  End;


{ ****** MemHeader *************************************************** }

  pMemHeader = ^tMemHeader;
  tMemHeader = Record
    mh_Node       : tNode;
    mh_Attributes : Word;       { * characteristics of this region * }
    mh_First      : pMemChunk;   { * first free region          * }
    mh_Lower,                    { * lower memory bound         * }
    mh_Upper      : Pointer;     { * upper memory bound+1       * }
    mh_Free       : Ulong;       { * total number of free bytes * }
  End;


{ ****** MemEntry **************************************************** }

  pMemUnit = ^tMemUnit;
  tMemUnit = Record
      meu_Reqs  : ULONG;        { * the AllocMem requirements * }
      meu_Addr  : Pointer;      { * the address of this memory region * }
  End;

  pMemEntry = ^tMemEntry;
  tMemEntry = Record
    me_Un       : tMemUnit;
    me_Length   : ULONG;        { * the length of this memory region * }
  End;


{ ****** MemList ***************************************************** }

{ * Note: sizeof(struct MemList) includes the size of the first MemEntry! * }

  pMemList = ^tMemList;
  tMemList = Record
    ml_Node       : tNode;
    ml_NumEntries : Word;      { * number of entries in this struct * }
    ml_ME         : Array [0..0] of tMemEntry;    { * the first entry * }
  End;

{ *----- Memory Requirement Types ---------------------------* }
{ *----- See the AllocMem() documentation for details--------* }

Const

   MEMF_ANY      = %000000000000000000000000;   { * Any type of memory will do * }
   MEMF_PUBLIC   = %000000000000000000000001;
   MEMF_CHIP     = %000000000000000000000010;
   MEMF_FAST     = %000000000000000000000100;
   MEMF_LOCAL    = %000000000000000100000000;
   MEMF_24BITDMA = %000000000000001000000000;   { * DMAable memory within 24 bits of address * }
   MEMF_KICK     = %000000000000010000000000;   { Memory that can be used for KickTags }

   MEMF_CLEAR    = %000000010000000000000000;
   MEMF_LARGEST  = %000000100000000000000000;
   MEMF_REVERSE  = %000001000000000000000000;
   MEMF_TOTAL    = %000010000000000000000000;   { * AvailMem: return total size of memory * }
   MEMF_NO_EXPUNGE = $80000000;   {AllocMem: Do not cause expunge on failure }

   MEM_BLOCKSIZE = 8;
   MEM_BLOCKMASK = MEM_BLOCKSIZE-1;

Type
{***** MemHandlerData *********************************************}
{ Note:  This structure is *READ ONLY* and only EXEC can create it!}

 pMemHandlerData = ^tMemHandlerData;
 tMemHandlerData = Record
        memh_RequestSize,       { Requested allocation size }
        memh_RequestFlags,      { Requested allocation flags }
        memh_Flags  : ULONG;    { Flags (see below) }
 end;

const
    MEMHF_RECYCLE  = 1; { 0==First time, 1==recycle }

{***** Low Memory handler return values **************************}
    MEM_DID_NOTHING = 0;     { Nothing we could do... }
    MEM_ALL_DONE    = -1;    { We did all we could do }
    MEM_TRY_AGAIN   = 1;     { We did some, try the allocation again }


type
    pInterrupt = ^tInterrupt;
    tInterrupt = record
        is_Node : tNode;
        is_Data : Pointer;      { Server data segment }
        is_Code : Pointer;      { Server code entry }
    end;

    pIntVector = ^tIntVector;
    tIntVector = record          { For EXEC use ONLY! }
        iv_Data : Pointer;
        iv_Code : Pointer;
        iv_Node : pNode;
    end;

    pSoftIntList = ^tSoftIntList;
    tSoftIntList = record        { For EXEC use ONLY! }
        sh_List : tList;
        sh_Pad  : Word;
    end;

const
    SIH_PRIMASK = $F0;

{ this is a fake INT definition, used only for AddIntServer and the like }

    INTB_NMI    = 15;
    INTF_NMI    = $0080;

{
    Every Amiga Task has one of these Task structures associated with it.
    To find yours, use FindTask(Nil).  AmigaDOS processes tack a few more
    values on to the end of this structure, which is the difference between
    Tasks and Processes.
}

type
  
    pTask = ^tTask;
    tTask = record
        tc_Node         : tNode;
        tc_Flags        : Byte;
        tc_State        : Byte;
        tc_IDNestCnt    : Shortint;         { intr disabled nesting         }
        tc_TDNestCnt    : Shortint;         { task disabled nesting         }
        tc_SigAlloc     : ULONG;        { sigs allocated                }
        tc_SigWait      : ULONG;        { sigs we are waiting for       }
        tc_SigRecvd     : ULONG;        { sigs we have received         }
        tc_SigExcept    : ULONG;        { sigs we will take excepts for }
        tc_TrapAlloc    : Word;        { traps allocated               }
        tc_TrapAble     : Word;        { traps enabled                 }
        tc_ExceptData   : Pointer;      { points to except data         }
        tc_ExceptCode   : Pointer;      { points to except code         }
        tc_TrapData     : Pointer;      { points to trap data           }
        tc_TrapCode     : Pointer;      { points to trap code           }
        tc_SPReg        : Pointer;      { stack pointer                 }
        tc_SPLower      : Pointer;      { stack lower bound             }
        tc_SPUpper      : Pointer;      { stack upper bound + 2         }
        tc_Switch       : Pointer;      { task losing CPU               }
        tc_Launch       : Pointer;      { task getting CPU              }
        tc_MemEntry     : tList;        { allocated memory              }
        tc_UserData     : Pointer;      { per task data                 }
    end;

{
 * Stack swap structure as passed to StackSwap()
 }
  pStackSwapStruct = ^tStackSwapStruct;
  tStackSwapStruct = Record
        stk_Lower       : Pointer;      { Lowest byte of stack }
        stk_Upper       : ULONG;        { Upper end of stack (size + Lowest) }
        stk_Pointer     : Pointer;      { Stack pointer at switch point }
  end;



{----- Flag Bits ------------------------------------------}

const

    TB_PROCTIME         = 0;
    TB_ETASK            = 3;
    TB_STACKCHK         = 4;
    TB_EXCEPT           = 5;
    TB_SWITCH           = 6;
    TB_LAUNCH           = 7;

    TF_PROCTIME         = 1;
    TF_ETASK            = 8;
    TF_STACKCHK         = 16;
    TF_EXCEPT           = 32;
    TF_SWITCH           = 64;
    TF_LAUNCH           = 128;

{----- Task States ----------------------------------------}

    TS_INVALID          = 0;
    TS_ADDED            = 1;
    TS_RUN              = 2;
    TS_READY            = 3;
    TS_WAIT             = 4;
    TS_EXCEPT           = 5;
    TS_REMOVED          = 6;

{----- Predefined Signals -------------------------------------}

    SIGB_ABORT          = 0;
    SIGB_CHILD          = 1;
    SIGB_BLIT           = 4;
    SIGB_SINGLE         = 4;
    SIGB_INTUITION      = 5;
    SIGB_DOS            = 8;

    SIGF_ABORT          = 1;
    SIGF_CHILD          = 2;
    SIGF_BLIT           = 16;
    SIGF_SINGLE         = 16;
    SIGF_INTUITION      = 32;
    SIGF_DOS            = 256;



{
    This file defines ports and messages, which are used for inter-
    task communications using the routines defined toward the
    bottom of this file.
}

type

{****** MsgPort *****************************************************}

    pMsgPort = ^tMsgPort;
    tMsgPort = record
    mp_Node     : tNode;
    mp_Flags    : Byte;
    mp_SigBit   : Byte;     { signal bit number    }
    mp_SigTask  : Pointer;   { task to be signalled (TaskPtr) }
    mp_MsgList  : tList;     { message linked list  }
    end;

{****** Message *****************************************************}

    pMessage = ^tMessage;
    tMessage = record
    mn_Node       : tNode;
    mn_ReplyPort  : pMsgPort;   { message reply port }
    mn_Length     : Word;      { message len in bytes }
    end;



{ mp_Flags: Port arrival actions (PutMsg) }

CONST

  PF_ACTION = 3;    { * Mask * }
  PA_SIGNAL = 0;    { * Signal task in mp_SigTask * }
  PA_SOFTINT    = 1;    { * Signal SoftInt in mp_SoftInt/mp_SigTask * }
  PA_IGNORE = 2;    { * Ignore arrival * }


        { Semaphore }
type
    pSemaphore = ^tSemaphore;
    tSemaphore = record
        sm_MsgPort : tMsgPort;
        sm_Bids    : Integer;
    end;

{  This is the structure used to request a signal semaphore }

    pSemaphoreRequest = ^tSemaphoreRequest;
    tSemaphoreRequest = record
        sr_Link    : tMinNode;
        sr_Waiter  : pTask;
    end;

{ The actual semaphore itself }

    pSignalSemaphore = ^tSignalSemaphore;
    tSignalSemaphore = record
        ss_Link         : tNode;
        ss_NestCount    : Integer;
        ss_WaitQueue    : tMinList;
        ss_MultipleLink : tSemaphoreRequest;
        ss_Owner        : pTask;
        ss_QueueCount   : Integer;
    end;


{  ***** Semaphore procure message (for use in V39 Procure/Vacate *** }


 pSemaphoreMessage = ^tSemaphoreMessage;
 tSemaphoreMessage = Record
   ssm_Message   : tMessage;
   ssm_Semaphore : pSignalSemaphore;
 end;

const
 SM_SHARED      = 1;
 SM_EXCLUSIVE   = 0;


CONST

{ ------ Special Constants --------------------------------------- }
  LIB_VECTSIZE  =  6;   {  Each library entry takes 6 bytes  }
  LIB_RESERVED  =  4;   {  Exec reserves the first 4 vectors  }
  LIB_BASE  = (-LIB_VECTSIZE);
  LIB_USERDEF   = (LIB_BASE-(LIB_RESERVED*LIB_VECTSIZE));
  LIB_NONSTD    = (LIB_USERDEF);

{ ------ Standard Functions -------------------------------------- }
  LIB_OPEN  =  -6;
  LIB_CLOSE = -12;
  LIB_EXPUNGE   = -18;
  LIB_EXTFUNC   = -24;  {  for future expansion  }

TYPE

{ ------ Library Base Structure ---------------------------------- }
{  Also used for Devices and some Resources  }

    pLibrary = ^tLibrary;
    tLibrary = record
        lib_Node     : tNode;
        lib_Flags,
        lib_pad      : Byte;
        lib_NegSize,            {  number of bytes before library  }
        lib_PosSize,            {  number of bytes after library  }
        lib_Version,            {  major  }
        lib_Revision : Word;   {  minor  }
        lib_IdString : STRPTR;  {  ASCII identification  }
        lib_Sum      : ULONG;   {  the checksum itself  }
        lib_OpenCnt  : Word;   {  number of current opens  }
    end;                {  * Warning: size is not a longword multiple ! * }

CONST

{  lib_Flags bit definitions (all others are system reserved)  }

  LIBF_SUMMING = %00000001; {  we are currently checksumming  }
  LIBF_CHANGED = %00000010; {  we have just changed the lib  }
  LIBF_SUMUSED = %00000100; {  set if we should bother to sum  }
  LIBF_DELEXP  = %00001000; {  delayed expunge  }

{
    This file defines the constants and types required to use
    Amiga device IO routines, which are also defined here.
}


TYPE

{***** Device *****************************************************}
  pDevice = ^tDevice;
  tDevice = record
    dd_Library : tLibrary;
  end;

{***** Unit *******************************************************}
  pUnit = ^tUnit;
  tUnit = record
      unit_MsgPort : tMsgPort;     { queue for unprocessed messages }
                    { instance of msgport is recommended }
      unit_flags,
      unit_pad     : Byte;
      unit_OpenCnt : Word;       { number of active opens }
  end;

Const
  UNITF_ACTIVE  = %00000001;
  UNITF_INTASK  = %00000010;

type

    pIORequest = ^tIORequest;
    tIORequest = record
    io_Message  : tMessage;
    io_Device   : pDevice;      { device node pointer  }
    io_Unit     : pUnit;        { unit (driver private)}
    io_Command  : Word;        { device command }
    io_Flags    : Byte;
    io_Error    : Shortint;         { error or warning num }
    end;

    pIOStdReq = ^tIOStdReq;
    tIOStdReq = record
    io_Message  : tMessage;
    io_Device   : pDevice;      { device node pointer  }
    io_Unit     : pUnit;        { unit (driver private)}
    io_Command  : Word;        { device command }
    io_Flags    : Byte;
    io_Error    : Shortint;         { error or warning num }
    io_Actual   : ULONG;        { actual number of bytes transferred }
    io_Length   : ULONG;        { requested number bytes transferred}
    io_Data     : Pointer;      { points to data area }
    io_Offset   : ULONG;        { offset for block structured devices }
    end;


{ library vector offsets for device reserved vectors }

const
    DEV_BEGINIO = -30;
    DEV_ABORTIO = -36;

{ io_Flags defined bits }

    IOB_QUICK   = 0;
    IOF_QUICK   = 1;

    CMD_INVALID = 0;
    CMD_RESET   = 1;
    CMD_READ    = 2;
    CMD_WRITE   = 3;
    CMD_UPDATE  = 4;
    CMD_CLEAR   = 5;
    CMD_STOP    = 6;
    CMD_START   = 7;
    CMD_FLUSH   = 8;

    CMD_NONSTD  = 9;




{  Definition of the Exec library base structure (pointed to by location 4).
** Most fields are not to be viewed or modified by user programs.  Use
** extreme caution.
 }

type

pExecBase = ^tExecBase;
tExecBase = Record
        LibNode    : tLibrary;   {  Standard library node  }

{ ******* Static System Variables ******* }

        SoftVer      : Word;   {  kickstart release number (obs.)  }
        LowMemChkSum : Integer;    {  checksum of 68000 trap vectors  }
        ChkBase      : ULONG;   {  system base pointer complement  }
        ColdCapture,            {  coldstart soft capture vector  }
        CoolCapture,            {  coolstart soft capture vector  }
        WarmCapture,            {  warmstart soft capture vector  }
        SysStkUpper,            {  system stack base   (upper bound)  }
        SysStkLower  : Pointer; {  top of system stack (lower bound)  }
        MaxLocMem    : ULONG;   {  top of chip memory  }
        DebugEntry,             {  global debugger entry point  }
        DebugData,              {  global debugger data segment  }
        AlertData,              {  alert data segment  }
        MaxExtMem    : Pointer; {  top of extended mem, or null if none  }

        ChkSum       : Word;   {  for all of the above (minus 2)  }

{ ***** Interrupt Related ************************************** }

        IntVects     : Array[0..15] of tIntVector;

{ ***** Dynamic System Variables ************************************ }

        ThisTask     : pTask;   {  pointer to current task (readable)  }

        IdleCount,              {  idle counter  }
        DispCount    : ULONG;   {  dispatch counter  }
        Quantum,                {  time slice quantum  }
        Elapsed,                {  current quantum ticks  }
        SysFlags     : Word;   {  misc internal system flags  }
        IDNestCnt,              {  interrupt disable nesting count  }
        TDNestCnt    : Shortint;    {  task disable nesting count  }

        AttnFlags,              {  special attention flags (readable)  }
        AttnResched  : Word;   {  rescheduling attention  }
        ResModules,             {  resident module array pointer  }
        TaskTrapCode,
        TaskExceptCode,
        TaskExitCode : Pointer;
        TaskSigAlloc : ULONG;
        TaskTrapAlloc: Word;


{ ***** System Lists (private!) ******************************* }

        MemList,
        ResourceList,
        DeviceList,
        IntrList,
        LibList,
        PortList,
        TaskReady,
        TaskWait     : tList;

        SoftInts     : Array[0..4] of tSoftIntList;

{ ***** Other Globals ****************************************** }

        LastAlert    : Array[0..3] of LONG;

        {  these next two variables are provided to allow
        ** system developers to have a rough idea of the
        ** period of two externally controlled signals --
        ** the time between vertical blank interrupts and the
        ** external line rate (which is counted by CIA A's
        ** "time of day" clock).  In general these values
        ** will be 50 or 60, and may or may not track each
        ** other.  These values replace the obsolete AFB_PAL
        ** and AFB_50HZ flags.
         }

        VBlankFrequency,                {  (readable)  }
        PowerSupplyFrequency : Byte;   {  (readable)  }

        SemaphoreList    : tList;

        {  these next two are to be able to kickstart into user ram.
        ** KickMemPtr holds a singly linked list of MemLists which
        ** will be removed from the memory list via AllocAbs.  If
        ** all the AllocAbs's succeeded, then the KickTagPtr will
        ** be added to the rom tag list.
         }

        KickMemPtr,             {  ptr to queue of mem lists  }
        KickTagPtr,             {  ptr to rom tag queue  }
        KickCheckSum : Pointer; {  checksum for mem and tags  }

{ ***** V36 Exec additions start here ************************************* }

        ex_Pad0           : Word;
        ex_Reserved0      : ULONG;
        ex_RamLibPrivate  : Pointer;

        {  The next ULONG contains the system "E" clock frequency,
        ** expressed in Hertz.  The E clock is used as a timebase for
        ** the Amiga's 8520 I/O chips. (E is connected to "02").
        ** Typical values are 715909 for NTSC, or 709379 for PAL.
         }

        ex_EClockFrequency,         {  (readable)  }
        ex_CacheControl,            {  Private to CacheControl calls  }
        ex_TaskID         : ULONG;  {  Next available task ID  }

        ex_Reserved1      : Array[0..4] of ULONG;

        ex_MMULock        : Pointer;    {  private  }

        ex_Reserved2      : Array[0..2] of ULONG;
{***** V39 Exec additions start here *************************************}

        { The following list and data element are used
         * for V39 exec's low memory handler...
         }
        ex_MemHandlers    : tMinList; { The handler list }
        ex_MemHandler     : Pointer;          { Private! handler pointer }
        ex_Reserved       : Array[0..1] of Shortint;
end;


{ ***** Bit defines for AttnFlags (see above) ***************************** }

{   Processors and Co-processors:  }

CONST

  AFB_68010     = 0;    {  also set for 68020  }
  AFB_68020     = 1;    {  also set for 68030  }
  AFB_68030     = 2;    {  also set for 68040  }
  AFB_68040     = 3;
  AFB_68881     = 4;    {  also set for 68882  }
  AFB_68882     = 5;
  AFB_FPU40     = 6;    {  Set if 68040 FPU }

  AFF_68010     = %00000001;
  AFF_68020     = %00000010;
  AFF_68030     = %00000100;
  AFF_68040     = %00001000;
  AFF_68881     = %00010000;
  AFF_68882     = %00100000;
  AFF_FPU40     = %01000000;

{    AFB_RESERVED8 = %000100000000;  }
{    AFB_RESERVED9 = %001000000000;  }


{ ***** Selected flag definitions for Cache manipulation calls ********* }

  CACRF_EnableI       = %0000000000000001;  { Enable instruction cache  }
  CACRF_FreezeI       = %0000000000000010;  { Freeze instruction cache  }
  CACRF_ClearI        = %0000000000001000;  { Clear instruction cache   }
  CACRF_IBE           = %0000000000010000;  { Instruction burst enable  }
  CACRF_EnableD       = %0000000100000000;  { 68030 Enable data cache   }
  CACRF_FreezeD       = %0000001000000000;  { 68030 Freeze data cache   }
  CACRF_ClearD        = %0000100000000000;  { 68030 Clear data cache    }
  CACRF_DBE           = %0001000000000000;  { 68030 Data burst enable   }
  CACRF_WriteAllocate = %0010000000000000;  { 68030 Write-Allocate mode
                                              (must always be set!)     }
  CACRF_EnableE       = 1073741824;  { Master enable for external caches }
                                     { External caches should track the }
                                     { state of the internal caches }
                                     { such that they do not cache anything }
                                     { that the internal cache turned off }
                                     { for. }

  CACRF_CopyBack      = $80000000;  { Master enable for copyback caches }

  DMA_Continue        = 2;      { Continuation flag for CachePreDMA }
  DMA_NoModify        = 4;      { Set if DMA does not update memory }
  DMA_ReadFromRAM     = 8;      { Set if DMA goes *FROM* RAM to device }


procedure AbortIO(io : pIORequest);
procedure AddDevice(device : pDevice);
procedure AddHead(list : pList;
                  node : pNode);
procedure AddIntServer(intNum : ULONG;
                       Int : pInterrupt);
procedure AddLibrary(lib : pLibrary);
procedure AddMemHandler(memhand : pInterrupt);
procedure AddMemList(size, attr : ULONG;
                     pri : Longint;
                     base : Pointer;
                     name : STRPTR);
procedure AddPort(port : pMsgPort);
procedure AddResource(resource : Pointer);
procedure AddSemaphore(sigsem : pSignalSemaphore);
procedure AddTail(list : pList;
                  node : pNode);
procedure AddTask(task : pTask;
                  initialPC, finalPC : Pointer);
procedure Alert(alertNum : ULONG;
                parameters : Pointer);
function AllocAbs(bytesize : ULONG;
                  location : Pointer) : Pointer;
function Allocate(mem : pMemHeader;
                  bytesize : ULONG) : Pointer;
function AllocEntry(mem : pMemList) : pMemList;
function AllocMem(bytesize : ULONG;
                  reqs : ULONG) : Pointer;
function AllocPooled( pooleheader : Pointer;
                      memsize : ULONG ): Pointer;
function AllocSignal(signalNum : Longint) : Shortint;
function AllocTrap(trapNum : Longint) : Longint;
function AllocVec( size, reqm : ULONG ): Pointer;
function AttemptSemaphore(sigsem : pSignalSemaphore) : Boolean;
function AttemptSemaphoreShared(sigsem : pSignalSemaphore): ULONG;
function AvailMem(attr : ULONG) : ULONG;
procedure CacheClearE( cxa : Pointer;
                       lenght, caches : ULONG);
procedure CacheClearU;
function CacheControl( cachebits, cachemask: ULONG ): ULONG;
procedure CachePostDMA(vaddress, length_IntPtr : Pointer;
                        flags : ULONG );
function CachePreDMA(vaddress, length_intPtr : Pointer;
                     flags : ULONG): Pointer;
procedure Cause(Int : pInterrupt);
function CheckIO(io : pIORequest) : pIORequest;
procedure ChildFree( tid : Pointer);
procedure ChildOrphan( tid : Pointer);
procedure ChildStatus( tid : Pointer);
procedure ChildWait( tid : Pointer);
procedure CloseDevice(io : pIORequest);
procedure CloseLibrary(lib : pLibrary);
procedure ColdReboot;
procedure CopyMem(source, dest : Pointer;
                  size : ULONG);
procedure CopyMemQuick(source, dest : Pointer;
                       size : ULONG);
function CreateIORequest( mp : pMsgPort;
                          size : ULONG ): pIORequest;
function CreateMsgPort: pMsgPort;
function CreatePool( requrements,puddlesize,
                     puddletresh : ULONG ): Pointer;
procedure Deallocate(header : pMemHeader;
                     block : Pointer;
                     size : ULONG);
procedure Debug(Param : ULONG);
procedure DeleteIORequest( iorq : Pointer );
procedure DeleteMsgPort( mp : pMsgPort );
procedure DeletePool( poolheader : Pointer );
procedure Disable;
function DoIO(io : pIORequest) : Shortint;
procedure Enable;
procedure Enqueue(list : pList;
                  node : pNode);
function FindName(start : pList;
                  name : STRPTR) : pNode;
function FindPort(name : STRPTR): pMsgPort;
function FindResident(name : STRPTR) : pResident;
function FindSemaphore(name : STRPTR) : pSignalSemaphore;
function FindTask(name : STRPTR) : pTask;
procedure Forbid;
procedure FreeEntry(memList : pMemList);
procedure ExecFreeMem(memBlock : Pointer;
                  size : ULONG);
procedure FreePooled( poolheader, memory: Pointer;
                      memsize: ULONG);
procedure FreeSignal(signalNum : Longint);
procedure FreeTrap(signalNum : ULONG);
procedure FreeVec( memory : Pointer );
function GetCC : Word;
function GetMsg(port : pMsgPort): pMessage;
procedure InitCode(startClass, version : ULONG);
procedure InitResident(resident : pResident;
                       segList : ULONG);
procedure InitSemaphore(sigsem : pSignalSemaphore);
procedure InitStruct(table, memory : Pointer;
                     size : ULONG);
procedure Insert(list : pList;
                 node, listNode : pNode);
procedure MakeFunctions(target, functionarray : Pointer ;
                       dispbase : ULONG);
function MakeLibrary(vec, struct, init : Pointer;
                     dSize : ULONG ;
                     segList : Pointer) : pLibrary;
function ObtainQuickVector(interruptCode : Pointer) : ULONG;
procedure ObtainSemaphore(sigsem : pSignalSemaphore);
procedure ObtainSemaphoreList(semlist : pList);
procedure ObtainSemaphoreShared(sigsem : pSignalSemaphore);
function OldOpenLibrary(lib : STRPTR): pLibrary;
function OpenDevice(devName : STRPTR;
                    unitNumber : ULONG;
                    io : pIORequest; flags : ULONG) : Shortint;
function OpenLibrary(libName : STRPTR;
                     version : Integer) : pLibrary;
function OpenResource(resname : STRPTR): Pointer;
procedure Permit;
function Procure(sem : pSemaphore;
                 bid : pMessage) : Boolean;
procedure PutMsg(port : pMsgPort;
                 mess : pMessage);
procedure RawDoFmt(Form : STRPTR;
                   data, putChProc, putChData : Pointer);
procedure ReleaseSemaphore(sigsem : pSignalSemaphore);
procedure ReleaseSemaphoreList(siglist : pList);
procedure RemDevice(device : pDevice);
function RemHead(list : pList) : pNode;
procedure RemIntServer(intNum : Longint;
                       Int : pInterrupt);
procedure RemLibrary(lib : pLibrary);
procedure RemMemHandler(memhand : pInterrupt);
procedure Remove(node : pNode);
procedure RemPort(port : pMsgPort);
procedure RemResource(resname : Pointer);
procedure RemSemaphore(sigsem : pSignalSemaphore);
function RemTail(list : pList) : pNode;
procedure RemTask(task : pTask);
procedure ReplyMsg(mess : pMessage);
procedure SendIO(io : pIORequest);
function SetExcept(newSignals, signalMask : ULONG) : ULONG;
function SetFunction(lib : pLibrary;
                     funcOff : LONG;
                     funcEntry : Pointer) : Pointer;
function SetIntVector(intNum : Longint;
                      Int : pInterrupt) : pInterrupt;
function SetSignal(newSignals, signalMask : ULONG) : ULONG;
function SetSR(newSR, mask : ULONG) : ULONG;
function SetTaskPri(task : pTask;
                    priority : Longint) : Shortint;
procedure Signal(task : pTask; signals : ULONG);
procedure StackSwap( StackSwapRecord : Pointer );
procedure SumKickData;
procedure SumLibrary(lib : pLibrary);
function SuperState : Pointer;
function Supervisor(thefunc : Pointer): ULONG;
function TypeOfMem(mem : Pointer) : ULONG;
procedure UserState(s : Pointer);
procedure Vacate(sigsem : pSignalSemaphore;
                 bidMsg : pSemaphoreMessage);
function Wait(signals : ULONG) : ULONG;
function WaitIO(io : pIORequest) : Shortint;
function WaitPort(port : pMsgPort): pMessage;

{*  Exec support functions from amiga.lib  *}

procedure BeginIO (ioRequest: pIORequest);
function CreateExtIO (port: pMsgPort; size: Longint): pIORequest;
procedure DeleteExtIO (ioReq: pIORequest);
function CreateStdIO (port: pMsgPort): pIOStdReq;
procedure DeleteStdIO (ioReq: pIOStdReq);
function CreatePort (name: STRPTR; pri: integer): pMsgPort;
procedure DeletePort (port: pMsgPort);
function CreateTask (name: STRPTR; pri: longint; 
                     initPC : Pointer;
             stackSize : ULONG): pTask; 
procedure DeleteTask (task: pTask);
procedure NewList (list: pList);

IMPLEMENTATION

{*  Exec support functions from amiga.lib  *}

procedure BeginIO (ioRequest: pIORequest); Assembler;
asm
    move.l  a6,-(a7)
    move.l  ioRequest,a1    ; get IO Request
    move.l  20(a1),a6      ; extract Device ptr
    jsr     -30(a6)        ; call BEGINIO directly
    move.l  (a7)+,a6
end;

function CreateExtIO (port: pMsgPort; size: Longint): pIORequest;
var
   IOReq: pIORequest;
begin
    IOReq := NIL;
    if port <> NIL then
    begin
        IOReq := AllocMem(size, MEMF_CLEAR or MEMF_PUBLIC);
        if IOReq <> NIL then
        begin
            IOReq^.io_Message.mn_Node.ln_Type   := NT_REPLYMSG;
            IOReq^.io_Message.mn_Length    := size;
            IOReq^.io_Message.mn_ReplyPort := port;
        end;
    end;
    CreateExtIO := IOReq;
end;


procedure DeleteExtIO (ioReq: pIORequest);
begin
    if ioReq <> NIL then
    begin
        ioReq^.io_Message.mn_Node.ln_Type := $FF;
        ioReq^.io_Message.mn_ReplyPort    := pMsgPort(-1);
        ioReq^.io_Device                  := pDevice(-1);
        ExecFreeMem(ioReq, ioReq^.io_Message.mn_Length);
    end
end;


function CreateStdIO (port: pMsgPort): pIOStdReq;
begin
    CreateStdIO := pIOStdReq(CreateExtIO(port, sizeof(tIOStdReq)))
end;


procedure DeleteStdIO (ioReq: pIOStdReq);
begin
    DeleteExtIO(pIORequest(ioReq))
end;


function CreatePort (name: STRPTR; pri: integer): pMsgPort;
var
   port   : pMsgPort;
   sigbit : shortint;
begin
    port  := NIL;
    sigbit := AllocSignal(-1);
    if sigbit <> -1 then
    begin
        port := AllocMem(sizeof(tMsgPort), MEMF_CLEAR or MEMF_PUBLIC);
        if port = NIL then
            FreeSignal(sigbit)
        else
            begin
                port^.mp_Node.ln_Name  := name;
                port^.mp_Node.ln_Pri   := pri;
                port^.mp_Node.ln_Type  := NT_MSGPORT;

                port^.mp_Flags    := PA_SIGNAL;
                port^.mp_SigBit   := sigbit;
                port^.mp_SigTask  := FindTask(NIL);

                if name <> NIL then
                    AddPort(port)
                else
                    NewList(@port^.mp_MsgList);
            end;
    end;
    CreatePort := port;
end;


procedure DeletePort (port: pMsgPort);
begin
    if port <> NIL then
    begin
        if port^.mp_Node.ln_Name <> NIL then
            RemPort(port);

        port^.mp_SigTask       := pTask(-1);
        port^.mp_MsgList.lh_Head  := pNode(-1);
        FreeSignal(port^.mp_SigBit);
        ExecFreeMem(port, sizeof(tMsgPort));
    end;
end;


function CreateTask (name: STRPTR; pri: longint;
        initPC: pointer; stackSize: ULONG): pTask;
var
   memlist : pMemList;
   task    : pTask;
   totalsize : Longint;
begin
    task  := NIL;
    stackSize   := (stackSize + 3) and not 3;
    totalsize := sizeof(tMemList) + sizeof(tTask) + stackSize;

    memlist := AllocMem(totalsize, MEMF_PUBLIC + MEMF_CLEAR);
    if memlist <> NIL then begin
       memlist^.ml_NumEntries := 1;
       memlist^.ml_ME[0].me_Un.meu_Addr := Pointer(memlist + 1);
       memlist^.ml_ME[0].me_Length := totalsize - sizeof(tMemList);

       task := pTask(memlist + sizeof(tMemList) + stackSize);
       task^.tc_Node.ln_Pri := pri;
       task^.tc_Node.ln_Type := NT_TASK;
       task^.tc_Node.ln_Name := name;
       task^.tc_SPLower := Pointer(memlist + sizeof(tMemList));
       task^.tc_SPUpper := Pointer(task^.tc_SPLower + stackSize);
       task^.tc_SPReg := task^.tc_SPUpper;

       NewList(@task^.tc_MemEntry);
       AddTail(@task^.tc_MemEntry,@memlist^.ml_Node);

       AddTask(task,initPC,NIL) 
    end;
    CreateTask := task;
end;


procedure DeleteTask (task: pTask);
begin
    RemTask(task)
end;


procedure NewList (list: pList);
begin
    with list^ do
    begin
        lh_Head     := pNode(@lh_Tail);
        lh_Tail     := NIL;
        lh_TailPred := pNode(@lh_Head)
    end
end;



procedure AbortIO(io : pIORequest); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  io,a1
    JSR -480(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddDevice(device : pDevice); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  device,a1
    JSR -432(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddHead(list : pList;
                  node : pNode); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  list,a0
    MOVE.L  node,a1
    JSR -240(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddIntServer(intNum : ULONG;
                       Int : pInterrupt); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  intNum,d0
    MOVE.L  Int,a1
    JSR -168(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddLibrary(lib : pLibrary); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  lib,a1
    JSR -396(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddMemHandler(memhand : pInterrupt); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  memhand,a1
    JSR -774(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddMemList(size, attr : ULONG;
                     pri : Longint;
                     base : Pointer;
                     name : STRPTR); Assembler;
asm
    MOVEM.L d2/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  size,d0
    MOVE.L  attr,d1
    MOVE.L  pri,d2
    MOVE.L  base,a0
    MOVE.L  name,a1
    JSR -618(A6)
    MOVEM.L (A7)+,d2/a6
end;

procedure AddPort(port : pMsgPort); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  port,a1
    JSR -354(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddResource(resource : Pointer); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  resource,a1
    JSR -486(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddSemaphore(sigsem : pSignalSemaphore); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a1
    JSR -600(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddTail(list : pList;
                  node : pNode); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  list,a0
    MOVE.L  node,a1
    JSR -246(A6)
    MOVE.L  (A7)+,A6
end;

procedure AddTask(task : pTask;
                  initialPC, finalPC : Pointer); Assembler;
asm
    MOVEM.L a2/a3/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  task,a1
    MOVE.L  initialPC,a2
    MOVE.L  finalPC,a3
    JSR -282(A6)
    MOVEM.L (A7)+,a2/a3/a6
end;

procedure Alert(alertNum : ULONG;
                parameters : Pointer); Assembler;
asm
    MOVEM.L d7/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  alertNum,d7
    JSR -108(A6)
    MOVEM.L (A7)+,d7/a6
end;

function AllocAbs(bytesize : ULONG;
                  location : Pointer) : Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  bytesize,d0
    MOVE.L  location,a1
    JSR -204(A6)
    MOVE.L  (A7)+,A6
end;

function Allocate(mem : pMemHeader;
                  bytesize : ULONG) : Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  mem,a0
    MOVE.L  bytesize,d0
    JSR -186(A6)
    MOVE.L  (A7)+,A6
end;

function AllocEntry(mem : pMemList) : pMemList; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  mem,a0
    JSR -222(A6)
    MOVE.L  (A7)+,A6
end;

function AllocMem(bytesize : ULONG;
                  reqs : ULONG) : Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  bytesize,d0
    MOVE.L  reqs,d1
    JSR -198(A6)
    MOVE.L  (A7)+,A6
end;

function AllocPooled( pooleheader : Pointer;
                      memsize : ULONG ): Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  pooleheader,a0
    MOVE.L  memsize,d0
    JSR -708(A6)
    MOVE.L  (A7)+,A6
end;

function AllocSignal(signalNum : Longint) : Shortint; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  signalNum,d0
    JSR -330(A6)
    MOVE.L  (A7)+,A6
end;

function AllocTrap(trapNum : Longint) : Longint; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  trapNum,d0
    JSR -342(A6)
    MOVE.L  (A7)+,A6
end;

function AllocVec( size, reqm : ULONG ): Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  size,d0
    MOVE.L  reqm,d1
    JSR -684(A6)
    MOVE.L  (A7)+,A6
end;

function AttemptSemaphore(sigsem : pSignalSemaphore) : Boolean; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a0
    JSR -576(A6)
    MOVE.L  (A7)+,A6
    TST.L   d0
    SNE     d0
    NEG.B   d0
end;

function AttemptSemaphoreShared(sigsem : pSignalSemaphore): ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a0
    JSR -720(A6)
    MOVE.L  (A7)+,A6
end;

function AvailMem(attr : ULONG) : ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  attr,d1
    JSR -216(A6)
    MOVE.L  (A7)+,A6
end;

procedure CacheClearE( cxa : Pointer;
                       lenght, caches : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  cxa,a0
    MOVE.L  lenght,d0
    MOVE.L  caches,d1
    JSR -642(A6)
    MOVE.L  (A7)+,A6
end;

procedure CacheClearU; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -636(A6)
    MOVE.L  (A7)+,A6
end;

function CacheControl( cachebits, cachemask: ULONG ): ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  cachebits,d0
    MOVE.L  cachemask,d1
    JSR -648(A6)
    MOVE.L  (A7)+,A6
end;

procedure CachePostDMA(vaddress, length_IntPtr : Pointer;
                        flags : ULONG ); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  vaddress,a0
    MOVE.L  length_IntPtr,a1
    MOVE.L  flags,d0
    JSR -768(A6)
    MOVE.L  (A7)+,A6
end;

function CachePreDMA(vaddress, length_intPtr : Pointer;
                     flags : ULONG): Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  vaddress,a0
    MOVE.L  length_intPtr,a1
    MOVE.L  flags,d0
    JSR -762(A6)
    MOVE.L  (A7)+,A6
end;

procedure Cause(Int : pInterrupt); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  Int,a1
    JSR -180(A6)
    MOVE.L  (A7)+,A6
end;

function CheckIO(io : pIORequest) : pIORequest; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  io,a1
    JSR -468(A6)
    MOVE.L  (A7)+,A6
end;

procedure ChildFree( tid : Pointer); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  tid,d0
    JSR -738(A6)
    MOVE.L  (A7)+,A6
end;

procedure ChildOrphan( tid : Pointer); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  tid,d0
    JSR -744(A6)
    MOVE.L  (A7)+,A6
end;

procedure ChildStatus( tid : Pointer); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  tid,d0
    JSR -750(A6)
    MOVE.L  (A7)+,A6
end;

procedure ChildWait( tid : Pointer); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  tid,d0
    JSR -756(A6)
    MOVE.L  (A7)+,A6
end;

procedure CloseDevice(io : pIORequest); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  io,a1
    JSR -450(A6)
    MOVE.L  (A7)+,A6
end;

procedure CloseLibrary(lib : pLibrary); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  lib,a1
    JSR -414(A6)
    MOVE.L  (A7)+,A6
end;

procedure ColdReboot; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -726(A6)
    MOVE.L  (A7)+,A6
end;

procedure CopyMem(source, dest : Pointer;
                  size : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  source,a0
    MOVE.L  dest,a1
    MOVE.L  size,d0
    JSR -624(A6)
    MOVE.L  (A7)+,A6
end;

procedure CopyMemQuick(source, dest : Pointer;
                       size : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  source,a0
    MOVE.L  dest,a1
    MOVE.L  size,d0
    JSR -630(A6)
    MOVE.L  (A7)+,A6
end;

function CreateIORequest( mp : pMsgPort;
                          size : ULONG ): pIORequest; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  mp,a0
    MOVE.L  size,d0
    JSR -654(A6)
    MOVE.L  (A7)+,A6
end;

function CreateMsgPort: pMsgPort; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -666(A6)
    MOVE.L  (A7)+,A6
end;

function CreatePool( requrements,puddlesize,
                     puddletresh : ULONG ): Pointer; Assembler;
asm
    MOVEM.L d2/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  requrements,d0
    MOVE.L  puddlesize,d1
    MOVE.L  puddletresh,d2
    JSR -696(A6)
    MOVEM.L (A7)+,d2/a6
end;

procedure Deallocate(header : pMemHeader;
                     block : Pointer;
                     size : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  header,a0
    MOVE.L  block,a1
    MOVE.L  size,d0
    JSR -192(A6)
    MOVE.L  (A7)+,A6
end;

procedure Debug(Param : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  Param,d0
    JSR -114(A6)
    MOVE.L  (A7)+,A6
end;

procedure DeleteIORequest( iorq : Pointer ); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  iorq,a0
    JSR -660(A6)
    MOVE.L  (A7)+,A6
end;

procedure DeleteMsgPort( mp : pMsgPort ); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  mp,a0
    JSR -672(A6)
    MOVE.L  (A7)+,A6
end;

procedure DeletePool( poolheader : Pointer ); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  poolheader,a0
    JSR -702(A6)
    MOVE.L  (A7)+,A6
end;

procedure Disable; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -120(A6)
    MOVE.L  (A7)+,A6
end;

function DoIO(io : pIORequest) : Shortint; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  io,a1
    JSR -456(A6)
    MOVE.L  (A7)+,A6
end;

procedure Enable; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -126(A6)
    MOVE.L  (A7)+,A6
end;

procedure Enqueue(list : pList;
                  node : pNode); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  list,a0
    MOVE.L  node,a1
    JSR -270(A6)
    MOVE.L  (A7)+,A6
end;

function FindName(start : pList;
                  name : STRPTR) : pNode; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  start,a0
    MOVE.L  name,a1
    JSR -276(A6)
    MOVE.L  (A7)+,A6
end;

function FindPort(name : STRPTR): pMsgPort; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  name,a1
    JSR -390(A6)
    MOVE.L  (A7)+,A6
end;

function FindResident(name : STRPTR) : pResident; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  name,a1
    JSR -96(A6)
    MOVE.L  (A7)+,A6
end;

function FindSemaphore(name : STRPTR) : pSignalSemaphore; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  name,a1
    JSR -594(A6)
    MOVE.L  (A7)+,A6
end;

function FindTask(name : STRPTR) : pTask; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  name,a1
    JSR -294(A6)
    MOVE.L  (A7)+,A6
end;

procedure Forbid; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -132(A6)
    MOVE.L  (A7)+,A6
end;

procedure FreeEntry(memList : pMemList); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  memlist,a0
    JSR -228(A6)
    MOVE.L  (A7)+,A6
end;

procedure ExecFreeMem(memBlock : Pointer;
                  size : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  memBlock,a1
    MOVE.L  size,d0
    JSR -210(A6)
    MOVE.L  (A7)+,A6
end;

procedure FreePooled( poolheader, memory: Pointer;
                      memsize: ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  poolheader,a0
    MOVE.L  memory,a1
    MOVE.L  memsize,d0
    JSR -714(A6)
    MOVE.L  (A7)+,A6
end;

procedure FreeSignal(signalNum : Longint); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  signalNum,d0
    JSR -336(A6)
    MOVE.L  (A7)+,A6
end;

procedure FreeTrap(signalNum : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  signalNum,d0
    JSR -348(A6)
    MOVE.L  (A7)+,A6
end;

procedure FreeVec( memory : Pointer ); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  memory,a1
    JSR -690(A6)
    MOVE.L  (A7)+,A6
end;

function GetCC : Word; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -528(A6)
    MOVE.L  (A7)+,A6
end;

function GetMsg(port : pMsgPort): pMessage; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  port,a0
    JSR -372(A6)
    MOVE.L  (A7)+,A6
end;

procedure InitCode(startClass, version : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  startClass,d0
    MOVE.L  version,d1
    JSR -72(A6)
    MOVE.L  (A7)+,A6
end;

procedure InitResident(resident : pResident;
                       segList : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  resident,a1
    MOVE.L  seglist,d1
    JSR -102(A6)
    MOVE.L  (A7)+,A6
end;

procedure InitSemaphore(sigsem : pSignalSemaphore); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a0
    JSR -558(A6)
    MOVE.L  (A7)+,A6
end;

procedure InitStruct(table, memory : Pointer;
                     size : ULONG); Assembler;
asm
    MOVEM.L a2/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  table,a1
    MOVE.L  memory,a2
    MOVE.L  size,d0
    JSR -78(A6)
    MOVEM.L (A7)+,a2/a6
end;

procedure Insert(list : pList;
                 node, listNode : pNode); Assembler;
asm
    MOVEM.L a2/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  list,a0
    MOVE.L  node,a1
    MOVE.L  listNode,a2
    JSR -234(A6)
    MOVEM.L (A7)+,a2/a6
end;

procedure MakeFunctions(target, functionarray : Pointer ;
                       dispbase : ULONG); Assembler;
asm
    MOVEM.L a2/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  target,a0
    MOVE.L  functionarray,a1
    MOVE.L  dispbase,a2
    JSR -90(A6)
    MOVEM.L (A7)+,a2/a6
end;

function MakeLibrary(vec, struct, init : Pointer;
                     dSize : ULONG ;
                     segList : Pointer) : pLibrary; Assembler;
asm
    MOVEM.L a2/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  vec,a0
    MOVE.L  struct,a1
    MOVE.L  init,a2
    MOVE.L  dSize,d0
    MOVE.L  seglist,d1
    JSR -84(A6)
    MOVEM.L (A7)+,a2/a6
end;

function ObtainQuickVector(interruptCode : Pointer) : ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  interruptCode,a0
    JSR -786(A6)
    MOVE.L  (A7)+,A6
end;

procedure ObtainSemaphore(sigsem : pSignalSemaphore); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a0
    JSR -564(A6)
    MOVE.L  (A7)+,A6
end;

procedure ObtainSemaphoreList(semlist : pList); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  semlist,a0
    JSR -582(A6)
    MOVE.L  (A7)+,A6
end;

procedure ObtainSemaphoreShared(sigsem : pSignalSemaphore); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a0
    JSR -678(A6)
    MOVE.L  (A7)+,A6
end;

function OldOpenLibrary(lib : STRPTR): pLibrary; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  lib,a1
    JSR -408(A6)
    MOVE.L  (A7)+,A6
end;

function OpenDevice(devName : STRPTR;
                    unitNumber : ULONG;
                    io : pIORequest; flags : ULONG) : Shortint; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  devName,a0
    MOVE.L  unitNumber,d0
    MOVE.L  io,a1
    MOVE.L  flags,d1
    JSR -444(A6)
    MOVE.L  (A7)+,A6
end;

function OpenLibrary(libName : STRPTR;
                     version : Integer) : pLibrary; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  libName,a1
    MOVE.L  version,d0
    JSR -552(A6)
    MOVE.L  (A7)+,A6
end;

function OpenResource(resname : STRPTR): Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  resname,a1
    JSR -498(A6)
    MOVE.L  (A7)+,A6
end;

procedure Permit; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -138(A6)
    MOVE.L  (A7)+,A6
end;

function Procure(sem : pSemaphore;
                 bid : pMessage) : Boolean; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sem,a0
    MOVE.L  bid,a1
    JSR -540(A6)
    MOVE.L  (A7)+,A6
    TST.L   d0
    SNE     d0
    NEG.B   d0
end;

procedure PutMsg(port : pMsgPort;
                 mess : pMessage); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  port,a0
    MOVE.L  mess,a1
    JSR -366(A6)
    MOVE.L  (A7)+,A6
end;

procedure RawDoFmt(Form : STRPTR;
                   data, putChProc, putChData : Pointer); Assembler;
asm
    MOVEM.L a2/a3/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  Form,a0
    MOVE.L  data,a1
    MOVE.L  putChProc,a2
    MOVE.L  putChData,a3
    JSR -522(A6)
    MOVEM.L (A7)+,a2/a3/a6
end;

procedure ReleaseSemaphore(sigsem : pSignalSemaphore); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a0
    JSR -570(A6)
    MOVE.L  (A7)+,A6
end;

procedure ReleaseSemaphoreList(siglist : pList); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  siglist,a0
    JSR -588(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemDevice(device : pDevice); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  device,a1
    JSR -438(A6)
    MOVE.L  (A7)+,A6
end;

function RemHead(list : pList) : pNode; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  list,a0
    JSR -258(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemIntServer(intNum : Longint;
                       Int : pInterrupt); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  intNum,d0
    MOVE.L  Int,a1
    JSR -174(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemLibrary(lib : pLibrary); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  lib,a1
    JSR -402(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemMemHandler(memhand : pInterrupt); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  memhand,a1
    JSR -780(A6)
    MOVE.L  (A7)+,A6
end;

procedure Remove(node : pNode); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  node,a1
    JSR -252(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemPort(port : pMsgPort); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  port,a1
    JSR -360(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemResource(resname : Pointer); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  resname,a1
    JSR -492(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemSemaphore(sigsem : pSignalSemaphore); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a1
    JSR -606(A6)
    MOVE.L  (A7)+,A6
end;

function RemTail(list : pList) : pNode; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  list,a0
    JSR -264(A6)
    MOVE.L  (A7)+,A6
end;

procedure RemTask(task : pTask); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  task,a1
    JSR -288(A6)
    MOVE.L  (A7)+,A6
end;

procedure ReplyMsg(mess : pMessage); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  mess,a1
    JSR -378(A6)
    MOVE.L  (A7)+,A6
end;

procedure SendIO(io : pIORequest); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  io,a1
    JSR -462(A6)
    MOVE.L  (A7)+,A6
end;

function SetExcept(newSignals, signalMask : ULONG) : ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  newSignals,d0
    MOVE.L  signalMask,d1
    JSR -312(A6)
    MOVE.L  (A7)+,A6
end;

function SetFunction(lib : pLibrary;
                     funcOff : LONG;
                     funcEntry : Pointer) : Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  lib,a1
    MOVE.L  funcOff,a0
    MOVE.L  funcEntry,d0
    JSR -420(A6)
    MOVE.L  (A7)+,A6
end;

function SetIntVector(intNum : Longint;
                      Int : pInterrupt) : pInterrupt; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  intNum,d0
    MOVE.L  Int,a1
    JSR -162(A6)
    MOVE.L  (A7)+,A6
end;

function SetSignal(newSignals, signalMask : ULONG) : ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  newSignals,d0
    MOVE.L  signalMask,d1
    JSR -306(A6)
    MOVE.L  (A7)+,A6
end;

function SetSR(newSR, mask : ULONG) : ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  newSR,d0
    MOVE.L  mask,d1
    JSR -144(A6)
    MOVE.L  (A7)+,A6
end;

function SetTaskPri(task : pTask;
                    priority : Longint) : Shortint; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  task,a1
    MOVE.L  priority,d0
    JSR -300(A6)
    MOVE.L  (A7)+,A6
end;

procedure Signal(task : pTask; signals : ULONG); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  task,a1
    MOVE.L  signals,d0
    JSR -324(A6)
    MOVE.L  (A7)+,A6
end;

procedure StackSwap( StackSwapRecord : Pointer ); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  StackSwapRecord,a0
    JSR -732(A6)
    MOVE.L  (A7)+,A6
end;

procedure SumKickData; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -612(A6)
    MOVE.L  (A7)+,A6
end;

procedure SumLibrary(lib : pLibrary); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  lib,a1
    JSR -426(A6)
    MOVE.L  (A7)+,A6
end;

function SuperState : Pointer; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    JSR -150(A6)
    MOVE.L  (A7)+,A6
end;

function Supervisor(thefunc : Pointer): ULONG; Assembler;
asm
    MOVEM.L a5/a6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  thefunc,a5
    JSR -30(A6)
    MOVEM.L (A7)+,a5/a6
end;

function TypeOfMem(mem : Pointer) : ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  mem,a1
    JSR -534(A6)
    MOVE.L  (A7)+,A6
end;

procedure UserState(s : Pointer); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  s,d0
    JSR -156(A6)
    MOVE.L  (A7)+,A6
end;

procedure Vacate(sigsem : pSignalSemaphore;
                 bidMsg : pSemaphoreMessage); Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  sigsem,a0
    MOVE.L  bidMsg,a1
    JSR -546(A6)
    MOVE.L  (A7)+,A6
end;

function Wait(signals : ULONG) : ULONG; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  signals,d0
    JSR -318(A6)
    MOVE.L  (A7)+,A6
end;

function WaitIO(io : pIORequest) : Shortint; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  io,a1
    JSR -474(A6)
    MOVE.L  (A7)+,A6
end;

function WaitPort(port : pMsgPort): pMessage; Assembler;
asm
    MOVE.L  A6,-(A7)
    MOVE.L  _ExecBase,A6
    MOVE.L  port,a0
    JSR -384(A6)
    MOVE.L  (A7)+,A6
end;


end.



{
  $Log$
  Revision 1.1  1998-03-25 11:18:47  root
  Initial revision

  Revision 1.3  1998/01/26 12:02:42  michael
  + Added log at the end


  
  Working file: rtl/amiga/exec.pp
  description:
  ----------------------------
  revision 1.2
  date: 1997/12/14 19:02:47;  author: carl;  state: Exp;  lines: +11 -10
  * small bugfixes
  ----------------------------
  revision 1.1
  date: 1997/12/10 13:48:45;  author: carl;  state: Exp;
  + exec dynamic library definitions and calls.
  =============================================================================
}
