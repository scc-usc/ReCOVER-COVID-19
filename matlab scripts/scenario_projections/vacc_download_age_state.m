addpath('../');
sel_url = 'https://data.cdc.gov/api/views/unsk-b7fc/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
vacc_age_state = readtable('dummy.csv');
%%
abvs = readcell('us_states_abbr_list.txt');

%%
d_idx = days(vacc_age_state.Date - datetime(2020, 1, 23));
[aa, bb] = ismember(vacc_age_state.Location, abvs);
%%

vacc_num_age = nan(length(abvs), max(d_idx), 5); % 4 age groups in data + 1 for 0-5
vacc_full = nan(length(abvs), max(d_idx));

extra_dose_age = nan(length(abvs), max(d_idx), 5);
extra_dose_full = nan(length(abvs), max(d_idx));

us_idx = strcmpi(vacc_age_state.Location, "US");
us_extra_dose_age = nan(1, max(d_idx), 5);
us_extra_dose_full = nan(1, max(d_idx), 1);

pop_by_age_all = nan(length(abvs), max(d_idx), 5);
for ii = 1:size(vacc_age_state, 1)
    if bb(ii)> 0
        %Series Complete by age
        vacc_num_age(bb(ii), d_idx(ii), 2) = vacc_age_state.Series_Complete_Yes(ii); % - vacc_age_state.Series_Complete_12Plus(ii);
        vacc_num_age(bb(ii), d_idx(ii), 3) = vacc_age_state.Series_Complete_12Plus(ii); % - vacc_age_state.Series_Complete_18Plus(ii);
        vacc_num_age(bb(ii), d_idx(ii), 4) = vacc_age_state.Series_Complete_18Plus(ii); % - vacc_age_state.Series_Complete_65Plus(ii);
        vacc_num_age(bb(ii), d_idx(ii), 5) = vacc_age_state.Series_Complete_65Plus(ii);       
        %Series complete total
        vacc_full(bb(ii), d_idx(ii)) = vacc_age_state.Series_Complete_Yes(ii);
        
        %Additional doses by age
        extra_dose_age(bb(ii), d_idx(ii), 2) = vacc_age_state.Additional_Doses(ii);
        extra_dose_age(bb(ii), d_idx(ii), 3) = vacc_age_state.Additional_Doses_18Plus(ii); 
        extra_dose_age(bb(ii), d_idx(ii), 4) = vacc_age_state.Additional_Doses_50Plus(ii); 
        extra_dose_age(bb(ii), d_idx(ii), 5) = vacc_age_state.Additional_Doses_65Plus(ii);       
        %Additional doses total
        extra_dose_full(bb(ii), d_idx(ii)) = vacc_age_state.Additional_Doses(ii);
        
        %Popu
        pop_by_age_all(bb(ii), d_idx(ii), 1) = vacc_age_state.Series_Complete_Yes(ii)./(vacc_age_state.Series_Complete_Pop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 2) = vacc_age_state.Series_Complete_Yes(ii)./(vacc_age_state.Series_Complete_Pop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 3) = vacc_age_state.Series_Complete_12Plus(ii)./(vacc_age_state.Series_Complete_12PlusPop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 4) = vacc_age_state.Series_Complete_18Plus(ii)./(vacc_age_state.Series_Complete_18PlusPop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 5) = vacc_age_state.Series_Complete_65Plus(ii)./(vacc_age_state.Series_Complete_65PlusPop_Pct(ii));

%         vacc_num_age(bb(ii), d_idx(ii), 1) = vacc_age_state.Administered_Dose1_Recip(ii) - vacc_age_state.Administered_Dose1_Recip_12Plus(ii);
%         vacc_num_age(bb(ii), d_idx(ii), 2) = vacc_age_state.Administered_Dose1_Recip_12Plus(ii) - vacc_age_state.Administered_Dose1_Recip_18Plus(ii);
%         vacc_num_age(bb(ii), d_idx(ii), 3) = vacc_age_state.Administered_Dose1_Recip_18Plus(ii) - vacc_age_state.Administered_Dose1_Recip_65Plus(ii);
%         vacc_num_age(bb(ii), d_idx(ii), 4) = vacc_age_state.Administered_Dose1_Recip_65Plus(ii);
    elseif us_idx(ii) > 0   % National level
        %Additional doses by age
        us_extra_dose_age(1, d_idx(ii), 2) = vacc_age_state.Additional_Doses(ii);
        us_extra_dose_age(1, d_idx(ii), 3) = vacc_age_state.Additional_Doses_18Plus(ii); 
        us_extra_dose_age(1, d_idx(ii), 4) = vacc_age_state.Additional_Doses_50Plus(ii); 
        us_extra_dose_age(1, d_idx(ii), 5) = vacc_age_state.Additional_Doses_65Plus(ii);       
        %Additional doses total
        us_extra_dose_full(1, d_idx(ii), 1) = vacc_age_state.Additional_Doses(ii);
    end

end
%%
vacc_full(vacc_full <= 0) = nan;
vacc_num_age(vacc_num_age <= 0) = nan;

extra_dose_full(extra_dose_full <= 0) = nan;
extra_dose_age(extra_dose_age <= 0) = nan;

popu_by_age_all(pop_by_age_all <= 0) = nan; %point of this?
vacc_num_age(:, :, 2) = vacc_num_age(:, :, 2) - vacc_num_age(:, :, 3); %Total - 12+ = <12
vacc_num_age(:, :, 3) = vacc_num_age(:, :, 3) - vacc_num_age(:, :, 4); %12+ - 18+ = 12->18
vacc_num_age(:, :, 4) = vacc_num_age(:, :, 4) - vacc_num_age(:, :, 5); %18+ - 65+ = 18-65

extra_dose_age(:, :, 2) = extra_dose_age(:, :, 2) - extra_dose_age(:, :, 3); %Total - 18+ = <18
extra_dose_age(:, :, 3) = extra_dose_age(:, :, 3) - extra_dose_age(:, :, 4); %18+ - 50+ = 10->50
extra_dose_age(:, :, 4) = extra_dose_age(:, :, 4) - extra_dose_age(:, :, 5); %50+ - 65+ = 50-65

pop_by_age_all(:, :, 2) = pop_by_age_all(:, :, 2) - pop_by_age_all(:, :, 3); %total - 12+ = <12
pop_by_age_all(:, :, 3) = pop_by_age_all(:, :, 3) - pop_by_age_all(:, :, 4); %12+ - 18+ = 12->18
pop_by_age_all(:, :, 4) = pop_by_age_all(:, :, 4) - pop_by_age_all(:, :, 5); %18+ - 65+ = 18-65

%% Fix the population value for NaNs and youngest age group
pop_by_age = squeeze(100*nanmean(pop_by_age_all, 2)); %??
popu = pop_by_age(:, 1); %Total age group

popu_age = readtable('population_by_age_by_state.csv');
popu_by_age = popu_age{:, 2:end};
% Convert to age_group [0-5, 5-12, 12-18, 18-65, 65+]
popu_by_age_ref = zeros(size(pop_by_age, 1), 5);
popu_by_age_ref(:, 1) = popu_by_age(:, 1);
popu_by_age_ref(:, 2) = (7/10)*popu_by_age(:, 2);
popu_by_age_ref(:, 3) = (3/10)*popu_by_age(:, 2) + (4/10)*popu_by_age(:, 3);
popu_by_age_ref(:, 4) = (6/10)*popu_by_age(:, 3) + sum(popu_by_age(:, 5:8), 2);
popu_by_age_ref(:, 5) = sum(popu_by_age(:, 9:end), 2);

popu_ratio = nansum(popu_by_age_ref, 1)./sum(nansum(popu_by_age_ref, 1));
idx = any(isnan(popu_by_age_ref), 2);
popu_by_age_ref(idx, :) = popu(idx)*popu_ratio;

bad_idx = isnan(pop_by_age) | isinf(pop_by_age);
pop_by_age(bad_idx) = popu_by_age_ref(bad_idx);
pop_by_age(:, 1) = popu_by_age_ref(:, 1);
pop_by_age(:, 2) = pop_by_age(:, 2) - pop_by_age(:, 1);


%%
vacc_num_age = fillmissing(vacc_num_age, 'previous', 2);
vacc_num_age = fillmissing(vacc_num_age, 'next', 2);

%% Fill missing data based on govex data
xx = load('vacc_data.mat', 'u_vacc_full');
gvacc_full = xx.u_vacc_full;
gvacc_full(isnan(gvacc_full)) = 0;
for cid = 1:size(vacc_full, 1)
    nidx = find(isnan(vacc_full(cid, :))); nidx(nidx > 500) = [];
    s = vacc_full(cid, nidx(end)+1)./gvacc_full(cid, nidx(end)+1);
    vacc_full(cid, nidx) = s*gvacc_full(cid, nidx);
end

%% Fill missing booster data based on US national data
for cid = 1:size(vacc_full, 1)
    for aa = 2:size(extra_dose_age, 3)
        nidx = find(isnan(extra_dose_age(cid, :, aa))); nidx(nidx < 500) = [];
        s = extra_dose_age(cid, nidx(end)+1, aa)./us_extra_dose_full(1, nidx(end)+1, 1);
        extra_dose_age(cid, nidx, aa) = s*us_extra_dose_full(1, nidx, 1);
    end
    nidx = find(isnan(extra_dose_full(cid, :))); nidx(nidx < 500) = [];
    s = extra_dose_full(cid, nidx(end)+1)./us_extra_dose_full(1, nidx(end)+1, 1);
    extra_dose_full(cid, nidx) = s*us_extra_dose_full(1, nidx, 1);
end

%% Make sure lengths are compatable & no Nans
try 
    T = size(data_4, 2);
catch
    T = min(size(vacc_full, 2), size(vacc_num_age, 2)); %This will have same dimension as extra_dose
end
vacc_full = vacc_full(:, 1:T);
vacc_num_age = vacc_num_age(:, 1:T, :);
vacc_num_age(isnan(vacc_num_age)) = 0;
vacc_num_age_est = vacc_full .* vacc_num_age./(1e-10 + sum(vacc_num_age, 3));
vacc_num_age_est(isnan(vacc_num_age_est)) = 0;

extra_dose_full = extra_dose_full(:, 1:T);
extra_dose_age = extra_dose_age(:, 1:T, :);
extra_dose_age(isnan(extra_dose_age)) = 0;
extra_dose_age_est = extra_dose_full .* extra_dose_age./(1e-10 + sum(extra_dose_age, 3));
extra_dose_age_est(isnan(extra_dose_age_est)) = 0;
extra_dose_age_est(:,:,4) = extra_dose_age_est(:,:,3) + extra_dose_age_est(:,:,4); %18-64
%Assuming here the extar doses for <18 are distributed by population ratio
extra_dose_age_est(:,:,3) = extra_dose_age_est(:,:,2) * popu_ratio(3)/sum(popu_ratio(1:3)); %12-18
extra_dose_age_est(:,:,1) = extra_dose_age_est(:,:,2) * popu_ratio(1)/sum(popu_ratio(1:3)); %0-5
extra_dose_age_est(:,:,2) = extra_dose_age_est(:,:,2) * popu_ratio(2)/sum(popu_ratio(1:3)); %5-12
%% outcomes by age (Processing my data, compatible lengths also)
load age_outcomes.mat
tt = size(c_3d, 2);
c_3d1 = nan(length(abvs), T, 6); d_3d1 = nan(length(abvs), T, 6); h_3d1 = nan(length(abvs), T, 6);
c_3d1(:, 1:tt, :) = c_3d;
d_3d1(:, 1:tt, :) = d_3d;
h_3d1(:, 1:tt, :) = h_3d;

c_3d1(:, 1:tt, 4) = c_3d(:, :, 4) + c_3d(:, :, 5); c_3d1(:, :, 5) = []; 
c_3d1 = fillmissing(c_3d1, "previous", 2); c_3d1 = movmean(c_3d1, 60, 2);
d_3d1(:, 1:tt, 4) = d_3d(:, :, 4) + d_3d(:, :, 5); d_3d1(:, :, 5) = [];
d_3d1 = fillmissing(d_3d1, "previous", 2); d_3d1 = movmean(d_3d1, 60, 2);
h_3d1(:, 1:tt, 4) = h_3d(:, :, 4) + h_3d(:, :, 5); h_3d1(:, :, 5) = [];
h_3d1 = fillmissing(h_3d1, "previous", 2); h_3d1 = movmean(h_3d1, 60, 2);

age_groups{4} = [age_groups{4} ', ' age_groups{5}]; age_groups(5) = [];
