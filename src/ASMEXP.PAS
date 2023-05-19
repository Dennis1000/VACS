{$R-,B-,S-,N-,A+}
unit asmexp;

interface

uses     asmvar,
         asmini,
         asminp;

procedure Expression (Lower, Upper: longint);
procedure MustBeExpr (l, h: longint);
function  IsString: boolean;

implementation


{
  This file  contains  the expression  evaluator  for  ASM.

  Filename:   EXPRESS.PAS        To be included in: ASM.PAS

  No changes for V1.10 and V1.11.

  Added from V1.12:
  $IDEF pseudo-operator added to check whether identifier is
        defined already.

  Changes to V1.13:
  $IDEF changed to DEF

  Changes to V1.20:
  Prepare for relocatable assembler

  Written By: ir. A.C. Verschueren  Date: November 20, 1987
  V1.13 ad V1.20 changes by W.H. Taphoorn

  This program donated to the public domain, November 1987.

}

{ this expression evaluator is fairly standard, NormExpr
  is the actual expression machine, calls itself if it
  finds () constructs.
}

procedure NormExpr (var Result: ExprRes);
var   ExprOper:   integer;
      ExprSubRes: ExprRes;
      ExprGoOn:   boolean;
      OperandPtr: integer;

{ perform +/-num-const | +/-func | +/-(expr) }

  procedure Term (var Result: ExprRes);
  var   CurOp: integer;
        i    : integer;
  begin
    Result.Def := FALSE;     { mandatory until proven wrong }
    Result.Forw := FALSE;    { ditto }
    Result.Base := TRUE;     { ditto per V1.120 }
    Result.IsUser := FALSE;  { V1.21 }
    Result.RefDef := FALSE;  { V1.23 }
    Result.RefName := '';    { V1.23a }
    Result.Val := 0;

    case CurTyp of
      Operand:
        begin
          CurExpDef := TRUE; { enable the 'Missing Value' error message }
          case CurVal of

            Minus:           { unary '-' }
              begin
                GetToken;
                Term (Result);
                if Result.Def then
                  Result.Val := -Result.Val;
              end;

            Plus:            { unary '+': ignored }
              begin
                GetToken;
                Term (Result);
              end;

            LBrace:          { expression between () }
              begin
                GetToken;
                NormExpr (Result);
                if (CurTyp = Operand) and (CurVal = RBrace) then
                  GetToken
                else StoError (0,'Missing ")"');
              end;

            Dollar:          { location counter referenced }
              begin
                GetToken;
                Result.Val := DollarPntr;
                Result.Def := TRUE;
{V1.23}         if EnaXrf and (CurSegment^.Rel <> AbsRel) then
                  begin
                    Result.RefDef  := TRUE;
                    Result.RefBase := CurSegment^.SegNum;
                    Result.RefName := CurSegment^.Name;
                    Result.RefVal  := DollarPntr;
                  end;
              end;

            Quote:           { quoted byte or word constant found }
              begin
                GetQuoted (4);
                if length (CurQuoted) > 0 then
                  begin
                    Result.Def := TRUE;
                    for i := length (CurQuoted) downto 1 do
                      Result.Val := Result.Val shl 8 + ord (CurQuoted[i]);
                  end;
              end;

            HiByte, LoByte:   { HIGH or LOW operator }
              begin
                CurOp := Curval;
                             { save wanted operator }
                GetToken;
                Term (Result);
                if Result.Def then
                  case CurOp of
                    HiByte: Result.Val := hi (Result.Val);
                    LoByte: Result.Val := lo (Result.Val);
                  end; { case CurOp }
              end;

            HiWord, LoWord:   { HIGH or LOW operator }
              begin
                CurOp := Curval;
                             { save wanted operator }
                GetToken;
                Term (Result);
                if Result.Def then
                  case CurOp of
                    HiWord: Result.Val := (Result.Val shr 16) and $ffff;
                    LoWord: Result.Val := Result.Val and $ffff;
                  end; { case CurOp }
              end;

            AbsOp:   { ABS operator }
              begin
                // CurOp := Curval; // Value assigned never used
                             { save wanted operator }
                GetToken;
                Term (Result);
                if Result.Def then
                  Result.Val := abs (Result.Val);
              end;

            DefOp:           { V1.12: check definition status of next
                               identifier }
              begin
                BlockAll := TRUE;
                             { prevent definition of new identifiers }
                GetToken;    { read next token, should be identifier }
                BlockAll := FALSE;
                             { re-enable definition of new identifiers }
                if     (CurTyp <> Ident)
                   and (CurTyp <> SetIdent)
                   and (CurTyp <> Segment)
                   and (CurTyp <> UserIdent) then
                             { token does not denote label name }
                  StoError (0,'No section or label')
                else
                  begin
                    Result.Def := TRUE;
                             { no error in handling token following DEF }
                    if CurDef and not CurForw then
                             { identifier already defined in this pass: }
                      Result.Val := -1;
                  end;
                GetToken;    { read token following identifier }
              end;

            BaseOp:          { V1.20: check base of next identifier }
              begin
                BlockAll := TRUE;
                             { prevent definition of new identifiers }
                GetToken;    { read next token, should be identifier }
                BlockAll := FALSE;
                             { re-enable definition of new identifiers }
                if (CurTyp <> Ident) and (CurTyp <> Segment) then
                    { token does not denote EQU or label name }
                  StoError (0,'No section or label')
                else
                  begin
                    Result.Def := TRUE;
                             { no error in handling token following $DEF }
                    if CurIdent^.SegNum = CurSegment^.SegNum then
                      Result.Val := -1;
                  end;
                GetToken;    { read token following identifier }
              end;

            Msum:   { $MSUM operator }
              begin
                Result.Def := true;
                Result.Val := ModuleSum;
                GetToken;
              end;
            else
              begin
                StoError (0,'Missing Value');
                             { unexpected operator (includes comma) }
                inc (ErrorPntr);
                             { disables 'Expression Needed' message }
              end;
          end; {case CurVal}
        end;

      Constant, Ident, SetIdent, UserIdent:
        begin
          CurExpDef := TRUE;
          Result.Def := CurDef;
          Result.Val := CurVal;
          Result.Forw := CurForw;
          Result.IsUser := (Assigned(CurIdent)) and (CurIdent^.Typ = UserIdent); //1.24j CurIdent may be NIL at this point.
          if CurTyp = UserIdent then
            CurExpUserPos := ErrorPntr;
          if CurTyp = Ident then
            Result.Base := (CurIdent^.SegNum = CurSegment^.SegNum);

{V1.23}   if EnaXrf and CurDef and
             (CurTyp = Ident) and
             (CurIdent^.Rel <> AbsRel) and
             (CurIdent^.SegNum <> -1) then
               begin
                 Result.RefDef := TRUE;
                 Result.RefBase := CurIdent^.SegNum;
                 Result.RefName := CurIdent^.Name;
                 Result.RefVal := CurVal;
               end;
          if not CurDef then
            StoError (0,'Undefined Symbol');
          GetToken;
        end;

      Segment:
        begin
          CurExpDef := TRUE;
          StoError (0,'Segments Not Allowed');
          GetToken;
        end;

      Opcode:
        begin
          CurExpDef := TRUE;
          StoError (0,'Opcodes Not Allowed');
          GetToken;
        end;

      EndLine:
        if CurExpDef then
          StoError (0,'Missing Value');
                             { part of an expression has been read, value
                               was expected, but end of line found }
        else                 { some other (ASMxx.INC) defined type }
          begin
            CurExpDef := TRUE;
            StoError (0, 'Value Expected');
            GetToken;
          end;
    end; { case CurTyp }

  end; { Term }

{ perform expr * | / expr }

  procedure Factor (var Result: ExprRes);
  var Operator  : integer;
      SubResult : ExprRes;
      GoOn      : boolean;
      FactError : integer;
  begin
    Term (Result);
    repeat
      GoOn := (CurTyp = Operand) and
              (
              (CurVal = Mult) or (CurVal = Divide) or
              (CurVal = ShftL) or (CurVal = ShftR) or
              (CurVal = Modulo)
              );
      if GoOn then
        begin
          OperandPtr := ErrorPntr;
          Operator := CurVal;
          GetToken;
          FactError := ErrorPntr;
          Term (SubResult);
          Result.Forw := Result.Forw or SubResult.Forw;
          Result.Base := Result.Base and SubResult.Base;
          Result.IsUser := SubResult.IsUser;
          if EnaXrf and SubResult.RefDef then
            begin
              Result.RefDef := TRUE;
              Result.RefVal := SubResult.RefVal;
              Result.RefBase := SubResult.RefBase;
              Result.RefName := SubResult.RefName;
            end;
          Result.Def := Result.Def and SubResult.Def;
          if Result.Def then
            begin
              if EnaXrf and Result.RefDef and (Result.RefBase = -2) then
                begin
                  ErrorPntr := OperandPtr;
                  StoError (1,'Invalid for Unbound Global');
                end;
              case Operator of
                Mult:
                  Result.Val := Result.Val * SubResult.Val;
                Divide, Modulo:
                  if SubResult.Val = 0 then
                    begin
                      Result.Def := FALSE;
                      ErrorPntr := FactError;
                      StoError (0,'Division By 0');
                    end
                  else
                    if Operator = Divide then
                      Result.Val := Result.Val div SubResult.Val
                    else Result.Val := Result.Val mod SubResult.Val;
                ShftL, ShftR:
                  if (SubResult.Val < 0) or (SubResult.Val > 31) then
                    begin
                      Result.Def := FALSE;
                      ErrorPntr := FactError;
                      StoError (0,'Shiftcount Out Of Range');
                    end
                  else
                    if Operator = ShftL then
                      Result.Val := Result.Val shl SubResult.Val
                    else
											Result.Val := Result.Val shr SubResult.Val;
              end; {case Operator}
            end;
        end;
    until not GoOn;
  end; {Factor}

{ perform expr + | - expr }

  procedure SumOfProd (var Result: ExprRes);
  var   SumOPOper:   integer;
        SumOPSubRes: ExprRes;
        SumOPGoOn:   boolean;
  begin
    Factor (Result);
    repeat
      SumOPGoOn := (CurTyp = Operand) and
                   ((CurVal = Minus) or (CurVal = Plus));
      if SumOPGoOn then
        begin
          SumOPOper := CurVal;
          GetToken;
          Factor (SumOPSubRes);
          Result.Forw := Result.Forw or SumOPSubRes.Forw;
          Result.Base := Result.Base and SumOPSubRes.Base;
          Result.IsUser := SumOPSubRes.IsUser;
          Result.Def := Result.Def and SumOPSubRes.Def;
          if EnaXrf and SumOPSubRes.RefDef then
            begin
              if Result.RefDef then
                StoError (1,'Invalid for Unbound Global');
              Result.RefDef := TRUE;
              Result.RefVal := SumOPSubRes.RefVal;
              Result.RefBase := SumOPSubRes.RefBase;
              Result.RefName := SumOpSubRes.RefName;
            end;
          if Result.Def then
            case SumOPOper of
              Plus  : Result.Val := Result.Val + SumOPSubRes.Val;
              Minus : Result.Val := Result.Val - SumOPSubRes.Val;
            end;
        end;
    until not SumOPGoOn;
  end; {SumOfProd}

{ perform expr REL expr }

  procedure ComPares (var Result: ExprRes);
  var   CompAccu:   longint;
        CompOper:   integer;
        CompSubRes: ExprRes;
  begin
    if (CurTyp = Operand) and (CurVal = NotOp) then
      begin
        GetToken;            { remove NOT }
        ComPares (Result);
        if Result.Def then
          Result.Val := not Result.Val;
      end
    else
      begin
        SumOfProd (Result);
        if (CurTyp = Operand) and
           ((CurVal = Equal   ) or (CurVal = NotEqual ) or
            (CurVal = LessThan) or (CurVal = LessEqual) or
            (CurVal = MoreThan) or (CurVal = MoreEqual)) then
          begin
            OperandPtr := ErrorPntr;
            CompOper := CurVal;
            GetToken;
            SumOfProd (CompSubRes);
            if EnaXrf and CompSubRes.RefDef then
              begin
                Result.RefDef := TRUE;
                Result.RefVal := CompSubRes.RefVal;
                Result.RefBase := CompSubRes.RefBase;
                Result.RefName := CompSubRes.RefName;
              end;
            Result.Forw := Result.Forw or CompSubRes.Forw;
            Result.Base := Result.Base and CompSubRes.Base;
            Result.IsUser := CompSubRes.IsUser;
            Result.Def := Result.Def and CompSubRes.Def;
            if Result.Def then
              begin
                if EnaXrf and Result.RefDef and (Result.RefBase = -2) then
                  begin
                    ErrorPntr := OperandPtr;
                    StoError (1,'Invalid for Unbound Global');
                  end;
                CompAccu := Result.Val;
                Result.Val := 0;
                case CompOper of
                  Equal    : if CompAccu = CompSubRes.Val then
                               Result.Val := -1;
                  NotEqual : if CompAccu <> CompSubRes.Val then
                               Result.Val := -1;
                  LessThan : if CompAccu < CompSubRes.Val then
                               Result.Val := -1;
                  LessEqual: if CompAccu <= CompSubRes.Val then
                               Result.Val := -1;
                  MoreThan : if CompAccu > CompSubRes.Val then
                               Result.Val := -1;
                  MoreEqual: if CompAccu >= CompSubRes.Val then
                               Result.Val := -1;
                end; {case CompOper}
              end;
          end;
      end;
  end; {ComPares}

{ perform expr AND expr }

  procedure AndTerm (var Result: ExprRes);
  var   AndTSubRes: ExprRes;
        AndTGoOn:   boolean;
  begin
    ComPares (Result);
    repeat
      AndTGoOn := (CurTyp = Operand) and (CurVal = AndOp);
      if AndTGoOn then
        begin
          OperandPtr := ErrorPntr;
          GetToken;
          ComPares (AndTSubRes);
          if EnaXrf and AndTSubRes.RefDef then
            begin
              Result.RefDef := TRUE;
              Result.RefVal := AndTSubRes.RefVal;
              Result.RefBase := AndTSubRes.RefBase;
              Result.RefName := AndTSubRes.RefName;
            end;
          Result.Forw := Result.Forw or AndTSubRes.Forw;
          Result.Base := Result.Base and AndTSubRes.Base;
          Result.IsUser := AndTSubRes.IsUser;
          Result.Def := Result.Def and AndTSubRes.Def;
          if Result.Def then
            begin
              if EnaXrf and (Result.RefBase = -2) then
                begin
                  ErrorPntr := OperandPtr;
                  StoError (1,'Invalid for Unbound Global');
                end;
              Result.Val := Result.Val and AndTSubRes.Val;
            end;
        end;
    until not AndTGoOn;
  end; {AndTerm}

{ perform  expr OR | XOR expr }

begin { NormExpr }
  AndTerm (Result);
  repeat
    ExprGoOn := (CurTyp = Operand) and
                ((CurVal = OrOp) or (CurVal = XorOp));
    if ExprGoOn then
      begin
        OperandPtr := ErrorPntr;
        ExprOper := CurVal;
        GetToken;
        AndTerm (ExprSubRes);

        if EnaXrf and ExprSubRes.RefDef then   { V1.23 }
          begin
            Result.RefDef := TRUE;
            Result.RefVal := ExprSubRes.RefVal;
            Result.RefBase := ExprSubRes.RefBase;
            Result.RefName := ExprSubRes.RefName;
          end;

        Result.Forw := Result.Forw or ExprSubRes.Forw;
        Result.Base := Result.Base and ExprSubRes.Base;
        Result.IsUser := ExprSubRes.IsUser;
        Result.Def := Result.Def and ExprSubRes.Def;
        if Result.Def then
          begin
            if EnaXrf and (Result.RefBase = -2) then
              begin
                ErrorPntr := OperandPtr;
                StoError (1,'Invalid for Unbound Global');
              end;
            case ExprOper of
              OrOp  : Result.Val := Result.Val or ExprSubRes.Val;
              XorOp : Result.Val := Result.Val xor ExprSubRes.Val;
            end; { case ExprOper }
          end;
      end;
  until not ExprGoOn;
end; {NormExpr}

{ the following procedure is the routine called by the other
  procedures in VACS to evaluate an expression.
  Lower and Upper are the lower and upper bounds of the
  expression result. if they are equal, then no range checking
  is done. Lower can be below 80000000H, while Upper is above or equal
  to 80000000H (in that case: Lower > Upper !).
  the expression result is stored in the global variable CurExpVal,
  CurExpDef gives the validity status of this value.
  CurExpForw gives the forward definition status of this value.
  CurExpBase indicates this value is evaluated inside current section.(V1.20)
  CurExpUser indicates expression contains user-defined identifier(s).

  Before starting expression evaluation, CurExpDef is set FALSE.
  As soon as a part of the expression is read, this is turned into
  TRUE. If now the lowest level of the expression evaluator is
  called (Term), with no valid identifier or constant in the text,
  then the 'Missing Value' error will be given.
}

procedure Expression (Lower, Upper: longint);
var HulpExpr : ExprRes;
    StrtExpr,
    EndExpr  : integer;
begin
  StrtExpr := ErrorPntr;
  CurExpDef := FALSE;        { completely empty expression: do NOT give
                               'Missing Value' error message }
  NormExpr (HulpExpr);
  CurExpVal := HulpExpr.Val;
  CurExpDef := HulpExpr.Def;
  CurExpForw := HulpExpr.Forw;
  CurExpBase := HulpExpr.Base; { V1.20 }
  CurExpUser := HulpExpr.IsUser; { V1.21 }
  CurExpRefDef := HulpExpr.RefDef; { V1.23 }
  CurExpRefVal := HulpExpr.RefVal;
  CurExpRefBase := HulpExpr.RefBase;
  CurExpRefName := HulpExpr.RefName;

  if CurExpDef and
     (
     ((Lower < Upper) and ((CurExpVal < Lower) or (CurExpVal > Upper))) or
     ((Lower > Upper) and not ((CurExpVal >= Lower) or (CurExpVal <= Upper)))
     ) then
    begin
      CurExpDef := FALSE;
      EndExpr := ErrorPntr;
      ErrorPntr := StrtExpr;
      StoError (0,'Value Out Of Range');
      ErrorPntr := EndExpr;
    end;
end;

{ the following routine is the same as above, but prints
  an error message if no valid expression is given
  (then also forces the result to 0)
}

procedure MustBeExpr (l, h: longint);
var ExprError: integer;
begin
  ExprError := ErrorPntr;
  Expression (l, h);
  if not CurExpDef then
    begin
      if ExprError = ErrorPntr then       { not even a single token read }
        StoError (0,'Expression Needed');
      CurExpVal := 0;
    end;
end; { MustBeExpr }

function IsString: boolean;
var i : integer;
		w : longint;

begin
	IsString := false;

	if CurTyp = StrIdent then
  	begin
    	StringPntr := StringBase;
    	while StringPntr^.Val <> CurVal do
      	StringPntr := StringPntr^.Next;
    	CurQuoted := StringPntr^.Name;
    	GetToken;
			IsString := true;
  	end
	else
		if CurTyp = Operand then
			begin
				if CurVal =	Quote then
					begin
						GetQuoted (255);
						IsString := true;
					end
				else
					if (Curval = Mult) or (CurVal = Colon) or (CurVal = Equal) then
    				begin
							i := CurVal; { save conversion operator }
      				GetToken;
      				MustBeExpr (0, 0);
      				w := CurExpVal;
      				CurQuoted := '????'; { assume No CurExpDef }
      				if CurExpDef then
								begin
                	case i of
                  	Mult:  Str (w, CurQuoted);
                  	Colon: CurQuoted := HexFourStr (w);
                  	Equal: CurQuoted := HexEightStr (w);
										end;
									IsString := true;
								end
    				end
 			end
end;

begin
end.
