load latest_us_data.mat
%%
abvs = readcell('us_states_abbr_list.txt');

tic;
T = table;
for jj=1:length(abvs)
    try
        temp = webread(['https://api.outbreak.info/genomics/prevalence-by-location-all-lineages?location_id=USA_US-' abvs{jj} '&other_threshold=0.03&nday_threshold=5&ndays=60']);
        T0 = struct2table(temp.results); T0.state = repmat(abvs(jj), [size(T0, 1) 1]);
        T = [T; T0];
    catch
        disp(['No data for ' abvs{jj}]);
        %break;
    end
end

%%
lineages = unique(T.lineage);
all_var_matrix = nan(length(abvs), length(lineages), size(data_4, 2));
all_var_est_matrix = nan(length(abvs), length(lineages), size(data_4, 2));
all_dates = days(T.date-datetime(2020, 1, 23));
[~, all_states] = ismember(T.state, abvs);
[~, all_lineages] = ismember(T.lineage, lineages);
for jj=1:length(T.state)
        all_var_matrix(all_states(jj), all_lineages(jj), all_dates(jj)) = T.lineage_count(jj);
        all_var_est_matrix(all_states(jj), all_lineages(jj), all_dates(jj)) = T.prevalence_rolling(jj);
end

%% Prune low frequency variants
all_var_matrix = fillmissing(all_var_matrix,'constant',0);
red_var_matrix = all_var_matrix;
min_samples_per_day = 0; raw_counts= 0; raw_prev_thres = 0; raw_single_day = 5;
valid_lins = zeros(length(abvs), length(lineages));
valid_times = zeros(length(abvs), size(all_var_matrix, 3));
total_samps = zeros(length(abvs), size(all_var_matrix, 3));
other_idx = find(strcmpi(lineages, 'other'));

for jj=1:length(abvs)
    xx = squeeze(all_var_matrix(jj, :, :));
    vcount = (squeeze(nansum(xx, 2)));
    valid_idx = (vcount/sum(vcount)>raw_prev_thres) & vcount > raw_counts & any(xx >= raw_single_day, 2);
    new_other = squeeze(sum(red_var_matrix(jj, ~valid_idx, :), 2));
    red_var_matrix(jj, ~valid_idx, :) = 0;
    red_var_matrix(jj, other_idx, :) = new_other;
    
    valid_lins(jj, :) = valid_idx; valid_lins(jj, other_idx)=1;
    total_samps(jj, :) = squeeze(sum(red_var_matrix(jj, :, :), 2));
    valid_times(jj, :) = total_samps(jj, :) > min_samples_per_day;
    red_var_matrix(jj, :, ~valid_times(jj, :)) = 0;
    total_samps(jj, ~valid_times(jj, :)) = 0;
    
    if ~any(valid_idx > 0 )
        valid_lins(jj, other_idx) = 1;
        red_var_matrix(jj, other_idx, :) = 10;
        valid_times(jj, :) = 1;
    end
end


%% Fit multinomial curves
ns = size(data_4, 1); nl = length(lineages); maxT = size(data_4, 2);
var_frac_all = zeros(size(all_var_est_matrix));
var_frac_se = nan(ns, nl);
rel_adv = nan(ns, nl);
for cid = 1:ns
    var_data = squeeze(red_var_matrix(cid, valid_lins(cid, :)>0, :));
    these_lins = find(valid_lins(cid, :)>0);
    val_times = find(valid_times(cid, :)>0); val_times(val_times< (maxT-90)) = [];

 %   try
     if size(var_data, 2) == 1
         var_frac_all(cid, these_lins, :) = 1;
     else
    var_data = var_data(:, val_times); 

    [betaHat, stat] = mnrfit(val_times', var_data');
    piHat = mnrval(betaHat, (1:maxT)');
    var_frac_all(cid, these_lins, :) = piHat';
    rel_adv(cid, these_lins(1:end-1)) = betaHat(2, :);
    rel_adv(cid, these_lins(end)) = 0;
     end
%     catch
%         fprintf('|');
%     end
end
%%
save variants.mat