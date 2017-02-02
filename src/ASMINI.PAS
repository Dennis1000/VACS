{$R-,B-,S-,N-,A+}
unit asmini;

interface

uses  dos,
      asmvar;

function  Exist (FileSpec : pathstr) : boolean;
procedure ExtendSpec (var Path : pathstr; Ext : extstr);
function  NameOf (Path : pathstr) : pathstr;
procedure GetSetBreak (SetTo : boolean; Code : integer);
procedure StoError (ErrorTyp : integer; AString : ErrorString);
procedure StoPatt (Name : PatName; Typ : byte; Val : longint);
procedure DelPatt (Name : PatName);
procedure InitTabs (TabPos : integer);
procedure ClearNonIdents;
procedure ExitHandler (ErrNo, ErrAddr : integer);
procedure StoMainPatt;
procedure HandleUser;

implementation

{
  This file  contains  the  initialisation  functions for the ASM
  assemblers  (including  'ClearNonIdents',  which  is  called in
  preparation for the second pass).

  filename:   ASMINI.PAS             must be included in: ASM.PAS

  originally written by: ir. A.C.Verschueren   November 20, 1987.

  this program donated to the public domain,       November 1987.

  Changes from V1.10:
  'User options' incorporated for assembly control.
  $PASS gives the number of the pass for assembly control.
  Expanded 'Questions' startup.
  'N' option controls line numbering in list file.

  No changes for V1.11 in this file.

  Changes from V1.12:
  $IDEF pattern added for 'identifier defined' checking pseudo-operator.

 --------------------------------------------------------------------------

  V1.13 and later changes by W.H. Taphoorn
  
  Changes from V1.13:
  GetSetBreak is called with extra parameter for the MS-DOS exit code.
  Errorlevel: 0 = No Errors
              1 = Console Abort
              2 = Assembly Warnings detected
              3 = Assembly Errors detected
              4 = I/O problems
              5 = Internal Error
  /T switch for Tektronix HexFormat   (see also ASM.PAS and OUTPUTFN.PAS )
  Shorthand notation for Tektronix assembler compatibility:

        Tektronix | Verschueren

          \       |   NOT
          &       |   AND
          !       |   OR
          !!      |   XOR
          DEF     |   $IDEF
          LO      |   LOW
          HI      |   HIGH
          STITLE  |   SBTTL
          SECTION |   SEG
          INCLUDE |   INCL

  Chanhes from V1.20:
  Mostly to prepare for relocatable assembler:
  - GLOBAL definitions (section names default to global)

  - Syntax change for segment definition:
    [symbol]  SECTION   <section-name>[,relocation type]

  - Section relocation attributes: ABSOLUTE, PAGE, INPAGE
        ABSOLUTE = non-relocatable
        PAGE     = relocatable, starting XX00H
        INPAGE   = byte-relocatable totally within 100H page

  - RESUME for segment re-definition:
    [symbol]  RESUME    <section-name>

  - BASE pseudo operand:
        IF BASE <symbol>      ;true if <symbol> is defined in current section

  - Origin '/' modifier to create 'MOD' offset of Loc. counter
    [symbol]  ORG  /100H  sets loc. counter to nearest XX00H address

  - Options added: -p no preprocessor
                   -b set tabs

  Changes to V1.21:
  - BACKWARD and FORWARD pseudo instructions added
  - WARNING pseudo instruction added
  - /R switch for debug info on error lines

  Changes to V1.23a:
  - Ctrl-Break interrupt handler installed. Sets the flag 'Interrupted'
    (when user presses ^Break or ^C) which is read by NextLine (ASMINP.PAS)
    to detect user-abort. Conveniant side effect is that the type-ahead
    buffer is not flushed when the user types during assembly.
  - Exit procedure modified.
  - User switches 1..9 imported into UserFlag[] boolean array, to be able
    to reference them from ASMINC module.
}


var
  TempI: Integer;

{ the following function checks whether a file exists: }

function Exist (FileSpec: pathstr): boolean;
var F: file;
begin
  {$I-}
  assign (F, FileSpec);
  reset (F);
  {$I+}
  if ioresult <> 0 then
    Exist := FALSE
  else
    begin
      Exist := TRUE;
      close (F);
    end;
end; {Exist}

{ the following procedure appends a default extension to a file
  specification which has no extension:
  V1.12: conversion of filename to all uppercase performed.
  V1.20: entirely replaced due to TP5 special functions on filenames.
}


procedure ExtendSpec (var Path:pathstr; Ext:extstr);

var d    : dirstr;
    n    : namestr;
    e    : extstr;

begin

 fsplit (Path, d, n, e);
 if e = '' then
   e := Ext;
 Path := d+n+e;

end;

{
  the following function returns the filename without extension
  from a filespec.
}

function NameOf (Path:pathstr) : pathstr;

var d    : dirstr;
    n    : namestr;
    e    : extstr;

begin
 fsplit (Path, d, n, e);
 NameOf := n;
end;


{ The following procedure stores an error description into the
  Errors[] array, in such a way that a caret (^) will appear
  under the character pointed to by ErrorPntr in the printed
  line in the list file.
  Only (MaxErrors - 1) error messages will be stored, the next
  one will be changed into 'Too Much Errors'.
  The error message is normally placed left from the caret. If
  there is not enough space, then it will be placed right from
  the caret. The error message should not be longer than 24
  characters to prevent problems placing it with small printable
  page widths.
  V1.20 change:
    ErroTyp introduced, 0 = Error, 1 = Warning
}

procedure StoError (ErrorTyp: integer; AString: ErrorString);

var ErrPtr : integer;        { ErrorPntr for 'folded' lines (lines too long }
    DebStr : string;         { to be printed on one line in the list file)  }

  procedure Fillspace (i1: integer);
  var i2: integer;
  begin                      { fill part of an error string with spaces }
    for i2 := 1 to i1
    do Errors[NrOfErrors].txt[i2] := ' ';
  end;

  procedure Seterror (i1: integer);
  var i2: integer;
  begin                      { copy the error message to an error string }
    dec (i1);
    for i2 := 1 to length (AString)
    do Errors[NrOfErrors].txt[i1 + i2] := AString[i2];
  end;

begin { StoError }
  if Pass = Second then      { error text, only set during second pass ! }
    begin
      if EnaDebug then
        begin
          write (CurrFileName, '(', LineNumber);
          if EnaDebugCol then
            write (DebugSep, ErrorPntr);
          write (') : ');
          if ErrorTyp = 0 then
            writeln ('Error: ', AString)
          else
            writeln ('Warning: ', AString);
        end;
      if NrOfErrors = (MaxError - 1) then
        begin
          AString := 'Too Much Errors';
          ErrorTyp := 0;
        end;
      if NrOfErrors < MaxError then
        begin
{}        if EnaErNum then
            begin
              str (LineNumber, DebStr);
              AString := '@line ' + DebStr + ': ' + AString;
            end;
          ErrPtr := ((ErrorPntr - 1) mod (PageWidth - 18)) + 1;
          inc (NrOfErrors);
{}        if length (AString) < (ErrPtr - 2) then
            begin            { place message left of caret }
              Fillspace (ErrPtr - length (AString) - 1);
              Seterror (ErrPtr - length (AString) - 1);
              Errors[NrOfErrors].txt[ErrPtr - 1] := ' ';
              Errors[NrOfErrors].txt[0] := chr (ErrPtr);
            end
          else
            begin            { place message right of caret }
              Fillspace (ErrPtr + 1);
              Seterror (ErrPtr + 2);
              Errors[NrOfErrors].txt[0] := chr (ErrPtr + length (AString) + 1);
            end;
          Errors[NrOfErrors].txt[ErrPtr] := '^';
          Errors[NrOfErrors].Code := ErrorTyp;
        end;
      inc (TotalErrors);
      if ErrorTyp = 1 then
        inc (TotalWarnings);
    end
  else
    inc (NrOfErrors);
end; { StoError }

{ Procedure to store the patterns in the Patterns array, sorting
  them in (ASCII) alphabetical order.

  The Name is a string with maximum length of PatLen characters,
           may be given in uppercase or lowercase.  This defines
           the pattern to be found with GetToken.
  The Typ(e) is one of the Token Types, except 'Ident'. 'Ident'-
           type tokens  cannot be used  because  they will block
           GetToken altogether (used as flag inside GetToken).
  The Val(ue) is an arbitrary integer value given to distinguish
           tokens with  the same  type.  It is possible  to have
           'alias' tokens with the same type and value.

  It is possible to re-define the Typ and/or Val of a pattern.
}

procedure StoPatt (Name: PatName; Typ: byte; Val: LongInt);
var BottomPtr,
    TopPtr,
    CenterPtr,
    CharPtr    : integer;

begin
  if NrOfPatt >= MaxPat then
    begin
      writeln ('MORE PATTERNS NEEDED !!!!');
      GetSetBreak (FALSE, 5);
    end
  else
    begin
      for CharPtr := 1 to length (Name) do
         Name[CharPtr] := upcase (Name[CharPtr]);
      for CharPtr := (length (Name) + 1) to PatLen do
         Name[CharPtr] := #00;

      BottomPtr := 1;
      TopPtr := NrOfPatt + 1;
      CenterPtr := (NrOfPatt shr 1) + 1;  { the middle of the array }
      Patterns[TopPtr].Name := #255;

      while BottomPtr < TopPtr do
        begin
          if Name > Patterns[CenterPtr].Name then
             BottomPtr := CenterPtr + 1
          else
             TopPtr := CenterPtr;
          CenterPtr := BottomPtr + ((TopPtr - BottomPtr) shr 1)
        end;

      if Name <> Patterns[CenterPtr].Name then
        begin
          for TopPtr := NrOfPatt downto CenterPtr do
            Patterns[TopPtr + 1] := Patterns[TopPtr];
          Patterns[CenterPtr].Name := Name;
          inc (NrOfPatt);
        end;

      Patterns[CenterPtr].Typ := Typ;
      Patterns[CenterPtr].Val := Val;

    end;
end; {procedure StoPatt}

{ Procedure to delete a pattern from the Patterns array.

  The Name is a string with maximum length of PatLen characters,
           may be given in uppercase or lowercase.  This defines
           the pattern to be deleted from the table.
}

procedure DelPatt (Name: PatName);
var BottomPtr,
    TopPtr,
    CenterPtr,
    CharPtr    : integer;

begin
  for CharPtr := 1 to length (Name) do
    Name[CharPtr] := upcase (Name[CharPtr]);
  for CharPtr := (length (Name) + 1) to PatLen do
    Name[CharPtr] := #00;
  BottomPtr := 1;
  TopPtr := NrOfPatt;
  CenterPtr := (NrOfPatt shr 1) + 1;
  while BottomPtr < TopPtr do
    begin
      if Name > Patterns[CenterPtr].Name then
        BottomPtr := CenterPtr + 1
      else
        TopPtr := CenterPtr;
      CenterPtr := BottomPtr + ((TopPtr - BottomPtr) shr 1)
    end;
  if (TopPtr < BottomPtr) or (Name <> Patterns[CenterPtr].Name) then
    begin
      writeln ('PATTERN TO DELETE NOT FOUND !!!!');
      GetSetBreak (FALSE, 5);
      TopPtr := 0;
      NrOfPatt := 1 div TopPtr;
    end
  else
    begin
      for TopPtr := CenterPtr to NrOfPatt - 1 do
        Patterns[TopPtr] := Patterns[TopPtr + 1];
      dec (NrOfPatt);
    end;
end; {procedure DelPatt}

{ the following procedure initialises the TabLine string to
  one tab each 8 characters:
}

procedure InitTabs (TabPos:integer);
var i: integer;
begin
  for i := 1 to 255 do
    if (i mod TabPos) = 1 then
      TabLine[i] := 'T'
    else
      TabLine[i] := ' ';
  TabLine[0] := chr (255);
end;

{ the following procedure 'un-initialises' all identifiers which
  do not represent a value (label or expression result for EQU).
  Also counts the identifiers. this procedure is executed at the
  end of the first pass.
  V1.10: total number of lines displayed.
  V1.20  clear String area.
}

procedure ClearNonIdents;
var i : integer;
    p : IdentPtr;
    h : string[4];           { for conversion of TotLines }


begin { ClearNonIdents }
  NrOfIdents := 0;
  for i := 0 to 28 do
    begin
      p := IdentArray[i];
      while p <> NIL do
        begin
{1.24}    if (p^.Typ <> Ident) and (p^.Typ <> UserIdent) then
            begin              { back to state of undeclared identifier: }
              p^.Def := NotYet;
              p^.Typ := Ident;
            end;
          p := p^.Next;
          inc (NrOfIdents);
        end;
    end;

  while StringBase <> NIL do         { V1.20:  clear string area }
    begin
      StringHelp := StringBase^.Next;
      dispose (StringBase);
      StringBase := StringHelp;
    end;

  {
  writeln ('Number of Identifiers : ', NrOfIdents);
  writeln ('Number of Lines read: ', TotLines:9);
  }
end; { ClearNonIdents }

{ the following procedures are used for a neat termination of the
  programm.
}

{$F+} procedure ExitHandler; {$F-}

begin { ExitHandler }
  if ExitCode = 1 then           { user abort }
      writeln ('asm: aborted');

  if ExitCode > 200 then         { TP5 memory or stack problems }
      begin
        writeln ('asm: memory allocation error');
        ExitCode := 5;
      end;
  ExitProc := BreakAdd;
end; { ExitHandler }


{ V1.23a: The next procedure is hooked to Int1B and Int23 to trap
  user-abort. It is installed in MAIN by means of a call to GetSetBreak()
  It only sets a local flag, which is tested in NextLine (ASMINP.PAS).
}

procedure CtrlBreakHandler; //interrupt;
begin
  Interrupted := TRUE;
end;

{ the following function is used to set and restore the MS-DOS break
  (^C) checking,
  SetTo TRUE = break set and traps installed (only once in MAIN),
  SetTo FALSE = break checking restored, all files are closed, Ints restored
  and the program is stopped.

}

procedure GetSetBreak { (SetTo: boolean; Code: integer) };
begin
  if SetTo then

    begin
      GetCbreak (OldBreak);
      SetCBreak (TRUE);
      BreakAdd := ExitProc;
      ExitProc := @ExitHandler;
      Interrupted := FALSE;
      SetIntVec ($1b, @CtrlBreakHandler);
      SetIntVec ($23, @CtrlBreakHandler);
    end

  else

    begin
      //mem[$40:$71] := 0;
      SetCBreak (OldBreak);
      halt (Code);
    end;

end; { GetSetBreak }

{ procedure to store the patterns needed by main files: 
}

procedure StoMainPatt;
begin
  StoPatt ('"'        , Operand, Quote);
  StoPatt ('$'        , Operand, Dollar);
  StoPatt ('$MSUM'    , Operand, Msum); { V1.23x }
  StoPatt ('$PASS'    , Constant, 1);  { V1.10: constant gives current pass number }
  StoPatt ('$USR1'    , Constant, 0);
  StoPatt ('$USR2'    , Constant, 0);
  StoPatt ('$USR3'    , Constant, 0);
  StoPatt ('$USR4'    , Constant, 0);
  StoPatt ('$USR5'    , Constant, 0);
  StoPatt ('$USR6'    , Constant, 0);
  StoPatt ('$USR7'    , Constant, 0);
  StoPatt ('$USR8'    , Constant, 0);
  StoPatt ('$USR9'    , Constant, 0);
  StoPatt (#39        , Operand, Quote);
  Stopatt ('!!'       , Operand, XorOp);       { V1.13 XOR operator  }
  StoPatt ('!'        , Operand, OrOp);        { V1.13  OR operator  }
  StoPatt ('%'        , Operand, Modulo);
  StoPatt ('&'        , Operand, AndOp);       { V1.13 AND operator  }
  StoPatt ('('        , Operand, LBrace);
  StoPatt (')'        , Operand, RBrace);
  StoPatt ('*'        , Operand, Mult);
  StoPatt ('+'        , Operand, Plus);
  StoPatt (','        , Operand, Comma);
  StoPatt ('-'        , Operand, Minus);
  StoPatt ('/'        , Operand, Divide);  { V1.20 also used in ORG expression }
  StoPatt (':'        , Operand, Colon);
  StoPatt (';'        , EndLine, 0); { start of remark is end of 'active' line }
  StoPatt ('<'        , Operand, LessThan);
  StoPatt ('<='       , Operand, LessEqual);
  StoPatt ('<>'       , Operand, NotEqual);
  StoPatt ('='        , Operand, Equal);
  StoPatt ('>'        , Operand, MoreThan);
  StoPatt ('>='       , Operand, MoreEqual);
  StoPatt ('<<'       , Operand, ShftL);
  StoPatt ('>>'       , Operand, ShftR);
  StoPatt ('ABSOLUTE' , Operand, AbsoluteOp);  { V1.20 relocation type }
  StoPatt ('ABS'      , Operand, AbsOp);       { V1.24 ABS operator }
  StoPatt ('ASCII'    , OpCode , DefMemory);   { V1.20 }
  StoPatt ('BACKWARD' , Opcode,  Bward);       { V1.21 reverse word format }
  StoPatt ('BASE'     , Operand, BaseOp);      { V1.20 }
  StoPatt ('BYTE'     , OpCode , DefMemory);   { V1.20 DB changed to BYTE }
  StoPatt ('DB'       , OpCode , DefMemory);   { V1.20 DB changed to BYTE }
  StoPatt ('DBX'      , OpCode , DefMemoryX);   { V1.24f DB changed to BYTE }
  StoPatt ('DD'       , OpCode , DefDouble);
  StoPatt ('DEF'      , Operand, DefOp);       { V1.13: $IDEF changed to DEF }
  StoPatt ('DS'       , Opcode , DefStorage);  { V1.20 storage allocator }
  StoPatt ('DW'       , Opcode , DefWord);     { V1.13 define word }
  StoPatt ('EJECT'    , Opcode , EjectPage);
  StoPatt ('ELSE'     , Opcode , ElseOp);
  StoPatt ('END'      , Opcode , EndFile);
  StoPatt ('ENDIF'    , Opcode , EndIfOp);
  StoPatt ('ENDREP'   , Opcode , EndRepOp);
  StoPatt ('EQU'      , Opcode , Equate);
  StoPatt ('FOLD'     , Opcode , StartFold);
  StoPatt ('FORWARD'  , Opcode , Fward);       { V1.21 wordformat default }
  StoPatt ('GLOBAL'   , OpCode , DefGlobal);   { V1.20 }
  StoPatt ('HI'       , Operand, HiByte);      { V1.13 }
  StoPatt ('HW'       , Operand, HiWord);
  StoPatt ('IF'       , Opcode , IfOp);
  StoPatt ('INCL'     , Opcode , InclOp);      { V1.13 }
  StoPatt ('INCLUDE'  , Opcode , InclOp);      { V1.13 }
  StoPatt ('INPAGE'   , Operand, InPageOp);    { V1.20 relocation type }
  StoPatt ('LIST'     , Opcode , StartList);
  StoPatt ('LMARG'    , Opcode , LeftMarg);
  StoPatt ('LEFTMARG' , Opcode , LeftMarg);
  StoPatt ('LO'       , Operand, LoByte);      { V1.13 }
  StoPatt ('LW'       , Operand, LoWord);      { V1.13 }
  StoPatt ('MOD'      , Operand, Modulo);
  StoPatt ('NAME'     , Opcode , NameOp);      { V1.20 assign module name }
  StoPatt ('NOFLD'    , Opcode , StopFold);
  StoPatt ('NOFOLD'   , Opcode , StopFold);
  StoPatt ('NOLST'    , Opcode , StopList);
  StoPatt ('NOLIST'   , Opcode , StopList);
  StoPatt ('NOPROCES' , OpCode , ProcesOff);   { V1.20 pre-processor OFF }
  StoPatt ('OFFS'     , Opcode , SetLoadOffs);
  StoPatt ('ORG'      , Opcode , Origin);
  StoPatt ('PAGE'     , Opcode , SetPageLen);
  StoPatt ('PAGELEN'  , Opcode , SetPageLen);
  StoPatt ('PGLEN'    , Opcode , SetPageLen);
  StoPatt ('PRPROCES' , OpCode , ProcesOn);    { V1.20 pre-processor ON }
  StoPatt ('REPEAT'   , OpCode , RepOp);       { V1.20 section re-definition }
  StoPatt ('RESUME'   , OpCode , ResumeOp);    { V1.20 section re-definition }
  StoPatt ('SBTTL'    , Opcode , SetSubTitle); { V1.13 }
  StoPatt ('SECTION'  , Opcode , SegmentOp);   { V1.13 }
  StoPatt ('SET'      , Opcode , SetEquate);
  StoPatt ('SHL'      , Operand, ShftL);
  StoPatt ('SHR'      , Operand, ShftR);
  StoPatt ('STITLE'   , Opcode , SetSubTitle); { V1.13 }
  StoPatt ('STRING'   , Opcode , DefString);   { V1.20 define a string variabele }
  StoPatt ('TABS'     , Opcode , SetTabs);
  StoPatt ('TITLE'    , Opcode , SetTitle);
  StoPatt ('TOCON'    , Opcode , ToScreen);
  StoPatt ('TOLIST'   , Opcode , ToList);
  StoPatt ('WARNING'  , Opcode,  Warning);    { V1.21 }
  StoPatt ('WIDTH'    , Opcode , SetWidth);
  StoPatt ('WORD'     , Opcode , DefWord);     { V1.20 DW changed to WORD }
  StoPatt ('\'        , Operand, NotOp);       { V1.13 NOT operator  }
  StoPatt ('`'        , Operand, BQuote);      { V1.20 backquote }
end; { StoMainPatt }

{ the following procedure reads the user's wishes from the
  command line, if such a thing is given.
  Otherwise, the user has to answer some questions.

  V1.10: this procedure made more user-friendly, possibility
         added to specify ass'y switches with questions.
}

procedure HandleUser;
var ParamCntr,
    CharCntr  : integer;
    ParamErr  : boolean;
    ParamChar : char;

  { the following procedure extracts a file specification from
    the parameter string given by the user. The spec will be
    converted to an uppercase full path name
    ParamErr is set if an error occured.
  }

  procedure ExtractFile (var AFile: pathstr);

  var i : integer;
      d : dirstr;
      n : namestr;
      e : extstr;

  begin
    ParamErr := (ParamCntr > paramcount);
    if not ParamErr then
      if length (paramstr (ParamCntr)) <= 64 then
        begin
          AFile := fexpand (paramstr (ParamCntr));
          fsplit (Afile, d, n, e);
          ParamErr := n = '';
        end
      else
        ParamErr := TRUE;
    inc (ParamCntr);
  end; { ExtractFile }

procedure wrintro;
begin
  write ('VACS ', ProcFamily + Version,'  by A.C. Verschueren and ');
                         { set by Process (-1) }
  if length (InclAuthor) > 0 then
    write (InclAuthor)
  else
    write ('W.H. Taphoorn');
  writeln ('.');
  writeln;
end;

begin { HandleUser }
  ParamErr := FALSE;
  
  if paramcount > 0 then
    begin                    { parameters given, handle parameter line }
      ParamCntr := 1;
      ExtractFile (InFileSpec);
      ExtendSpec (InFileSpec,'.ASM');
      if not Exist (InFileSpec) then
        begin
          wrintro;
          writeln ('Unable to open ',InFileSpec);
          GetSetBreak (FALSE, 4);
        end;

      if not ParamErr then

        begin
              { filespec OK, and file exists;  set default List and Object
               file specs, equal to input file (name only) }

          OutFileSpec  := NameOf (InFileSpec);
          ListFileSpec := OutFileSpec;
          XrfFileSpec  := OutFileSpec;        { V 1.23: Cross reference file }

          while (not ParamErr) and (ParamCntr <= paramcount) do
                             { work through parameter list }
            begin
              if ParamCntr <= paramcount then
                begin
                  CurLine := paramstr (ParamCntr);
                  inc (ParamCntr);
                  CharCntr := 2;
                  if (length (CurLine) >= 2) and
                     ((CurLine[1] = '/') or (CurLine[1] = '-')) then
                    repeat   { V1.10: more switches possible in one block }
                      case upcase (CurLine[CharCntr]) of
                        'Q': Quiet := true;
                        'P': PreProcess := false;
                        'R': EnaErNum := TRUE;
                        'D': begin
                               EnaDebug := TRUE;
                               if (length (CurLine) > CharCntr) and
                                  (upcase (CurLine[CharCntr + 1]) = 'C') then
                                 begin
                                   inc (CharCntr);
                                   EnaDebugCol := TRUE;
                                   if (length (CurLine) > CharCntr) and
                                         (CurLine[CharCntr + 1] in [',',':',';','-','.']) then
                                      begin
                                        DebugSep[1] := CurLine[CharCntr + 1];
                                        inc (CharCntr);
                                      end;
                                 end;
                             end;
                        'B': if CharCntr = length (CurLine) then
                               begin
                                 CurLine := paramstr (ParamCntr);
                                 inc (ParamCntr);
                                 if length (CurLine) < 3 then
                                   begin
                                     Tabs := 0;
                                     if CurLine[1] in ['0'..'9'] then
                                       Tabs := Tabs + ord (Curline[1])-48
                                     else
                                       ParamErr := TRUE;
                                     if CurLine[2] in ['0'..'9'] then
                                       Tabs := (Tabs * 10) + ord (Curline[2])-48;
                                     if (Tabs < 4) or (Tabs > 20) then
                                       ParamErr := TRUE;
                                   end
                                 else
                                   ParamErr := TRUE;
                               end
                             else
                               ParamErr := TRUE;

                        'U': if UpFunc and (CharCntr = length (CurLine)) then
                               begin
                                 UpFuncLine := paramstr (ParamCntr);
                                 inc (ParamCntr);
                               end
                             else
                               ParamErr := TRUE;

                        'L': if CharCntr = length (CurLine) then
                               ExtractFile (ListFileSpec)
                             else
                               ParamErr := TRUE;

                        'O': if CharCntr = length (CurLine) then
                               ExtractFile (OutFileSpec)
                             else
                               ParamErr := TRUE;

                        'X': EnaXrf := TRUE; { V1.23 }

                        'E': ListStatus := ErrorsOnly;

                        'I': IdentStatus := Suppressed;

                        'S': EndRecord := FALSE;

                        'M': HexFormat := Motorola;

                        'T': HexFormat := Tektronix;   { V1.13 }

                        'N': EnaLineNum := TRUE;

                        'V': EnaUnused := TRUE;

                        'W': if HasExtWarn then
                               ExtWarn := false
                             else
                               ParamErr := true;

                        '1'..'9':        { V1.10: set a 'User Option' }
                              begin
                                StoPatt ('$USR'+CurLine[CharCntr], Constant,- 1);
                                { V1.23: set userflag }
                                UserFlag[ord (CurLine[CharCntr]) - $30] := TRUE;
                              end;
                        //'A': BinaryFormat := True; v1.24b
                        'K':
                        if CharCntr = length (CurLine) then
                               begin
                                 CurLine := paramstr (ParamCntr);
                                 val (CurLine,BinaryPad,TempI);
                                 if (TempI=0) and (BinaryPad>0) then
                                 begin
                                   inc (ParamCntr);
                                   CharCntr := length(CurLine);
                                 end
                                 else
                                   ParamErr := TRUE
                               end;
                        'C':
                        if CharCntr = length (CurLine) then
                               begin
                                 CurLine := paramstr (ParamCntr);
                                 val (CurLine,BinaryPadByte,TempI);
                                 if (TempI=0) and (BinaryPadByte>=0) and (BinaryPadByte<=255) then
                                 begin
                                   inc (ParamCntr);
                                   CharCntr := length(CurLine);
                                 end
                                 else
                                   ParamErr := TRUE
                               end

                        else ParamErr := TRUE;
                             { unrecognised character following '/' or '-' }

                      end; { case }

                      inc (CharCntr);
                    until ParamErr or (CharCntr > length (CurLine))

                  else
                    ParamErr := TRUE;
                             { switch block only one character long,
                               or no '/' or '-' present }
                end;
            end; { while not ParamErr .. }
        end;
    end;

  if ParamErr then
    begin
      if not Quiet then
        wrintro;
      writeln ('Command line error');
      GetSetBreak (FALSE, 5);
    end;

  if length (InFileSpec) = 0 then
                   { no command line given, ask what to do: }
    begin
      wrintro;
      write ('Give source filespec: ');
      readln (InFileSpec);

      if length (InFileSpec) = 0 then
        begin
          writeln ('Type ASM -h for help');
          GetSetBreak (FALSE, 0);
        end;

      ExtendSpec (InFileSpec,'.ASM');
      InfileSpec := fexpand (InFileSpec);

      if not exist (InFileSpec) then
        begin
          writeln ('Unable to open ',InFileSpec);
          GetSetBreak (FALSE, 0);
        end;

      write ('Give object filespec [NUL]: ');
      readln (OutFileSpec);
      if length (OutFileSpec) = 0 then
        OutFileSpec := 'NUL'
      else
        OutFileSpec := fexpand (OutFileSpec);

      write ('Give list   filespec [NUL]: ');
      readln (ListFileSpec);
      if length (ListFileSpec) = 0 then
        ListFileSpec := 'NUL'
      else
        ListFileSpec := fexpand (ListFileSpec);

      if UpFunc then
        begin
          write ('Give uP Definition or <CR>: ');
          readln (UpFuncLine);
        end;

      write ('Give options [qerd[c[,:;-.]]ismtnpv1..9] or <CR>: ');
      readln (CurLine);

      //for CharCntr := 1 to length (CurLine) do
      CharCntr := 1;
      while (CharCntr<Length(CurLine)) do
      begin
        case upcase (CurLine[CharCntr]) of
          'Q': Quiet := true;
          'E': ListStatus := ErrorsOnly;
          'R': EnaErNum := TRUE;
          'D': begin
                 EnaDebug := TRUE;
                 if (length (CurLine) > CharCntr) and
                           (upcase (CurLine[CharCntr + 1]) = 'C') then
                   begin
                     inc (CharCntr);
                     EnaDebugCol := TRUE;
                     if (length (CurLine) > CharCntr) and
                        (CurLine[CharCntr + 1] in [',',':',';','-','.']) then
                       begin
                         DebugSep[1] := CurLine[CharCntr + 1];
                         inc (CharCntr);
                       end;
                   end;
               end;
          'I': IdentStatus := Suppressed;
          'S': EndRecord := FALSE;
          'M': HexFormat := Motorola;
          'T': HexFormat := Tektronix;    { V1.13 }
          'N': EnaLineNum := TRUE;
          'V': EnaUnused := TRUE;
          'P': PreProcess := false;
          '1'..'9': begin
                      StoPatt ('$USR' + CurLine[CharCntr], Constant, - 1);
{ V1.23a }            UserFlag[ord (CurLine[CharCntr]) - $30] := TRUE;
                    end;
          ' ','/','-':      ; { skip spaces and option delimiters }
          else
           if HasExtWarn and (upcase (CurLine[CharCntr]) = 'W') then
              ExtWarn := false
           else
            begin
              writeln ('Option ',#39, CurLine[CharCntr], #39, ' not recognized.');
              GetSetBreak (FALSE, 0);
            end;
        end; { case }
        inc(CharCntr);
      end;
    end
      else
        if not quiet then
          wrintro;
end; { HandleUser }

begin
end.
