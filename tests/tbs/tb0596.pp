{ %NORUN }
{ %TARGET=win32,win64,wince }

program tb0596;

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;
  IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE = $8000;

{$setpeflags IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$setpeflags $0800}

{$setpeoptflags IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE}
{$setpeoptflags $0040}

begin

end.
