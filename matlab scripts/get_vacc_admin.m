function [vacc_given_by_age] = get_vacc_admin(vacc_perc, target_cov, age_cov, min_age, popu_for_vacc, vacc_fd, horizon)
% vacc_given_by_age(:, :, :) is num_reg x horizon x num_age_groups

popu_for_vacc(1, :) = popu_for_vacc(1, :)*(12-min_age)/12;

tot_popu_for_vacc = sum(popu_for_vacc, 2);
rel_cov = age_cov/100;
prev_cov = (dot(rel_cov, tot_popu_for_vacc)./sum(tot_popu_for_vacc));
if target_cov > 0
    final_cov = age_cov .* target_cov/prev_cov;
else
    final_cov = age_cov;
end

vacc_given_by_age = zeros(size(vacc_fd, 1), horizon, length(tot_popu_for_vacc));
latest_vac =  vacc_fd(:, end);
vacc_perc_orig = vacc_perc;

for cid = 1:size(vacc_fd, 1)
    mdl = cell(size(vacc_perc, 1), 1);
%     vfact = latest_vac(cid)./(dot(popu_for_vacc(:, cid), vacc_perc_orig(:, end))/100);
%     vacc_perc = vfact*vacc_perc_orig;
    vacc_perc(vacc_perc>95) = 95;
    % Fit data
    for ii = 1:size(vacc_perc, 1)
        if sum(vacc_perc(ii, :)>0) < 1
            continue;
        end
        modelfun = @(b, x)(final_cov(ii)./(1+exp(b(2)*x - b(3))));
        X = find(~isnan(vacc_perc(ii, :)));
        Y = vacc_perc(ii, X);
        mdl{ii} = fitnlm(X(end-70:end), Y(end-70:end), modelfun, [0 0 0]');
    end
    
    % Estimate and Predict
    last_date = size(vacc_perc, 2)+ horizon;
    vacc_est = nan(size(vacc_perc, 1), last_date);
    for ii = 1:size(vacc_perc, 1)
        if sum(vacc_perc(ii, :)>0) < 1
            continue;
        end
        target_dates = [1:last_date];
        vacc_est(ii, :) = predict(mdl{ii}, target_dates');
    end
    xx = popu_for_vacc(:, cid)' .* vacc_est(:, (last_date - horizon +1): last_date)'/100;
    vfact = vacc_fd(cid, end)/sum(xx(1, :));
    vacc_given_by_age(cid, :, :) = xx*vfact;
end

display(sum(sum(sum(vacc_given_by_age(:, end, :))))./sum(sum(popu_for_vacc)));
end

