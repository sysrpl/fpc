program bug0233;

var s:string;
    w:cardinal;
    code:word;

begin
    s:='192';
    val(s,w,code);
    if code<>0 then
        begin
           writeln('Error');
           halt(1);
        end
    else
        writeln(w);
end.
