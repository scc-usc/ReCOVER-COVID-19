P = 5;
alpha = sym('a', [1 P]);
Y0 = sym('y', [1 P]);
%%
t = 10;

newY = Y0;
Y = sym('Y',  [t P]);
for i=1:t
    xx = coeffs(poly2sym(newY)*poly2sym(alpha), 'x');
    for j=1:P
        [a] = coeffs(collect((xx(P)), Y0), Y0(j));
        Y(i, j) = a(2);
    end
    newY = [newY(2:end) xx(P)];
end
    