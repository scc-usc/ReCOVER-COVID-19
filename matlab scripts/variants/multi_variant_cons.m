function [c, ceq] = multi_variant_cons(X1, var_data, val_times, ii, base_var)

nv = size(var_data, 1);
T = size(var_data, 2);


Y0 = abs(X1(1:nv))+ 1e-30; Y0 = Y0/sum(Y0);
R0 = X1(nv+1:(2*nv-1)); R0 = [R0(1:(base_var-1)); 0; R0(base_var:end)];
R1 = 1e-3 + abs(X1(2*nv:3*nv-2)); R1 = [R1(1:(base_var-1)); 1; R1(base_var:end)];
base_lin_prev = X1(end-T+1:end);

c = zeros(T, 1);
ceq = zeros(T, 1);

xv_raw = abs(base_lin_prev) + 1e-100;

for t = 1:T
    %A = Y0./(Y0(base_var).^(1./R1)) .* exp((R0)*(val_times(t) - val_times(end))./R1);
    %B = (R1(base_var)./R1);
    %ceq(t) = sum(A .* (xv_raw(t)).^B) - ii(t);
    
    ceq(t) = sum(exp((R0).*(val_times(t) - val_times(end))./R1) .* Y0 ...
        .* ((xv_raw(t)/Y0(base_var)).^(1./R1)) .* ((ii(t)/ii(end)).^(1./R1 - 1))) - 1;
    
    
    
%     if t>2
%         %c(t) = -abs(xv_raw(t) - 2*xv_raw(t-1) + xv_raw(t-2)) + 0.01*xv_raw(t);
%         c(t) = -abs(base_lin_prev(t) - base_lin_prev(t-1))/base_lin_prev(t) + 0.1;
%     end
end

if any(isnan(ceq) | isinf(ceq))
    fprintf('ERROR');
end

end
