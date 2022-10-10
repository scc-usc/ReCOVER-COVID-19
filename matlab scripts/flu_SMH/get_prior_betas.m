function [all_betas,rate_change_ag] = get_prior_betas(all_data_vars,hosp_cumu_s,vac_effect_all, halpha, hk, hjp, window_size, ret_conf, M_0, un, popu_ag,season)
%Find betas on every sunday: 1st sunday date
skip = 7-weekday(datetime(2021,9,1))+1;
D = days(7-weekday(datetime(2021,9,1)+days(window_size))+1) + datetime(2021,9,1)+days(window_size);
ns = size(hosp_cumu_s, 1);
ag = size(hosp_cumu_s, 3);
all_betas = nan(ns,days(datetime(2022,8,14)-D),ag);
eps = 1e-10;
% all_betas_ci = nan(ns,days(datetime(2022,8,14)-D),ag,num_dh_rates_sample);
if season ~=0
    skip = 0;
end
M_all = M_0;
for i =window_size:7:size(hosp_cumu_s,2)-1 %rolling window
    %Get datapoints at those points in time
    data_vars = all_data_vars(:,:,(i-window_size)+1+skip:i+skip,:);
    hosps = hosp_cumu_s(:,(i-window_size)+1+skip:i+skip,:);
    hosps = hosps - hosps(:, 1, :);
    if sum(hosps, 'all') < 1e-10
        continue;
    end
    vac = vac_effect_all(:,(i-window_size)+1+skip:i+skip,:);

    %Find beta
    [all_betas2, ~, ~, ~, M_all] = get_betas_age_AoN(data_vars, zeros(size(all_data_vars)), 1, 0, hosps, halpha, hk, hjp, window_size, ret_conf, ones(56,1), 0, M_all, vac_effect_all, un, popu_ag);
    betas = cellfun(@(x)(sum(x)), all_betas2);
    all_betas(:,i-window_size+1,:) = betas;% mat2cell(betas);
end


%1st datapoint is on sep1st, assume prior days before that have same
%betas
first_beta = days(window_size)+datetime(2021,9,1)+skip;
missing_days = days(first_beta - datetime(2021,8,14));
all_betas = cat(2,nan(ns,missing_days,ag),all_betas);

for n=1:ns
    for g=1:ag
        these_betas = squeeze(all_betas(n, :, g));
        tt = find(~isnan(these_betas));
        yy = these_betas(tt);
        pp=csaps(tt,yy,0.00001);
        all_betas(n,tt(1):tt(end),g) = fnval(pp,tt(1):tt(end));
        all_betas(n,1,g) = all_betas(n, tt(1), g);
        all_betas(n,end,g) = all_betas(n, tt(1), g);
    end
end

%     all_betas = fillmissing(all_betas, 'next', 2);
%     all_betas = fillmissing(all_betas, 'previous', 2);

rate_change_ag = all_betas./(all_betas(:, 1, :)+eps);%(all_betas(:,1,:)+eps);%min(B,[],2); % base_hosp_rate nanmean(all_betas,2);
rate_change_ag(rate_change_ag > 2.5) = 2.5;
rate_change_ag(rate_change_ag < 0.5) = 0.5;
for n=1:ns %smooth rate_change_ag
    for g = 1:ag
        xx = ((rate_change_ag(n, :, g)'));
        yy = csaps(1:length(xx), xx, 0.00001, [1:length(xx)]);
        rate_change_ag(n, :, g) = yy;
        rate_change_ag(n, :, g) = rate_change_ag(n, :, g)./rate_change_ag(n, 1, g);
    end
end
rate_change_ag(rate_change_ag > 2.5) = 2.5;
rate_change_ag(rate_change_ag < 0.5) = 0.5;

%     for n=1:ns %smooth rate_change_ag
%         for g = 1:ag
%             xx = ((rate_change_ag(n, :, g)'));
%             yy = csaps(1:length(xx), xx, 0.00001, [1:length(xx)]);
%             rate_change_ag(n, :, g) = yy;
%             rate_change_ag(n, :, g) = rate_change_ag(n, :, g)./rate_change_ag(n, 1, g);
%         end
%     end


end

