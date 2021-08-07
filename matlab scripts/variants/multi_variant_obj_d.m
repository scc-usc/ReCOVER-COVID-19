function [nLL, G, Yhat, Y0, R0, R1] = multi_variant_obj_d(X1, var_data, val_times, ii, ret_vec, base_var)
% returns the negative log likelihood of observing the data with the
% seleciton probabilities implicitly defined by the constraints

nv = size(var_data, 1);
T = size(var_data, 2);
base_time = 1;

Y0 = (X1(1:nv))+ 1e-30;
R0 = X1(nv+1:(2*nv-1)); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
R1 = (X1(2*nv:3*nv-2)); R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];
base_lin_prev = X1(end-T+1:end);

xv_raw = (base_lin_prev) + 1e-100;


lnYhat = log(Y0) + (R0.*(val_times - val_times(base_time)) ...
        + log(xv_raw'/Y0(base_var)) - (R1-1).*log(ii'/ii(base_time)))./R1;

Yhat = exp(lnYhat);

if ret_vec == 0
    nLL = - sum(sum(var_data.*lnYhat));
elseif ret_vec == 1
    %nLL = sqrt(-sum(var_data.*(log(Yhat + 1e-10))));
    nLL = sum(sum((var_data - sum(var_data, 1).*Yhat).^2));
else
    nLL = sqrt(-(var_data.*lnYhat));
end

%nLL = nLL(:);

if any(~isreal(nLL) | isinf(nLL) | isnan(nLL))
    fprintf('ERROR');
end

if nargout > 1
    G = zeros(length(X1), 1);
    imap = [1:(base_var-1), (base_var+1):nv]';
    for kk = 1:nv
        G(kk) = sum(var_data(kk, :)/Y0(kk));
    end
    G(base_var) = G(base_var) - (1/Y0(base_var))*sum(sum(var_data./R1));
    
    for kk = nv+1 : 2*nv-1
        jj = imap(kk-nv);
        G(kk) = sum(var_data(jj, :).*(val_times - val_times(base_time))/R1(jj));
    end
    
    for kk = 2*nv : 3*nv-2
        jj = imap(kk - 2*nv + 1);
        G(kk) = -(1./R1(jj)^2)* sum(var_data(jj, :).*(R0(jj)*(val_times - val_times(base_time))...
             + log(xv_raw'./Y0(base_var)) + log(ii'./ii(base_time))));
    end
    
    for kk = 3*nv-1: length(X1)
        tt = kk - 3*nv + 2;
        G(kk) = sum(var_data(:, tt)./(R1*xv_raw(tt)));
    end
    G = -G;
end

end


