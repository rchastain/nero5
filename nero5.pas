
program nero5;

{$ifdef windows}
{$apptype gui}
{$endif}

uses
{$ifdef unix}
  cthreads,
{$endif}
  sysutils, ptccrt, ptcgraph, pieceset, engine88, log, sound;

{$ifdef windows}
{$r nero5.res}
{$endif}

{$i version}
{$i colors4}

const
  blines = 264;

type
  bltype = ^string;

  savedpostype = record
    positio: positiontype;
    mnumber, ep: integer;
    wtomove, wk, bk, wra, bra, wrh, brh: boolean;
    avaus: shortstring;
  end;

var
  previous: savedpostype;
  posf: file of savedpostype;
  cursorx, cursory, cursorc, aa, cee, joku, movenumber, darks, lights, xmargin, ymargin: integer;
  soundon, gameover, whitesturn, whiteatbottom, playeriswhite: boolean;
  movesecs: longint;
  gamef: text;
  name, templine, avaus, secstr: string;
  movelist: array[1..24] of string;
  bookline: array[1..blines] of bltype;

procedure gettime(var hour, minute, second, sec100: word);
var
  millisecond: word;
begin
  decodetime(time, hour, minute, second, millisecond);
  sec100 := millisecond div 10;
end;

procedure set_to_graphics_mode;
var
  d, m: smallint;
begin
  d := vga;
  m := vgahi; { 640x480x16 }
  windowtitle := 'NERO 5';
  initgraph(d, m, '');
  if graphresult <> grok then
  begin
    writeln(stderr, grapherrormsg(graphresult));
    halt(1);
  end;
  setlinestyle(0, 0, 1);
end;

procedure update_movelist(rivi: string);
var
  i: integer;
begin
  settextstyle(defaultfont, horizdir, 1);
  setcolor(cblack);
  for i := 1 to 24 do outtextxy(525, 50 + 15 * i, movelist[i]);
  for i := 1 to 23 do movelist[i] := movelist[i + 1];
  movelist[24] := rivi;
  setcolor(clightgray);
  for i := 1 to 23 do outtextxy(525, 50 + 15 * i, movelist[i]);
  setcolor(cwhite);
  outtextxy(525, 410, movelist[24]);
  settextstyle(defaultfont, horizdir, 2);
end;

procedure empty_movelist;
var
  i: integer;
begin
  settextstyle(defaultfont, horizdir, 1);
  setcolor(cblack);
  for i := 1 to 24 do outtextxy(525, 50 + 15 * i, movelist[i]);
  for i := 1 to 24 do movelist[i] := ' ';
  settextstyle(defaultfont, horizdir, 2);
end;

procedure draw_board_skeleton;
var i, j, x, y: integer;
begin
  setcolor(cwhite);
  moveto(xmargin, ymargin);
  for i := 1 to files do
    for j := 1 to ranks do begin
      x := xmargin + 50 * i; y := ymargin + 50 * j; moveto(x, y);
      linerel(-50, 0); linerel(0, -50); linerel(50, 0); linerel(0, 50);
    end;
end;

procedure drawcursor;
begin
  setcolor(cursorc);
  moveto(xmargin + cursorx * 50 - 2, 480 - ymargin - cursory * 50 + 48);
  linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
  moveto(xmargin + cursorx * 50 - 1, 480 - ymargin - cursory * 50 + 49);
  linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
  moveto(xmargin + cursorx * 50 - 3, 480 - ymargin - cursory * 50 + 47);
  linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
end;

procedure drawmark;
begin
  setcolor(clightred);
  moveto(xmargin + cursorx * 50 - 4, 480 - ymargin - cursory * 50 + 46);
  linerel(0, -42); linerel(-42, 0); linerel(0, 42); linerel(42, 0);
  moveto(xmargin + cursorx * 50 - 5, 480 - ymargin - cursory * 50 + 45);
  linerel(0, -40); linerel(-40, 0); linerel(0, 40); linerel(40, 0);
  moveto(xmargin + cursorx * 50 - 6, 480 - ymargin - cursory * 50 + 44);
  linerel(0, -38); linerel(-38, 0); linerel(0, 38); linerel(38, 0);
end;

procedure delcursor;
begin
  if ((cursorx + cursory) mod 2 = 1) then setcolor(lights)
  else setcolor(darks);
  moveto(xmargin + cursorx * 50 - 2, 480 - ymargin - cursory * 50 + 48);
  linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
  moveto(xmargin + cursorx * 50 - 1, 480 - ymargin - cursory * 50 + 49);
  linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
  moveto(xmargin + cursorx * 50 - 3, 480 - ymargin - cursory * 50 + 47);
  linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
end;

function promoted: shortint;
var
  c: char;
begin
  setcolor(cyellow);
  settextstyle(defaultfont, horizdir, 2);
  outtextxy(0, 85, 'SELECT:');
  setcolor(cwhite);
  outtextxy(0, 110, 'Q/R/');
  outtextxy(0, 135, 'B/N?');
  repeat
    c := readkey;
  until (c in ['Q', 'R', 'N', 'B', 'q', 'r', 'n', 'b']);
  setcolor(cblack);
  outtextxy(0, 85, 'SELECT:');
  outtextxy(0, 110, 'Q/R/');
  outtextxy(0, 135, 'B/N?');

  if (c in ['Q', 'q']) then promoted := 2;
  if (c in ['R', 'r']) then promoted := 3;
  if (c in ['B', 'b']) then promoted := 4;
  if (c in ['N', 'n']) then promoted := 5;
end;

procedure draw_piece(linepos, rowpos, piece: integer);
var y: integer;
begin
  if (whiteatbottom) then rowpos := ranks + 1 - rowpos
  else linepos := files + 1 - linepos;
  if ((rowpos + linepos) mod 2 = 1) then setcolor(darks) else setcolor(lights);
  for y := ymargin + rowpos * 50 - 49 to ymargin + rowpos * 50 - 1 do
    line(xmargin + linepos * 50 - 1, y, xmargin + linepos * 50 - 49, y);
  if (piece = 2)
    then draw_white_queen(xmargin + linepos * 50 - 40, ymargin + rowpos * 50 - 40)
  else if (piece = 3)
    then draw_white_rook(xmargin + linepos * 50 - 38, ymargin + rowpos * 50 - 40)
  else if (piece = 5)
    then draw_white_knight(xmargin + linepos * 50 - 36, ymargin + rowpos * 50 - 8)
  else if (piece = 1)
    then draw_white_king(xmargin + linepos * 50 - 40, ymargin + rowpos * 50 - 36)
  else if (piece = 4)
    then draw_white_bishop(xmargin + linepos * 50 - 39, ymargin + rowpos * 50 - 8)
  else if (piece = 6)
    then draw_white_pawn(xmargin + linepos * 50 - 38, ymargin + rowpos * 50 - 10)
  else if (piece = -5)
    then draw_black_knight(xmargin + linepos * 50 - 36, ymargin + rowpos * 50 - 8)
  else if (piece = -1)
    then draw_black_king(xmargin + linepos * 50 - 40, ymargin + rowpos * 50 - 36)
  else if (piece = -4)
    then draw_black_bishop(xmargin + linepos * 50 - 39, ymargin + rowpos * 50 - 8)
  else if (piece = -6)
    then draw_black_pawn(xmargin + linepos * 50 - 38, ymargin + rowpos * 50 - 10)
  else if (piece = -2)
    then draw_black_queen(xmargin + linepos * 50 - 40, ymargin + rowpos * 50 - 40)
  else if (piece = -3)
    then draw_black_rook(xmargin + linepos * 50 - 38, ymargin + rowpos * 50 - 40)
end;

procedure setsqc;
var i, j: integer;
begin
  if ((lights = clightgray) and (darks = cbrown)) then begin
    lights := clightgray; darks := cdarkgray; cursorc := cwhite;
  end else
    if ((lights = clightgray) and (darks = cdarkgray)) then begin
      lights := ccyan; darks := cblue; cursorc := cwhite;
    end else
      if ((lights = ccyan) and (darks = cblue)) then
      begin
        lights := cyellow; darks := cgreen; cursorc := cwhite;
      end else
        if ((lights = cyellow) and (darks = cgreen)) then
        begin
          lights := clightgray; darks := cblue; cursorc := cwhite;
        end else
          if ((lights = clightgray) and (darks = cblue)) then
          begin
            lights := clightgray; darks := cbrown; cursorc := cwhite;
          end;
  for i := 1 to files do for j := 1 to ranks do
      draw_piece(i, j, position[i, j]);
end;

procedure turn_board;
var
  i, j: integer;
begin
  whiteatbottom := (not whiteatbottom);
  if (whiteatbottom) then begin
    settextstyle(defaultfont, horizdir, 1);
    setcolor(cblack);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(ord('i') - i));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(ord('9') - i));
    setcolor(ccyan);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(i + ord('a') - 1));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(i + ord('0')));
  end
  else begin
    settextstyle(defaultfont, horizdir, 1);
    setcolor(cblack);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(i + ord('a') - 1));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(i + ord('0')));
    setcolor(ccyan);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(ord('i') - i));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(ord('9') - i));
  end;
  settextstyle(defaultfont, horizdir, 2);
  for i := 1 to files do for j := 1 to ranks do
      draw_piece(i, j, position[i, j]);
  cursorx := files + 1 - cursorx;
  cursory := ranks + 1 - cursory;
end;

procedure set_initial_pos(setup: boolean);
label
  100, 200, 300;
var
  i, j, ii, jj: integer; c: char; askep, joo: boolean;
begin
  c := '0';
  analysis := false;
  for i := 1 to 8 do lmoved[i] := 0;
  settextstyle(defaultfont, horizdir, 1);
  setcolor(cblack);
  outtextxy(0, 250, kpstr);
  settextstyle(defaultfont, horizdir, 2);
  movenumber := 0;
  writeln(gamef, ' ');
  writeln(gamef, ' ');
  writeln(gamef, '[Event "?"]');
  writeln(gamef, '[Site "?"]');
  writeln(gamef, '[Date "?"]');
  writeln(gamef, '[Round "?"]');
  writeln(gamef, '[Result "?"]');
  writeln(gamef, '[White "?"]');
  writeln(gamef, '[Black "?"]');
  writeln(gamef, ' ');
  empty_movelist;
  avaus := '';
  if (setup) then begin
    viewscores := true;
    setcolor(cblack); avaus := 'towerofpowerisagreatband'; gameover := false;
    outtextxy(20, 220, ' GAME');
    outtextxy(20, 250, ' OVER');
    outtextxy(0, 330, 'Your');
    outtextxy(0, 360, 'move');
    outtextxy(5, 300, lstr);
    outtextxy(5, 275, beststr);
    lstr := '0.0';
    if (not whiteatbottom) then turn_board;
    100:
    for j := ranks downto 1 do for i := 1 to files do begin
        position[i, j] := 0;
        draw_piece(i, j, position[i, j]);
      end;
    settextstyle(defaultfont, horizdir, 1);
    setcolor(cwhite);
    outtextxy(5, 70, 'Give position');
    outtextxy(5, 90, 'from a8 to h1');
    setcolor(cgreen);
    outtextxy(5, 150, 'cblack pieces:');
    outtextxy(5, 210, 'cwhite pieces:');

    outtextxy(5, 270, 'Empty square:');
    outtextxy(5, 325, 'Many empty');
    outtextxy(5, 345, 'squares:');
    outtextxy(5, 385, 'Random!: F5');
    setcolor(cyellow);
    outtextxy(5, 385, '         F5');
    outtextxy(5, 170, 'k,q,r,b,n,p');
    outtextxy(5, 230, 'K,Q,R,B,N,P');
    outtextxy(5, 290, 'any other key');
    outtextxy(5, 345, '          2-8');
    settextstyle(defaultfont, horizdir, 3);
    for j := ranks downto 1 do for i := 1 to files do begin
        cursorx := i; cursory := j; drawcursor;
        setcolor(clightred);
        moveto(xmargin + cursorx * 50 - 33, 480 - ymargin - cursory * 50 + 14);
        outtext('?');
        if (c <> '?') then
          if (c > '1') and (c < '9') then c := chr(ord(c) - 1)
          else c := readkey;
        if (c = 'K') then begin
          wkx := i; wky := j; position[i, j] := 1
        end
        else if (c = 'k') then begin
          bkx := i; bky := j; position[i, j] := -1
        end
        else if (c = 'Q') then position[i, j] := 2
        else if (c = 'R') then position[i, j] := 3
        else if (c = 'B') then position[i, j] := 4
        else if (c = 'N') then position[i, j] := 5
        else if (c = 'P') then position[i, j] := 6
        else if (c = 'q') then position[i, j] := -2
        else if (c = 'r') then position[i, j] := -3
        else if (c = 'b') then position[i, j] := -4
        else if (c = 'n') then position[i, j] := -5
        else if (c = 'p') then position[i, j] := -6
        else if (c = '?') then begin
          c := 'x';
          for jj := ranks downto 1 do for ii := 1 to files do
              position[ii, jj] := 0;
          for jj := 1 to 8 do begin
            position[jj, 2] := 6;
            position[jj, 7] := -6;
          end;
          jj := random(4) * 2 + 1;
          position[jj, 1] := 4;
          jj := random(4) * 2 + 2;
          position[jj, 1] := 4;
          repeat
            jj := random(8) + 1
          until (position[jj, 1] = 0);
          position[jj, 1] := 1;
          repeat
            jj := random(8) + 1
          until (position[jj, 1] = 0);
          position[jj, 1] := 2;
          repeat
            jj := random(8) + 1
          until (position[jj, 1] = 0);
          position[jj, 1] := 3;
          repeat
            jj := random(8) + 1
          until (position[jj, 1] = 0);
          position[jj, 1] := 3;
          for jj := 1 to 8 do if (position[jj, 1] = 0) then position[jj, 1] := 5;
          for jj := 1 to 8 do position[jj, 8] := -position[jj, 1];
          for jj := ranks downto 1 do for ii := 1 to files do
              draw_piece(ii, jj, position[ii, jj]);
          goto 200;
        end
        else position[i, j] := 0;
        draw_piece(i, j, position[i, j]);
      end;
    200: settextstyle(defaultfont, horizdir, 1);
    setcolor(cblack);
    outtextxy(5, 70, 'Give position');
    outtextxy(5, 90, 'from a8 to h1');
    outtextxy(5, 150, 'black pieces:');
    outtextxy(5, 170, 'k,q,r,b,n,p');
    outtextxy(5, 210, 'white pieces:');
    outtextxy(5, 230, 'K,Q,R,B,N,P');
    outtextxy(5, 270, 'Empty square:');
    outtextxy(5, 290, 'any other key');
    outtextxy(5, 325, 'Many empty');
    outtextxy(5, 345, 'squares:  2-8');
    outtextxy(5, 385, 'Random!: F5');
    if (c = 'x') then begin
      whitesturn := true;
      mwk := (not position[5, 1] = 1);
      mbk := mwk;
      mwra := (not position[1, 1] = 3);
      mwrh := (not position[8, 1] = 3);
      mbra := mwra; mbrh := mwrh;
      goto 300;
    end;
    setcolor(cyellow);
    outtextxy(5, 270, 'Side to move');
    outtextxy(5, 290, 'next (B/W)?');
    repeat
      c := readkey
    until (c in ['B', 'b', 'W', 'w', '?']);
    whitesturn := (c in ['W', 'w']);
    if (not whitesturn) then movenumber := 1;
    setcolor(cblack);
    outtextxy(5, 270, 'Side to move');
    outtextxy(5, 290, 'next (B/W)?');
    if (c = '?') then goto 100;
    mwra := true; mbra := true; mwrh := true; mbrh := true; mwk := true; mbk := true;
    if ((position[5, 1] = 1) and ((position[1, 1] = 3) or (position[8, 1] = 3)))
      then begin
      setcolor(cyellow);
      outtextxy(5, 270, 'Has white king');
      outtextxy(5, 290, 'moved (Y/N)?');
      repeat
        c := readkey
      until (c in ['n', 'y', 'N', 'Y']);
      mwk := (c in ['Y', 'y']);
      setcolor(cblack);
      outtextxy(5, 270, 'Has white king');
      outtextxy(5, 290, 'moved (Y/N)?');
      if (not mwk) then begin
        if (position[1, 1] = 3) then begin
          setcolor(cyellow);
          outtextxy(5, 270, 'Has rook on a1');
          outtextxy(5, 290, 'moved (Y/N)?');
          repeat
            c := readkey
          until (c in ['n', 'y', 'N', 'Y']);
          mwra := (c in ['Y', 'y']);
          setcolor(cblack);
          outtextxy(5, 270, 'Has rook on a1');
          outtextxy(5, 290, 'moved (Y/N)?');
        end;
        if (position[8, 1] = 3) then begin
          setcolor(cyellow);
          outtextxy(5, 270, 'Has rook on h1');
          outtextxy(5, 290, 'moved (Y/N)?');
          repeat
            c := readkey
          until (c in ['n', 'y', 'N', 'Y']);
          mwrh := (c in ['Y', 'y']);
          setcolor(cblack);
          outtextxy(5, 270, 'Has rook on h1');
          outtextxy(5, 290, 'moved (Y/N)?');
        end;
      end;
    end;

    if ((position[5, 8] = -1) and ((position[1, 8] = -3) or (position[8, 8] = -3)))
      then begin
      setcolor(cyellow);
      outtextxy(5, 270, 'Has black king');
      outtextxy(5, 290, 'moved (Y/N)?');
      repeat
        c := readkey
      until (c in ['n', 'y', 'N', 'Y']);
      mbk := (c in ['Y', 'y']);
      setcolor(cblack);
      outtextxy(5, 270, 'Has black king');
      outtextxy(5, 290, 'moved (Y/N)?');
      if (not mbk) then begin
        if (position[1, 8] = -3) then begin
          setcolor(cyellow);
          outtextxy(5, 270, 'Has rook on a8');
          outtextxy(5, 290, 'moved (Y/N)?');
          repeat
            c := readkey
          until (c in ['n', 'y', 'N', 'Y']);
          mbra := (c in ['Y', 'y']);
          setcolor(cblack);
          outtextxy(5, 270, 'Has rook on a8');
          outtextxy(5, 290, 'moved (Y/N)?');
        end;
        if (position[8, 8] = -3) then begin
          setcolor(cyellow);
          outtextxy(5, 270, 'Has rook on h8');
          outtextxy(5, 290, 'moved (Y/N)?');
          repeat
            c := readkey
          until (c in ['n', 'y', 'N', 'Y']);
          mbrh := (c in ['Y', 'y']);
          setcolor(cblack);
          outtextxy(5, 270, 'Has rook on h8');
          outtextxy(5, 290, 'moved (Y/N)?');
        end;
      end;
    end;

    for i := 1 to maxdepth + 1 do enpassant[i] := 100; askep := false;
    if (whitesturn) then begin
      if ((position[1, 5] = 6) and (position[2, 5] = -6) and
        (position[2, 6] = 0) and (position[2, 7] = 0)) then askep := true;
      if ((position[8, 5] = 6) and (position[7, 5] = -6) and
        (position[7, 6] = 0) and (position[7, 7] = 0)) then askep := true;
      for i := 2 to 7 do begin
        if ((position[i, 5] = 6) and (position[i + 1, 5] = -6) and
          (position[i + 1, 6] = 0) and (position[i + 1, 7] = 0)) then askep := true;
        if ((position[i, 5] = 6) and (position[i - 1, 5] = -6) and
          (position[i - 1, 6] = 0) and (position[i - 1, 7] = 0)) then askep := true;
      end;
    end
    else begin
      if ((position[1, 4] = -6) and (position[2, 4] = 6) and
        (position[2, 3] = 0) and (position[2, 2] = 0)) then askep := true;
      if ((position[8, 4] = -6) and (position[7, 4] = 6) and
        (position[7, 3] = 0) and (position[7, 2] = 0)) then askep := true;
      for i := 2 to 7 do begin
        if ((position[i, 4] = -6) and (position[i + 1, 4] = 6) and
          (position[i + 1, 3] = 0) and (position[i + 1, 2] = 0)) then askep := true;
        if ((position[i, 4] = -6) and (position[i - 1, 4] = 6) and
          (position[i - 1, 2] = 0) and (position[i - 1, 2] = 0)) then askep := true;
      end;
    end;
    if (askep) then begin
      setcolor(cyellow);
      outtextxy(5, 270, 'Is en passant');
      outtextxy(5, 290, 'allowed (Y/N)');
      repeat
        c := readkey
      until (c in ['n', 'y', 'N', 'Y']);
      joo := (c in ['Y', 'y']);
      if (joo) then begin
        outtextxy(5, 320, 'To file >');
        repeat
          c := readkey;
          if ((c >= 'A') and (c <= 'H')) then c := chr(ord(c) - ord('A') + ord('a'));
        until (c in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']);
        enpassant[1] := (ord(c) - ord('a') + 1);
      end;
      setcolor(cblack);
      outtextxy(5, 320, 'To file >');
      outtextxy(5, 270, 'Is en passant');
      outtextxy(5, 290, 'allowed (Y/N)');
    end;
    300: settextstyle(defaultfont, horizdir, 2);
    movesmade := 0;

    cursorx := 1; cursory := 1;
    if (not whiteatbottom) then begin
      cursorx := files; cursory := ranks;
    end;
    playeriswhite := (whitesturn);
  end
  else begin
    for i := 1 to files do for j := 1 to ranks do position[i, j] := 0;
    position[1, 2] := 6; position[2, 2] := 6; position[3, 2] := 6; position[4, 2] := 6;
    position[5, 2] := 6; position[6, 2] := 6; position[7, 2] := 6; position[8, 2] := 6;
    position[1, 1] := 3; position[2, 1] := 5; position[3, 1] := 4; position[4, 1] := 2;
    position[5, 1] := 1; position[6, 1] := 4; position[7, 1] := 5; position[8, 1] := 3;
    position[1, 7] := -6; position[2, 7] := -6; position[3, 7] := -6; position[4, 7] := -6;
    position[5, 7] := -6; position[6, 7] := -6; position[7, 7] := -6; position[8, 7] := -6;
    position[1, 8] := -3; position[2, 8] := -5; position[3, 8] := -4; position[4, 8] := -2;
    position[5, 8] := -1; position[6, 8] := -4; position[7, 8] := -5; position[8, 8] := -3;
    for i := 1 to files do for j := 1 to ranks do
        draw_piece(i, j, position[i, j]);
    whitesturn := true;
    cursorx := 1; cursory := 1;
    if (not whiteatbottom) then begin
      cursorx := files; cursory := ranks;
    end;
    playeriswhite := true;
    wkx := 5; wky := 1; bkx := 5; bky := 8; for i := 1 to maxdepth + 1 do enpassant[i] := 100;
    mwk := false; mbk := false; mwra := false; mbra := false; mwrh := false; mbrh := false;
    movesmade := 0;
  end;

  if (whiteatbottom) then begin
    settextstyle(defaultfont, horizdir, 1);
    setcolor(cblack);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(ord('i') - i));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(ord('9') - i));
    setcolor(ccyan);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(i + ord('a') - 1));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(i + ord('0')));
  end
  else begin
    settextstyle(defaultfont, horizdir, 1);
    setcolor(cblack);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(i + ord('a') - 1));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(i + ord('0')));
    setcolor(ccyan);
    for i := 1 to 8 do outtextxy(91 + i * 50, 445, chr(ord('i') - i));
    for i := 1 to 8 do outtextxy(110, 460 - 50 * i, chr(ord('9') - i));
  end;
  if (setup) then movesmade := 30;
  settextstyle(defaultfont, horizdir, 2);
  setcolor(cgreen);
  outtextxy(0, 330, 'Your');
  outtextxy(0, 360, 'move');

  previous.avaus := avaus;
  previous.positio := position;
  previous.mnumber := movenumber;
  previous.ep := enpassant[1];
  previous.wtomove := whitesturn;
  previous.wk := mwk;
  previous.bk := mbk;
  previous.wra := mwra;
  previous.bra := mbra;
  previous.wrh := mwrh;
  previous.brh := mbrh;
end;

procedure infos;
var i: integer;
begin
  setcolor(clightgray);
  settextstyle(defaultfont, horizdir, 1);
  outtextxy(33, (ymargin div 2) - 15,
    'New      Make     Turn     Sound     View     Setup    Square    2 player');
  outtextxy(33, (ymargin div 2) - 5,
    'game     move     board    on/off    score    board    colors    analysis');
  setcolor(cgreen);
  for i := 1 to 4 do begin
    moveto(27 + (i - 1) * 72, (ymargin div 2) + 5);
    linerel(0, -20); linerel(-22, 0); linerel(0, 20); linerel(22, 0);
  end;
  for i := 5 to 7 do begin
    moveto(34 + (i - 1) * 72, (ymargin div 2) + 5);
    linerel(0, -20); linerel(-22, 0); linerel(0, 20); linerel(22, 0);
  end;
  moveto(42 + 7 * 72, (ymargin div 2) + 5);
  linerel(0, -20); linerel(-22, 0); linerel(0, 20); linerel(22, 0);
  outtextxy(9, (ymargin div 2) - 10,
    'F1       F2       F3       F4        F5       F6       F7        F8');
  settextstyle(defaultfont, horizdir, 2);
  setcolor(clightgray);
  outtextxy(5, 480 - (ymargin div 2), '-/+ ' + secstr + ' s. /move  Load Save  ESC Exit');
  setcolor(cgreen);
  outtextxy(5, 480 - (ymargin div 2), '-/+                L    S     ESC');
  setcolor(cyellow);
  outtextxy(5, 480 - (ymargin div 2), '    ' + secstr);
end;

procedure add_movetime;
var add: integer;
begin
  if (movesecs < 15) then add := 1 else
    if (movesecs < 60) then add := 5 else
      if (movesecs < 600) then add := 10 else
        add := 100;
  movesecs := movesecs + add;
  if (movesecs > 9999) then movesecs := 0;
  setcolor(cblack);
  outtextxy(5, 480 - (ymargin div 2), '    ' + secstr);
  str(movesecs: 4, secstr);
  setcolor(cyellow);
  outtextxy(5, 480 - (ymargin div 2), '    ' + secstr);
end;

procedure subtract_time;
var add: integer;
begin
  if (movesecs <= 10) then add := 1 else
    if (movesecs <= 60) then add := 5 else
      if (movesecs <= 600) then add := 10 else
        add := 100;
  movesecs := movesecs - add;
  if (movesecs < 0) then movesecs := 9900;
  setcolor(cblack);
  outtextxy(5, 480 - (ymargin div 2), '    ' + secstr);
  str(movesecs: 4, secstr);
  setcolor(cyellow);
  outtextxy(5, 480 - (ymargin div 2), '    ' + secstr);
end;

procedure players_move;
var
  wasx, wasy, file1, rank1, file2, rank2, moved, taken, i: integer;
  escape, illegal: boolean; siirto: string; etum, valim: char;
  ch: char;
begin
  ch := 'z';
  searchlegmvs(whitesturn, 1);
  wasx := cursorx; wasy := cursory; escape := false;
  if (ord(ch) = 13) then else
    repeat
      if ((ord(ch) = 72) and (cursory < ranks)) then begin
        delcursor;
        cursory := cursory + 1;
        drawcursor;
      end;
      if ((ord(ch) = 80) and (cursory > 1)) then begin
        delcursor;
        cursory := cursory - 1;
        drawcursor;
      end;
      if ((ord(ch) = 77) and (cursorx < files)) then begin
        delcursor;
        cursorx := cursorx + 1;
        drawcursor;
      end;
      if ((ord(ch) = 75) and (cursorx > 1)) then begin
        delcursor;
        cursorx := cursorx - 1;
        drawcursor;
      end;

      ch := readkey;
      if (not (ord(ch) in [0, 13, 72, 75, 77, 80])) then escape := true;
    until ((ord(ch) = 13) or (escape));
  file1 := cursorx; rank1 := cursory;
  drawmark;
  if (not whiteatbottom) then begin
    file1 := files + 1 - file1;
    rank1 := ranks + 1 - rank1;
  end;
  if (escape) then else
    repeat

      if ((ord(ch) = 72) and (cursory < ranks)) then begin
        delcursor;
        cursory := cursory + 1;
        drawcursor;
      end;
      if ((ord(ch) = 80) and (cursory > 1)) then begin
        delcursor;
        cursory := cursory - 1;
        drawcursor;
      end;
      if ((ord(ch) = 77) and (cursorx < files)) then begin
        delcursor;
        cursorx := cursorx + 1;
        drawcursor;
      end;
      if ((ord(ch) = 75) and (cursorx > 1)) then begin
        delcursor;
        cursorx := cursorx - 1;
        drawcursor;
      end;
      ch := readkey;
      if (not (ord(ch) in [0, 13, 72, 75, 77, 80])) then escape := true;
    until ((ord(ch) = 13) or (escape));
  file2 := cursorx; rank2 := cursory;
  if (not whiteatbottom) then begin
    file2 := files + 1 - file2;
    rank2 := ranks + 1 - rank2;
  end;
  illegal := true;
  for i := 1 to legals[1] do if ((legmvs[1, i].file1 = file1) and
      (legmvs[1, i].file2 = file2) and (legmvs[1, i].rank1 = rank1) and
      (legmvs[1, i].rank2 = rank2)) then illegal := false;
  if (illegal) then begin
    delcursor;
    draw_piece(file1, rank1, position[file1, rank1]);
    cursorx := wasx; cursory := wasy;
  end
  else begin
    previous.avaus := avaus;
    previous.positio := position;
    previous.mnumber := movenumber;
    previous.ep := enpassant[1];
    previous.wtomove := whitesturn;
    previous.wk := mwk;
    previous.bk := mbk;
    previous.wra := mwra;
    previous.bra := mbra;
    previous.wrh := mwrh;
    previous.brh := mbrh;
    valim := '-';
    moved := position[file1, rank1];
    if (abs(moved) < 6) then begin
      lmoved[8] := lmoved[7];
      lmoved[7] := lmoved[6];
      lmoved[6] := lmoved[5];
      lmoved[5] := lmoved[4];
      lmoved[4] := lmoved[3];
      lmoved[3] := lmoved[2];
      lmoved[2] := lmoved[1];
      lmoved[1] := moved;
    end;
    taken := position[file2, rank2];
    if (taken <> 0) then valim := 'x';
    if (moved = 1) then mwk := true;
    if (moved = -1) then mbk := true;
    if ((file1 = 1) and (rank1 = 1)) then mwra := true;
    if ((file1 = 8) and (rank1 = 1)) then mwrh := true;
    if ((file1 = 1) and (rank1 = 8)) then mbra := true;
    if ((file1 = 8) and (rank1 = 8)) then mbrh := true;
    if ((file2 = 1) and (rank2 = 1)) then mwra := true;
    if ((file2 = 8) and (rank2 = 1)) then mwrh := true;
    if ((file2 = 1) and (rank2 = 8)) then mbra := true;
    if ((file2 = 8) and (rank2 = 8)) then mbrh := true;
    if (moved = 1) and (file1 + 2 = file2) then begin
      position[8, 1] := 0; position[6, 1] := 3;
      draw_piece(8, 1, position[8, 1]);
      draw_piece(6, 1, position[6, 1]);
    end;
    if (moved = 1) and (file1 - 2 = file2) then begin
      position[1, 1] := 0; position[4, 1] := 3;
      draw_piece(1, 1, position[1, 1]);
      draw_piece(4, 1, position[4, 1]);
    end;
    if (moved = -1) and (file1 + 2 = file2) then begin
      position[8, 8] := 0; position[6, 8] := -3;
      draw_piece(8, 8, position[8, 8]);
      draw_piece(6, 8, position[6, 8]);
    end;
    if (moved = -1) and (file1 - 2 = file2) then begin
      position[1, 8] := 0; position[4, 8] := -3;
      draw_piece(1, 8, position[1, 8]);
      draw_piece(4, 8, position[4, 8]);
    end;

    position[file1, rank1] := 0;
    position[file2, rank2] := moved;
    if ((moved = 6) and (rank2 = ranks)) then
      position[file2, rank2] := promoted;
    if ((moved = -6) and (rank2 = 1)) then
      position[file2, rank2] := -promoted;
    enpassant[1] := 100;
    if ((moved = 6) and (rank2 - rank1 = 2)) then enpassant[1] := file1;
    if ((moved = -6) and (rank1 - rank2 = 2)) then enpassant[1] := file1;
    if ((moved = 6) and (file2 <> file1) and (taken = 0)) then begin
      position[file2, rank1] := 0; valim := 'x';
      draw_piece(file2, rank1, position[file2, rank1]);
    end;
    if ((moved = -6) and (file2 <> file1) and (taken = 0)) then begin
      position[file2, rank1] := 0; valim := 'x';
      draw_piece(file2, rank1, position[file2, rank1]);
    end;
    draw_piece(file1, rank1, position[file1, rank1]);
    draw_piece(file2, rank2, position[file2, rank2]);
    if (moved > 0) then movenumber := movenumber + 1;
    whitesturn := (not whitesturn);
    movesmade := movesmade + 1;

    if (abs(moved) = 1) then etum := 'K' else
      if (abs(moved) = 2) then etum := 'Q' else
        if (abs(moved) = 3) then etum := 'R' else
          if (abs(moved) = 4) then etum := 'B' else
            if (abs(moved) = 5) then etum := 'N' else
              etum := ' ';
    if (length(avaus) < 252) then avaus := avaus + chr(file1 + ord('a') - 1) + chr(rank1 + ord('0')) +
      chr(file2 + ord('a') - 1) + chr(rank2 + ord('0'));
    if (moved > 0) then begin
      str(movenumber: 3, siirto);
      siirto := siirto + '.';
    end
    else siirto := '    ';
    siirto := siirto + ' ' + etum + chr(file1 + ord('a') - 1) + chr(rank1 + ord('0')) + valim +
      chr(file2 + ord('a') - 1) + chr(rank2 + ord('0'));
    if (moved > 0) then write(gamef, siirto) else writeln(gamef, siirto);
    update_movelist(siirto);
  end;
  if (escape) then ch := 'z'
end;

procedure computers_move;
var
  mv: movetype; sc, moved, taken, i: integer; found: boolean; siirto: string;
  etum, valim: char; fiu1, rau1, fiu2, rau2: integer;
begin
  found := false;
  if (movesmade < 26) then
    for i := 1 to blines do
      if ((length(bookline[i]^) > length(avaus))
      and (copy(bookline[i]^, 1, length(avaus)) = avaus)) then
      begin
        found := true;
        mv.file1 := ord(bookline[i]^[length(avaus) + 1]) + 1 - ord('a');
        mv.rank1 := ord(bookline[i]^[length(avaus) + 2]) + 1 - ord('1');
        mv.file2 := ord(bookline[i]^[length(avaus) + 3]) + 1 - ord('a');
        mv.rank2 := ord(bookline[i]^[length(avaus) + 4]) + 1 - ord('1');
      end;

  if analysis then found := false;

  if not found then
  begin
    if analysis then
    else
    begin
      setcolor(cblack);
      outtextxy(0, 330, 'Your');
      outtextxy(0, 360, 'move');
      setcolor(cgreen);
      settextstyle(defaultfont, horizdir, 1);
      outtextxy(25, 392, ' SPACE');
      setcolor(clightgray);
      outtextxy(20, 410, 'MOVE NOW!');
      settextstyle(defaultfont, horizdir, 2);
    end;
    compute(whitesturn, mv, sc, movesecs * 100);
  end;
  if not analysis then
  begin
    if whiteatbottom then
    begin
      fiu1 := mv.file1; rau1 := mv.rank1;
      fiu2 := mv.file2; rau2 := mv.rank2;
    end else
    begin
      fiu1 := 9 - mv.file1; rau1 := 9 - mv.rank1;
      fiu2 := 9 - mv.file2; rau2 := 9 - mv.rank2;
    end;
    setcolor(cwhite);
    moveto(xmargin + fiu1 * 50 - 2, 480 - ymargin - rau1 * 50 + 48);
    linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
    moveto(xmargin + fiu1 * 50 - 1, 480 - ymargin - rau1 * 50 + 49);
    linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
    moveto(xmargin + fiu1 * 50 - 3, 480 - ymargin - rau1 * 50 + 47);
    linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
    moveto(xmargin + fiu2 * 50 - 2, 480 - ymargin - rau2 * 50 + 48);
    linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
    moveto(xmargin + fiu2 * 50 - 1, 480 - ymargin - rau2 * 50 + 49);
    linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
    moveto(xmargin + fiu2 * 50 - 3, 480 - ymargin - rau2 * 50 + 47);
    linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
    if soundon then Beep;
    Sleep(400);
    setcolor(clightred);
    moveto(xmargin + fiu1 * 50 - 2, 480 - ymargin - rau1 * 50 + 48);
    linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
    moveto(xmargin + fiu1 * 50 - 1, 480 - ymargin - rau1 * 50 + 49);
    linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
    moveto(xmargin + fiu1 * 50 - 3, 480 - ymargin - rau1 * 50 + 47);
    linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
    moveto(xmargin + fiu2 * 50 - 2, 480 - ymargin - rau2 * 50 + 48);
    linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
    moveto(xmargin + fiu2 * 50 - 1, 480 - ymargin - rau2 * 50 + 49);
    linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
    moveto(xmargin + fiu2 * 50 - 3, 480 - ymargin - rau2 * 50 + 47);
    linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
    Sleep(400);
    setcolor(cwhite);
    moveto(xmargin + fiu1 * 50 - 2, 480 - ymargin - rau1 * 50 + 48);
    linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
    moveto(xmargin + fiu1 * 50 - 1, 480 - ymargin - rau1 * 50 + 49);
    linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
    moveto(xmargin + fiu1 * 50 - 3, 480 - ymargin - rau1 * 50 + 47);
    linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
    moveto(xmargin + fiu2 * 50 - 2, 480 - ymargin - rau2 * 50 + 48);
    linerel(0, -46); linerel(-46, 0); linerel(0, 46); linerel(46, 0);
    moveto(xmargin + fiu2 * 50 - 1, 480 - ymargin - rau2 * 50 + 49);
    linerel(0, -48); linerel(-48, 0); linerel(0, 48); linerel(48, 0);
    moveto(xmargin + fiu2 * 50 - 3, 480 - ymargin - rau2 * 50 + 47);
    linerel(0, -44); linerel(-44, 0); linerel(0, 44); linerel(44, 0);
    Sleep(400);
    moved := position[mv.file1, mv.rank1];
    taken := position[mv.file2, mv.rank2];
    if abs(moved) < 6 then
    begin
      lmoved[8] := lmoved[7];
      lmoved[7] := lmoved[6];
      lmoved[6] := lmoved[5];
      lmoved[5] := lmoved[4];
      lmoved[4] := lmoved[3];
      lmoved[3] := lmoved[2];
      lmoved[2] := lmoved[1];
      lmoved[1] := moved;
    end;
    if (taken = 0) then valim := '-' else valim := 'x';
    if (moved = 1) then mwk := true;
    if (moved = -1) then mbk := true;
    if ((mv.file1 = 1) and (mv.rank1 = 1)) then mwra := true;
    if ((mv.file1 = 8) and (mv.rank1 = 1)) then mwrh := true;
    if ((mv.file1 = 1) and (mv.rank1 = 8)) then mbra := true;
    if ((mv.file1 = 8) and (mv.rank1 = 8)) then mbrh := true;
    if ((mv.file2 = 1) and (mv.rank2 = 1)) then mwra := true;
    if ((mv.file2 = 8) and (mv.rank2 = 1)) then mwrh := true;
    if ((mv.file2 = 1) and (mv.rank2 = 8)) then mbra := true;
    if ((mv.file2 = 8) and (mv.rank2 = 8)) then mbrh := true;
    position[mv.file1, mv.rank1] := 0;
    position[mv.file2, mv.rank2] := moved;
    if (moved > 0) then movenumber := movenumber + 1;
    if ((moved = 6) and (mv.rank2 = ranks)) then position[mv.file2, mv.rank2] := 2;
    if ((moved = -6) and (mv.rank2 = 1)) then position[mv.file2, mv.rank2] := -2;
    enpassant[1] := 100;
    if ((moved = 6) and (mv.rank2 - mv.rank1 = 2)) then enpassant[1] := mv.file1;
    if ((moved = -6) and (mv.rank1 - mv.rank2 = 2)) then enpassant[1] := mv.file1;
    if ((moved = 6) and (mv.file2 <> mv.file1) and (taken = 0)) then
    begin
      position[mv.file2, mv.rank1] := 0; valim := 'x';
      draw_piece(mv.file2, mv.rank1, position[mv.file2, mv.rank1]);
    end;
    if ((moved = -6) and (mv.file2 <> mv.file1) and (taken = 0)) then
    begin
      position[mv.file2, mv.rank1] := 0; valim := 'x';
      draw_piece(mv.file2, mv.rank1, position[mv.file2, mv.rank1]);
    end;
    if (moved = 1) and (mv.file1 + 2 = mv.file2) then
    begin
      position[8, 1] := 0; position[6, 1] := 3;
      draw_piece(8, 1, position[8, 1]);
      draw_piece(6, 1, position[6, 1]);
    end;
    if (moved = 1) and (mv.file1 - 2 = mv.file2) then
    begin
      position[1, 1] := 0; position[4, 1] := 3;
      draw_piece(1, 1, position[1, 1]);
      draw_piece(4, 1, position[4, 1]);
    end;
    if (moved = -1) and (mv.file1 + 2 = mv.file2) then
    begin
      position[8, 8] := 0; position[6, 8] := -3;
      draw_piece(8, 8, position[8, 8]);
      draw_piece(6, 8, position[6, 8]);
    end;
    if (moved = -1) and (mv.file1 - 2 = mv.file2) then
    begin
      position[1, 8] := 0; position[4, 8] := -3;
      draw_piece(1, 8, position[1, 8]);
      draw_piece(4, 8, position[4, 8]);
    end;
    draw_piece(mv.file1, mv.rank1, position[mv.file1, mv.rank1]);
    draw_piece(mv.file2, mv.rank2, position[mv.file2, mv.rank2]);
    movesmade := movesmade + 1;

    whitesturn := not whitesturn;
    setcolor(cblack);
    settextstyle(defaultfont, horizdir, 1);
    outtextxy(25, 392, ' SPACE');
    outtextxy(20, 410, 'MOVE NOW!');
    settextstyle(defaultfont, horizdir, 2);
    if length(avaus) < 252 then
      avaus := avaus +
      chr(mv.file1 + ord('a') - 1) + chr(mv.rank1 + ord('0')) +
      chr(mv.file2 + ord('a') - 1) + chr(mv.rank2 + ord('0'));
    if abs(moved) = 1 then etum := 'K' else
      if abs(moved) = 2 then etum := 'Q' else
        if abs(moved) = 3 then etum := 'R' else
          if abs(moved) = 4 then etum := 'B' else
            if abs(moved) = 5 then etum := 'N' else
              etum := ' ';
    if moved > 0 then
    begin
      str(movenumber: 3, siirto);
      siirto := siirto + '.'
    end else
      siirto := '    ';
    siirto := siirto + ' ' + etum + chr(mv.file1 + ord('a') - 1) + chr(mv.rank1 + ord('0')) +
      valim + chr(mv.file2 + ord('a') - 1) + chr(mv.rank2 + ord('0'));
    if (moved > 0) then write(gamef, siirto) else writeln(gamef, siirto);
    update_movelist(siirto);

    setcolor(cblack);
    outtextxy(0, 330, 'Your');
    outtextxy(0, 360, 'move');
    destr :=
      chr(mv.file1 + 96) +
      chr(mv.rank1 + 48) +
      chr(mv.file2 + 96) +
      chr(mv.rank2 + 48);
    setcolor(cgreen);
    outtextxy(0, 330, 'Your');
    outtextxy(0, 360, 'move');
    if (viewscores) then begin
      setcolor(cblue);
      outtextxy(5, 300, lstr);
    end;
  end
end;

var
  ii, jj: shortint;
  ch: char;
  
begin
  log.append(concat('** ', cappinfo));
  randomize; lstr := '0.0'; ch := 'z';

  for joku := 1 to blines do new(bookline[joku]);
  
  {$I book}

  assign(gamef, 'games.txt');
  if FileExists('games.txt') then
    append(gamef)
  else
    rewrite(gamef);
  
  set_to_graphics_mode; darks := cdarkgray; lights := clightgray; cursorc := cwhite;
  soundon := true;
  setbkcolor(cblack); whiteatbottom := true; movesecs := 5; viewscores := false;
  xmargin := 320 - 25 * files; ymargin := 240 - 25 * ranks; draw_board_skeleton;
  rrate := 4;
  settextstyle(defaultfont, horizdir, 2); str(movesecs: 4, secstr); infos;
  
  repeat
    set_initial_pos(false); gameover := false; avaus := ''; analysis := false;

    for aa := 1 to blines do
    begin
      cee := 1 + random(blines);
      templine := bookline[aa]^;
      bookline[aa]^ := bookline[cee]^;
      bookline[cee]^ := templine
    end;
    
    setcolor(cblack);
    outtextxy(20, 220, ' GAME');
    outtextxy(20, 250, ' OVER');
    outtextxy(5, 300, lstr);
    outtextxy(5, 275, beststr);
    lstr := 'book';
    
    repeat
      if analysis then
        computers_move
      else
        if ((whitesturn = not playeriswhite) and not gameover) then
          computers_move;

      for ii := 1 to ranks do for jj := 1 to files do
        if (position[jj, ii] = 1) then
        begin
          wkx := jj; wky := ii
        end else
          if (position[jj, ii] = -1) then
          begin
            bkx := jj; bky := ii
          end;
      
      searchlegmvs(whitesturn, 1);
      if (legals[1] < 1) then gameover := true;
      if (gameover) then
      begin
        settextstyle(defaultfont, horizdir, 1);
        setcolor(cblack);
        outtextxy(0, 250, kpstr);
        settextstyle(defaultfont, horizdir, 2);
        outtextxy(0, 330, 'Your');
        outtextxy(0, 360, 'move');
        setcolor(cyellow);
        outtextxy(20, 220, ' GAME');
        outtextxy(20, 250, ' OVER');
        if (soundon) then begin
          Beep;
        end
      end;
      drawcursor;
      ch := readkey;
      if (ord(ch) = 0) then ch := readkey;
      
      if (ch in ['l', 'L']) then
      begin
        empty_movelist; name := '';
        setcolor(cyellow);
        settextstyle(defaultfont, horizdir, 1);
        outtextxy(535, 340, 'Filename:');
        outtextxy(535, 380, '--------');
        repeat
          ch := readkey;
          if ((ch in ['a'..'z']) or (ch in ['A'..'Z']) or (ch in ['0'..'9'])) then name := name + ch;
          outtextxy(535, 370, name)
        until ((length(name) = 8) or (ord(ch) = 13));
        ch := 'z';
        setcolor(cblack);
        outtextxy(535, 340, 'Filename:');
        outtextxy(535, 380, '--------');
        outtextxy(535, 370, name);
        name := name + '.n5g';
        settextstyle(defaultfont, horizdir, 2);
        if FileExists(name) then
        begin
          assign(posf, name);
          reset(posf);
          writeln(gamef, ' ');
          writeln(gamef, 'Loaded position ', name);
          writeln(gamef, ' ');
          read(posf, previous);
          gameover := false;
          setcolor(cblack);
          outtextxy(20, 220, ' GAME');
          outtextxy(20, 250, ' OVER');
          outtextxy(5, 300, lstr);
          lstr := 'book';
          position := previous.positio;
          avaus := previous.avaus;
          movenumber := previous.mnumber;
          enpassant[1] := previous.ep;
          whitesturn := previous.wtomove;
          playeriswhite := whitesturn;
          mwk := previous.wk;
          mbk := previous.bk;
          mwra := previous.wra;
          mbra := previous.bra;
          mwrh := previous.wrh;
          mbrh := previous.brh;
          for aa := 1 to files do for cee := 1 to ranks do
            draw_piece(aa, cee, position[aa, cee]);
          empty_movelist;
          close(posf);
        end;
      end;
      
      if (ch in ['s', 'S']) then
      begin
        empty_movelist; name := '';
        setcolor(cyellow);
        settextstyle(defaultfont, horizdir, 1);
        outtextxy(535, 340, 'Filename:');
        outtextxy(535, 380, '--------');
        repeat
          ch := readkey;
          if ((ch in ['a'..'z']) or (ch in ['A'..'Z']) or (ch in ['0'..'9'])) then name := name + ch;
          outtextxy(535, 370, name)
        until ((length(name) = 8) or (ord(ch) = 13));
        ch := 'z';
        setcolor(cblack);
        outtextxy(535, 340, 'Filename:');
        outtextxy(535, 380, '--------');
        outtextxy(535, 370, name);
        name := name + '.n5g';
        settextstyle(defaultfont, horizdir, 2);
        assign(posf, name);
        rewrite(posf);
        previous.avaus := avaus;
        previous.positio := position;
        previous.mnumber := movenumber;
        previous.ep := enpassant[1];
        previous.wtomove := whitesturn;
        previous.wk := mwk;
        previous.bk := mbk;
        previous.wra := mwra;
        previous.bra := mbra;
        previous.wrh := mwrh;
        previous.brh := mbrh;
        write(posf, previous);
        close(posf);
      end;

      if (ord(ch) = 62) then begin
        soundon := (not soundon);
        if (soundon) then begin
          Beep;
        end
      end;
      
      if (ord(ch) = 63) then
      begin
        viewscores := (not viewscores);
        if (viewscores) then setcolor(cblue)
        else setcolor(cblack);
        outtextxy(5, 300, lstr);
      end;
      if (ord(ch) = 61) then turn_board;
      if (ord(ch) = 65) then setsqc;
      if (ord(ch) = 66) then
      begin
        viewscores := true;
        analysis := (not analysis)
      end;
      if (ord(ch) = 8) then
      begin
        gameover := false;
        setcolor(cblack);
        outtextxy(20, 220, ' GAME');
        outtextxy(20, 250, ' OVER');
        outtextxy(5, 300, lstr);
        lstr := 'book';
        position := previous.positio;
        avaus := previous.avaus;
        movenumber := previous.mnumber;
        enpassant[1] := previous.ep;
        whitesturn := previous.wtomove;
        mwk := previous.wk;
        mbk := previous.bk;
        mwra := previous.wra;
        mbra := previous.bra;
        mwrh := previous.wrh;
        mbrh := previous.brh;
        for aa := 1 to files do for cee := 1 to ranks do
          draw_piece(aa, cee, position[aa, cee]);
        update_movelist('   Takeback');
        writeln(gamef, ' ');
        writeln(gamef, ' OOPS!');
        writeln(gamef, ' ');
      end;

      if (ord(ch) = 64) then set_initial_pos(true);
      if (ord(ch) = 60) then
      begin
        playeriswhite := (not playeriswhite);
        analysis := false
      end;
      if ((ord(ch) in [13, 72, 75, 77, 80]) and (not gameover)) then
        players_move;

      for ii := 1 to ranks do for jj := 1 to files do
        if (position[jj, ii] = 1) then
        begin
          wkx := jj; wky := ii
        end
        else if (position[jj, ii] = -1) then begin
          bkx := jj; bky := ii
        end;
      searchlegmvs(whitesturn, 1);
      if (legals[1] < 1) then gameover := true;
      if (gameover) then
      begin
        settextstyle(defaultfont, horizdir, 1);
        setcolor(cblack);
        outtextxy(0, 250, kpstr);
        settextstyle(defaultfont, horizdir, 2);
        setcolor(cyellow);
        outtextxy(20, 220, ' GAME');
        outtextxy(20, 250, ' OVER');
        if (soundon) then begin
          Beep;
        end
      end;
      if (ch = '+') then add_movetime;
      if (ch = '-') then subtract_time;
    until ((ord(ch) = 59) or (ord(ch) = 27) or (ord(ch) = 3));
  until (ord(ch) = 27) or (ord(ch) = 3);
  close(gamef);
  closegraph;
  (*
  writeln('You have played freeware program NERO 5.');
  writeln('Send your feedback!');
  writeln('<huikari@mit.jyu.fi>');
  writeln('Jari Huikari, Jenkkakuja 1 B 34, 40520 JKL, FINLAND');
  *)
  for joku := 1 to blines do dispose(bookline[joku]);
end.
