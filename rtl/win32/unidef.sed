# function names with parameters
s/function \([^(]*\)W *(/function \1(/
# procedure names with parameters
s/procedure \([^(]*\)W *(/procedure \1(/
# function names without parameters
s/function \([^:(]*\)W *: */function \1 : /
# procedure names without parameters
s/procedure \([^;(]*\)W *;/procedure \1;/
# function return value
s/\([^ \t]*\)W *:=/\1:=/
# function call with parameters
s/\:=\(.*\)W(/:=\1(/
# function call without parameters
s/\:=\(.*\)W *;/:=\1;/
# unit name
s/ascfun;/ascdef;/
# cvs name
s/ascfun.pp,v/ascdef.pp,v/
# unit conditionnal
s/UNICODEFUNCTIONS/UNICODEFUNCTIONSDEFAULT/

