vacc_by_age = readtable('vacc_by_age.csv');
%%
age_data = startsWith(vacc_by_age.DemographicGroup, 'Ages');
a_groups = unique(vacc_by_age.DemographicGroup(age_data));
a_groups = [a_groups(end); a_groups(1:end-1)];
%%
d_idx = days(vacc_by_age.Date - datetime(2020, 1, 23));

[~, cidx] = ismember(vacc_by_age.DemographicGroup, a_groups);
vacc_perc = nan(length(a_groups), max(d_idx));

for ii = 1:size(vacc_by_age, 1)
    if cidx(ii)>0
        vacc_perc(cidx(ii), d_idx(ii)) = vacc_by_age.PercentOfGroupWithAtLeastOneDose(ii);
    end
end
%% Expected coverage across age groups
final_cov1 = [59 59 59 59 59 56 74 81 81];
final_cov2 = [77 77 77 77 77 78 88 95 95];
final_cov = (final_cov1+final_cov2)*0.5;
final_cov = [0.4 31.8 44.2 49.5 54.3 63.9 73.9 90.1 86.1];