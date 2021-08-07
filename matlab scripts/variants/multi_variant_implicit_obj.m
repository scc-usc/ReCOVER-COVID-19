function [nLL, Yhat, err_mat, Y0, R0, R1] = multi_variant_implicit_obj(X, var_data, val_times, ii, ret_vec, base_var, init_base)
% returns the negative log likelihood of observing the data with the
% seleciton probabilities implicitly defined by the constraints


bounds_given = 1;



nv = 1 + floor(length(X)/3);

X1 = X;
if bounds_given > 0
    X1(X1<0) = 1e-10;
    Y0 = X1(1:nv); Y0(base_var) = init_base(end); Y0 = ii(end)*Y0/sum(Y0); 
    R0 = X1(nv+1:(2*nv-1)); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
    R1 = X1(2*nv:3*nv-2); R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];
else
    var_data = reshape(var_data, nv, []);
    X1(X1<0) = 1e-10;
    Y0 = logsig(X1(1:nv-1)); Y0 = [Y0; max(0,1-sum(Y0))]; Y0 = ii(end)*Y0/sum(Y0); 
    R0 = (X1(nv:(2*nv-2))); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
    R1 = (X1(2*nv-1:3*nv-3)).^2; R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];
end
Yhat = zeros(size(var_data));
err_mat = zeros(size(var_data));


for t = 1:length(val_times)
    %[~, base_var] = max(R0);
    A = Y0./(Y0(base_var).^(R1(base_var)./R1)) .* exp((R0-R0(base_var))*(val_times(t) - val_times(end))./R1);
    B = (R1(base_var)./R1);
    %xv = secant_solve(A, B, ii(t), init_base(t));
    %xv_raw = ii(t)*logsig(xv) + 1e-10;
    
    xv_raw = ii(t)*init_base(t);
    
    for vi = 1:nv
        x0 = A(vi)* xv_raw^B(vi);
        %err_mat(vi, t) = func_const(x0, A(vi), B(vi), ii(t));
        Yhat(vi, t) = x0/ii(t);
    end
end

Yhat = Yhat./sum(Yhat, 1);
%Yhat(Yhat <= 0) = 1e-20; Yhat(Yhat >= 1) = 1- 1e-20;

if ret_vec == 0
    nLL = - sum(sum(var_data.*log(Yhat + 1e-10)));
elseif ret_vec == 1
    nLL = sqrt(-sum(var_data.*(log(Yhat + 1e-10))));
    %nLL = (var_data - sum(var_data, 1).*Yhat);
else
    nLL = sqrt(-(var_data.*log(Yhat + 1e-50)));
end

nLL = nLL(:);

if any(~isreal(nLL))
    fprintf('ERROR');
end

end

function res = func_const(x, A, B, ii)
res = ii - sum(A .* (ii*logsig(x)).^B);
end

function xprob = secant_solve(A, B, ii, init_val)
x1 = ii*init_val/2; x2 = ii*init_val*2;
tolX = 1e-5;
err = Inf; maxIter = 100; iter =1; ferr = Inf;
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
x = max([1e-20 x]); x = min([x ii]);
ferr = abs(sum(A .* (x).^B) - ii);

xprob = log(x + 1e-10) - log(ii - x + 1e-10);
end


