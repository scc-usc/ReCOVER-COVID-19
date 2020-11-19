%% Load Data

clear;
load_data_us;
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);

%% Fixed params
meta_start = 50;
meta_end = 110;
min_period = 14;
max_period = 28;
skip_days = 7;
alpha = 1; %best_param_list_no(j, 3)*0.1;
k = 1; %best_param_list_no(j, 1);
jp = 7; %best_param_list_no(j, 2);
delim = char(9);
endline = '';
un_fact_f = zeros(length(popu), 3);
un_fact_i = zeros(length(popu), 3);
un_fact_ll = zeros(length(popu), 3);
st_mid_end = zeros(length(popu), 4);
%% Iterate through all regions

%for cid = 11:11
for cid = 1:length(popu)
    new_infec = diff(data_4_s(cid, meta_start:meta_end));
    [yy, peaksat] = findpeaks(new_infec);
    
    if isempty(peaksat)
        continue;
    end
    
    [~, pidx] = max(yy);
    
    if 2*min(new_infec) > yy(pidx) % If the "peak" is not at least double the min value in the range, then it is noise
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
    
    % Auto-detect using FIR and NLR
    
    try
        [beta_cell, un_prob_f, err, init_dat, ci_f, del, fittedC] = learn_un_fix_beta(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, alpha, a_T, ii, 'l', 1);
        [beta_auto_un1, un_prob_i, init_dat, fittedC, ci_i] = learn_nonlin(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, 1, [], 'i');
        [beta_auto_un2, un_prob_ll, init_dat, fittedC, ci_ll] = learn_nonlin(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, 1, [], 'l');
        delta_list(cid) = del;
    catch
        un_prob_i = 0;
        un_prob_ii = 0;
        delta_list(cid) = -1;
    end
    
    % Generate table for unreported cases
    % We have assumed that the dynamics don't change in the time period under consideration.
    % We do not provide any tests to confirm this. For now, this has to be assessed
    % visually.
    
    j = 1;
    
    try
        res_i{j} =  [num2str(1./(ci_i{j}(1, 2))),' - ' , num2str(1./(un_prob_i(j))),' - ',  num2str(1./(ci_i{j}(1, 1)))];
    catch
        res_i{j} = 'FAILED';
    end
    
    try
        res_ll{j} = [num2str(1./(ci_ll{j}(1, 2))),' - ' , num2str(1./(un_prob_ll(j))),' - ', num2str(1./(ci_ll{j}(1, 1)))];
    catch
        res_ll{j} = 'FAILED';
    end
    
    try
        if del(j)>1 || del(j) < 0
            res_f{j} = 'FAILED';
            st_mid_end(cid, 4) = Inf;
        else
            res_f{j} = [num2str(1./(ci_f{j}(1, 2))),' - ' , num2str(1./(un_prob_f(j))),' - ', num2str(1./((1-del(j))*ci_f{j}(1, 1)))];
            un_fact_f(cid, :) = [ci_f{j}(1, 2), un_prob_f(j), (1-del(j))*ci_f{j}(1, 1)];
            un_fact_i(cid, :) = [ci_i{j}(1, 2), un_prob_i(j), ci_i{j}(1, 1)];
            un_fact_ll(cid, :) = [ci_ll{j}(1, 2), un_prob_ll(j), ci_ll{j}(1, 1)];
            st_mid_end(cid, 4) = err;
        end
    catch
        res_f{j} = 'FAILED';
    end
    disp([countries{cid}, delim, res_i{j}, delim, res_ll{j}, delim res_f{j}, 'Error = ', num2str(err) ,endline]);
end

%%
good_cid = st_mid_end(:, 4)<0.2 & un_fact_f(:, 2) > 0;