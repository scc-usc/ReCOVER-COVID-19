% Generate regions data
nn = 50; % no. of time_series
countries = cell(nn, 1);
popu = 10.^(5 + (9-5)*rand(nn, 1));
maxT = 600;
inter_points = repmat((20:100:maxT), [nn 1]) + randi(20, [nn, length((20:100:maxT))]); 
rec_rate = 1/7; R0 = 3+rand(nn, 1);
init_betas = R0*rec_rate;
inter_max_betas = 1.2*rec_rate; % after the first intervention, R0 will remain below 1.5
inter_days = 60;
start_uns = 6 + (30 - 6)*rand(nn, 1);
end_uns = 1.1 + (8 - 1.1)*rand(nn, 1);
var_uns = 6*rand(nn, 1);
dec_uns = 0;
%% Prepare unreporting factor and intervention driven betas
true_uns1 = zeros(nn, maxT);
all_betas = zeros(nn, maxT);
for jj = 1:nn
    if dec_uns > 0
        xx = -cumsum([0 (randn(1, maxT-1))+abs(randn(1, maxT-1))]);
        xx = xx/max(abs(xx));
        true_uns1(jj, :) = start_uns(jj) + (start_uns(jj) - end_uns(jj))*xx;
    else
        xx = end_uns(jj) + abs((end_uns(jj) + 2*var_uns(jj)*(rand(1, maxT)-0.5)));
        true_uns1(jj, :) = smooth(xx', 7)';
    end
    
    inter_points(jj, :) = sort(inter_points(jj, :));
    xx = inter_max_betas*ones(1, maxT);
    xx(1:inter_points(jj, 1)) = init_betas(jj);
    for ii = 1:size(inter_points, 2)
        last_day = inter_points(jj, ii)+inter_days;
        if  last_day > maxT
            continue
        end
        inter_effect = rec_rate*(1 - 0.5*rand(1)); % Brings R0 to 1 - 0.5*rand(1)
        xx(inter_points(jj, ii):inter_points(jj, ii)+inter_days) = (inter_effect:(inter_max_betas-inter_effect)/(inter_days):inter_max_betas);
    end
    xx(last_day:end) = inter_max_betas;
    % Add random noise and smooth
    all_betas(jj, :) = movmean(xx.*(1+0.2*(0.5-rand(1, length(xx)))), 50);
end

%%
data_4 = zeros(nn, maxT);
true_uns = zeros(nn, maxT);
for cid = 1:nn
    [Re, S, I, R] = sir_sim(all_betas(cid, :),rec_rate,0, popu(cid), 100, maxT, true_uns1(cid, :));
    data_4(cid, :) = Re(1:maxT);
    true_uns(cid, :) = (popu(cid) - S)./Re(1:maxT);
end
%% Plot all
nn = size(data_4, 1);
for cid = 1:nn
    figure;
    plot(diff(data_4(cid, :)));
    title(['Region ' num2str(cid) ': Population = ' num2str(popu(cid))]);
end
%% Identify time-series that do not have multiple waves
rem_idx = [];
%rem_idx = [1, 2, 4, (6:9), 11, 12, (14:16)];
for jj=1:nn
    pks = (findpeaks(movmean(diff(data_4(jj,:)), 56)));
    if length(pks)<2
        rem_idx = [rem_idx; jj];
    end
end
%% Filter time-series that do not have multiple waves
data_4(rem_idx, :) = [];
popu(rem_idx) = [];
true_uns(rem_idx, :) = [];
true_uns1(rem_idx, :) = [];
all_betas(rem_idx, :) = [];
countries(rem_idx, :) = [];
%% Identify unreported
explore_unrep_all;

%% 
iscore_f = []; 
alpha = 0.05;
err_thres = 0.2;
for cid = 1:length(popu)
    xx = find(~isnan(un_uts(cid, :)) & ~isinf(un_uts(cid, :)) & un_lts(cid, :)<1000);
%     disp(['Country ' num2str(cid)]);
%     disp([idx_weeks(xx)' un_lts(cid, xx)' true_uns(cid, idx_weeks(xx))' un_uts(cid, xx)' err_ts(cid, xx)']);
    figure;
    tiledlayout(2, 1);
    nexttile;
    dt = diff(data_4_s(cid, :));
    plot(idx_weeks(xx), dt(idx_weeks(xx)));
    title(['Region ' num2str(cid) ': Population = ' num2str(popu(cid))]);
    nexttile;
    plot(idx_weeks(xx), [un_lts(cid, xx)' true_uns(cid, idx_weeks(xx))' un_uts(cid, xx)']);
    title(['Country ' num2str(cid)]); ylim([0, 20]);
    lb = min([un_lts(cid, xx)' un_uts(cid, xx)'], [], 2); lb = 1;
    ub = max([un_lts(cid, xx)' un_uts(cid, xx)'], [], 2);
    val = true_uns(cid, idx_weeks(xx))';
    iscore_f = [iscore_f ; ((ub - lb) + (2/alpha) * ((val-ub).*(val > ub) + (lb - val).*(val < lb)))];
end
mean(iscore_f)
%%
iscore_h = []; norm_factor_h = 0;
alpha = 0.05;
for cid = 1:length(popu)
    xx = find(~isnan(un_uts(cid, :)) & ~isinf(un_uts(cid, :)) & un_lts(cid, :)<1000 );
    disp(['Country ' num2str(cid)]);
    disp([idx_weeks(xx)' un_h_lts(cid, xx)' true_uns(cid, idx_weeks(xx))' un_h_ts(cid, xx)' un_h_uts(cid, xx)' err_ts(cid, xx)']);
    
    figure;
    tiledlayout(2, 1);
    nexttile;
    dt = diff(data_4_s(cid, :));
    plot(idx_weeks(xx), dt(idx_weeks(xx)));
    title(['Region ' num2str(cid) ': Population = ' num2str(popu(cid))]);
    nexttile;
    plot(idx_weeks(xx), [un_h_lts(cid, xx)' un_h_ts(cid, xx)' true_uns(cid, idx_weeks(xx))' un_h_uts(cid, xx)' popu(cid)./data_4(cid, idx_weeks(xx))']);
    title(['Country ' num2str(cid)]);
    
    norm_factor_h = norm_factor_h + length(xx);
    lb = min([un_h_lts(cid, xx)' un_h_uts(cid, xx)'], [], 2); lb = 1;
    ub = max([un_h_lts(cid, xx)' un_h_uts(cid, xx)'], [], 2);
    val = true_uns(cid, idx_weeks(xx))';
    iscore_h = [iscore_h; ((ub - lb) + (2/alpha) * ((val-ub).*(val > ub) + (lb - val).*(val < lb)))];
end
mean(iscore_h)