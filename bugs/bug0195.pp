uses graph
{$ifdef go32v2}
,dpmiexcp
{$endif go32v2};
var
   GDriver, GMode: Integer;
   w:word;
   p:pointer;
begin
   GDriver := $FF;
   GMode := $101;
   InitGraph(GDriver, GMode, '');
   if (GraphResult <> grOK) then
     Halt(0);
   rectangle(0,0,getmaxx,getmaxy);
   w := imagesize(0,0,111,111);
   getmem(p, w);

   {---runtime-error!------}
   { getimage(0,0,111,111, p); }
   {-----------------------}
   
   { This is the correct usage (PFV) }
   getimage(0,0,111,111, p^);
   

   freemem(p, w);
   closegraph;
   readln;
end.
