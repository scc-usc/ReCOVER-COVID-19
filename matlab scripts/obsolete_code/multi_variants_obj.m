function [nLL, gradLL] = multi_variants_obj(Y, var_data, val_times)
% negative log-likelihood
tmax = size(var_data, 2);
Y = reshape(Y, [length(Y)/(tmax+2), tmax+2]);
nLL = - sum(sum(var_data(:, val_times).*log(Y(:, val_times)+ 1e-20)));

gradLL = zeros(size(Y));
gradLL(:, val_times) = -var_data(:, val_times)./(Y(:, val_times)+ 1e-20);
gradLL = gradLL(:);
end

