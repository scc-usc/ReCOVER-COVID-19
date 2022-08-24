addpath('..');

% URL: https://data.chhs.ca.gov/dataset/e39edc8e-9db1-40a7-9e87-89169401c3f5/resource/c5978614-6a23-450b-b637-171252052214/download/covid19postvaxstatewidestats.csv

ca_tab = readtable("ca_vax_outcomes.csv");
load latest_us_data.mat
load vacc_data.mat
load us_hospitalization.mat
%%

all_days = days(ca_tab.DATE - datetime(2020, 1, 23));
maxt = max(all_days);
infec_ineffi = nan(maxt, 1);
hosp_ineffi = nan(maxt, 1);
death_ineffi = nan(maxt, 1);

ca_infec_ineffi(all_days) = ca_tab.VACCINATED_CASES_PER_100K./ca_tab.UNVACCINATED_CASES_PER_100K;
ca_hosp_ineffi(all_days) = ca_tab.VACCINATED_HOSP_PER_100K./ca_tab.UNVACCINATED_HOSP_PER_100K;
ca_death_ineffi(all_days) = ca_tab.VACCINATED_DEATHS_PER_100K./ca_tab.UNVACCINATED_DEATHS_PER_100K;

%%

ca_data_ag = squeeze(sum(data_4_ag(3, :, :), 1));
ca_vac_ag = [zeros(14, 5); squeeze(sum(vacc_num_age_est(3, 1:end-13, :), 1))];
ca_pop_ag = sum(pop_by_age(3, :), 1);

%%
new_infec = nan(maxt, 1);
new_death = nan(maxt, 1);
new_hosp = nan(maxt, 1);

ca_vax = [zeros(1, 14) u_vacc_full(3, 1:maxt-14)]';
ca_vax_ag = squeeze();

new_infec(all_days) = ca_tab.VACCINATED_CASES + ca_tab.UNVACCINATED_CASES; new_infec = movmean(new_infec, 7);
new_vax = movmean([0; diff(ca_vax)], 7);
new_death(all_days) = movmean(ca_tab.VACCINATED_DEATHS + ca_tab.UNVACCINATED_DEATHS, 7);
new_hosp(all_days) = movmean(ca_tab.VACCINATED_HOSP + ca_tab.UNVACCINATED_HOSP, 7);

guess_ts = new_infec.*ca_vax./(popu(3) - ca_vax);
new_vax(isnan(new_vax)) = 0;
%%
un = 1.5; pop12p = 3.3647e+07;
new_vax_cases = nan(maxt, 1);
new_unvax_cases = nan(maxt, 1);

new_vax_cases(all_days) = ca_tab.VACCINATED_CASES;
new_unvax_cases(all_days) = ca_tab.UNVACCINATED_CASES;

vax_cases = cumsum(new_vax_cases, 'omitnan');

unvax_cases = data_4(3, min(all_days)+1) + cumsum(new_unvax_cases, 'omitnan');
unvax_popu = pop12p - ca_vax;
%%


%% Variants data may be useful! Load for CA

sel_var = [2, 4, 5, 11, 12];
[ca_red_var_matrix, ca_valid_lins, ca_valid_times] = clean_var_data(sum(all_var_data(3, sel_var, :), 1), lineages(sel_var));
[ca_var_frac_all, var_frac_all_low, var_frac_all_high, rel_adv] = mnr_variants(red_var_matrix, valid_lins, valid_times, lineages(sel_var), maxt);

%%
