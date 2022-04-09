{$R-,B-,I-,S-,N-}

unit types;

interface

function iscntr  (ch:AnsiChar): boolean;
function islower (ch:AnsiChar): boolean;
function isupper (ch:AnsiChar): boolean;
function isdigit (ch:AnsiChar): boolean;
function ishex   (ch:AnsiChar): boolean;
function islabel (ch:AnsiChar): boolean;
function isspace (ch:AnsiChar): boolean;
function isalpha (ch:AnsiChar): boolean;
function tolower (ch:AnsiChar): AnsiChar;

implementation

uses SysUtils;

function iscntr  (ch:AnsiChar): boolean;
begin
  result := (ord(ch)<16);
end;


function islower (ch:AnsiChar): boolean;
//lower { 'a'..'z' }
begin
 result := ((ch>='a') and (ch<='z'));
end;


function isupper (ch:AnsiChar): boolean;
//upper { 'A'..'Z' }
begin
 result := ((ch>='A') and (ch<='Z'));
end;


function isdigit (ch:AnsiChar): boolean;
//digit   '0'..'9' }
begin
 result := ((ch>='0') and (ch<='9'));
end;

function ishex   (ch:AnsiChar): boolean;
//xdigit  { '0'..'9', 'A'..'F', 'a'..'f' }
begin
 result := ((ch>='A') and (ch<='F')) or
           ((ch>='a') and (ch<='f')) or
           ((ch>='0') and (ch<='9'));
end;

function islabel (ch:AnsiChar): boolean;
//labl  { 'A'..'Z', '0'..'9', '@', '$', '_' }
begin
 result := ((ch>='A') and (ch<='Z')) or
           ((ch>='0') and (ch<='9')) or
           (ch='@') or
           (ch='$') or
           (ch='_');
end;

function isspace (ch:AnsiChar): boolean;
begin
 result := (ch=' ');
end;

function isalpha (ch:AnsiChar): boolean;
// alpha { 'a'..'z', 'A'..'Z' }
begin
 result := ((ch>='a') and (ch<='z')) or
           ((ch>='A') and (ch<='Z'));
end;

function tolower (ch:AnsiChar): AnsiChar;
begin
  result := AnsiChar(LowerCase(String(ch))[1]);
end;

end.



; C-like typechecking for TurboPascal
;
; written by Wil Taphoorn
;


data      segment word public
data      ends

code      segment byte public

          assume  cs:code, ds:data

          public  isalpha, iscntr, islower, isupper
          public  isdigit, ishex, islabel, isspace, tolower

upper     equ       1     ; { 'A'..'Z' }
lower     equ       2     ; { 'a'..'z' }
digit     equ       4     ; { '0'..'9' }
blank     equ       8     ; { space    }
contr     equ      16     ; { NUL..US  }
xdigit    equ      32     ; { '0'..'9', 'A'..'F', 'a'..'f' }
alpha     equ      64     ; { 'a'..'z', 'A'..'Z' }
labl      equ     128     ; { 'A'..'Z', '0'..'9', '@', '$', '_' }

ascii     label   byte
          db       16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
          db       16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
          db        8,  0,  0,  0,128,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db      164,164,164,164,164,164,164,164,164,164,  0,  0,  0,  0,  0,  0
          db      128,225,225,225,225,225,225,193,193,193,193,193,193,193,193,193
          db      193,193,193,193,193,193,193,193,193,193,193,  0,  0,  0,  0,128
          db        0, 98, 98, 98, 98, 98, 98, 66, 66, 66, 66, 66, 66, 66, 66, 66
          db       66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          db        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0

iscntr    proc    far
          mov     ah, contr
          jmp     do_it

islower   proc    far
          mov     ah, lower
          jmp     do_it

isupper   proc    far
          mov     ah, upper
          jmp     do_it

isalpha   proc    far
          mov     ah, alpha
          jmp     do_it

isdigit   proc    far
          mov     ah, digit
          jmp     do_it

ishex     proc    far
          mov     ah, xdigit
          jmp     do_it

islabel   proc    far
          mov     ah, labl
          jmp     do_it

isspace   proc    far
          mov     ah, blank

do_it:    mov     di,ax
          and     di, 0ffh
          mov     al, cs: [di+ascii]
          and     al,ah
          xor     ah,ah
          ret     2

isspace   endp
islabel   endp
ishex     endp
isdigit   endp
isalpha   endp
isupper   endp
islower   endp
iscntr    endp

tolower   proc far
          cmp     al, 'A'
          jb      nolow
          cmp     al, 'Z'
          ja      nolow
          add     al, 20h
nolow:    ret     2
tolower   endp

code      ends
          end

