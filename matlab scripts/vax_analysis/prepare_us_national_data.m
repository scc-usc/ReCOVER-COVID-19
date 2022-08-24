addpath('..');
addpath('../scenario_projections/');

load latest_us_data.mat
load us_hospitalization.mat

sel_url = 'https://data.cdc.gov/api/views/3rge-nu2a/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
effi_data_tab1 = readtable('dummy.csv');

%%
vacc_download_age_state;
CDC_sero;
%%
age_map = containers.Map();
age_map('0-4') = 1;
age_map('5-11') = 2;
age_map('12-17') = 3;
age_map('18-29') = 4;
age_map('30-49') = 4;
age_map('50-64') = 4;
age_map('65-79') = 5;
age_map('80+') = 5;
age_map('all_ages_adj') = 0;
%%
idx = strcmp(effi_data_tab1.VaccineProduct, 'all_types');
effi_data_tab = effi_data_tab1(idx, :);
%%
maxt = size(data_4, 2);
ns = size(data_4, 1);
ag = 5;

infec_ratio =  nan(maxt, ag);
vax_num_dummy =  zeros(maxt, ag);
unvax_num_dummy =  zeros(maxt, ag);
infec_vac = zeros(maxt, ag);
infec_unvac = zeros(maxt, ag);
death_vac = zeros(maxt, ag);
death_unvac = zeros(maxt, ag);
death_ratio = nan(maxt, ag);
MMWR_week = mod(effi_data_tab.MMWRWeek, 100);
t = datetime(2021, 1, 1, 'Format', 'dd-MMMM-yyyy');
all_dates = t - days(weekday(t)-1) + days((MMWR_week).*7);
didx = days(all_dates - datetime(2020, 1, 23));

for j=1:length(all_dates)
    gg = age_map(effi_data_tab.AgeGroup{j});
    if gg < 1
        continue;
    end

    if strcmp(effi_data_tab.outcome{j}, 'case')
        infec_vac(didx(j), gg) = infec_vac(didx(j), gg) + effi_data_tab.VaccinatedWithOutcome(j);
        infec_unvac(didx(j), gg) = infec_vac(didx(j), gg) + effi_data_tab.UnvaccinatedWithOutcome(j);
        vax_num_dummy(didx(j), gg) = vax_num_dummy(didx(j), gg) + effi_data_tab.FullyVaccinatedPopulation(j);
        unvax_num_dummy(didx(j), gg) = unvax_num_dummy(didx(j), gg) + effi_data_tab.UnvaccinatedPopulation(j);
    end

    if strcmp(effi_data_tab.outcome{j}, 'death')
        death_vac(didx(j), gg) = death_vac(didx(j), gg) + effi_data_tab.VaccinatedWithOutcome(j);
        death_unvac(didx(j), gg) = death_vac(didx(j), gg) + effi_data_tab.UnvaccinatedWithOutcome(j);
    end
end

%%
udidx = unique(didx);
data_selector = zeros(maxt, 1); data_selector(udidx) = 1;
first_day = find(data_selector); last_day = first_day(end); first_day = first_day(1);

infec_vac(~data_selector, :) = nan; 
infec_unvac(~data_selector, :) = nan; 

cum_vax_infec = cumsum(infec_vac, 1, 'omitnan');
cum_unvax_infec = cumsum(infec_unvac, 1, 'omitnan');

vax_num_dummy(~data_selector, :) = nan;
unvax_num_dummy(~data_selector, :) = nan;

cum_vax_infec(~data_selector, :) = nan;
cum_unvax_infec(~data_selector, :) = nan;

vax_num_dummy(first_day:last_day, :) = fillmissing(vax_num_dummy(first_day:last_day, :), 'linear', 1);
unvax_num_dummy(first_day:last_day, :) = fillmissing(unvax_num_dummy(first_day:last_day, :), 'linear', 1);

cum_vax_infec(first_day:last_day, :) = fillmissing(cum_vax_infec(first_day:last_day, :), 'linear', 1);
cum_unvax_infec(first_day:last_day, :) = fillmissing(cum_unvax_infec(first_day:last_day, :), 'linear', 1);

infec_vac = diff(cum_vax_infec);
infec_unvac = diff(cum_unvax_infec);

infec_ratio = infec_vac./infec_unvac;
%%
countries = readcell('us_states_list.txt');
reporting_regions = readcell('infec_effi_regions.txt');
aa = ismember(countries, reporting_regions);

data_4_ag = cumsum([zeros(ns, 1) diff(data_4, 1, 2)].*c_3d1, 2);
deaths_ag = cumsum([zeros(ns, 1) diff(deaths, 1, 2)].*d_3d1, 2);


data_ag = squeeze(sum(data_4_ag(aa, :, :), 1));
%vac_ag = squeeze(sum(vacc_num_age_est(aa, 1:end-13, :), 1));
vac_ag = [zeros(14, 5); squeeze(sum(vacc_num_age_est(aa, 1:end-13, :), 1))];
pop_ag = sum(pop_by_age(aa, :), 1);
%% Get Variant data

T_prune = readtable('../US_state_variants.csv');
sel_idx = ((now) - datenum(T_prune.date) < 100); %Only take the last 100 days of data
sel_idx(:) = 1;
T_small = T_prune(sel_idx, :);
xx = cellfun(@isempty, T_small.gisaidClade); % Deal with empty clades
T_small.gisaidClade(xx) = repmat({'other'}, [sum(xx) 1]);

countries = readcell('us_states_list.txt');

maxt = time2num(days(floor(now) - datenum(datetime(2020, 1, 23))));
ns = length(countries);

lineages = unique(T_small.gisaidClade);
%%
delta_idx = strcmpi(lineages, 'GK'); % Make this the reference (last lineage)
lineages(delta_idx) = [];
lineages = [lineages; 'GK'];

[~, cc] = ismember(T_small.division, countries);
[~, ll] = ismember(T_small.gisaidClade, lineages);
dd = days(T_small.date - datetime(2020, 1, 23));

% idx = find(strcmpi(lineages, 'O'));
% if ~isempty(idx)
%     lineages{idx} = 'other';
% else
%     lineages = [lineages; {'other'}];
% end
other_idx = find(strcmpi(lineages, 'other'));
delta_idx = strcmpi(lineages, 'GK');
lineages{delta_idx} = 'Delta';
lineages{strcmpi(lineages, 'GRA')} = 'Omicron';
omic_idx = find(strcmpi(lineages, 'Omicron'));
nl = length(lineages);
all_var_data = zeros(ns, nl, maxt);

for jj = 1:length(cc)
    if cc(jj)>0 && dd(jj) > 0
        all_var_data(cc(jj), ll(jj), dd(jj)) = all_var_data(cc(jj), ll(jj), dd(jj)) + T_small.count(jj);
    end
end

%%
sel_var = [2, 4, 5, 11, 12];
[red_var_matrix, valid_lins, valid_times] = clean_var_data(sum(all_var_data(aa, sel_var, :), 1), lineages(sel_var));
[var_frac_all, var_frac_all_low, var_frac_all_high, rel_adv] = smoothed_variants(red_var_matrix, valid_lins, valid_times, lineages(sel_var), maxt);