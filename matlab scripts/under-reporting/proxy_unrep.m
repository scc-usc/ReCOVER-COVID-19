%% Load Data

%clear;
%load_data_us;
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
err_h_ts = nan(size(data_4, 1), length(idx_weeks));
un_h_ts = nan(size(data_4, 1), length(idx_weeks));

periods = [(idx_weeks(1):skip_days:idx_weeks(end)-plen)' (idx_weeks(1)+plen:skip_days:idx_weeks(end))'];
%%
tic;
for  mm = 1:size(periods, 1)
    pp = mm;    % For consistency with some copy-pasted code
    un_fact_f = zeros(length(popu), 3);
    st_mid_end = zeros(length(popu), 4);
    thisdate = datestr(datetime(2020, 1, 23)+caldays(periods(mm, 1)));
    disp(['Running for ' thisdate]);
    
    for cid = 1:length(popu)
       
        start_time = periods(pp, 1);
        end_time = periods(pp, 2);
                
        j = 1;
%        try
            [beta_auto_un1, un_prob_i, init_dat, fittedC, ci_i] = learn_nonlin(data_4_s(cid, start_time-k*jp:end_time), popu(cid), k, jp, 1, [], 'i');    
            [~, err] = calc_errors(fittedC{1}(:, 1)', fittedC{1}(:, 2)');
            res_i{j} = [num2str(1./(ci_i{j}(1, 2))),' - ' , num2str(1./(un_prob_i(j))),' - ', num2str(1./ci_i{j}(1, 1))];
            un_fact_i(cid, :) = [ci_i{j}(1, 2), un_prob_i(j), ci_i{j}(1, 1)];
            thiserr = err;
            disp([thisdate, delim, countries{cid}, delim, res_i{j}, ' Error = ', num2str(err) ,endline]);
            
%         catch
%             disp('FAILED');
%         end
        
        end_idx = 1 + (end_time - idx_weeks(1))/7;
        err_h_ts(cid, end_idx) = thiserr;
        un_h_ts(cid, end_idx) = 1./un_fact_i(cid, 2);
    end
end

toc;

