%% Load Data

clear; tic;
load_data_us;
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);

%% Fixed params
a_sunday = 3;
min_period = 14;
max_period = 28;
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
un_midts = nan(size(data_4, 1), length(idx_weeks));
period_checked = nan(size(data_4, 1), length(idx_weeks));

periods = [(idx_weeks(1):skip_days:idx_weeks(end)-plen)' (idx_weeks(1)+plen:skip_days:idx_weeks(end))'];
%%
for  mm = 1:size(periods, 1)
    pp = mm;    % For consistency with some copy-pasted code
    un_fact_f = zeros(length(popu), 3);
    st_mid_end = zeros(length(popu), 4);
    thisdate = datestr(datetime(2020, 1, 23)+caldays(periods(mm, 1)));
    disp(['Running for ' thisdate]);
    
    for cid = 1:length(popu)
        new_infec = diff(data_4_s(cid, periods(mm, 1):periods(mm, 2)));
        [yy, peaksat] = findpeaks(new_infec);
        
        if isempty(peaksat)
            continue;
        end
        
        [~, pidx] = max(yy);
        
        if 1.5*min(new_infec) > yy(pidx) % If the "peak" is not at least 1.5x the min value in the range, then it is noise
            continue;
        end
        
        
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
        
        first_val = 5;
        checkvals = (first_val:(end_time-start_time-first_val));
        a_T = data_4_s(cid, end)./popu(cid);
        
        for ii=checkvals(1):3:checkvals(end)
            try
                [~, ~, err, ~, ~, this_del] = learn_un_fix_beta(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, alpha, a_T, ii, '1', 0);
            catch
                err = Inf;
                this_del = -1;
            end
            if this_del>0 && this_del< 1
                err_mat(pp, ii) = err;
            end
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
        mid_idx = 1+(((start_time + ii) - mod(start_time + ii - a_sunday, 7)) - idx_weeks(1))/7;
        if mid_idx < 1
            continue;   % Too early to record
        end
        try
            [beta_cell, un_prob_f, err, init_dat, ci_f, del, fittedC] = learn_un_fix_beta(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, alpha, a_T, ii, 'l', 1);
            if del(j)>1 || del(j) < 0 || ci_f{j}(1, 1) <= 0
                res_f{j} = 'FAILED';
                st_mid_end(cid, 4) = Inf;
            else
                res_f{j} = [num2str(1./(ci_f{j}(1, 2))),' - ' , num2str(1./(un_prob_f(j))),' - ', num2str(1./((1-del(j))*ci_f{j}(1, 1)))];
                un_fact_f(cid, :) = [ci_f{j}(1, 2), un_prob_f(j), (1-del(j))*ci_f{j}(1, 1)];
                st_mid_end(cid, 4) = err;
                disp([thisdate, delim, countries{cid}, delim res_f{j}, 'Error = ', num2str(err) ,endline]);
            end
        catch
            res_f{j} = 'FAILED';
        end
        
        
        err_ts(cid, mid_idx) = st_mid_end(cid, 4);
        un_ts(cid, mid_idx) = 1./un_fact_f(cid, 2);
        un_lts(cid, mid_idx) = 1./un_fact_f(cid, 3);
        un_uts(cid, mid_idx) = 1./un_fact_f(cid, 1);
    end
end

toc;

