function [nLL, G, Yhat, Y0, R0, R1, total_iters] = multi_variant_imp_obj_d(X1, var_data, val_times, ii, base_var, base_time)
% returns the negative log likelihood of observing the data with the
% seleciton probabilities implicitly defined by the constraints

G = 0;
nv = floor((length(X1)+3)/3);

if nargin < 6
    T = size(var_data, 2);
    base_time = T;
end

l = 0.2;
Y0 = (X1(1:nv-1)); Y0 = [Y0(1:(base_var-1)); 0; Y0(base_var:end)];
Y0 = exp(Y0); Y0 = Y0./sum(Y0);
R0 = X1(nv:(2*nv-2)); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
R1 = l + exp(X1(2*nv-1:3*nv-3)); R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];
total_iters = 0;
xv_raw = zeros(length(val_times), 1);
func_const1 = @(x, A, B)(1 - sum(exp(A + B*x)));

for t = 1:length(val_times)    
    A = log(Y0) + (R0.*(val_times(t) - val_times(base_time)) ...
         - log(Y0(base_var)) - (R1-1).*log(ii(t)'/ii(base_time)))./R1;
    B = 1./R1;
    try
         xv = fzero(@(x)(func_const1(x, A, B)), [0 -1000]);
%           [xv, iters] = secant_solve(A, B);
%           total_iters = total_iters + iters;
    catch
        xv = -1000;
        fprintf('fzero error at %d', t);
    end
    xv_raw(t) = exp(xv);
end

lnYhat = log(Y0) + (R0.*(val_times - val_times(base_time)) ...
        + log(xv_raw'/Y0(base_var)) - (R1-1).*log(ii'/ii(base_time)))./R1;

Yhat = exp(lnYhat);

if isempty(var_data)
    nLL = 0;
    return;
end

nLL = - sum(sum(var_data.*lnYhat));

if any(~isreal(nLL) | isinf(nLL) | isnan(nLL))
    fprintf('ERROR');
end

if nargout > 1
    G = zeros(length(X1), 1);
    imap = [1:(base_var-1), (base_var+1):nv]';
    var_data1 = var_data; var_data1(base_var, :) = 0;
    St = sum(Yhat./R1, 1);
    Dik = eye(nv, nv);
    for kk = 1:nv-1
        jj = imap(kk);
        impt = (Y0(jj) - Yhat(jj, :))./St - Y0(jj);
        G(kk) = sum(sum(var_data1.* ( Dik(:, jj) - Y0(jj).*(1 - 1./R1) + impt./R1 )));
        G(kk) = G(kk) + sum(var_data(base_var, :).*impt);
    end
    
    for kk = nv : 2*nv-2
        jj = imap(kk-nv+1);
        tdel = val_times - val_times(base_time);
        impt = -tdel.*Yhat(jj, :)./(St*R1(jj));
        G(kk) = sum(sum(var_data1.* (Dik(:, jj).*tdel./R1 + impt./R1)));
        G(kk) = G(kk) + sum(var_data(base_var, :).*impt);
    end
    
    for kk = 2*nv-1 : 3*nv-3
        jj = imap(kk-2*nv+2);
        tdel = val_times - val_times(base_time);
        impt = (Yhat(jj, :)./St)*((R1(jj) - l)./(R1(jj)^2)) ...
            .*(R0(jj)*tdel + log(Yhat(base_var, :)./Y0(base_var)) + log(ii'./ii(base_var)));
        iterm = - Dik(:, jj).*((R1 - l)./(R1.^2)) ...
            .*(R0.*tdel + log(Yhat(base_var, :)./Y0(base_var)) + log(ii'./ii(base_var)));
        G(kk) = sum(sum(var_data1.* (iterm + impt./R1)));
        G(kk) = G(kk) + sum(var_data(base_var, :).*impt);
    end
    G = -G;
end

end

function [x, iter] = secant_solve(A, B)
% to solve: 1 - sum(exp(A + B*x)) = 0;
xmin = -500; xmax = 0;
x1 = xmin; x2 = xmax; x = xmin;
tolX = 1e-6;
x = x1;
maxIter = 500; iter =1; ferr = Inf;
fx1 = sum(exp(A + B*x1)) - 1;
fx2 = sum(exp(A + B*x2)) - 1;
while abs(x2-x1) > tolX && iter < maxIter
    %    disp([x1 x2]);
    
    if fx1*fx2 > 0
        fprintf('Error');
    end
    fx1_old = fx1; fx2_old = fx2;
    
    %x = (x1*fx2 - x2*fx1)/(fx2 - fx1);

    x = (x1+x2)/2;
    
    
    fx = sum(exp(A + B*x)) - 1;
    
    if fx < 0
        x1 = x; fx1 = fx; fx2 = fx2_old;
    else
        x2 = x; fx1 = fx1_old; fx2 = fx;
    end
    err = abs(x-x2);
    ferr = abs(fx);
    iter = iter + 1;
end
x = max([xmin x]); x = min([x xmax]);
ferr = abs(sum(exp(A + B*x)) - 1);
end

