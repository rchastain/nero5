Unit Fdelay;              { Place this before CRT. Real mode only }
  interface
  const dfix:word=1;        { call delay() dfix times }

  implementation
  uses dos;

  procedure oldints; assembler; { "variables" in the code segment }
            asm dd 0,0 end;

  Procedure error;
  begin
    runerror(200);
  End;

  Procedure Int0; assembler;
            asm
            cmp cx,55       { If CX<>55 we are at some other point }
            je @ok
            sti
            call error
  @ok:
            shr dx,1        { divide dx:ax by 2 }
            rcr ax,1
            shl Dfix,1      { multiply Dfix by 2 }
            iret            { return to the DIV (286+) }
            end;

  { Int21h handler removes the int0 handler (as well as itself) from
    the memory when CtrlBreak vector is set by CRT right after
    calculating the delay counter. Note DS does NOT point to the data
    segment when this is called }

  Procedure Int21h; assembler;
            asm
            cmp ax,$251B
            jne @old               { Not setint 1Bh? }
            push es; push si; push di
            mov si,offset oldints
            xor di,di
            mov es,di
            cld
            segcs; movsw
            segcs; movsw           { restore int 0 }
            mov di,$21*4
            segcs; movsw           { restore int 21h }
            segcs; movsw
            pop di; pop si; pop es
  @old:     db $2e,$ff,$2e         { jmp far indirect cs:[oldints+4] }
            dw offset oldints+4
            end;

  type tr=record int0,int21:pointer; End;
       pr=^tr;

  begin
    GetIntVec(0,pr(@oldints)^.int0);
    GetIntVec($21,pr(@oldints)^.int21);
    SetIntVec(0,@int0);
    SetIntVec($21,@int21h);
  end.

