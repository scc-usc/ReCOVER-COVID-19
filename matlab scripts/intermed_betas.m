function [rate_change] = intermed_betas(init_betas, init_param, final_betas, final_param, ndays, init_Rt, final_Rt)
%Finds scaling factors to change an initial infection rate to a final one
%gradually over n time_steps

if nargin < 6
    rate_change = nan(length(init_betas), ndays);    
    init_Rt = calc_Rt(init_betas, init_param(:, 1), init_param(:, 2), ones(length(init_betas), 1));
    final_Rt = calc_Rt(final_betas, final_param(:, 1), final_param(:, 2), ones(length(init_betas), 1));
else
    rate_change = nan(size(init_Rt, 1), ndays);    
end

rate_change(:, 1) = 1;
rate_change(:, end) = final_Rt./init_Rt;

rate_change = fillmissing(rate_change, 'linear', 2);

