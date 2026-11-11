local U={}
function U.f(c) return c*9/5+32 end
function U.c(f) return (f-32)*5/9 end
function U.temperature(c) return string.format('%.0f °F',U.f(c)) end
return U
