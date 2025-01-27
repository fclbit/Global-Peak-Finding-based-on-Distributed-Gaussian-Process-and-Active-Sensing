function z = f(x, y)
% The true environment model, which is assuemd to be unknown.
% x = x-1;
% y = y-1;
z = 3*(1-x).^2.*exp(-(x.^2) - (y+1).^2) ... 
   - 10*(x/5 - x.^3 - y.^5).*exp(-x.^2/2-y.^2) ... 
   - 3*exp(-(x+1).^2 - y.^2);
end