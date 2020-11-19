%% Load Data

clear;
load_data_global;
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);

%% Fixed params

min_period = 14;
max_period = 28;
skip_days = 7;
alpha = 1;
k = 1;
jp = 7;
delim = char(9);
endline = '';
meta_end_list = (101:28:size(data_4, 2));

err_ts = nan(size(data_4, 1), length(meta_end_list));
un_ts = nan(size(data_4, 1), length(meta_end_list));

%%
for  mm = 2:length(meta_end_list)
    meta_end = meta_end_list(mm);
    meta_start = meta_end - 56;
    
    un_fact_f = zeros(length(popu), 3);
    st_mid_end = zeros(length(popu), 4);
    
    disp(['Running for ' datestr(datetime(2020, 1, 23)+caldays(meta_end))]);
    
    for cid = 1:length(popu)
        new_infec = diff(data_4_s(cid, meta_start:meta_end));
        [yy, peaksat] = findpeaks(new_infec);
        
        if isempty(peaksat)
            continue;
        end
        
        [~, pidx] = max(yy);
        
        if 1.5*min(new_infec) > yy(pidx) % If the "peak" is not at least 1.5x the min value in the range, then it is noise
            continue;
        end
        
        peakday = meta_start + peaksat(pidx);
        periods = [(peakday-max_period:skip_days:peakday-2*skip_days)' (peakday+2*skip_days:skip_days:peakday+max_period)'];
        err_mat = Inf*ones(size(periods, 1), max_period+1);
        for pp=1:size(periods, 1)
            start_time = periods(pp, 1);
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
        end
        %  Find the best fit
        [val, lidx] = min(err_mat, [], 'all', 'linear');
        pp = mod(lidx-1, size(periods, 1))+1;
        ii = ceil(lidx/size(periods, 1));
        start_time = periods(pp, 1);
        end_time = periods(pp, 2);
        st_mid_end(cid, :) = [start_time, start_time+ii, end_time val];
        
        j = 1;
        try
            [beta_cell, un_prob_f, err, init_dat, ci_f, del, fittedC] = learn_un_fix_beta(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, alpha, a_T, ii, 'l', 1);
            if del(j)>1 || del(j) < 0 || ci_f{j}(1, 1) <= 0
                res_f{j} = 'FAILED';
                st_mid_end(cid, 4) = Inf;
            else
                res_f{j} = [num2str(1./(ci_f{j}(1, 2))),' - ' , num2str(1./(un_prob_f(j))),' - ', num2str(1./((1-del(j))*ci_f{j}(1, 1)))];
                un_fact_f(cid, :) = [ci_f{j}(1, 2), un_prob_f(j), (1-del(j))*ci_f{j}(1, 1)];
                st_mid_end(cid, 4) = err;
                disp([countries{cid}, delim res_f{j}, 'Error = ', num2str(err) ,endline]);
            end
        catch
            res_f{j} = 'FAILED';
        end
    end
    
    good_cid = un_fact_f(:, 2) > 0;
    err_ts(good_cid, mm) = st_mid_end(good_cid, 4);
    un_ts(good_cid, mm) = 1./un_fact_f(good_cid, 2);
end

%%


xx = un_ts.*(1./(err_ts < 0.2 & un_ts < 100)) ;
%yy = nan(size(xx, 1), size(xx, 2));
idx_weeks = (52:7:299);
filled_un = zeros(size(un_ts, 1), length(idx_weeks));

for jj = 1:size(un_ts, 1)
    idx = find(~(isnan(xx(jj, :))|isinf(xx(jj, :))));
    if length(idx) >= 2
        filled_un(jj, :) = interp1(meta_end_list(idx), xx(jj, idx), idx_weeks, 'linear');
    end
    
    if length(idx) == 1
        filled_un(jj, idx_weeks == idx) = xx(jj, idx);
    end
    
    for mm = 2:length(idx_weeks)
        if isnan(filled_un(jj, mm))
            filled_un(jj, mm) = filled_un(jj, mm-1);
        end
    end
end

nzrows = sum(filled_un > 0, 2) > 0;
for jj = 1:size(un_ts, 1)   %% Replace those with no interpolated data with median of the rest
    if sum(abs(filled_un(jj, :))< 1e-10)>0
        filled_un(jj, :) = nanmedian(filled_un(nzrows, :), 1);
    end
end

def_un = 40; % default value to use when nothing is available
foresight = 0; % Do we see the future? Make it zero for forecasting
for jj = 1:size(un_ts, 1)   %% Fill in initial NaNs
    if foresight > 0
    nnanidx = find(~isnan(filled_un(jj, :)));
    if ~isempty(nnanidx)
        if nnanidx(1)>1
            filled_un(jj, 1:nnanidx(1)-1) = filled_un(jj, nnanidx(1));
        end
    end
    else
        nanidx = find(isnan(filled_un(jj, :)) | filled_un(jj, :)< 1e-10 );
        filled_un(jj, nanidx) = def_un;
    end
end

csvwrite(['../results/unreported/' prefix '_all_unreported.csv'], [idx_weeks; filled_un]);


