Program nero5;

Uses fdelay,crt,dos,bgidriv,graph,pieceset,engine88;

const blines=264;

type bltype=^string;

    savedpostype=Record
                  positio:positiontype;
               mnumber,ep:integer;
      wtomove,wk,bk,wra,bra,wrh,brh:boolean;
      avaus:string;
    End;


Var                                             ch:char;
     previous:savedpostype;
     posf:file of savedpostype;
     cursorx,cursory,cursorc,score,aa,cee,joku,oldmode,
           movenumber,darks,lights,xmargin,ymargin:integer;
                       soundon,gameover,whitesturn,
                 virhe,whiteatbottom,playeriswhite:boolean;
                                          movesecs:longint;
                                              move:movetype;
                                             gamef:text;
                                             ii,jj:shortint;
                             name,templine,avaus,secstr:string;
                          movelist:array[1..24] of string;
                     bookline:array [1..blines] of bltype;

{*************************************************************************}
Procedure set_to_graphics_mode;
Var Gd, Gm : Integer;
begin
  Gd := Detect; InitGraph(Gd, Gm, '');
  if GraphResult <> grOk then Halt(1);
  Setlinestyle(0,0,1);
End;
{*************************************************************************}
Procedure update_movelist(rivi:string);
Var i : Integer;
begin
  settextstyle(defaultfont,horizdir,1);
  setcolor(black);
  for i:=1 to 24 do outtextxy(525,50+15*i,movelist[i]);
  for i:=1 to 23 do movelist[i]:=movelist[i+1];
  movelist[24]:=rivi;
  setcolor(lightgray);
  for i:=1 to 23 do outtextxy(525,50+15*i,movelist[i]);
  setcolor(white);
  outtextxy(525,410,movelist[24]);
  settextstyle(defaultfont,horizdir,2);
End;
{*************************************************************************}
Procedure empty_movelist;
Var i : Integer;
begin
  settextstyle(defaultfont,horizdir,1);
  setcolor(black);
  for i:=1 to 24 do outtextxy(525,50+15*i,movelist[i]);
  for i:=1 to 24 do movelist[i]:=' ';
  settextstyle(defaultfont,horizdir,2);
End;
{*************************************************************************}
Procedure owndelay(hundreths : word);
{ hundreths means hundreths of seconds (value smaller than 100 only used) }
var h,m,s,hos,oldhos:word;
begin
  gettime(h,m,s,hos);
  oldhos:=hos;
  repeat
    gettime(h,m,s,hos);
    if (hos<oldhos) then hos:=hos+100
  until ((hos-oldhos) mod 100>=hundreths)
end;
{*************************************************************************}
procedure Abort(Msg : string);
begin
  Writeln(Msg, ': ', GraphErrorMsg(GraphResult));
  Halt(1);
end;
{*************************************************************************}
procedure draw_board_skeleton;
var i,j,x,y:integer;
BEGIN
  setcolor(white);
  moveto(xmargin,ymargin);
  for i:=1 to files do
  for j:=1 to ranks do begin
    x:=xmargin+50*i;y:=ymargin+50*j;moveto(x,y);
    linerel(-50,0);linerel(0,-50);linerel(50,0);linerel(0,50);
  end;
END;
{*************************************************************************}
procedure drawcursor;
Begin
  setcolor(cursorc);
  moveto(xmargin+cursorx*50-2,480-ymargin-cursory*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+cursorx*50-1,480-ymargin-cursory*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+cursorx*50-3,480-ymargin-cursory*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
End;
{*************************************************************************}
procedure drawmark;
Begin
  setcolor(lightred);
  moveto(xmargin+cursorx*50-4,480-ymargin-cursory*50+46);
  linerel(0,-42);linerel(-42,0);linerel(0,42);linerel(42,0);
  moveto(xmargin+cursorx*50-5,480-ymargin-cursory*50+45);
  linerel(0,-40);linerel(-40,0);linerel(0,40);linerel(40,0);
  moveto(xmargin+cursorx*50-6,480-ymargin-cursory*50+44);
  linerel(0,-38);linerel(-38,0);linerel(0,38);linerel(38,0);
End;
{*************************************************************************}
procedure delcursor;
Begin
  if ((cursorx+cursory) mod 2=1) then setcolor(lights)
  else setcolor(darks);
  moveto(xmargin+cursorx*50-2,480-ymargin-cursory*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+cursorx*50-1,480-ymargin-cursory*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+cursorx*50-3,480-ymargin-cursory*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
End;
{*************************************************************************}
function promoted:shortint;
var c:char;
Begin
  setcolor(yellow);
  settextstyle(defaultfont,horizdir,2);
  outtextxy(0,85,'SELECT:');
  setcolor(white);
  outtextxy(0,110,'Q/R/');
  outtextxy(0,135,'B/N?');
  repeat
  c:=readkey;
  until (c in ['Q','R','N','B','q','r','n','b']);
  setcolor(black);
  outtextxy(0,85,'SELECT:');
  outtextxy(0,110,'Q/R/');
  outtextxy(0,135,'B/N?');

  if (c in ['Q','q']) then promoted:=2;
  if (c in ['R','r']) then promoted:=3;
  if (c in ['B','b']) then promoted:=4;
  if (c in ['N','n']) then promoted:=5;
End;
{*************************************************************************}
procedure draw_piece(linepos,rowpos,piece:integer);
var y:integer;
BEGIN
  if (whiteatbottom) then rowpos:=ranks+1-rowpos
  else linepos:=files+1-linepos;
  if ((rowpos+linepos) mod 2=1) then setcolor(darks) else setcolor(lights);
  for y:=ymargin+rowpos*50-49 to ymargin+rowpos*50-1 do
  line(xmargin+linepos*50-1,y,xmargin+linepos*50-49,y);
  if (piece=2)
  then draw_white_queen(xmargin+linepos*50-40,ymargin+rowpos*50-40)
  else if (piece=3)
  then draw_white_rook(xmargin+linepos*50-38,ymargin+rowpos*50-40)
  else if (piece=5)
  then draw_white_knight(xmargin+linepos*50-36,ymargin+rowpos*50-8)
  else if (piece=1)
  then draw_white_king(xmargin+linepos*50-40,ymargin+rowpos*50-36)
  else if (piece=4)
  then draw_white_bishop(xmargin+linepos*50-39,ymargin+rowpos*50-8)
  else if (piece=6)
  then draw_white_pawn(xmargin+linepos*50-38,ymargin+rowpos*50-10)
  else if (piece=-5)
  then draw_black_knight(xmargin+linepos*50-36,ymargin+rowpos*50-8)
  else if (piece=-1)
  then draw_black_king(xmargin+linepos*50-40,ymargin+rowpos*50-36)
  else if (piece=-4)
  then draw_black_bishop(xmargin+linepos*50-39,ymargin+rowpos*50-8)
  else if (piece=-6)
  then draw_black_pawn(xmargin+linepos*50-38,ymargin+rowpos*50-10)
  else if (piece=-2)
  then draw_black_queen(xmargin+linepos*50-40,ymargin+rowpos*50-40)
  else if (piece=-3)
  then draw_black_rook(xmargin+linepos*50-38,ymargin+rowpos*50-40)
END;
{*************************************************************************}
procedure setsqc;
var i,j:integer;
begin
  if ((lights=lightgray) and (darks=brown)) then begin
    lights:=lightgray;darks:=darkgray;cursorc:=white;
  end else
  if ((lights=lightgray) and (darks=darkgray)) then begin
    lights:=cyan;darks:=blue;cursorc:=white;
  end else
  if ((lights=cyan) and (darks=blue)) then
   begin
    lights:=yellow;darks:=green;cursorc:=white;
  end else
  if ((lights=yellow) and (darks=green)) then
   begin
    lights:=lightgray;darks:=blue;cursorc:=white;
  end else
  if ((lights=lightgray) and (darks=blue)) then
   begin
    lights:=lightgray;darks:=brown;cursorc:=white;
  end;
  for i:=1 to files do for j:=1 to ranks do
   draw_piece(i,j,position[i,j]);
end;
{*************************************************************************}
procedure turn_board;
var i,j,t:integer;
begin
  whiteatbottom:=(not whiteatbottom);
  if (whiteatbottom) then begin
    settextstyle(defaultfont,horizdir,1);
    setcolor(black);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(ord('i')-i));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(ord('9')-i));
    setcolor(cyan);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(i+ord('a')-1));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(i+ord('0')));
  end
  else begin
    settextstyle(defaultfont,horizdir,1);
    setcolor(black);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(i+ord('a')-1));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(i+ord('0')));
    setcolor(cyan);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(ord('i')-i));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(ord('9')-i));
  end;
      settextstyle(defaultfont,horizdir,2);
  if ((files+ranks) mod 2=1) then begin
  t:=darks;darks:=lights;lights:=t;
  end;
  for i:=1 to files do for j:=1 to ranks do
   draw_piece(i,j,position[i,j]);
   cursorx:=files+1-cursorx;
   cursory:=ranks+1-cursory;
end;
{*************************************************************************}
procedure set_initial_pos(setup:boolean);
label 100,200,300;
var i,j,x,ii,jj:integer;c:char;askep,joo:boolean;
begin
  analysis:=false;
  for i:=1 to 8 do lmoved[i]:=0;
  settextstyle(defaultfont,horizdir,1);
  setcolor(black);
  outtextxy(0,250,kpstr);
  settextstyle(defaultfont,horizdir,2);
  movenumber:=0;
  writeln(gamef,' ');
  writeln(gamef,' ');
  writeln(gamef,'[Event "?"]');
  writeln(gamef,'[Site "?"]');
  writeln(gamef,'[Date "?"]');
  writeln(gamef,'[Round "?"]');
  writeln(gamef,'[Result "?"]');
  writeln(gamef,'[White "?"]');
  writeln(gamef,'[Black "?"]');
  writeln(gamef,' ');
    empty_movelist;
    avaus:='';
if (setup) then begin
    viewscores:=true;
    setcolor(black);avaus:='towerofpowerisagreatband';gameover:=false;
    outtextxy(20,220,' GAME');
    outtextxy(20,250,' OVER');
    outtextxy(0,330,'Your');
    outtextxy(0,360,'move');
    outtextxy(5,300,lstr);
          outtextxy(5,275,beststr);
    lstr:='0.0';
  if (not whiteatbottom) then turn_board;
100:
   for j:=ranks downto 1 do for i:=1 to files do begin
     position[i,j]:=0;
     draw_piece(i,j,position[i,j]);
   end;
   settextstyle(defaultfont,horizdir,1);
   setcolor(white);
   outtextxy(5,70,'Give position');
   outtextxy(5,90,'from a8 to h1');
   setcolor(green);
   outtextxy(5,150,'Black pieces:');
   outtextxy(5,210,'White pieces:');

   outtextxy(5,270,'Empty square:');
   outtextxy(5,325,'Many empty');
   outtextxy(5,345,'squares:');
   outtextxy(5,385,'Random!: F5');
   setcolor(yellow);
   outtextxy(5,385,'         F5');
   outtextxy(5,170,'k,q,r,b,n,p');
   outtextxy(5,230,'K,Q,R,B,N,P');
   outtextxy(5,290,'any other key');
   outtextxy(5,345,'          2-8');
   settextstyle(defaultfont,horizdir,3);
   for j:=ranks downto 1 do for i:=1 to files do begin
     cursorx:=i;cursory:=j;drawcursor;
     setcolor(lightred);
     moveto(xmargin+cursorx*50-33,480-ymargin-cursory*50+14);
     outtext('?');
     if (c<>'?') then
     if (c>'1') and (c<'9') then c:=chr(ord(c)-1)
     else c:=readkey;
     if (c='K') then begin
       wkx:=i;wky:=j;position[i,j]:=1
     end
     else if (c='k') then begin
       bkx:=i;bky:=j;position[i,j]:=-1
     end
     else if (c='Q') then position[i,j]:=2
     else if (c='R') then position[i,j]:=3
     else if (c='B') then position[i,j]:=4
     else if (c='N') then position[i,j]:=5
     else if (c='P') then position[i,j]:=6
     else if (c='q') then position[i,j]:=-2
     else if (c='r') then position[i,j]:=-3
     else if (c='b') then position[i,j]:=-4
     else if (c='n') then position[i,j]:=-5
     else if (c='p') then position[i,j]:=-6
     else if (c='?') then begin
     c:='x';
     for jj:=ranks downto 1 do for ii:=1 to files do
     position[ii,jj]:=0;
     for jj:=1 to 8 do begin
     position[jj,2]:=6;
     position[jj,7]:=-6;
     end;
     jj:=random(4)*2+1;
     position[jj,1]:=4;
     jj:=random(4)*2+2;
     position[jj,1]:=4;
     repeat
     jj:=random(8)+1
     until (position[jj,1]=0);
     position[jj,1]:=1;
     repeat
     jj:=random(8)+1
     until (position[jj,1]=0);
     position[jj,1]:=2;
     repeat
     jj:=random(8)+1
     until (position[jj,1]=0);
     position[jj,1]:=3;
     repeat
     jj:=random(8)+1
     until (position[jj,1]=0);
     position[jj,1]:=3;
     for jj:=1 to 8 do if (position[jj,1]=0) then position[jj,1]:=5;
     for jj:=1 to 8 do position[jj,8]:=-position[jj,1];
     for jj:=ranks downto 1 do for ii:=1 to files do
     draw_piece(ii,jj,position[ii,jj]);
     goto 200;
     end
     else position[i,j]:=0;
     draw_piece(i,j,position[i,j]);
   end;
200:  settextstyle(defaultfont,horizdir,1);
   setcolor(black);
   outtextxy(5,70,'Give position');
   outtextxy(5,90,'from a8 to h1');
   outtextxy(5,150,'Black pieces:');
   outtextxy(5,170,'k,q,r,b,n,p');
   outtextxy(5,210,'White pieces:');
   outtextxy(5,230,'K,Q,R,B,N,P');
   outtextxy(5,270,'Empty square:');
   outtextxy(5,290,'any other key');
   outtextxy(5,325,'Many empty');
   outtextxy(5,345,'squares:  2-8');
   outtextxy(5,385,'Random!: F5');
   if (c='x') then begin
   whitesturn:=true;
   mwk:=(not position[5,1]=1);
   mbk:=mwk;
   mwra:=(not position[1,1]=3);
   mwrh:=(not position[8,1]=3);
   mbra:=mwra;mbrh:=mwrh;
   goto 300;
   end;
   setcolor(yellow);
   outtextxy(5,270,'Side to move');
   outtextxy(5,290,'next (B/W)?');
   repeat
    c:=readkey
   until (c in ['B','b','W','w','?']);
   whitesturn:=(c in ['W','w']);
   if (not whitesturn) then movenumber:=1;
   setcolor(black);
   outtextxy(5,270,'Side to move');
   outtextxy(5,290,'next (B/W)?');
   if (c='?') then goto 100;
   mwra:=true;mbra:=true;mwrh:=true;mbrh:=true;mwk:=true;mbk:=true;
   if ((position[5,1]=1) and ((position[1,1]=3) or (position[8,1]=3)))
   then begin
     setcolor(yellow);
     outtextxy(5,270,'Has white king');
     outtextxy(5,290,'moved (Y/N)?');
     repeat
      c:=readkey
     until (c in ['n','y','N','Y']);
     mwk:=(c in ['Y','y']);
     setcolor(black);
     outtextxy(5,270,'Has white king');
     outtextxy(5,290,'moved (Y/N)?');
     if (not mwk) then begin
       if (position[1,1]=3) then begin
         setcolor(yellow);
         outtextxy(5,270,'Has rook on a1');
         outtextxy(5,290,'moved (Y/N)?');
         repeat
           c:=readkey
         until (c in ['n','y','N','Y']);
         mwra:=(c in ['Y','y']);
         setcolor(black);
         outtextxy(5,270,'Has rook on a1');
         outtextxy(5,290,'moved (Y/N)?');
       end;
       if (position[8,1]=3) then begin
         setcolor(yellow);
         outtextxy(5,270,'Has rook on h1');
         outtextxy(5,290,'moved (Y/N)?');
         repeat
           c:=readkey
         until (c in ['n','y','N','Y']);
         mwrh:=(c in ['Y','y']);
         setcolor(black);
         outtextxy(5,270,'Has rook on h1');
         outtextxy(5,290,'moved (Y/N)?');
       end;
     end;
   end;

   if ((position[5,8]=-1) and ((position[1,8]=-3) or (position[8,8]=-3)))
   then begin
     setcolor(yellow);
     outtextxy(5,270,'Has black king');
     outtextxy(5,290,'moved (Y/N)?');
     repeat
      c:=readkey
     until (c in ['n','y','N','Y']);
     mbk:=(c in ['Y','y']);
     setcolor(black);
     outtextxy(5,270,'Has black king');
     outtextxy(5,290,'moved (Y/N)?');
     if (not mbk) then begin
       if (position[1,8]=-3) then begin
         setcolor(yellow);
         outtextxy(5,270,'Has rook on a8');
         outtextxy(5,290,'moved (Y/N)?');
         repeat
           c:=readkey
         until (c in ['n','y','N','Y']);
         mbra:=(c in ['Y','y']);
         setcolor(black);
         outtextxy(5,270,'Has rook on a8');
         outtextxy(5,290,'moved (Y/N)?');
       end;
       if (position[8,8]=-3) then begin
         setcolor(yellow);
         outtextxy(5,270,'Has rook on h8');
         outtextxy(5,290,'moved (Y/N)?');
         repeat
           c:=readkey
         until (c in ['n','y','N','Y']);
         mbrh:=(c in ['Y','y']);
         setcolor(black);
         outtextxy(5,270,'Has rook on h8');
         outtextxy(5,290,'moved (Y/N)?');
       end;
     end;
   end;

   for i:=1 to maxdepth+1 do enpassant[i]:=100;askep:=false;
   if (whitesturn) then begin
     if ((position[1,5]=6) and (position[2,5]=-6) and
        (position[2,6]=0) and (position[2,7]=0)) then askep:=true;
     if ((position[8,5]=6) and (position[7,5]=-6) and
        (position[7,6]=0) and (position[7,7]=0)) then askep:=true;
     for i:=2 to 7 do begin
     if ((position[i,5]=6) and (position[i+1,5]=-6) and
        (position[i+1,6]=0) and (position[i+1,7]=0)) then askep:=true;
     if ((position[i,5]=6) and (position[i-1,5]=-6) and
        (position[i-1,6]=0) and (position[i-1,7]=0)) then askep:=true;
     end;
   end
   else begin
     if ((position[1,4]=-6) and (position[2,4]=6) and
        (position[2,3]=0) and (position[2,2]=0)) then askep:=true;
     if ((position[8,4]=-6) and (position[7,4]=6) and
        (position[7,3]=0) and (position[7,2]=0)) then askep:=true;
     for i:=2 to 7 do begin
     if ((position[i,4]=-6) and (position[i+1,4]=6) and
        (position[i+1,3]=0) and (position[i+1,2]=0)) then askep:=true;
     if ((position[i,4]=-6) and (position[i-1,4]=6) and
        (position[i-1,2]=0) and (position[i-1,2]=0)) then askep:=true;
     end;
   end;
   if (askep) then begin
     setcolor(yellow);
     outtextxy(5,270,'Is en passant');
     outtextxy(5,290,'allowed (Y/N)');
     repeat
      c:=readkey
     until (c in ['n','y','N','Y']);
     joo:=(c in ['Y','y']);
     if (joo) then begin
     outtextxy(5,320,'To file >');
     repeat
      c:=readkey;
      if ((c>='A') and (c<='H')) then c:=chr(ord(c)-ord('A')+ord('a'));
     until (c in ['a','b','c','d','e','f','g','h']);
     enpassant[1]:=(ord(c)-ord('a')+1);
     end;
     setcolor(black);
     outtextxy(5,320,'To file >');
     outtextxy(5,270,'Is en passant');
     outtextxy(5,290,'allowed (Y/N)');
   end;
300:   settextstyle(defaultfont,horizdir,2);
   movesmade:=0;

  cursorx:=1;cursory:=1;
   if (not whiteatbottom) then begin
     cursorx:=files;cursory:=ranks;
   end;
  playeriswhite:=(whitesturn);
end
else begin

  for i:=1 to files do for j:=1 to ranks do position[i,j]:=0;
  position[1,2]:=6;position[2,2]:=6;position[3,2]:=6;position[4,2]:=6;
  position[5,2]:=6;position[6,2]:=6;position[7,2]:=6;position[8,2]:=6;
  position[1,1]:=3;position[2,1]:=5;position[3,1]:=4;position[4,1]:=2;
  position[5,1]:=1;position[6,1]:=4;position[7,1]:=5;position[8,1]:=3;
  position[1,7]:=-6;position[2,7]:=-6;position[3,7]:=-6;position[4,7]:=-6;
  position[5,7]:=-6;position[6,7]:=-6;position[7,7]:=-6;position[8,7]:=-6;
  position[1,8]:=-3;position[2,8]:=-5;position[3,8]:=-4;position[4,8]:=-2;
  position[5,8]:=-1;position[6,8]:=-4;position[7,8]:=-5;position[8,8]:=-3;
  for i:=1 to files do for j:=1 to ranks do
   draw_piece(i,j,position[i,j]);
   whitesturn:=true;
   cursorx:=1;cursory:=1;
   if (not whiteatbottom) then begin
     cursorx:=files;cursory:=ranks;
   end;
   playeriswhite:=true;
   wkx:=5;wky:=1;bkx:=5;bky:=8;for i:=1 to maxdepth+1 do enpassant[i]:=100;
   mwk:=false;mbk:=false;mwra:=false;mbra:=false;mwrh:=false;mbrh:=false;
   movesmade:=0;

 end;

if (whiteatbottom) then begin
    settextstyle(defaultfont,horizdir,1);
    setcolor(black);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(ord('i')-i));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(ord('9')-i));
    setcolor(cyan);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(i+ord('a')-1));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(i+ord('0')));
  end
  else begin
    settextstyle(defaultfont,horizdir,1);
    setcolor(black);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(i+ord('a')-1));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(i+ord('0')));
    setcolor(cyan);
    for i:=1 to 8 do outtextxy(91+i*50,445,chr(ord('i')-i));
    for i:=1 to 8 do outtextxy(110,460-50*i,chr(ord('9')-i));
  end;
  if (setup) then movesmade:=30;
  settextstyle(defaultfont,horizdir,2);
  setcolor(green);
    outtextxy(0,330,'Your');
    outtextxy(0,360,'move');

     previous.avaus:=avaus;
        previous.positio:=position;
        previous.mnumber:=movenumber;
        previous.ep:=enpassant[1];
        previous.wtomove:=whitesturn;
        previous.wk:=mwk;
        previous.bk:=mbk;
        previous.wra:=mwra;
        previous.bra:=mbra;
        previous.wrh:=mwrh;
        previous.brh:=mbrh;
end;

{*************************************************************************}
procedure infos;
var i:integer;
Begin
  setcolor(lightgray);
  settextstyle(defaultfont,horizdir,1);
  outtextxy(33,(ymargin div 2)-15,
  'New      Make     Turn     Sound     View     Setup    Square    2 player');
  outtextxy(33,(ymargin div 2)-5,
  'game     move     board    on/off    score    board    colors    analysis');

  setcolor(green);

  for i:=1 to 4 do begin
  moveto(27+(i-1)*72,(ymargin div 2)+5);
  linerel(0,-20);linerel(-22,0);linerel(0,20);linerel(22,0);
  end;
  for i:=5 to 7 do begin
  moveto(34+(i-1)*72,(ymargin div 2)+5);
  linerel(0,-20);linerel(-22,0);linerel(0,20);linerel(22,0);
  end;

  moveto(42+7*72,(ymargin div 2)+5);
  linerel(0,-20);linerel(-22,0);linerel(0,20);linerel(22,0);

  outtextxy(9,(ymargin div 2)-10,
  'F1       F2       F3       F4        F5       F6       F7        F8');

  settextstyle(defaultfont,horizdir,2);
  setcolor(lightgray);
  outtextxy(5,480-(ymargin div 2),'-/+ '+secstr+' s. /move  Load Save  ESC Exit');
    setcolor(green);
  outtextxy(5,480-(ymargin div 2),'-/+                L    S     ESC');
  setcolor(yellow);
  outtextxy(5,480-(ymargin div 2),'    '+secstr);

End;
{*************************************************************************}
procedure add_movetime;
var add:integer;
begin
  if (movesecs<15) then add:=1 else
  if (movesecs<60) then add:=5 else
  if (movesecs<600) then add:=10 else
  add:=100;
  movesecs:=movesecs+add;
  if (movesecs>9999) then movesecs:=0;
  setcolor(black);
  outtextxy(5,480-(ymargin div 2),'    '+secstr);
  str(movesecs:4,secstr);
  setcolor(yellow);
  outtextxy(5,480-(ymargin div 2),'    '+secstr);
end;
{*************************************************************************}
procedure subtract_time;
var add:integer;
begin
  if (movesecs<=10) then add:=1 else
  if (movesecs<=60) then add:=5 else
  if (movesecs<=600) then add:=10 else
  add:=100;
  movesecs:=movesecs-add;
  if (movesecs<0) then movesecs:=9900;
  setcolor(black);
  outtextxy(5,480-(ymargin div 2),'    '+secstr);
  str(movesecs:4,secstr);
  setcolor(yellow);
  outtextxy(5,480-(ymargin div 2),'    '+secstr);
end;
{*************************************************************************}
Procedure players_move;
var wasx,wasy,file1,rank1,file2,rank2,moved,taken,i:integer;
    escape,illegal:boolean;siirto:string;etum,valim:char;
Begin
  searchlegmvs(whitesturn,1);
  wasx:=cursorx;wasy:=cursory;escape:=false;
  if (ord(ch)=13) then else
  repeat
    if ((ord(ch)=72) and (cursory<ranks)) then begin
      delcursor;
      cursory:=cursory+1;
      drawcursor;
    end;
    if ((ord(ch)=80) and (cursory>1)) then begin
      delcursor;
      cursory:=cursory-1;
      drawcursor;
    end;
    if ((ord(ch)=77) and (cursorx<files)) then begin
      delcursor;
      cursorx:=cursorx+1;
      drawcursor;
    end;
    if ((ord(ch)=75) and (cursorx>1)) then begin
      delcursor;
      cursorx:=cursorx-1;
      drawcursor;
    end;

  ch:=readkey;
  if (not (ord(ch) in [0,13,72,75,77,80])) then escape:=true;
  until ((ord(ch)=13) or (escape));
  file1:=cursorx;rank1:=cursory;
  drawmark;
  if (not whiteatbottom) then begin
    file1:=files+1-file1;
    rank1:=ranks+1-rank1;
  end;
  if (escape) then else
  repeat

    if ((ord(ch)=72) and (cursory<ranks)) then begin
      delcursor;
      cursory:=cursory+1;
      drawcursor;
    end;
    if ((ord(ch)=80) and (cursory>1)) then begin
      delcursor;
      cursory:=cursory-1;
      drawcursor;
    end;
    if ((ord(ch)=77) and (cursorx<files)) then begin
      delcursor;
      cursorx:=cursorx+1;
      drawcursor;
    end;
    if ((ord(ch)=75) and (cursorx>1)) then begin
      delcursor;
      cursorx:=cursorx-1;
      drawcursor;
    end;
  ch:=readkey;
  if (not (ord(ch) in [0,13,72,75,77,80])) then escape:=true;
  until ((ord(ch)=13) or (escape));
  file2:=cursorx;rank2:=cursory;
  if (not whiteatbottom) then begin
    file2:=files+1-file2;
    rank2:=ranks+1-rank2;
  end;
  illegal:=true;
  for i:=1 to legals[1] do if ((legmvs[1,i].file1=file1) and
  (legmvs[1,i].file2=file2) and (legmvs[1,i].rank1=rank1) and
  (legmvs[1,i].rank2=rank2)) then illegal:=false;
  if (illegal) then begin
    delcursor;
    draw_piece(file1,rank1,position[file1,rank1]);
    cursorx:=wasx;cursory:=wasy;
  end
  else begin
        previous.avaus:=avaus;
        previous.positio:=position;
        previous.mnumber:=movenumber;
        previous.ep:=enpassant[1];
        previous.wtomove:=whitesturn;
        previous.wk:=mwk;
        previous.bk:=mbk;
        previous.wra:=mwra;
        previous.bra:=mbra;
        previous.wrh:=mwrh;
        previous.brh:=mbrh;
    valim:='-';
    moved:=position[file1,rank1];
    if (abs(moved)<6) then begin
    lmoved[8]:=lmoved[7];
    lmoved[7]:=lmoved[6];
    lmoved[6]:=lmoved[5];
    lmoved[5]:=lmoved[4];
    lmoved[4]:=lmoved[3];
    lmoved[3]:=lmoved[2];
    lmoved[2]:=lmoved[1];
    lmoved[1]:=moved;
    end;
    taken:=position[file2,rank2];
    if (taken<>0) then valim:='x';
  if (moved=1) then mwk:=true;
  if (moved=-1) then mbk:=true;
  if ((file1=1) and (rank1=1)) then mwra:=true;
  if ((file1=8) and (rank1=1)) then mwrh:=true;
  if ((file1=1) and (rank1=8)) then mbra:=true;
  if ((file1=8) and (rank1=8)) then mbrh:=true;
  if ((file2=1) and (rank2=1)) then mwra:=true;
  if ((file2=8) and (rank2=1)) then mwrh:=true;
  if ((file2=1) and (rank2=8)) then mbra:=true;
  if ((file2=8) and (rank2=8)) then mbrh:=true;
  if (moved=1) and (file1+2=file2) then begin
    position[8,1]:=0;position[6,1]:=3;
    draw_piece(8,1,position[8,1]);
    draw_piece(6,1,position[6,1]);
  end;
  if (moved=1) and (file1-2=file2) then begin
    position[1,1]:=0;position[4,1]:=3;
    draw_piece(1,1,position[1,1]);
    draw_piece(4,1,position[4,1]);
  end;
  if (moved=-1) and (file1+2=file2) then begin
    position[8,8]:=0;position[6,8]:=-3;
    draw_piece(8,8,position[8,8]);
    draw_piece(6,8,position[6,8]);
  end;
  if (moved=-1) and (file1-2=file2) then begin
    position[1,8]:=0;position[4,8]:=-3;
    draw_piece(1,8,position[1,8]);
    draw_piece(4,8,position[4,8]);
  end;

    position[file1,rank1]:=0;
    position[file2,rank2]:=moved;
    if ((moved=6) and (rank2=ranks)) then
    position[file2,rank2]:=promoted;
    if ((moved=-6) and (rank2=1)) then
    position[file2,rank2]:=-promoted;
    enpassant[1]:=100;
    if ((moved=6) and (rank2-rank1=2)) then enpassant[1]:=file1;
    if ((moved=-6) and (rank1-rank2=2)) then enpassant[1]:=file1;
    if ((moved=6) and (file2<>file1) and (taken=0)) then begin
      position[file2,rank1]:=0;valim:='x';
      draw_piece(file2,rank1,position[file2,rank1]);
    end;
    if ((moved=-6) and (file2<>file1) and (taken=0)) then begin
      position[file2,rank1]:=0;valim:='x';
      draw_piece(file2,rank1,position[file2,rank1]);
    end;
    draw_piece(file1,rank1,position[file1,rank1]);
    draw_piece(file2,rank2,position[file2,rank2]);
    if (moved>0) then movenumber:=movenumber+1;
    whitesturn:=(not whitesturn);
    movesmade:=movesmade+1;


    if (abs(moved)=1) then etum:='K' else
    if (abs(moved)=2) then etum:='Q' else
    if (abs(moved)=3) then etum:='R' else
    if (abs(moved)=4) then etum:='B' else
    if (abs(moved)=5) then etum:='N' else
    etum:=' ';
    if (length(avaus)<252) then avaus:=avaus+chr(file1+ord('a')-1)+chr(rank1+ord('0'))+
    chr(file2+ord('a')-1)+chr(rank2+ord('0'));
    if (moved>0) then begin
    str(movenumber:3,siirto);
    siirto:=siirto+'.';
    end
    else siirto:='    ';
    siirto:=siirto+' '+etum+chr(file1+ord('a')-1)+chr(rank1+ord('0'))+valim+
    chr(file2+ord('a')-1)+chr(rank2+ord('0'));
    if (moved>0) then write(gamef,siirto) else writeln(gamef,siirto);
    update_movelist(siirto);
  end;
  if (escape) then ch:='z'
End;
{*************************************************************************}
procedure computers_move;
var mv:movetype;sc,moved,taken,i:integer;found:boolean;siirto:string;
    etum,valim:char;fiu1,rau1,fiu2,rau2:integer;
Begin

  found:=false;
  if (movesmade<26) then
  for i:=1 to blines do
  if ((length(bookline[i]^)>length(avaus)) and
  (copy(bookline[i]^,1,length(avaus))=avaus)) then begin
    found:=true;
    mv.file1:=ord(bookline[i]^[length(avaus)+1])+1-ord('a');
    mv.rank1:=ord(bookline[i]^[length(avaus)+2])+1-ord('1');
    mv.file2:=ord(bookline[i]^[length(avaus)+3])+1-ord('a');
    mv.rank2:=ord(bookline[i]^[length(avaus)+4])+1-ord('1');
  end;

  if (analysis) then found:=false;

  if (not found) then begin
  if (analysis) then else begin
    setcolor(black);
    outtextxy(0,330,'Your');
    outtextxy(0,360,'move');
  setcolor(green);
  settextstyle(defaultfont,horizdir,1);
  outtextxy(25,392,' SPACE');
  setcolor(lightgray);
  outtextxy(20,410,'MOVE NOW!');
  settextstyle(defaultfont,horizdir,2);
  end;
  compute(whitesturn,mv,sc,movesecs*100);
  end;
if (not analysis) then begin
  if (whiteatbottom) then begin
  fiu1:=mv.file1;rau1:=mv.rank1;
  fiu2:=mv.file2;rau2:=mv.rank2;
  end
  else begin
  fiu1:=9-mv.file1;rau1:=9-mv.rank1;
  fiu2:=9-mv.file2;rau2:=9-mv.rank2;
  end;
  setcolor(white);
  moveto(xmargin+fiu1*50-2,480-ymargin-rau1*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+fiu1*50-1,480-ymargin-rau1*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+fiu1*50-3,480-ymargin-rau1*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
  moveto(xmargin+fiu2*50-2,480-ymargin-rau2*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+fiu2*50-1,480-ymargin-rau2*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+fiu2*50-3,480-ymargin-rau2*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
    if (soundon) then begin
          sound(300);owndelay(15);nosound;
  end;
  owndelay(40);
  setcolor(lightred);
  moveto(xmargin+fiu1*50-2,480-ymargin-rau1*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+fiu1*50-1,480-ymargin-rau1*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+fiu1*50-3,480-ymargin-rau1*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
  moveto(xmargin+fiu2*50-2,480-ymargin-rau2*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+fiu2*50-1,480-ymargin-rau2*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+fiu2*50-3,480-ymargin-rau2*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
  owndelay(40);
  setcolor(white);
  moveto(xmargin+fiu1*50-2,480-ymargin-rau1*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+fiu1*50-1,480-ymargin-rau1*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+fiu1*50-3,480-ymargin-rau1*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
  moveto(xmargin+fiu2*50-2,480-ymargin-rau2*50+48);
  linerel(0,-46);linerel(-46,0);linerel(0,46);linerel(46,0);
  moveto(xmargin+fiu2*50-1,480-ymargin-rau2*50+49);
  linerel(0,-48);linerel(-48,0);linerel(0,48);linerel(48,0);
  moveto(xmargin+fiu2*50-3,480-ymargin-rau2*50+47);
  linerel(0,-44);linerel(-44,0);linerel(0,44);linerel(44,0);
  owndelay(40);
  moved:=position[mv.file1,mv.rank1];
  taken:=position[mv.file2,mv.rank2];
  if (abs(moved)<6) then begin
  lmoved[8]:=lmoved[7];
  lmoved[7]:=lmoved[6];
  lmoved[6]:=lmoved[5];
  lmoved[5]:=lmoved[4];
  lmoved[4]:=lmoved[3];
  lmoved[3]:=lmoved[2];
  lmoved[2]:=lmoved[1];
  lmoved[1]:=moved;
  end;
  if (taken=0) then valim:='-' else valim:='x';
  if (moved=1) then mwk:=true;
  if (moved=-1) then mbk:=true;
  if ((mv.file1=1) and (mv.rank1=1)) then mwra:=true;
  if ((mv.file1=8) and (mv.rank1=1)) then mwrh:=true;
  if ((mv.file1=1) and (mv.rank1=8)) then mbra:=true;
  if ((mv.file1=8) and (mv.rank1=8)) then mbrh:=true;
  if ((mv.file2=1) and (mv.rank2=1)) then mwra:=true;
  if ((mv.file2=8) and (mv.rank2=1)) then mwrh:=true;
  if ((mv.file2=1) and (mv.rank2=8)) then mbra:=true;
  if ((mv.file2=8) and (mv.rank2=8)) then mbrh:=true;
  position[mv.file1,mv.rank1]:=0;
  position[mv.file2,mv.rank2]:=moved;
  if (moved>0) then movenumber:=movenumber+1;
  if ((moved=6) and (mv.rank2=ranks)) then position[mv.file2,mv.rank2]:=2;
  if ((moved=-6) and (mv.rank2=1)) then position[mv.file2,mv.rank2]:=-2;
  enpassant[1]:=100;
  if ((moved=6) and (mv.rank2-mv.rank1=2)) then enpassant[1]:=mv.file1;
  if ((moved=-6) and (mv.rank1-mv.rank2=2)) then enpassant[1]:=mv.file1;
  if ((moved=6) and (mv.file2<>mv.file1) and (taken=0)) then begin
      position[mv.file2,mv.rank1]:=0;valim:='x';
      draw_piece(mv.file2,mv.rank1,position[mv.file2,mv.rank1]);
    end;
    if ((moved=-6) and (mv.file2<>mv.file1) and (taken=0)) then begin
      position[mv.file2,mv.rank1]:=0;valim:='x';
      draw_piece(mv.file2,mv.rank1,position[mv.file2,mv.rank1]);
    end;
    if (moved=1) and (mv.file1+2=mv.file2) then begin
    position[8,1]:=0;position[6,1]:=3;
    draw_piece(8,1,position[8,1]);
    draw_piece(6,1,position[6,1]);
  end;
  if (moved=1) and (mv.file1-2=mv.file2) then begin
    position[1,1]:=0;position[4,1]:=3;
    draw_piece(1,1,position[1,1]);
    draw_piece(4,1,position[4,1]);
  end;
  if (moved=-1) and (mv.file1+2=mv.file2) then begin
    position[8,8]:=0;position[6,8]:=-3;
    draw_piece(8,8,position[8,8]);
    draw_piece(6,8,position[6,8]);
  end;
  if (moved=-1) and (mv.file1-2=mv.file2) then begin
    position[1,8]:=0;position[4,8]:=-3;
    draw_piece(1,8,position[1,8]);
    draw_piece(4,8,position[4,8]);
  end;
  draw_piece(mv.file1,mv.rank1,position[mv.file1,mv.rank1]);
  draw_piece(mv.file2,mv.rank2,position[mv.file2,mv.rank2]);
  movesmade:=movesmade+1;

 whitesturn:=(not whitesturn);
 setcolor(black);
  settextstyle(defaultfont,horizdir,1);
  outtextxy(25,392,' SPACE');
  outtextxy(20,410,'MOVE NOW!');
  settextstyle(defaultfont,horizdir,2);
  if (length(avaus)<252) then avaus:=avaus+chr(mv.file1+ord('a')-1)+chr(mv.rank1+ord('0'))+
  chr(mv.file2+ord('a')-1)+chr(mv.rank2+ord('0'));
  if (abs(moved)=1) then etum:='K' else
    if (abs(moved)=2) then etum:='Q' else
    if (abs(moved)=3) then etum:='R' else
    if (abs(moved)=4) then etum:='B' else
    if (abs(moved)=5) then etum:='N' else
    etum:=' ';
   if (moved>0) then begin
   str(movenumber:3,siirto);
   siirto:=siirto+'.'
   end else siirto:='    ';
    siirto:=siirto+' '+etum+chr(mv.file1+ord('a')-1)+chr(mv.rank1+ord('0'))+
    valim+chr(mv.file2+ord('a')-1)+chr(mv.rank2+ord('0'));
    if (moved>0) then write(gamef,siirto) else writeln(gamef,siirto);
    update_movelist(siirto);

    setcolor(black);
    outtextxy(0,330,'Your');
    outtextxy(0,360,'move');
    destr:=chr(mv.file1+96)+
    chr(mv.rank1+48)+
    chr(mv.file2+96)+
    chr(mv.rank2+48);
    setcolor(green);
    outtextxy(0,330,'Your');
    outtextxy(0,360,'move');
        if (viewscores) then begin
  setcolor(blue);
  outtextxy(5,300,lstr);
    end;
 end
End;
{*************************************************************************}
BEGIN
  randomize;lstr:='0.0';


    for joku:=1 to blines do new(bookline[joku]);

  bookline[1]^:='e2e4g8f6e4e5f6d5d2d4d7d6c2c4d5b6e5d6c7d6g1f3g7g6f1e2f8g7e1g1e8g8h2h3b8c6b1c3c8f5c1e3d6d5c4c5b6c4e2c4d5c4';
  bookline[2]^:='e2e4g8f6e4e5f6d5d2d4d7d6c2c4d5b6f2f4d6e5f4e5b8c6c1e3c8f5b1c3e7e6g1f3f8e7f1e2e8g8e1g1f7f6e5f6e7f6d1d2d8e7';
  bookline[3]^:='e2e4g8f6e4e5f6d5d2d4d7d6g1f3g7g6f1c4d5b6c4b3f8g7f3g5e7e6d1f3d8e7g5e4d6e5c1g5e7b4c2c3b4a5g5f6g7f6f3f6e8g8';
  bookline[4]^:='e2e4g8f6e4e5f6d5c2c4d5b6c4c5b6d5f1c4e7e6b1c3d5c3d2c3b8c6c1f4f8c5d1g4g7g5f4g5h8g8g1h3c5e7g5e7g8g4e7d8e8d8';
  bookline[5]^:='e2e4e7e6d2d4d7d5c2c4d5e4b1c3g8f6c1e3b8c6g2g3f8b4f1g2e8g8g1e2e6e5d4d5c6a5d1a4c7c5a2a3b4c3e2c3b7b6c3e4f6e4';
  bookline[6]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7f1e1b7b5a4b3d7d6c2c3e8g8h2h3c6a5b3c2c7c5d2d4d8c7b1d2c5d4c3d4a5c6';
  bookline[7]^:='e2e4e7e5g1f3b8c6b1c3g8f6f1c4f8c5e1g1e8g8d2d3d7d6c3a4f6d7a4c5d7c5c1e3c5e6d3d4e5d4f3d4e6d4e3d4c6d4d1d4f8e8';
  bookline[8]^:='d2d4d7d5e2e4d5e4b1c3g8f6f2f3e4f3g1f3c8g4h2h3g4f3d1f3c7c6c1e3e7e6f1d3b8d7e1g1f8e7f1f2d8a5f3g3e8g8e3h6f6h5';
  bookline[9]^:='e2e4e7e5b1c3b8c6f1c4g8f6f2f4f6e4g1f3e4c3d2c3d8e7b2b4d7d6e1g1c8e6c4e6e7e6b4b5c6d8f4e5d6e5f3e5f8d6e5f3e8g8';
 bookline[10]^:='d2d4g8f6c2c4d7d6b1c3g7g6e2e4f8g7g1f3e8g8f1e2e7e5e1g1b8c6d4d5c6e7f3e1f6d7e1d3f7f5c1d2d7f6f2f3f5f4c4c5g6g5';
 bookline[11]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f6e4d2d4b7b5a4b3d7d5d4e5c8e6c2c3f8e7b1d2e8g8d1e2e4d2e2d2f7f6e5f6e7f6';
 bookline[12]^:='e2e4e7e5g1f3b8c6f1c4g8f6d2d3f8e7b1c3d7d6';
 bookline[13]^:='c2c4c7c5b1c3b8c6g2g3g7g6f1g2f8g7g1f3e7e5e1g1g8e7d2d3e8g8a2a3d7d6a1b1a7a5c1d2a8b8f3e1c8e6e1c2d6d5c4d5e7d5';
 bookline[14]^:='e2e4c7c5g1f3d7d6d2d4c5d4f3d4g8f6b1c3a7a6f1e2e7e5d4b3f8e7e1g1c8e6a2a4b8d7f2f4d8c7g1h1e8g8c1e3e5f4f1f4d7e5';
 bookline[15]^:='e2e4d7d5e4d5d8d5b1c3d5a5d2d4g8f6g1f3c8g4h2h3g4f3d1f3c7c6c1d2b8d7e1c1e7e6f1c4a5c7h1e1e8c8c4b3f8d6c1b1c8b8';
 bookline[16]^:='e2e4g8f6e4e5f6d5g1f3d7d6d2d4g7g6e5d6c7d6c2c4d5b6h2h3f8g7f1e2e8g8e1g1b8c6b1c3c8f5c1f4h7h6a1c1e7e5f4e3e5e4';
 bookline[17]^:='f2f4d7d5g1f3g8f6e2e3g7g6f1e2f8g7e1g1e8g8';
 bookline[18]^:='d2d4g8f6c2c4c7c6b1c3d7d5e2e3g7g6g1f3f8g7f1d3e8g8e1g1c8g4h2h3g4f3d1f3e7e6f1d1b8d7b2b4d5c4d3c4d7b6c4b3b6d5';
 bookline[19]^:='g1f3e7e6g2g3g8f6f1g2b7b6e1g1c8b7d2d4f8e7c2c4e8g8b1c3f6e4d1c2e4c3c2c3c7c5f1d1d7d6b2b3e7f6c1b2d8c7c3d2f8d8';
 bookline[20]^:='e2e4e7e5g1f3b8c6f1c4g8f6b1c3f8c5e1g1d7d6d2d3';
 bookline[21]^:='e2e4e7e5g1f3b8c6f1c4g8f6b1c3f8c5d2d3d7d6c1e3c5e3f2e3c6a5c4b3e8g8e1g1c7c6d1e1';
 bookline[22]^:='e2e4e7e5g1f3b8c6f1c4g8f6b1c3f8c5d2d3d7d6c1g5h7h6g5f6d8f6c3d5f6d8c2c3c6e7b2b4c5b6d5b6a7b6d3d4';
 bookline[23]^:='e2e4d7d5e4d5g8f6f1b5c8d7b5c4b7b5c4b3';
 bookline[24]^:='e2e4g8f6b1c3e7e5g1f3f8b4f3e5e8g8f1e2f8e8e5d3b4c3d2c3f6e4e1g1d7d5';
 bookline[25]^:='e2e4c7c5d2d4c5d4g1f3b8c6f3d4g8f6b1c3d7d6f1e2e7e5d4f3h7h6e1g1f8e7c1e3';
 bookline[26]^:='c2c3c7c5g1f3d7d5d2d4c5d4c3d4g8f6c1f4c8f5e2e3b8c6f1b5a8c8f3e5f6d7';
 bookline[27]^:='c2c4e7e5b1c3g8f6g1f3b8c6e2e4f8b4d2d3e8g8g2g3d7d6f1g2a7a6c1d2';
 bookline[28]^:='e2e4c7c5d2d4c5d4g1f3b8c6f3d4g8f6b1c3d7d6f1e2e7e5d4f3f8e7c1g5c8e6';
 bookline[29]^:='d2d4e7e6e2e4d7d5b1d2d5e4d2e4b8d7g1f3f8e7f1d3g8f6e4f6e7f6d1e2e8g8';
 bookline[30]^:='e2e4c7c5d2d4c5d4g1f3b8c6f3d4g8f6b1c3d7d6f1e2e7e5d4b3f8e7e1g1e8g8c1e3c8e6e2f3c6a5b3a5d8a5d1d2f8c8f1d1';
 bookline[31]^:='e2e4c7c5d2d4c5d4g1f3b8c6f3d4g8f6b1c3d7d6c1g5e7e6d1d2f8e7e1c1e8g8';
 bookline[32]^:='f2f4d7d5e2e3g8f6b2b3e7e6g1f3c7c5c1b2f8e7f1b5c8d7';
 bookline[33]^:='f2f4d7d5g1f3g8f6e2e3c8g4h2h3g4f3d1f3b8c6';
 bookline[34]^:='e2e4c7c5d2d4c5d4g1f3b8c6f3d4g8f6b1c3d7d6f1c4e7e6c4b3f8e7c1e3e8g8e1g1a7a6f2f4c6d4e3d4b7b5a2a3c8b7';
 bookline[35]^:='e2e4e7e5g1f3b8c6f1b5d7d6d2d4c8d7b1c3g8f6e1g1f8e7f1e1e5d4f3d4e8g8b5c6b7c6c1f4';
 bookline[36]^:='e2e4e7e6d2d4d7d5b1c3g8f6c1g5f8e7e4e5f6d7g5e7d8e7f2f4c7c5g1f3b8c6d1d2e8g8e1c1a7a6c1b1b7b5d4c5d7c5f1d3c8d7';
 bookline[37]^:='e2e4e7e6d2d4d7d5b1c3f8b4e4e5c7c5a2a3b4c3b2c3g8e7g1f3b8c6f1e2d8a5c1d2c8d7e1g1c5c4f3g5h7h6g5h3e8c8h3f4';
 bookline[38]^:='e2e4c7c5g1f3e7e6d2d4c5d4f3d4a7a6b1c3b8c6c1e3g8f6f1d3d7d5e4d5e6d5e1g1f8d6';
 bookline[39]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5b8d7e2e3c7c6g1f3d8a5f3d2d5c4g5f6d7f6d2c4a5c7f1e2f8e7e1g1e8g8';
 bookline[40]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5f8e7e2e3e8g8g1f3b8d7a1c1c7c6f1d3d5c4d3c4f6d5g5e7d8e7e1g1d5c3c1c3e6e5d4e5d7e5';
 bookline[41]^:='d2d4g8f6c2c4g7g6b1c3f8g7g2g3e8g8f1g2d7d6g1f3b8d7e1g1e7e5e2e4c7c6h2h3d8b6f1e1e5d4f3d4f8e8e1e2';
 bookline[42]^:='d2d4d7d5g1f3c7c6c2c4e7e6e2e3g8f6b1c3b8d7f1d3d5c4d3c4b7b5c4d3c8b7e1g1b5b4c3e4f8e7e4f6d7f6e3e4e8g8e4e5f6d7';
 bookline[43]^:='g1f3g8f6g2g3b7b6f1g2c8b7e1g1c7c5d2d3e7e6e2e4d7d6b1c3f8e7';
 bookline[44]^:='d2d4g8f6c2c4e7e6b1c3d7d5g1f3f8e7c1f4e8g8e2e3c7c5d4c5e7c5d1c2b8c6';
 bookline[45]^:='d2d4g8f6c2c4e7e5d4e5f6g4c1f4b8c6g1f3f8b4b1d2d8e7a2a3g4e5f3e5c6e5e2e3b4d2d1d2d7d6f1e2e8g8e1g1b7b6d2c3c8b7';
 bookline[46]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4d7d6b1c3';
 bookline[47]^:='d2d4g8f6c2c4e7e6g1f3d7d5c1g5f8e7b1c3e8g8e2e3h7h6g5f6e7f6a1c1c7c6f1d3b8d7e1g1d5c4d3c4e6e5c3e4e5d4e4f6d7f6';
 bookline[48]^:='d2d4d7d5c2c4d5c4g1f3g8f6e2e3c8g4f1c4e7e6h2h3g4h5e1g1a7a6b1c3b8c6b2b3f8d6c1b2e8g8c4e2d8e7e3e4h5f3e2f3f8d8';
 bookline[49]^:='c2c4e7e5b1c3g8f6g1f3b8c6g2g3d7d5c4d5f6d5d2d3d5b6f1g2f8e7e1g1e8g8a2a3c8e6b2b4a7a5b4b5c6d4f3d2c7c6a3a4b6d5';
 bookline[50]^:='e2e4c7c6d2d4d7d5b1d2d5e4d2e4b8d7f1c4g8f6e4g3e7e6g1f3c6c5';
 bookline[51]^:='c2c4e7e5b1c3g8f6g1f3b8c6g2g3d7d5c4d5f6d5d2d3d5b6f1g2f8e7e1g1e8g8c1e3f8e8a1c1e7f8c3e4c6d4e4c5d4f3g2f3c7c6';
 bookline[52]^:='e2e4e7e5g1f3b8c6d2d4e5d4f3d4g8f6b1c3f8b4d4c6b7c6f1d3d7d5e4d5c6d5e1g1e8g8c1g5c7c6d1f3b4d6g5f6d8f6f3f6g7f6';
 bookline[53]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f6e4d2d4b7b5a4b3d7d5d4e5c8e6c2c3f8e7f1e1';
 bookline[54]^:='e2e4c7c5d2d4c5d4c2c3d7d5';
 bookline[55]^:='d2d4d7d5c2c4e7e6b1c3c7c6g1f3d5c4a2a4f8b4e2e3b7b5c1d2c8b7a4b5b4c3d2c3c6b5b2b3a7a5b3c4b5b4c3b2g8f6f1d3b8d7';
 bookline[56]^:='d2d4g8f6c2c4e7e6g1f3b7b6a2a3c8b7b1c3d7d5c4d5f6d5d1c2d5c3b2c3f8e7e2e3b8d7f1d3c7c5c1b2a8c8c2e2e8g8e1g1d8c7';
 bookline[57]^:='d2d4g8f6c2c4e7e6g1f3b7b6g2g3c8b7f1g2f8e7e1g1e8g8b1c3f6e4d1c2e4c3c2c3c7c5f1d1d7d6b2b3e7f6c1b2d8c7c3d2f8d8';
 bookline[58]^:='e2e4c7c6d2d4d7d5e4e5c8f5g1e2e7e6h2h4h7h6e2g3f5g6h4h5g6h7f1d3h7d3d1d3d8b6';
 bookline[59]^:='e2e4e7e5f1c4g8f6d2d3c7c6g1f3d7d5c4b3f8d6b1c3d5e4d3e4b8a6c1e3d8e7f3d2d6c5d1e2c5e3e2e3c8e6b3e6';
 bookline[60]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6g1f3e8g8f1e2e7e5e1g1b8c6d4d5c6e7f3d2a7a5a2a3f6d7a1b1f7f5b2b4a5b4a3b4d7f6';
 bookline[61]^:='g1f3d7d5c2c4c7c6d2d4e7e6e2e3g8f6b1c3b8d7a2a3f8d6f1d3e8g8e1g1d5c4d3c4e6e5h2h3d8e7d1c2';
 bookline[62]^:='d2d4d7d5g1f3g8f6c2c4c7c6b1c3e7e6e2e3b8d7f1d3d5c4d3c4b7b5c4d3c8b7e1g1b5b4c3e4f8e7e4f6d7f6e3e4e8g8e4e5f6d7';
 bookline[63]^:='e2e4e7e5g1f3g8f6f3e5d8e7d2d4d7d6e5f3e7e4f1e2c8f5c2c4d6d5b1c3f8b4e1g1';
 bookline[64]^:='g1f3e7e6g2g3g8f6f1g2b7b6e1g1c8b7d2d3d7d5b1d2b8d7c2c3f8e7d1c2e8g8e2e4';
 bookline[65]^:='e2e4e7e5f2f4e5f4g1f3d7d6f1c4c8e6c4e6f7e6d2d4d8f6d1d2';
 bookline[66]^:='e2e4d7d6d2d4g8f6b1c3g7g6f2f4f8g7g1f3c7c5f1b5b8c6d4c5d8a5e1g1e8g8d1e1f6d7a2a4a7a6b5c6a5c5c1e3c5c6c3d5c6c2';
 bookline[67]^:='e2e4c7c5g1f3e7e6d2d4c5d4f3d4b8c6d4b5d7d6c2c4g8f6b1c3a7a6b5a3f8e7f1e2e8g8e1g1c8d7c1e3d8a5';
 bookline[68]^:='e2e4c7c6d2d4d7d5b1d2d5e4d2e4g8f6e4g3b8d7g1f3e7e6f1d3c6c5e1g1c5d4f3d4f8c5d4f3e8g8d1e2b7b6c1f4c8b7a1d1d8e7';
 bookline[69]^:='e2e4e7e5g1f3b8c6f1c4g8f6f3g5d7d5e4d5c6a5c4b5c7c6d5c6';
 bookline[70]^:='e2e4c7c6g1f3d7d5b1c3c8g4h2h3g4f3d1f3g8f6d2d3e7e6f1e2b8d7';
 bookline[71]^:='d2d4d7d5c2c4c7c6g1f3g8f6b1c3e7e6e2e3f8d6f1d3b8d7e3e4d5e4c3e4f6e4d3e4e8g8e1g1h7h6e4c2e6e5b2b3f8e8f1e1e5d4';
 bookline[72]^:='d2d4d7d5c2c4c7c6g1f3g8f6b1c3d5c4a2a4c8f5e2e3e7e6f1c4f8b4e1g1b8d7f3h4f5g6d1b3d8b6g2g3a7a5h4g6h7g6f1d1e8c8';
 bookline[73]^:='e2e4e7e5g1f3b8c6f1b5f8b4c2c3b4a5e1g1g8e7b5c6e7c6b2b4a5b6b4b5c6a5f3e5e8g8d2d4d8e8d1d3f7f5d3g3g8h8e4f5d7d6';
 bookline[74]^:='d2d4g8f6c2c4c7c5d4d5b7b5c4b5a7a6b5a6c8a6b1c3d7d6g1f3g7g6e2e4a6f1e1f1f8g7g2g3e8g8f1g2b8d7h1e1d8a5a1b1f8b8';
 bookline[75]^:='e2e4e7e5g1f3g8f6f3e5d7d6e5f3f6e4d2d4d6d5f1d3b8c6e1g1f8e7c2c4c6b4d3e2e8g8b1c3c8e6a2a3e4c3b2c3b4c6';
 bookline[76]^:='e2e4c7c5d2d4c5d4c2c3e7e5';
 bookline[77]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5c6d7c6e1g1f7f6d2d4c8g4d4e5d8d1f1d1f6e5d1d3f8d6b1d2b7b5b2b3g8e7c1b2e7g6g2g3e8g8';
 bookline[78]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4d7d6c2c4';
 bookline[79]^:='e2e4e7e5g1f3b8c6f1b5g8f6';
 bookline[80]^:='e2e4c7c5d2d4c5d4c2c3d4c3b1c3b8c6g1f3e7e6f1c4d8c7d1e2g8f6h2h3d7d6e1g1f8e7f1d1a7a6c1e3b7b5c4b3e8g8a1c1c7b7';
 bookline[81]^:='g1f3d7d5g2g3c7c6f1g2c8g4e1g1g8f6c2c4e7e6b2b3b8d7c1b2f8d6d2d3e8g8b1d2d8e7a2a3a7a5h2h3g4h5d1c2e6e5e2e4d5e4';
 bookline[82]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6g1f3e8g8f1e2e7e5e1g1b8c6d4d5c6e7f3e1f6d7e1d3f7f5c1d2g8h8b2b4d7f6f2f3h7h5';
 bookline[83]^:='d2d4g8f6c2c4c7c5d4d5e7e6b1c3e6d5c4d5d7d6e2e4g7g6g1f3f8g7f1e2e8g8e1g1f8e8f3d2b8a6f2f3a6c7a2a4b7b6d2c4c8a6';
 bookline[84]^:='e2e4e7e5f2f4f8c5g1f3b8c6';
 bookline[85]^:='e2e4e7e5f2f4e5f4b1c3d8h4e1e2d7d5c3d5c8g4g1f3f8d6d2d4b8c6c2c3g4f3g2f3e8c8e2d3';
 bookline[86]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5f8e7e2e3e8g8a1c1b8d7g1f3c7c6f1d3d5c4d3c4f6d5g5e7d8e7e1g1d5c3c1c3e6e5d1c2e5d4';
 bookline[87]^:='d2d4d7d5c2c4c7c6c4d5c6d5g1f3b8c6b1c3g8f6c1f4c8f5e2e3e7e6f1b5f6d7d1a4a8c8b5c6c8c6a4a7d8c8a7a5c6a6a5c7c8c7';
 bookline[88]^:='d2d4g8f6c2c4e7e6g1f3d7d5b1c3d5c4e2e4f8b4c1g5c7c5e4e5c5d4f3d4d8a5e5f6b4c3b2c3a5g5f6g7g5g7d1d2b8c6d4c6b7c6';
 bookline[89]^:='d2d4d7d5c2c4c7c6g1f3g8f6b1c3d5c4a2a4b8a6e2e4c8g4f1c4e7e6c1e3a6b4e1g1f8e7h2h3g4h5g2g4h5g6f3d2e8g8f2f4';
 bookline[90]^:='e2e4c7c5c2c3g8f6e4e5f6d5d2d4c5d4c3d4d7d6g1f3b8c6f1c4e7e6e1g1f8e7d1e2e8g8e2e4b7b6a2a3c8b7c4d3g7g6c1h6f8e8';
 bookline[91]^:='e2e4c7c5g1f3d7d6d2d4c5d4f3d4g8f6b1c3a7a6f1e2e7e6e1g1f8e7f2f4e8g8c1e3d8c7d1e1b8c6e1g3c6d4e3d4b7b5a2a3c8b7';
 bookline[92]^:='g1f3d7d5g2g3c7c6f1g2g8f6e1g1c8g4h2h3g4f3g2f3e7e5d2d3b8d7b1d2f8c5e2e4d5e4';
 bookline[93]^:='d2d4c7c5d4c5e7e6b1c3f8c5c3e4g8f6e4c5d8a5c2c3a5c5g1f3d7d5';
 bookline[94]^:='e2e4c7c5g1f3e7e6d2d4c5d4f3d4b8c6';
 bookline[95]^:='c2c4g8f6b1c3c7c6e2e4d7d5e4d5c6d5d2d4e7e6c4d5f6d5g1f3f8b4c1d2e8g8f1d3b8c6e1g1b4e7a2a3e7f6d1c2h7h6a1d1c8d7';
 bookline[96]^:='e2e4e7e5b1c3g8f6f1c4f6e4d1h5e4d6h5e5d8e7e5e7f8e7c4b3d6f5g1f3c7c6e1g1';
 bookline[97]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5f8e7e2e3e8g8a1c1b8d7g1f3c7c6f1d3d5c4d3c4f6d5g5e7d8e7c3e4d5f6e4f6e7f6e1g1c6c5';
 bookline[98]^:='e2e4e7e5b1c3g8f6g1f3f8b4f3e5e8g8f1e2f8e8e5d3b4c3d2c3f6e4e1g1d7d5';
 bookline[99]^:='e2e4c7c5b2b4c5b4a2a3d7d5e4d5d8d5g1f3e7e5c1b2b8c6c2c4d5e6f1d3f7f6e1g1f8c5d3e4g8e7';
bookline[100]^:='e2e4c7c5g1f3e7e6d2d4c5d4f3d4g8f6';
bookline[101]^:='e2e4c7c6b1c3d7d5d2d4d5e4c3e4b8d7g1f3g8f6e4g3e7e6f1d3c6c5e1g1c5d4f3d4f8c5d4f3e8g8d1e2b7b6c1f4c8b7a1d1';
bookline[102]^:='c2c4c7c6d2d4d7d5g1f3g8f6b1c3e7e6e2e3f8d6f1d3b8d7e3e4d5e4c3e4f6e4d3e4e8g8e1g1h7h6e4c2e6e5b2b4d6b4d4e5d7c5';
bookline[103]^:='e2e4c7c6b1c3d7d5g1f3c8g4h2h3g4f3d1f3e7e6d2d3g8f6f1e2b8d7';
bookline[104]^:='e2e4c7c6d2d4d7d5b1c3d5e4c3e4b8d7f1c4g8f6e4g5e7e6d1e2d7b6c4d3h7h6g5f3c6c5d4c5f8c5f3e5b6d7g1f3d8c7e1g1e8g8';
bookline[105]^:='e2e4c7c6b1c3d7d5d2d4d5e4c3e4b8d7f1c4g8f6e4g3e7e6g1f3c6c5';
bookline[106]^:='d2d4g8f6c2c4e7e6g1f3b7b6g2g3c8a6b2b3f8b4c1d2b4e7f1g2c7c6e1g1d7d5d2c3e8g8b1d2b8d7f1e1c6c5e2e4';
bookline[107]^:='e2e4c7c5c2c3d7d5e4d5d8d5d2d4e7e6g1f3g8f6b1a3b8c6f1e2d5d8a3c2c5d4c2d4c6d4d1d4d8d4f3d4';
bookline[108]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5c6d7c6e1g1f7f6d2d4e5d4f3d4c6c5d4b3d8d1f1d1c8g4f2f3g4e6c1e3b7b6a2a4f8d6a4a5e8c8';
bookline[109]^:='e2e4e7e6g1f3d7d5e4d5e6d5';
bookline[110]^:='d2d4g8f6c2c4c7c5d4d5b7b5c4b5a7a6b1c3a6b5e2e4d8a5c1d2b5b4e4e5b4c3d2c3a5a4d1a4a8a4e5f6g7f6f1b5';
bookline[111]^:='e2e4e7e5b1c3g8f6f2f4d7d5f4e5f6e4g1f3f8e7d2d4e8g8f1d3f7f5e5f6e7f6e1g1b8c6c3e4d5e4d3e4c6d4';
bookline[112]^:='e2e4e7e5g1f3g8f6f3e5d7d6e5f3f6e4d2d4d6d5f1d3f8d6e1g1e8g8c2c4c7c6b1c3e4c3b2c3d5c4d3c4c8g4d1d3g4h5c1g5d8c7';
bookline[113]^:='e2e4c7c6b1c3d7d5d2d4d5e4c3e4c8f5e4g3f5g6h2h4h7h6h4h5g6h7g1f3b8d7f1d3h7d3d1d3d8c7c1d2g8f6d3e2e7e6e1c1e8c8';
bookline[114]^:='e2e4c7c5c2c3d7d5e4d5d8d5d2d4e7e6g1f3b8c6f1e2g8f6b1a3d5d8a3c2f8e7e1g1e8g8c1g5c5d4c2d4c8d7';
bookline[115]^:='e2e4c7c6b1c3d7d5g1f3c8g4h2h3g4f3d1f3e7e6d2d3g8f6c1d2b8d7g2g4d5d4c3e2';
bookline[116]^:='e2e4e7e5g1f3b8c6d2d4e5d4c2c3d7d5e4d5d8d5c3d4f8b4b1c3c8g4f1e2g4f3e2f3d5c4f3e2c4d5';
bookline[117]^:='e2e4e7e5g1f3f7f5f3e5d8f6d2d4d7d6e5c4f5e4f1e2f6d8e1g1g8f6c1g5f8e7c4e3c7c6c2c4e8g8b1c3b8d7d1c2f8e8a1d1d8a5';
bookline[118]^:='e2e4e7e5g1f3b8c6d2d4e5d4c2c3d4c3b1c3f8b4f1c4d7d6d1b3b4c3b2c3d8d7';
bookline[119]^:='d2d4g8f6f2f3d7d5e2e4e7e6b1c3f8b4c1g5c7c5';
bookline[120]^:='f2f4e7e5e2e4e5f4g1f3d7d5e4d5g8f6f1b5c7c6d5c6b8c6d2d4f8d6e1g1e8g8b1d2c8g4d2c4d6c7b5c6b7c6d1d3d8d5f3e5';
bookline[121]^:='d2d4d7d5e2e4d5e4b1c3e7e5c1e3e5d4d1d4d8d4e3d4b8c6f1b5c8d7e1c1e8c8';
bookline[122]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f6e4d2d4b7b5a4b3d7d5d4e5c8e6c1e3f8e7c2c3e4c5b3c2e6g4b1d2c5e6d1b1g4h5';
bookline[123]^:='e2e4e7e5g1f3b8c6f1c4g8f6d2d3f8e7e1g1e8g8c2c3d7d6c4b3h7h6';
bookline[124]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5f8e7e2e3e8g8g1f3b8d7a1c1c7c6f1d3d5c4d3c4f6d5g5e7d8e7c3e4d5f6e4f6e7f6e1g1c6c5';
bookline[125]^:='g1f3c7c5c2c4g8f6b1c3b8c6d2d4c5d4f3d4e7e6d4b5d7d5c1f4e6e5c4d5e5f4d5c6b7c6d1d8e8d8a1d1c8d7';
bookline[126]^:='g1f3c7c5c2c4b7b6d2d4c5d4f3d4g8f6b1c3c8b7f2f3';
bookline[127]^:='c2c4c7c5b1c3g8f6g1f3e7e6g2g3b8c6f1g2f8e7e1g1d7d5c4d5f6d5c3d5e6d5d2d4e8g8d4c5e7c5c1g5f7f6';
bookline[128]^:='g1f3c7c5c2c4b8c6d2d4c5d4f3d4g7g6e2e4f8g7c1e3g8f6b1c3f6g4d1g4c6d4g4d1d4e6a1c1b7b6f1d3c8b7';
bookline[129]^:='g1f3c7c5c2c4g8f6b1c3b8c6d2d4c5d4f3d4g7g6g2g3';
bookline[130]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7f1e1b7b5a4b3d7d6c2c3e8g8h2h3c8b7d2d4f8e8b1d2e7f8a2a3h7h6b3c2c6b8';
bookline[131]^:='e2e4c7c5g1f3d7d6d2d4c5d4f3d4g8f6b1c3a7a6c1g5e7e6f2f4d8b6d4b3b8d7d1f3f8e7e1c1b6c7f1d3b7b5h1e1c8b7a2a3e8c8';
bookline[132]^:='e2e4c7c6g1f3d7d5e4d5c6d5f1b5c8d7';
bookline[133]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7a4c6d7c6d2d3f6d7b1d2e8g8d2c4f7f6f3h4d7c5d1f3c5e6h4f5e6d4f5d4d8d4';
bookline[134]^:='c2c4e7e5b1c3g8f6g1f3b8c6g2g3f8c5f1g2d7d6e1g1e8g8d2d3h7h6a2a3a7a6b2b4c5a7e2e3c8e6d1c2d8d7c1b2e6h3a1c1a8c8';
bookline[135]^:='e2e4c7c5g1f3d7d6b1c3e7e5f1c4b8c6';
bookline[136]^:='e2e4e7e5f2f4f8c5g1f3d7d6c2c3g8f6f4e5d6e5f3e5d8e7d2d4c5d6e5f3f6e4f1e2e8g8e1g1c7c5e2d3';
bookline[137]^:='e2e4e7e5f2f4f8c5d2d3b8c6';
bookline[138]^:='d2d4g8f6c2c4e7e6g1f3f8b4b1d2b7b6a2a3b4d2c1d2c8b7d2g5d7d6e2e3b8d7f1d3h7h6g5h4g7g5h4g3d8e7d1c2h6h5';
bookline[139]^:='d2d4g8f6c2c4e7e6g1f3f8b4c1d2d8e7g2g3b8c6f1g2b4d2b1d2d7d6e2e4e6e5d4d5c6b8e1g1e8g8b2b4a7a5a2a3b8a6d1b3';
bookline[140]^:='d2d4g8f6c2c4e7e6g1f3f8b4c1d2a7a5g2g3d7d5f1g2d5c4d1c2b8c6c2c4d8d5c4d5e6d5b1c3c8e6a1c1a5a4e1g1e8g8a2a3';
bookline[141]^:='d2d4g8f6c2c4e7e6g1f3c7c5d4d5b7b5d5e6f7e6c4b5d7d5e2e3f8d6b1c3c8b7f1e2e8g8b2b3b8d7c1b2d8e7';
bookline[142]^:='e2e4c7c5g1f3d7d6d2d4c5d4f3d4g8f6b1c3a7a6f1e2e7e5d4b3f8e7e1g1e8g8a2a4c8e6f2f4d8c7g1h1b8d7c1e3e5f4f1f4d7e5';
bookline[143]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7f1e1b7b5a4b3e8g8c2c3d7d6h2h3c6a5b3c2c7c5d2d4d8c7b1d2c5d4c3d4c8b7';
bookline[144]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7d1e2b7b5a4b3e8g8c2c3d7d5d2d3f8e8f1e1c8b7';
bookline[145]^:='f2f4d7d5g1f3g8f6e2e3g7g6b2b3f8g7c1b2e8g8f1e2c7c5e1g1b8c6f3e5c6e5f4e5f6e8';
bookline[146]^:='d2d4g8f6c2c4c7c5d4d5e7e6b1c3e6d5c4d5d7d6e2e4g7g6f2f4f8g7f1b5f6d7a2a4e8g8g1f3b8a6e1g1a8b8f1e1a6c7b5c4';
bookline[147]^:='d2d4g8f6c2c4c7c5d4d5e7e6b1c3e6d5c4d5d7d6g1f3g7g6e2e4f8g7f1e2e8g8e1g1a7a6a2a4c8g4c1f4g4f3e2f3d8e7f1e1b8d7';
bookline[148]^:='d2d4g8f6c2c4c7c5d4d5e7e6b1c3e6d5c4d5d7d6g1f3g7g6e2e4f8g7f1e2e8g8e1g1f8e8f3d2b8d7a2a4d7e5d1c2g6g5b2b3g5g4';
bookline[149]^:='e2e4e7e5g1f3b8c6f1c4c6d4e1g1';
bookline[150]^:='d2d4g8f6c2c4c7c5d4d5e7e6b1c3e6d5c4d5d7d6g1f3g7g6g2g3f8g7f1g2e8g8e1g1b8d7f3d2a7a6a2a4f8e8h2h3a8b8d2c4d7e5';
bookline[151]^:='e2e4c7c5c2c3e7e6d2d4d7d5e4e5c8d7g1f3d8b6a2a3c5c4b1d2b8c6f1e2c6a5e1g1g8e7a1b1e8c8b2b4c4b3c1b2h7h6';
bookline[152]^:='d2d4d7d6e2e4g7g6g1f3f8g7f1c4g8f6d1e2b8c6c2c3e8g8e1g1f6h5d4d5c6b8c1e3e7e5d5e6f7e6e3g5d8e8e2e3';
bookline[153]^:='c2c4c7c5b1c3b8c6g2g3g7g6f1g2f8g7g1f3e7e6e1g1g8e7d2d3e8g8c1f4d7d5';
bookline[154]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5f8e7e2e3e8g8g1f3h7h6g5h4f6e4h4e7d8e7c4d5e4c3b2c3e6d5d1b3e7d6c3c4d5c4f1c4';
bookline[155]^:='d2d4d7d5c2c4e7e6b1c3g8f6g1f3f8b4c4d5e6d5c1g5b8d7e2e3c7c5f1d3c5c4d3f5d8a5d1c2e8g8e1g1';
bookline[156]^:='d2d4d7d5c2c4e7e6b1c3g8f6g1f3c7c5c4d5f6d5e2e3b8c6f1c4c5d4e3d4f8e7e1g1e8g8f1e1d5c3b2c3b7b6c4d3c8b7';
bookline[157]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5f8e7e2e3e8g8g1f3h7h6g5h4b7b6c4d5f6d5h4e7d8e7c3d5e6d5a1c1c8e6d1a4c7c5a4a3f8c8';
bookline[158]^:='d2d4g8f6c2c4e7e6g1f3b7b6a2a3c7c5d4d5e6d5c4d5d7d6b1c3g7g6e2e4a7a6c1g5h7h6g5h4g6g5h4g3f6h5f3d2h5g3h2g3f8g7';
bookline[159]^:='d2d4g8f6c2c4e7e6g1f3b7b6a2a3c8b7b1c3d7d5c4d5f6d5e2e3f8e7f1b5c7c6b5d3d5c3b2c3c6c5e1g1b8c6e3e4e8g8c1b2c5d4';
bookline[160]^:='d2d4g8f6c2c4e7e6g1f3b7b6g2g3c8a6b2b3f8b4c1d2b4e7b1c3d7d5c4d5f6d5f1g2e8g8c3d5e6d5e1g1b8d7a1c1';
bookline[161]^:='d2d4g8f6c2c4e7e6g1f3b7b6e2e3c8b7f1d3f8e7b1c3d7d5e1g1e8g8b2b3c7c5c1b2b8c6a1c1c5d4e3d4a8c8';
bookline[162]^:='g1f3d7d5c2c4c7c6b2b3g8f6g2g3c8g4f1g2e7e6e1g1f8d6c1b2e8g8d2d3b8d7b1d2e6e5';
bookline[163]^:='e2e4g7g6d2d4f8g7b1c3d7d6f2f4c7c6g1f3c8g4c1e3d8b6d1d2g4f3g2f3b6b2a1b1b2a3b1b7b8d7b7b3';
bookline[164]^:='d2d4d7d5c2c4c7c6g1f3g8f6b1c3d5c4a2a4c8f5e2e3e7e6f1c4f8b4e1g1e8g8d1e2f6e4c3a2b4e7';
bookline[165]^:='d2d4d7d5c2c4c7c6c4d5c6d5b1c3g8f6c1f4b8c6e2e3c8f5g1f3e7e6f1b5f6d7d1a4a8c8e1g1a7a6b5c6c8c6f1c1f8e7c3e2d8b6';
bookline[166]^:='d2d4d7d5c2c4c7c6g1f3g8f6b1c3d5c4a2a4c8f5e2e3e7e6f1c4f8b4e1g1e8g8f3h4f5g6h4g6h7g6f2f3b8d7';
bookline[167]^:='d2d4d7d5c2c4c7c6g1f3g8f6b1c3e7e6e2e3b8d7f1d3d5c4d3c4b7b5c4d3a7a6e3e4c6c5d4d5c5c4d5e6f7e6d3c2c8b7e1g1d8c7';
bookline[168]^:='e2e4e7e5g1f3b8c6d2d4e5d4f3d4g7g6b1c3f8g7c1e3d7d6';
bookline[169]^:='e2e4c7c6d2d4d7d5e4e5c8f5g1e2e7e6e2g3f5g6h2h4h7h5f1d3g6d3d1d3d8a5c2c3a5a6';
bookline[170]^:='e2e4c7c5g1f3e7e6d2d4c5d4f3d4a7a6f1d3g8f6e1g1d7d6c2c4f8e7b1c3e8g8d1e2b8d7f2f4d8c7g1h1b7b6c1d2c8b7';
bookline[171]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7f1e1b7b5a4b3d7d6a2a4c6a5b3a2c7c5c2c3';
bookline[172]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7f1e1d7d6c2c3c8g4d2d3e8g8b1d2f8e8d2f1e7f8';
bookline[173]^:='e2e4e7e5b1c3g8f6f2f4d7d5f4e5f6e4g1f3f8e7d2d3e4c3b2c3e8g8c3c4f7f6c1e3f6e5f3e5c8f5';
bookline[174]^:='e2e4c7c5g1f3b8c6d2d4c5d4f3d4g8f6b1c3d7d6f1c4e7e6c4b3f8e7c1e3e8g8d1e2a7a6e1c1d8c7g2g4c6d4d1d4b7b5g4g5f6d7';
bookline[175]^:='e2e4c7c5d2d4c5d4c2c3d4c3b1c3b8c6g1f3d7d6f1c4e7e6e1g1g8f6d1e2f8e7f1d1e6e5h2h3e8g8c1e3a7a6a1c1h7h6';
bookline[176]^:='d2d4d7d5c2c4e7e6b1c3c7c5c4d5e6d5g1f3b8c6g2g3g8f6f1g2f8e7e1g1e8g8d4c5e7c5c1g5d5d4g5f6d8f6c3d5f6d8f3d2f8e8';
bookline[177]^:='e2e4e7e5g1f3b8c6b1c3f8c5f3e5c6e5d2d4c5d6d4e5d6e5c1d2g7g6f2f4e5g7d1f3d7d6e1c1g8f6h2h3e8g8';
bookline[178]^:='d2d4g8f6g1f3e7e6c1g5c7c5e2e3c5d4e3d4f8e7f1d3e8g8c2c3b7b6e1g1c8b7b1d2d7d6f1e1b8d7';
bookline[179]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f6e4d2d4b7b5a4b3d7d5d4e5c8e6c2c3f8e7b1d2e8g8d1e2e4c5f3d4c5b3d4c6b3c1';
bookline[180]^:='e2e4b8c6d2d4d7d5b1c3e7e6e4e5';
bookline[181]^:='e2e4e7e5g1f3d7d6d2d4g8f6b1c3b8d7f1c4f8e7e1g1e8g8d1e2c7c6a2a4d8c7h2h3b7b6f1d1';
bookline[182]^:='c2c4c7c5g1f3g8f6d2d4c5d4f3d4e7e6b1c3f8b4d4b5d7d5c4d5e6d5a2a3b4c3b2c3e8g8e2e3';
bookline[183]^:='e2e4e7e5g1f3g8f6f3e5d7d6e5f3f6e4d2d4d6d5f1d3f8e7e1g1b8c6c2c4c6b4d3e2c8e6b1c3e8g8c1e3e7f6c3e4d5e4f3e1';
bookline[184]^:='c2c4c7c5b1c3b8c6g1f3g8f6d2d4c5d4f3d4e7e6d4b5d7d6c1f4e6e5f4g5a7a6b5a3';
bookline[185]^:='d2d4d7d5c2c4e7e6b1c3c7c5c4d5e6d5g1f3b8c6g2g3g8f6f1g2f8e7e1g1e8g8c1g5c8e6a1c1f6e4';
bookline[186]^:='d2d4d7d5c2c4d5c4g1f3g8f6e2e3e7e6f1c4c7c5e1g1a7a6d1e2b7b5c4b3c8b7f1d1b8d7b1c3d8b6d4d5e6d5c3d5f6d5b3d5b7d5';
bookline[187]^:='e2e4e7e5g1f3b8c6c2c3g8f6d2d4f6e4d4d5c6e7f3e5e7g6f1d3g6e5d3e4f8c5';
bookline[188]^:='e2e4d7d6d2d4g8f6b1c3g7g6g1f3f8g7f1e2e8g8e1g1c8g4c1e3b8c6d1d2e7e5d4d5c6e7a1d1g4d7h2h3f6e8f3h2f7f5g2g3g8h8';
bookline[189]^:='d2d4d7d5c2c4e7e6b1c3g8f6c4d5e6d5c1g5c7c6e2e3f8e7f1d3f6e4g5e7d8e7g1f3b8d7d1c2f7f5e1g1e8g8f1e1e7f7c2b3';
bookline[190]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7f1e1b7b5a4b3d7d6c2c3e8g8h2h3c6b8d2d4b8d7b1d2c8b7b3c2c7c5d2f1f8e8';
bookline[191]^:='e2e4d7d6d2d4g8f6b1c3g7g6f2f4f8g7g1f3e8g8f1d3b8c6e1g1c8g4e4e5d6e5d4e5f6d5h2h3d5c3b2c3g4f5d3f5d8d1f1d1g6f5';
bookline[192]^:='d2d4g8f6c2c4d7d6b1c3b8d7g1f3e7e5e2e4f8e7f1e2e8g8e1g1c7c6f1e1a7a6e2f1b7b5a2a3c8b7c1g5d8b8h2h3f8e8d1c2e7f8';
bookline[193]^:='e2e4e7e5g1f3g8f6f3e5d7d6e5f3f6e4d1e2d8e7d2d3e4f6';
bookline[194]^:='e2e4b8c6g1f3d7d6d2d4c8g4f1b5a7a6b5a4b7b5a4b3g8f6c2c3e7e6d1e2f8e7e1g1e8g8b1d2';
bookline[195]^:='d2d4g8f6c2c4e7e6b1c3f8b4a2a3b4c3b2c3e8g8f2f3f6e8e2e4b7b6f1d3c8a6a3a4b8c6c1a3d7d6f3f4c6a5d1e2f7f5';
bookline[196]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1f8e7f1e1b7b5a4b3d7d6c2c3c6a5b3c2c7c5d2d4d8c7';
bookline[197]^:='d2d4g8f6c2c4e7e6b1c3f8b4e2e3b7b6f1d3c8b7g1f3e8g8e1g1c7c5c3a4c5d4e3d4b4e7f1e1d7d6b2b4b8d7c1b2a7a5b4b5d6d5';
bookline[198]^:='d2d4g8f6c2c4e7e6b1c3f8b4e2e3e8g8f1d3d7d5g1f3c7c5e1g1b8c6a2a3b4c3b2c3d5c4d3c4d8c7c4a2e6e5h2h3e5e4f3h2c8f5';
bookline[199]^:='d2d4g8f6c2c4e7e6b1c3f8b4d1c2e8g8a2a3b4c3c2c3b7b6g1f3c8b7e2e3d7d6b2b4b8d7c1b2a7a5f1e2f6e4c3c2c7c5';
bookline[200]^:='d2d4g8f6c2c4e7e6b1c3f8b4e2e3e8g8g1f3d7d5f1d3c7c5e1g1d5c4d3c4b8d7d1e2b7b6f1d1c5d4e3d4c8b7c4b3b4c3b2c3d8c7';
bookline[201]^:='e2e4e7e5g1f3f7f5f3e5d8f6e5c4f5e4b1c3f6g6d2d3f8b4c1d2b4c3d2c3g8f6c3f6g7f6d3e4g6e4c4e3';
bookline[202]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6f2f3e8g8c1e3b8c6g1e2a7a6d1d2a8b8h2h4h7h5e1c1b7b5e3h6e7e5';
bookline[203]^:='b2b3e7e5c1b2b8c6c2c4g8f6e2e3d7d5c4d5f6d5a2a3f8d6d1c2e8g8g1f3d8e7f1e2g8h8d2d3c8d7b1d2f7f5';
bookline[204]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6f2f3e8g8c1e3e7e5d4d5f6h5d1d2f7f5e1c1b8d7e4f5g6f5f1d3d7f6g1e2g8h8e3g5d8e8';
bookline[205]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6f2f4e8g8g1f3c7c5d4d5e7e6f1e2e6d5c4d5c8g4e1g1b8d7h2h3g4f3e2f3a7a6a2a4h7h5';
bookline[206]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6g1f3e8g8f1e2e7e5e1g1b8c6d4d5c6e7f3e1f6d7e1d3f7f5c1d2d7f6f2f3f5f4c4c5g6g5';
bookline[207]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6f1e2e8g8c1g5c7c5d4d5e7e6d1d2e6d5e4d5f8e8g1f3c8g4e1g1b8d7h2h3g4f3e2f3a7a6';
bookline[208]^:='d2d4g8f6c2c4g7g6b1c3f8g7e2e4d7d6g1f3e8g8f1e2e7e5e1g1b8c6d4d5c6e7f3d2c7c5a1b1f6e8b2b4b7b6a2a4f7f5';
bookline[209]^:='g1f3d7d5g2g3c7c5f1g2b8c6e1g1e7e5d2d3f8e7e2e4d5d4b1d2g8f6d2c4f6d7a2a4e8g8';
bookline[210]^:='e2e4e7e5f2f4d7d5e4d5e5e4d2d3g8f6b1c3f8b4c1d2e4e3d2e3e8g8e3d2b4c3b2c3f8e8f1e2c8g4e1f2g4e2g1e2d8d5';
bookline[211]^:='e2e4e7e5f2f4f8c5g1f3d7d6b1c3g8f6f1c4b8c6d2d3c8g4c3a4c5b6a4b6a7b6c2c3e8g8e1g1';
bookline[212]^:='e2e4e7e5g1f3g8f6b1c3b8c6';
bookline[213]^:='e2e4e7e5f2f4f8c5g1f3d7d5f3e5g8f6d2d4c5b6e4d5d8d5c1e3b8c6b1c3b6a5';
bookline[214]^:='d2d4g8f6c2c4g7g6g2g3f8g7f1g2d7d5c4d5f6d5g1f3e8g8e1g1d5b6b1c3b8c6e2e3e7e5d4d5c6a5e3e4c7c6c1g5f7f6g5e3c6d5';
bookline[215]^:='d2d4g8f6c2c4g7g6b1c3d7d5c1f4f8g7e2e3c7c5d4c5d8a5a1c1f6e4c4d5e4c3d1d2a5a2b2c3a2a5f1c4b8d7g1f3d7c5e1g1e8g8';
bookline[216]^:='d2d4g8f6c2c4g7g6b1c3d7d5c4d5f6d5e2e4d5c3b2c3f8g7g1f3c7c5a1b1e8g8f1e2c5d4c3d4d8a5d1d2a5d2c1d2e7e6e1g1b7b6';
bookline[217]^:='d2d4g8f6c2c4g7g6b1c3d7d5c4d5f6d5d1b3';
bookline[218]^:='d2d4g8f6c2c4g7g6b1c3d7d5c4d5f6d5e2e4d5c3b2c3f8g7f1c4e8g8g1e2c7c5e1g1b8c6c1e3c5d4c3d4c8g4f2f3c6a5c4d3g4e6';
bookline[219]^:='d2d4d7d5c2c4e7e6b1c3g8f6c1g5f8e7g1f3e8g8e2e3b8d7a1c1c7c6f1d3d5c4d3c4f6d5';
bookline[220]^:='e2e4g8f6b1c3e7e5f1c4b8c6g1f3f6e4c3e4d7d5c4d3d5e4d3e4f8d6d2d4e5d4e4c6b7c6d1d4e8g8e1g1c6c5d4c3c8b7';
bookline[221]^:='e2e4e7e5d1f3d8f6';
bookline[222]^:='e2e4e7e5g1f3b8c6f1c4f8c5c2c3g8f6d2d4e5d4c3d4c5b4c1d2b4d2b1d2d7d5e4d5f6d5d1b3c6e7e1g1e8g8f1e1c7c6';
bookline[223]^:='e2e4e7e5g1f3b8c6f1b5a7a6b5a4g8f6e1g1b7b5';
bookline[224]^:='d2d4f7f5c2c4g8f6g2g3d7d6f1g2c7c6';
bookline[225]^:='e2e4e7e6d2d4d7d5b1d2g8f6e4e5f6d7f1d3c7c5c2c3b8c6g1e2c5d4c3d4f7f6e5f6d7f6e1g1f8d6d2f3d8c7e2c3a7a6c1g5e8g8';
bookline[226]^:='e2e4e7e6d2d4d7d5b1d2c7c5e4d5e6d5g1f3b8c6f1b5f8d6d4c5d6c5e1g1g8e7d2b3c5d6f1e1e8g8c1g5c8g4b5e2f8e8c2c3a7a6';
bookline[227]^:='e2e4e7e6d2d4d7d5b1c3g8f6e4e5f6d7f2f4c7c5g1f3b8c6c1e3c5d4f3d4f8c5d1d2c6d4e3d4c5d4d2d4d8b6d4b6d7b6c3b5e8e7';
bookline[228]^:='e2e4e7e6d2d4d7d5b1c3d5e4c3e4b8d7g1f3g8f6e4f6d7f6f1d3c7c5d4c5f8c5c1g5c5e7d1e2e8g8e1c1d8a5c1b1';
bookline[229]^:='e2e4e7e6d2d4d7d5e4e5c7c5c2c3b8c6g1f3d8b6f1e2c5d4c3d4g8h6b1c3h6f5c3a4f8b4c1d2b6a5d2c3b7b5a2a3b4c3a4c3b5b4';
bookline[230]^:='e2e4e7e6d2d4d7d5e4e5c7c5c2c3b8c6g1f3d8b6a2a3c5c4g2g3c6a5b1d2c8d7f1h3h7h6e1g1e8c8a1b1g8e7f3e1f7f5e5f6g7f6';
bookline[231]^:='e2e4e7e5g1f3b8c6b1c3g8f6f1b5f8b4e1g1e8g8d2d3d7d6c1g5b4c3b2c3c8d7d3d4h7h6g5h4f8e8f1e1a7a6b5d3d7g4';
bookline[232]^:='c2c4c7c5b1c3b8c6g2g3g7g6f1g2f8g7e2e3e7e6g1e2g8e7e1g1e8g8d2d4c5d4e2d4c6d4e3d4d7d5c4d5e7d5c3d5e6d5';
bookline[233]^:='c2c4c7c5b1c3b8c6g1f3g8f6d2d4c5d4f3d4e7e6d4b5d7d5c1f4e6e5c4d5e5f4d5c6b7c6d1d8e8d8a1d1c8d7b5d6f8d6d1d6a8b8';
bookline[234]^:='c2c4e7e5b1c3b8c6g1f3g8f6g2g3f8b4f1g2e8g8e1g1e5e4f3g5b4c3b2c3f8e8f2f3e4f3g5f3d7d5c4d5d8d5f3d4d5h5d4c6b7c6';
bookline[235]^:='c2c4c7c5b1c3g8f6g2g3d7d5c4d5f6d5f1g2d5c7g1f3b8c6d1a4d8d7e1g1g7g6a4c4b7b6b2b4f8g7b4c5b6b5';
bookline[236]^:='d2d4f7f5c2c4g8f6g2g3e7e6f1g2d7d5g1f3c7c6e1g1f8d6b2b3d8e7c1b2e8g8b1d2b8d7f3e5f6e4e5d3';
bookline[237]^:='d2d4f7f5c2c4g8f6g2g3g7g6f1g2f8g7g1f3e8g8e1g1d7d6b1c3b8c6d4d5c6e5f3e5d6e5e2e4';
bookline[238]^:='d2d4f7f5c2c4g8f6g2g3e7e6f1g2f8e7g1f3e8g8e1g1d7d6b1c3d8e8d1c2e8h5c1g5b8c6a1d1e6e5d4e5c6e5g5f6e7f6c4c5d6c5';
bookline[239]^:='e2e4e7e5d2d4e5d4c2c3d7d5e4d5d8d5c3d4g8f6g1f3f8b4b1c3e8g8f1e2f6e4c1d2b4c3b2c3e4d2';
bookline[240]^:='e2e4c7c5g1f3b8c6f1c4d7d6e1g1g8f6f3g5e7e6';
bookline[241]^:='e2e4c7c5d1f3g8f6';
bookline[242]^:='d2d4g8f6c2c4c7c5d4d5e7e5b1c3d7d6e2e4f8e7g1f3e8g8h2h3b8d7g2g4a7a6a2a4a8b8f1d3f8e8h1g1d7f8g4g5f6d7h3h4';
bookline[243]^:='d2d4d7d5c2c4b8c6g1f3c8g4c4d5g4f3g2f3d8d5e2e3e7e6b1c3f8b4c1d2d5h5f1g2g8e7f3f4';
bookline[244]^:='d2d4d7d5g1f3g8f6e2e3e7e6f1d3c7c5c2c3b8c6b1d2f8d6e1g1e8g8f1e1e6e5d4e5c6e5f3e5d6e5';
bookline[245]^:='e2e4e7e5d2d4e5d4d1d4b8c6d4e3g8f6b1c3f8b4c1d2e8g8e1c1f8e8f1c4c6a5c4d3d7d5g1e2c7c5';
bookline[246]^:='e2e4d7d5e4d5g8f6d2d4f6d5c2c4d5b6g1f3g7g6f1e2f8g7e1g1e8g8b1c3';
bookline[247]^:='e2e4c7c6d2d4d7d5e4d5c6d5c2c4b8c6c4d5d8d5g1f3e7e5b1c3f8b4c1d2b4c3d2c3e5e4';
bookline[248]^:='e2e4d7d5e4d5d8d5b1c3d5a5d2d4g8f6g1f3c8g4h2h3g4h5g2g4h5g6f3e5e7e6f1g2c7c6e1g1b8d7d1e2d7e5d4e5f6d5c3e4';
bookline[249]^:='d2d4g8f6c2c4e7e6g2g3d7d5f1g2f8e7g1f3e8g8e1g1b8d7d1c2c7c6b1d2b7b6b2b3c8b7c1b2a8c8e2e4c6c5e4d5e6d5d4c5d5c4';
bookline[250]^:='d2d4g8f6c2c4e7e6g2g3d7d5f1g2d5c4g1f3f8e7e1g1e8g8d1c2a7a6c2c4b7b5c4c2c8b7c1g5b8d7g5f6d7f6b1d2a8c8d2b3b7e4';
bookline[251]^:='e2e4c7c6d2d4d7d5e4d5c6d5c2c4g8f6b1c3e7e6g1f3f8e7c4c5e8g8f1d3b7b6b2b4a7a5c3a4f6d7b4b5b6c5d4c5e6e5c5c6e5e4';
bookline[252]^:='e2e4c7c6d2d4d7d5b1c3d5e4c3e4b8d7e4g5g8f6f1c4e7e6d1e2d7b6c4d3h7h6g5f3c6c5d4c5f8c5f3e5b6d7g1f3d7e5f3e5e8g8';
bookline[253]^:='e2e4c7c6d2d4d7d5b1c3d5e4c3e4c8f5e4g3f5g6h2h4h7h6g1f3b8d7h4h5g6h7f1d3h7d3d1d3d8c7c1d2e7e6e1c1g8f6g3e4e8c8';
bookline[254]^:='e2e4c7c6d2d4d7d5e4e5c8f5b1c3e7e6g2g4f5g6g1e2c6c5h2h4h7h6c1e3d8b6d1d2b8c6e1c1h6h5d4c5f8c5';
bookline[255]^:='f2f4f7f5e2e4f5e4d2d3e4e3c1e3g8f6d3d4e7e6';
bookline[256]^:='e2e4c7c5g1f3b7b6d2d4c5d4f3d4c8b7f1d3';
bookline[257]^:='c2c4c7c5g1f3b7b6g2g3e7e6f1g2c8b7b1c3g8f6';
bookline[258]^:='d2d4d7d5g1f3e7e6c1f4f8d6';
bookline[259]^:='e2e4e7e5g1f3b8c6f1b5d7d6b5c6b7c6d2d4f7f6';
bookline[260]^:='b2b3g8f6c1b2g7g6e2e4d7d6g2g3f8g7f1g2e8g8';
bookline[261]^:='e2e4e7e5f1c4f8c5c2c3d7d5c4d5g8f6';
bookline[262]^:='e2e4b7b6d2d4c8b7f1d3f7f5f2f3e7e6b1c3b8c6';
bookline[263]^:='d2d4c7c6e2e4g7g6c2c3f8g7g1f3d7d5';
bookline[264]^:='d2d4d7d5c2c4e7e6b1c3g8f6g1f3c7c6e2e3b8d7f1d3f8b4';


  assign(gamef,'weplayed.txt');
  oldmode:=filemode;
  filemode:=0;
  {$I-} append(gamef); {$I+}
  virhe:=(IOResult<>0);
  filemode:=oldmode;
  if (virhe) then rewrite(gamef);

  if RegisterBGIdriver(@EGAVGADriverProc) < 0 then Abort('EGA/VGA');
  set_to_graphics_mode; darks:=darkgray;lights:=lightgray;cursorc:=white;
  soundon:=true;
  setbkcolor(black);whiteatbottom:=true;movesecs:=5;viewscores:=false;
  xmargin:=320-25*files;ymargin:=240-25*ranks;draw_board_skeleton;
  rrate:=4;
  settextstyle(defaultfont,horizdir,2);str(movesecs:4,secstr);infos;
  repeat
    set_initial_pos(false);gameover:=false;avaus:='';analysis:=false;

    for aa:=1 to blines do begin
      cee:=1+random(blines);
      templine:=bookline[aa]^;
      bookline[aa]^:=bookline[cee]^;
      bookline[cee]^:=templine
    end;
    setcolor(black);
    outtextxy(20,220,' GAME');
    outtextxy(20,250,' OVER');
    outtextxy(5,300,lstr);
          outtextxy(5,275,beststr);
    lstr:='book';
    repeat
      if (analysis) then computers_move else
      if ((whitesturn=(not playeriswhite)) and (not gameover))
      then computers_move;

      for ii:=1 to ranks do for jj:=1 to files do
      if (position[jj,ii]=1) then begin
        wkx:=jj;wky:=ii
      end
      else if (position[jj,ii]=-1) then begin
        bkx:=jj;bky:=ii
      end;
      searchlegmvs(whitesturn,1);
      if (legals[1]<1) then gameover:=true;
      if (gameover) then begin
          settextstyle(defaultfont,horizdir,1);
  setcolor(black);
  outtextxy(0,250,kpstr);
  settextstyle(defaultfont,horizdir,2);
          outtextxy(0,330,'Your');
        outtextxy(0,360,'move');
        setcolor(yellow);
        outtextxy(20,220,' GAME');
        outtextxy(20,250,' OVER');

        if (soundon) then begin
          sound(400);owndelay(15);nosound;
        end
      end;
      drawcursor;
      ch:=readkey;
      if (ord(ch)=0) then ch:=readkey;
      if (ch in ['l','L']) then begin
        empty_movelist;name:='';
        setcolor(yellow);
        settextstyle(defaultfont,horizdir,1);
        outtextxy(535,340,'Filename:');
        outtextxy(535,380,'--------');
        repeat
          ch:=readkey;
          if  ((ch in ['a'..'z']) or (ch in ['A'..'Z']) or
          (ch in ['0'..'9'])) then name:=name+ch;
          outtextxy(535,370,name)
        until ((length(name)=8) or (ord(ch)=13));
        ch:='z';
        setcolor(black);
        outtextxy(535,340,'Filename:');
        outtextxy(535,380,'--------');
        outtextxy(535,370,name);
        name:=name+'.n5g';
        settextstyle(defaultfont,horizdir,2);
        assign(posf,name);
        oldmode:=filemode;
        filemode:=0;
        {$I-} reset(posf); {$I+}
        virhe:=(IOResult<>0);
        filemode:=oldmode;
        if (virhe) then else begin;
        writeln(gamef,' ');
        writeln(gamef,'Loaded position ',name);
           writeln(gamef,' ');
        read(posf,previous);
              gameover:=false;
    setcolor(black);
    outtextxy(20,220,' GAME');
    outtextxy(20,250,' OVER');
    outtextxy(5,300,lstr);
    lstr:='book';
    position:=previous.positio;
    avaus:=previous.avaus;
    movenumber:=previous.mnumber;
    enpassant[1]:=previous.ep;
    whitesturn:=previous.wtomove;
    playeriswhite:=whitesturn;
    mwk:=previous.wk;
    mbk:=previous.bk;
    mwra:=previous.wra;
    mbra:=previous.bra;
    mwrh:=previous.wrh;
    mbrh:=previous.brh;
    for aa:=1 to files do for cee:=1 to ranks do
   draw_piece(aa,cee,position[aa,cee]);
   empty_movelist;
        close(posf);
        end;
      end;
      if (ch in ['s','S']) then begin
        empty_movelist;name:='';
        setcolor(yellow);
        settextstyle(defaultfont,horizdir,1);
        outtextxy(535,340,'Filename:');
        outtextxy(535,380,'--------');
        repeat
          ch:=readkey;
          if  ((ch in ['a'..'z']) or (ch in ['A'..'Z']) or
          (ch in ['0'..'9'])) then name:=name+ch;
          outtextxy(535,370,name)
        until ((length(name)=8) or (ord(ch)=13));
        ch:='z';
        setcolor(black);
        outtextxy(535,340,'Filename:');
        outtextxy(535,380,'--------');
        outtextxy(535,370,name);
        name:=name+'.n5g';
        settextstyle(defaultfont,horizdir,2);
        assign(posf,name);
        oldmode:=filemode;
        filemode:=0;
        rewrite(posf);
        previous.avaus:=avaus;
        previous.positio:=position;
        previous.mnumber:=movenumber;
        previous.ep:=enpassant[1];
        previous.wtomove:=whitesturn;
        previous.wk:=mwk;
        previous.bk:=mbk;
        previous.wra:=mwra;
        previous.bra:=mbra;
        previous.wrh:=mwrh;
        previous.brh:=mbrh;
        write(posf,previous);
        close(posf);
      end;

      if (ord(ch)=62) then begin
        soundon:=(not soundon);
        if (soundon) then begin
          sound(300);owndelay(15);nosound;
        end
      end;
      if (ord(ch)=63) then begin
        viewscores:=(not viewscores);
        if (viewscores) then setcolor(blue)
        else setcolor(black);
        outtextxy(5,300,lstr);
      end;
      if (ord(ch)=61) then turn_board;
      if (ord(ch)=65) then setsqc;
      if (ord(ch)=66) then begin
      viewscores:=true;
      analysis:=(not analysis)
      end;
      if (ord(ch)=8) then begin
      gameover:=false;
    setcolor(black);
    outtextxy(20,220,' GAME');
    outtextxy(20,250,' OVER');
    outtextxy(5,300,lstr);
    lstr:='book';
    position:=previous.positio;
    avaus:=previous.avaus;
    movenumber:=previous.mnumber;
    enpassant[1]:=previous.ep;
    whitesturn:=previous.wtomove;
    mwk:=previous.wk;
    mbk:=previous.bk;
    mwra:=previous.wra;
    mbra:=previous.bra;
    mwrh:=previous.wrh;
    mbrh:=previous.brh;
    for aa:=1 to files do for cee:=1 to ranks do
   draw_piece(aa,cee,position[aa,cee]);
   update_movelist('   Takeback');
   writeln(gamef,' ');
   writeln(gamef,' OOPS!');
      writeln(gamef,' ');
      end;


      if (ord(ch)=64) then set_initial_pos(true);
      if (ord(ch)=60) then begin
        playeriswhite:=(not playeriswhite);
        analysis:=false
      end;
      if ((ord(ch) in [13,72,75,77,80]) and (not gameover))
      then players_move;

      for ii:=1 to ranks do for jj:=1 to files do
      if (position[jj,ii]=1) then begin
        wkx:=jj;wky:=ii
      end
      else if (position[jj,ii]=-1) then begin
        bkx:=jj;bky:=ii
      end;
      searchlegmvs(whitesturn,1);
      if (legals[1]<1) then gameover:=true;
      if (gameover) then begin
        settextstyle(defaultfont,horizdir,1);
  setcolor(black);
  outtextxy(0,250,kpstr);
  settextstyle(defaultfont,horizdir,2);
        setcolor(yellow);
        outtextxy(20,220,' GAME');
        outtextxy(20,250,' OVER');

        if (soundon) then begin
          sound(400);owndelay(15);nosound;
        end
      end;
      if (ch='+') then add_movetime;
      if (ch='-') then subtract_time;
    until ((ord(ch)=59) or (ord(ch)=27))
  until (ord(ch)=27);
  writeln(gamef,' ');
  writeln(gamef,' ');
  writeln(gamef,'End of games');
  close(gamef);
  closegraph;
  while (keypressed) do ch:=readkey;

  writeln('                    You have played FREEWARE program NERO 5.');
  writeln('                   Feel free to give it to your friends too!');
  writeln;
  writeln('                             Send your feedback to:');
  writeln;
  writeln('                              <huikari@mit.jyu.fi>');
  writeln('                                       OR');
  writeln('          Jari Huikari, Jenkkakuja 1 B 34, 40520  JKL, FINLAND, EUROPE');
  writeln;
  ch:=readkey;
END.