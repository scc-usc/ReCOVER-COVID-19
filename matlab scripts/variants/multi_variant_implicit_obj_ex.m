function [Yhat, Y0, R0, R1] = multi_variant_implicit_obj_ex(X, val_times, ii, base_var, nv, base_time)
% returns the negative log likelihood of observing the data with the
% seleciton probabilities implicitly defined by the constraints


X1 = X;
Y0 = X1(1:nv) + 1e-30;
R0 = X1(nv+1:(2*nv-1)); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
R1 = X1(2*nv:3*nv-2); R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];

%Yhat = zeros(nv, length(val_times));
xv_raw = zeros(length(val_times), 1);

for t = 1:length(val_times)
    
%     A = Y0./(Y0(base_var).^(R1(base_var)./R1)) .* exp((R0-R0(base_var))*(val_times(t) - base_time)./R1);
%     B = (R1(base_var)./R1);
%     %xv = secant_solve(A, B, ii(t));
%     xv = fzero(@(x)(func_const(x, A, B, ii(t))), 0);
%     xv_raw = ii(t)*logsig(xv);
    
    A = log(Y0) + (R0.*(val_times(t) - val_times(base_time)) ...
         - log(Y0(base_var)) - (R1-1).*log(ii(t)'/ii(base_time)))./R1;
    B = 1./R1;
    try
        xv = fzero(@(x)(func_const1(x, A, B)), [-500 0]);
    catch
        xv = -500;
        fprintf('fzero error at %d', t);
    end
    xv_raw(t) = exp(xv);
end
Yhat = exp(log(Y0) + (R0.*(val_times - val_times(base_time)) ...
        + log(xv_raw'/Y0(base_var)) - (R1-1).*log(ii'/ii(base_time)))./R1);
%Yhat = Yhat./sum(Yhat, 1);

end

function res = func_const(x, A, B, ii)
res = ii - sum(A .* (ii*logsig(x)).^B);
end

function res = func_const1(x, A, B)
    res = 1 - sum(exp(A + B*x));
end
function xprob = secant_solve(A, B, ii)
x1 = 1e-50; x2 = ii;
tolX = 1e-5; x = x1;
err = Inf; maxIter = 500; iter =1; ferr = Inf;
while abs(x2-x1) > tolX && iter < maxIter
    %    disp([x1 x2]);
    fx1 = sum(A .* (x1).^B) - ii;
    fx2 = sum(A .* (x2).^B) - ii;
    
    if abs(fx1) <= 0.01
        x = x1; break;
    elseif abs(fx2) <= 0.01
        x = x2; break;
    end
    
    x = (x1*fx2 - x2*fx1)/(fx2 - fx1);
    %     if x < 0.1
    %         x = (x1+x2)/2;
    %     end
    
    fx = sum(A .* (x).^B) - ii;
    if fx < 0
        x1 = x;
    else
        x2 = x;
    end
    err = abs(x-x2);
    ferr = abs(fx);
    iter = iter + 1;
end
x = max([1e-50 x]); x = min([x ii-(1e-50)]);
ferr = abs(sum(A .* (x).^B) - ii);

xprob = log(x) - log(ii - x);
end


