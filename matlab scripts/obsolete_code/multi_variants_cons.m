function [ceq, gradc, gradceq] = multi_variants_cons(Y, valid_time_list, ii)
tmax = length(ii);
Y = reshape(Y, [length(Y)/(tmax+2), tmax+2]);
ridx = [(2:size(Y, 1))'; 1];
X = Y(ridx, :);

t0 = valid_time_list(1);

R0_y = Y(:, end-1);
R1_y = Y(:, end);
R0_x = X(:, end-1);
R1_x = X(:, end);
leps = 1e-20;

ceq1 = R1_y.*log(Y(:, 1:end-2)+leps) - R1_y.*log(Y(:, t0)+leps) ...
    - R1_x.*log(X(:, 1:end-2)+leps) + R1_x.*log(X(:, t0)+leps)...
    + (R0_x - R0_y)*((1:tmax)-t0);

ceq2 = sum(Y(:, 1:tmax), 1) - ii;
ceq = [ceq1(:); ceq2(:)];

gradceq = zeros(length(ceq), length(Y(:)));
V = size(Y, 1);
for jj=1:(length(ceq1))
    i = 1 + mod(jj-1, V);
    t = 1 + (jj-i)/V;
    ci = 1+mod(i, V);
    gradceq(jj, jj) = R1_y(i)/Y(i, t); % due to y_i,t
    gradceq(jj, jj+1) = -R1_y(ci)/Y(ci, t); % due to y_i,t
    gradceq(jj, V*(tmax) + i) = -t; % due to R0
    gradceq(jj, V*(tmax) + ci) = t; % due to R0
    
    gradceq(jj, V*(tmax+1) + i) = log(Y(i, t)+ leps) - log(Y(i, t0)+ leps); % due to R1
    gradceq(jj, V*(tmax+1) + ci) = -log(Y(ci, t)+ leps) + log(Y(ci, t0)+ leps); % due to R1
    gradceq(jj, V*(tmax+1) + ci) = t; % due to R1
end

for jj=(length(ceq1)+1):(length(ceq1)+tmax)
    t = jj - length(ceq1);
    gradceq(jj, V*(t-1)+(1:V)) = 1;
end
gradceq = gradceq';

eps = 0.0001;
d1 = (Y(:, 1:tmax-1)-Y(:, 2:tmax));
d2 = d1(:, 1:end-1) - d1(:, 2:end);
c = d2.^2 - (eps.*(1+Y(:,2:tmax-1))).^2;
c = c(:); 
gradc = zeros(length(c), length(Y(:)));

for jj=1:length(c)
    i = 1 + mod(jj-1, V);
    t = 1 + (jj-i)/V + 2;
    
    gradc(jj, V*(t-1) + (1:V)) = 2*d2(t-2) - eps;
    gradc(jj, V*(t-2) + (1:V)) = -4*d2(t-2);
    gradc(jj, V*(t-3) + (1:V)) = 2*d2(t-2);
end
gradc = gradc';
end