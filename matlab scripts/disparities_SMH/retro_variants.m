
fname = 'us_vars_May22.csv';
maxdate = datetime(2023, 10, 1);
zero_date = datetime(2020, 1, 2);
bin_sz = 1;

T_prune = readtable(fname);
dstring = '2022-03-31';

try
    idx = cellfun(@isempty,(T_prune.date));
    T_prune(idx, :) = [];
catch
end


rem_idx = T_prune.date > maxdate;
T_prune(rem_idx, :) = [];

%%

T_small = T_prune;

xx = cellfun(@isempty, T_small.gisaidClade); % Deal with empty clades
T_small.gisaidClade(xx) = repmat({'other'}, [sum(xx) 1]);
xx = cellfun(@isempty, T_small.pangoLineage); % Deal with empty pango names
T_small.pangoLineage(xx) = repmat({'other'}, [sum(xx) 1]);
xx = cellfun(@isempty, T_small.division); % Deal with empty division
T_small(xx, :) = [];
%
countries = readcell('us_states_list.txt');

maxt = time2num(days(floor(now) - datenum(datetime(2020, 1, 23))));
ns = length(countries);

pre_omic_idx = ~strcmpi(T_small.gisaidClade, 'GRA') & ~strcmpi(T_small.gisaidClade, 'other');
orig_idx = strcmpi(T_small.gisaidClade, 'S') | strcmpi(T_small.gisaidClade, 'L') | strcmpi(T_small.gisaidClade, 'G') | strcmpi(T_small.gisaidClade, 'V');
alpha_idx = strcmpi(T_small.gisaidClade, 'GRY');
delta_idx = strcmpi(T_small.gisaidClade, 'GK');
T_small.pangoLineage(orig_idx) = repmat({'original'}, [sum(orig_idx) 1]);
T_small.pangoLineage(alpha_idx) = repmat({'alpha'}, [sum(alpha_idx) 1]);
T_small.pangoLineage(delta_idx) = repmat({'delta'}, [sum(delta_idx) 1]);
%T_small.pangoLineage(pre_omic_idx) = repmat({'pre-omicron'}, [sum(pre_omic_idx) 1]);


lineages_voc = unique(T_small.gisaidClade);
nl = length(lineages_voc);
[~, cc] = ismember(T_small.division, countries);
[~, ll] = ismember(T_small.gisaidClade, lineages_voc);
dd = days(T_small.date - zero_date);

if ~strcmpi(lineages_voc, 'other')
    lineages = [lineages_voc; {'other'}];
end
other_idx = find(strcmpi(lineages_voc, 'other'));

%%
all_var_data_voc = zeros(ns, nl, maxt);

for jj = 1:length(cc)
    if cc(jj)>0 && dd(jj) > 0
        all_var_data_voc(cc(jj), ll(jj), dd(jj)) = all_var_data_voc(cc(jj), ll(jj), dd(jj)) + T_small.count(jj);
    end
end

%%

%all_var_data_voc_w = bin_ts(all_var_data_voc, 3, 2, bin_sz, 1);
all_var_data_voc_w = all_var_data_voc;
[red_var_matrix_voc, valid_lins_voc, valid_times_voc] = clean_var_data(all_var_data_voc_w, lineages_voc);

%%
%[var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = mnr_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, 300);
%red_var_matrix_voc = ndSparse(red_var_matrix_voc);
[var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = smooth_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, maxt - 1, 0);
lineages_voc = strcat(lineages_voc, '.');
%%
save retro_variants.mat var_frac_* lineages* rel_adv* valid_* red_var_matrix* all_var_data*;
