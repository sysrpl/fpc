{
    $Id$
    This file is part of the Free Pascal run time library.
    Copyright (c) 2003 by Florian Klaempfl
    member of the Free Pascal development team

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
 
unit rtlconst;

interface

ResourceString

{ ---------------------------------------------------------------------
    Various error messages.
  ---------------------------------------------------------------------}

  HNoContext                    = 'No context-sensitive Help installed.';
  HNoSystem                     = 'No Help Manager installed.';
  HNoTableOfContents            = 'No Table of Contents found.';
  HNothingFound                 = 'No help found for "%s"';
  HNoTopics                     = 'No topic-based Help installed.';
  SAbortButton                  = 'Abort';
  SAllButton                    = '&All';
  SAllFilter                    = 'All files';
  SAncestorNotFound             = 'Ancestor class for "%s" not found.';
  SAssignError                  = 'Cannot assign a %s to a %s.';
  SAsyncSocketError             = 'Asynchronous socket error: %d';
  SBG                           = 'BG';
  SBitmapEmpty                  = 'Bitmap is empty';
  SBitsIndexError               = 'Bits index out of range.';
  SBoldFont                     = 'Bold';
  SBoldItalicFont               = 'Bold Italic';
  SBucketListLocked             = 'List is locked during an active ForEach.';
  SCancelButton                 = 'Cancel';
  SCannotCreateDir              = 'Das Verzeichnis kann nicht erstellt werden';
  SCannotCreateName             = 'Cannot use standard name for and unknown component';
  SCannotCreateSocket           = 'Unable to create new socket';
  SCannotDragForm               = 'Forms cannot be dragged';
  SCannotFocus                  = 'A disbled or invisible Window cannot get focus';
  SCannotListenOnOpen           = 'Listening on an open socket is not allowed';
  SCannotOpenAVI                = 'AVI can not be opened';
  SCannotShowModal              = 'A visible Window can not be made modal';
  SCantChangeWhileActive        = 'Changing value on an active socket is not allowed';
  SCantWriteResourceStreamError = 'Can not write to read-only ResourceStream';
  SCardDLLNotLoaded             = 'CARDS library could not be loaded';
  SChangeIconSize               = 'Can not change icon size';
  SCharExpected                 = '"%s" expected';
  SCheckSynchronizeError        = 'CheckSynchronize called from non-main thread "$%x"';
  SClassMismatch                = 'Resource %s has wrong class';
  SClassNotFound                = 'Class "%s" not found';
  SClientNotSet                 = 'Client of TDrag was not initialized';
  SCloseButton                  = '&Close';
  SCmplxCouldNotParseImaginary  = 'Failed to parse imaginary portion';
  SCmplxCouldNotParsePlus       = 'Failed to parse required "+" (or "-") symbol';
  SCmplxCouldNotParseReal       = 'Failed to parse real portion';
  SCmplxCouldNotParseSymbol     = 'Failed to parse required "%s" symbol';
  SCmplxErrorSuffix             = '%s [%s<?>%s]';
  SCmplxUnexpectedChars         = 'Unexpected characters';
  SCmplxUnexpectedEOS           = 'Unexpected end of string [%s]';
  SColorPrefix                  = 'Color';
  SColorTags                    = 'ABCDEFGHIJKLMNOP';
  SComponentNameTooLong         = 'Component name "%s" exceeds 64 character limit';
  SConfirmCreateDir             = 'The selected directory does not exist. Should it be created?';
  SControlParentSetToSelf       = 'A component can not have itself as parent';
  SConvDuplicateFamily          = 'Conversion family "%s" already registered';
  SConvDuplicateType            = 'Conversion type (%s) already registered in %s';
  SConvFactorZero               = '"%s" has a factor of zero';
  SConvIllegalFamily            = 'Illegal family';
  SConvIllegalType              = 'Illegal type';
  SConvIncompatibleTypes2       = 'Incompatible conversion types (%s, %s)';
  SConvIncompatibleTypes3       = 'Incompatible conversion types (%s, %s, %s)';
  SConvIncompatibleTypes4       = 'Incompatible conversion types (%s - %s, %s - %s)';
  SConvStrParseError            = 'Could not parse %s';
  SConvUnknownDescription       = '[$%.8x]' ; // no longer used
  SConvUnknownDescriptionWithPrefix = '[%s%.8x]';
  SConvUnknownFamily            = 'Unknown conversion family: "%s"';
  SConvUnknownType              = 'Unknown conversion type: "%s"';
  SCustomColors                 = 'Custom colors';
  SDateEncodeError              = 'Invalid argument for date encode.';
  SDdeConvErr                   = 'DDE error - conversion was not performed ($0%x)';
  SDdeErr                       = 'An error was returned by DDE ($0%x)';
  SDdeMemErr                    = 'An error occurred - not enough memory for DDE ($0%x)';
  SDdeNoConnect                 = 'DDE-Conversation could not be started';
  SDefault                      = 'Default';
  SDefaultFilter                = 'All files (*.*)|*.*';
  SDelimiterQuoteCharError      = 'Delimiter and QuoteChar properties cannot have the same value';
  SDeviceOnPort                 = '%s on %s';
  SDimsDoNotMatch               = 'Image size mismatch';
  SDirNameCap                   = 'Directory &name:';
  SDirsCap                      = '&Directories:';
  SDrivesCap                    = '&Drives:';
  SDuplicateCardId              = 'Duplicate card ID found';
  SDuplicateClass               = 'A class named "%s" already exists';
  SDuplicateItem                = 'Duplicates not allowed in this list ($0%x)';
  SDuplicateMenus               = 'Menu "%s" is used by another form';
  SDuplicateName                = 'Duplcate name: A component named "%s" already exists';
  SDuplicateReference           = 'WriteObject was called twice for one instance';
  SDuplicateString              = 'String list does not allow duplicates';
  SErrindexTooLarge             = 'Bit index exceeds array limit: %d';
  SErrInvalidBitIndex           = 'Invalid bit index : %d';
  SErrNoStreaming               = 'Failed to initialize component: No streaming method available.';
  SErrOutOfMemory               = 'Out of memory';
  SFailedToCallConstructor      = 'TStrings descendant "%s" failed to call inherited constructor';
  SFB                           = 'FB';
  SFCreateError                 = 'Unable to create file "%s"';
  SFCreateErrorEx               = 'Unable to create file "%s": %s';
  SFG                           = 'FG';
  SFilesCap                     = '&Files: (*.*)';
  SFixedColTooBig               = 'Fixed column count must be less than column count';
  SFixedRowTooBig               = 'Fixed row count must be less than row count';
  SFOpenError                   = 'Unable to open file "%s"';
  SFOpenErrorEx                 = 'Unable to open file "%s": %s';
  SGridTooLarge                 = 'Grid too large for this operation';
  SGroupIndexTooLow             = 'GroupIndex must be greater than preceding menu groupindex';
  SHelpButton                   = '&Help';
  SIconToClipboard              = 'Clipboard does not support Icons';
  SIdentifierExpected           = 'Identifier expected';
  SIgnoreButton                 = '&Ignore';
  SImageCanvasNeedsBitmap       = 'A Canvas can only be changed if it contains a bitmap';
  SImageIndexError              = 'Invalid ImageList index';
  SImageReadFail                = 'The ImageList data could not be read from stream';
  SImageWriteFail               = 'The ImageList data could not be written to stream';
  SIndexOutOfRange              = 'Grid index out of range';
  SIniFileWriteError            = 'Unable to write to "%s"';
  SInsertLineError              = 'Line could not be inserted';
  SInvalidActionCreation        = 'Invalid action creation';
  SInvalidActionEnumeration     = 'Invalid action enumeration';
  SInvalidActionRegistration    = 'Invalid action registration';
  SInvalidActionUnregistration  = 'Invalid action unregistration';
  SInvalidBinary                = 'Invalid binary value';
  SInvalidBitmap                = 'Invalid Bitmap';
  SInvalidClipFmt               = 'Invalid clipboard format';
  SInvalidCurrentItem           = 'Invalid item';
  SInvalidDateDay               = '(%d, %d) is not a valid DateDay pair';
  SInvalidDateMonthWeek         = '(%d, %d, %d, %d) is not a valid DateMonthWeek quad';
  SInvalidDateWeek              = '(%d, %d, %d) is not a valid DateWeek triplet';
  SInvalidDayOfWeekInMonth      = '(%d, %d, %d, %d) is not a valid DayOfWeekInMonth quad';
  SInvalidFileName              = '"%s" is not a valid file name.';
  SInvalidIcon                  = 'Invalid Icon';
  SInvalidImage                 = 'Invalid stream format';
  SInvalidImageList             = 'Invalid ImageList';
  SInvalidImageSize             = 'Invalid image size';
  SInvalidJulianDate            = '%f Julian cannot be represented as a DateTime';
  SInvalidMask                  = '"%s" is not a valid mask at (%d)';
  SInvalidMemoSize              = 'Text larger than memo capacity';
  SInvalidMetafile              = 'Invalid Metafile';
  SInvalidName                  = '"%s" is not a valid component name';
  SInvalidNumber                = 'Invalid numerical value';
  SInvalidPixelFormat           = 'Invalid Pixelformat';
  SInvalidPrinter               = 'Selected printer is invalid';
  SInvalidPrinterOp             = 'Operation invalid on selected printer';
  SInvalidProperty              = 'Invalid property value';
  SInvalidPropertyElement       = 'Invalid property element: "%s"';
  SInvalidPropertyPath          = 'Invalid property path';
  SInvalidPropertyType          = 'Property type (%s) is not valid';
  SInvalidPropertyValue         = 'Invalid value for property';
  SInvalidRegType               = 'Invalid data type for "%s"';
  SInvalidString                = 'Invalid string constant';
  SInvalidStringGridOp          = 'Unable to insert rows in or delete rows from grid';
  SInvalidTabIndex              = 'Registerindex out of bounds';
  SItalicFont                   = 'Italic';
  SItemNotFound                 = 'Item not found ($0%x)';
  SLineTooLong                  = 'Line too long';
  SListCapacityError            = 'List capacity (%d) exceeded.';
  SListCountError               = 'List count (%d) out of bounds.';
  SListIndexError               = 'List index (%d) out of bounds';
  SMaskEditErr                  = 'Invalid mask input value.  Use escape key to abandon changes';
  SMaskErr                      = 'Invalid mask input value';
  SMDIChildNotVisible           = 'A MDI-Child Window can not be hidden.';
  SMemoryStreamError            = 'Out of memory while expanding memory stream';
  SMenuIndexError               = 'Menu Index out of range';
  SMenuNotFound                 = 'Menu entry not found in menu';
  SMenuReinserted               = 'Menu reinserted';
  SMissingDateTimeField         = '?';
  SMPOpenFilter                 = 'All files (*.*)|*.*|Wave-files (*.WAV)|*.WAV|Midi-files (*.MID)|*.MID|Video for Windows (*.avi)|*.avi';
  SNetworkCap                   = 'Ne&twork...';
  sNoAddress                    = 'No address specified';
  SNoButton                     = '&No';
  SNoCanvasHandle               = 'Canvas handle does not allow drawing';
  SNoComSupport                 = '"%s" has not been registered as a COM class';
  SNoDefaultPrinter             = 'No default printer was selected';
  SNoMDIForm                    = 'No MDI form is available, none is active';
  SNoTimers                     = 'No timers available';
  SNotOpenErr                   = 'No MCI-device opened';
  SNotPrinting                  = 'Printer is not currently printing';
  SNoVolumeLabel                = ': [ - No name - ]';
  SNumberExpected               = 'Number expected';
  SOKButton                     = 'OK';
  SOldTShape                    = 'Can not load older version of TShape';
  SOleGraphic                   = 'Invalid operation for TOleGraphic';
  SOutlineBadLevel              = '???';
  SOutlineError                 = 'Invalid Node index';
  SOutlineExpandError           = 'Parent node must be expanded';
  SOutlineFileLoad              = 'Error loading file';
  SOutlineIndexError            = 'Node index not found';
  SOutlineLongLine              = 'Line too long';
  SOutlineMaxLevels             = 'Maximum level exceeded';
  SOutlineSelection             = 'Invalid selection';
  SOutOfRange                   = 'Value must be between %d and %d';
  SOutOfResources               = 'Out of system resources';
  SParentRequired               = 'Element ''%s'' has no parent Window';
  SParseError                   = '%s on line %d';
  SPictureDesc                  = ' (%dx%d)';
  SPictureLabel                 = 'Image:';
  SPreviewLabel                 = 'Preview';
  SPrinterIndexError            = 'Printer Index out of range';
  SPrinting                     = 'Printing in progress';
  SPropertiesVerb               = 'Properties';
  SPropertyException            = 'Error reading %s%s%s: %s';
  SPropertyOutOfRange           = 'Property %s out of range';
  SPutObjectError               = 'PutObject on undefined object';
  SRangeError                   = 'Range error';
  SReadError                    = 'Stream read error';
  SReadOnlyProperty             = 'Property is read-only';
  SRegCreateFailed              = 'Failed to create key %s';
  SRegGetDataFailed             = 'Failed to get data for "%s"';
  SRegisterError                = 'Invalid component registration';
  SRegSetDataFailed             = 'Failed to set data for "%s"';
  SRegularFont                  = 'Normal';
  SReplaceImage                 = 'Image can not be replaced';
  SResNotFound                  = 'Resource "%s" not found';
  SRetryButton                  = '&Retry';
  SRNone                        = '(Empty)';
  SRUnknown                     = '(Unknown)';
  SScanLine                     = 'Line index out of bounds';
  SScrollBarRange               = 'Scrollbar property out of range';
  SSeekNotImplemented           = '%s.Seek not implemented';
  SSelectDirCap                 = 'Select directory';
  SSocketAlreadyOpen            = 'Socket is already open';
  SSocketIOError                = '%s error %d, %s';
  SSocketMustBeBlocking         = 'Socket must be in blocking mode';
  SSocketRead                   = 'Read';
  SSocketWrite                  = 'Write';
  SSortedListError              = 'Operation not allowed on sorted list';
  SStreamSetSize                = 'Error setting stream size';
  SStringExpected               = 'String expected';
  SSymbolExpected               = '%s expected';
  SThreadCreateError            = 'Thread creation error: %s';
  SThreadError                  = 'Thread Error: %s (%d)';
  STooManyDeleted               = 'Too many rows or columns deleted';
  STooManyImages                = 'Too many images';
  STwoMDIForms                  = 'There is only one MDI window available';
  SUnknownClipboardFormat       = 'Unknown clipboard format';
  SUnknownConversion            = 'Unknown extension for RichEdit-conversion (.%s)';
  SUnknownExtension             = 'Unknown extension (.%s)';
  SUnknownGroup                 = '%s not in a class registration group';
  SUnknownProperty              = 'Unknown property: "%s"';
  SUnknownPropertyType          = 'Unknown property type %d';
  SUntitled                     = '(Untitled)';
  SVBitmaps                     = 'Bitmaps';
  SVEnhMetafiles                = 'Enhanced MetaFiles';
  SVIcons                       = 'Icons';
  SVisibleChanged               = 'Visible property cannot be changed in OnShow or OnHide handlers';
  SVMetafiles                   = 'MetaFiles';
  SWindowClass                  = 'Error when initializing Window Class';
  SWindowCreate                 = 'Error when creating Window';
  SWindowDCError                = 'Error when??';
  sWindowsSocketError           = 'A Windows socket error occurred: %s (%d), on API "%s"';
  SWriteError                   = 'Stream write error';
  SYesButton                    = '&Yes';

{ ---------------------------------------------------------------------
    Keysim Names
  ---------------------------------------------------------------------}
  
  SmkcAlt   = 'Alt+';
  SmkcBkSp  = 'Backspace';
  SmkcCtrl  = 'Ctrl+';
  SmkcDel   = 'Delete';
  SmkcDown  = 'Down';
  SmkcEnd   = 'End';
  SmkcEnter = 'Enter';
  SmkcEsc   = 'Esc';
  SmkcHome  = 'Home';
  SmkcIns   = 'Insert';
  SmkcLeft  = 'Left';
  SmkcPgDn  = 'Page down';
  SmkcPgUp  = 'Page up';
  SmkcRight = 'Right';
  SmkcShift = 'Shift+';
  SmkcSpace = 'Space';
  SmkcTab   = 'Tab';
  SmkcUp    = 'Up';
  
{ ---------------------------------------------------------------------
    "Distance" family type and conversion types
  ---------------------------------------------------------------------}

  SAngstromsDescription         = 'Angstroms';
  SAstronomicalUnitsDescription = 'AstronomicalUnits';
  SCentimetersDescription       = 'Centimeters';
  SChainsDescription            = 'Chains';
  SCubitsDescription            = 'Cubits';
  SDecametersDescription        = 'Decameters';
  SDecimetersDescription        = 'Decimeters';
  SDistanceDescription          = 'Distance';
  SFathomsDescription           = 'Fathoms';
  SFeetDescription              = 'Feet';
  SFurlongsDescription          = 'Furlongs';
  SGigametersDescription        = 'Gigameters';
  SHandsDescription             = 'Hands';
  SHectometersDescription       = 'Hectometers';
  SInchesDescription            = 'Inches';
  SKilometersDescription        = 'Kilometers';
  SLightYearsDescription        = 'LightYears';
  SLinksDescription             = 'Links';
  SMegametersDescription        = 'Megameters';
  SMetersDescription            = 'Meters';
  SMicromicronsDescription      = 'Micromicrons';
  SMicronsDescription           = 'Microns';
  SMilesDescription             = 'Miles';
  SMillimetersDescription       = 'Millimeters';
  SMillimicronsDescription      = 'Millimicrons';
  SNauticalMilesDescription     = 'NauticalMiles';
  SPacesDescription             = 'Paces';
  SParsecsDescription           = 'Parsecs';
  SPicasDescription             = 'Picas';
  SPointsDescription            = 'Points';
  SRodsDescription              = 'Rods';
  SYardsDescription             = 'Yards';

{ ---------------------------------------------------------------------
    "Area" family type and conversion types
  ---------------------------------------------------------------------}

  SAcresDescription             = 'Acres';
  SAreaDescription              = 'Area';
  SAresDescription              = 'Ares';
  SCentaresDescription          = 'Centares';
  SHectaresDescription          = 'Hectares';
  SSquareCentimetersDescription = 'SquareCentimeters';
  SSquareDecametersDescription  = 'SquareDecameters';
  SSquareDecimetersDescription  = 'SquareDecimeters';
  SSquareFeetDescription        = 'SquareFeet';
  SSquareHectometersDescription = 'SquareHectometers';
  SSquareInchesDescription      = 'SquareInches';
  SSquareKilometersDescription  = 'SquareKilometers';
  SSquareMetersDescription      = 'SquareMeters';
  SSquareMilesDescription       = 'SquareMiles';
  SSquareMillimetersDescription = 'SquareMillimeters';
  SSquareRodsDescription        = 'SquareRods';
  SSquareYardsDescription       = 'SquareYards';

{ ---------------------------------------------------------------------
    "Volume" family type and conversion types
  ---------------------------------------------------------------------}

  SAcreFeetDescription          = 'AcreFeet';
  SAcreInchesDescription        = 'AcreInches';
  SCentiLitersDescription       = 'CentiLiters';
  SCordFeetDescription          = 'CordFeet';
  SCordsDescription             = 'Cords';
  SCubicCentimetersDescription  = 'CubicCentimeters';
  SCubicDecametersDescription   = 'CubicDecameters';
  SCubicDecimetersDescription   = 'CubicDecimeters';
  SCubicFeetDescription         = 'CubicFeet';
  SCubicHectometersDescription  = 'CubicHectometers';
  SCubicInchesDescription       = 'CubicInches';
  SCubicKilometersDescription   = 'CubicKilometers';
  SCubicMetersDescription       = 'CubicMeters';
  SCubicMilesDescription        = 'CubicMiles';
  SCubicMillimetersDescription  = 'CubicMillimeters';
  SCubicYardsDescription        = 'CubicYards';
  SDecaLitersDescription        = 'DecaLiters';
  SDecasteresDescription        = 'Decasteres';
  SDeciLitersDescription        = 'DeciLiters';
  SDecisteresDescription        = 'Decisteres';
  SHectoLitersDescription       = 'HectoLiters';
  SKiloLitersDescription        = 'KiloLiters';
  SLitersDescription            = 'Liters';
  SMilliLitersDescription       = 'MilliLiters';
  SSteresDescription            = 'Steres';
  SVolumeDescription            = 'Volume';

  // US Fluid Units
  SFluidCupsDescription         = 'FluidCups';
  SFluidGallonsDescription      = 'FluidGallons';
  SFluidGillsDescription        = 'FluidGills';
  SFluidOuncesDescription       = 'FluidOunces';
  SFluidPintsDescription        = 'FluidPints';
  SFluidQuartsDescription       = 'FluidQuarts';
  SFluidTablespoonsDescription  = 'FluidTablespoons';
  SFluidTeaspoonsDescription    = 'FluidTeaspoons';

  // US Dry Units
  SDryBucketsDescription        = 'DryBuckets';
  SDryBushelsDescription        = 'DryBushels';
  SDryGallonsDescription        = 'DryGallons';
  SDryPecksDescription          = 'DryPecks';
  SDryPintsDescription          = 'DryPints';
  SDryQuartsDescription         = 'DryQuarts';

  // UK Fluid/Dry Units
  SUKBucketsDescription         = 'UKBuckets';
  SUKBushelsDescription         = 'UKBushels';
  SUKGallonsDescription         = 'UKGallons';
  SUKGillsDescription           = 'UKGill';
  SUKOuncesDescription          = 'UKOunces';
  SUKPecksDescription           = 'UKPecks';
  SUKPintsDescription           = 'UKPints';
  SUKPottlesDescription         = 'UKPottle';
  SUKQuartsDescription          = 'UKQuarts';

{ ---------------------------------------------------------------------
    "Mass" family type and conversion types
  ---------------------------------------------------------------------}

  SCentigramsDescription        = 'Centigrams';
  SDecagramsDescription         = 'Decagrams';
  SDecigramsDescription         = 'Decigrams';
  SDramsDescription             = 'Drams';
  SGrainsDescription            = 'Grains';
  SGramsDescription             = 'Grams';
  SHectogramsDescription        = 'Hectograms';
  SKilogramsDescription         = 'Kilograms';
  SLongTonsDescription          = 'LongTons';
  SMassDescription              = 'Mass';
  SMetricTonsDescription        = 'MetricTons';
  SMicrogramsDescription        = 'Micrograms';
  SMilligramsDescription        = 'Milligrams';
  SNanogramsDescription         = 'Nanograms';
  SOuncesDescription            = 'Ounces';
  SPoundsDescription            = 'Pounds';
  SStonesDescription            = 'Stones';
  STonsDescription              = 'Tons';
  
{ ---------------------------------------------------------------------
    "Temperature" family type and conversion types
  ---------------------------------------------------------------------}

  SCelsiusDescription           = 'Celsius';
  SFahrenheitDescription        = 'Fahrenheit';
  SKelvinDescription            = 'Kelvin';
  SRankineDescription           = 'Rankine';
  SReaumurDescription           = 'Reaumur';
  STemperatureDescription       = 'Temperature';

{ ---------------------------------------------------------------------
    "Time" family type and conversion types
  ---------------------------------------------------------------------}

  SCenturiesDescription          = 'Centuries';
  SDateTimeDescription           = 'DateTime';
  SDaysDescription               = 'Days';
  SDecadesDescription            = 'Decades';
  SFortnightsDescription         = 'Fortnights';
  SHoursDescription              = 'Hours';
  SJulianDateDescription         = 'JulianDate';
  SMillenniaDescription          = 'Millennia';
  SMilliSecondsDescription       = 'MilliSeconds';
  SMinutesDescription            = 'Minutes';
  SModifiedJulianDateDescription = 'ModifiedJulianDate';
  SMonthsDescription             = 'Months';
  SSecondsDescription            = 'Seconds';
  STimeDescription               = 'Time';
  SWeeksDescription              = 'Weeks';
  SYearsDescription              = 'Years';

{ ---------------------------------------------------------------------
    Strings also found in SysConsts.pas
  ---------------------------------------------------------------------}

  SInvalidDate                   = '"%s" is not a valid date' ;
  SInvalidDateTime               = '"%s" is not a valid date and time' ;
  SInvalidInteger                = '"%s" is not a valid integer value' ;
  SInvalidTime                   = '"%s" is not a valid time' ;
  STimeEncodeError               = 'Invalid argument to time encode' ;

{ ---------------------------------------------------------------------
    MCI subsystem constants
  ---------------------------------------------------------------------}
  
  SMCIAVIVideo                  = 'AVIVideo';
  SMCICDAudio                   = 'CDAudio';
  SMCIDAT                       = 'DAT';
  SMCIDigitalVideo              = 'DigitalVideo';
  SMCIMMMovie                   = 'MMMovie';
  SMCINil                       = '';
  SMCIOther                     = 'Other';
  SMCIOverlay                   = 'Overlay';
  SMCIScanner                   = 'Scanner';
  SMCISequencer                 = 'Sequencer';
  SMCIUnknownError              = 'Unknown error code';
  SMCIVCR                       = 'VCR';
  SMCIVideodisc                 = 'Videodisc';
  SMCIWaveAudio                 = 'WaveAudio';

{ ---------------------------------------------------------------------
    Message Dialog constants
  ---------------------------------------------------------------------}
    
  SMsgDlgAbort                  = '&Abort';
  SMsgDlgAll                    = '&All';
  SMsgDlgCancel                 = 'Cancel';
  SMsgDlgConfirm                = 'Confirm';
  SMsgDlgError                  = 'Error';
  SMsgDlgHelp                   = '&Help';
  SMsgDlgHelpHelp               = 'Help';
  SMsgDlgHelpNone               = 'No help available';
  SMsgDlgIgnore                 = '&Ignore';
  SMsgDlgInformation            = 'Information';
  SMsgDlgNo                     = '&No';
  SMsgDlgNoToAll                = 'N&o to all';
  SMsgDlgOK                     = 'OK';
  SMsgDlgRetry = '&Retry';
  SMsgDlgWarning = 'Warning';
  SMsgDlgYes = '&Yes';
  SMsgDlgYesToAll = 'Yes to A&lle';


implementation

end.
{
  $Log$
  Revision 1.4  2004-01-10 20:13:19  michael
  + Some more fixes to rtlconst. Const strings moved from classes to rtlconst

  Revision 1.3  2004/01/10 19:35:17  michael
  + Moved all resource strings to rtlconst/sysconst

  Revision 1.2  2004/01/10 17:30:32  michael
  + Implemented all constants for compatibility

  Revision 1.1  2003/09/03 14:09:37  florian
    * arm fixes to the common rtl code
    * some generic math code fixed
    * ...
}
