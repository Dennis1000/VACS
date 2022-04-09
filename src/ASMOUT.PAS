{$R-,B-,S-,N-,A+}
unit asmout;

interface

uses asmvar;

procedure HexStart (i: integer);
procedure PrintHead;
procedure PrintLine;
procedure AppendOut (aByte: integer);
procedure ForceOut;
procedure WriteEOF (FileLevel: integer);
procedure WriteByte (aByte: integer);
procedure ListIdents;
procedure CountUnused;
procedure PadOrg(HOutPntr, OldHOutPntr: longint);

implementation

{
  This file contains the output  functions for the ASM assemblers.
  Both the output to the  object and  list files  is handled here.

  filename:   OUTPUTFN.PAS           must be included in: ASM.PAS

  written by: ir. A.C.Verschueren         date: November 20, 1987
  V1.13 changes by W.H. Taphoorn

  this program donated to the public domain,       November 1987.

  Added from V1.10:
  Motorola S1-S9 Hex file generation.
  Load address modification possibility for object files.
  Continuous list file (no paging) if pagelength set to 255.
  Line numbering in list file.

  No changes for V1.11 in this file.

  Added from V1.12:
  Current filename will be placed in listing when using /E option
       or while NOLST is active and error is detected.

  Added from V1.13:
  Tektronix HexFormat implemented as option /T
}


var
  BufferCount: Integer;

procedure WriteBinary(outString: ShortString);
var
  buffer: array [0..4096] of byte;
  bufferc: integer;
  c: integer;
  b: Byte;
  s: ShortString;


begin
 bufferc := 0;
 delete(OutString,1,8);
 if (length(OutString)>1) then
 begin
   delete(OutString,length(OutString)-1,2);
 end;

 while length(OutString)<>0 do
 begin
   s := '$'+copy(OutString,1,2);
   delete(OutString,1,2);
   val (String(s),b,c);
   buffer[bufferc] := b;
   inc(bufferc);
 end;
 blockwrite (OutFileBinary, buffer[0],bufferc);
 inc(bufferCount,bufferc);
end;


procedure WriteBinaryPadding;
var
  buffer: array [0..1023] of byte;
  kBlocks: Integer;
  PadBytes: integer;
  i: integer;
begin
  fillchar(buffer,1024,BinaryPadByte);

  PadBytes := BinaryPad-BufferCount;
  if (PadBytes>0) then
  begin
    kBlocks := PadBytes div 1024;
    PadBytes := PadBytes mod 1024;

    for i:= 1 to kBlocks do
      blockwrite(OutFileBinary,buffer[0],1024);
    blockwrite(OutFileBinary,buffer[0],PadBytes);
  end;

end;


{ Procedure to place a byte as two hex characters in the StartLine
  string (printed in front of the input text in the list file).
  Placing starts at StLinePntr (incremented by 2 afterwards).
}

procedure HexStart (i: integer);

begin
if Pass = Second then
  if StLinePntr < 17 then
    begin
      StartLine[StLinePntr] := HexString[((i shr 4) and 15)];
      StartLine[StLinePntr + 1] := HexString[(i and 15)];
      StLinePntr := StLinePntr + 2;
    end;
end; { HexStart }


{ Procedure to keep track of the number of printed lines for the
  list file, and generate a form feed and page heading when needed.
  If LineCntr > 0, then only a heading is produced (first page).
  If LineCntr = 0, then a FF and a heading are produced (EJECT).
  If PageLength = 255, then only one heading is printed (V1.10).
}

procedure PrintHead;
begin
  if PageLength < 255 then   { paging done }
    if LineCntr > (PageLength - 6) then
      LineCntr := 0       { end of page reached }
    else
      if LineCntr > 0 then
        inc (LineCntr);
                             { not at end of page }
  if LineCntr < 1 then
    begin
      if LineCntr = 0 then
        write (ListFile,#12,#13)  { FF and CR }
      else
        write (ListFile,#13);     { CR to print from left paper edge }
      write (ListFile, LMargStr,'VACS ', ProcFamily + Version,'  ', TitleLine);
      if PageLength < 255 then
         writeln (ListFile,' Page ', PageCntr)
      else
        writeln (ListFile,'');
      LineCntr := 2;
      if length (SbTitleLine) > 0 then
        begin
          writeln (ListFile, LMargStr, SbTitleLine);
          inc (LineCntr);
        end;
      writeln (ListFile);
      inc (PageCntr);
    end;
end; { PrintHead }

{ The following procedure sends a line to the list file, including
  the StartLine string (containing the compiled code) and the Errors[]
  array. The textline is 'folded' (printed on several lines) if it
  cannot be printed on a single line.
  Printing only done during the second pass, if not suppressed with
  NOLST or /E (these are overridden by the presence of one or more
  errors in the line).
  LineNumber printed if enabled by /N flag (V1.10).
  Filename printed if NOLST or /E and error detected (V1.12).
}

procedure PrintLine;
var i, j, k    : integer;
    NumString : ShortString;
begin
  if (not (DontPrint or (ListStatus <> Full)) or (NrOfErrors > 0))
     and (Pass = Second) then
    begin
      if (DontPrint or (ListStatus <> Full)) and CurrFileNew then
                             { error forces printing of line, first time
                               since (re-)entering current file }
        begin
          PrintHead;         { V1.12: print name of current file }
          writeln (ListFile, LMargStr, 'Error(s) in ', CurrFileName,' :');
          CurrFileNew := FALSE;
                             { only print this message once for each change
                               of current file }
        end;
      PrintHead;
      if EnaLineNum then
        begin
          Str (LineNumber, NumString);

          NumString := ShortString(copy ('000', length (NumString), 4) + String(NumString) + ' ');
          write (ListFile, LMargStr, NumString, StartLine);
          k := PageWidth - 23;
        end
      else
        begin
          write (ListFile, LMargStr, StartLine);
          k := PageWidth - 18;
        end;
      if FoldEnable or (NrOfErrors > 0) then
        while length (CurLine) > k do
          begin              { print one part of a folded line }
            i := length (CurLine);
            CurLine[0] := AnsiChar (k);
            writeln (ListFile, CurLine);
            PrintHead;
            if EnaLineNum then write (ListFile,'     ');
                             { 'pre-indent' the next write statement }
            write (ListFile, LMargStr,'              --> ');
            for j := 1 to (i - k) do
              CurLine[j] := CurLine[j + k];
            CurLine[0] := AnsiChar (i - k);
          end { then while }
      else
        if length (CurLine) > k then
          CurLine[0] := AnsiChar (k);

              { print the remainder of the line if folded,
                the complete line if it fits, or the first
                part if not folded }

      writeln (ListFile, CurLine);

      for i := 1 to NrOfErrors do
        begin
          PrintHead;
          if EnaLineNum then write (ListFile,'     ');
          { 'pre-indent' the next write statement }

          { prefix is total of 18 chars }

          if Errors[i].code = 0 then
            writeln (ListFile, LmargStr,'     ** ERROR **  ', Errors[i].txt)
          else
            writeln (ListFile, LmargStr,'     ** WARNING **', Errors[i].txt);
        end;
    end;
  DontPrint := FALSE;        { re-enable printing of the next line }
end; { PrintLine }

{ The following procedure stores a byte as two hex characters in the
  string HOutString, to be sent to the object file by ForceOut.
  Placing starts at HOStringPntr (incremented by 2).
}

procedure AppendOut (aByte: integer);

var l, h : byte;

begin
  h := (aByte shr 4) and 15;
  l := aByte and 15;

  HOutString[HOStringPntr] := HexString[h];
  HOutString[HOStringPntr + 1] := HexString[l];

  { adjust checksum accumulator }

  if HexFormat = Tektronix then
    HOutCheck := HOutCheck + h + l
  else
    HOutCheck := HOutCheck + aByte;

  HOStringPntr := HOStringPntr + 2;

end; { AppendOut }

{ The following procedure completes HOutString by inserting the
  number of bytes and the checksum as two pairs of hexadecimal
  characters, sends the completed string to the object file and
  prepares HOutString to receive the next byte.
}

procedure ForceOut;
var SumLocation  : integer;
begin
  if NrOfHexBytes > 0 then   { HOutString is not empty }
    begin
      SumLocation := HOStringPntr;
      if HexFormat = Tektronix then
        begin
          HOStringPntr := 5;
          SecondSum := HOutCheck;
          HOutCheck := 0;
        end
      else
        HOStringPntr := 1;
      if HexFormat = Motorola then
        AppendOut (NrOfHexBytes + 3)
      else
        AppendOut (NrOfHexBytes);    { insert '# data bytes' byte }
                             
      if HexFormat = Tektronix then
        begin
          AppendOut (lo (FirstSum + HOutCheck));
          HOutCheck := SecondSum;
        end;
      HOStringPntr := SumLocation;
      HOutString[0] := AnsiChar (SumLocation + 1);
                             { set number of bytes in HOutString }
      case HexFormat of

        Intel:      begin
                      AppendOut (lo (- HOutCheck));
                      writeln (OutFile,':', HOutString);
                      if BinaryFormat then
                        WriteBinary(HOutString);
                    end;

        Motorola:   begin
                      AppendOut (lo (not HOutCheck));
                      writeln (OutFile,'S1', HOutString);
                    end;

        Tektronix:  begin
                      AppendOut (lo (HOutCheck));
                      Writeln (OutFile,'/', HOutString);
                    end;

        end; { case}


      NrOfHexBytes := 0;
      HOutCheck := 0;

    end;
end;

{ the following procedure terminates the object file correctly
  if the end of the main input file is found.
}

procedure WriteEOF (FileLevel: integer);
begin
  if FileLevel = 0 then
    begin
      ForceOut;
      if EndRecord then    { write end of file record }
        begin
          if HexFormat = Tektronix then
            HOStringPntr := 1
          else
            HOStringPntr := 3;

          HOutCheck := 0;
          AppendOut (hi (CurExpVal));
          AppendOut (lo (CurExpVal));

          case HexFormat of

                 Intel   :  begin
                              AppendOut (1);
                              HOStringPntr := 1;
                              AppendOut (0);
                              HOStringPntr := 9;
                              AppendOut (lo (- HOutCheck));
                              HOutString[0] := chr (10);
                              writeln (OutFile,':', HOutString);
                              if BinaryFormat then
                              begin
                                WriteBinary(HOutString);
                                WriteBinaryPadding;
                              end;
                            end;

                 Motorola:  begin
                              HOStringPntr := 1;
                              AppendOut (3);
                              HOStringPntr := 7;
                              AppendOut (lo (not HOutCheck));
                              HOutString[0] := chr (8);
                              writeln (OutFile,'S9', HOutString);
                            end;

                 Tektronix: begin
                              AppendOut (0);          { bytes = 00 }
                              AppendOut (lo (HOutCheck)); { checksum }
                              HOutString[0] := chr (8);
                              writeln (OutFile,'/', HOutString);
                            end;

                 end; { case }
        end;
    end

  else

    StartLine := '** END INCLUDE ** ';

end; { WriteEOF }

{ The following procedure sends the given byte to both the StartLine
  string (for printing in the list file) and the HOutString (the
  buffer for the object file).
  This routine should be called for each object code byte generated.
}

procedure WriteByte (aByte: integer);
begin
  if Pass = Second then
    begin
      HexStart (aByte);       { print byte in list file }
      if (NrOfHexBytes = 0) or (NrOfHexBytes = 16) or
         ((HOutAddr + OldLoadOffs) <> (HOutPntr + LoadOffset)) then
                             { HOString is empty, full or not at the
                               correct address }
        begin

          ForceOut;          { send old HOString to object file }

          if HexFormat = Tektronix then
            HOStringPntr := 1
          else
            HOStringPntr := 3; { store load address in new HOString }

          AppendOut (hi (HOutPntr + LoadOffset));
          AppendOut (lo (HOutPntr + LoadOffset));

          if HexFormat = Tektronix then
            begin
              HOStringPntr := 9;     { move pointer to data section }
              FirstSum := HOutCheck; { remember part of 1st checksum }
              HOutCheck := 0;        { reset checksum counter }
            end;

          if HexFormat = Intel then
            AppendOut (0);      { 'record type' byte is 0 (data record) }
        end;

      AppendOut (lo (aByte));   { store data byte in HOString }
      inc (NrOfHexBytes);

    end;
  inc (HOutPntr);               { assumed address of next object byte,
                                  can be changed by ORG or DEFS/DS }
  HOutAddr    := HOutPntr;      { addr. of next byte if sent to HOString }
  OldLoadOffs := LoadOffset;    { remember current LoadOffset }

  ModuleSum   := ModuleSum + (aByte and 255);

end;

{ procedure to list the identifiers alphabetically, using
  the fact that the identifiers in a group are already
  sorted, on first character in the IdentArray[] array, and
  further in the linked lists built by GetToken.
}

procedure ListIdents;

var ArrayPntr   : integer;
    ListPntr    : IdentPtr;

  procedure PrintIdent;      { print name, type and contents of identifier }
  var i   : integer;

  begin
    PrintHead;
    with ListPntr^ do
      begin
        write (ListFile, LMargStr, Name,
                                copy (DotString, length (Name) + 1, 32),' = ');
          if (Typ = Ident)
              or (Typ = SetIdent)
              or (Typ = Segment)
              or (Typ = StrIdent)
              or (Typ = UserIdent) then
            begin                { value identifier found }
              case Typ of
                UserIdent: write (ListFile, UserIDName);
                Ident:     if Def and Global = Global then
                             write (ListFile,'Global   ')
                           else
                             write (ListFile,'Value    ');
                SetIdent:  write   (ListFile,'SETvalue ');
                Segment:   write   (ListFile,'Section  ');
                StrIdent:  write   (ListFile,'String   ');
              end; {case Typ}

              if Def <> NotYet then
                begin
                  if Typ <> Segment then
                    write (ListFile, HexEightStr (Val))
                  else
                    write (ListFile, HexFourStr (Val));
                  if Typ = Segment then
                    begin
                      if LocPtr = Val then
                        write (ListFile,' Empty')
                      else
                          write (ListFile, '-', HexFourStr (LocPtr - 1));

                      case Rel of
                        AbsRel:   writeln (ListFile,' (Absolute)');
                        ByteRel:  writeln (ListFile,' (Byte)'    );
                        PageRel:  writeln (ListFile,' (Page)'    );
                        InPageRel:writeln (ListFile,' (Inpage)'  );
                      end { case }
                    end

                  else 

                    if (Typ = Ident) and (Def = Global) then
                      writeln (ListFile,' (Unbound)')
                    else
                      if (typ = Ident) and (RefTo = FALSE) then
                          writeln (ListFile,' (not used)')
                      else
                        writeln (ListFile,'');
                end

              else
                writeln (ListFile,'Undefined');
            end

          else          { reg or opcode identifier }

            begin
              i := 1;
              while ((Patterns[i].Typ <> Typ) or (Patterns[i].Val <> Val)) and
                    (i < NrOfPatt)
                do inc (i);

              if Typ = Register then
                writeln (ListFile,'Register ', Patterns[i].Name)
              else
                writeln (ListFile,'Opcode   ', Patterns[i].Name);

            end;

      end; { with .. do }

  end; { PrintIdent }

begin { ListIdents }

  CurSegment^.LocPtr := HOutPntr;   { update last used segment end }
  if LineCntr <> -1 then
    if PageLength < 255 then
      LineCntr := 0          { start at top of page }
    else                     { generate intermediate heading, NO FORMFEED }
      begin
        WriteLn (ListFile);   { add an empty line before heading }
        dec (LineCntr);        { force intermediate heading }
      end;

  SbTitleLine := 'List of Identifiers';

  { list default section (if used ) }

  if DefaultSeg^.Val <> DefaultSeg^.LocPtr then
    with DefaultSeg^ do
      begin
        PrintHead;
        write (ListFile, LMargStr,
                      DefaultSeg^.Name,
                      copy (DotString, length (DefaultSeg^.Name) + 1, 32),
                      ' = Section  ');
        writeln (ListFile, HexFourStr (Val), '-', HexFourStr (LocPtr - 1),
                          ' (Byte)');
    end;

  { print sections only }

  for ArrayPntr := 0 to 28 do
    begin
      ListPntr := IdentArray[ArrayPntr];
      while ListPntr <> NIL do
         begin
           if ListPntr^.Typ = Segment then
             PrintIdent;               { print section data }
           ListPntr := ListPntr^.next; { get next record }
         end;
    end;                     { FOR loop end }

  { print all but sections }

  for ArrayPntr := 0 to 28 do
    begin
      ListPntr := IdentArray[ArrayPntr];
      while ListPntr <> NIL do
         begin
           if ListPntr^.Typ <> Segment then
             PrintIdent;               { print identifier data }
           ListPntr := ListPntr^.next; { get next record }
         end;
    end;                     { FOR loop end }
end; { ListIdents }

procedure CountUnused;
var i         : integer;
    ListPntr  : IdentPtr;

begin
  Unused := 0;
  if EnaUnused then
    for i := 0 to 28 do
      begin
        ListPntr := IdentArray[i];
        while ListPntr <> NIL do
          begin
            with ListPntr^ do
              if (Typ = Ident) and (RefTo = FALSE) and (Def <> NotYet) then
                inc (Unused);
            ListPntr := ListPntr^.next; { get next record }
          end;
      end;

end;


procedure PadOrg(HOutPntr, OldHOutPntr: longint);
var
  buffer: array [0..1023] of byte;
  Blocks: Integer;
  PadBytes: integer;
  I: integer;
begin
  if Pass <> Second then
    Exit;

  if OldHOutPntr >= HOutPntr then
    Exit;

  ForceOut;          { send old HOString to object file }

  fillchar(buffer,1024,BinaryPadByte);

  PadBytes := HOutPntr - OldHOutPntr;
  if PadBytes <= 0 then
    Exit;

  Blocks := PadBytes div 1024;
  PadBytes := PadBytes mod 1024;

  for I := 1 to Blocks do
    blockwrite(OutFileBinary, buffer[0], 1024);

  blockwrite(OutFileBinary, buffer[0], PadBytes);
end;

begin
  BufferCount := 0;
end.
