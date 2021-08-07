function [c, ceq] = variant_t_cons(st, rr, ii, tvals)
ceq = (log(ii) - log(1+exp(st(1:end-3)))).*st(end-2) + st(1:end-3) + (tvals).*st(end-1) + st(end);
c = 0;
eps = 0.1;
d1 = (st(1:end-4)-st(2:end-3))./(tvals(1:end-1)-tvals(2:end));
d2 = (d1(1:end-1) - d1(2:end))./(tvals(2:end-1)-tvals(3:end));
c = ([d2].^2 - eps.^2);
end