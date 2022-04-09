unit dos;


interface


type
 ComStr      = String;
 PathStr     = String;
 extstr      = String;
 dirstr      = String;
 NameStr     = String;

procedure fsplit (Path: string; var d, n, e : string);
procedure GetCbreak (OldBreak: Boolean);
procedure SetCBreak (Break: Boolean);
procedure SetIntVec (Vec: Integer; P: Pointer);
function fexpand (Path: PathStr): PathStr;
procedure GetDate (var Year, Month, Day, WeekDay: word);
procedure GetTime (var Hour, Minute, Sec, Sec100: word);

implementation

uses sysutils;

procedure fsplit (Path: string; var d, n, e : string);
begin
  d := ExtractFilePath(path);
  e := ExtractFileExt(path);
  n := ExtractFileName(Path);
  if e <> '' then
    n := Copy(n,1,length(n)-length(e));
end;

procedure GetCbreak (OldBreak: Boolean);
begin
end;

procedure SetCBreak (Break: Boolean);
begin
end;

procedure SetIntVec (Vec: Integer; P: Pointer);
begin
end;


function fexpand (Path: PathStr): PathStr;
var
  S: string;
begin
  if ExtractFilePath(Path)='' then
  begin
    GetDir(0, S);
    Path := S + '\'+Path;
  end;
  Result := Path;
end;


procedure GetDate (var Year, Month, Day, WeekDay: word);
begin
  DecodeDate(now, Year, Month, Day);
  Weekday := DayOfWeek(now) - 1;
end;


procedure GetTime (var Hour, Minute, Sec, Sec100: word);
begin
  DecodeTime(now, Hour, Minute, Sec, Sec100);
end;

end.
