program asm32;
{$APPTYPE CONSOLE}


// {$R-,B-,S-,N-,A+,M 35000,0,640000}

{
  ASM.PAS,

                     VACS  Version 1.24a

  VACS is short for 'Verschueren Assembler Constuction Set',
  named after the guy who did the initial writing of all the
  programs.

  The  file  ASM.PAS is the  assembler main file and the files
  ASMVAR.PAS, ASMINI.PAS, ASMOUT.PAS,  ASMINP.PAS,  ASMEXP.PAS
  and  ASMHAN.PAS  are  the  unit files of the assembler.  The
  files ASMxx.INC are the processor (family) definition files.

  To build one  of  the  assemblers,  the  specific  ASMxx.INC
  should be copied to a file with the name ASMINC.PAS and com-
  piled using Turbo Pascal V5.0

  Because the .TPU files  have  dependencies  on  each  other,
  MAKEFILE  is  present for use with the Turbo MAKE utility to
  build a complete assembler.

 -----------------------------------------------------------------------

  Programs, up to V1.12, designed and written by ir. A.C. Verschueren,
  Eindhoven, November 20, 1987.
  V1.12 was donated to the public domain in November 1987.

  Programs redesigned by W.H. Taphoorn, Uithoorn, Fidonet 2:500/40.1547
    during 1988:  V1.13 .. V1.20 changes
  December 1988:  renamed to VACS V1.20 and converted for Turbo Pascal 5.0
      June 1990:  V1.21 additions


  VACS V1.2x  donated to the public domain,         December 1989.

 ------------------------------------------------------------------------


  additions V1.10:
  DEFW pseudo-op controlled by WordFormat (HiFirst or LoFirst)
       to allow for hi-lo word storage ('Motorola format').
       WordFormat  also  controls  character  pair  to integer
       translation for expression evaluation.
  DelPatt procedure can be used to delete a pattern.
  indented list of included files during pass 1.
  'forward' identifiers recognised (identifiers known  in pass
       2, which were not known at that point in pass 1).
  Expression  evaluation  changed so  that multiple errors can
       be detected. 'forward' Identifiers handled too.
  Storage format of identifiers changed to use  smaller amount
       of code (uses dirty turbo Pascal trick !).
  SET and '=' pseudo-op included for re-definable identifiers.
  SEG pseudo-op included for multiple location counters.
  Motorola S1-S9 Hex format added.
  New include file ('INITFN.PAS') to make this file shorter.
  List file line folding control possible.
  Minimum page width for WIDTH increased to 68 characters.
  Line numbering can be enabled (minimum WIDTH then 73 chars).
  Total number of lines displayed after first pass.
  Pagination can be switched off (set page length to 255).
  User switches and pass identification for assembly control.
  Load offset specification possible for object file.
  Possibility to send formatted strings to listing or screen.
  '*' at beginning of line denotes a remarks line.
  InclAuthor string  can be  used to  display  the name of the
       author of the ASMxx.INC file.

  Changes V1.11:
  Input file handled with Turbo Pascal blockread command.
  Bug removed 'INCL' function (endless loop if placed to close
       to the end of the file). SEE V1.12 !
  Bug removed 'OR' function (executed an 'XOR').

  Changes V1.12:
  Strategy for remembering 'INCL' file position changed to remove
       associated bug once and forever.
  Extra pseudovariables for conditional assembly
       (See: 'EXPRESS.PAS').
  Filename given in /E error report (eases finding the offending
       file when using includes).
  $IDEF pseudo-operator checks for the 'defined' state of an
       identifier.

  Changes V1.13:
  - Stdout buffered for MS-DOS redirection.
  - Bug in 'IF' function removed.
  - Set screen to Low intensity at start-up.
  - Variable 'PatLen' set to 7.
  - Changes from: AND  OR  XOR  NOT  $IDEF   INCL    SEG   (See: INITFN.PAS).
              to:  &   !   !!    \    DEF   INCLUDE SECTION
  - Program returns exit code 3 to MS-DOS if terminated with errors.
    (INITFN.PAS)
  - /T for Tektronix Hex format added (see also INITFN.PAS and OUTPUTFN.PAS).


  Additions V1.20:
  Most of V1.20 changes are preparations for the relocatable assembler
  version.
  - SECTION operand reversal (see sectiontypes below)
  - Optional sectiontypes: ABSOLUTE, PAGE and INPAGE
        SECTION MAIN,ABSOLUTE   ;non-relocatable section
        SECTION SUBS            ;byte-relocatable section
        SECTION DATA,PAGE       ;located on a page start: xx00H
        SECTION TEXT,INPAGE     ;byte-relocatable, totally inside a 100H page
  - RESUME pseudo opcode for section re-definition
     (Re-use of SECTION for same section name not longer allowed)
  - GLOBAL pseudo opcode: for global definition of identifiers.
        GLOBAL  name, name ..   ;will initialize all 'names' to 0000
  - BASE pseudo operator: to check the section base of a symbol.
    var CurExpBase in EXPRESS.PAS
    CurExpBase is TRUE if all identifiers in an expression share the same
                        base as the current section. See also EXPRESS.PAS
        IF  BASE <name>   ;this is true (-1) if <name> is initialized in the
                        ;current section (could be forward too).
  - Optional '/' (slash) unary operator for operands in ORG statements:
    if the slash is used, then the location counter is set to the next address
    that is a multiple of the value after the '/'. If the location counter is
    already on such an address, nothing is changed.
    Assume the location counter on 0355H
    then
        ORG  /100H    ;will set the location counter to 0400H
    but another
        ORG  /100H  ;will leave the location counter at 0400H
  - Commandline Option-indicator choise '-' or '/'
  - Additional commandline options:
        -h, -? or ?  = help screen
        -b <num>     = set tabs [4..20] (Default 8)
        -p           = suppress the pre-processor
        -q           = quietely operation
  - Skip option-indicators in interactive mode (some birds do enter them)
  - Program terminate if unrecognized options in interactive mode
  - Module checksum is appended to ListFile (just above 'Total Errors')
  - STRING pseudo opcode to declare identifier(s) as a stringvariabele
          STRING     str1, str2, ..
    Opcode SET modified for string assignments

  - Bug in ExtendSpec fixed (see ASMINI.PAS)
  - Warnings introduced by additional parameter in StoError() procedure
      StoError(0, 'This is an error')
      StoError(1, 'This is a warning')
  - Exit codes defined (see also ASMINI.PAS)
      Errorlevel: 0 = No Errors
                  1 = Console Abort
                  2 = Assembly Warnings detected
                  3 = Assembly Errors detected
                  4 = I/O problems
                  5 = Internal Error

  - Pre-processor for text replacements:
    Procedure NextLine will pre-process incoming data for text-replacements
    These are parameters enclosed in backquote characters ` (60H)
    current implementations are:
     `%` is replaced by the current section name (uppercase)
     `<ident>` is replaced by the string <ident>
     `@`, `#` and `<numexpr>` are reserved for macro expansion:
    Example:
             STRING    segname    ;declare SEGNAME to be a string variabele
             SECTION   rom
             ..
    segname  SET      "`%`"       ;SEGNAME is assigned ROM
             SECTION  ram         ;start new section
             ..
             RESUME   `segname`   ;resume ROM
             ..
    Character ^ (5EH) is used to flag the next character as a literal
    i.e. "This backquote doesn^`t generate an error"


  - The planning for text replacement at macro expansion time is:
     `#` is replaced by the number of call parameters (like argc in C)
     `n` where n = 1, 2, 3..
         is replaced by call parameter[n] (like argv[n] in C)
     `@` is replaced by a 4-char ascii string, representing the current
         macro invokation number
         (this is to create labels inside macros)
         i.e. LAB`@` is a unique 7-char label, for each macro expansion

  Additions V1.21:
  - BACKWARD and FORWARD pseudo instructions implemented to change order
    in which 'define-word' bytes are stored. FORWARD is uP default and
    BACKWARD sets reversed storage order.

  - WARNING pseudo instruction implemented.  This traps the assembler's
    error processor for user-defined warning messages.  Warning lines are
    sent to the listfile in the same way as normal warning reporting is
    done, except for the warning locationpointer.  User- defined text is
    appended to ** WARNING ** and sent to to the listfile.  Errorcount is
    updated.

        WARNING <user-string>

  Additions V1.22:

  - SetUserIdent() added, changes the current line label value.

  - /R option inserts line number info on error/warning lines in list file.

  - /D option display error lines on stdout in Microsoft (tm) format, for
       the use with intelligent editors.

  Changes V1.23a:
  - the Till32X construct is changed. The identifier array now contain
    28 single entries, holding the start addresses of 28 linked lists
    of identifier records (not 4 x 28). By using getmem() instead of new(),
    each record will now be adjusted to match the exact length of its
    identifier name. This makes it easier to travel along the linked lists.

  - boolean array 'UserFlag[0..15]' and integer array 'UserVar[0..15]' are
    appended for to forfill the need of static memory inside ASMINC.PAS.
    On start-up, all UserFlag[] entries will be set FALSE and all UserVar[]
    elements to zero. UserFlag[] and/or UserVar[] elements can be pre-set
    in ASMINC.PAS at Process(-1) tag.

    CAUTION: Due to lack of boundary-checking on both arrays, the 
             responsibility for keeping the indices into the 0..15 limits
             is totally to the ASMINC programmer !

    After reading the commandline, user options '1'..'9' (if entered) will
    set TRUE the corresponding entry in UserFlag[]. This feature enables
    expansion of the assembler options.

    Example:
      An assembler that generates 'Out of Internal Memory' warnings which
      can be suppressed with option '9', should have a part of the ASMINC 
      code look like:
         ...
         if (error_detected) and not UserFlag[9] then
           StoError (1, 'Out of Internal Memory');
         ...

  Changes V1.24:
   - introduction of VACS 32-bit version
       related pseudos:
        DD   define double
        HW   returns higher word of operand
        LW   returns lower word of operand
        =    8-digit hex formatter in DB, TOCON and TOLIST lists

   - start changing some names (keeping the old ones)
        <<   new syntax for for SHL operator
        >>   new syntax for for SHR operator

  Changes V1.24a:
	 - string handling modified: string identifiers now work everywhere a
	   string constant is needed

}



uses
  Dos in 'dos.pas',
  asmvar in 'ASMVAR.PAS',
  asmini in 'ASMINI.pas',
  asminp in 'ASMINP.pas',
  asmout in 'ASMOUT.pas',
  asmexp in 'ASMEXP.pas',
  asmhan in 'ASMHAN.pas',
  asminc in 'ASMINC.pas',
  asmxrf in 'ASMXRF.pas',
  types in 'TYPES.PAS';

var
  lTabs: Integer;
  lDollarPntr: Integer;
begin { MAIN ROUTINE }
  Version := ' V1.24i/w32';
  writeln;
  writeln ('VACS   Verschueren Assembler Construction Set ',ProcFamily + Version);
  writeln ('       The public domain modular assembler package, written by');
  writeln ('       A.C. Verschueren 1987 and W.H. Taphoorn, 1989..1993');
  writeln ('       Updated & ported to Win32 by D.D. Spreen, 2003..2022');
  writeln;

//  assign (output,'');         { V1.20 suppress direct video I/O }
//  rewrite (output);

  GetSetBreak (TRUE, 0);       { disable break checking and store old state }

  if paramcount > 0 then
    begin
      TabLine := ShortString(paramstr (1));  { misuse TabLine var }

      if ((TabLine[1] in ['-','/']) and (TabLine[2] in ['h','H','?']))
           or (TabLine[1] = '?') then
        begin
          {writeln;
          writeln ('VACS   Verschueren Assembler Construction Set ',ProcFamily + Version);
          writeln ('       The public domain modular assembler package, written by');
          writeln ('       A.C. Verschueren 1987 and W.H. Taphoorn, 1989..1993');
          writeln ('       Updated and ported to Win32 byDennis D. Spreen, 04/2003');
          writeln;}
          writeln ('Usage:    ASM [[d:][path]infile[.ext] [options]]  (default .ext = .ASM)');
          writeln ('     Options:');
          writeln ('       -l <file>    List File Name [Default infile.LST]');
          writeln ('       -o <file>    Object File Name [Default infile.HEX]');
          writeln ('       -e           List Error/Warning Lines Only');
          writeln ('       -r           Add Line Number Info to Error/Warning Lines');
          writeln ('       -d[c[<sep>]] Display Error/Warning Source Line Info');
          writeln ('       -i           Suppress Identifier Listing');
          writeln ('       -x           Generate Cross Reference File [infile.XRF]');
          writeln ('       -s           Suppress End Of Record in Object File');
          writeln ('       -m           Motorola Hex Format Object File');
          writeln ('       -t           Tektronix Hex Format Object File');
          writeln ('       -n           Append Line Numbers in List File');
          writeln ('       -b <num>     Set Tab Stops [num = 4..20]');
          writeln ('       -p           Suppress Pre-processor');
          writeln ('       -v           Generate Unused Labels Warning');
          writeln ('       -q           Quiet operation');
{V1.24b}  //writeln ('       -a           Generate Binary File ');
          writeln ('       -k <num>     Padd Binary File with 00h to [num] bytes');
          writeln ('       -c <byte>    Padd with <byte> [byte = 0..255 (decimal)] instead of 00h');

{V1.23h}  if HasExtWarn then
          writeln ('       -w           ' + ExtWarnStr);
{V1.23h}  if UpFunc then
          writeln ('       -u <opt>     uP specific options');
          writeln ('       -1..-9       User Switches 1 to 9');
          GetSetBreak (FALSE, 0);
        end;
    end;

  NrOfPatt    := 0;
  StoMainPatt;            { store main file patterns }
  WordFormat  := LoFirst; { assume Intel format for word storage }
  HexFormat   := Intel;   { assume Intel hex file to be generated }
  BinaryFormat := True;   { v1.24d: assume Binary format to be generated }

  for lTabs := 0 to 15 do  { V1.23a: misuse Tabs to clear static user-area }
    begin
      UserFlag[lTabs] := False;
      UserVar[lTabs] := 0;
    end;

  Process (-1);            { initialise processor specific patterns }

  if length (UserIDName) = 0 then
    UserIDName := 'SETvalue '
  else
    while length (UserIDName) < 9 do
      UserIDName := UserIDName + ' ';
  UserIDName[0] := chr (9);

  StartFormat := WordFormat; { V1.21 remember default word format }
  ListStatus  := Full;
  IdentStatus := Normal;
  EndRecord   := TRUE;
  EnaLineNum  := FALSE;
  EnaErNum    := FALSE; { V1.22 }
  EnaDebug    := FALSE; { V1.22 }
  EnaDebugCol := FALSE; { V1.22 }
  EnaXrf      := FALSE; { V1.23 }
  DebugSep    := ':';
  InFileSpec  := '';
  CurDef      := TRUE;
  Tabs        := 8;      { default tab settings }
  PreProcess  := true;   { V1.20: activate pre-processor by default }
  Quiet       := false;  { assume 'rumorous' processing }


  HandleUser;            { read user's wishes from command line,
                          or else issue questions and get answers }



  ExtendSpec (ListFileSpec, '.lst');
  ListFileSpec := fexpand (ListFileSpec);
  assign (ListFile, ListFileSpec);
  {$I-}  rewrite (ListFile);  {$I+}
  if ioresult <> 0 then
    begin
      writeln ('Unable to create ', ListFileSpec);
      write(#7);
      GetSetBreak (FALSE, 4);
    end;

  OutFileBinarySpec := OutFileSpec;
  ExtendSpec (OutFileBinarySpec, '.bin');

  ExtendSpec (OutFileSpec, '.hex');
  OutFileSpec := fexpand (OutFileSpec);

  assign (OutFile, OutFileSpec);
  {$I-}  rewrite (OutFile);  {$I+}
  if ioresult <> 0 then
    begin
      writeln ('Unable to create ', OutFileSpec);
      write(#7);
      GetSetBreak (FALSE, 4);
    end;

  if BinaryFormat then
  begin
    assign (OutFileBinary, OutFileBinarySpec);
    {$I-}  rewrite (OutFileBinary,1);  {$I+}
    if ioresult <> 0 then
      begin
        writeln ('Unable to create ', OutFileBinarySpec);
        write(#7);
        GetSetBreak (FALSE, 4);
      end;
  end;


  if EnaXrf then  { V1.23 open Xref file }
    begin
      ExtendSpec (XrfFileSpec, '.XRF');
      XrfFileSpec := fexpand (XrfFileSpec);
      assign (XrfFile, XrfFileSpec);
      {$I-}  rewrite (XrfFile);  {$I+}
      if ioresult <> 0 then
        begin
          write(#7);
          writeln ('Unable to create ', XrfFileSpec);
          EnaXrf := FALSE;
          GetSetBreak (FALSE, 4);
        end;
    end;

  for lDollarPntr := 0 to 28 do         { clear the identifier tables }
      IdentArray[lDollarPntr] := NIL;

  StringBase := NIL;

  new (DefaultSeg);           { initialize default segment pointer }
  CurSegment := DefaultSeg;   { start with default segment }
  with DefaultSeg^ do
    begin
      Def    := FPass;
      Val    := 0;
      LocPtr := 0;
      Typ    := Segment;
      SegNum := 0;
      Rel    := ByteRel;
      Name   := '%' + ShortString(NameOf (InFileSpec));
    end;
  NewSegNum := 1;

  Pass     := First;          { initialise for the first pass }
  HOutPntr := 0;
  TotLines := 0;
  TotSkipLines := 0;
  InitTabs (Tabs);
  ModName  := '*NONAME*';     { V1.20: assume unnamed module }
  if not Quiet then
    writeln ({#13, #10,} 'Starting First Pass');
  HandleFile (InFileSpec, 0);  { start nesting with the main input file }

  CurSegment^.LocPtr := HoutPntr; { update last used section }

  if EnaXrf then
    XrfStart;               { V1.23a: write sections and globals to XRF file}

{ --------------  First Pass Done -------------------- }

  PageWidth     := 80;       { initialise for the second pass }
  PageLength    := 66;
  SbTitleLine   := '';
  TitleLine     := '                                        ';
  LMargStr      := '                ';
  LMargStr[0]   := chr (0);
  LineCntr      := -1;
  PageCntr      := 1;
  DontPrint     := FALSE;
  ClearNonIdents;
  HOutString    := '';
  NrOfHexBytes  := 0;
  HOutCheck     := 0;
  ModuleSum     := 0;
  Pass          := Second;
  StoPatt ('$PASS', Constant, 2); { $PASS in source will now give 2 }
  HOutPntr      := 0;
  TotalErrors   := 0;
  TotalWarnings := 0;
  FoldEnable    := TRUE;
  LoadOffset    := 0;
  InitTabs (Tabs);
  CurSegment    := DefaultSeg;  { start with 'unnamed segment' }
  WordFormat    := StartFormat; { V1.21 re-gain default wordformat }
  NewSegNum     := 1;
  if not Quiet then
    begin
      writeln ('Starting Second Pass');
      writeln;
    end;
  HandleFile (InFileSpec, 0);  { start nesting with the main input file }

  close (OutFile);

  if BinaryFormat then
    close (OutFileBinary);

  if EnaXrf then { V1.23 }
    close (XrfFile);

  DefaultSeg^.Name := DefaultSeg^.Name + ' (default)';
  CountUnused;
  if (IdentStatus = Normal) and (NrOfIdents > 0) then
    ListIdents; { forces FormFeed before header }
  SbTitleLine := '';
  PrintHead;
  writeln (ListFile); { just an empty line }
  PrintHead;
  writeln (ListFile, LMargStr, 'Module Name:     ', ModName);
  PrintHead;
  writeln (Listfile, LMargStr, 'Module Checksum: ', HexEightStr (ModuleSum));
  GetDate (Year, Month, Day, WeekDay);
  GetTime (Hour, Minute, Sec, Sec100);
  writeln (ListFile);
  write (ListFile, LMargStr, Days[Weekday], 'day, ', Months[Month], ' ', Day,
         ', ', Year,'  ');
  if Hour < 10 then write (ListFile,'0');
  write (ListFile, Hour, ':');
  if Minute < 10 then write (ListFile, '0');
  write (ListFile, Minute, ':');
  if Sec < 10 then write (ListFile, '0');
  writeln (ListFile, Sec);
  PrintHead;
  writeln (ListFile);
  if not Quiet then
    begin
      if EnaDebug then  { V1.22 }
        writeln;
      write (TotLines:12,' Source Lines ', TotLines - TotSkipLines:7,
                         ' Assembled Lines ');

      //1.24i memavail is deprecated, and not really necessary anymore.
      //writeln (memavail:12,' Bytes Available');
      writeln;
    end;
  PrintHead;
  write (ListFile, TotLines:12, ' Source Lines ', TotLines - TotSkipLines : 7,
                                ' Assembled Lines ');
  //1.24i memavail is deprecated, and not really necessary anymore.
  //writeln (ListFile, memavail:12,' Bytes Available');
  PrintHead;
  writeln (ListFile);
  if (TotalErrors = 0) and (Unused = 0) then
    begin
      if not Quiet then
        begin
          writeln ('                >>>>   No Assembly Errors Detected.   <<<<');
        end;
      PrintHead;
      writeln (ListFile,'                >>>>   No Assembly Errors Detected.   <<<<');
      close (ListFile);
      GetSetBreak (FALSE, 0);       { restore break checking and exit 0 }
    end
  else
    begin
      if not Quiet then
        begin
          write ('');
          write (TotalErrors - TotalWarnings : 12,' Error');
          if TotalErrors - TotalWarnings <> 1 then write ('s');
          write (', ', TotalWarnings, ' Warning');
          if TotalWarnings <> 1 then write ('s');
          if EnaUnused then
            begin
              write (', ', Unused, ' Unused Label');
              if Unused <> 1 then write ('s');
            end;
          writeln ('.');
        end;
      PrintHead;
      write (ListFile, TotalErrors-TotalWarnings:12,' Error');
      if TotalErrors-TotalWarnings <> 1 then write (ListFile,'s');
      write (ListFile,', ', TotalWarnings,' Warning');
      if TotalWarnings <> 1 then write (ListFile,'s');
      if EnaUnused then
        begin
          write (ListFile,', ', Unused, ' Unused Label');
          if Unused <> 1 then write (ListFile,'s');
        end;
      writeln (ListFile,'.');
      close (ListFile);
      if TotalErrors - TotalWarnings <> 0 then
        GetSetBreak (FALSE, 3)     { restore break checking and exit 3 }
      else GetSetBreak (FALSE, 2); {    "      "      "     and exit 2 }
    end;
end.
