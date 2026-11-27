{ Headless stand-in for the emulator's GUI cassette/printer unit (comm.pas).
  No tape or printer is attached: reads return "no data", writes are dropped,
  and the FA-80 switches read as all off. }

unit Comm;

{$MODE Delphi}

interface

  function CommRead: integer;
  procedure CommWrite (b: byte);
  function CommSwitches: byte;

implementation

function CommRead: integer;
begin
  CommRead := -1;
end;

procedure CommWrite (b: byte);
begin
end;

function CommSwitches: byte;
begin
  CommSwitches := 0;
end;

end.
