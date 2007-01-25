{ %cpu=powerpc,powerpc64 }

{$ifdef fpc}
{$mode delphi}
{$endif}

type
  tc = class
    procedure v; virtual;
    procedure test; virtual;
  end;

procedure tc.test; assembler;
asm
{$ifdef cpu64}
  ld r4,0(r3)
  ld r4,+vmtoffset tc.v(r4)
{$else}
  lwz r4,0(r3)
  lwz r4,+vmtoffset tc.v(r4)
{$endif}
  mtctr r4
  bctr
end;

var
  l : longint;

procedure tc.v;
begin
  l := 5;
end;

var
  c: tc;
begin
  c := tc.create;
  c.test;
  if l <> 5 then
    halt(1);
  c.free;
end.

