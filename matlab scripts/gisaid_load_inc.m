warning off;
%% Load saved global variants data
T_old = readtable('global_vars_May22.csv');
dstring = '2022-05-01';
%% Load recent global data
global_fail = 0;
options = weboptions;
options.Timeout = 20;

try
    jsondata = webread(['https://lapis.cov-spectrum.org/open/v1/sample/aggregated?fields=gisaidClade,pangoLineage,country,date&dateFrom=' dstring], options);
catch
    try
        jsondata = webread(['https://lapis.cov-spectrum.org/open/v1/sample/aggregated?fields=gisaidClade,pangoLineage,country,date&dateFrom=' dstring], options);
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


xx = startsWith((T_small.pangoLineage), {'BA', 'B.1.1.529'});
pre_omic_idx = ~strcmpi(T_small.gisaidClade, 'GRA') & ~strcmpi(T_small.gisaidClade, 'other');
T_small.pangoLineage(~xx & ~pre_omic_idx) = repmat({'other'}, [sum(~xx & ~pre_omic_idx) 1]);
T_small.pangoLineage(pre_omic_idx) = repmat({'pre-omicron'}, [sum(pre_omic_idx) 1]);

lineages_voc = unique(T_small.pangoLineage);
pre_omic_idx = find(strcmp(lineages_voc, 'pre-omicron'));

if isempty(strcmpi(lineages_voc, 'B.1.1.529'))
    lineages_voc = [lineages; {'B.1.1.529'}];
end

nl = length(lineages_voc);
[~, cc] = ismember(T_small.country, countries);
[~, ll] = ismember(T_small.pangoLineage, lineages_voc);
dd = days(T_small.date - datetime(2020, 1, 23));

if ~strcmpi(lineages_voc, 'other')
    lineages_voc = [lineages_voc; {'other'}];
end
other_idx = find(strcmpi(lineages_voc, 'other'));

%%
all_var_data_voc = zeros(ns, nl, maxt);

for jj = 1:length(cc)
    if cc(jj)>0 && dd(jj) > 0
        thisval = T_small.count(jj);
        if ll(jj)~= pre_omic_idx && dd(jj) < days(datetime(2021, 11, 1) - datetime(2020, 1, 23))
            thisval = 0; % a variant that early and not labeled pre-omicron is noise
        end
        all_var_data_voc(cc(jj), ll(jj), dd(jj)) = all_var_data_voc(cc(jj), ll(jj), dd(jj)) + thisval;
    end
end

%%
% Te = readtable('https://opendata.ecdc.europa.eu/covid19/virusvariant/csv/data.csv');
% yy = cellfun(@(x)(str2double(x(1:4))), Te.year_week);
% ww = cellfun(@(x)(str2double(x(6:7))), Te.year_week);
%%

try
    %temp = webread('https://opendata.ecdc.europa.eu/covid19/virusvariant/json');
    temp = readtable('https://opendata.ecdc.europa.eu/covid19/virusvariant/csv/data.csv');
    %%
    % hh = length(temp)
    old_rows = startsWith(temp.year_week, {'2020', '2021'});
    temp(old_rows, :) = [];
    hh = height(temp);
    yy = zeros(hh, 1); ww = zeros(hh, 1);
    var_vals = zeros(hh, 1); isGISAID = zeros(hh, 1);
    var_column = cell(hh, 1); country_column = cell(hh, 1);
    for jj=1:hh
        %     country_column{jj} = temp{jj}.country;
        %     yy(jj) = str2double(temp{jj}.year_week(1:4));
        %     ww(jj) = str2double(temp{jj}.year_week(6:7));
        %     var_column{jj} = temp{jj}.variant;
        %     var_vals(jj) = temp{jj}.number_detections_variant;
        %     isGISAID(jj) = strcmpi(temp{jj}.source, 'GISAID');
        country_column{jj} = temp.country{jj};
        yy(jj) = str2double(temp.year_week{jj}(1:4));
        ww(jj) = str2double(temp.year_week{jj}(6:7));
        var_column{jj} = temp.variant{jj};
        var_vals(jj) = temp.number_detections_variant(jj);
        isGISAID(jj) = strcmpi(temp.source{jj}, 'GISAID');
    end

    dd = days(datetime(yy, 1, 1) + 7*ww - datetime(2020, 1, 23));
    sel_idx = isGISAID > 0 & dd > 768;
    yy = yy(sel_idx); ww = ww(sel_idx); var_vals = var_vals(sel_idx);
    var_column = var_column(sel_idx); country_column = country_column(sel_idx);
    dd = dd(sel_idx);
    countries(strcmpi(countries, 'Czech Republic')) =  {'Czechia'};
    %%
    pre_omic_idx = find(strcmpi(lineages_voc, 'pre-omicron'));
    xx = var_column;
    %xx(strcmp(xx, 'B.1.1.529')) = {'BA.1'};
    other_idx = find(strcmpi(lineages_voc, 'other'));
    %[pre_omic_vars, ~] = ismember(pre_omic_vars_names, xx);
    pre_omic_vars = ~(startsWith(xx, {'BA', 'B.1.1.529', 'other', 'Other'})) & contains(xx, '.');
    pre_omic_vars = pre_omic_vars | (startsWith(xx, {'other', 'Other', 'UNK', 'X'}) & dd < 690);
    xx(pre_omic_vars) = {'pre-omicron'};
    [~, cc] = ismember(country_column, countries);
    [~, ll] = ismember(xx, lineages_voc);
    ll(ll==0) = other_idx;
    [aa] = ismember(countries, country_column);
    %%
    all_var_data_voc(aa, min(dd):end, :) = 0;

    for jj = 1:length(cc)
        if cc(jj)>0 && dd(jj) > 0
            all_var_data_voc(cc(jj), ll(jj), dd(jj)) = all_var_data_voc(cc(jj), ll(jj), dd(jj)) +   var_vals(jj);
        end
    end
catch
    disp('ECDC variant update failed');

end
%%
[red_var_matrix_voc, valid_lins_voc, valid_times_voc] = clean_var_data(all_var_data_voc, lineages_voc);

%%
%[var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = mnr_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, 300);
[var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = smooth_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, maxt-1);
%% Filtered_VOC
filter_list = {'BA.1.1'; 'BA.1'; 'BA.2.12.1'; 'BA.2.75'; 'BA.2'; 'BA.3*';'BA.4*';'BA.5*'; 'pre-omicron'; 'other'};
lineages_f = filter_list; covered = zeros(length(lineages_voc),1 );
ns = size(var_frac_all_voc, 1); T = size(var_frac_all_voc, 3); nl = length(lineages_f);
var_frac_all_f = zeros(ns, nl, T);
var_frac_all_low_f = zeros(ns, nl, T);
var_frac_all_high_f = zeros(ns, nl, T);
for ll = 1:length(lineages_f)-1
    if lineages_f{ll}(end) == '*'
        idx = find(contains(lineages_voc, lineages_f{ll}(1:end-1)) & ~covered); covered(idx) = 1;
    else
        idx = find(strcmpi(lineages_voc, lineages_f{ll})); covered(idx(1)) = 1;
    end
    var_frac_all_f(:, ll, :) = sum(var_frac_all_voc(:, idx, :), 2);
    var_frac_all_low_f(:, ll, :) = sum(var_frac_all_low_voc(:, idx, :), 2);
    var_frac_all_high_f(:, ll, :) = sum(var_frac_all_high_voc(:, idx, :), 2);
end
idx = covered < 1;
var_frac_all_f(:, nl, :) = sum(var_frac_all_voc(:, idx, :), 2);
var_frac_all_low_f(:, nl, :) = sum(var_frac_all_low_voc(:, idx, :), 2);
var_frac_all_high_f(:, nl, :) = sum(var_frac_all_high_voc(:, idx, :), 2);

%%
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
    jsondata = webread(['https://lapis.cov-spectrum.org/open/v1/sample/aggregated?fields=gisaidClade,pangoLineage,division,date&country=USA&dateFrom=' dstring], options);
catch
    try
        jsondata = webread(['https://lapis.cov-spectrum.org/open/v1/sample/aggregated?fields=gisaidClade,pangoLineage,division,date&country=USA&dateFrom=' dstring], options);
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
[var_frac_all_voc, var_frac_all_low_voc, var_frac_all_high_voc, rel_adv_voc] = smooth_variants(red_var_matrix_voc, valid_lins_voc, valid_times_voc, lineages_voc, maxt - 1);

%% Filtered_VOC
filter_list = {'BA.1.1'; 'BA.1'; 'BA.2.12.1'; 'BA.2.75'; 'BA.2'; 'BA.3*';'BA.4*';'BA.5*'; 'pre-omicron'; 'other'};
lineages_f = filter_list; covered = zeros(length(lineages_voc),1 );
ns = size(var_frac_all_voc, 1); T = size(var_frac_all_voc, 3); nl = length(lineages_f);
var_frac_all_f = zeros(ns, nl, T);
var_frac_all_low_f = zeros(ns, nl, T);
var_frac_all_high_f = zeros(ns, nl, T);
for ll = 1:length(lineages_f)-1
    if lineages_f{ll}(end) == '*'
        idx = find(contains(lineages_voc, lineages_f{ll}(1:end-1)) & ~covered); covered(idx) = 1;
    else
        idx = find(strcmpi(lineages_voc, lineages_f{ll})); covered(idx(1)) = 1;
    end
    var_frac_all_f(:, ll, :) = sum(var_frac_all_voc(:, idx, :), 2);
    var_frac_all_low_f(:, ll, :) = sum(var_frac_all_low_voc(:, idx, :), 2);
    var_frac_all_high_f(:, ll, :) = sum(var_frac_all_high_voc(:, idx, :), 2);
end
idx = covered < 1;
var_frac_all_f(:, nl, :) = sum(var_frac_all_voc(:, idx, :), 2);
var_frac_all_low_f(:, nl, :) = sum(var_frac_all_low_voc(:, idx, :), 2);
var_frac_all_high_f(:, nl, :) = sum(var_frac_all_high_voc(:, idx, :), 2);
%%
save variants.mat var_frac_* lineages* rel_adv* valid_* red_var_matrix* all_var_data*;