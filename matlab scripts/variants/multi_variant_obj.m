function [nLL, Yhat, err_mat, Y0, R0, R1] = multi_variant_obj(X, var_data, val_times, ii, ret_vec, base_var)
% returns the negative log likelihood of observing the data with the
% seleciton probabilities implicitly defined by the constraints

nv = size(var_data, 1);
T = size(var_data, 2);

X1 = X;

Y0 = abs(X1(1:nv))+ 1e-30; Y0 = Y0/sum(Y0);
R0 = X1(nv+1:(2*nv-1)); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
R1 = 1e-3 + abs(X1(2*nv:3*nv-2)); R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];
base_lin_prev = X1(end-T+1:end);

Yhat = zeros(size(var_data)); lnYhat = Yhat;
err_mat = zeros(size(var_data));
xv_raw = abs(base_lin_prev) + 1e-100;


for t = 1:T
    %Yhat(:, t) = exp((R0).*(val_times(t) - val_times(end))./R1) .* Y0 ...
     %   .* ((xv_raw(t)/Y0(base_var)).^(1./R1)) .* ((ii(t)/ii(end)).^(1./R1 - 1));
    
    lnYhat(:, t) = log(Y0) + (R0*(val_times(t) - val_times(end)) ...
        + log(xv_raw(t)/Y0(base_var)) - (R1-1).*log(ii(t)/ii(end)))./R1;
end

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

end


