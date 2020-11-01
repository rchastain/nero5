
unit engine88;

interface

uses
  sysutils, ptccrt, ptcgraph;

const
  maxdepth = 40;
  maxmoves = 200;
  files = 8;
  ranks = 8;

type
  positiontype = array[1..files, 1..ranks] of shortint;

  movetype = record
    file1, rank1, file2, rank2, degree: shortint;
  end;

var
  position: positiontype;

  legals: array[1..maxdepth + 1] of integer;
  beta: array[1..maxdepth + 1] of integer;
  enpassant: array[1..maxdepth + 1] of shortint;
  legmvs: array[1..maxdepth + 1, 1..maxmoves] of movetype;
  best2: array[1..maxmoves] of movetype;
  bonuses, movescores: array[1..maxmoves] of integer;
  lmoved, bpwns, wpwns: array[1..8] of shortint;
  killer, killer2: array[2..maxdepth] of movetype;


  bigs, storesc, searchdepth, mcount, rrate, hyva, huonoja,
    viimeksi, wmat, bmat, bonus, movesmade, posvalue: integer;
  kpos, positions, pos2: longint;
  mwk, mbk, mwra, mbra, mwrh, mbrh, viewscores, analysis,
    keskeyta, opening, stopcalc: boolean;

  replystr, kpstr, beststr, lstr, destr, cstr, mstr: string;
  wkx, wky, bkx, bky: shortint;
  chi: char;
  ho2, mi2, se2, hu2, ho1, mi1, se1, hu1: word;
  sekunnit, smax: longint;

procedure searchlegmvs(forwhite: boolean; depth: integer);

procedure compute(forwhite: boolean; var bestmove: movetype; var score: integer;
  seconds: longint);

implementation

{$I colors4}

procedure gettime(var hour, minute, second, sec100: word);
var
  millisecond: word;
begin
  decodetime(time, hour, minute, second, millisecond);
  sec100 := millisecond div 10;
end;

procedure searchlegmvs(forwhite: boolean; depth: integer);
var x1, y1, moved, taken: shortint; ep, nopossiblechecks, incheck: boolean;

  procedure makemove(x2, y2: shortint);

  begin
    moved := position[x1, y1];
    taken := position[x2, y2];
    position[x1, y1] := 0;
    position[x2, y2] := moved;
    if (ep) then position[x2, y1] := 0;

    if (moved > 0) then begin
      if (moved = 1) then begin
        wkx := x2; wky := y2;
        if (x2 = x1 + 2) then begin
          position[8, 1] := 0; position[6, 1] := 3
        end
        else if (x2 = x1 - 2) then begin
          position[1, 1] := 0; position[4, 1] := 3
        end
      end
      else if ((moved = 6) and (y2 = ranks)) then position[x2, y2] := 2
    end
    else begin
      if (moved = -1) then begin
        bkx := x2; bky := y2;
        if (x2 = x1 + 2) then begin
          position[8, 8] := 0; position[6, 8] := -3
        end
        else if (x2 = x1 - 2) then begin
          position[1, 8] := 0; position[4, 8] := -3
        end
      end
      else if ((moved = -6) and (y2 = 1)) then position[x2, y2] := -2
    end
  end;

  procedure unmakemv(x2, y2: shortint);
  begin
    position[x1, y1] := moved;
    position[x2, y2] := taken;

    if (moved > 0) then begin
      if (ep) then position[x2, y1] := -6
      else if (moved = 1) then begin
        wkx := x1; wky := y1;
        if (x2 = x1 + 2) then begin
          position[8, 1] := 3; position[6, 1] := 0
        end
        else if (x2 = x1 - 2) then begin
          position[1, 1] := 3; position[4, 1] := 0
        end
      end
    end
    else begin
      if (ep) then position[x2, y1] := 6
      else if (moved = -1) then begin
        bkx := x1; bky := y1;
        if (x2 = x1 + 2) then begin
          position[8, 8] := -3; position[6, 8] := 0
        end
        else if (x2 = x1 - 2) then begin
          position[1, 8] := -3; position[4, 8] := 0
        end
      end
    end
  end;

  function kingincheck: boolean;
  var xx, yy: shortint;
  label 111, 222;
  begin
    kingincheck := false;
    if (forwhite) then begin
      if ((wkx > 1) and (wky > 1)) then
        if (position[wkx - 1, wky - 1] = -1) then goto 111;
      if (wkx > 1) then
        if (position[wkx - 1, wky] = -1) then goto 111;
      if (wkx < files) then
        if (position[wkx + 1, wky] = -1) then goto 111;
      if (wky > 1) then
        if (position[wkx, wky - 1] = -1) then goto 111;
      if (wky < ranks) then
        if (position[wkx, wky + 1] = -1) then goto 111;
      if ((wkx < files) and (wky < ranks)) then begin
        if (position[wkx + 1, wky + 1] = -6) then goto 111;
        if (position[wkx + 1, wky + 1] = -1) then goto 111
      end;
      if ((wkx < files) and (wky > 1)) then
        if (position[wkx + 1, wky - 1] = -1) then goto 111;
      if ((wkx > 1) and (wky < ranks)) then begin
        if (position[wkx - 1, wky + 1] = -6) then goto 111;
        if (position[wkx - 1, wky + 1] = -1) then goto 111
      end;
      if ((wkx > 2) and (wky < ranks)) then
        if (position[wkx - 2, wky + 1] = -5) then goto 111;
      if ((wkx > 2) and (wky > 1)) then
        if (position[wkx - 2, wky - 1] = -5) then goto 111;
      if ((wkx < files - 1) and (wky < ranks)) then
        if (position[wkx + 2, wky + 1] = -5) then goto 111;
      if ((wkx < files - 1) and (wky > 1)) then
        if (position[wkx + 2, wky - 1] = -5) then goto 111;
      if ((wkx < files) and (wky > 2)) then
        if (position[wkx + 1, wky - 2] = -5) then goto 111;
      if ((wkx > 1) and (wky > 2)) then
        if (position[wkx - 1, wky - 2] = -5) then goto 111;
      if ((wkx < files) and (wky < ranks - 1)) then
        if (position[wkx + 1, wky + 2] = -5) then goto 111;
      if ((wkx > 1) and (wky < ranks - 1)) then
        if (position[wkx - 1, wky + 2] = -5) then goto 111;
      xx := wkx; yy := wky;
      repeat
        if (yy < ranks) then if (position[xx, yy + 1] = 0) then yy := yy + 1;
      until ((yy = ranks) or (position[xx, yy + 1] <> 0));
      if (yy < ranks) then
        if ((position[xx, yy + 1] = -2) or (position[xx, yy + 1] = -3)) then goto 111;
      xx := wkx; yy := wky;
      repeat
        if (yy > 1) then if (position[xx, yy - 1] = 0) then yy := yy - 1;
      until ((yy = 1) or (position[xx, yy - 1] <> 0));

      if (yy > 1) then
        if ((position[xx, yy - 1] = -2) or (position[xx, yy - 1] = -3)) then goto 111;
      xx := wkx; yy := wky;
      repeat
        if (xx < files) then if (position[xx + 1, yy] = 0) then xx := xx + 1;
      until ((xx = files) or (position[xx + 1, yy] <> 0));
      if (xx < files) then
        if ((position[xx + 1, yy] = -2) or (position[xx + 1, yy] = -3)) then goto 111;
      xx := wkx; yy := wky;
      repeat
        if (xx > 1) then if (position[xx - 1, yy] = 0) then xx := xx - 1;
      until ((xx = 1) or (position[xx - 1, yy] <> 0));
      if (xx > 1) then
        if ((position[xx - 1, yy] = -2) or (position[xx - 1, yy] = -3)) then goto 111;

      xx := wkx; yy := wky;
      repeat
        if ((xx > 1) and (yy > 1)) then if (position[xx - 1, yy - 1] = 0) then begin
            xx := xx - 1; yy := yy - 1;
          end;
      until ((xx = 1) or (yy = 1) or (position[xx - 1, yy - 1] <> 0));
      if ((xx > 1) and (yy > 1)) then
        if ((position[xx - 1, yy - 1] = -2) or (position[xx - 1, yy - 1] = -4)) then goto 111;
      xx := wkx; yy := wky;
      repeat
        if ((xx > 1) and (yy < ranks)) then if (position[xx - 1, yy + 1] = 0) then begin
            xx := xx - 1; yy := yy + 1;
          end;
      until ((xx = 1) or (yy = ranks) or (position[xx - 1, yy + 1] <> 0));
      if ((xx > 1) and (yy < ranks)) then
        if ((position[xx - 1, yy + 1] = -2) or (position[xx - 1, yy + 1] = -4)) then goto 111;
      xx := wkx; yy := wky;
      repeat
        if ((xx < files) and (yy > 1)) then if (position[xx + 1, yy - 1] = 0) then begin
            xx := xx + 1; yy := yy - 1;
          end;
      until ((xx = files) or (yy = 1) or (position[xx + 1, yy - 1] <> 0));
      if ((xx < files) and (yy > 1)) then
        if ((position[xx + 1, yy - 1] = -2) or (position[xx + 1, yy - 1] = -4)) then goto 111;
      xx := wkx; yy := wky;
      repeat
        if ((xx < files) and (yy < ranks)) then if (position[xx + 1, yy + 1] = 0) then
          begin
            xx := xx + 1; yy := yy + 1;
          end;
      until ((xx = files) or (yy = ranks) or (position[xx + 1, yy + 1] <> 0));
      if ((xx < files) and (yy < ranks)) then
        if ((position[xx + 1, yy + 1] = -2) or (position[xx + 1, yy + 1] = -4)) then goto 111;
    end
    else begin
      if ((bkx > 1) and (bky > 1)) then begin
        if (position[bkx - 1, bky - 1] = 1) then goto 111;
        if (position[bkx - 1, bky - 1] = 6) then goto 111;
      end;
      if (bkx > 1) then
        if (position[bkx - 1, bky] = 1) then goto 111;
      if (bkx < files) then
        if (position[bkx + 1, bky] = 1) then goto 111;
      if (bky > 1) then
        if (position[bkx, bky - 1] = 1) then goto 111;
      if (bky < ranks) then
        if (position[bkx, bky + 1] = 1) then goto 111;
      if ((bkx < files) and (bky < ranks)) then
        if (position[bkx + 1, bky + 1] = 1) then goto 111;
      if ((bkx < files) and (bky > 1)) then begin
        if (position[bkx + 1, bky - 1] = 1) then goto 111;
        if (position[bkx + 1, bky - 1] = 6) then goto 111;
      end;
      if ((bkx > 1) and (bky < ranks)) then
        if (position[bkx - 1, bky + 1] = 1) then goto 111;
      if ((bkx > 2) and (bky < ranks)) then
        if (position[bkx - 2, bky + 1] = 5) then goto 111;
      if ((bkx > 2) and (bky > 1)) then
        if (position[bkx - 2, bky - 1] = 5) then goto 111;
      if ((bkx < files - 1) and (bky < ranks)) then
        if (position[bkx + 2, bky + 1] = 5) then goto 111;
      if ((bkx < files - 1) and (bky > 1)) then
        if (position[bkx + 2, bky - 1] = 5) then goto 111;
      if ((bkx < files) and (bky > 2)) then
        if (position[bkx + 1, bky - 2] = 5) then goto 111;
      if ((bkx > 1) and (bky > 2)) then
        if (position[bkx - 1, bky - 2] = 5) then goto 111;
      if ((bkx < files) and (bky < ranks - 1)) then
        if (position[bkx + 1, bky + 2] = 5) then goto 111;
      if ((bkx > 1) and (bky < ranks - 1)) then
        if (position[bkx - 1, bky + 2] = 5) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if (yy < ranks) then if (position[xx, yy + 1] = 0) then yy := yy + 1;
      until ((yy = ranks) or (position[xx, yy + 1] <> 0));
      if (yy < ranks) then
        if ((position[xx, yy + 1] = 2) or (position[xx, yy + 1] = 3)) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if (yy > 1) then if (position[xx, yy - 1] = 0) then yy := yy - 1;
      until ((yy = 1) or (position[xx, yy - 1] <> 0));
      if (yy > 1) then
        if ((position[xx, yy - 1] = 2) or (position[xx, yy - 1] = 3)) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if (xx < files) then if (position[xx + 1, yy] = 0) then xx := xx + 1;
      until ((xx = files) or (position[xx + 1, yy] <> 0));
      if (xx < files) then
        if ((position[xx + 1, yy] = 2) or (position[xx + 1, yy] = 3)) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if (xx > 1) then if (position[xx - 1, yy] = 0) then xx := xx - 1;
      until ((xx = 1) or (position[xx - 1, yy] <> 0));
      if (xx > 1) then
        if ((position[xx - 1, yy] = 2) or (position[xx - 1, yy] = 3)) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if ((xx > 1) and (yy > 1)) then if (position[xx - 1, yy - 1] = 0) then begin
            xx := xx - 1; yy := yy - 1;
          end;
      until ((xx = 1) or (yy = 1) or (position[xx - 1, yy - 1] <> 0));
      if ((xx > 1) and (yy > 1)) then
        if ((position[xx - 1, yy - 1] = 2) or (position[xx - 1, yy - 1] = 4)) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if ((xx > 1) and (yy < ranks)) then if (position[xx - 1, yy + 1] = 0) then begin
            xx := xx - 1; yy := yy + 1;
          end;
      until ((xx = 1) or (yy = ranks) or (position[xx - 1, yy + 1] <> 0));
      if ((xx > 1) and (yy < ranks)) then
        if ((position[xx - 1, yy + 1] = 2) or (position[xx - 1, yy + 1] = 4)) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if ((xx < files) and (yy > 1)) then if (position[xx + 1, yy - 1] = 0) then begin
            xx := xx + 1; yy := yy - 1;
          end;
      until ((xx = files) or (yy = 1) or (position[xx + 1, yy - 1] <> 0));
      if ((xx < files) and (yy > 1)) then
        if ((position[xx + 1, yy - 1] = 2) or (position[xx + 1, yy - 1] = 4)) then goto 111;
      xx := bkx; yy := bky;
      repeat
        if ((xx < files) and (yy < ranks)) then if (position[xx + 1, yy + 1] = 0) then
          begin
            xx := xx + 1; yy := yy + 1;
          end;
      until ((xx = files) or (yy = ranks) or (position[xx + 1, yy + 1] <> 0));
      if ((xx < files) and (yy < ranks)) then
        if ((position[xx + 1, yy + 1] = 2) or (position[xx + 1, yy + 1] = 4)) then goto 111;
    end;
    goto 222;
    111: kingincheck := true;
    222:
  end;

  procedure checkleg(x2, y2: shortint);
  var islegal: boolean;
  begin
    makemove(x2, y2);
    islegal := ((nopossiblechecks) and (abs(moved) > 1));
    if (not islegal) then islegal := (not kingincheck);
    if (islegal) then begin
      if (legals[depth] < maxmoves) then begin
        legals[depth] := legals[depth] + 1;
        legmvs[depth, legals[depth]].file1 := x1;
        legmvs[depth, legals[depth]].rank1 := y1;
        legmvs[depth, legals[depth]].file2 := x2;
        legmvs[depth, legals[depth]].rank2 := y2;
        if (taken = 0) then legmvs[depth, legals[depth]].degree := 3
        else if (abs(taken) < abs(moved)) then
          legmvs[depth, legals[depth]].degree := 1
        else legmvs[depth, legals[depth]].degree := 2;

        if (ep) then legmvs[depth, legals[depth]].degree := 2;
        if ((moved = 6) and (y2 = ranks))
          then legmvs[depth, legals[depth]].degree := 1;
        if ((moved = -6) and (y2 = 1))
          then legmvs[depth, legals[depth]].degree := 1;
      end;
    end;
    unmakemv(x2, y2)
  end;

  procedure blackknight;
  begin
    if ((x1 < files) and (y1 < ranks - 1) and (position[x1 + 1, y1 + 2] > -1))
      then checkleg(x1 + 1, y1 + 2);
    if ((x1 < files) and (y1 > 2) and (position[x1 + 1, y1 - 2] > -1))
      then checkleg(x1 + 1, y1 - 2);
    if ((x1 > 1) and (y1 < ranks - 1) and (position[x1 - 1, y1 + 2] > -1))
      then checkleg(x1 - 1, y1 + 2);
    if ((x1 > 1) and (y1 > 2) and (position[x1 - 1, y1 - 2] > -1))
      then checkleg(x1 - 1, y1 - 2);
    if ((x1 < files - 1) and (y1 < ranks) and (position[x1 + 2, y1 + 1] > -1))
      then checkleg(x1 + 2, y1 + 1);
    if ((x1 < files - 1) and (y1 > 1) and (position[x1 + 2, y1 - 1] > -1))
      then checkleg(x1 + 2, y1 - 1);
    if ((x1 > 2) and (y1 < ranks) and (position[x1 - 2, y1 + 1] > -1))
      then checkleg(x1 - 2, y1 + 1);
    if ((x1 > 2) and (y1 > 1) and (position[x1 - 2, y1 - 1] > -1))
      then checkleg(x1 - 2, y1 - 1);
  end;

  procedure blackking;
  var nhelp: integer;
  begin
    if ((x1 < files) and (y1 < ranks) and (position[x1 + 1, y1 + 1] > -1))
      then checkleg(x1 + 1, y1 + 1);
    if ((x1 < files) and (y1 > 1) and (position[x1 + 1, y1 - 1] > -1))
      then checkleg(x1 + 1, y1 - 1);
    if ((x1 > 1) and (y1 < ranks) and (position[x1 - 1, y1 + 1] > -1))
      then checkleg(x1 - 1, y1 + 1);
    if ((x1 > 1) and (y1 > 1) and (position[x1 - 1, y1 - 1] > -1))
      then checkleg(x1 - 1, y1 - 1);
    nhelp := legals[depth];
    if ((x1 < files) and (position[x1 + 1, y1] > -1))
      then checkleg(x1 + 1, y1);
    if ((x1 = 5) and (y1 = 8) and (legals[depth] > nhelp)) then begin
      if ((not mbk) and (not mbrh) and (position[6, 8] = 0)
        and (position[8, 8] = -3) and
        (position[7, 8] = 0) and (not kingincheck)) then checkleg(x1 + 2, y1)
    end;
    if ((y1 > 1) and (position[x1, y1 - 1] > -1))
      then checkleg(x1, y1 - 1);
    if ((y1 < ranks) and (position[x1, y1 + 1] > -1))
      then checkleg(x1, y1 + 1);
    nhelp := legals[depth];
    if ((x1 > 1) and (position[x1 - 1, y1] > -1))
      then checkleg(x1 - 1, y1);
    if ((x1 = 5) and (y1 = 8) and (legals[depth] > nhelp)) then begin
      if ((not mbk) and (not mbra) and (position[4, 8] = 0) and (position[2, 8] = 0)
        and (position[1, 8] = -3)
        and (position[3, 8] = 0) and (not kingincheck)) then checkleg(x1 - 2, y1)
    end;
  end;

  procedure whiteking;
  var nhelp: integer;
  begin
    if ((x1 < files) and (y1 < ranks) and (position[x1 + 1, y1 + 1] < 1))
      then checkleg(x1 + 1, y1 + 1);
    if ((x1 < files) and (y1 > 1) and (position[x1 + 1, y1 - 1] < 1))
      then checkleg(x1 + 1, y1 - 1);
    if ((x1 > 1) and (y1 < ranks) and (position[x1 - 1, y1 + 1] < 1))
      then checkleg(x1 - 1, y1 + 1);
    if ((x1 > 1) and (y1 > 1) and (position[x1 - 1, y1 - 1] < 1))
      then checkleg(x1 - 1, y1 - 1);
    nhelp := legals[depth];
    if ((x1 < files) and (position[x1 + 1, y1] < 1))
      then checkleg(x1 + 1, y1);
    if ((x1 = 5) and (y1 = 1) and (legals[depth] > nhelp)) then begin
      if ((not mwk) and (not mwrh) and (position[6, 1] = 0)
        and (position[8, 1] = 3) and
        (position[7, 1] = 0) and (not kingincheck)) then checkleg(x1 + 2, y1)
    end;
    if ((y1 > 1) and (position[x1, y1 - 1] < 1))
      then checkleg(x1, y1 - 1);
    if ((y1 < ranks) and (position[x1, y1 + 1] < 1))
      then checkleg(x1, y1 + 1);
    nhelp := legals[depth];
    if ((x1 > 1) and (position[x1 - 1, y1] < 1))
      then checkleg(x1 - 1, y1);
    if ((x1 = 5) and (y1 = 1) and (legals[depth] > nhelp)) then begin
      if ((not mwk) and (not mwra) and (position[4, 1] = 0)
        and (position[1, 1] = 3) and (position[3, 1] = 0)
        and (position[2, 1] = 0) and (not kingincheck)) then checkleg(x1 - 2, y1)
    end;
  end;

  procedure whitepawn;
  begin
    if ((x1 < files) and (y1 < ranks) and (position[x1 + 1, y1 + 1] < 0))
      then checkleg(x1 + 1, y1 + 1);
    if ((x1 > 1) and (y1 < ranks) and (position[x1 - 1, y1 + 1] < 0))
      then checkleg(x1 - 1, y1 + 1);
    if ((y1 < ranks) and (position[x1, y1 + 1] = 0))
      then checkleg(x1, y1 + 1);
    if ((y1 = 2) and (position[x1, 3] = 0) and (position[x1, 4] = 0))
      then checkleg(x1, 4);
    if ((y1 = 5) and (enpassant[depth] = x1 + 1)) then begin
      ep := true;
      checkleg(x1 + 1, 6);
      ep := false
    end;
    if ((y1 = 5) and (enpassant[depth] = x1 - 1)) then begin
      ep := true;
      checkleg(x1 - 1, 6);
      ep := false
    end
  end;

  procedure blackpawn;
  begin
    if ((x1 < files) and (y1 > 1) and (position[x1 + 1, y1 - 1] > 0))
      then checkleg(x1 + 1, y1 - 1);
    if ((x1 > 1) and (y1 > 1) and (position[x1 - 1, y1 - 1] > 0))
      then checkleg(x1 - 1, y1 - 1);
    if ((y1 > 1) and (position[x1, y1 - 1] = 0))
      then checkleg(x1, y1 - 1);
    if ((y1 = 7) and (position[x1, 6] = 0) and (position[x1, 5] = 0))
      then checkleg(x1, 5);
    if ((y1 = 4) and (enpassant[depth] = x1 + 1)) then begin
      ep := true;
      checkleg(x1 + 1, 3);
      ep := false;
    end;
    if ((y1 = 4) and (enpassant[depth] = x1 - 1)) then begin
      ep := true;
      checkleg(x1 - 1, 3);
      ep := false;
    end
  end;

  procedure whiteknight;
  begin
    if ((x1 < files) and (y1 < ranks - 1) and (position[x1 + 1, y1 + 2] < 1))
      then checkleg(x1 + 1, y1 + 2);
    if ((x1 < files) and (y1 > 2) and (position[x1 + 1, y1 - 2] < 1))
      then checkleg(x1 + 1, y1 - 2);
    if ((x1 > 1) and (y1 < ranks - 1) and (position[x1 - 1, y1 + 2] < 1))
      then checkleg(x1 - 1, y1 + 2);
    if ((x1 > 1) and (y1 > 2) and (position[x1 - 1, y1 - 2] < 1))
      then checkleg(x1 - 1, y1 - 2);
    if ((x1 < files - 1) and (y1 < ranks) and (position[x1 + 2, y1 + 1] < 1))
      then checkleg(x1 + 2, y1 + 1);
    if ((x1 < files - 1) and (y1 > 1) and (position[x1 + 2, y1 - 1] < 1))
      then checkleg(x1 + 2, y1 - 1);
    if ((x1 > 2) and (y1 < ranks) and (position[x1 - 2, y1 + 1] < 1))
      then checkleg(x1 - 2, y1 + 1);
    if ((x1 > 2) and (y1 > 1) and (position[x1 - 2, y1 - 1] < 1))
      then checkleg(x1 - 2, y1 - 1);
  end;

  procedure whitequeen;
  var xx, yy: shortint;
  begin
    xx := x1; yy := y1;
    repeat
      if (yy < ranks) then
        if (position[xx, yy + 1] = 0) then begin
          yy := yy + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (position[xx, yy + 1] <> 0));
    if ((yy < ranks) and (position[xx, yy + 1] < 0)) then checkleg(xx, yy + 1);
    xx := x1; yy := y1;
    repeat
      if (yy > 1) then
        if (position[xx, yy - 1] = 0) then begin
          yy := yy - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (position[xx, yy - 1] <> 0));
    if ((yy > 1) and (position[xx, yy - 1] < 0)) then checkleg(xx, yy - 1);
    xx := x1; yy := y1;
    repeat
      if (xx < files) then
        if (position[xx + 1, yy] = 0) then begin
          xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((xx = files) or (position[xx + 1, yy] <> 0));
    if ((xx < files) and (position[xx + 1, yy] < 0)) then checkleg(xx + 1, yy);
    xx := x1; yy := y1;
    repeat
      if (xx > 1) then
        if (position[xx - 1, yy] = 0) then begin
          xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((xx = 1) or (position[xx - 1, yy] <> 0));
    if ((xx > 1) and (position[xx - 1, yy] < 0)) then checkleg(xx - 1, yy);
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx < files)) then
        if (position[xx + 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = files) or (position[xx + 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx < files) and (position[xx + 1, yy + 1] < 0))
      then checkleg(xx + 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx < files)) then
        if (position[xx + 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = files) or (position[xx + 1, yy - 1] <> 0));
    if ((yy > 1) and (xx < files) and (position[xx + 1, yy - 1] < 0))
      then checkleg(xx + 1, yy - 1);
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx > 1)) then
        if (position[xx - 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = 1) or (position[xx - 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx > 1) and (position[xx - 1, yy + 1] < 0))
      then checkleg(xx - 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx > 1)) then
        if (position[xx - 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = 1) or (position[xx - 1, yy - 1] <> 0));
    if ((yy > 1) and (xx > 1) and (position[xx - 1, yy - 1] < 0))
      then checkleg(xx - 1, yy - 1);
  end;

  procedure blackqueen;
  var xx, yy: shortint;
  begin
    xx := x1; yy := y1;
    repeat
      if (yy < ranks) then
        if (position[xx, yy + 1] = 0) then begin
          yy := yy + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (position[xx, yy + 1] <> 0));
    if ((yy < ranks) and (position[xx, yy + 1] > 0)) then checkleg(xx, yy + 1);
    xx := x1; yy := y1;
    repeat
      if (yy > 1) then
        if (position[xx, yy - 1] = 0) then begin
          yy := yy - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (position[xx, yy - 1] <> 0));
    if ((yy > 1) and (position[xx, yy - 1] > 0)) then checkleg(xx, yy - 1);
    xx := x1; yy := y1;
    repeat
      if (xx < files) then
        if (position[xx + 1, yy] = 0) then begin
          xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((xx = files) or (position[xx + 1, yy] <> 0));
    if ((xx < files) and (position[xx + 1, yy] > 0)) then checkleg(xx + 1, yy);
    xx := x1; yy := y1;
    repeat
      if (xx > 1) then
        if (position[xx - 1, yy] = 0) then begin
          xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((xx = 1) or (position[xx - 1, yy] <> 0));
    if ((xx > 1) and (position[xx - 1, yy] > 0)) then checkleg(xx - 1, yy);
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx < files)) then
        if (position[xx + 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = files) or (position[xx + 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx < files) and (position[xx + 1, yy + 1] > 0))
      then checkleg(xx + 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx < files)) then
        if (position[xx + 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = files) or (position[xx + 1, yy - 1] <> 0));
    if ((yy > 1) and (xx < files) and (position[xx + 1, yy - 1] > 0))
      then checkleg(xx + 1, yy - 1);
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx > 1)) then
        if (position[xx - 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = 1) or (position[xx - 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx > 1) and (position[xx - 1, yy + 1] > 0))
      then checkleg(xx - 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx > 1)) then
        if (position[xx - 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = 1) or (position[xx - 1, yy - 1] <> 0));
    if ((yy > 1) and (xx > 1) and (position[xx - 1, yy - 1] > 0))
      then checkleg(xx - 1, yy - 1);
  end;

  procedure whiterook;
  var xx, yy: shortint;
  begin
    xx := x1; yy := y1;
    repeat
      if (yy < ranks) then
        if (position[xx, yy + 1] = 0) then begin
          yy := yy + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (position[xx, yy + 1] <> 0));
    if ((yy < ranks) and (position[xx, yy + 1] < 0)) then checkleg(xx, yy + 1);
    xx := x1; yy := y1;
    repeat
      if (yy > 1) then
        if (position[xx, yy - 1] = 0) then begin
          yy := yy - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (position[xx, yy - 1] <> 0));
    if ((yy > 1) and (position[xx, yy - 1] < 0)) then checkleg(xx, yy - 1);
    xx := x1; yy := y1;
    repeat
      if (xx < files) then
        if (position[xx + 1, yy] = 0) then begin
          xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((xx = files) or (position[xx + 1, yy] <> 0));
    if ((xx < files) and (position[xx + 1, yy] < 0)) then checkleg(xx + 1, yy);
    xx := x1; yy := y1;
    repeat
      if (xx > 1) then
        if (position[xx - 1, yy] = 0) then begin
          xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((xx = 1) or (position[xx - 1, yy] <> 0));
    if ((xx > 1) and (position[xx - 1, yy] < 0)) then checkleg(xx - 1, yy);
  end;

  procedure blackrook;
  var xx, yy: shortint;
  begin
    xx := x1; yy := y1;
    repeat
      if (yy < ranks) then
        if (position[xx, yy + 1] = 0) then begin
          yy := yy + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (position[xx, yy + 1] <> 0));
    if ((yy < ranks) and (position[xx, yy + 1] > 0)) then checkleg(xx, yy + 1);
    xx := x1; yy := y1;
    repeat
      if (yy > 1) then
        if (position[xx, yy - 1] = 0) then begin
          yy := yy - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (position[xx, yy - 1] <> 0));
    if ((yy > 1) and (position[xx, yy - 1] > 0)) then checkleg(xx, yy - 1);
    xx := x1; yy := y1;
    repeat
      if (xx < files) then
        if (position[xx + 1, yy] = 0) then begin
          xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((xx = files) or (position[xx + 1, yy] <> 0));
    if ((xx < files) and (position[xx + 1, yy] > 0)) then checkleg(xx + 1, yy);
    xx := x1; yy := y1;
    repeat
      if (xx > 1) then
        if (position[xx - 1, yy] = 0) then begin
          xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((xx = 1) or (position[xx - 1, yy] <> 0));
    if ((xx > 1) and (position[xx - 1, yy] > 0)) then checkleg(xx - 1, yy);
  end;

  procedure whitebishop;
  var xx, yy: shortint;
  begin
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx < files)) then
        if (position[xx + 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = files) or (position[xx + 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx < files) and (position[xx + 1, yy + 1] < 0))
      then checkleg(xx + 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx < files)) then
        if (position[xx + 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = files) or (position[xx + 1, yy - 1] <> 0));
    if ((yy > 1) and (xx < files) and (position[xx + 1, yy - 1] < 0))
      then checkleg(xx + 1, yy - 1);
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx > 1)) then
        if (position[xx - 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = 1) or (position[xx - 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx > 1) and (position[xx - 1, yy + 1] < 0))
      then checkleg(xx - 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx > 1)) then
        if (position[xx - 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = 1) or (position[xx - 1, yy - 1] <> 0));
    if ((yy > 1) and (xx > 1) and (position[xx - 1, yy - 1] < 0))
      then checkleg(xx - 1, yy - 1);
  end;

  procedure blackbishop;
  var xx, yy: shortint;
  begin
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx < files)) then
        if (position[xx + 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = files) or (position[xx + 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx < files) and (position[xx + 1, yy + 1] > 0))
      then checkleg(xx + 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx < files)) then
        if (position[xx + 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx + 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = files) or (position[xx + 1, yy - 1] <> 0));
    if ((yy > 1) and (xx < files) and (position[xx + 1, yy - 1] > 0))
      then checkleg(xx + 1, yy - 1);
    xx := x1; yy := y1;
    repeat
      if ((yy < ranks) and (xx > 1)) then
        if (position[xx - 1, yy + 1] = 0) then begin
          yy := yy + 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = ranks) or (xx = 1) or (position[xx - 1, yy + 1] <> 0));
    if ((yy < ranks) and (xx > 1) and (position[xx - 1, yy + 1] > 0))
      then checkleg(xx - 1, yy + 1);
    xx := x1; yy := y1;
    repeat
      if ((yy > 1) and (xx > 1)) then
        if (position[xx - 1, yy - 1] = 0) then begin
          yy := yy - 1; xx := xx - 1;
          checkleg(xx, yy);
        end;
    until ((yy = 1) or (xx = 1) or (position[xx - 1, yy - 1] <> 0));
    if ((yy > 1) and (xx > 1) and (position[xx - 1, yy - 1] > 0))
      then checkleg(xx - 1, yy - 1);
  end;

begin
  ep := false;
  legals[depth] := 0; incheck := kingincheck;
  if (incheck) then nopossiblechecks := false else begin
    nopossiblechecks := true;
    if (forwhite) then begin
      for x1 := 1 to 8 do if ((position[x1, wky] = -2) or
          (position[x1, wky] = -3)) then nopossiblechecks := false;
      for x1 := 1 to 8 do if ((position[wkx, x1] = -2) or
          (position[wkx, x1] = -3)) then nopossiblechecks := false;
      x1 := wkx; y1 := wky;
      while ((x1 < 8) and (y1 < 8)) do begin
        x1 := x1 + 1; y1 := y1 + 1;
        if ((position[x1, y1] = -2) or
          (position[x1, y1] = -4)) then nopossiblechecks := false;
      end;
      x1 := wkx; y1 := wky;
      while ((x1 > 1) and (y1 < 8)) do begin
        x1 := x1 - 1; y1 := y1 + 1;
        if ((position[x1, y1] = -2) or
          (position[x1, y1] = -4)) then nopossiblechecks := false;
      end;
      x1 := wkx; y1 := wky;
      while ((x1 < 8) and (y1 > 1)) do begin
        x1 := x1 + 1; y1 := y1 - 1;
        if ((position[x1, y1] = -2) or
          (position[x1, y1] = -4)) then nopossiblechecks := false;
      end;
      x1 := wkx; y1 := wky;
      while ((x1 > 1) and (y1 > 1)) do begin
        x1 := x1 - 1; y1 := y1 - 1;
        if ((position[x1, y1] = -2) or
          (position[x1, y1] = -4)) then nopossiblechecks := false;
      end;
    end
    else begin
      for x1 := 1 to 8 do if ((position[x1, bky] = 2) or
          (position[x1, bky] = 3)) then nopossiblechecks := false;
      for x1 := 1 to 8 do if ((position[bkx, x1] = 2) or
          (position[bkx, x1] = 3)) then nopossiblechecks := false;
      x1 := bkx; y1 := bky;
      while ((x1 < 8) and (y1 < 8)) do begin
        x1 := x1 + 1; y1 := y1 + 1;
        if ((position[x1, y1] = 2) or
          (position[x1, y1] = 4)) then nopossiblechecks := false;
      end;
      x1 := bkx; y1 := bky;
      while ((x1 > 1) and (y1 < 8)) do begin
        x1 := x1 - 1; y1 := y1 + 1;
        if ((position[x1, y1] = 2) or
          (position[x1, y1] = 4)) then nopossiblechecks := false;
      end;
      x1 := bkx; y1 := bky;
      while ((x1 < 8) and (y1 > 1)) do begin
        x1 := x1 + 1; y1 := y1 - 1;
        if ((position[x1, y1] = 2) or
          (position[x1, y1] = 4)) then nopossiblechecks := false;
      end;
      x1 := bkx; y1 := bky;
      while ((x1 > 1) and (y1 > 1)) do begin
        x1 := x1 - 1; y1 := y1 - 1;
        if ((position[x1, y1] = 2) or
          (position[x1, y1] = 4)) then nopossiblechecks := false;
      end;
    end
  end;


  if (forwhite) then begin
    for y1 := ranks downto 1 do
      for x1 := 1 to files do
        if (position[x1, y1] = 5) then whiteknight
        else if (position[x1, y1] = 6) then whitepawn
        else if (position[x1, y1] = 1) then whiteking
        else if (position[x1, y1] = 4) then whitebishop
        else if (position[x1, y1] = 2) then whitequeen
        else if (position[x1, y1] = 3) then whiterook
  end
  else begin
    for y1 := 1 to ranks do
      for x1 := 1 to files do
        if (position[x1, y1] = -5) then blackknight
        else if (position[x1, y1] = -6) then blackpawn
        else if (position[x1, y1] = -4) then blackbishop
        else if (position[x1, y1] = -2) then blackqueen
        else if (position[x1, y1] = -3) then blackrook
        else if (position[x1, y1] = -1) then blackking
  end;
  if (legals[depth] = 0) then if (incheck) then legals[depth] := -1
    else legals[depth] := -2;

  positions := positions + 1;
  if (positions > 99) then begin
    positions := 0; kpos := kpos + 1;

    if (kpos mod 25 = 0) then begin
      settextstyle(defaultfont, horizdir, 1);
      setcolor(cblack);
      outtextxy(0, 250, kpstr);
      str(kpos: 1, kpstr);
      kpstr := kpstr + '00 nodes';
      if (viewscores) then begin
        setcolor(cblue);
        outtextxy(0, 250, kpstr);
      end;
      settextstyle(defaultfont, horizdir, 2);
    end;
    if (kpos mod 5 = 0) then begin
      gettime(ho2, mi2, se2, hu2);

      if (se2 < se1) then se2 := se2 + 60;
      sekunnit := sekunnit + 100 * se2 - 100 * se1 + hu2 - hu1;

      gettime(ho1, mi1, se1, hu1);
      if ((sekunnit >= smax) and (searchdepth > 1)) then keskeyta := true;
      if (analysis) then keskeyta := false;

      if (keypressed) then begin
        chi := readkey;
        if (analysis) then keskeyta := true else
          if (chi = ' ') then keskeyta := true
      end
    end
  end;
end;
{*************************************************************************}

function eval_leafs(forwhite: boolean; depth: integer): integer;
label 123;
var ii, store, k, iii, kkk, movevalue, bestvalue: integer;
  moved, taken: shortint;
  found, wq, bq, cutoff, protected: boolean;
begin
  found := false;
  if (forwhite) then bestvalue := -30000 else
    bestvalue := 30000;
  ii := 1;
  repeat
    if (legmvs[depth, ii].degree = 3) then found := true;
    ii := ii + 1;
  until ((found) or (ii > legals[depth]));
  if (found) then bestvalue := posvalue;
  if (depth = 2) then begin
    if (forwhite) then beta[depth] := -30000 else
      beta[depth] := 30000
  end
  else beta[depth] := beta[depth - 2];
  cutoff := false;
  for iii := 1 to 2 do
    for kkk := 1 to legals[depth] do
      if (legmvs[depth, kkk].degree = iii) then begin
        store := posvalue;
        taken := position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2];
        moved := position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1];
        if (taken = -6) then posvalue := posvalue + 96 else
          if (taken = 6) then posvalue := posvalue - 96 else
            if (taken = -3) then posvalue := posvalue + 496 else
              if (taken = 3) then posvalue := posvalue - 496 else
                if (taken = -4) then posvalue := posvalue + 306 else
                  if (taken = 4) then posvalue := posvalue - 306 else
                    if (taken = -5) then posvalue := posvalue + 296 else
                      if (taken = 5) then posvalue := posvalue - 296 else
                        if (taken = -2) then posvalue := posvalue + 896 else
                          if (taken = 2) then posvalue := posvalue - 896;

        if ((moved = 6) and (legmvs[depth, kkk].rank2 = ranks))
          then posvalue := posvalue + 720;
        if ((moved = -6) and (legmvs[depth, kkk].rank2 = 1))
          then posvalue := posvalue - 720;
        if ((moved = 6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := 0;
          posvalue := posvalue + 96;
        end;
        if ((moved = -6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := 0;
          posvalue := posvalue - 96;
        end;

        position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1] := 0;
        position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := moved;
        if (moved = 1) then begin
          wkx := legmvs[depth, kkk].file2; wky := legmvs[depth, kkk].rank2
        end;
        if (moved = -1) then begin
          bkx := legmvs[depth, kkk].file2; bky := legmvs[depth, kkk].rank2
        end;
        wq := false; bq := false;
        enpassant[depth + 1] := 100;
        if ((moved = 6) and (legmvs[depth, kkk].rank2 = ranks)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := 2;
          wq := true
        end;
        if ((moved = -6) and (legmvs[depth, kkk].rank2 = 1)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := -2;
          bq := true
        end;
        searchlegmvs(not forwhite, depth + 1);

        protected := false; k := 1;
        repeat
          if ((legmvs[depth + 1, k].file2 = legmvs[depth, kkk].file2) and
            (legmvs[depth + 1, k].rank2 = legmvs[depth, kkk].rank2))
            then protected := true;
          k := k + 1;
        until ((k > legals[depth + 1]) or (protected));
        if protected then
          if (wq) then posvalue := posvalue - 800 else
            if (bq) then posvalue := posvalue + 800 else
              if (moved = 2) then posvalue := posvalue - 895 else
                if (moved = 3) then posvalue := posvalue - 495 else
                  if (moved = 4) then posvalue := posvalue - 305 else
                    if (moved = 5) then posvalue := posvalue - 295 else
                      if (moved = 6) then posvalue := posvalue - 95 else
                        if (moved = -2) then posvalue := posvalue + 895 else
                          if (moved = -3) then posvalue := posvalue + 495 else
                            if (moved = -4) then posvalue := posvalue + 305 else
                              if (moved = -5) then posvalue := posvalue + 295 else
                                if (moved = -6) then posvalue := posvalue + 95;
        if (legals[depth + 1] = -2) then posvalue := 0;
        if (legals[depth + 1] = -1) then begin
          if (forwhite) then posvalue := 10001 - depth
          else posvalue := depth - 10001;
        end;
        movevalue := posvalue;
        position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1] := moved;
        position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := taken;
        if ((moved = 6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := -6
        end;
        if ((moved = -6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := 6
        end;
        if (moved = 1) then begin
          wkx := legmvs[depth, kkk].file1; wky := legmvs[depth, kkk].rank1
        end;
        if (moved = -1) then begin
          bkx := legmvs[depth, kkk].file1; bky := legmvs[depth, kkk].rank1
        end;

        if ((forwhite) and (movevalue > bestvalue)) then bestvalue := movevalue;
        if ((not forwhite) and (movevalue < bestvalue)) then bestvalue := movevalue;

        if ((forwhite) and (bestvalue >= beta[depth - 1])) then cutoff := true;
        if ((not forwhite) and (bestvalue <= beta[depth - 1])) then cutoff := true;
        if ((forwhite) and (bestvalue > beta[depth]))
          then beta[depth] := bestvalue;
        if ((not forwhite) and (bestvalue < beta[depth]))
          then beta[depth] := bestvalue;
        posvalue := store;
        if (cutoff) then begin
          killer2[depth] := killer[depth];
          killer[depth] := legmvs[depth, kkk]
        end;
        if ((cutoff) or (keskeyta)) then goto 123;
      end;
  123: eval_leafs := bestvalue;
end;
{*************************************************************************}

function evaluate(forwhite: boolean; depth, plusd, silent: integer): integer;
var store, iii, kkk, movevalue, bestvalue, silentm: integer;
  moved, taken: shortint; helpmv: movetype;
  cutoff, found: boolean;
begin
  if (depth = 2) then begin
    if (forwhite) then beta[depth] := -30000 else
      beta[depth] := 30000
  end
  else beta[depth] := beta[depth - 2];

  if ((legals[depth] < 2) and
    (searchdepth + plusd + 2 < maxdepth)) then plusd := plusd + 1;

  if ((depth >= searchdepth) and (silent < searchdepth div 4) and (plusd < 2))
    then plusd := plusd + 1;
  silentm := silent;

  if ((depth = 2) and (searchdepth > 2) and (legals[2] > 2)) then begin
    found := false;
    kkk := 0;
    repeat
      kkk := kkk + 1;
      if ((legmvs[depth, kkk].file1 = best2[mcount].file1) and
        (legmvs[depth, kkk].file2 = best2[mcount].file2) and
        (legmvs[depth, kkk].rank1 = best2[mcount].rank1) and
        (legmvs[depth, kkk].rank2 = best2[mcount].rank2)) then begin
        found := true;
        helpmv := legmvs[depth, 1];
        legmvs[depth, 1] := legmvs[depth, kkk];
        legmvs[depth, kkk] := helpmv;
        legmvs[depth, 1].degree := 1
      end
    until ((found) or (kkk = legals[depth]));
  end;
  if (((depth = 2) and (searchdepth = 2) and (legals[2] > 2))
    or ((depth > 2) and (legals[depth] > 2))) then begin
    found := false;
    kkk := 1;
    repeat
      kkk := kkk + 1;
      if ((legmvs[depth, kkk].file1 = killer[depth].file1) and
        (legmvs[depth, kkk].file2 = killer[depth].file2) and
        (legmvs[depth, kkk].rank1 = killer[depth].rank1) and
        (legmvs[depth, kkk].rank2 = killer[depth].rank2)) then begin
        found := true;
        helpmv := legmvs[depth, 1];
        legmvs[depth, 1] := legmvs[depth, kkk];
        legmvs[depth, kkk] := helpmv;
        legmvs[depth, 1].degree := 1
      end
    until ((found) or (kkk = legals[depth]));
  end;
  if (legals[depth] > 3) then begin
    found := false;
    kkk := 2;
    repeat
      kkk := kkk + 1;
      if ((legmvs[depth, kkk].file1 = killer2[depth].file1) and
        (legmvs[depth, kkk].file2 = killer2[depth].file2) and
        (legmvs[depth, kkk].rank1 = killer2[depth].rank1) and
        (legmvs[depth, kkk].rank2 = killer2[depth].rank2)) then begin
        found := true;
        helpmv := legmvs[depth, 2];
        legmvs[depth, 2] := legmvs[depth, kkk];
        legmvs[depth, kkk] := helpmv;
        legmvs[depth, 2].degree := 1
      end
    until ((found) or (kkk = legals[depth]));
  end;



  cutoff := false;
  if (forwhite) then bestvalue := -30000 else
    bestvalue := 30000;

  III := 0;
  repeat
    iii := iii + 1;
    kkk := 0;
    repeat
      kkk := kkk + 1;
      if (legmvs[depth, kkk].degree = iii) then begin
        store := posvalue;

        taken := position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2];
        moved := position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1];
        if (taken = -6) then posvalue := posvalue + 101 + bonus - 5 * depth else
          if (taken = 6) then posvalue := posvalue - 101 + bonus + 5 * depth else
            if (taken = -3) then posvalue := posvalue + 498 + bonus else
              if (taken = 3) then posvalue := posvalue - 498 + bonus else
                if (taken = -4) then posvalue := posvalue + 308 + bonus else
                  if (taken = 4) then posvalue := posvalue - 308 + bonus else
                    if (taken = -5) then posvalue := posvalue + 298 + bonus else
                      if (taken = 5) then posvalue := posvalue - 298 + bonus else
                        if (taken = -2) then posvalue := posvalue + 898 + bonus else
                          if (taken = 2) then posvalue := posvalue - 898 + bonus;

        if (taken = 0) then silent := silentm + 1 else silent := silentm;
        if ((moved = 6) and (legmvs[depth, kkk].rank2 = ranks))
          then begin
          posvalue := posvalue + 790;
          silent := silentm
        end;
        if ((moved = -6) and (legmvs[depth, kkk].rank2 = 1))
          then begin
          posvalue := posvalue - 790;
          silent := silentm
        end;
        if ((moved = 6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := 0;
          posvalue := posvalue + 98 + bonus;
          silent := silentm
        end;
        if ((moved = -6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := 0;
          posvalue := posvalue - 98 + bonus;
          silent := silentm
        end;

{*************************}
        if (forwhite) then begin
          if ((depth < 4) and ((moved = 4) or (moved = 5)) and
            (legmvs[depth, kkk].rank1 = 1)) then posvalue := posvalue + 7;
          if ((moved = 6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1))
            then begin
            if (position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] = 6)
              then posvalue := posvalue - 30;
            if (position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1 + 1] = 6)
              then posvalue := posvalue + 30;
            if (position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1 - 1] = 6)
              then posvalue := posvalue + 30;
          end;
          if ((moved = 1) and (wmat = 0)) then begin
            if ((wkx < 5) and (wky < 5)) then begin
              posvalue := posvalue + 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue + 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
            if ((wkx > 4) and (wky < 5)) then begin
              posvalue := posvalue - 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue + 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
            if ((wkx < 5) and (wky > 4)) then begin
              posvalue := posvalue + 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue - 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
            if ((wkx > 4) and (wky > 4)) then begin
              posvalue := posvalue - 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue - 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
          end;

        end
        else begin
          if ((depth < 4) and ((moved = -4) or (moved = -5)) and
            (legmvs[depth, kkk].rank1 = 8)) then posvalue := posvalue - 7;
          if ((moved = -6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1))
            then begin
            if (position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] = -6)
              then posvalue := posvalue + 30;
            if (position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1 + 1] = -6)
              then posvalue := posvalue - 30;
            if (position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1 - 1] = -6)
              then posvalue := posvalue - 30;
          end;
          if ((moved = -1) and (bmat = 0)) then begin
            if ((bkx < 5) and (bky < 5)) then begin
              posvalue := posvalue - 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue - 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
            if ((bkx > 4) and (bky < 5)) then begin
              posvalue := posvalue + 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue - 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
            if ((bkx < 5) and (bky > 4)) then begin
              posvalue := posvalue - 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue + 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
            if ((bkx > 4) and (bky > 4)) then begin
              posvalue := posvalue + 20 * (legmvs[depth, kkk].file2 - legmvs[depth, kkk].file1);
              posvalue := posvalue + 20 * (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1);
            end;
          end;

        end;
{*************************}



        position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1] := 0;
        position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := moved;
        if (moved = 1) and (legmvs[depth, kkk].file2 = wkx + 2) then begin
          position[8, 1] := 0; position[6, 1] := 3; posvalue := posvalue + 20;
        end;
        if (moved = 1) and (legmvs[depth, kkk].file2 = wkx - 2) then begin
          position[1, 1] := 0; position[4, 1] := 3; posvalue := posvalue + 20;
        end;
        if (moved = -1) and (legmvs[depth, kkk].file2 = bkx + 2) then begin
          position[8, 8] := 0; position[6, 8] := -3; posvalue := posvalue - 20;
        end;
        if (moved = -1) and (legmvs[depth, kkk].file2 = bkx - 2) then begin
          position[1, 8] := 0; position[4, 8] := -3; posvalue := posvalue - 20;
        end;
        if (moved = 1) then begin
          wkx := legmvs[depth, kkk].file2; wky := legmvs[depth, kkk].rank2
        end;
        if (moved = -1) then begin
          bkx := legmvs[depth, kkk].file2; bky := legmvs[depth, kkk].rank2
        end;

        enpassant[depth + 1] := 100;
        if ((moved = 6) and (legmvs[depth, kkk].rank2 - legmvs[depth, kkk].rank1 = 2))
          then enpassant[depth + 1] := legmvs[depth, kkk].file1;
        if ((moved = -6) and (legmvs[depth, kkk].rank1 - legmvs[depth, kkk].rank2 = 2))
          then enpassant[depth + 1] := legmvs[depth, kkk].file1;
        if ((moved = 6) and (legmvs[depth, kkk].rank2 = ranks)) then
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := 2;


        if ((moved = -6) and (legmvs[depth, kkk].rank2 = 1)) then
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := -2;

        searchlegmvs(not forwhite, depth + 1);
        if ((depth = 2) or (depth = 4)) then
          if (forwhite) then posvalue := posvalue +
            (legals[depth] div depth) - (legals[depth + 1] div depth)
          else posvalue := posvalue -
            (legals[depth] div depth) + (legals[depth + 1] div depth);

        if (legals[depth + 1] = -2) then posvalue := 0;
        if (legals[depth + 1] = -1) then begin
          if (forwhite) then posvalue := 10001 - depth
          else posvalue := depth - 10001;
        end;
        if ((searchdepth + plusd <= depth) or (legals[depth + 1] < 1)
          or (depth > maxdepth - 3)) then
        begin
          if (legals[depth + 1] < 1) then movevalue := posvalue
          else movevalue := eval_leafs(not forwhite, depth + 1)
        end
        else movevalue := evaluate(not forwhite, depth + 1, plusd, silent);
        if (depth = 2) then begin
          if (forwhite) then begin
            if (movevalue < hyva - 200) then huonoja := huonoja + 1;
            if (movevalue < -9000) then huonoja := huonoja + 2;
          end
          else begin
            if (movevalue > hyva + 200) then huonoja := huonoja + 1;
            if (movevalue > 9000) then huonoja := huonoja + 2;
          end
        end;
        position[legmvs[depth, kkk].file1, legmvs[depth, kkk].rank1] := moved;
        position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank2] := taken;
        if ((moved = 6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := -6
        end;
        if ((moved = -6) and (legmvs[depth, kkk].file2 <> legmvs[depth, kkk].file1)
          and (taken = 0)) then begin
          position[legmvs[depth, kkk].file2, legmvs[depth, kkk].rank1] := 6
        end;
        if (moved = 1) then begin
          wkx := legmvs[depth, kkk].file1; wky := legmvs[depth, kkk].rank1
        end;
        if (moved = -1) then begin
          bkx := legmvs[depth, kkk].file1; bky := legmvs[depth, kkk].rank1
        end;
        if (moved = 1) and (legmvs[depth, kkk].file2 = wkx + 2) then begin
          position[8, 1] := 3; position[6, 1] := 0;
        end;
        if (moved = 1) and (legmvs[depth, kkk].file2 = wkx - 2) then begin
          position[1, 1] := 3; position[4, 1] := 0;
        end;
        if (moved = -1) and (legmvs[depth, kkk].file2 = bkx + 2) then begin
          position[8, 8] := -3; position[6, 8] := 0;
        end;
        if (moved = -1) and (legmvs[depth, kkk].file2 = bkx - 2) then begin
          position[1, 8] := -3; position[4, 8] := 0;
        end;
        if (depth = 2) then begin
          if ((forwhite) and (movevalue > bestvalue))
            then best2[mcount] := legmvs[depth, kkk];
          if ((not forwhite) and (movevalue < bestvalue))
            then best2[mcount] := legmvs[depth, kkk];
        end;


        if ((forwhite) and (movevalue > bestvalue)) then bestvalue := movevalue;
        if ((not forwhite) and (movevalue < bestvalue)) then bestvalue := movevalue;

        if ((forwhite) and (bestvalue >= beta[depth - 1])) then cutoff := true;
        if ((not forwhite) and (bestvalue <= beta[depth - 1])) then cutoff := true;

        if ((forwhite) and (bestvalue > 9000)) then cutoff := true;
        if ((not forwhite) and (bestvalue < -9000)) then cutoff := true;

        if (cutoff) then begin
          killer2[depth] := killer[depth];
          killer[depth] := legmvs[depth, kkk]
        end;

        if ((forwhite) and (bestvalue > beta[depth]))
          then beta[depth] := bestvalue;
        if ((not forwhite) and (bestvalue < beta[depth]))
          then beta[depth] := bestvalue;

        posvalue := store;
      end;
    until ((kkk = legals[depth]) or (cutoff) or (keskeyta));
  until ((iii = 3) or (keskeyta) or (cutoff));
  evaluate := bestvalue;
end;
{*************************************************************************}

procedure compute(forwhite: boolean; var bestmove: movetype; var score: integer;
  seconds: longint);
var best, bscore, tmpsc, ii, jj, iii, jjj, plusd, silent,
  jjh, material, palikat: integer;
  moved, taken: shortint;
  helpmv: movetype; wq, bq: boolean;

begin
  positions := 0; kpos := 0; bigs := 0;
  gettime(ho1, mi1, se1, hu1);
  sekunnit := 0;
  smax := seconds;
  if (smax = 0) then smax := 30;
  setcolor(cblack);
  outtextxy(5, 300, lstr);
  for ii := 1 to 8 do begin
    bpwns[ii] := 0; wpwns[ii] := 0;
  end;
  wmat := 0; bmat := 0;
  setcolor(cblack);
  outtextxy(5, 275, beststr);


  destr := ''; palikat := 0;
  setcolor(clightred);
  outtextxy(0, 360, destr);

  for ii := 1 to ranks do for jj := 1 to files do
      if (position[jj, ii] <> 0) then palikat := palikat + 1;

  for ii := 1 to ranks do for jj := 1 to files do
      if (position[jj, ii] = 2) then wmat := wmat + 900
      else if (position[jj, ii] = 3) then wmat := wmat + 500
      else if (position[jj, ii] = 4) then wmat := wmat + 305
      else if (position[jj, ii] = 5) then wmat := wmat + 295
      else if (position[jj, ii] = 6) then begin
        wmat := wmat + 100;
        wpwns[jj] := wpwns[jj] + 1;
      end

      else if (position[jj, ii] = -2) then bmat := bmat + 900
      else if (position[jj, ii] = -3) then bmat := bmat + 500
      else if (position[jj, ii] = -4) then bmat := bmat + 305
      else if (position[jj, ii] = -5) then bmat := bmat + 295
      else if (position[jj, ii] = 1) then begin
        wkx := jj; wky := ii
      end
      else if (position[jj, ii] = -1) then begin
        bkx := jj; bky := ii
      end
      else if (position[jj, ii] = -6) then begin
        bmat := bmat + 100;
        bpwns[jj] := bpwns[jj] + 1;
      end;
  material := wmat - bmat; hyva := material;
  bonus := (wmat div 25) - (bmat div 25);
  searchlegmvs(forwhite, 1);
  str(legals[1], mstr);
  for ii := 1 to legals[1] do begin
    movescores[ii] := 0;
    bonuses[ii] := random(rrate + 1) - (rrate div 2);
  end;
  stopcalc := false; keskeyta := false;
  opening := (movesmade < 41);
  if (movesmade = viimeksi + 1) then begin
    for ii := 2 to maxdepth - 1 do killer[ii] := killer[ii + 1];
    for ii := 2 to maxdepth - 1 do killer2[ii] := killer2[ii + 1]
  end
  else if (movesmade = viimeksi + 2) then begin
    for ii := 2 to maxdepth - 2 do killer[ii] := killer[ii + 2];
    for ii := 2 to maxdepth - 2 do killer2[ii] := killer2[ii + 2]
  end;
  viimeksi := movesmade;
  searchdepth := 1;
  iii := 1;
  if (forwhite) then beta[1] := -30000 else
    beta[1] := 30000;
  bscore := beta[1];
  repeat
    mcount := iii; huonoja := 0;

    posvalue := material + bonuses[iii];
    if (searchdepth > 2) then begin
      setcolor(cblack);
      settextstyle(defaultfont, horizdir, 1);
      outtextxy(5, 262, cstr);
      settextstyle(defaultfont, horizdir, 2);
      if (viewscores) then begin
        settextstyle(defaultfont, horizdir, 1);
        str(mcount, cstr);
        cstr := cstr + '/' + mstr + ' ' + chr(legmvs[1, iii].file1 + 96) +
          chr(legmvs[1, iii].rank1 + 48) +
          chr(legmvs[1, iii].file2 + 96) +
          chr(legmvs[1, iii].rank2 + 48);
        setcolor(cblue);
        outtextxy(5, 262, cstr);
        settextstyle(defaultfont, horizdir, 2);
      end
    end;
    if (abs(movescores[iii]) < 9000) then begin
      taken := position[legmvs[1, iii].file2, legmvs[1, iii].rank2];
      moved := position[legmvs[1, iii].file1, legmvs[1, iii].rank1];
      if (forwhite) then begin
        for jjh := 1 to 8 do if (moved = lmoved[jjh]) then posvalue := posvalue - 4;
        if (moved = 1) then begin
          if (bmat = 0) then begin
            if (abs(legmvs[1, iii].file2 - bkx) < abs(legmvs[1, iii].file1 - bkx))
              then posvalue := posvalue + 3;
            if (abs(legmvs[1, iii].rank2 - bky) < abs(legmvs[1, iii].rank1 - bky))
              then posvalue := posvalue + 3;
            if (abs(legmvs[1, iii].file2 - bkx) > abs(legmvs[1, iii].file1 - bkx))
              then posvalue := posvalue - 3;
            if (abs(legmvs[1, iii].rank2 - bky) > abs(legmvs[1, iii].rank1 - bky))
              then posvalue := posvalue - 3;

          end
          else if ((wmat < 400) or (bmat < 1400)) then begin
            if ((legmvs[1, iii].file1 = 8) and (legmvs[1, iii].file2 = 7))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].file1 = 7) and (legmvs[1, iii].file2 = 6))
              then posvalue := posvalue + 4;
            if ((legmvs[1, iii].file1 = 1) and (legmvs[1, iii].file2 = 2))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].file1 = 2) and (legmvs[1, iii].file2 = 3))
              then posvalue := posvalue + 4;
            if ((legmvs[1, iii].rank1 = 8) and (legmvs[1, iii].rank2 = 7))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].rank1 = 7) and (legmvs[1, iii].rank2 = 6))
              then posvalue := posvalue + 4;
            if ((legmvs[1, iii].rank1 = 1) and (legmvs[1, iii].rank2 = 2))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].rank1 = 2) and (legmvs[1, iii].rank2 = 3))
              then posvalue := posvalue + 4;
            if ((legmvs[1, iii].file1 = 6) and (legmvs[1, iii].file2 = 7))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].file1 = 7) and (legmvs[1, iii].file2 = 8))
              then posvalue := posvalue - 6;
            if ((legmvs[1, iii].file1 = 3) and (legmvs[1, iii].file2 = 2))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].file1 = 2) and (legmvs[1, iii].file2 = 1))
              then posvalue := posvalue - 6;
            if ((legmvs[1, iii].rank1 = 6) and (legmvs[1, iii].rank2 = 7))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].rank1 = 7) and (legmvs[1, iii].rank2 = 8))
              then posvalue := posvalue - 6;
            if ((legmvs[1, iii].rank1 = 3) and (legmvs[1, iii].rank2 = 2))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].rank1 = 2) and (legmvs[1, iii].rank2 = 1))
              then posvalue := posvalue - 6;
          end
        end;
        if ((moved = 6) and (legmvs[1, iii].file2 > 5)) then begin
          if ((wkx < 5) and (wky < 3) and (bkx > 5) and (bky > 6))
            then begin
            posvalue := posvalue + 12;
            if (legmvs[1, iii].rank2 = legmvs[1, iii].rank1 + 2)
              then posvalue := posvalue + 5;
          end
        end;
        if ((moved = 6) and (legmvs[1, iii].file2 < 4)) then begin
          if ((wkx > 5) and (wky < 3) and (bkx < 5) and (bky > 6))
            then begin
            posvalue := posvalue + 12;
            if (legmvs[1, iii].rank2 = legmvs[1, iii].rank1 + 2)
              then posvalue := posvalue + 5;
          end
        end;
        if ((moved = 1) and (wmat = 0)) then begin
          if ((wkx < 5) and (wky < 5)) then begin
            posvalue := posvalue + 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue + 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
          if ((wkx > 4) and (wky < 5)) then begin
            posvalue := posvalue - 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue + 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
          if ((wkx < 5) and (wky > 4)) then begin
            posvalue := posvalue + 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue - 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
          if ((wkx > 4) and (wky > 4)) then begin
            posvalue := posvalue - 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue - 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
        end;

        if ((moved = 4) or (moved = 5)) then begin
          if (legmvs[1, iii].rank1 > legmvs[1, iii].rank2) then posvalue := posvalue - 10;
          posvalue := posvalue - abs(legmvs[1, iii].rank2 - 5)
            - abs(legmvs[1, iii].file2 - 5) + abs(legmvs[1, iii].rank1 - 5)
            + abs(legmvs[1, iii].file1 - 5);
          if ((legmvs[1, iii].file2 = 8) or (legmvs[1, iii].file2 = 1))
            then posvalue := posvalue - 8
        end;

        if (moved = 1) then begin
          if ((legmvs[1, iii].rank1 = 1) and (legmvs[1, iii].rank2 = 1)
            and (legmvs[1, iii].file2 > 6)) then posvalue := posvalue - 21;
        end;
        if ((moved = 3) and (legmvs[1, iii].rank1 = 1) and (legmvs[1, iii].rank2 = 1))
          then begin
          posvalue := posvalue - 2;
          if (legmvs[1, iii].file1 = 4) then posvalue := posvalue - 3;
          if (legmvs[1, iii].file1 = 5) then posvalue := posvalue - 3;
          if (legmvs[1, iii].file2 = 4) then posvalue := posvalue + 4;
          if (legmvs[1, iii].file2 = 5) then posvalue := posvalue + 4;
        end;
        if (((moved = 4) or (moved = 5)) and (legmvs[1, iii].rank1 = 1)) then
          posvalue := posvalue + 7;
        if ((moved = 3) and (legmvs[1, iii].rank2 = 7)) then
          posvalue := posvalue + 7;
        if (opening) then begin
          if ((moved = 1) and (abs(legmvs[1, iii].file1 - legmvs[1, iii].file2) = 2))
            then posvalue := posvalue + 30;

          if ((moved = 3) and ((legmvs[1, iii].file1 = 1) or
            (legmvs[1, iii].file1 = 8))) then posvalue := posvalue - 25;
          if ((moved = 6) and (legmvs[1, iii].rank1 = 2) and
            (legmvs[1, iii].rank2 = 4) and ((legmvs[1, iii].file1 < 3) or
            (legmvs[1, iii].file1 > 6))) then posvalue := posvalue - 16;
          if ((moved = 6) and (legmvs[1, iii].rank1 = 2) and
            ((legmvs[1, iii].file1 = 5) or (legmvs[1, iii].file1 = 4))) then begin
            posvalue := posvalue + 20;
            if (legmvs[1, iii].rank2 = 3) then begin
              if ((legmvs[1, iii].file1 = 5) and ((position[3, 1] = 4) or
                (position[4, 2] = 4))) then posvalue := posvalue - 20;
              if ((legmvs[1, iii].file1 = 4) and ((position[6, 1] = 4) or
                (position[5, 2] = 4))) then posvalue := posvalue - 20;
            end
          end;
          if (moved = 1) then posvalue := posvalue - 20;
          if (moved = 2) then posvalue := posvalue - 4;
          if (moved = 5) then posvalue := posvalue - 4;
          if ((moved = 4) and (legmvs[1, iii].rank2 = 3) and
            ((legmvs[1, iii].file2 = 4) or (legmvs[1, iii].file2 = 5)) and
            (position[legmvs[1, iii].file2, 2] = 6)) then posvalue := posvalue - 50;

          if ((moved = 5) and ((legmvs[1, iii].file2 = 6)
            or (legmvs[1, iii].file2 = 3))) then posvalue := posvalue + 15;
          if ((moved = 4) and (legmvs[1, iii].rank2 = 4) and
            (legmvs[1, iii].rank1 = 1)) then posvalue := posvalue + 9;
          if ((moved = 6) and (position[3, 1] = 4)
            and (legmvs[1, iii].rank1 = 2) and (legmvs[1, iii].file1 = 2)
            and (legmvs[1, iii].rank2 = 3)) then posvalue := posvalue + 10;
          if ((moved = 6) and (position[6, 1] = 4)
            and (legmvs[1, iii].rank1 = 2) and (legmvs[1, iii].file1 = 7)
            and (legmvs[1, iii].rank2 = 3)) then posvalue := posvalue + 10;

          if ((moved = 4) and (legmvs[1, iii].rank2 = 2)
            and ((legmvs[1, iii].file2 = 7) or (legmvs[1, iii].file2 = 2)))
            then posvalue := posvalue + 10;
        end;

        if ((moved = 2) or (moved = 4) or (moved = 5)) then begin
          if (abs(legmvs[1, iii].file2 - bkx) < abs(legmvs[1, iii].file1 - bkx))
            then posvalue := posvalue + 3;
          if (abs(legmvs[1, iii].rank2 - bky) < abs(legmvs[1, iii].rank1 - bky))
            then posvalue := posvalue + 3;
          if (abs(legmvs[1, iii].file2 - bkx) > abs(legmvs[1, iii].file1 - bkx))
            then posvalue := posvalue - 3;
          if (abs(legmvs[1, iii].rank2 - bky) > abs(legmvs[1, iii].rank1 - bky))
            then posvalue := posvalue - 3;
        end;
        if ((moved = 1) and (not mwk)) then posvalue := posvalue - 25;
      end
      else begin
        for jjh := 1 to 8 do if (moved = lmoved[jjh]) then posvalue := posvalue + 4;
        if (moved = -1) then begin
          if (wmat = 0) then begin
            if (abs(legmvs[1, iii].file2 - wkx) < abs(legmvs[1, iii].file1 - wkx))
              then posvalue := posvalue - 2;
            if (abs(legmvs[1, iii].rank2 - wky) < abs(legmvs[1, iii].rank1 - wky))
              then posvalue := posvalue - 2;
            if (abs(legmvs[1, iii].file2 - wkx) > abs(legmvs[1, iii].file1 - wkx))
              then posvalue := posvalue + 2;
            if (abs(legmvs[1, iii].rank2 - wky) > abs(legmvs[1, iii].rank1 - wky))
              then posvalue := posvalue + 2;
          end
          else if ((bmat < 400) or (wmat < 1400)) then begin
            if ((legmvs[1, iii].file1 = 8) and (legmvs[1, iii].file2 = 7))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].file1 = 7) and (legmvs[1, iii].file2 = 6))
              then posvalue := posvalue - 4;
            if ((legmvs[1, iii].file1 = 1) and (legmvs[1, iii].file2 = 2))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].file1 = 2) and (legmvs[1, iii].file2 = 3))
              then posvalue := posvalue - 4;
            if ((legmvs[1, iii].rank1 = 8) and (legmvs[1, iii].rank2 = 7))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].rank1 = 7) and (legmvs[1, iii].rank2 = 6))
              then posvalue := posvalue - 4;
            if ((legmvs[1, iii].rank1 = 1) and (legmvs[1, iii].rank2 = 2))
              then posvalue := posvalue - 5;
            if ((legmvs[1, iii].rank1 = 2) and (legmvs[1, iii].rank2 = 3))
              then posvalue := posvalue - 4;
            if ((legmvs[1, iii].file1 = 6) and (legmvs[1, iii].file2 = 7))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].file1 = 7) and (legmvs[1, iii].file2 = 8))
              then posvalue := posvalue + 6;
            if ((legmvs[1, iii].file1 = 3) and (legmvs[1, iii].file2 = 2))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].file1 = 2) and (legmvs[1, iii].file2 = 1))
              then posvalue := posvalue + 6;
            if ((legmvs[1, iii].rank1 = 6) and (legmvs[1, iii].rank2 = 7))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].rank1 = 7) and (legmvs[1, iii].rank2 = 8))
              then posvalue := posvalue + 6;
            if ((legmvs[1, iii].rank1 = 3) and (legmvs[1, iii].rank2 = 2))
              then posvalue := posvalue + 5;
            if ((legmvs[1, iii].rank1 = 2) and (legmvs[1, iii].rank2 = 1))
              then posvalue := posvalue + 6;
          end
        end;
        if ((moved = -6) and (legmvs[1, iii].file2 > 5)) then begin
          if ((wkx > 5) and (wky < 3) and (bkx < 5) and (bky > 6))
            then begin
            posvalue := posvalue - 12;
            if (legmvs[1, iii].rank2 = legmvs[1, iii].rank1 - 2)
              then posvalue := posvalue - 5;
          end
        end;
        if ((moved = -6) and (legmvs[1, iii].file2 < 4)) then begin
          if ((wkx < 5) and (wky < 3) and (bkx > 5) and (bky > 6))
            then begin
            posvalue := posvalue - 12;
            if (legmvs[1, iii].rank2 = legmvs[1, iii].rank1 - 2)
              then posvalue := posvalue - 5;
          end
        end;

        if ((moved = -1) and (bmat = 0)) then begin
          if ((bkx < 5) and (bky < 5)) then begin
            posvalue := posvalue - 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue - 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
          if ((bkx > 4) and (bky < 5)) then begin
            posvalue := posvalue + 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue - 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
          if ((bkx < 5) and (bky > 4)) then begin
            posvalue := posvalue - 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue + 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
          if ((bkx > 4) and (bky > 4)) then begin
            posvalue := posvalue + 20 * (legmvs[1, iii].file2 - legmvs[1, iii].file1);
            posvalue := posvalue + 20 * (legmvs[1, iii].rank2 - legmvs[1, iii].rank1);
          end;
        end;

        if ((moved = -4) or (moved = -5)) then begin
          if (legmvs[1, iii].rank1 < legmvs[1, iii].rank2) then posvalue := posvalue + 10;
          posvalue := posvalue + abs(legmvs[1, iii].rank2 - 4)
            + abs(legmvs[1, iii].file2 - 5) - abs(legmvs[1, iii].rank1 - 4)
            - abs(legmvs[1, iii].file1 - 5);
          if ((legmvs[1, iii].file2 = 8) or (legmvs[1, iii].file2 = 1))
            then posvalue := posvalue + 8
        end;

        if (moved = -1) then begin
          if ((legmvs[1, iii].rank1 = 8) and (legmvs[1, iii].rank2 = 8)
            and (legmvs[1, iii].file2 > 6)) then posvalue := posvalue + 21;
        end;
        if ((moved = -3) and (legmvs[1, iii].rank1 = 8) and (legmvs[1, iii].rank2 = 8))
          then begin
          posvalue := posvalue + 2;
          if (legmvs[1, iii].file1 = 4) then posvalue := posvalue + 3;
          if (legmvs[1, iii].file1 = 5) then posvalue := posvalue + 3;
          if (legmvs[1, iii].file2 = 4) then posvalue := posvalue - 4;
          if (legmvs[1, iii].file2 = 5) then posvalue := posvalue - 4;
        end;
        if (((moved = -4) or (moved = -5)) and (legmvs[1, iii].rank1 = 8)) then
          posvalue := posvalue - 7;
        if ((moved = -3) and (legmvs[1, iii].rank2 = 2)) then
          posvalue := posvalue - 7;
        if (opening) then begin
          if ((moved = -1) and (abs(legmvs[1, iii].file1 - legmvs[1, iii].file2) = 2))
            then posvalue := posvalue - 30;
          if ((moved = -3) and ((legmvs[1, iii].file1 = 1) or
            (legmvs[1, iii].file1 = 8))) then posvalue := posvalue + 25;
          if ((moved = -6) and (legmvs[1, iii].rank1 = 7) and
            (legmvs[1, iii].rank2 = 5) and ((legmvs[1, iii].file1 < 3) or
            (legmvs[1, iii].file1 > 6))) then posvalue := posvalue + 16;
          if ((moved = -6) and (legmvs[1, iii].rank1 = 7) and
            ((legmvs[1, iii].file1 = 5) or (legmvs[1, iii].file1 = 4))) then begin
            posvalue := posvalue - 20;
            if (legmvs[1, iii].rank2 = 6) then begin
              if ((legmvs[1, iii].file1 = 5) and ((position[3, 8] = -4) or
                (position[4, 7] = -4))) then posvalue := posvalue + 20;
              if ((legmvs[1, iii].file1 = 4) and ((position[6, 8] = -4) or
                (position[5, 7] = -4))) then posvalue := posvalue + 20;
            end
          end;
          if (moved = -1) then posvalue := posvalue + 20;
          if (moved = -2) then posvalue := posvalue + 4;
          if (moved = -5) then posvalue := posvalue + 4;
          if ((moved = -4) and (legmvs[1, iii].rank2 = 6) and
            ((legmvs[1, iii].file2 = 4) or (legmvs[1, iii].file2 = 5)) and
            (position[legmvs[1, iii].file2, 7] = -6)) then posvalue := posvalue + 50;
          if ((moved = -5) and ((legmvs[1, iii].file2 = 6)
            or (legmvs[1, iii].file2 = 3))) then posvalue := posvalue - 15;
          if ((moved = -4) and (legmvs[1, iii].rank2 = 5) and
            (legmvs[1, iii].rank1 = 8)) then posvalue := posvalue - 9;
          if ((moved = -4) and (legmvs[1, iii].rank2 = 7)
            and ((legmvs[1, iii].file2 = 7) or (legmvs[1, iii].file2 = 2)))
            then posvalue := posvalue - 10;
          if ((moved = -6) and (position[3, 8] = -4)
            and (legmvs[1, iii].rank1 = 7) and (legmvs[1, iii].file1 = 2)
            and (legmvs[1, iii].rank2 = 6)) then posvalue := posvalue - 10;
          if ((moved = -6) and (position[6, 8] = -4)
            and (legmvs[1, iii].rank1 = 7) and (legmvs[1, iii].file1 = 7)
            and (legmvs[1, iii].rank2 = 6)) then posvalue := posvalue - 10;
        end;

        if ((moved = -2) or (moved = -4) or (moved = -5)) then begin
          if (abs(legmvs[1, iii].file2 - wkx) < abs(legmvs[1, iii].file1 - wkx))
            then posvalue := posvalue - 2;
          if (abs(legmvs[1, iii].rank2 - wky) < abs(legmvs[1, iii].rank1 - wky))
            then posvalue := posvalue - 2;
          if (abs(legmvs[1, iii].file2 - wkx) > abs(legmvs[1, iii].file1 - wkx))
            then posvalue := posvalue + 2;
          if (abs(legmvs[1, iii].rank2 - wky) > abs(legmvs[1, iii].rank1 - wky))
            then posvalue := posvalue + 2;
        end;
        if ((moved = -1) and (not mbk)) then posvalue := posvalue + 25;
      end;

      if (taken = -6) then posvalue := posvalue + 107 + bonus else
        if (taken = 6) then posvalue := posvalue - 107 + bonus else
          if (taken = -3) then posvalue := posvalue + 500 + bonus else
            if (taken = 3) then posvalue := posvalue - 500 + bonus else
              if (taken = -4) then posvalue := posvalue + 307 + bonus else
                if (taken = 4) then posvalue := posvalue - 307 + bonus else
                  if (taken = -5) then posvalue := posvalue + 299 + bonus else
                    if (taken = 5) then posvalue := posvalue - 299 + bonus else
                      if (taken = -2) then posvalue := posvalue + 900 + bonus else
                        if (taken = 2) then posvalue := posvalue - 900 + bonus;

      if (legmvs[1, iii].degree = 3) then silent := 1 else silent := 0;

      if ((moved = 6) and (legmvs[1, iii].rank2 = ranks)) then begin
        posvalue := posvalue + 800;
        silent := 0;
      end;
      if ((moved = -6) and (legmvs[1, iii].rank2 = 1)) then begin
        posvalue := posvalue - 800;
        silent := 0;
      end;
      if ((moved = 6) and (legmvs[1, iii].file2 <> legmvs[1, iii].file1)
        and (taken = 0)) then begin
        position[legmvs[1, iii].file2, legmvs[1, iii].rank1] := 0;
        silent := 0;
        posvalue := posvalue + 100 + bonus
      end;
      if ((moved = -6) and (legmvs[1, iii].file2 <> legmvs[1, iii].file1)
        and (taken = 0)) then begin
        position[legmvs[1, iii].file2, legmvs[1, iii].rank1] := 0;
        silent := 0;
        posvalue := posvalue - 100 + bonus
      end;
      position[legmvs[1, iii].file1, legmvs[1, iii].rank1] := 0;
      position[legmvs[1, iii].file2, legmvs[1, iii].rank2] := moved;
      if (moved = 1) and (legmvs[1, iii].file2 = wkx + 2) then begin
        position[8, 1] := 0; position[6, 1] := 3; posvalue := posvalue + 70;
        if (wpwns[7] = 0) then posvalue := posvalue - 100;
        if (wpwns[8] = 0) then posvalue := posvalue - 70;
      end;
      if (moved = 1) and (legmvs[1, iii].file2 = wkx - 2) then begin
        position[1, 1] := 0; position[4, 1] := 3; posvalue := posvalue + 70;
        if (wpwns[3] = 0) then posvalue := posvalue - 100;
        if (wpwns[2] = 0) then posvalue := posvalue - 70;
        if (wpwns[1] = 0) then posvalue := posvalue - 70;
      end;
      if ((moved = 6) and (legmvs[1, iii].file2 <> legmvs[1, iii].file1)) then begin
        if (wpwns[legmvs[1, iii].file2] > 0) then posvalue := posvalue - 35;
        if (wpwns[legmvs[1, iii].file1] > 1) then posvalue := posvalue + 35;
      end;
      if ((moved = -6) and (legmvs[1, iii].file2 <> legmvs[1, iii].file1)) then begin
        if (bpwns[legmvs[1, iii].file2] > 0) then posvalue := posvalue + 35;
        if (bpwns[legmvs[1, iii].file1] > 1) then posvalue := posvalue - 35;
      end;
      if (moved = 6) then begin
        if (legmvs[1, iii].file2 = 1) then begin
          jjh := 0;
          for jjj := legmvs[1, iii].rank2 + 1 to 7 do
            if (position[1, jjj] = -6) then jjh := jjh + 1;
          for jjj := legmvs[1, iii].rank2 + 1 to 7 do
            if (position[2, jjj] = -6) then jjh := jjh + 1;
          if (jjh = 0) then posvalue := posvalue + 5 + legmvs[1, iii].rank2 * 3;
        end
        else if (legmvs[1, iii].file2 = 8) then begin
          jjh := 0;
          for jjj := legmvs[1, iii].rank2 + 1 to 7 do
            if (position[8, jjj] = -6) then jjh := jjh + 1;
          for jjj := legmvs[1, iii].rank2 + 1 to 7 do
            if (position[7, jjj] = -6) then jjh := jjh + 1;
          if (jjh = 0) then posvalue := posvalue + 5 + legmvs[1, iii].rank2 * 3
        end
        else begin
          jjh := 0;
          for jjj := legmvs[1, iii].rank2 + 1 to 7 do
            if (position[legmvs[1, iii].file2, jjj] = -6) then jjh := jjh + 1;
          for jjj := legmvs[1, iii].rank2 + 1 to 7 do
            if (position[legmvs[1, iii].file2 + 1, jjj] = -6) then jjh := jjh + 1;
          for jjj := legmvs[1, iii].rank2 + 1 to 7 do
            if (position[legmvs[1, iii].file2 - 1, jjj] = -6) then jjh := jjh + 1;
          if (jjh = 0) then posvalue := posvalue + 5 + legmvs[1, iii].rank2 * 3;
        end;
      end;
      if (moved = -6) then begin
        if (legmvs[1, iii].file2 = 1) then begin
          jjh := 0;
          for jjj := 2 to legmvs[1, iii].rank2 - 1 do
            if (position[1, jjj] = 6) then jjh := jjh + 1;
          for jjj := 2 to legmvs[1, iii].rank2 - 1 do
            if (position[2, jjj] = 6) then jjh := jjh + 1;
          if (jjh = 0) then posvalue := posvalue - 32 + legmvs[1, iii].rank2 * 3
        end
        else if (legmvs[1, iii].file2 = 8) then begin
          jjh := 0;
          for jjj := 2 to legmvs[1, iii].rank2 - 1 do
            if (position[8, jjj] = 6) then jjh := jjh + 1;
          for jjj := 2 to legmvs[1, iii].rank2 - 1 do
            if (position[7, jjj] = 6) then jjh := jjh + 1;
          if (jjh = 0) then posvalue := posvalue - 32 + legmvs[1, iii].rank2 * 3
        end
        else begin
          jjh := 0;
          for jjj := 2 to legmvs[1, iii].rank2 - 1 do
            if (position[legmvs[1, iii].file2, jjj] = 6) then jjh := jjh + 1;
          for jjj := 2 to legmvs[1, iii].rank2 - 1 do
            if (position[legmvs[1, iii].file2 + 1, jjj] = 6) then jjh := jjh + 1;
          for jjj := 2 to legmvs[1, iii].rank2 - 1 do
            if (position[legmvs[1, iii].file2 - 1, jjj] = 6) then jjh := jjh + 1;
          if (jjh = 0) then posvalue := posvalue - 32 + legmvs[1, iii].rank2 * 3
        end
      end;
      if (moved = -1) and (legmvs[1, iii].file2 = bkx + 2) then begin
        position[8, 8] := 0; position[6, 8] := -3; posvalue := posvalue - 70;
        if (bpwns[7] = 0) then posvalue := posvalue + 100;
        if (bpwns[8] = 0) then posvalue := posvalue + 70;
      end;
      if (moved = -1) and (legmvs[1, iii].file2 = bkx - 2) then begin
        position[1, 8] := 0; position[4, 8] := -3; posvalue := posvalue - 70;
        if (bpwns[3] = 0) then posvalue := posvalue + 100;
        if (bpwns[2] = 0) then posvalue := posvalue + 70;
        if (bpwns[1] = 0) then posvalue := posvalue + 70;
      end;
      if (moved = 1) then begin
        wkx := legmvs[1, iii].file2; wky := legmvs[1, iii].rank2
      end;
      if (moved = -1) then begin
        bkx := legmvs[1, iii].file2; bky := legmvs[1, iii].rank2
      end;
      enpassant[2] := 100;
      if ((moved = 6) and (legmvs[1, iii].rank2 - legmvs[1, iii].rank1 = 2))
        then enpassant[2] := legmvs[1, iii].file1;
      if ((moved = -6) and (legmvs[1, iii].rank1 - legmvs[1, iii].rank2 = 2))
        then enpassant[2] := legmvs[1, iii].file1;
      wq := false; bq := false;
      if ((moved = 6) and (legmvs[1, iii].rank2 = ranks))
        then begin
        position[legmvs[1, iii].file2, legmvs[1, iii].rank2] := 2;
        wq := true;
      end;
      if ((moved = -6) and (legmvs[1, iii].rank2 = 1))
        then begin
        position[legmvs[1, iii].file2, legmvs[1, iii].rank2] := -2;
        bq := true;
      end;
      searchlegmvs(not forwhite, 2);
      if (legals[2] = -2) then posvalue := 0;
      if (legals[2] = -1) then begin
        if (forwhite) then posvalue := 10000
        else posvalue := -10000;
      end;
      storesc := movescores[iii];
      if (legals[2] = 2) then plusd := 1 else plusd := 0;

      if ((searchdepth = 1) or (legals[2] < 1)) then begin
        if (legals[2] < 1) then movescores[iii] := posvalue
        else movescores[iii] := eval_leafs(not forwhite, 2)
      end
      else movescores[iii] := evaluate(not forwhite, 2, plusd, silent);
      if (keskeyta) then movescores[iii] := storesc;
      if (abs(movescores[iii]) < 9000) then begin
        if (forwhite) then else huonoja := -huonoja;
        movescores[iii] := movescores[iii] + huonoja;
      end;
      if (((forwhite) and (movescores[iii] > bscore)) or
        ((not forwhite) and (movescores[iii] < bscore))) then begin
        bscore := movescores[iii];
        if (forwhite) then beta[1] := bscore - 50 - (700 div searchdepth)
        else beta[1] := bscore + 50 + (700 div searchdepth);
        if (viewscores) then begin
          setcolor(cblack);
          outtextxy(5, 300, lstr);
          outtextxy(5, 275, beststr);
          str(searchdepth, beststr);
          beststr := chr(legmvs[1, iii].file1 + 96) +
            chr(legmvs[1, iii].rank1 + 48) +
            chr(legmvs[1, iii].file2 + 96) +
            chr(legmvs[1, iii].rank2 + 48) + ' ' + beststr;
          if (forwhite) then str(movescores[iii] * 0.01: 2: 2, lstr)
          else str(-movescores[iii] * 0.01: 2: 2, lstr);
          setcolor(cblue);
          if (legals[1] < 1) then else begin
            outtextxy(5, 300, lstr);
            outtextxy(5, 275, beststr);
          end
        end;
      end;
      position[legmvs[1, iii].file1, legmvs[1, iii].rank1] := moved;
      position[legmvs[1, iii].file2, legmvs[1, iii].rank2] := taken;
      if ((moved = 6) and (legmvs[1, iii].file2 <> legmvs[1, iii].file1)
        and (taken = 0)) then begin
        position[legmvs[1, iii].file2, legmvs[1, iii].rank1] := -6
      end;
      if ((moved = -6) and (legmvs[1, iii].file2 <> legmvs[1, iii].file1)
        and (taken = 0)) then begin
        position[legmvs[1, iii].file2, legmvs[1, iii].rank1] := 6
      end;
      if (moved = 1) then begin
        wkx := legmvs[1, iii].file1; wky := legmvs[1, iii].rank1
      end;
      if (moved = -1) then begin
        bkx := legmvs[1, iii].file1; bky := legmvs[1, iii].rank1
      end;
      if (moved = 1) and (legmvs[1, iii].file2 = wkx + 2) then begin
        position[8, 1] := 3; position[6, 1] := 0;
      end;
      if (moved = 1) and (legmvs[1, iii].file2 = wkx - 2) then begin
        position[1, 1] := 3; position[4, 1] := 0;
      end;
      if (moved = -1) and (legmvs[1, iii].file2 = bkx + 2) then begin
        position[8, 8] := -3; position[6, 8] := 0;
      end;
      if (moved = -1) and (legmvs[1, iii].file2 = bkx - 2) then begin
        position[1, 8] := -3; position[4, 8] := 0;
      end;
      if ((forwhite) and (movescores[iii] > 9000)) then stopcalc := true;
      if ((not forwhite) and (movescores[iii] < -9000)) then stopcalc := true;
    {jos aika niin, stopcalc:=true, jos matti l”yty ni my”s.}
    end;
    iii := iii + 1;

    if (iii > legals[1]) then begin

      for ii := 1 to legals[1] - 1 do
        for jj := ii + 1 to legals[1] do
          if ((forwhite) and (movescores[jj] > movescores[ii])) then begin
            tmpsc := movescores[ii];
            movescores[ii] := movescores[jj];
            movescores[jj] := tmpsc;
            tmpsc := bonuses[ii];
            bonuses[ii] := bonuses[jj];
            bonuses[jj] := tmpsc;
            helpmv := best2[ii];
            best2[ii] := best2[jj];
            best2[jj] := helpmv;
            helpmv := legmvs[1, ii];
            legmvs[1, ii] := legmvs[1, jj];
            legmvs[1, jj] := helpmv
          end
          else if ((not forwhite) and (movescores[jj] < movescores[ii]))
            then begin
            tmpsc := movescores[ii];
            movescores[ii] := movescores[jj];
            movescores[jj] := tmpsc;
            tmpsc := bonuses[ii];
            bonuses[ii] := bonuses[jj];
            bonuses[jj] := tmpsc;
            helpmv := best2[ii];
            best2[ii] := best2[jj];
            best2[jj] := helpmv;
            helpmv := legmvs[1, ii];
            legmvs[1, ii] := legmvs[1, jj];
            legmvs[1, jj] := helpmv
          end;
      if (legals[1] > 2) then
        if (forwhite) then begin
          bonuses[1] := bonuses[1] + 6;
          bonuses[2] := bonuses[2] + 4;
          bonuses[3] := bonuses[3] + 2;
        end else begin
          bonuses[1] := bonuses[1] - 6;
          bonuses[2] := bonuses[2] - 4;
          bonuses[3] := bonuses[3] - 2;
        end;

      settextstyle(defaultfont, horizdir, 2);
      searchdepth := searchdepth + 1;


      if (forwhite) then beta[1] := -30000 else
        beta[1] := 30000;
      bscore := beta[1];

      if (searchdepth > maxdepth - 2) then stopcalc := true;
      if (abs(movescores[1]) > 9000) then stopcalc := true;
      iii := 1
    end;

    if (keskeyta) then stopcalc := true;
    settextstyle(defaultfont, horizdir, 2);

    if ((legals[1] = 1) and (searchdepth > 2) and (not analysis))
      then stopcalc := true;
  until (stopcalc);

  best := 1; bscore := movescores[1];
  for iii := 2 to legals[1] do begin
    if ((forwhite) and (movescores[iii] > bscore))
      then begin
      bscore := movescores[iii];
      best := iii;
    end;
    if ((not forwhite) and (movescores[iii] < bscore))
      then begin
      bscore := movescores[iii];
      best := iii;
    end
  end;

  bestmove := legmvs[1, best];
  score := movescores[best];
  gettime(ho2, mi2, se2, hu2);

  if (se2 < se1) then se2 := se2 + 60;
  sekunnit := sekunnit + 100 * se2 - 100 * se1 + hu2 - hu1;

  if (not forwhite) then score := -score;
  setcolor(cblack);
  outtextxy(5, 275, beststr);
  outtextxy(0, 360, destr);
  outtextxy(5, 300, lstr);
  beststr := chr(legmvs[1, best].file1 + 96) +
    chr(legmvs[1, best].rank1 + 48) +
    chr(legmvs[1, best].file2 + 96) +
    chr(legmvs[1, best].rank2 + 48);


  settextstyle(defaultfont, horizdir, 1);
  setcolor(cblack);
  outtextxy(0, 250, kpstr);
  str(kpos * 100 + positions: 1, kpstr);
  kpstr := kpstr + ' nodes';
  replystr := chr(best2[best].file1 + 96) +
    chr(best2[best].rank1 + 48) +
    chr(best2[best].file2 + 96) +
    chr(best2[best].rank2 + 48);
  if (viewscores) then begin
    setcolor(cblue);
    outtextxy(0, 250, kpstr);
  end;
  settextstyle(defaultfont, horizdir, 2);
  if (viewscores) then begin
    setcolor(cblue);
    if (legals[2] > 0) then
      if (not analysis) then beststr := '..' + replystr;
    if (legals[1] < 1) then beststr := ' ';
    outtextxy(5, 275, beststr);
  end;
  str(score * 0.01: 2: 2, lstr);
  if (score = 10000) then lstr := 'MATE!'
  else if (score > 9900) then begin
    str((10002 - score) div 2, lstr);
    lstr := 'Mate' + lstr
  end
  else if (score < -9900) then begin
    str((10001 + score) div 2, lstr);
    lstr := '-Mate' + lstr
  end;
  if (viewscores) then begin
    setcolor(cblue);
    if (legals[1] < 1) then lstr := ' ';
    outtextxy(5, 300, lstr);
  end;
  settextstyle(defaultfont, horizdir, 1);
  setcolor(cblack);
  outtextxy(5, 262, cstr);
  settextstyle(defaultfont, horizdir, 2);
end;

begin
end.
