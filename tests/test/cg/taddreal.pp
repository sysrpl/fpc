{****************************************************************}
{  CODE GENERATOR TEST PROGRAM                                   }
{****************************************************************}
{ NODE TESTED : secondadd() FPU real type code                   }
{****************************************************************}
{ PRE-REQUISITES: secondload()                                   }
{                 secondassign()                                 }
{                 secondtypeconv()                               }
{****************************************************************}
{ DEFINES:                                                       }
{            FPC     = Target is FreePascal compiler             }
{****************************************************************}
{ REMARKS:                                                       }
{                                                                }
{                                                                }
{                                                                }
{****************************************************************}

{ Result is either LOC_FPU or LOC_REFERENCE                     }
{ LEFT NODE (operand) (left operator)                           }
{  LOC_REFERENCE / LOC_MEM                                      }
{  LOC_FPU                                                      }
{ RIGHT NODE (operand)                                          }
{  LOC_FPU                                                      }
{  LOC_REFERENCE / LOC_MEM                                      }
{$E+}
procedure fail;
begin
  WriteLn('Failed!');
  halt(1);
end;


 Procedure RealTestSub;
 var
  i : Real;
  j : Real;
  result : boolean;
 Begin
  Write('Real - Real test...');
  result := true;
  i:=99.9;
  j:=10.0;
  i:=i-j;
  if trunc(i) <> trunc(89.9) then
    result := false;
  WriteLn('Result (89.9) :',i);
  i:=j-i;
  if trunc(i) <> trunc(-79.9) then
    result := false;
  WriteLn('Result (-79.9) :',i);
  j:=j-10.0;
  if j <> 0.0 then
    result := false;
  WriteLn('Result (0.0) :',j);
  if not result then
    Fail
  else
    WriteLn('Success.');
 end;

 procedure RealTestAdd;
 var
  i : real;
  j : real;
  result : boolean;
 Begin
   WriteLn('Real + Real test...');
   result := true;
   i:= 9;
   i:=i+1.5;
   if trunc(i) <> trunc(10.5) then
     result := false;
   WriteLn('Result (10.5) :',i);
   i := 0.0;
   j := 100.0;
   i := i + j + j + 12.5;
   if trunc(i) <> trunc(212.5) then
     result := false;
   WriteLn('Result (212.5) :',i);
   if not result then
    Fail
   else
    WriteLn('Success.');
 end;


 procedure realtestmul;
 var
  i : real;
  j : real;
  result : boolean;
 begin
  WriteLn('Real * Real test...');
  result := true;
  i:= 0;
  j:= 0;
  i := i * j * i;
  if trunc(i) <> trunc(0.0) then
    result := false;
  WriteLn('Result (0.0) :',i);
  i := 10.0;
  j := -12.0;
  i := i * j * 10.0;
  if trunc(i) <> trunc(-1200.0) then
    result := false;
  WriteLn('Result (-1200.0) :',i);
  if not result then
    Fail
  else
    WriteLn('Success.');
 end;



 Procedure RealTestDiv;
 var
  i : Real;
  j : Real;
  result : boolean;
 Begin
  result := true;
  WriteLn('Real / Real test...');
  i:=-99.9;
  j:=10.0;
  i:=i / j;
  if trunc(i) <> trunc(-9.9) then
    result := false;
  WriteLn('Result (-9.9) :',i);
  i:=j / i;
  if trunc(i) <> trunc(-1.01) then
    result := false;
  WriteLN('Result (-1.01) :',i);
  j:=i / 10.0;
  if trunc(j) <> trunc(-0.1001) then
    result := false;
  WriteLn('Result (-0.1001) :',j);
  if not result then
    Fail
  else
    WriteLn('Success.');
 end;



{ Procedure RealTestComplex;
 var
  i : real;
 Begin
   Write('RESULT SHOULD BE 2.09 :');
   i := 4.4;
   WriteLn(Sqrt(i));
   Write('RESULT SHOULD BE PI :');
   WriteLn(Pi);
   Write('RESULT SHOULD BE 4.0 :');
   WriteLn(Round(3.6));
 end;}


 procedure realtestequal;
 var
  i : real;
  j : real;
  result : boolean;
 begin
  result := true;
  Write('Real = Real test...');
  i := 1000.0;
  j := 1000.0;
  if not (trunc(i) = trunc(j)) then
    result := false;
  if not (trunc(i) = trunc(1000.0)) then
    result := false;
  if not result then
    Fail
  else
    WriteLn('Success.');
 end;

 procedure realtestnotequal;
 var
  i : real;
  j : real;
  result : boolean;
 begin
  result := true;
  Write('Real <> Real test...');
  i := 1000.0;
  j := 1000.0;
  if (trunc(i) <> trunc(j)) then
    result := false;
  if (trunc(i) <> trunc(1000.0)) then
    result := false;
  if not result then
    Fail
  else
    WriteLn('Success.');
 end;


 procedure realtestle;
 var
  i : real;
  j : real;
  result : boolean;
 begin
  result := true;
  Write('Real <= Real test...');
  i := 1000.0;
  j := 1000.0;
  if not (trunc(i) <= trunc(j)) then
    result := false;
  if not (trunc(i) <= trunc(1000.0)) then
    result := false;
  i := 10000.0;
  j := 999.0;
  if trunc(i) < trunc(j) then
    result := false;
  if trunc(i) < trunc(999.0) then
    result := false;
  if not result then
    Fail
  else
    WriteLn('Success.');
 end;

 procedure realtestge;
 var
  i : real;
  j : real;
  result : boolean;
 begin
  result := true;
  Write('Real >= Real test...');
  i := 1000.0;
  j := 1000.0;
  if not (trunc(i) >= trunc(j)) then
    result := false;
  if not (trunc(i) >= trunc(1000.0)) then
    result := false;
  i := 999.0;
  j := 1000.0;
  if trunc(i) > trunc(j) then
    result := false;
  if trunc(i) > trunc(999.0) then
    result := false;
  if not result then
    Fail
  else
    WriteLn('Success.');
 end;


Begin
 RealTestEqual;
 RealTestNotEqual;
 RealTestLE;
 RealTestGE;
 RealTestSub;
 RealTestAdd;
 RealTestDiv;
 RealTestMul;
{ RealTestComplex;}
end.


{
  $Log$
  Revision 1.5  2002-04-13 21:02:38  carl
  * fixed typos

  Revision 1.4  2002/03/05 21:55:11  carl
  * Adapted for automated testing

  Revision 1.3  2001/07/31 01:55:23  carl
  * corrected comparing value for real

  Revision 1.2  2001/06/12 01:12:34  carl
  + added header

  Revision 1.1  2001/05/19 11:51:50  peter
    * renamed to .pp

  Revision 1.2  2001/05/16 15:28:40  carl
  * corrected problem with log


}
