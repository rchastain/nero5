
unit log;

interface

uses
  sysutils;

procedure append(const atext: string; const asecondfile: boolean = false); overload;

implementation

const
  cdir = 'log';
  
var
  lfile: array[boolean] of text;
  llogcreated: boolean;
  
procedure openlog;
var
  lfilename: string;
  lidx: boolean;
begin
  lfilename := cdir + directoryseparator +
    formatdatetime('yyyymmddhhnnsszzz"-%d.log"', now);
  if directoryexists(cdir)
  or createdir(cdir) then
  begin
    for lidx := false to true do
    begin
      assign(lfile[lidx], format(lfilename, [ord(lidx)]));
      rewrite(lfile[lidx]);
    end;
    llogcreated := true;
  end else
    llogcreated := false;
end;

procedure closelog;
begin
  if llogcreated then
  begin
    close(lfile[false]);
    close(lfile[true]);
  end;
end;

procedure append(const atext: string; const asecondfile: boolean);
begin
{$ifdef createlog}
  if llogcreated then
  begin
    writeln(lfile[asecondfile], atext);
    flush(lfile[asecondfile]);
  end;
{$endif}
end;

{$ifdef createlog}
initialization
  openlog;

finalization
  closelog;
{$endif}

end.
