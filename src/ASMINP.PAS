{$R-,B-,S-,N-,A+}
unit asminp;

interface

uses
     types,          { the functions IsLabel, IsHex etc }
     asmvar,
     asmout,
     asmini;

procedure GetInp;

procedure SkipSpace;
procedure GetToken;
procedure GetQuoted (MaxLen: integer);
procedure SeekComma;
procedure NextLine;
procedure SetUserIdent (UserVal: longint);

implementation

{
  filename:   ASMINP.PAS

  This  file   contains  the  procedures  in  to  handle  the
  incoming data from the main and included input files.

  Changes in this file for version 1.10:
  GetToken  recognises $01 as hex, %01 as binary and &01 as octal.
  Characters in the range 80H..0FFH kept 'as is'.
  Keyboard checked for <CTRL><C> once per source line read.
  'forward' identifiers recognised (see main file).
  Handling of unrecognised characters improved.
  Line numbers counted.

  Changes for V1.11:
  Blockread used for reading the input file.

  Changes for V1.12:
  'SectorPos' used to keep track of the current block read with
        'blockread' (doing a 'longfilepos' before actually reading.

  written by: ir. A.C. Verschueren         date: November 20, 1987
 --------------------------------------------------------------------------

  V1.13 and later changes by W.H. Taphoorn
  
  Changes for V1.13:
  - speed-up all character checking IsXX functions.

  Additions for V1.20:
  - pre-processor in procedure NextLine

  V1.20 programs donated to the public domain,        December 1989.

  Changes for V1.21:
  - procedure SetUserIdent implemented for user-defined EQUs

  Changes for V1.23a:
  - IdenTillX construction changed by using single 0..28 array. Through
    use of other memory allocation constructs, each identifier record now
    will be allocated to fit the exact name length.
  - all IsXX character functions replaced by assembly routines.

  Changes for V1.23c:
  - (oops!) bug fixed in allocating memory for new identifiers.
}

{
 The following procedure checks for a line label identifier and if present
 sets Typ from Ident to UserIdent and sets Val to the parameter value.
 If no label identifier is given, an error is generated.
}

procedure SetUserIdent (UserVal: longint); { V1.21 }

begin
  if CurLabelDef then { V1.21: copy of DollarDef in ParseLine, TRUE if a }
    begin             {        label identifier was on the current line }
      if CurLabel^.Typ = Ident then
        begin
          CurLabel^.Val := UserVal;   { set user value }
          CurLabel^.Typ := UserIdent; { new typedef }
        end;
      if Pass = Second then { send '= <value>' to listing }
        begin
          StartLine[6] := '=';
          StLinePntr := 8;
          HexStart (hi (UserVal shr 16));
          HexStart (lo (UserVal shr 16));
          HexStart (hi (UserVal));
          HexStart (lo (UserVal));
        end;
      end
  else    { no label present on current line }
    begin
      ErrorPntr := 1;  { force marker to begin of line }
      StoError (0,'Missing Identifier');
    end;
end;


{ The following procedure  gets a character  from the current line
  string CurLine[], checking for the end of the line  (setting the
  EndOfLine flag accordingly).
  The character is stored in NormBuffer (unchanged) and LockBuffer
  (all letters in uppercase).
  The read pointer for CurLine (CurLinePntr) is pre-incremented.
}

procedure GetInp;
begin
  if CurLinePntr >= length (CurLine) then
    begin
      EndOfLine := TRUE;
      NormBuffer := #00;
      LockBuffer := #00;
      CurLinePntr := length (CurLine) + 1;
    end
  else
    begin
      inc (CurLinePntr);
      NormBuffer := CurLine[CurLinePntr];
      LockBuffer := upcase (NormBuffer);
    end;
end; { GetInp }

{ The following procedure skips spaces in the input line }

procedure SkipSpace;
begin
  while (not EndOfLine) and (LockBuffer = #$20) do
    GetInp;
end; {SkipSpace}

{ The following procedure is a general purpose lexical analiser,
  working with the arrays Patterns and IdentArray[].

  Builds IdentArray[] structure if BlockAll flag not set.
  All linked chains "hanging" from the IdentArray[] array are
  sorted in alphabetical order, all entries in a linked chain
  have the same starting character.

  Returns the result in the variables
    CurTyp : one of the Pattern .Typ possibilities,
    CurVal : value given to the token,
    CurDef : defined state of identifier tokens.
    CurForw: 'forward' definition state of identifier tokes.
}

procedure GetToken;
var SeekPtr,                 { vars for binary bisection }
    BottomPtr,
    BottomOld,
    TopPtr,
    TopOld,
    BackUpPtr,
    BackUpChar,
    FirstChar,
    LastChar,
    CharPtr,
    Ratio     : integer;          { vars for numerical constant extraction }
    Accu,
    Hulp      : longint;
    Seek,
    PrevHook,
    NextHook  : IdentPtr;    { V1.23a }
    BlockIt,
    FirstCL,                 { first token character OK for identifier }
    BlockOfCL,               { pattern can also be identifier }
    BackUpCL  : boolean;     { backup pattern can also be identifier }

label 111,222;


begin { GetToken }
111:
  if not EndOfLine then
    SkipSpace;
  ErrorPntr := CurLinePntr;
  FirstChar := CurLinePntr;

  //1.24i Initialize unitialized variables.
  SeekPtr := 0;
  Ratio := 0;
  BackUpChar := 0;
  BackUpCL := False;

  if EndOfLine then
    CurTyp := EndLine
  else
    begin
      CurForw := FALSE;        { no identifier found yet, cannot be 'forward' }
      if (LockBuffer = '$') or (LockBuffer = '&') or (LockBuffer = '%')
          {or (LockBuffer = 'X')} then // v1.24d
        begin

          case LockBuffer of
            '$'{,'X'}: Ratio := 16; // v1.24d
            '&': Ratio := 8;
            '%': Ratio := 2;
            end; { case }
          GetInp;

          while IsHex (LockBuffer)  { skip over digits }
            do GetInp;

          if IsLabel (LockBuffer) or (CurLinePntr = (FirstChar + 1)) then
                    { no digits given, or is a label }
                    { reset read pointer to FirstChar location }
            begin
              CurLinePntr := FirstChar;
              EndOfLine := FALSE;
              NormBuffer := CurLine[CurLinePntr];
              LockBuffer := NormBuffer;
            end
          else                  { nummeric found }
            begin
              inc (FirstChar);  { skip ratio indicator }
              LastChar := CurLinePntr - 1;
              goto 222;  { this saves a LOT of begin..end blocks here ! }
            end;
        end;

      { ---- Token is not starting $, & or % ---------------------------- }

      if IsDigit (LockBuffer) then          { numerical constant found }
        begin
          while IsHex (LockBuffer)
            do GetInp;
          LastChar := CurLinePntr - 1;
          Ratio := 10;         { assume decimal number system }

          case LockBuffer of   { determine number system }
            'H': begin
                  Ratio := 16;
                  GetInp;
                end;
            'O': begin
                  Ratio := 8;
                  GetInp;
                end;
            'Q': begin
                  Ratio := 4;
                  GetInp;
                end;
            else  { check D or B indicators (misinterpreted as hex?) }
              case upcase (CurLine[LastChar]) of
                'D': begin
                      Ratio := 10;
                      dec (LastChar);
                    end;
                'B': begin
                      Ratio := 2;
                      dec (LastChar);
                    end;
              end; {case CurLine[...]}
          end; {case LockBuffer}

222 :    Accu := 0;           { initialise accumulator }
          repeat               { calculate number }
            Hulp := ord (upcase (CurLine[FirstChar]));
            if Hulp < 65 then
              Hulp := Hulp - 48
            else
              Hulp := Hulp - 55;
            if Hulp < Ratio then
              begin
                Accu := Accu * Ratio + Hulp;
                inc (FirstChar);
              end
            else FirstChar := 257;
          until FirstChar > LastChar;

          if FirstChar = 257 then { digit not in selected number system }
            begin
              CurTyp := UnDef;
              CurVal := 0;
              CurDef := FALSE;
              StoError (0,'Number Error');
            end
          else      { correct numerical constant found }
            begin
              CurTyp := Constant;
              CurVal := Accu;
              CurDef := TRUE;
            end;
        end

      else  { not IsDigit, must be token or identifier }

        begin
          CurTyp := Ident;     { search loop terminator flag,
                                IT IS NOT POSSIBLE TO 'STOPATT' IDENTIFIERS }
          BottomPtr := 1;      { initialise bisection pointers }
          BottomOld := 1;
          TopPtr := NrOfPatt;
          TopOld := NrOfPatt;
          CharPtr := 1;
          BackUpPtr := 0;
          FirstCL := IsLabel (LockBuffer);
          BlockOfCL := FirstCL;
          //BlockIt := FALSE;  // Value assigned never used

          while CurTyp = Ident do
            begin                { start/continue searching }

              { set binary search window }

              SeekPtr := BottomPtr + ((TopPtr - BottomPtr) shr 1);

              { seek char in current window }

              while (Patterns[SeekPtr].Name[CharPtr] <> LockBuffer) and
                    (BottomPtr < TopPtr) do
                begin
                  if Patterns[SeekPtr].Name[CharPtr] < LockBuffer then
                    BottomPtr := SeekPtr + 1
                  else
                    TopPtr := SeekPtr;
                  SeekPtr := BottomPtr + ((TopPtr - BottomPtr) shr 1);
                end;

              if (Patterns[SeekPtr].Name[CharPtr] <> LockBuffer) then
                          { search failed }
                if BackUpPtr > 0 then
                        { search failed, but there was a candidate }
                  begin
                    CurLinePntr := BackUpChar;
                    NormBuffer := CurLine[CurLinePntr];
                    LockBuffer := upcase (NormBuffer);
                    EndOfLine := FALSE;
                    BlockOfCL := BackUpCL and IsLabel (LockBuffer);
                    if BlockOfCL then { pattern at start of identifier }
                      CurTyp := Undef
                    else         { pattern found that is start of other pattern }
                      with Patterns[BackUpPtr] do
                        begin
                          CurTyp := Typ;
                          CurVal := Val;
                          CurDef := TRUE;
                        end;
                    end
                else
                                { search failed, there was no backup candidate }
                  CurTyp := Undef

              else             { search hitted the character }

                begin

                   { expand binary search window if possible }

                  BottomPtr := SeekPtr;
                  while (BottomPtr > BottomOld) and
                        (Patterns[BottomPtr - 1].Name[CharPtr] = LockBuffer)
                    do
                      dec (BottomPtr);

                  TopPtr := SeekPtr;
                  while (TopPtr < TopOld) and
                        (Patterns[TopPtr + 1].Name[CharPtr] = LockBuffer)
                    do inc (TopPtr);

                  BottomOld := BottomPtr;
                  TopOld := TopPtr;

                  GetInp;        { read next character for comparison }

                  if EndOfLine then { no characters are following }
                    if length (Patterns[BottomPtr].Name) = CharPtr then
                        { full pattern found at end of line }
                      with Patterns[BottomPtr] do
                        begin
                          CurTyp := Typ;
                          CurVal := Val;
                          CurDef := TRUE;
                        end
                    else
                                { no pattern match at end of line }
                      Curtyp := Undef

                  else
                    begin   { end of line not reached, search continues }

                      BlockIt := BottomPtr = TopPtr;
                      if length (Patterns[BottomPtr].Name) = CharPtr then
                            { found possible candidate with current pattern }
                        begin
                          BackUpCL := BlockOfCL;
                          BackUpPtr := BottomPtr;
                          BackUpChar := FirstChar + CharPtr;
                          if not BlockIt then
                            inc (BottomOld);
                        end;

                      BlockOfCL := BlockOfCL and IsLabel (LockBuffer);
                      BottomPtr := BottomOld;

                      if (not BlockIt) or
                         (CharPtr < length (Patterns[TopPtr].Name)) then
                           inc (CharPtr)
                                { there is a window or not at end of pattern }

                      else       { full pattern match }

                        if BlockOfCL then
                          CurTyp := Undef { pattern start of identifier ? }
                        else     { pattern cannot be start of identifier }
                          with Patterns[SeekPtr] do
                            begin
                              CurTyp := Typ;
                              CurVal := Val;
                              CurDef := TRUE;
                            end;
                    end;
                end;
            end;

          if (CurTyp = UnDef) and FirstCL then

                               { no pattern found, must be identifier }
            begin              { reset read pointers to start of identifier }

              CurLinePntr := FirstChar;
              NormBuffer := CurLine[CurLinePntr];
              LockBuffer := upcase (NormBuffer);
              EndOfLine := FALSE;
              LastChar := 0;   { lastchar misused for name length }

              while IsLabel (LockBuffer) do
                begin          { read and calculate name length }
                  if LastChar < 32 then
                    begin
                      inc (LastChar);
                      SeekStr[LastChar] := LockBuffer;
                    end;
                  GetInp;
                end;

              SeekStr[0] := AnsiChar (LastChar);

              { initialise for identifier search: }

              case SeekStr[1] of
                  '$'      : SeekPtr := 0;
                  '@'..'Z' : SeekPtr := ord (SeekStr[1]) - 63;
                  '_'      : SeekPtr := 28;
                end;
              Seek     := IdentArray[SeekPtr];
              PrevHook := NIL; 
              CurDef   := TRUE;
              //FirstCL  := TRUE; // Value assigned never used

              { search linked list until last record found,
                                 or Name >= name to search: }

              while (Seek <> NIL) and (Seek^.Name < SeekStr) do
                begin
                  PrevHook := Seek;
                  Seek := Seek^.Next;
                end;

              if (Seek = NIL) or (Seek^.Name <> SeekStr) then
                if BlockAll then
                  CurDef := FALSE
                else    { insert before this record }
                  begin
                    NextHook := Seek; { save trailing list }
                    getmem (Seek, IdentRecSize + ord (SeekStr[0]));
                    with Seek^ do
                      begin
                        Val  := 0;
                        if BlockRefTo = TRUE then
                          RefTo := FALSE  { no references to new label }
                        else
                          RefTo := TRUE;
                        Def  := NotYet;
                        Name := SeekStr;
                        Typ  := Ident;
                        SegNum := CurSegment^.SegNum;
                        Next := NextHook;  { append trailing list }
                      end;

                    { hook new record to leading list or IdentArray }

                    if PrevHook = NIL then
                      IdentArray[SeekPtr] := Seek
                    else
                      PrevHook^.Next := Seek;
                  end;

              if CurDef then   { read data from identifier record: }
                begin
                  CurIdent := Seek;
                  with CurIdent^ do
                    begin
                      CurVal  := Val;
                      CurTyp  := Typ;
                      CurDef  := Def <> NotYet;
                      CurForw :=(  ((Pass = First ) and ((Def and FPass) = 0))
                                or ((Pass = Second) and ((Def and SPass) = 0))
                                );
                      if BlockRefTo = FALSE then
                        RefTo := TRUE;  { reference to  label }
                    end;
                end
              else     { BlockAll blocked definition of new identifier: }
                begin
                  CurTyp := Ident;
                  CurVal := 0;
                  CurIdent := NIL;
                end;
            end
          else
            if CurTyp = Undef then
              begin
                StoError (0,'Unrecognised Character');
                GetInp;
                goto 111;      { strange character skipped, try again ! }
              end;
        end;
    end;
                             { do some administration: }

  if CurTyp = EndLine then
    EndOfLine := TRUE;

  if (CurTyp = Operand) and (CurVal = Quote) then
    QuoteChar := CurLine[ErrorPntr];

end; {procedure GetToken}

{ The following procedure gets a quoted string into the variable
  CurQuoted. Assumes the first quote is already read by GetToken
  and placed in QuoteChar.

  Two quotes are stored as a single quote, error indicated if
  string is of zero length or not terminated by setting the length
  of CurQuoted to 0.
  Calls GetToken after processing.
}

procedure GetQuoted (MaxLen: integer);
var i         : integer;
    EndQuoted : boolean;

begin { GetQuoted }
  i := 1;
  EndQuoted := FALSE;

  while not (EndQuoted or EndOfLine) do
    begin
      if NormBuffer <> QuoteChar then
        begin
          CurQuoted[i] := NormBuffer;
          inc (i);
          GetInp;
        end
      else
        begin
          GetInp;
          if EndOfLine or (NormBuffer <> QuoteChar) then
            EndQuoted := TRUE
          else
            begin
              CurQuoted[i] := QuoteChar;
              inc (i);
              GetInp;
            end;
        end;
    end;

  dec (i);
  CurQuoted[0] := chr (0);

  if (i > MaxLen) and EndQuoted then
    begin
      ErrorPntr := CurLinePntr - 2;
      StoError (0,'String Too Long');
    end
  else
    if not EndQuoted then
      begin
        ErrorPntr := CurLinePntr;
        StoError (0,'Unterminated String');
      end
    else
      if i = 0 then
        begin
          ErrorPntr := CurLinePntr - 1;
          StoError (0,'Zero Length String');
        end
      else
        CurQuoted[0] := AnsiChar (i);
  GetToken;
end; { GetQuoted }

{ the following procedure is used by the expression list handlers
  (DEFM, DEFB, DEFW, TABS etc.) to recover from an error in one of
  the items in the list.
}

procedure SeekComma;
begin
  if not (((CurTyp = Operand) and (CurVal = Comma)) or EndOfLine) then
    begin
      StoError (0,'Excess Data');
      repeat
        if (CurTyp = Operand) and (CurVal = Quote) then
          GetQuoted (255)
        else
          GetToken;
      until ((CurTyp = Operand) and (CurVal = Comma)) or EndOfLine;
    end;
end; { SeekComma }

{ the following procedure reads a line of text from the current
  input file (from CurSector into CurLine). Handles reading of the
  next sector, tab (and other control-) characters, initialisation
  of StartLine and HOutString strings.

  V1.10: check once per line read for input of <CTRL><C> (user break)
          (function changed per V1.23a)
  V1.20: performs text replacement between backquotes
  V1.23a: user interrupt check changed, type-ahead buffer not flushed.
          new errortrapping (ASMINI.PAS) sets the flag 'Interrupted'.
}

procedure NextLine;
var i       : integer;
    CurChar : AnsiChar;
    RepLine : string[255];
    RepPntr : integer;
    SavPntr : integer;

  procedure GetByte;         { reads a byte from the input file, skipping
                               LF characters }
  begin { GetByte }
    repeat
      if SectorPntr = 512 then
        begin                { V1.12: strategy change for reading InFile }
          SectorPos := filepos (InFile);
          blockread (InFile, CurSector, 512, SectorCont);
          SectorPntr := 0;
        end;
      CurChar := CurSector[SectorPntr];
      EndOfFile := (CurChar = #26) or
                   ((SectorCont < 512) and (SectorPntr = SectorCont));
      if not EndOfFile then
        inc (SectorPntr);
    until (CurChar <> #10) or EndOfFile;
  end; { GetByte }

begin { NextLine }

  if Interrupted then         
    GetSetBreak (FALSE, 1);  { V1.23a see ASMINI.PAS }

  ErrorPntr := 1;            { display errors found here at start of line }
  NrOfErrors := 0;           { no errors on this line yet }
                             { NormBuffer, LockBuffer has 1st character }
  CurLinePntr := 0;          { reset read pointer }

  if Pass = First then        { count the total number of lines (V1.10) }
    inc (TotLines)
  else
    LineNumber := (LineNumber + 1) mod 10000;
                             { count the line numbers (V1.10) }

  DollarPntr := HOutPntr;    { DollarPntr is location counter }
  GetByte;                   { get first byte }

  if EndOfFile then          { missed the end statement altogether ! }
    begin
      CurLine := '';
      StoError (0,'Missing END Statement');
      CurTyp := Opcode;      { mimick finding of 'END' }
      CurVal := EndFile;
      GetInp;                { sets EndOfLine }
    end
  else                       { not at end of file }
    begin
      if Pass = First then

        begin                { read line without tabs expansion: }
          i := 1;
          while not EndOfFile and (CurChar <> #13) and (i < 256) do
            begin
              if (ord (CurChar) and 240) = 0 then
                             { changed V1.10: only 0..31 are control chars }
                CurLine[i] := ' '
              else
                CurLine[i] := CurChar;

              inc (i);
              GetByte;
            end;

          CurLine[0] := AnsiChar (i - 1);
          while not EndOfFile and (CurChar <> #13)
            do GetByte;        { line too long, read until CR found }
        end

      else      { pass = second }

        begin                { read line with tabs expansion: }
          StartLine := '                  ';
          StLinePntr := 1;
          HexStart (hi (DollarPntr));
          HexStart (lo (DollarPntr));
          StLinePntr := 6;   { StartLine initialised }
          CurLine := TabLine;
          i := 1;            { copy data from CurSector, expanding tabs: }
          while not EndOfFile and (CurChar <> #13) and (i < 256) do
            begin
              if CurChar = #09 then
                repeat
                  CurLine[i] :=  ' ';
                  inc (i);
                until (i > 254) or (CurLine[i] <> ' ')
              else
                begin
                  if (ord (CurChar) and 240) = 0 then
                             { changed V1.10: only 0..31 are control chars }
                    CurLine[i] := ' '
                  else
                    CurLine[i] := CurChar;
                  inc (i)
                end;
              GetByte;
            end;

          CurLine[0] := AnsiChar (i - 1);
          if (i > 255) and (CurChar <> #13) then
            begin            { line is too long to be handled }
              StoError (0,'Line Too Long');
              while not EndOfFile and (CurChar <> #13) do
                getByte;    { read remainder of line }
            end;
        end;

      EndOfline := FALSE;
      
      if PreProcess then  { V 1.20 start pre-processor } 
        begin
          RepLine := '';
          RepPntr := 1;
          repeat
            GetInp;
            while not (EndOfLine or (NormBuffer = '`')) do
              begin
                RepLine[RepPntr] := NormBuffer;
                inc (RepPntr);
                GetInp;
              end;
            if not EndOfLine then { NormBuffer has a backquote }
              begin
                SavPntr := CurLinePntr - 1;  { save to "GetInp" 1st backquote }
                Getinp;    { get 1st replacement char }
                case LockBuffer of

                '%':  { replace by ascii name of current section }
                      begin
                        GetInp; { remove trailing backquote }
                        if LockBuffer <> '`' then
                          begin
                            ErrorPntr := CurLinePntr;
                            StoError (0, 'Unknown Replacement Identifier');
                          end
                        else
                          with CurSegment^ do
                             begin
                               for i := 1 to length (Name) do
                                 begin
                                   RepLine[RepPntr] := Name[i];
                                   inc (RepPntr);
                                 end;
                             end;
                      end;

                '@': { replace by unique labelnumber }

                    begin
                      ErrorPntr := CurLinePntr;
                      StoError (0,'Invalid Macro Replacement');
                      CurLinePntr := SavPntr;
                    end;

                '#':  { replace by number of parameters }
                      { like Turbo's ParamCount         }

                    begin
                      ErrorPntr := CurLinePntr;
                      StoError (0,'Invalid Macro Replacement');
                      CurLinePntr := SavPntr;
                    end;

                '0'..'9': { replace by parameter(i)  }
                          { like Turbo's ParamStr(i) }

                    begin
                      ErrorPntr := CurLinePntr;
                      StoError (0,'Invalid Macro Replacement');
                      CurLinePntr := SavPntr;
                    end;

                'A'..'Z': { StrIdent or SetIdent replacement }

                    begin
                      BlockAll := TRUE;
                      GetToken;
                      BlockAll := FALSE;
                      if CurDef and (CurTyp = StrIdent)
                         and (LockBuffer = '`') then
                        begin     { String Identifier }
                          StringPntr := StringBase;
                          while StringPntr^.Val <> CurIdent^.Val do
                            StringPntr := StringPntr^.Next;
                          CurQuoted := StringPntr^.Name;
                          for i := 1 to length (CurQuoted) do
                            begin
                              RepLine[RepPntr] := CurQuoted[i];
                              inc (RepPntr);
                            end;
                        end
                      else       { SetIdent ? }
                        if CurDef
                           and (CurTyp = SetIdent)
                           and (LockBuffer = '`') then
                          begin  
                            StoError (0,'Invalid Macro Replacement');
                            CurLinePntr := SavPntr;
                          end
                        else        { unknown replacement } 
                          begin
                            if CurTyp = StrIdent then
                              ErrorPntr := CurLinePntr;
                            CurLinePntr := SavPntr;
                            StoError (0,'Invalid Replacement Identifier');
                          end;
                    end; { A..Z }
                else
                  begin  { no replcement identifier at all }
                    ErrorPntr := CurLinePntr;
                    StoError (0,'Unknown Replacement Identifier');
                    CurLinePntr := SavPntr;
                  end;
                end; { case }
              end; { NormBuffer has BackQuote }
          until (EndOfLine or (NrOfErrors <> 0));

          if NrOfErrors <> 0 then  { the pre-processor detected errors }
            begin
              PrintLine;           { print the line without parsing }
              Nextline;            { read next line }
            end
          else                     { else normal line }
            begin
              RepLine[0] := AnsiChar (RepPntr - 1);
              CurLine := RepLine;
              CurLinePntr := 0;
              EndOfLine := FALSE;
              GetInp;                { read first character into buffers }
              GetToken;              { read first token on new line }
            end;
        end

      else { no pre-processing }

        begin
          CurLinePntr := 0;
          EndOfLine := false;
          GetInp;
          GetToken;
        end;

    end;
end; { NextLine }

begin
end.
