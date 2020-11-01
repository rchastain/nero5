
unit pieceset;

interface

uses
  ptcgraph;

procedure draw_white_rook(x, y: integer);
procedure draw_white_king(x, y: integer);
procedure draw_white_queen(x, y: integer);
procedure draw_white_pawn(x, y: integer);
procedure draw_white_knight(x, y: integer);
procedure draw_white_bishop(x, y: integer);
procedure draw_black_rook(x, y: integer);
procedure draw_black_king(x, y: integer);
procedure draw_black_queen(x, y: integer);
procedure draw_black_pawn(x, y: integer);
procedure draw_black_knight(x, y: integer);
procedure draw_black_bishop(x, y: integer);

implementation

{$I colors4}

procedure draw_white_rook(x, y: integer);
begin
  setcolor(cblack);
  moveto(x, y);
  linerel(5, 0); linerel(0, 5); linerel(5, 0); linerel(0, -5); linerel(5, 0);
  linerel(0, 5); linerel(5, 0); linerel(0, -5); linerel(5, 0);
  linerel(0, 8); linerel(-5, 5); linerel(0, 7); linerel(2, 5);
  linerel(5, 0); linerel(0, 8); linerel(-30, 0); linerel(0, -8);
  linerel(5, 0); linerel(2, -5); linerel(0, -7); linerel(-5, -5);
  linerel(0, -8); setfillstyle(1, cwhite); floodfill(x + 16, y + 16, cblack);
end;

procedure draw_black_rook(x, y: integer);
begin
  setcolor(cwhite);
  moveto(x, y);
  linerel(5, 0); linerel(0, 5); linerel(5, 0); linerel(0, -5); linerel(5, 0);
  linerel(0, 5); linerel(5, 0); linerel(0, -5); linerel(5, 0); linerel(0, 8);
  linerel(-5, 5); linerel(0, 7); linerel(2, 5); linerel(5, 0); linerel(0, 8);
  linerel(-30, 0); linerel(0, -8); linerel(5, 0); linerel(2, -5); linerel(0, -7);
  linerel(-5, -5); linerel(0, -8); setfillstyle(1, cblack);
  floodfill(x + 16, y + 16, cwhite);
end;

procedure draw_white_king(x, y: integer);
begin
  setcolor(cblack);
  moveto(x, y);
  linerel(0, 28); linerel(30, 0); linerel(0, -28); linerel(-7, 9);
  linerel(-6, -8); linerel(0, -2); linerel(3, 0); linerel(0, -4);
  linerel(-3, 0); linerel(0, -3); linerel(-4, 0); linerel(0, 3);
  linerel(-3, 0); linerel(0, 4); linerel(3, 0); linerel(0, 2);
  linerel(-6, 8); linerel(-7, -9);
  setfillstyle(1, cwhite); floodfill(x + 16, y + 20, cblack);
  circle(x + 3, y + 21, 3);
  circle(x + 9, y + 21, 3);
  circle(x + 15, y + 21, 3);
  circle(x + 21, y + 21, 3);
  circle(x + 27, y + 21, 3);
end;

procedure draw_black_king(x, y: integer);
begin
  setcolor(cwhite);
  moveto(x, y);
  linerel(0, 28); linerel(30, 0); linerel(0, -28); linerel(-7, 9);
  linerel(-6, -8); linerel(0, -2); linerel(3, 0); linerel(0, -4);
  linerel(-3, 0); linerel(0, -3); linerel(-4, 0); linerel(0, 3);
  linerel(-3, 0); linerel(0, 4); linerel(3, 0); linerel(0, 2);
  linerel(-6, 8); linerel(-7, -9); setfillstyle(1, cblack);
  floodfill(x + 16, y + 20, cwhite);
  circle(x + 3, y + 21, 3);
  circle(x + 9, y + 21, 3);
  circle(x + 15, y + 21, 3);
  circle(x + 21, y + 21, 3);
  circle(x + 27, y + 21, 3);
end;

procedure draw_white_queen(x, y: integer);
begin
  setcolor(cblack);
  moveto(x, y);
  linerel(6, 31); linerel(18, 0); linerel(6, -31); linerel(-8, 15);
  linerel(-2, -15); linerel(-5, 15); linerel(-5, -15); linerel(-2, 15);
  linerel(-8, -15); setfillstyle(1, cwhite);
  floodfill(x + 16, y + 20, cblack);
end;

procedure draw_black_queen(x, y: integer);
begin
  setcolor(cwhite);
  moveto(x, y);
  linerel(6, 31); linerel(18, 0); linerel(6, -31); linerel(-8, 15);
  linerel(-2, -15); linerel(-5, 15); linerel(-5, -15); linerel(-2, 15);
  linerel(-8, -15); setfillstyle(1, cblack); floodfill(x + 16, y + 20, cwhite);
end;

procedure draw_white_pawn(x, y: integer);
begin
  setcolor(cblack);
  moveto(x, y);
  linerel(24, 0); linerel(0, -6); linerel(-3, -3);
  linerel(-5, 0); linerel(0, -4); linerel(2, -1); linerel(-3, -2); linerel(4, -3);
  linerel(0, -3); linerel(-1, -3); linerel(-3, -2); linerel(-6, 0); linerel(-3, 2);
  linerel(-1, 3); linerel(0, 3); linerel(4, 3); linerel(-3, 2); linerel(2, 1);
  linerel(0, 4); linerel(-5, 0); linerel(-3, 3); linerel(0, 6);
  setfillstyle(1, cwhite); floodfill(x + 16, y - 6, cblack);
end;

procedure draw_black_pawn(x, y: integer);
begin
  setcolor(cwhite);
  moveto(x, y);
  linerel(24, 0); linerel(0, -6); linerel(-3, -3);
  linerel(-5, 0); linerel(0, -4); linerel(2, -1); linerel(-3, -2); linerel(4, -3);
  linerel(0, -3); linerel(-1, -3); linerel(-3, -2); linerel(-6, 0); linerel(-3, 2);
  linerel(-1, 3); linerel(0, 3); linerel(4, 3); linerel(-3, 2); linerel(2, 1);
  linerel(0, 4); linerel(-5, 0); linerel(-3, 3); linerel(0, 6);
  setfillstyle(1, cblack); floodfill(x + 16, y - 6, cwhite);
end;

procedure draw_white_knight(x, y: integer);
begin
  setcolor(cblack);
  moveto(x, y);
  linerel(23, 0); linerel(0, -7); linerel(-2, 0); linerel(-2, -3);
  linerel(2, -6); linerel(-1, -8); linerel(-6, -7); linerel(-5, -1);
  linerel(-2, -4); linerel(-1, 3); linerel(-5, -2); linerel(1, 5);
  linerel(-2, 2); linerel(-3, 10); linerel(4, 2); linerel(2, -3);
  linerel(4, -3); linerel(0, 1); linerel(-3, 7); linerel(-1, 4);
  linerel(-4, 3); linerel(0, 7); setfillstyle(1, cwhite);
  floodfill(x + 2, y - 2, cblack); floodfill(x + 2, y - 20, cblack);
end;

procedure draw_black_knight(x, y: integer);
begin
  setcolor(cwhite);
  moveto(x, y); linerel(23, 0); linerel(0, -7); linerel(-2, 0);
  linerel(-2, -3); linerel(2, -6); linerel(-1, -8); linerel(-6, -7); linerel(-5, -1);
  linerel(-2, -4); linerel(-1, 3); linerel(-5, -2); linerel(1, 5);
  linerel(-2, 2); linerel(-3, 10); linerel(4, 2); linerel(2, -3);
  linerel(4, -3); linerel(0, 1); linerel(-3, 7); linerel(-1, 4);
  linerel(-4, 3); linerel(0, 7); setfillstyle(1, cblack);
  floodfill(x + 2, y - 2, cwhite); floodfill(x + 2, y - 20, cwhite);
end;

procedure draw_white_bishop(x, y: integer);
begin
  setcolor(cblack);
  moveto(x, y);
  linerel(29, 0); linerel(-1, -6); linerel(-2, -2); linerel(-5, -2);
  linerel(-1, -3); linerel(5, -3); linerel(0, -5); linerel(-8, -8);
  linerel(-2, -5); linerel(-1, 0); linerel(-2, 5); linerel(-8, 8);
  linerel(0, 5); linerel(5, 3); linerel(-1, 3); linerel(-5, 2);
  linerel(-2, 2); linerel(-1, 6); setfillstyle(1, cwhite);
  floodfill(x + 16, y - 6, cblack);
  line(x + 13, y - 18, x + 20, y - 25);
end;

procedure draw_black_bishop(x, y: integer);
begin
  setcolor(cwhite);
  moveto(x, y);
  linerel(29, 0); linerel(-1, -6); linerel(-2, -2); linerel(-5, -2);
  linerel(-1, -3); linerel(5, -3); linerel(0, -5); linerel(-8, -8);
  linerel(-2, -5); linerel(-1, 0); linerel(-2, 5); linerel(-8, 8);
  linerel(0, 5); linerel(5, 3); linerel(-1, 3); linerel(-5, 2);
  linerel(-2, 2); linerel(-1, 6); setfillstyle(1, cblack);
  floodfill(x + 16, y - 6, cwhite);
  line(x + 13, y - 18, x + 20, y - 25);
end;

end.
