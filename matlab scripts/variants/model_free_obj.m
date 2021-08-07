function [ferr, G] = model_free_obj(X, var_data)
S1 = 0; S2 = 1e15;

nv = size(var_data, 1);

Yhat = exp(X); Yhat = Yhat./sum(Yhat, 1);
Y1 = [Yhat(:, 1:end-2) zeros(nv, 2)];
Y2 = [zeros(nv, 1) Yhat(:, 2:end-1) zeros(nv, 1)];
Y3 = [zeros(nv, 2) Yhat(:, 3:end)];

 ferr = -sum(sum(var_data.*log(Yhat))) + ...
  S1*sum(sum((Y1 - Y2).^2)) + ...   
 S2*sum(sum((Y1 - 2*Y2 + Y3).^2));

%ferr = -sum(sum(var_data.*(log(Yhat)+log(Y1+ 1e-50)+log(Y2 + 1e-100))));

if nargout > 1
    T1 = sum(var_data, 1).*Yhat - var_data;
    Y3 = (2*Yhat - (Y1 + Y2));
    T2 = 2*S1*( Y3.*Yhat - sum(Y3.*Yhat, 1).*Yhat );
    G = T1 + T2;
end

end

