{$R-,B-,S-,N-}
unit asminc;

interface

uses     asmvar,
         asminp,
         asmini,
         asmout,
         asmexp;

procedure process(Commd:integer);

implementation

{
  file to be used with ASM.PAS, defining the Signetics 2650
  microprocessor registers and opcodes

  filename:   ASM50.INC                   Version: 1.24h

  this file should be copied to ASMINC.PAS to be included
  during compilation of the file ASM.PAS,  resulting in
  a 2650 family assembler.

  written by: W.H. Taphoorn  Date: June 6, 1990
  updated by: D.D. Spreen Date: May, 2003

  this program donated to the public domain,  June 1990.
}

procedure Process(Commd: integer);
const

{ the registers : }

  R0        = 0;
  R1        = 1;
  R2        = 2;
  R3        = 3;

{ the opcodes : }

  Adda_     = $8c;
  Addi_     = $84;
  Addr_     = $88;
  Addz_     = $80;
  Anda_     = $4c;
  Andi_     = $44;
  Andr_     = $48;
  Andz_     = $41;
  Bcfa_     = $9c;
  Bcfr_     = $98;
  Bcta_     = $1c;
  Bctr_     = $18;
  Bdra_     = $fc;
  Bdrr_     = $f8;
  Bira_     = $dc;
  Birr_     = $d8;
  Brna_     = $5c;
  Brnr_     = $58;
  Bsfa_     = $bc;
  Bsfr_     = $b8;
  Bsna_     = $7c;
  Bsnr_     = $78;
  Bsta_     = $3c;
  Bstr_     = $38;
  Bsxa_     = $bf;
  Bxa_      = $9f;
  Coma_     = $ec;
  Comi_     = $e4;
  Comr_     = $e8;
  Comz_     = $e0;
  Cpsl_     = $75;
  Cpsu_     = $74;
  Dar_      = $94;
  Eora_     = $2c;
  Eori_     = $24;
  Eorr_     = $28;
  Eorz_     = $20;
  Halt_     = $40;
  Iora_     = $6c;
  Iori_     = $64;
  Iorr_     = $68;
  Iorz_     = $60;
  Loda_     = $0c;
  Lodi_     = $04;
  Lodr_     = $08;
  Lodz_     = $00;
  Lpsl_     = $93;
  Lpsu_     = $92;
  Nop_      = $c0;
  Ppsl_     = $77;
  Ppsu_     = $76;
  Redc_     = $30;
  Redd_     = $70;
  Rede_     = $54;
  Retc_     = $14;
  Rete_     = $34;
  Rrl_      = $d0;
  Rrr_      = $50;
  Spsl_     = $13;
  Spsu_     = $12;
  Stra_     = $cc;
  Strr_     = $c8;
  Strz_     = $c1;
  Suba_     = $ac;
  Subi_     = $a4;
  Subr_     = $a8;
  Subz_     = $a0;
  Tmi_      = $f4;
  Tpsl_     = $b5;
  Tpsu_     = $b4;
  Wrtc_     = $b0;
  Wrtd_     = $f0;
  Wrte_     = $d4;
  Zbrr_     = $9b;
  Zbsr_     = $bb;

var Indirect: integer;

  procedure IncorrectReg;
  begin
    StoError(0,'Register Error');
    CurTyp := EndLine;
  end; { IncorrectReg }


  procedure IncorrectCond;
  begin
    StoError(0,'Invalid Condition');
    CurTyp := EndLine;
  end; { IncorrectReg }

  function AtComma: boolean;
  var h: boolean;
  begin
    h := (CurTyp = Operand) and (CurVal = Comma);
    if h
    then GetToken
    else
      begin
        StoError(0,'Comma Expected');
        CurTyp := EndLine;
      end;
    AtComma := h;
  end; { AtComma }

  procedure SetIndirect;
  begin
    if (CurTyp = Operand) and (CurVal = Mult) then
      begin
      GetToken;
      Indirect := $80;
      end
    else
      Indirect := 0;
  end; { SetIndirect }

  procedure DisposeToken(Code: integer);
  begin
    WriteByte(Code);
    GetToken;
  end; { DisposeToken }

  function IsReg: boolean;
  begin
    IsReg := (CurTyp = Register) and (CurVal >= R0) and (CurVal <= R3);
  end; { IsReg }

  function IsCond: boolean;
  begin
    IsCond := ((CurTyp = Constant) or ((CurTyp = Ident) and CurDef)) and (CurVal >= 0) and (CurVal <= 3);
  end; { IsCond }

  procedure Mode1;				{ Opcode  }
  begin
    WriteByte(Commd);
  end;

  procedure Mode2;           { Opcode r }
  begin
    if IsReg then
      DisposeToken(Commd + CurVal)
    else
      IncorrectReg;
  end;

  procedure Mode2a;           { Opcode r        (r = 1..3)}
  begin
    if IsReg then
      begin
        if (CurVal = 0) then
           StoError(0,'Invalid Register Usage')
        else
          DisposeToken(Commd + CurVal -1 );
      end
    else
      IncorrectReg;
  end;

  // v1.24g
  procedure Mode2b;           { Opcode r        (r = 1..3)}
  begin
    if IsReg then
      begin
        if (CurVal = 0) then       // convert LODZ R0 into IORZ
          Commd := Iorz_;
        DisposeToken(Commd + CurVal);  // fixed v1.24h
      end
    else
      IncorrectReg;
  end;


  procedure Mode3;           { Opcode,r }
  begin
    if AtComma then
      if IsReg then
        DisposeToken(Commd + CurVal)
      else
        IncorrectReg;
  end;

  procedure Mode3c;          { Opcode,c }
  begin
    if AtComma then
      if IsCond then
        DisposeToken(Commd + CurVal)
      else
        IncorrectCond;
  end;

  procedure Mode4;           { Opcode v         (v = 0..255)}
  begin
    //1.24i Expanded the lower bounds to -128 - was MustBeExpr(0,255) before.
    MustBeExpr(-128,255);
    WriteByte(Commd);
    WriteByte(CurExpVal);
    GetToken;
  end;

  procedure Mode5;           { Opcode,r v       (v = 0..255)}
  begin
    if AtComma then
      if IsReg then
        begin
          DisposeToken(Commd + CurVal);
          //1.24i Expanded the lower bounds to -128 - was MustBeExpr(0,255) before.
          MustBeExpr(-128,255);
          DisposeToken(CurExpVal);
          end
       else
         IncorrectReg;
  end;

  procedure Mode6;           { Opcode [*]z      (z = 0..63 or 8128..8191)}
  var Address:integer;
  begin
    SetIndirect;
    MustbeExpr(0,8191);
    Address := CurExpVal;
    if(((Address > 0) and (Address < 64)) or ((Address > 8127) and (Address < 8192))) then
      begin
      WriteByte(Commd);
      WriteByte((Address and 63) + Indirect);
      end
   else
     begin
       WriteByte(0);
       WriteByte(0);
       StoError(0,'Zero page address out of range');
     end;
  end;

  procedure Mode7;           { Opcode,r [*]d    (d = -64 .. +63)}
  begin
    if AtComma then
      if IsReg then
        begin
        DisposeToken(Commd + CurVal);
        SetIndirect;
        MustBeExpr(HOutPntr - 63, HOutPntr + 64);
        if CurDef and not CurExpBase then
            begin
            WriteByte(0);
            StoError(0,'Displacement out of Section');
            end
        else
        WriteByte(Indirect+((CurExpVal - HOutPntr -1)and 127));
        end
      else
        IncorrectReg;
  end;

  procedure Mode7c;          { Opcode,c [*]d    (d = -64 .. +63)}
  begin
    if AtComma then
      if IsCond then
        begin
        DisposeToken(Commd + CurVal);
        SetIndirect;
        MustBeExpr(HOutPntr - 63, HOutPntr + 64);
        if CurDef and not CurExpBase then
            begin
            WriteByte(0);
            StoError(0,'Displacement out of Section');
            end
        else
        WriteByte(Indirect+((CurExpVal - HOutPntr -1)and 127));
        end
      else
        IncorrectCond;
  end;

  procedure Mode7ca;          { Opcode,c [*]d   (d = -64 .. +63)}
  begin
    if AtComma then
      if IsCond then
        if CurVal <> 3 then
           begin
           DisposeToken(Commd + CurVal);
           SetIndirect;
           MustBeExpr(HOutPntr - 63, HOutPntr + 64);
           if CurDef and not CurExpBase then
               begin
               WriteByte(0);
               StoError(0,'Displacement out of Section');
               end
           else
           WriteByte(Indirect+((CurExpVal - HOutPntr -1)and 127));
           end
        else
          IncorrectCond;
  end;

  procedure Mode8;           { Opcode,r [*]a    (a = 0..32767) }
  begin
    if AtComma then
      if IsReg then
        begin
        DisposeToken(Commd + CurVal);
        SetIndirect;
        MustBeExpr(0,32767);
        WriteByte(Indirect+ hi(CurExpVal));
        WriteByte(lo(CurExpVal));
        end
      else
        IncorrectReg;
  end;

  procedure Mode8c;          { Opcode,c  [*]a   (a = 0..32767) }
  begin
    if AtComma then
      if IsCond then
        begin
        DisposeToken(Commd + CurVal);
        SetIndirect;
        MustBeExpr(0,32767);
        WriteByte(Indirect+ hi(CurExpVal));
        WriteByte(lo(CurExpVal));
        end
      else
        IncorrectCond;
  end;

  procedure Mode8ca;          { Opcode,c  [*]a    (a = 0..32767) }
  begin
    if AtComma then
      if IsCond then
        if CurVal <>3 then
           begin
           DisposeToken(Commd + CurVal);
           SetIndirect;
           MustBeExpr(0,32767);
           WriteByte(Indirect+ hi(CurExpVal));
           WriteByte(lo(CurExpVal));
           end
        else
          IncorrectCond;
  end;

  procedure Mode9;           { Opcode [*]a[,3] }
  var SavPtr: integer;
  begin
    WriteByte(Commd);
    SetIndirect;
    MustBeExpr(0,32767);
    WriteByte(Indirect+ hi(CurExpVal));
    WriteByte(lo(CurExpVal));

    // v1.24d
    if (CurTyp = Operand) and (CurVal = Comma) then
    begin

    if AtComma then
      begin
      SavPtr := ErrorPntr;
      if IsReg then
        begin
        CurExpVal := CurVal;
        GetToken;
        end
      else
        MustBeExpr(0,0);
      if (CurExpVal <> 3) then
        begin
        ErrorPntr := SavPtr;
        StoError(1,'Replaced by Index Register R3');
        end;
      end;
    end
    else
      CurExpVal := 3; // use r3
  end;


  // v1.24f
  procedure Mode10;          { Opcode,r [*]p [,x] [,] [+/-]     (p = 0..8191) }
  var IndexControl, Register, Address:integer;
      page: Integer;
  begin
    if AtComma then
      if IsReg then
        begin
        Register := CurVal;   { save 0..3 register equate }
        GetToken;             { skip r, read next token }
        SetIndirect;          { if '*' is present, set Indirect + skip '*' }

        // v1.24g page boundary
        page := (HoutPntr shr 13) shl 13;
        MustBeExpr(page+0,page+8191);   { read p (must be 0..8191) and read next token }
        Address := CurExpVal-page;      { save result from MustBeExpr() }

        IndexControl := 0;    { assume no index, let's work on it }

        if (CurTyp = Operand) and (CurVal = Comma) then
          begin
          GetToken;           { remove comma, read next token }
          if Isreg then       { if r0..r3 }
            begin
            Register := CurVal; { save index register equate }
            IndexControl := $60;{ assume IndexControl "indexed-only" }
            GetToken;           { and remove x from input }
            end;


           // v1.24d
          if (CurTyp = Operand) and (CurVal = Comma) then
           GetToken;           { remove comma, read next token }

			    { test for trailing '-' or '+' (auto-indexing }
          if (CurTyp = Operand) and ((CurVal = Plus) or (CurVal = Minus)) then
          begin
            if(CurVal = Plus) then
              IndexControl := $20
            else
              IndexControl := $40;
            GetToken;
          end



          end;

        { finally write the code-bytes }

        WriteByte(Commd + Register);
        WriteByte(Indirect + IndexControl + hi(Address));
        WriteByte(lo(Address));
        end
      else
        IncorrectReg;
  end;


begin { Process }
  case Commd of
    Adda_ : Mode10;
    Addi_ : Mode5;
    Addr_ : Mode7;
    Addz_ : Mode2;
    Anda_ : Mode10;
    Andi_ : Mode5;
    Andr_ : Mode7;
    Andz_ : Mode2a;
    Bcfa_ : Mode8ca;
    Bcfr_ : Mode7ca;
    Bcta_ : Mode8c;
    Bctr_ : Mode7c;
    Bdra_ : Mode8;
    Bdrr_ : Mode7;
    Bira_ : Mode8;
    Birr_ : Mode7;
    Brna_ : Mode8;
    Brnr_ : Mode7;
    Bsfa_ : Mode8ca;
    Bsfr_ : Mode7ca;
    Bsna_ : Mode8c;
    Bsnr_ : Mode7c;
    Bsta_ : Mode8c;
    Bstr_ : Mode7c;
    Bsxa_ : Mode9;
    Bxa_  : Mode9;
    Coma_ : Mode10;
    Comi_ : Mode5;
    Comr_ : Mode7;
    Comz_ : Mode2;
    Cpsl_ : Mode4;
    Cpsu_ : Mode4;
    Dar_  : Mode3;
    Eora_ : Mode10;
    Eori_ : Mode5;
    Eorr_ : Mode7;
    Eorz_ : Mode2;
    Halt_ : Mode1;
    Iora_ : Mode10;
    Iori_ : Mode5;
    Iorr_ : Mode7;
    Iorz_ : Mode2;
    Loda_ : Mode10;
    Lodi_ : Mode5;
    Lodr_ : Mode7;
    Lodz_ : Mode2b;
    Lpsl_ : Mode1;
    Lpsu_ : Mode1;
    Nop_  : Mode1;
    Ppsl_ : Mode4;
    Ppsu_ : Mode4;
    Redc_ : Mode3;
    Redd_ : Mode3;
    Rede_ : Mode5;
    Retc_ : Mode3c;
    Rete_ : Mode3c;
    Rrl_  : Mode3;
    Rrr_  : Mode3;
    Spsl_ : Mode1;
    Spsu_ : Mode1;
    Stra_ : Mode10;
    Strr_ : Mode7;
    Strz_ : Mode2a;
    Suba_ : Mode10;
    Subi_ : Mode5;
    Subr_ : Mode7;
    Subz_ : Mode2;
    Tmi_  : Mode5;
    Tpsl_ : Mode4;
    Tpsu_ : Mode4;
    Wrtc_ : Mode3;
    Wrtd_ : Mode3;
    Wrte_ : Mode5;
    Zbrr_ : Mode6;
    Zbsr_ : Mode6;

    -1:
      begin
        InclAuthor := 'W.H. Taphoorn';
        WordFormat := HiFirst;

        StoPatt('R0'   ,Register, R0);
        StoPatt('R1'   ,Register, R1);
        StoPatt('R2'   ,Register, R2);
        StoPatt('R3'   ,Register, R3);

        StoPatt('ADDA' ,Opcode, Adda_);
        StoPatt('ADDI' ,Opcode, Addi_);
        StoPatt('ADDR' ,Opcode, Addr_);
        StoPatt('ADDZ' ,Opcode, Addz_);
        StoPatt('ANDA' ,Opcode, Anda_);
        StoPatt('ANDI' ,Opcode, Andi_);
        StoPatt('ANDR' ,Opcode, Andr_);
        StoPatt('ANDZ' ,Opcode, Andz_);
        StoPatt('BCFA' ,Opcode, Bcfa_);
        StoPatt('BCFR' ,Opcode, Bcfr_);
        StoPatt('BCTA' ,Opcode, Bcta_);
        StoPatt('BCTR' ,Opcode, Bctr_);
        StoPatt('BDRA' ,Opcode, Bdra_);
        StoPatt('BDRR' ,Opcode, Bdrr_);
        StoPatt('BIRA' ,Opcode, Bira_);
        StoPatt('BIRR' ,Opcode, Birr_);
        StoPatt('BRNA' ,Opcode, Brna_);
        StoPatt('BRNR' ,Opcode, Brnr_);
        StoPatt('BSFA' ,Opcode, Bsfa_);
        StoPatt('BSFR' ,Opcode, Bsfr_);
        StoPatt('BSNA' ,Opcode, Bsna_);
        StoPatt('BSNR' ,Opcode, Bsnr_);
        StoPatt('BSTA' ,Opcode, Bsta_);
        StoPatt('BSTR' ,Opcode, Bstr_);
        StoPatt('BSXA' ,Opcode, Bsxa_);
        StoPatt('BXA'  ,Opcode, Bxa_);
        StoPatt('COMA' ,Opcode, Coma_);
        StoPatt('COMI' ,Opcode, Comi_);
        StoPatt('COMR' ,Opcode, Comr_);
        StoPatt('COMZ' ,Opcode, Comz_);
        StoPatt('CPSL' ,Opcode, Cpsl_);
        StoPatt('CPSU' ,Opcode, Cpsu_);
        StoPatt('DAR'  ,Opcode, Dar_);
        StoPatt('EORA' ,Opcode, Eora_);
        StoPatt('EORI' ,Opcode, Eori_);
        StoPatt('EORR' ,Opcode, Eorr_);
        StoPatt('EORZ' ,Opcode, Eorz_);
        StoPatt('HALT' ,Opcode, Halt_);
        StoPatt('IORA' ,Opcode, Iora_);
        StoPatt('IORI' ,Opcode, Iori_);
        StoPatt('IORR' ,Opcode, Iorr_);
        StoPatt('IORZ' ,Opcode, Iorz_);
        StoPatt('LODA' ,Opcode, Loda_);
        StoPatt('LODI' ,Opcode, Lodi_);
        StoPatt('LODR' ,Opcode, Lodr_);
        StoPatt('LODZ' ,Opcode, Lodz_);
        StoPatt('LPSL' ,Opcode, Lpsl_);
        StoPatt('LPSU' ,Opcode, Lpsu_);
        StoPatt('NOP'  ,Opcode, Nop_);
        StoPatt('PPSL' ,Opcode, Ppsl_);
        StoPatt('PPSU' ,Opcode, Ppsu_);
        StoPatt('REDC' ,Opcode, Redc_);
        StoPatt('REDD' ,Opcode, Redd_);
        StoPatt('REDE' ,Opcode, Rede_);
        StoPatt('RETC' ,Opcode, Retc_);
        StoPatt('RETE' ,Opcode, Rete_);
        StoPatt('RRL'  ,Opcode, Rrl_);
        StoPatt('RRR'  ,Opcode, Rrr_);
        StoPatt('SPSL' ,Opcode, Spsl_);
        StoPatt('SPSU' ,Opcode, Spsu_);
        StoPatt('STRA' ,Opcode, Stra_);
        StoPatt('STRR' ,Opcode, Strr_);
        StoPatt('STRZ' ,Opcode, Strz_);
        StoPatt('SUBA' ,Opcode, Suba_);
        StoPatt('SUBI' ,Opcode, Subi_);
        StoPatt('SUBR' ,Opcode, Subr_);
        StoPatt('SUBZ' ,Opcode, Subz_);
        StoPatt('TMI'  ,Opcode, Tmi_ );
        StoPatt('TPSL' ,Opcode, Tpsl_);
        StoPatt('TPSU' ,Opcode, Tpsu_);
        StoPatt('WRTC' ,Opcode, Wrtc_);
        StoPatt('WRTD' ,Opcode, Wrtd_);
        StoPatt('WRTE' ,Opcode, Wrte_);
        StoPatt('ZBRR' ,Opcode, Zbrr_);
        StoPatt('ZBSR' ,Opcode, Zbsr_);
      end;
    end; { case Commd }
end; { Process }
begin
        ProcFamily := '2650 Cross Assembler';
end.

