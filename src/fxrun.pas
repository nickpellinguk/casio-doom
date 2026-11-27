{ fxrun - headless driver for Piotr Piatek's Casio FX-8000G emulator core.

  Usage: fxrun [-d romdir] [-s] script.txt     (script "-" reads stdin)

  The emulated CPU runs in virtual time, as fast as the host allows.
  Script commands, one per line (lines starting with '#' are comments):

    wait MS            run the calculator for MS milliseconds of emulated time
    press KEY ...      press and release each named key in turn
    hold MS            how long press keeps a key down (default 60)
    gap MS             how long press waits after releasing it (default 60)
    type TEXT          press the keys for TEXT: program keywords (Plot, Line,
                       Range, Cls, Lbl, Goto, Isz, Dsz, Graph Y=, Abs, Frac,
                       Ran#, -> or →, => or ⇒, ◢, ?, ², = < > <= >= <>, (-) ...),
                       digits, + - * / ÷ . ( ) , : and
                       A-Z/space/" which use ALPHA
    program FILE       type a program listing, pressing EXE after each line
                       (open the program area in WRT mode first)
    shot FILE          save the 96x64 display as a PGM image (4x scaled)
    ascii              print the display as text to stdout
    record DIR [MS]    from now on, save a frame every MS emulated ms
                       (default 100) as DIR/frameNNNNN.pgm; "record off" stops
    scale N            pixel scale for shot (default 4)
    init               press the memory-initialisation button (P on the back)

  -s saves ram.bin and register.bin back to romdir on exit, as the GUI does.
}

program FxRun;

{$MODE Delphi}

uses SysUtils, Classes, Def, Lcd, Keyboard, Cpu, Fa80;

const
  NKEYS = 53;
  KeyNames: array[1..NKEYS] of string = (
    'SHIFT', 'ALPHA', 'PROG', 'LEFT', 'RIGHT', 'MODE', 'MDISP', 'GRAPH',
    'RANGE', 'UP', 'DOWN', 'GT', ':', 'ENG', 'SQRT', 'X2', 'LOG', 'LN',
    'RECIP', 'DMS', 'HYP', 'SIN', 'COS', 'TAN', 'NEG', 'STO', '(', ')',
    'POW', 'XROOT', '7', '8', '9', 'DEL', 'AC', '4', '5', '6', '*', '/',
    '1', '2', '3', '+', '-', '0', '.', 'EXP', 'ANS', 'EXE', 'OFF', 'INIT',
    'HD');

  { letters printed above the keys, in key-code order starting at RECIP (19),
    as used by the GUI's keyboard handler; 'a' marks keys without a letter }
  Letters = 'ABCDEFGHIJKLMNOaaPQRSTUVWXYZ[] ';

var
  OnCounter: integer = 0;
  SerialCounter: integer = 0;
  RomDir: string = 'rom';
  HoldMs: integer = 60;
  GapMs: integer = 60;
  Scale: integer = 4;

procedure Fail (const msg: string);
begin
  WriteLn (ErrOutput, 'fxrun: ', msg);
  Halt (1);
end;

procedure LoadFile (const name: string; var buf; recsize, count: integer;
  required: boolean);
var
  f: file;
  got: integer;
  path: string;
begin
  path := IncludeTrailingPathDelimiter (RomDir) + name;
  if not FileExists (path) then
  begin
    if required then Fail ('missing ' + path);
    Exit;
  end;
  AssignFile (f, path);
  Reset (f, recsize);
  BlockRead (f, buf, count, got);
  CloseFile (f);
end;

procedure MemLoad;
var
  i, size: integer;
begin
  LoadFile ('charset.bin', lcdchr, 1, CHRSIZE div 2, True);
  { unpack the character ROM to one nibble per byte, as main.pas does }
  for size := 127 downto 0 do
    for i := 15 downto 0 do
    begin
      lcdchr[2*size + i div 8, 2*(i mod 8)] := lcdchr[size,i] shr 4;
      lcdchr[2*size + i div 8, 2*(i mod 8) + 1] := lcdchr[size,i] and $F;
    end;
  LoadFile ('rom0.bin', rom0, 3, ROM0SIZE, True);
  FillChar (rom1, ROM1SIZE, $FF);
  LoadFile ('rom1.bin', rom1, 1, ROM1SIZE, False);
  LoadFile ('ram.bin', ram, 1, RAMSIZE, False);
  LoadFile ('register.bin', mr, 1, 128, False);
end;

procedure MemSave;
var
  f: file;
begin
  AssignFile (f, IncludeTrailingPathDelimiter (RomDir) + 'ram.bin');
  Rewrite (f, 1);
  BlockWrite (f, ram, RAMSIZE);
  CloseFile (f);
  AssignFile (f, IncludeTrailingPathDelimiter (RomDir) + 'register.bin');
  Rewrite (f, 1);
  BlockWrite (f, mr, 128);
  CloseFile (f);
end;

procedure ResetAll;
begin
  lcdctrl := 0;
  LcdInit;
  OnCounter := 0;
  TestCounter := 0;
  IoInit;
  CpuReset;
  DoPorts;
end;

var
  RecDir: string = '';      { 'record' output directory, '' when off }
  RecEvery: integer = 100;  { emulated ms between recorded frames }
  RecElapsed: integer = 0;
  RecFrame: integer = 0;

procedure Shot (const fname: string); forward;

{ the body of TMainForm.OnRunTimer, minus the debugger hooks }
procedure RunCycles (ms: integer);
var
  x: integer;
begin
  Inc (acycles, OscFreq * ms);
  while acycles > 0 do
  begin
    case (ie and $84) of
      $80: x := 2;              { slow mode }
      $84: x := 4 * onrate;     { external clock }
      else x := 1;              { fast mode }
    end;
    x := x * CpuRun;
    Dec (acycles, x);

    { INT1 interrupt from the LCD controller }
    if ((lcdctrl and VDD2_bit) = 0) or ((ie and $84) = $84) then
    begin
      OnCounter := 2 * onrate;
      ifreg := ifreg and not INT_input[1];
    end
    else
    begin
      Dec (OnCounter, x);
      if OnCounter < 0 then
      begin
        Inc (OnCounter, 2 * onrate);
        if OnCounter < 0 then OnCounter := 2 * onrate;
        ifreg := ifreg xor INT_input[1];
        if (ifreg and INT_input[1]) <> 0 then IntReq (1);
      end;
    end;

    { serial port bit clock }
    Dec (SerialCounter, x);
    while SerialCounter < 0 do
    begin
      Inc (SerialCounter, SerialRate);
      OnSerialTick;
    end;
  end;
end;

{ run for ms of emulated time, saving a frame every RecEvery ms if recording }
procedure RunMs (ms: integer);
begin
  if RecDir = '' then begin RunCycles (ms); Exit; end;
  while ms > 0 do
  begin
    RunCycles (1);
    Dec (ms);
    Inc (RecElapsed);
    if RecElapsed >= RecEvery then
    begin
      RecElapsed := 0;
      Shot (IncludeTrailingPathDelimiter (RecDir) + Format ('frame%.5d.pgm', [RecFrame]));
      Inc (RecFrame);
    end;
  end;
end;

procedure PressCode (code: integer);
begin
  KeyCode[2] := code;
  KeyHandle;
  RunMs (HoldMs);
  KeyCode[2] := 0;
  KeyHandle;
  RunMs (GapMs);
end;

function FindKey (const name: string): integer;
var
  i: integer;
  u: string;
begin
  u := UpperCase (name);
  for i := 1 to NKEYS do
    if KeyNames[i] = u then Exit (i);
  { a few friendlier aliases }
  if (u = 'ENTER') or (u = 'RET') then Exit (50);
  if (u = 'G<->T') or (u = 'G-T') then Exit (12);
  if (u = '->') or (u = 'ARROW') then Exit (26);
  if (u = 'X^2') then Exit (16);
  if (u = 'X^Y') or (u = '^') then Exit (29);
  if (u = '1/X') then Exit (19);
  if (u = '(-)') then Exit (25);
  FindKey := 0;
end;

{ commands reached with SHIFT, as found by pressing SHIFT + every key;
  returns the unshifted key's code, or 0 }
function FindShifted (const name: string): integer;
const
  N = 30;
  Names: array[1..N] of string = (
    'PLOT', 'LINE', 'CLS', 'ABS', ',', 'COMMA', 'THEN', '=>', 'GOTO', 'LBL',
    'ISZ', 'DSZ', 'FACTOR', 'INT', 'FRAC', 'PI', 'RAN#', 'MCL', '?', 'DISP',
    '=', '<>', '>=', '<=', '>', '<', 'PRINT', 'ASIN', 'ACOS', 'ATAN');
  Codes: array[1..N] of integer = (
    7, 10, 12, 29, 27, 27, 31, 31, 3, 4,
    36, 41, 9, 15, 16, 48, 47, 34, 26, 13,
    32, 33, 37, 38, 42, 43, 49, 22, 23, 24);
var
  i: integer;
  u: string;
begin
  u := UpperCase (name);
  for i := 1 to N do
    if Names[i] = u then Exit (Codes[i]);
  FindShifted := 0;
end;

type
  TKeyword = record
    text: string;     { as written in a program listing (case-sensitive) }
    shift: boolean;   { reached with SHIFT }
    code: integer;    { key code }
  end;

const
  { checked in order, so longer spellings come before their prefixes }
  NWORDS = 34;
  Keywords: array[1..NWORDS] of TKeyword = (
    (text: #$E2#$89#$A0; shift: True;  code: 33),   { ≠ }
    (text: #$C2#$B2;     shift: False; code: 16),   { ² }
    { the calculator's own symbols, as UTF-8 }
    (text: #$E2#$87#$92; shift: True;  code: 31),   { ⇒ }
    (text: #$E2#$86#$92; shift: False; code: 26),   { → }
    (text: #$E2#$97#$A2; shift: True;  code: 13),   { ◢ }
    (text: #$C3#$B7;     shift: False; code: 40),   { ÷ }
    (text: '?';          shift: True;  code: 26),
    (text: 'Graph Y='; shift: False; code: 8),
    (text: 'Range';    shift: False; code: 9),
    (text: 'Plot';     shift: True;  code: 7),
    (text: 'Line';     shift: True;  code: 10),
    (text: 'Cls';      shift: True;  code: 12),
    (text: 'Abs';      shift: True;  code: 29),
    (text: 'Lbl';      shift: True;  code: 4),
    (text: 'Goto';     shift: True;  code: 3),
    (text: 'Isz';      shift: True;  code: 36),
    (text: 'Dsz';      shift: True;  code: 41),
    (text: 'Prog';     shift: False; code: 3),
    (text: 'Int';      shift: True;  code: 15),
    (text: 'Frac';     shift: True;  code: 16),
    (text: 'sin';      shift: False; code: 22),
    (text: 'cos';      shift: False; code: 23),
    (text: 'tan';      shift: False; code: 24),
    (text: 'Ran#';     shift: True;  code: 47),
    (text: 'pi';       shift: True;  code: 48),
    (text: '(-)';      shift: False; code: 25),
    (text: '=>';       shift: True;  code: 31),
    (text: '->';       shift: False; code: 26),
    (text: '<>';       shift: True;  code: 33),
    (text: '>=';       shift: True;  code: 37),
    (text: '<=';       shift: True;  code: 38),
    (text: '>';        shift: True;  code: 42),
    (text: '<';        shift: True;  code: 43),
    (text: '=';        shift: True;  code: 32));

{ Types TEXT. Program keywords such as Plot, Line, Range, Lbl, Goto, -> and
  => become their keys (one following space is dropped, as the calculator
  adds its own); everything else is typed character by character. }
procedure TypeText (const s: string);
var
  i, j, k, p: integer;
  c: char;
  matched: boolean;
begin
  i := 1;
  while i <= Length (s) do
  begin
    matched := False;
    for j := 1 to NWORDS do
      with Keywords[j] do
        if Copy (s, i, Length (text)) = text then
        begin
          if shift then PressCode (1);
          PressCode (code);
          Inc (i, Length (text));
          if (i <= Length (s)) and (s[i] = ' ') and (text[Length (text)] in ['a'..'z', 'A'..'Z']) then
            Inc (i);
          matched := True;
          Break;
        end;
    if matched then Continue;

    c := UpCase (s[i]);
    Inc (i);
    if c = ',' then begin PressCode (1); PressCode (27); Continue; end;
    k := FindKey (c);
    if (k = 0) and (c = '"') then
    begin
      PressCode (2);  PressCode (3);   { ALPHA + Prog key carries the quote }
      Continue;
    end;
    if k = 0 then
    begin
      p := Pos (c, Letters);
      if (p = 0) or (c = 'a') then Fail ('cannot type ' + QuotedStr (c));
      PressCode (2);                   { ALPHA }
      PressCode (p + 18);
      Continue;
    end;
    PressCode (k);
  end;
end;

function Pixel (x, y: integer): boolean;
var
  idx: integer;
  w: integer;
begin
  w := y mod 8;
  idx := (y div 8) * 192 + x * 2 + (w div 4);
  Pixel := (lcdimage[idx] and ($8 shr (w mod 4))) <> 0;
end;

procedure Shot (const fname: string);
var
  f: TFileStream;
  hdr: string;
  row: array of byte;
  x, y, i: integer;
  v: byte;
begin
  LcdRender;
  f := TFileStream.Create (fname, fmCreate);
  try
    hdr := Format ('P5'#10'%d %d'#10'255'#10, [96 * Scale, 64 * Scale]);
    f.WriteBuffer (hdr[1], Length (hdr));
    SetLength (row, 96 * Scale);
    for y := 0 to 63 do
    begin
      for x := 0 to 95 do
      begin
        if Pixel (x, y) then v := 40 else v := 200;  { dark pixel on grey-green }
        for i := 0 to Scale - 1 do row[x * Scale + i] := v;
      end;
      for i := 1 to Scale do f.WriteBuffer (row[0], Length (row));
    end;
  finally
    f.Free;
  end;
end;

procedure Ascii;
var
  x, y: integer;
  line: string;
begin
  LcdRender;
  WriteLn ('+', StringOfChar ('-', 96), '+');
  for y := 0 to 63 do
  begin
    line := '';
    for x := 0 to 95 do
      if Pixel (x, y) then line := line + '#' else line := line + ' ';
    WriteLn ('|', line, '|');
  end;
  WriteLn ('+', StringOfChar ('-', 96), '+');
end;

{ types a program listing: one statement line per line, EXE after each;
  lines starting with '#' and blank lines are skipped }
procedure TypeProgram (const fname: string);
var
  t: Text;
  line: string;
begin
  if not FileExists (fname) then Fail ('missing ' + fname);
  AssignFile (t, fname);
  Reset (t);
  while not Eof (t) do
  begin
    ReadLn (t, line);
    line := TrimRight (line);
    if (Trim (line) = '') or (Trim (line)[1] = '#') then Continue;
    TypeText (Trim (line));
    PressCode (50);   { EXE ends the statement line }
  end;
  CloseFile (t);
end;

procedure RunScript (var t: Text);
var
  line, cmd, rest, tok: string;
  sp, n, k, lineno: integer;
begin
  lineno := 0;
  while not Eof (t) do
  begin
    ReadLn (t, line);
    Inc (lineno);
    line := Trim (line);
    if (line = '') or (line[1] = '#') then Continue;
    sp := Pos (' ', line);
    if sp = 0 then begin cmd := LowerCase (line); rest := ''; end
    else begin cmd := LowerCase (Copy (line, 1, sp - 1)); rest := Copy (line, sp + 1, MaxInt); end;

    if cmd = 'wait' then RunMs (StrToInt (Trim (rest)))
    else if cmd = 'hold' then HoldMs := StrToInt (Trim (rest))
    else if cmd = 'gap' then GapMs := StrToInt (Trim (rest))
    else if cmd = 'scale' then Scale := StrToInt (Trim (rest))
    else if cmd = 'shot' then Shot (Trim (rest))
    else if cmd = 'ascii' then Ascii
    else if cmd = 'record' then
    begin
      { record DIR [MS] starts saving frames; "record off" stops }
      rest := Trim (rest);
      if LowerCase (rest) = 'off' then RecDir := '' else
      begin
        sp := Pos (' ', rest);
        if sp > 0 then
        begin
          RecEvery := StrToInt (Trim (Copy (rest, sp + 1, MaxInt)));
          rest := Copy (rest, 1, sp - 1);
        end;
        RecDir := rest;
        ForceDirectories (RecDir);
        RecElapsed := 0;
      end;
    end
    else if cmd = 'init' then PressCode (52)
    else if cmd = 'type' then TypeText (rest)
    else if cmd = 'program' then TypeProgram (Trim (rest))
    else if cmd = 'press' then
    begin
      rest := Trim (rest);
      while rest <> '' do
      begin
        sp := Pos (' ', rest);
        if sp = 0 then begin tok := rest; rest := ''; end
        else begin tok := Copy (rest, 1, sp - 1); rest := Trim (Copy (rest, sp + 1, MaxInt)); end;
        n := 1;
        { KEY*N repeats a key, e.g. DOWN*3 }
        k := LastDelimiter ('*', tok);
        if (k > 1) and (k < Length (tok)) and TryStrToInt (Copy (tok, k + 1, MaxInt), n) then
          tok := Copy (tok, 1, k - 1)
        else
          n := 1;
        k := FindKey (tok);
        if k <> 0 then
          while n > 0 do begin PressCode (k); Dec (n); end
        else
        begin
          k := FindShifted (tok);
          if k = 0 then Fail (Format ('line %d: unknown key %s', [lineno, tok]));
          while n > 0 do begin PressCode (1); PressCode (k); Dec (n); end;
        end;
      end;
    end
    else Fail (Format ('line %d: unknown command %s', [lineno, cmd]));
  end;
end;

var
  i: integer;
  script: string = '';
  save: boolean = False;
  t: Text;

begin
  i := 1;
  while i <= ParamCount do
  begin
    if ParamStr (i) = '-d' then begin Inc (i); RomDir := ParamStr (i); end
    else if ParamStr (i) = '-s' then save := True
    else script := ParamStr (i);
    Inc (i);
  end;
  if script = '' then
  begin
    WriteLn ('usage: fxrun [-d romdir] [-s] script.txt   (- for stdin)');
    Halt (2);
  end;

  OscFreq := XTAL;
  CpuStop := False;
  CpuSteps := -1;
  BreakPoint := -1;
  KeyCode[1] := 0; KeyCode[2] := 0; KeyCode[3] := 0;
  MemLoad;
  LcdInit;
  ResetAll;

  if script = '-' then RunScript (Input)
  else
  begin
    AssignFile (t, script);
    Reset (t);
    RunScript (t);
    CloseFile (t);
  end;

  if save then MemSave;
end.
