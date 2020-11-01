
unit sound;

interface

procedure beep;

implementation

{$ifdef unix}
uses
  alsa_sound; (* https://github.com/fredvs/alsa_sound *)
{$endif}

procedure beep;
begin
{$ifdef unix}
  ALSAbeep1;
{$endif}
end;

end.
