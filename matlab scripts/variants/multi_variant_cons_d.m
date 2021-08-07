function [c, ceq, gc, gceq] = multi_variant_cons_d(X1, var_data, val_times, ii, base_var)

nv = size(var_data, 1);
T = size(var_data, 2);
base_time = 1;

Y0 = (X1(1:nv))+ 1e-30;
R0 = X1(nv+1:(2*nv-1)); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
R1 = (X1(2*nv:3*nv-2)); R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];
base_lin_prev = X1(end-T+1:end);

c = zeros(T, 1); ceq = zeros(T, 1);
gc = zeros(length(X1), T); gceq = zeros(length(X1), T);

xv_raw = (base_lin_prev) + 1e-100;

lnYhat = log(Y0) + (R0.*(val_times - val_times(base_time)) ...
        + log(xv_raw'/Y0(base_var)) - (R1-1).*log(ii'/ii(base_time)))./R1;

Yhat = exp(lnYhat);
    
ceq = sum(Yhat, 1)' - 1;


if nargout > 1
    imap = [1:(base_var-1), (base_var+1):nv]';
    for kk = 1:nv
        gceq(kk, :) = (Yhat(kk, :)/Y0(kk));
    end
    gceq(base_var, :) = gceq(base_var, :) - (1/Y0(base_var))*sum(Yhat./R1, 1);
    
    for kk = nv+1 : 2*nv-1
        jj = imap(kk-nv);
        gceq(kk, :) = (Yhat(jj, :).*(val_times - val_times(base_time))/R1(jj));
    end
    
    for kk = 2*nv : 3*nv-2
        jj = imap(kk - 2*nv + 1);
        gceq(kk, :) = -(1./R1(jj)^2)*(Yhat(jj, :).*(R0(jj)*(val_times - val_times(base_time))...
             + log(xv_raw'./Y0(base_var)) + log(ii'./ii(base_time))));
    end
    
    for kk = 3*nv-1: length(X1)
        tt = kk - 3*nv + 2;
        gceq(kk, tt) = sum(Yhat(:, tt)./(R1.*xv_raw(tt)));
    end
end

if any(isnan(ceq) | isinf(ceq))
    fprintf('ERROR');
end

end
