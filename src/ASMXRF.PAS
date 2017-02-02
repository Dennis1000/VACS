{$R-,B-,S-,N-,A+}
unit asmxrf;

interface

uses   asmvar;

procedure XrfStart;

implementation

{
  file defining the XRF tpu for VACS V1.23 assemblers.

  filename:   ASMXRF.PAS              Version 1.23a

  written by: W.H. Taphoorn           Date: September 20, 1990

  this program donated to the public domain, xxxx, 1990.
}

procedure XrfStart;

var i,j,k : integer;
    p     : IdentPtr;


  begin

  writeln (XrfFile,'Module  ', ModName);

  { if default section is used, write default info }

  if DefaultSeg^.LocPtr <> DefaultSeg^.Val then
    with DefaultSeg^ do
      writeln (XrfFile, 'Section ', Name, ' %0 Byte',
               ' [', HexEightStr (Val), '-', HexEightStr (LocPtr -1), ']');

  { scan linked lists for sections }

  for i := 0 to 28 do
    begin
      p := IdentArray[i];
      while p <> NIL do
        begin
          if p^.Typ = Segment then
            with p^ do
              begin
                write (XrfFile,'Section ', Name,' ');
                write (XrfFile,'%', SegNum,' ');
                case Rel of
                      AbsRel:    write (XrfFile, 'Absolute');
                      ByteRel:   write (XrfFile, 'Byte');
                      PageRel:   write (XrfFile, 'Page');
                      InPageRel: write (XrfFile, 'Inpage');
                    end;
                writeln (XrfFile,
                    ' [', HexEightStr (Val), '-',HexEightStr (LocPtr -1),']');
              end;
          p := p^.next;
        end;
    end;


  { scan linked lists for other globals }

  for i := 0 to 28 do
    begin
      p := IdentArray[i];
      while p <> NIL do
        begin
          if (p^.Typ <> Segment) and (p^.Def and Global = Global) then
            with p^ do
              begin
                write (XrfFile, 'Global  ', Name);
                if Def = Global then
                  writeln (XrfFile)
                else
                  begin
                    write (XrfFile, ' = ');
                    if (SegNum >= 0) and (Rel <> AbsRel) then
                      write (XrfFile, '%', SegNum, '[');
                    write (XrfFile, HexEightStr (Val));
                    if (SegNum >= 0) and (Rel <> AbsRel) then
                      write (XrfFile, ']');
                    writeln (XrfFile);
                  end;
              end;
          p := p^.next;
        end;
    end;

  end;

begin
end.
