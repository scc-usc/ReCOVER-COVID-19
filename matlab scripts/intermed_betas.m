function [rate_change] = intermed_betas(init_betas, init_param, final_betas, final_param, ndays, init_Rt, final_Rt)
%Finds scaling factors to change an initial infection rate to a final one
%gradually over n time_steps
if size(init_betas, 2)==1
    if nargin < 6
        rate_change = nan(length(init_betas), ndays);
        init_Rt = calc_Rt(init_betas, init_param(:, 1), init_param(:, 2), ones(length(init_betas), 1));
        final_Rt = calc_Rt(final_betas, final_param(:, 1), final_param(:, 2), ones(length(init_betas), 1));
    else
        rate_change = nan(size(init_Rt, 1), ndays);
    end
    
    rate_change(:, 1) = 1;
    rate_change(:, end) = final_Rt./(1e-20 + init_Rt);
else
    ag = size(init_betas, 2);
    rate_change = nan(length(init_betas), ndays, ag);
    if nargin < 6    
        for g = 1:ag
            init_Rt = calc_Rt(init_betas(:, g), init_param(:, 1), init_param(:, 2), ones(length(init_betas), 1));
            final_Rt = calc_Rt(final_betas(:, g), final_param(:, 1), final_param(:, 2), ones(length(init_betas), 1));
            rate_change(:, 1, g) = 1;
            rate_change(:, end, g) = final_Rt./(1e-20 + init_Rt);
        end
    end


end

rate_change = fillmissing(rate_change, 'linear', 2);

