{$R-,B-,S-,N-,A+}
unit asmvar;

interface
uses dos;
{
 --------------------------------------------------------------------------

  V1.13 and later changes by W.H. Taphoorn
  
  Changes for V1.23a:
  - IdenTillX construction changed to only one 0..28 array. Identifier
    records now are adjusted to the exact name length.
  - HexTwoStr and HexFourStr functions added.
}



const  MaxPat      = 500;    {max nr of patterns lexical analiser}
       PatLen      = 8;      {max nr of chars in pattern}
       MaxError    = 4;      {max nr of error lines per line}
       MaxInclude  = 32;     {max nr of file INCLude levels}

{ the "Operands" (negative numbers reserved for main file): }

       Minus       = -1;
       Plus        = -2;
       Mult        = -3;
       Divide      = -4;
       ShftL       = -5;
       ShftR       = -6;
       LBrace      = -7;
       RBrace      = -8;
       Dollar      = -9;
       Quote       = -10;
       LoByte      = -11;
       HiByte      = -12;
       Equal       = -13;
       NotEqual    = -14;
       LessThan    = -15;
       LessEqual   = -16;
       MoreThan    = -17;
       MoreEqual   = -18;
       AndOp       = -19;
       OrOp        = -20;
       XorOp       = -21;
       NotOp       = -22;
       Comma       = -23;
       Modulo      = -24;
       Colon       = -25;
       DefOp       = -26;    { V1.12: checks if identifier defined }
       AbsoluteOp  = -27;    { V1.20: section type }
       InPageOp    = -29;    { V1.20: section type }
       BaseOp      = -30;    { V1.20: test for identifier in current section }
       BQuote      = -31;    { V1.20: backquote for replacement identifier   }
       Msum        = -32;    { V1.23: returns current ModuleSum }
       HiWord      = -33;    { V1.24: returns bit 16..31 of operand }
       LoWord      = -34;    { V1.24: returns bit 0..15 of operand }
       AbsOp       = -35;    { V1.24: returns absolute value of operand }

{ The "Opcodes" (negative numbers reserved for main file): }

       Equate      = -1;
       Origin      = -2;
       DefStorage  = -3;
       DefMemory   = -4;
       DefWord     = -5;
       EndFile     = -6;
       SetTabs     = -7;
       SetTitle    = -8;
       SetSubTitle = -9;
       SetWidth    = -10;
       SetPageLen  = -11;
       EjectPage   = -12;
       StopList    = -13;
       StartList   = -14;
       LeftMarg    = -15;
       IfOp        = -16;
       ElseOp      = -17;
       EndIfOp     = -18;
       InclOp      = -19;
       SetEquate   = -20;
       SegmentOp   = -21;
       StopFold    = -22;
       StartFold   = -23;
       ToList      = -24;
       ToScreen    = -25;
       SetLoadOffs = -26;
       DefGlobal   = -27; { V1.20 }
       ResumeOp    = -28; { V1.20 }
       DefString   = -29;
       ProcesOff   = -30; { V1.20 }
       ProcesOn    = -31; { V1.20 }
       NameOp      = -32; { V1.20 }
       Bward       = -33; { V1.21 }
       Fward       = -34; { V1.21 }
       Warning     = -35; { V1.21 }
       DefDouble   = -36;
       RepOp       = -37;
       EndRepOp    = -38; // was 37 - changed in v1.24b
       DefMemoryX  = -39; // v1.24f new in
       NoOpFound   = -32767; { no opcode found at all }

{ identifier definition states:  pointer^.Def }

       NotYet      = 0;
       FPass       = 1;
       SPass       = 2;
       Global      = 4; { V1.20 }

{ token types pointer^.Typ (numbers 0..15 reserved for main file): }

       Ident       = 0;
       Opcode      = 1;
       Register    = 2;
       UnDef       = 3;
       Operand     = 4;
       Constant    = 5;
       EndLine     = 6;
       SetIdent    = 7;
       Segment     = 8;
       StrIdent    = 9; { V1.20 string identifier }
       UserIdent   =10; { V1.21 new typedef for SetUserIdent }
       LocalLabel  =11; { V1.23b }

       Days        : array[0..6] of string[6] =
                     ('Sun','Mon','Tues','Wednes','Thurs','Fri','Satur');
       Months      : array[1..12] of string[9] =
                     ('January','February','March','April','May','June',
                      'July','August','September','October','November',
                      'December');

       HexString   : array[0..15] of AnsiChar = '0123456789ABCDEF';
       DotString   : string[32] = ' . . . . . . . . . . . . . . . .';

type   AsciiStr    = string[8];
       PatName     = string[PatLen];
       Pattern     = record
                       Name   : PatName;
                       Typ    : byte;
                       Val    : longint;
                     end;

       RelocType   = (AbsRel, ByteRel, PageRel, InPageRel); { V1.20 }
       String32    = string[32];
       StrRecPtr   = ^StrRec;
       StrRec      = record
                       Val     : longint;
                       Next    : StrRecPtr;
                       Name    : String32;
                     end;

       { from V1.23a, the Till32X construct is changed. The identifier
         array now contain 28 single entries that point to the start of 
         28 linked lists of identifier records (not 4 x 28). By use of
         getmem () instead of new (), each record is now adjusted to match
         the exact length of its identifier name.
        }

       IdentPtr    = ^IdentRec; { V1.23a }

       IdentRec    = record
                       Def    : byte;      { V1.20: changed to bitmap }
                       RefTo  : boolean;   { V1.23h: label is referred to }
                       Val    : longint;   { section base, value for others }
                       LocPtr : longint;   { V1.20: section location pointer }
                       Typ    : byte;
                       SegNum : integer;   { V1.20: section number of origin }
                       Rel    : RelocType; { V1.20: segment relocation type }
                       Next   : IdentPtr;
                       Name   : String32;
                     end;

       ExprRes     = record  { short for expression result }
                       Val    : longint;
                       Def    : boolean;
                       Forw   : boolean;
                             { Forw = identifier used before definition }
                       Base   : boolean; { V1.20 }
                             { Base = identifier in current section }
                       IsUser  : boolean;   { V1.21: if UserIdent }
                       RefDef  : boolean;   { V1.23: if symbolic reference }
                       RefBase : longint;   {        referenced section    }
                       RefVal  : longint;   {        referenced label      }
                       RefName : string[32];{        referenced name       }
                     end;

       ANumberStr  = string[5];
       ErrorString = string[30];
       Sector      = array[0..511] of AnsiChar;

const  IdentRecSize    = sizeof (IdentRec) - 32;

var    InFile        : file;   { V1.11: needed declaration for blockread }
       OutFileBinary : file;
       ListFile,
       XrfFile,
       OutFile       : text;
       InFileSpec,
       OutFileSpec,
       ListFileSpec,
       XrfFileSpec,
       OutFileBinarySpec,
       CurrFileName  : pathstr;
       Interrupted,
       OldBreak,
       CurrFileNew   : boolean;
       CurSector     : Sector;
       SectorCont,           { V1.11: number of bytes read from sector }
       SectorPntr    : integer;
       SectorPos     : longint;   { V1.12: pos of current sector in file }
       IdentArray    : array[0..28] of IdentPtr;
                             { array with pointers to the start of linked
                               lists. all identifiers in a list start with
                               the same character, which can be a letter,
                               '$', '_' or '@'. the lists themselves are
                               ordered alphabetically. }

       CurIdent      : IdentPtr;
       NrOfIdents    : integer;
                             { identifiers counted at end of first loop }
       CurQuoted     : string[255];

       UpFuncLine    : string[255]; { V1.23h }
       UpFuncNum     : word;        { V1.23h }
       UpFunc,                      { V1.23h }
       UpFuncDef     : boolean;     { V1.23h }

       ModName       : string[32];
       SeekStr       : string[32];
       Version       : string[11];
       UserIDName    : string[9];
       QuoteChar     : AnsiChar;

       Patterns      : array[1..MaxPat] of Pattern;
       NrOfPatt      : integer;

       Errors        : array[1..MaxError] of record
                         Code : longint;
                         Txt  : string[255];
                       end;
       Unused,
       ErrorPntr,
       OpcodePos,
       NrOfErrors,              { number of errors found in a line }
       TotalErrors,
       TotalWarnings : integer;

       HasExtWarn,                 { V1.23i }
       ExtWarn       : boolean;    { V1.23i }
       ExtWarnStr    : string[50]; { V1.23i }
       LineNumber    : word;    { line number in one (include) file }
       TotLines      : longint;
       TotSkipLines  : longint; { total number of lines (up to 327670000 !) }
       EndOfLine,
       EndOfFile,
       DontPrint,               { listing suppressed for one line }
       EndRecord,               { don't generate end of file record }
       CurLabelDef,             { V1.21: used by SetUserIdent (ASMINP.PAS) }
       BlockAll,
       BlockRefTo    : boolean; { V1.23h: block label reference marking }
       CurExpUserPos,
       CurExpRefVal,            { V1.23: symbolvalue in expression }
       CurExpRefBase,           { V1.23: section number of CurExpRefVal }
       CurExpVal     : longint;
       CurExpRefName : string[32];
       CurExpBase,              { expression's identifiers are all intersegment }
       CurExpUser,              { expression contain UserIdent(s) }
       CurExpDef,
       CurExpForw,              { expression contains 'forward' identifiers }
       CurForw,                 { identifier is 'forward' defined }
       CurDef,
       CurExpRefDef,            { V1.23: symbol found in expression }
       FoldEnable,
       Quiet,
       EnaErNum,                { V1.22: line number info in error listfile }
       EnaDebug,                { V1.22: debug enabled }
       EnaDebugCol,             { V1.22: debug columns enabled }
       EnaXrf,                  { Xref list enabled }
       EnaUnused,               { V1.24 unused label report enabled }
       EnaLineNum    : boolean;
       CurTyp        : byte;
       CurVal,
       DollarPntr    : longint;
       LineCntr,
       PageWidth,
       PageCntr,
       PageLength,
       CurLinePntr   : integer;
       CurLine,
       TitleLine,
       SbTitleLine,
       TabLine       : string[255];
       DebugSep      : string[1];
       Tabs          : integer;
       StLinePntr    : integer;
       StartLine     : string[18];
       LMargStr      : string[16];
       ProcFamily,
       InclAuthor    : string[41];  { banner width is only 41 characters ! }
       HOutString    : string[48];
       FirstSum,          { for Tektronix HexFormat, V1.13 and up }
       SecondSum,         {     ditto                             }
       NrOfHexBytes,
       HOStringPntr,
       HOutCheck     : integer;

       HOutAddr,
       HOutPntr,
       LoadOffset,
       OldLoadOffs,
       ModuleSum     : longint;   { V1.20 module checksum implementation  }

       DefaultSeg,                { V1.20 default segment pointer }
       CurLabel,                  { V1.21: used by SetUserIdent }
       CurSegment    : IdentPtr;

       NewSegNum     : integer;   { V1.20 number of highest declared section }
       Pass          : (First, Second);
       ListStatus    : (Stopped, Full, ErrorsOnly);
       IdentStatus   : (Normal, Suppressed);
       StartFormat,
       WordFormat    : (LoFirst, HiFirst);
       HexFormat     : (Intel, Motorola, Tektronix);   { V1.13 }
       BinaryFormat  : boolean; {V22}
       BinaryPad     : integer;
       BinaryPadByte : byte;

       PreProcess,
       BreakState    : boolean;

       BreakAdd      : pointer;     { old INT 23H pointer (^C handling) }

       NormBuffer,
       LockBuffer    : AnsiChar;

       StringBase,
       StringPntr,
       StringHelp    : StrRecPtr;

       Year,
       Month,
       Day,
       WeekDay,
       Hour,
       Minute,
       Sec,
       Sec100        : word;

       UserFlag      : array[0..15] of boolean; { V1.23a }
       UserVar       : array[0..15] of longint; { V1.23a }

function HexTwoStr (i : longint) : AsciiStr;
function HexFourStr (i : longint) : AsciiStr;
function HexSixStr (i : longint) : AsciiStr;
function HexEightStr (i : longint) : AsciiStr;

implementation

function HexTwoStr (i : longint) : AsciiStr;
begin
  HexTwoStr := HexString[(i shr 4) and 15] +
               HexString[i and 15];
end;

function HexFourStr (i : longint) : AsciiStr;
begin
  HexFourStr :=  HexString[(i shr 12) and 15] +
                 HexString[(i shr 8) and 15] +
                 HexString[(i shr 4) and 15] +
                 HexString[i and 15];
end;

function HexSixStr (i : longint) : AsciiStr;
begin
  HexSixStr := HexString[(i shr 20) and 15] +
               HexString[(i shr 16) and 15] +
               HexString[(i shr 12) and 15] +
               HexString[(i shr 8) and 15] +
               HexString[(i shr 4) and 15] +
               HexString[i and 15];

end;

function HexEightStr (i : longint) : AsciiStr;
begin
  HexEightStr := HexString[(i shr 28) and 15] +
                 HexString[(i shr 24) and 15] +
                 HexString[(i shr 20) and 15] +
                 HexString[(i shr 16) and 15] +
                 HexString[(i shr 12) and 15] +
                 HexString[(i shr 8) and 15] +
                 HexString[(i shr 4) and 15] +
                 HexString[i and 15];

end;

begin
  UpFunc := false;     { V1.23h }
  UpFuncDef := false;  { V1.23h }
  UpFuncLine := '';    { V1.23h }
  HasExtWarn := false; { V1.23i }
  ExtWarn := true;     { V1.23i }
  ExtWarnStr := '';    { V1.23i }
  InclAuthor := '';
  UserIdName := '';
  EnaUnused  := FALSE;
  BinaryPad  := 0;
  BinaryPadByte := 0;
end.
