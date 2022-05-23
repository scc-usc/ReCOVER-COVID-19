
warning off;
%% Load saved global variants data
T_old = readtable('global_vars_May22.csv');
dstring = '2022-05-01';
%% Load recent global data
global_fail = 0;
options = weboptions;
options.Timeout = 20;

try
    jsondata = webread(['https://lapis.cov-spectrum.org/gisaid/v1/sample/aggregated?fields=gisaidClade,pangoLineage,country,date&dateFrom=' dstring], options);
catch
    try
        jsondata = webread(['https://lapis.cov-spectrum.org/gisaid/v1/sample/aggregated?fields=gisaidClade,pangoLineage,country,date&dateFrom=' dstring], options);
    catch
        global_fail = 1;
    end
end
%% Merge old and new

    fprintf('Loaded Gloabl Variants Data!\n');
    T_prune = struct2table(jsondata.data);
    idx = cellfun(@isempty,(T_prune.date));
    T_prune(idx, :) = [];

    min_new_date = min(datenum(T_prune.date));

    try
    idx = cellfun(@isempty,(T_old.date));
    T_old(idx, :) = [];
    catch
    end

    old_idx_to_rep = datenum(T_old.date) >= min_new_date;   % remove common entries from old table
    T_old(old_idx_to_rep, :) = [];
    
    T_prune = [T_old; T_prune];
%%
    try
    idx = cellfun(@isempty,(T_prune.date));
    T_prune(idx, :) = [];
    catch
    end


    % Process global data: only use data from the last 100 days
%    sel_idx = ((now) - datenum(T_prune.date) < 100); %Only take the last 100 days of data
%    
    T_small = T_prune;

    xx = cellfun(@isempty, T_small.gisaidClade); % Deal with empty clades
    T_small.gisaidClade(xx) = repmat({'other'}, [sum(xx) 1]);
    xx = cellfun(@isempty, T_small.pangoLineage); % Deal with empty pango names
    T_small.pangoLineage(xx) = repmat({'other'}, [sum(xx) 1]);

    %
    countries = readcell('countries_list.txt', 'Delimiter','');
    countries(strcmpi(countries, 'US')) =  {'USA'};
    countries(strcmpi(countries, 'Czechia')) =  {'Czech Republic'};
    maxt = time2num(days(floor(now) - datenum(datetime(2020, 1, 23))));
    ns = length(countries);

    
    xx = startsWith((T_small.pangoLineage), 'BA');
    pre_omic_idx = ~strcmpi(T_small.gisaidClade, 'GRA') & ~strcmpi(T_small.gisaidClade, 'other');
    T_small.pangoLineage(~xx & ~pre_omic_idx) = repmat({'other'}, [sum(~xx & ~pre_omic_idx) 1]);
    T_small.pangoLineage(pre_omic_idx) = repmat({'pre-omicron'}, [sum(pre_omic_idx) 1]);

    lineages_voc = unique(T_small.pangoLineage);
    nl = length(lineages_voc);
    [~, cc] = ismember(T_small.country, countries);
    [~, ll] = ismember(T_small.pangoLineage, lineages_voc);
    dd = days(T_small.date - datetime(2020, 1, 23));

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

    %
    [red_var_matrix_voc, valid_lins_voc, valid_times_voc] = clean_var_data(all_var_data_voc, lineages_voc);

%%    
    %[var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = mnr_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, 300);
    [var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = smooth_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, 300);
    
        save variants_global.mat var_frac_* lineages* rel_adv* valid_* red_var_matrix* all_var_data*;

%% Load saved US variants data
clear;
T_old = readtable('us_vars_May22.csv');
dstring = '2022-05-01';

%% Load new data
us_fail = 0;
options = weboptions;
options.Timeout = 20;
try
    jsondata = webread(['https://lapis.cov-spectrum.org/gisaid/v1/sample/aggregated?fields=gisaidClade,pangoLineage,division,date&country=USA&dateFrom=' dstring], options);
catch
    try
        jsondata = webread(['https://lapis.cov-spectrum.org/gisaid/v1/sample/aggregated?fields=gisaidClade,pangoLineage,division,date&country=USA&dateFrom=' dstring], options);
    catch
        us_fail = 1;
    end
end

%% Merge old and new

    fprintf('Loaded US Variants Data!\n');
    T_prune = struct2table(jsondata.data);
    idx = cellfun(@isempty,(T_prune.date));
    T_prune(idx, :) = [];

    min_new_date = min(datenum(T_prune.date));

    try
    idx = cellfun(@isempty,(T_old.date));
    T_old(idx, :) = [];
    catch
    end

    old_idx_to_rep = datenum(T_old.date) >= min_new_date;   % remove common entries from old table
    T_old(old_idx_to_rep, :) = [];
    
    T_prune = [T_old; T_prune];

%%
    try
    idx = cellfun(@isempty,(T_prune.date));
    T_prune(idx, :) = [];
    catch
    end

    % Process global data: only use data from the last 100 days
%    sel_idx = ((now) - datenum(T_prune.date) < 100); %Only take the last 100 days of data
%    
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

    
    xx = startsWith((T_small.pangoLineage), 'BA');
    pre_omic_idx = ~strcmpi(T_small.gisaidClade, 'GRA') & ~strcmpi(T_small.gisaidClade, 'other');
    T_small.pangoLineage(~xx & ~pre_omic_idx) = repmat({'other'}, [sum(~xx & ~pre_omic_idx) 1]);
    T_small.pangoLineage(pre_omic_idx) = repmat({'pre-omicron'}, [sum(pre_omic_idx) 1]);

    lineages_voc = unique(T_small.pangoLineage);
    nl = length(lineages_voc);
    [~, cc] = ismember(T_small.division, countries);
    [~, ll] = ismember(T_small.pangoLineage, lineages_voc);
    dd = days(T_small.date - datetime(2020, 1, 23));

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

    %
    [red_var_matrix_voc, valid_lins_voc, valid_times_voc] = clean_var_data(all_var_data_voc, lineages_voc);

%%    
    %[var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = mnr_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, 300);
    [var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = smooth_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, 300);
    save variants.mat var_frac_* lineages* rel_adv* valid_* red_var_matrix* all_var_data*;