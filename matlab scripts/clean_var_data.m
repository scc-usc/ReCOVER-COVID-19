function [red_var_matrix, valid_lins, valid_times] = clean_var_data(all_var_matrix, lineages, filter_vars)
nl = size(all_var_matrix, 2);
ns = size(all_var_matrix, 1);
red_var_matrix = all_var_matrix;
valid_lins = zeros(ns, nl);
valid_times = zeros(ns, size(all_var_matrix, 3));
total_samps = zeros(ns, size(all_var_matrix, 3));
other_idx = find(strcmpi(lineages, 'other'));

if nargin < 3
    filter_vars = zeros(5, 1);
    filter_vars(2) = 10;
    filter_vars(4) = 3;
    filter_vars(5) = 0.01;
end

min_samples_per_day = filter_vars(1); 
raw_counts= filter_vars(2); 
raw_prev_thres = filter_vars(3); 
raw_single_day = filter_vars(4); 
min_max_frac = filter_vars(5);

for jj=1:ns
    xx = squeeze(all_var_matrix(jj, :, :));
    vcount = (squeeze(nansum(xx, 2)));
    valid_idx = (vcount/sum(vcount)>raw_prev_thres) & vcount > raw_counts & any(xx >= raw_single_day, 2) & max(xx./vcount, [], 2)>min_max_frac;
    new_other = squeeze(nansum(red_var_matrix(jj, ~valid_idx, :), 2));
    red_var_matrix(jj, ~valid_idx, :) = 0;
    red_var_matrix(jj, other_idx, :) = squeeze(red_var_matrix(jj, other_idx, :)) + new_other;
    
%     if jj == 396
%         display('.');
%     end

    valid_lins(jj, :) = valid_idx; valid_lins(jj, other_idx)=1;
    total_samps(jj, :) = squeeze(nansum(red_var_matrix(jj, :, :), 2));
    valid_times(jj, :) = total_samps(jj, :) > min_samples_per_day;
    red_var_matrix(jj, :, ~valid_times(jj, :)) = 0;
    total_samps(jj, ~valid_times(jj, :)) = 0;
    
    if ~any(valid_idx > 0 )
        valid_lins(jj, other_idx) = 1;
        red_var_matrix(jj, other_idx, :) = 10;
        valid_times(jj, :) = 1;
    end
        % Remove "other" if we have at least two lineages
%     if sum(valid_lins(jj, :)) > 2
%         valid_lins(jj, other_idx) = 0;
%     end
end

end

