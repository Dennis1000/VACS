{$R-,B-,S-,N-,A+}
unit asmhan;

interface

uses     dos,
         types,          { the functions IsLabel, IsHex etc }

         asmvar,
         asminp,
         asmini,
         asmout,
         asmexp,
         asminc;

procedure HandleFile (AFile: pathstr; FileLevel: integer);

implementation



{ the following procedure handles an input file (the main or included
  file). calls itself recursively to include files.
}

procedure HandleFile (AFile: pathstr; FileLevel: integer);
var InclSectPos: longint;
    InclPntr,
    InclLine   : integer;
    InclEOF    : boolean;
    InclFile   : pathstr;

{ the following procedure handles a block of the input file to be
  actually processed. is called recursively to process nested
  IF .. ENDIF blocks.
}

  procedure HandleBlock (IfLevel: integer);
  var EndOfBlock: boolean;
      i:          integer;

{ the following procedure is used to handle the lines that do not
  contain the IF, ELSE, ENDIF or INCL opcodes as first token.
}
    procedure ParseLine;
    var StartError,
        OldHOutPtr,
        BackUpPtr,
        OpcodePtr,
        i, j, k, l1 : integer;
        w, l        : longint;
        TryExpr,
        Loop,
        OrgOk,
        HasColon,
        DollarDef   : Boolean;
        DollarTyp   : byte;
        LineLabel   : IdentPtr;

        FillNr: Integer; //v1.24g

    begin { ParseLine }
      DollarDef := FALSE;
      CurLabelDef := FALSE;
      StartError := ErrorPntr;
 {
      for i := 1 to length (CurLine) do
        if CurLine[i] = '^' then
          begin
            if i < length (CurLine) then
              for j := i to length (CurLine) - 1 do
                CurLine[j] := CurLine[j + 1];
            CurLine[0] := chr (ord (Curline[0]) - 1);
          end
        else if CurLine[i] = '`' then
          begin
            ErrorPntr := i + 1;
            StoError (0,'Invalid Replacement Identifier');
            CurTyp := EndLine;
            i := length (CurLine);
          end;
 }
      if (CurTyp = Operand) and (CurVal = Mult) then
        CurTyp := EndLine;   { first nonblank char = '*': remark line }
      if CurTyp in [Ident, SetIdent, StrIdent, Segment, UserIdent] then
        begin                { identifier found at start of line }
          LineLabel := CurIdent;
          CurLabel := CurIdent;
{}        if (Pass = First) and
             ((CurTyp = Ident) or (CurTyp = UserIdent)) and
             (CurIdent^.SegNum <> - 1) then
            begin { V1.20 }
             LineLabel^.SegNum := CurSegment^.SegNum;
             LineLabel^.Rel := CurSegment^.Rel;
           end;
          DollarDef := TRUE;
          CurLabelDef := TRUE;
          DollarTyp := CurTyp;

{23b}     if (CurTyp = Ident) and (LockBuffer = '>') then
            begin
              GetToken;
              DollarTyp := LocalLabel;
              LineLabel^.Val := HOutPntr;
            end;

          if Lockbuffer = ':' then
            begin
             GetToken;      { remove optional ':' }
             HasColon := true;
            end
          else
             HasColon := false;

          GetToken;
        end
      else
        LineLabel := NIL;       { no identifier found }
                      
      if (CurTyp = Operand) and (CurVal = Equal) then
                   { '=' is an alias for SET }
        begin
          CurTyp := Opcode;
          CurVal := SetEquate;
        end;

      if CurTyp = Opcode then   { there IS an opcode behind the label }
        begin
          OpcodePtr := CurVal; { save the opcode }
          OpcodePos := ErrorPntr;
          if OpcodePtr <> NameOp then
            GetToken;          { get operand }
          case OpcodePtr of  { and process the opcodes ! }

            Bward:  { V1.21 }
                   if StartFormat = LoFirst then
                     WordFormat := HiFirst
                   else
                     WordFormat := LoFirst;

            Fward:  { V1.21 }
                    WordFormat := StartFormat;

            Warning: { V1.21 }
                    if Pass = Second then
                      if (CurTyp = Operand) and (CurVal = Quote) then
                         begin
                           GetQuoted (40);
                           if ord (CurQuoted[0]) = 0 then
                               CurTyp := EndLine
                           else
                           begin
                             PrintHead;
                             if (DontPrint or (ListStatus <> Full))
                                and CurrFileNew then
                               begin
                                 writeln (ListFile, LMargStr, 'Error(s) in ',
                                          CurrFileName,' :');
                                 CurrFileNew := FALSE;
                               end;
                             if EnaLineNum then
                               write (ListFile,'     ');
                             if EnaErNum then
                               writeln (ListFile,'     ** WARNING **  @line ',
                                        LineNumber,': ', CurQuoted)
                             else
                               writeln (ListFile,'     ** WARNING **  ',
                                        CurQuoted);
                             if EnaDebug then
                               begin
                                 write (CurrFileName,'(', LineNumber);
                                 if EnaDebugCol then
                                   write (DebugSep, ErrorPntr);
                                 writeln (') : Warning: ', CurQuoted);
                               end;
                             inc (TotalErrors);
                             inc (TotalWarnings);
                             DontPrint := True;
                           end
                         end
                       else
                         StoError (0,'String Expected');

            NameOp:
                if ModName <> '*NONAME*' then
                  CurTyp := EndLine { skip, if NAME is already defined }
                else
                  begin
                    SkipSpace;
                    ErrorPntr := CurLinePntr;
                    i := 1;
                    while (not EndOfLine)
                          and (i < 33) and IsLabel (LockBuffer) do
                      begin
                        CurQuoted[i] := LockBuffer;
                        inc (i);
                        GetInp;
                      end;
                    CurQuoted[0] := chr (i - 1);
                    if (i > 1) and (CurQuoted[1] in ['A'..'Z']) then
                      if EndOfLine or (LockBuffer = ' ')
                         or (LockBuffer = ';') then
                        begin
                          ModName := CurQuoted;
                          GetToken;
                        end
                      else
                        begin
                          CurTyp := EndLine;
                          ErrorPntr := CurLinePntr;
                          if IsLabel (LockBuffer) then
                            StoError (0,'Name Too Long')
                          else
                            StoError (0,'Invalid Character in Name');
                        end
                    else
                      begin
                        CurTyp := EndLine;
                        if (i = 1) and EndOfLine then
                          StoError (0,'Missing Module Name')
                        else
                          StoError (0,'Invalid Starting Character');
                      end;
                  end;

            Origin:
              begin
                OpcodePos := ErrorPntr;
                OrgOk := false;
                if (CurTyp = Operand) and (CurVal = Divide) then
                  begin
                    GetToken; { skip '/' }
                    MustBeExpr (0, $ffff);
                    if CurExpVal <> 0 then
                      if CurExpVal = 1 then
                        begin
                          OrgOk := true;
                          OldHOutPtr := HOutPntr;
                          HOutPntr := HOutPntr or 1;
                        end
                      else
                        if (word (HOutPntr) mod CurExpVal) <> 0 then
                          begin
                            OrgOk := true;
                            OldHOutPtr := HOutPntr;
                            HOutPntr := HOutPntr -
                                (word (HOutPntr) mod CurExpVal) + CurExpVal;
                          end;
                  end
                else
                  begin
                    MustBeExpr (0, $ffff);
                    if CurExpDef then
                      begin
                        OrgOk := true;
                        OldHOutPtr := HOutPntr;
                        HOutPntr := CurExpVal;
                      end;
                  end;
                L1:=StLinePntr;        { V1.20 }
                StLinePntr := 1;
                HexStart (hi (HOutPntr));
                HexStart (lo (HOutPntr));
                StLinePntr := L1;
                if LineLabel<> NIL then LineLabel^.Val := HOutPntr;
                if DollarDef then DollarPntr := HOutPntr;
                if OrgOk then
                  if CurSegment^.Val = OldHOutPtr then
                    begin
                      CurSegment^.Val := HOutPntr;
                      if EnaXrf and
                        (HoutPntr <> 0) and
                        (CurSegment^.Rel <> AbsRel) then
                          begin
                            ErrorPntr := OpcodePos;
                            StoError (1, 'Offset Ignored by Linker');
                          end;
                    end;
               end;

            SegmentOp:
              if (Curtyp = Ident) and (CurIdent^.Def = NotYet) then
                        { there is an identifier given as segment }
                begin
                  CurSegment^.LocPtr := HOutPntr;
                           { save current segment's location counter }
                  HOutPntr := 0;
                  CurSegment := CurIdent; { copy segment pointer }
                  with CurSegment^ do
                  begin
                    Typ     := Segment;
                    if Pass = First then
                      Def := Global + FPass
                    else
                      Def := Global + SPass;
                    SegNum  := NewSegNum;
                    Rel     := ByteRel;
                    Val     := 0;
                  end;
                  L1:=StLinePntr;        { V1.20 }
                  StLinePntr := 1;
                  HexStart (hi (HOutPntr));
                  HexStart (lo (HOutPntr));
                  StLinePntr := L1;
                  if LineLabel<> NIL then LineLabel^.Val := HOutPntr;
                  if DollarDef then DollarPntr := HOutPntr;
                  inc (NewSegNum);
                  GetToken;
                  if (CurTyp = Operand) and (CurVal = Comma) then
                    begin
                      GetToken;
                      if (CurTyp = Opcode) and (CurVal = SetPageLen) then
                        begin
                          CurSegment^.Rel := PageRel;
                          GetToken;
                        end
                      else
                        if (CurTyp = Operand) or (CurTyp <> EndLine) then
                          case CurVal of
                            AbsoluteOp: begin
                                          CurSegment^.Rel := Absrel;
                                          GetToken;
                                        end;
                            InPageOp  : begin
                                          CurSegment^.Rel := InPageRel;
                                          GetToken;
                                        end;
                            else
                              StoError (0,'Invalid Relocation Type');
                            end { case }
                        else
                          StoError (0,'Missing Relocation Type');
                    end;
                end
              else
                case CurTyp of
                     Operand,
                     OpCode:   StoError (0,'Reserved Keyword');
                     Ident,
                     UserIdent,
                     SetIdent: StoError (0,'Symbol Already Defined');
                     Segment:  StoError (0,'Section Already Defined');
                     else      StoError (0,'Identifier Expected');
                end; { case }

            ResumeOp:
              if (CurTyp = Segment) or (CurTyp = EndLine) then
                begin
                  CurSegment^.LocPtr := HOutPntr;
                           { save current segment's location counter }
                  if CurTyp = Segment then
                    CurSegment := CurIdent
                  else
                    CurSegment := DefaultSeg;
                  HOutPntr := CurSegment^.LocPtr;

                  L1 := StLinePntr;
                  StLinePntr := 1;
                  HexStart (hi (HOutPntr));
                  HexStart (lo (HOutPntr));
                  StLinePntr := L1;

                  if LineLabel <> NIL then LineLabel^.Val := HOutPntr;
                  if DollarDef then DollarPntr := HOutPntr;
                  GetToken;
                end
              else
                if (CurTyp = Ident) and not CurDef then
                  StoError (0,'Undefined Section')
                else
                  StoError (0,'Invalid Section Name');

            Equate, SetEquate: { V1.20: extended for string expressions }
              if DollarDef then { there is an identifier given to EQU or SET }
                if (CurTyp in [Register, Opcode]) and
                    (OpcodePtr <> SetEquate) then
                  begin      { alias name definition: (not for SET) }
                    DollarDef := TRUE;
                    DollarPntr := CurVal;
                    DollarTyp := CurTyp;
                    GetToken;
                  end
                else    { token is read }
                  begin
                    if DollarTyp <> StrIdent then
                      begin
                        if OpCodePtr = SetEquate then
                          DollarTyp := SetIdent;
                        MustBeExpr (0, 0);
                        DollarDef := CurExpDef;
                        if DollarDef then
                          begin
                            DollarPntr := CurExpVal;
                            { V1.23 delete section number for constants }
                            if not CurExpRefDef then
                              LineLabel^.SegNum := - 1
                            else
                              LineLabel^.SegNum := CurExpRefBase;
                          end;
                      end
                    else  { dollartyp is StringIdent }

                    if (OpcodePtr = SetEquate) and (DollarTyp = StrIdent) then
                      { LineLabel^.Val = stringnumber }
                      if IsString then
                        begin       { get stringvariale }
                          DollarPntr := LineLabel^.Val;
                          { move string to SETident string }
                          StringPntr := StringBase;
                          while StringPntr^.Val <> LineLabel^.Val do
                            StringPntr := StringPntr^.Next;
                          StringPntr^.Name := CurQuoted;
                          DollarPntr := LineLabel^.Val;
                        end
                      else
                        StoError (0,'Missing String Expression');

                    if DollarDef and (Pass = Second) then
                      begin { send '= <value>' or 'S'to listing }
                        if LineLabel^.Typ = StrIdent then
                          StartLine[6] := 'S'
                        else
                          StartLine[6] := '=';
                        if not ((OpcodePtr = Equate) and
{}                             (LineLabel^.Def = SPass)) then
                          begin
                            StLinePntr := 8;
                            HexStart (hi ((DollarPntr shr 16) and $ffff));
                            HexStart (lo ((DollarPntr shr 16) and $ffff));
                            HexStart (hi (DollarPntr and $ffff));
                            HexStart (lo (DollarPntr and $ffff));
                          end;
                        end;
                  end

              else { no DollarDef }
                begin
                  ErrorPntr := OpcodePos;
                  StoError (0,'No Identifier Given');
                end;

            DefStorage: { V1.23g define filler }
              begin
                MustBeExpr (0, 32767);
                if CurExpDef then
                  begin
                    i := CurExpVal;
                    if not EndofLine then
                      if (CurTyp = Operand) and (CurVal = Comma) then
                        begin
                          GetToken;
                          MustBeExpr (0, 32767);
                          if CurExpDef then
                            begin
                              k := CurExpVal;
                              for j := 1 to i do WriteByte (k);
                            end;
                        end
                      else
                        StoError (0, 'Comma Expected')
                    else
                      HOutPntr := HOutPntr + i;
                  end;
              end;

            DefMemory:
              repeat         { work through list }
                if IsString then
                  begin
                    BackUpPtr := CurLinePntr;
                    if (length (CurQuoted) > 2) or EndOfline or
                       ((CurTyp = Operand) and (CurVal = Comma)) then
                        { quoted string cannot be part of expression: }
                      for i := 1 to length (CurQuoted)
                        do WriteByte (ord (CurQuoted[i]))
                    else
                      begin  { try quoted string as part of expression: }
                        if (Length (CurQuoted) = 0) then
                           { error message given for string, 'undo' it }
                          begin
                            dec (TotalErrors);
                            if (NrOfErrors < MaxError) then
                              dec (NrOfErrors);
                          end;
                        CurLinePntr := BackUpPtr - 2;
                        GetInp;
                        GetToken;
                        TryExpr := TRUE;
                      end;
                  end

                else   { no string try to define byte as expression result }

                  begin
                    MustBeExpr (-128, 255);
                    WriteByte (lo (CurExpVal));
                  end;
                SeekComma;
                Loop := (CurTyp = Operand) and (CurVal = Comma);
                if Loop then
                  GetToken; { remove comma }
              until not Loop;

            DefMemoryX: //v1.24f
              repeat         { work through list }
                if IsString then
                  begin
                    BackUpPtr := CurLinePntr;
                    if (length (CurQuoted) = 8){ or EndOfline or
                       ((CurTyp = Operand) and (CurVal = Comma)) }then
                        { quoted string cannot be part of expression: }
                      begin
                        j := 0;
                        for i := 1 to length (CurQuoted) do
                          if (CurQuoted[i]<>' ') and (CurQuoted[i]<>'.') then
                            j := j + (1 shl (8-i));
                        WriteByte (j);
                      end
                      else
                        StoError (0, 'Need 8 quoted values');
                   end;
              until not Loop;

            DefWord:
              repeat         { work through list }
                MustBeExpr (-32768, 65535);
                case WordFormat of
                  LoFirst:   { format for most Intel processors }
                    begin
                      WriteByte (lo (CurExpVal));
                      WriteByte (hi (CurExpVal));
                    end;
                  HiFirst:   { format for most Motorola processors }
                    begin
                      WriteByte (hi (CurExpVal));
                      WriteByte (lo (CurExpval));
                    end;
                end; { case WordFormat }
                SeekComma;
                Loop := (CurTyp = Operand) and (CurVal = Comma);
                if Loop then
                  GetToken;
              until not Loop;

            DefDouble:
              repeat         { work through list }
                MustBeExpr (0, 0);
                case WordFormat of
                  LoFirst:   { format for most Intel processors }
                    begin
                      WriteByte (lo (CurExpVal and $ffff));
                      WriteByte (hi (CurExpVal and $ffff));
                      WriteByte (lo ((CurExpVal shr 16) and $ffff));
                      WriteByte (hi ((CurExpVal shr 16) and $ffff));
                    end;
                  HiFirst:   { format for most Motorola processors }
                    begin
                      WriteByte (hi ((CurExpVal shr 16) and $ffff));
                      WriteByte (lo ((CurExpVal shr 16) and $ffff));
                      WriteByte (hi (CurExpVal and $ffff));
                      WriteByte (lo (CurExpVal and $ffff));
                    end;
                end; { case WordFormat }
                SeekComma;
                Loop := (CurTyp = Operand) and (CurVal = Comma);
                if Loop then
                  GetToken;
              until not Loop;

            EndFile:
              begin
                Expression (0, 0);
                if not CurExpDef then
                  CurExpVal := 0;
                EndOfFile := TRUE;
                if Pass = Second then
                  begin      { send '> <startaddress>' to list file }
                    StartLine[6] := '>';
                    StLinePntr := 8;
                    HexStart (hi (CurExpVal));
                    HexStart (lo (CurExpVal));
                    WriteEOF (FileLevel);
                  end
                else         { first pass }
                  if not Quiet and (FileLevel > 0) then
                    begin
                      write ('':FileLevel - 1);
                             { V1.10: indented pass 1 include listing }
                      writeln ('End of : ', AFile);
                    end;
                ErrorPntr := 1;
                             { IfLevel is counted down by successive ending
                               of nested HandleBlock calls after finding the
                               end of the file. generate error message for
                               open IF .. ENDIF blocks only once: }
                if IfLevel = 1 then
                  StoError (0,'Open IF..ENDIF');
              end;

            DefGlobal:     { just store any argument into the symbol table }
              repeat
                Loop := false;
                if CurTyp = Ident then with CurIdent^ do
                  begin
                    Def := (Def or Global);
                    if Def = Global then
                      SegNum := -2;
                    GetToken;   { get comma }
                    Loop := (CurTyp = Operand) and (CurVal = Comma);
                    if Loop then
                      GetToken;  { get symbol, following comma }
                  end
                else
                  if CurTyp = Segment then
                    StoError (0,'Segments Not Allowed')
                  else
                    StoError (0,'Identifier Expected');
              until not Loop;

            DefString:
              repeat
                Loop := false;
                if (CurTyp = Ident) and (CurIdent^.Def = NotYet) then
                  begin
                    CurIdent^.Typ := StrIdent;
                    if StringBase = NIL then
                      begin
                        new (StringBase);
                        StringBase^.Val := 1;
                        StringPntr := StringBase;
                      end
                    else  { append a string at the end }
                      begin
                        StringPntr := StringBase;
                        while StringPntr^.Next <> NIL do
                             StringPntr := StringPntr^.Next;
                        new (StringHelp);
                        StringHelp^.Val := StringPntr^.Val + 1;
                        StringPntr^.Next := StringHelp;
                        StringPntr := StringHelp;
                      end;
                    CurIdent^.Val := StringPntr^.Val;
                    CurIdent^.Def := FPass;
                    StringPntr^.Name[0] := chr (0);
                    StringPntr^.Next := NIL;
                    GetToken;   { get comma }
                    Loop := (CurTyp = Operand) and (CurVal = Comma);
                    if Loop then
                      GetToken;  { get symbol, following comma }
                  end
                else { CurTyp <> Ident  }
                  begin
                    if CurTyp = StrIdent then
                      StoError (0,'Double Definition')
                    else
                     if CurTyp <> UnDef then
                       StoError (0,'Invalid Identifier')
                     else
                       StoError (0,'String Identifier Expected');
                    GetToken;   { remove invalid identifier }
                    Loop := (CurTyp = Operand) and (CurVal = Comma);
                    if Loop then
                      GetToken;  { get symbol, following comma }
                  end;
              until not Loop;

            SetTabs:
              begin
                i := 1;      { used as pointer in TabLine }
                TabLine[1] := ' ';
                k := 8;      { default tab column width }
                repeat       { work through list }
                  MustBeExpr (1, 256 - i);
                  if CurExpDef then
                    begin    { set one tab column with found width }
                      k := CurExpVal;
                      j := i + k;
                      for i := (i + 1) to (j - 1)
                        do TabLine[i] := ' ';
                      i := j;
                      TabLine[i] := 'T';
                    end;
                  SeekComma;
                  Loop := (CurTyp = Operand) and (CurVal = Comma);
                  if Loop then
                    GetToken;
                until not Loop;
                j := k - 1;
                inc (i);
                while i <= 255 do
                  begin      { fill out the line with tab columns with the
                               last given width }
                    if j = 0 then
                      begin
                        TabLine[i] := 'T';
                        j := k;
                      end
                    else
                      TabLine[i] := ' ';
                    dec (j);
                    inc (i);
                  end;
                DontPrint := TRUE;
              end;

            SetTitle, SetSubTitle:
              if (CurTyp = Operand) and (CurVal = Quote) then
                begin        { set the wanted line }
                  GetQuoted (128);
                  if length (CurQuoted) > 0 then
                    if OpcodePtr = SetTitle then
                      begin
                        TitleLine := '                                        ';
                        if length (CurQuoted) > 40 then
                          begin
                            ErrorPntr := ErrorPntr-length (CurQuoted)+39;
                            StoError (1,'Line Truncated');
                            Curquoted[0] := chr (40);
                          end;
                        for i := 1 to length (CurQuoted) do
                          TitleLine[i]:= CurQuoted[i];
                      end
                    else
                      SbTitleLine := CurQuoted;
                  DontPrint := TRUE;
                end
              else           { clear the wanted line }
                if OpcodePtr = SetTitle then
                  TitleLine := ''
                else
                  SbTitleLine := '';

            SetWidth:
              begin
                if EnaLineNum then
                  MustBeExpr (73, 255 - length (LMargStr))
                else
                  MustBeExpr (68, 255 - length (LMargStr));
                             { V1.10: minimum page width changed }
                if CurExpDef then
                  PageWidth := CurExpVal;
                if length (TitleLine) > PageWidth then
                  TitleLine[0] := chr (PageWidth);
                if length (SbTitleLine) > Pagewidth then
                  SbTitleLine[0] := chr (PageWidth);
                DontPrint := TRUE;
              end;

            LeftMarg:
              begin
                BackUpPtr := ErrorPntr;
                MustBeExpr (0, 0);
                if (CurExpVal < 0) or (CurExpVal > 16) or
                   (CurExpVal > (255 - PageWidth)) then
                  begin
                    ErrorPntr := BackUpPtr;
                    StoError (0,'Value Out Of Range');
                  end
                else
                  LMargStr[0] := chr (CurExpVal);
                DontPrint := TRUE;
              end;

            SetPageLen:
              begin
                MustBeExpr (24, 255);
                if CurExpDef then
                   PageLength := CurExpVal;
                DontPrint := TRUE;
              end;

            EjectPage:
              begin
                if (LineCntr > 0) and (PageLength < 255) then
                             { V1.10: EJECT impossible if no paging done }
                  LineCntr := 0;
                DontPrint := TRUE;
              end;

            StopList:
              if ListStatus <> ErrorsOnly then
                begin
                  ListStatus := Stopped;
                  DontPrint := TRUE;
                end;

            StartList:
              if ListStatus <> ErrorsOnly then
                begin
                  ListStatus := Full;
                  DontPrint := TRUE;
                end;

            StopFold:        { V1.10 stop folding of lines in list file }
              begin
                FoldEnable := FALSE;
                DontPrint := TRUE;
              end;

            StartFold:       { V1.10 re-enable folding of lines in list file }
              begin
                FoldEnable := TRUE;
                DontPrint := TRUE;
              end;

            SetLoadOffs:     { V1.10 set load offset for object file }
              begin
                MustBeExpr (-65536, $ffff);
                if CurExpDef then LoadOffset := CurExpVal;
              end;

            ToList, ToScreen: { V1.10 send string to listing or screen }
              begin
                repeat       { work through list }
                  if IsString then
                    begin
                      if OpcodePtr = ToScreen then
                        write (CurQuoted)
                      else
                        if Pass = Second then
                          write (ListFile, CurQuoted);
                    end
									else
                    begin
                      MustBeExpr (0, 255);
                      if CurExpDef then
                        if OpcodePtr = ToScreen then
                          write (chr (CurExpVal))
                        else
                          if Pass = Second then
                            write (ListFile, chr (CurExpVal));
                    end;
                  SeekComma;
                  Loop := (CurTyp = Operand) and (CurVal = Comma);
                  if Loop then
                    GetToken;
                until not Loop;
                if OpcodePtr = ToScreen then
                  writeln;
                DontPrint := TRUE;
              end;

            IfOp, ElseOp, EndIfOp, InclOp:
              begin          { these should not be handled here }
                ErrorPntr := StartError;
                StoError (0,'No Label Allowed');
                CurTyp := EndLine;
              end;

            ProcesOn:
               begin
                 PreProcess := true;
                 DontPrint := true;
               end;

            ProcesOff:
               begin
                 PreProcess := false;
                 DontPrint := true;
               end;

            RepOp, EndRepOp:
               begin
                 ErrorPntr := OpcodePos;
                 StoError (0, 'Invalid Outside Macro');
               end;

            else Process (OpcodePtr);
                             { no standard pseudo-op, try processor ops }
          end; { case OpcodePtr }
        end
      else                   { no opcode found in line }
        begin
          OpcodePtr := NoOpFound; { indicate 'no opcode found' }
          if (CurTyp <> EndLine) then
            begin            { found something else instead }
              StoError (0,'Opcode Expected');
              CurTyp := EndLine;
            end;
        end;

      { check if all parameters are processed }

      if (CurTyp <> EndLine) and (NrOfErrors = 0) then
        StoError (1,'Excess Data');

      { check / set label }

      if LineLabel <> NIL then   { identifier found at start of line }
        with LineLabel^ do
          begin
            ErrorPntr := StartError;
            DontPrint := FALSE;
            if ( (Def <> NotYet)
                 and (((OpcodePtr <> SetEquate)
                       and (Typ in [SetIdent, StrIdent])
                       )
                      or ((OpcodePtr = SetEquate)
                          and not (Typ in [SetIdent, StrIdent])
                          )
                      )
                     )
                 or ((OpcodePtr = NoOpFound)
                     and (Typ <> Ident)) then
                   StoError (0,'Type Error')
            else
							if (OpcodePtr = NoOpFound)
                 and (NrOfErrors = 0)
                 and not HasColon
                 and (DollarTyp <> LocalLabel) then
                  StoError (0, 'Unknown Instruction')
                else
              if DollarDef then     { value setting not done yet }
                if (Def and SPass = SPass)
                   and (OpcodePtr <> SetEquate)
                   and (DollarTyp <> LocalLabel) then
                  StoError (0,'Double Definition')
                else
                  begin
                    if (Def and FPass = FPass)
                        and  (Val <> DollarPntr)
                        and  (OpcodePtr <> SetEquate)
                        and  (OpcodePtr <> SegmentOp)
                        and  (OpcodePtr <> ResumeOp)
                        and  (OpcodePtr <> Origin)
{1.24}                  and  (Typ <> UserIdent) then
                      StoError (0,'Phase Error')
                    else
                      if (Typ <> UserIdent) then { V1.21 prevent overwrite }
                        begin
                          Val := DollarPntr;
                          if DollarTyp <> LocalLabel then
                            Typ := DollarTyp;
                        end;
                    if Pass = First then
                      Def := Def or FPass
                    else
                      Def := (Def and Global) or SPass;
                  end;
          end;
    end; {ParseLine}

{ the following procedure skips a not executed block, calls itself
  recursively to handle nested IF .. ENDIF blocks (all skipped).
}

    procedure SkipBlock (IfLevel: integer);
    var EndOfBlock: Boolean;
        i         : integer;
    begin
      BlockAll := TRUE;      { prevent definition of identifiers }
      repeat
        NextLine;
        if Pass = First then
          inc (TotSkipLines);
        if (CurTyp = Opcode) and (CurVal = IfOp) then
          begin
            SkipBlock (IfLevel + 1);
                             { skip block following IF }
            if (CurTyp = Opcode) and (CurVal = ElseOp) then
              SkipBlock (IfLevel + 1);
                             { skip block following ELSE }
            EndOfBlock := FALSE;
          end
        else
           EndOfBlock := (CurTyp = Opcode) and
                           ((CurVal = ElseOp) or (CurVal = EndIfOp));
      until EndOfFile or EndOfBlock;
      if (Pass = First) and (IfLevel = 1) then
        dec (TotSkipLines);
      if EndOfFile and (IfLevel > 0) then
        if Pass = Second then
          begin
            CurExpVal := 0;  { dummy value as start address }
            CurLine := '';   { dummy line to print }
            ErrorPntr := 1;  { store error string at start of line }
            WriteEof (FileLevel);
                             { write EOF record if FileLevel = 0 }
            StoError (0,'Open IF..ENDIF');
            PrintLine;
          end
        else                 { first pass }
          if not Quiet and (FileLevel > 0) then
            begin
              write ('':FileLevel - 1);
                             { V1.10: indented pass 1 include listing }
              writeln ('End of : ', AFile);
            end;
      BlockAll := FALSE;     { re-enable definition of identifiers }
    end;

  begin { HandleBlock }
    EndOfBlock := FALSE;
    repeat
      BlockRefTo := TRUE;    { V1.23h: disable reference marking for labels }
      NextLine;              { this parses the FIRST token }
      BlockRefTo := FALSE;   { V1.23h: enable identifier reference marking }
      if (CurTyp = Opcode) and
         ((CurVal = IfOp) or (CurVal = ElseOp) or
          (CurVal = EndIfOp) or (CurVal = InclOp)) then
        case CurVal of
          IfOp:
            begin
              GetToken;      { remove IF }
              MustBeExpr (0, 0);
              if not CurExpDef then  { invalid expression following IF }
                PrintLine;       { V1.13 Change }
              if CurExpVal = 0 then
                begin
                  SkipBlock (IfLevel + 1);
                         { IF failed, seek ELSE or ENDIF }
                  if (CurTyp = Opcode) and (CurVal = ElseOp) then
                    HandleBlock (IfLevel + 1);
                         { do ELSE block }
                end
              else
                begin
                  HandleBlock (IfLevel + 1);
                         { IF passed, handle block until ELSE or ENDIF }
                  if (CurTyp = Opcode) and (CurVal = ElseOp) then
                    SkipBlock (IfLevel + 1);
                         { skip the ELSE part }
                end;
              if (CurTyp = Opcode) and (CurVal = ElseOp) then
                begin    { IF .. ELSE .. ELSE found }
                  StoError (0,'Mismatching ELSE');
                  PrintLine;
                end;
            end;

          ElseOp:
            begin
              EndOfBlock := IfLevel > 0;
              if not EndOfBlock then
                begin        { ELSE found without an IF }
                  StoError (0,'Mismatching ELSE');
                  PrintLine;
                end;
            end;

          EndIfOp:
            begin
              EndOfBlock := IfLevel > 0;
              if not EndOfBlock then
                begin        { ENDIF found without an IF }
                  StoError (0,'Mismatching ENDIF');
                  PrintLine;
                end;
            end;

          InclOp:
            if FileLevel = MaxInclude then
              begin
                StoError (0,'Too much INCL-udes');
                PrintLine;
              end
            else
              begin
                GetToken;    { delete INCL }
                InclEOF := (CurTyp = Operand) and (CurVal = Quote);
                if InclEOF then
                  begin
                    DollarPntr := ErrorPntr;
                             { misused to store start of string }
                    GetQuoted (64);
                    InclEOF := length (CurQuoted) > 0;
                    InclFile := fexpand (CurQuoted);

                    if CurTyp <> EndLine then
                      begin
                        StoError (0,'Excess Data');
                        InclEOF := FALSE;
                      end;
                  end
                else
                  StoError (0,'Missing Filespec');
                if not InclEof then
                  PrintLine   { error in line, include not tried }
                else
                  begin
                    ErrorPntr := DollarPntr;
                             { reset errorpointer to start of string }
                    ExtendSpec (InclFile,'.ASM');
                             { store file position and close file: }

                    InclSectPos := SectorPos;
                             { V1.12 strategy change: remember position
                               'longfilepos' gave before reading current
                               block with 'blockread' }
                    InclPntr    := SectorPntr;
                    InclEOF     := EndOfFile;
                    InclLine    := LineNumber;
                    close (InFile);
                    if Exist (InclFile) then
                      begin
                        StartLine := '* START INCLUDE * ';
                        PrintLine;
                        if not Quiet and (Pass = First) then
                          begin
                            write ('':FileLevel);
                             { V1.10: indented pass 1 include listing,
                               ErrorPntr misused ! }
                            writeln ('Include: ', InclFile);
                          end;
                             { Include a file : }
                        HandleFile (InclFile, FileLevel + 1);


                      end
                    else
                      begin
                        StoError (0,'File Not Found');
                        PrintLine;
                        writeln ('File Not Found ',inclfile,#7);
                        halt;
                      end;
                             { re-open and re-position current file : }
                    assign (InFile, AFile);
                    reset (InFile, 1);
                    seek (InFile, InclSectPos);
                             { V1.12 strategy change }
                    blockread (InFile, CurSector, 512, SectorCont);
                    SectorPos  := InclSectPos;
                    SectorPntr := InclPntr;
                    EndOfFile  := InclEOF;
                    LineNumber := InclLine;
                    CurrFileName := AFile;
                             { V1.12: filename given for /E listing,
                                      returned from include ! }
                    CurrFileNew := TRUE;
                             { V1.12: no error detected yet for file }
                  end;
              end;
        end { case }
      else                   { not an IF, ELSE, ENDIF or INCL opcode }
        begin
          ParseLine;
          PrintLine;
        end;
    until EndOfFile or EndOfBlock;
  end; { HandleBlock }

begin { HandleFile }
  assign (InFile, AFile);      { open file and initialise for HandleBlock }
  reset (InFile, 1);
  SectorPos := filepos (InFile);
                             { V1.12 strategy change, start of file }
  blockread (InFile, CurSector, 512, SectorCont);
  SectorPntr := 0;
  LineNumber := 0;           { will be incremented to 1 by first ReadLine }
  BlockAll := FALSE;
  BlockRefTo := FALSE;
  EndOfFile := FALSE;
  CurrFileName := AFile;     { V1.12: filename given for /E listing }
  CurrFileNew := TRUE;       { V1.12: no error detected yet for file }
  HandleBlock (0);            { start nesting of blocks at ground level }
  close (InFile);             { end of file reached, close the file }
end; { HandleFile }

begin
end.
