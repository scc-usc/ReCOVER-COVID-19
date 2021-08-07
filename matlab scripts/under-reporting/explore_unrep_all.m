%% Load Data

% clear;
% load_data_county;
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);

%% Fixed params
a_sunday = 3;
min_period = 14;
max_period = 35;
plen = max_period;
skip_days = 7;
alpha = 1;
k = 1;
jp = 7;
delim = char(9);
endline = '';
idx_weeks = 52:7:size(data_4, 2);
err_ts = nan(size(data_4, 1), length(idx_weeks));
un_ts = nan(size(data_4, 1), length(idx_weeks));
un_lts = nan(size(data_4, 1), length(idx_weeks));
un_uts = nan(size(data_4, 1), length(idx_weeks));
period_checked = nan(size(data_4, 1), length(idx_weeks));

un_h_ts = nan(size(data_4, 1), length(idx_weeks));
un_h_lts = nan(size(data_4, 1), length(idx_weeks));
un_h_uts = nan(size(data_4, 1), length(idx_weeks));

periods = [(idx_weeks(1):skip_days:idx_weeks(end)-plen)' (idx_weeks(1)+plen:skip_days:idx_weeks(end))'];

best_range = [ones(length(popu), 1)*1e-10, ones(length(popu), 1)];
err_thres = 0.04;
%%
tic;
for mm = 1:size(periods, 1)
    pp = mm;    % For consistency with some copy-pasted code
    un_fact_f = zeros(length(popu), 3);
    st_mid_end = zeros(length(popu), 4);
    thisdate = datestr(datetime(2020, 1, 23)+caldays(periods(mm, 1)));
    disp(['Running for ' thisdate]);
    
    for cid = 1:length(popu)
        
        err_mat = Inf*ones(size(periods, 1), max_period+1);
        start_time = periods(pp, 1);
        
        previous_sun = start_time - mod(start_time-a_sunday, 7);
        week_idx = 1+(previous_sun - idx_weeks(1))/7; % week_id in selected weeks
        if week_idx < 1
            continue;
        end
        if ~isnan(period_checked(cid, week_idx))
            continue;   % This period has already been checked, no need to recompute
        else
            period_checked(cid, week_idx) = 1;  % Flag that the period has been checked
        end
        end_time = periods(pp, 2);
        
        this_t = floor((end_time + start_time)/2);
        mid_idx = 1+((start_time - mod(start_time - a_sunday, 7)) - idx_weeks(1))/7;
        if mid_idx < 1
            continue;   % Too early to record
        end
        
        %a_T = data_4_s(cid, end)./popu(cid);
        a_T = data_4_s(cid, end_time)./popu(cid);
        %lb = max([best_range(cid, 1) a_T]); ub = min([best_range(cid, 2) 1]);
        lb = a_T; ub = 1;
        un_prob_h = 1; ci_h{1} = [0 1]; err = Inf;
%        [~, un_prob_h, ~, ~, ci_h, err] = learn_nonlin_imm(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, alpha, {0.5}, 'i', [lb ub]);
        err_h_ts(cid, mid_idx) = err;
        un_h_ts(cid, mid_idx) = 1./un_prob_h;
        un_h_uts(cid, mid_idx) = 1./ci_h{1}(1, 1);
        un_h_lts(cid, mid_idx) = 1./ci_h{1}(1, 2);
        
        first_val = 7;
        checkvals = (first_val:(end_time-start_time-first_val)/2);
        
        for ii=checkvals(1):3:checkvals(end)
            [~, ~, err, ~, thisci, this_del] = learn_un_fix_beta_2way(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, alpha, a_T, ii, 'f', 1);
            err_mat(pp, ii) = abs(thisci{1}(1, 2)-thisci{1}(1, 1));
%             if err >= 1
%                 err_mat(pp, ii) = (err-1);
%             end
        end
        
        if sum(sum(~isinf(err_mat))) < 1
            continue;   % No periods were computed, no need to proceed
        end
        %  Find the best fit
        [val, lidx] = min(err_mat, [], 'all', 'linear');
        pp = mod(lidx-1, size(periods, 1))+1;
        ii = ceil(lidx/size(periods, 1));
        start_time = periods(pp, 1);
        end_time = periods(pp, 2);
        st_mid_end(cid, :) = [start_time, start_time+ii, end_time val];
        
        j = 1;
        
        [beta_cell, un_prob_f, err, init_dat, ci_f, del, fittedC] = learn_un_fix_beta_2way(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, alpha, a_T, ii, 'f', 1);
        lb = max([ci_f{j}(1, 1) a_T]);
        %lb = max([(1-del(j))*un_prob_f(j) a_T]);
        res_f{j} = [num2str(1./(ci_f{j}(1, 2))),' - ' , num2str(1./(un_prob_f(j))),' - ', num2str(1./lb)];
        un_fact_f(cid, :) = 1./[ci_f{j}(1, 2), un_prob_f(j), lb];
        st_mid_end(cid, 4) = err;
        
        if err < err_thres
            best_range(cid, :) = [max([1./un_fact_f(cid, 2), a_T]) 1./un_fact_f(cid, 1)];
        end
        if ci_f{j}(1, 1) > 1.1*a_T
            disp(['[ ' num2str(data_4(j, start_time+ii)./popu(j)), delim, num2str(a_T) ']', delim, countries{cid}, delim res_f{j}, 'Limit: ' num2str(1./a_T) ', Error = ', num2str(err) ,endline]);
        end
        
        err_ts(cid, mid_idx) = st_mid_end(cid, 4);
        un_ts(cid, mid_idx) = un_fact_f(cid, 2);
        un_lts(cid, mid_idx) = un_fact_f(cid, 1);
        un_uts(cid, mid_idx) = un_fact_f(cid, 3);
        
    end
end
toc;

