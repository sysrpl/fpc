unit tbs0140;

{ 
 The first compilation runs fine. 
 A second compilation (i.e; .ppu files exist already) crashes the compiler !!
}

interface
type
 TObject = object
  constructor Init(aPar:byte);
 end;
implementation

uses bug0140a;

constructor TObject.Init(aPar:byte);
 begin
  if aPar=0 then Message(Self);
 end;
end.
