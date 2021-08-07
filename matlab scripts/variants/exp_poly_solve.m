function [x, ferr] = exp_poly_solve(A, B, N)
% Approximate solution for L(x) = \sum_i A(i)x^B(i) = 1

% First we write the expression as taylor expansion around 1, i.e., x = 1+h
% L2(h) = (\sum_i A(i)) - 1 + \sum_n>0 f_n h^n /n!
% where f_n = \sum_i a_i*(b_i(b_i - 1). ... . (b_i - n + 1))
% And f(x) = \sum_n>0 f_n x^n /n!

temp = A.*cumprod(B  - [0:N-1], 2);
f = sum(temp, 1);

% Now we will invert the series f(x)
Be = bell_poly(N-1, N-1, f(2:end)./(f(1)*(2:N)));

g = f(1).^-(2:N)' .* sum( ((-1).^(1:N-1)) .* exp(gammaln((2:N)' + (1:N-1)) - gammaln((2:N)')) ...
    .* Be(2:end, 2:end), 2);
g = [1./f(1); g];

arg = 1 - sum(A);
x = 1 + sum(g'.*(arg.^(1:N))./gamma([2:N+1]));
ferr = sum(A.*(x.^B)) - 1;
end

