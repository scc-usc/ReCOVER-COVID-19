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
T = days(today('datetime')-datetime(2020, 1, 23));
vacc_num_age = nan(length(abvs), T, 5); % 4 age groups in data + 1 for 0-5
vacc_full = nan(length(abvs), T);

first_dose_age = nan(length(abvs), T, 5); % 4 age groups in data + 1 for 0-5
first_dose_full = nan(length(abvs), T);

extra_dose_age = nan(length(abvs), T, 5);
extra_dose_full = nan(length(abvs), T);

extra_dose_age2 = nan(length(abvs), T, 5);
extra_dose_full2 = nan(length(abvs), T);

us_idx = strcmpi(vacc_age_state.Location, "US");
us_extra_dose_age = nan(1, T, 5);
us_extra_dose_full = nan(1, T, 1);

us_extra_dose_age2 = nan(1, T, 5);
us_extra_dose_full2 = nan(1, T, 1);

pop_by_age_all = nan(length(abvs), T, 5);
for ii = 1:size(vacc_age_state, 1)
    if bb(ii)> 0
        %Series Complete by age
        vacc_num_age(bb(ii), d_idx(ii), 2) = vacc_age_state.Series_Complete_Yes(ii); % - vacc_age_state.Series_Complete_12Plus(ii);
        vacc_num_age(bb(ii), d_idx(ii), 3) = vacc_age_state.Series_Complete_12Plus(ii); % - vacc_age_state.Series_Complete_18Plus(ii);
        vacc_num_age(bb(ii), d_idx(ii), 4) = vacc_age_state.Series_Complete_18Plus(ii); % - vacc_age_state.Series_Complete_65Plus(ii);
        vacc_num_age(bb(ii), d_idx(ii), 5) = vacc_age_state.Series_Complete_65Plus(ii);       
        %Series complete total
        vacc_full(bb(ii), d_idx(ii)) = vacc_age_state.Series_Complete_Yes(ii);

        %Series Complete by age
        first_dose_age(bb(ii), d_idx(ii), 2) = vacc_age_state.Administered_Dose1_Recip(ii); % - vacc_age_state.Series_Complete_12Plus(ii);
        first_dose_age(bb(ii), d_idx(ii), 3) = vacc_age_state.Administered_Dose1_Recip_12Plus(ii); % - vacc_age_state.Series_Complete_18Plus(ii);
        first_dose_age(bb(ii), d_idx(ii), 4) = vacc_age_state.Administered_Dose1_Recip_18Plus(ii); % - vacc_age_state.Series_Complete_65Plus(ii);
        first_dose_age(bb(ii), d_idx(ii), 5) = vacc_age_state.Administered_Dose1_Recip_65Plus(ii);       
        %Series complete total
        first_dose_full(bb(ii), d_idx(ii)) = vacc_age_state.Administered_Dose1_Recip(ii);
        
        %Additional doses by age
        extra_dose_age(bb(ii), d_idx(ii), 2) = vacc_age_state.Additional_Doses(ii);
        extra_dose_age(bb(ii), d_idx(ii), 3) = vacc_age_state.Additional_Doses_18Plus(ii); 
        extra_dose_age(bb(ii), d_idx(ii), 4) = vacc_age_state.Additional_Doses_50Plus(ii); 
        extra_dose_age(bb(ii), d_idx(ii), 5) = vacc_age_state.Additional_Doses_65Plus(ii);       
        %Additional doses total
        extra_dose_full(bb(ii), d_idx(ii)) = vacc_age_state.Additional_Doses(ii);

        %Additional doses by age
        extra_dose_age2(bb(ii), d_idx(ii), 4) = vacc_age_state.Second_Booster_50Plus(ii);
        extra_dose_age2(bb(ii), d_idx(ii), 5) = vacc_age_state.Second_Booster_65Plus(ii);    
        %Additional doses total
        extra_dose_full2(bb(ii), d_idx(ii)) = vacc_age_state.Second_Booster(ii);
        
        %Popu
        pop_by_age_all(bb(ii), d_idx(ii), 1) = vacc_age_state.Series_Complete_Yes(ii)./(vacc_age_state.Series_Complete_Pop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 2) = vacc_age_state.Series_Complete_Yes(ii)./(vacc_age_state.Series_Complete_Pop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 3) = vacc_age_state.Series_Complete_12Plus(ii)./(vacc_age_state.Series_Complete_12PlusPop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 4) = vacc_age_state.Series_Complete_18Plus(ii)./(vacc_age_state.Series_Complete_18PlusPop_Pct(ii));
        pop_by_age_all(bb(ii), d_idx(ii), 5) = vacc_age_state.Series_Complete_65Plus(ii)./(vacc_age_state.Series_Complete_65PlusPop_Pct(ii));


    elseif us_idx(ii) > 0   % National level
        %Additional doses by age
        us_extra_dose_age(1, d_idx(ii), 2) = vacc_age_state.Additional_Doses(ii);
        us_extra_dose_age(1, d_idx(ii), 3) = vacc_age_state.Additional_Doses_18Plus(ii); 
        us_extra_dose_age(1, d_idx(ii), 4) = vacc_age_state.Additional_Doses_50Plus(ii); 
        us_extra_dose_age(1, d_idx(ii), 5) = vacc_age_state.Additional_Doses_65Plus(ii);   

        us_extra_dose_age2(1, d_idx(ii), 4) = vacc_age_state.Second_Booster_50Plus(ii);
        us_extra_dose_age2(1, d_idx(ii), 5) = vacc_age_state.Second_Booster_65Plus(ii);
        %Additional doses total
        us_extra_dose_full(1, d_idx(ii), 1) = vacc_age_state.Additional_Doses(ii);

        us_extra_dose_full2(1, d_idx(ii), 1) = vacc_age_state.Second_Booster(ii);
    end

end
%%
vacc_full(vacc_full <= 0) = nan;
vacc_num_age(vacc_num_age <= 0) = nan;

extra_dose_full(extra_dose_full <= 0) = nan;
extra_dose_age(extra_dose_age <= 0) = nan;

extra_dose_full2(extra_dose_full <= 0) = nan;
extra_dose_age2(extra_dose_age <= 0) = nan;

first_dose_age(first_dose_age <= 0) = nan;
%%
popu_by_age_all(pop_by_age_all <= 0) = nan; %point of this?

extra_dose_age(:, :, 2) = extra_dose_age(:, :, 2) - extra_dose_age(:, :, 3); %Total - 18+ = <18
extra_dose_age(:, :, 3) = extra_dose_age(:, :, 3) - extra_dose_age(:, :, 4); %18+ - 50+ = 10->50
extra_dose_age(:, :, 4) = extra_dose_age(:, :, 4) - extra_dose_age(:, :, 5); %50+ - 65+ = 50-65

extra_dose_age2(:, :, 2) = extra_dose_age2(:, :, 2) - extra_dose_age2(:, :, 3); %Total - 18+ = <18
extra_dose_age2(:, :, 3) = extra_dose_age2(:, :, 3) - extra_dose_age2(:, :, 4); %18+ - 50+ = 10->50
extra_dose_age2(:, :, 4) = extra_dose_age2(:, :, 4) - extra_dose_age2(:, :, 5); %50+ - 65+ = 50-65

vacc_num_age(:, :, 2) = vacc_num_age(:, :, 2) - vacc_num_age(:, :, 3); %Total - 12+ = <12
vacc_num_age(:, :, 3) = vacc_num_age(:, :, 3) - vacc_num_age(:, :, 4); %12+ - 18+ = 12->18
vacc_num_age(:, :, 4) = vacc_num_age(:, :, 4) - vacc_num_age(:, :, 5); %18+ - 65+ = 18-65

first_dose_age(:, :, 2) = first_dose_age(:, :, 2) - first_dose_age(:, :, 3); %Total - 18+ = <18
first_dose_age(:, :, 3) = first_dose_age(:, :, 3) - first_dose_age(:, :, 4); %18+ - 50+ = 10->50
first_dose_age(:, :, 4) = first_dose_age(:, :, 4) - first_dose_age(:, :, 5); %50+ - 65+ = 50-65

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

%% Fill missing data based on OWID dataset
xx = load('vacc_data.mat', 'u_vacc_full', 'u_vacc');
gvacc_full = xx.u_vacc_full;
gvacc_first = xx.u_vacc - xx.u_vacc_full;
first_day_vax = days(datetime(2020, 12, 14) - datetime(2020, 1, 23));
gvacc_first(:, first_day_vax) = 1; gvacc_full(:, first_day_vax+21) = 1;
gvacc_first(:, 1:first_day_vax-1) = 0; gvacc_full(:, 1:first_day_vax+20) = 0;
gvacc_full = fillmissing(gvacc_full, 'linear', 2);
gvacc_first = fillmissing(gvacc_first, 'linear', 2);

gvacc_full(isnan(gvacc_full)) = 0;
gvacc_first(isnan(gvacc_first)) = 0;

first_dose_full = gvacc_first;
vacc_full = gvacc_full;
%% Fill missing booster data based on US national data
for cid = 1:size(vacc_full, 1)
    for aa = 2:size(extra_dose_age, 3)
        nidx = find(isnan(extra_dose_age(cid, :, aa))); nidx(nidx < 500) = [];
        s = extra_dose_age(cid, nidx(end), aa)./us_extra_dose_full(1, nidx(end), 1);
        extra_dose_age(cid, nidx, aa) = s*us_extra_dose_full(1, nidx, 1);
    end
    nidx = find(isnan(extra_dose_full(cid, :))); nidx(nidx < 500) = [];
    s = extra_dose_full(cid, nidx(end))./us_extra_dose_full(1, nidx(end), 1);
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
vacc_num_age_est = fillmissing(vacc_num_age_est, 'previous', 2);
vacc_num_age_est(isnan(vacc_num_age_est)) = 0;

first_dose_full = first_dose_full(:, 1:T);
first_dose_age = first_dose_age(:, 1:T, :);
first_dose_age(isnan(first_dose_age)) = 0;
first_dose_age_est = first_dose_full .* first_dose_age./(1e-10 + sum(first_dose_age, 3));
first_dose_age_est = fillmissing(first_dose_age_est, 'previous', 2);
first_dose_age_est(isnan(first_dose_age_est)) = 0;

extra_dose_full = fillmissing(extra_dose_full(:, 1:T), 'previous', 2);
extra_dose_age = extra_dose_age(:, 1:T, :);
extra_dose_age = fillmissing(extra_dose_age, 'previous', 2);
extra_dose_age(isnan(extra_dose_age)) = 0;
extra_dose_age_est = extra_dose_full .* extra_dose_age./(1e-10 + sum(extra_dose_age, 3));

%extra_dose_full2 = fillmissing(extra_dose_full2(:, 1:T), 'previous', 2);
extra_dose_age2 = extra_dose_age2(:, 1:T, :);
extra_dose_age2 = fillmissing(extra_dose_age2, 'previous', 2);
extra_dose_age2(isnan(extra_dose_age2)) = 0;
%extra_dose_age_est2 = extra_dose_full2 .* extra_dose_age2./(1e-10 + sum(extra_dose_age2, 3));
extra_dose_age_est2 = extra_dose_age2;
%%
extra_dose_age_est(isnan(extra_dose_age_est)) = 0;
extra_dose_age_est(:,:,4) = extra_dose_age_est(:,:,3) + extra_dose_age_est(:,:,4); %18-64
%Assuming here the extar doses for <18 are distributed by population ratio
extra_dose_age_est(:,:,3) = extra_dose_age_est(:,:,2) * popu_ratio(3)/sum(popu_ratio(1:3)); %12-18
extra_dose_age_est(:,:,1) = extra_dose_age_est(:,:,2) * popu_ratio(1)/sum(popu_ratio(1:3)); %0-5
extra_dose_age_est(:,:,2) = extra_dose_age_est(:,:,2) * popu_ratio(2)/sum(popu_ratio(1:3)); %5-12

extra_dose_age_est2(isnan(extra_dose_age_est2)) = 0;
extra_dose_age_est2(:,:,4) = extra_dose_age_est2(:,:,3) + extra_dose_age_est2(:,:,4); %18-64
%Assuming here the extar doses for <18 are distributed by population ratio
extra_dose_age_est2(:,:,3) = extra_dose_age_est2(:,:,2) * popu_ratio(3)/sum(popu_ratio(1:3)); %12-18
extra_dose_age_est2(:,:,1) = extra_dose_age_est2(:,:,2) * popu_ratio(1)/sum(popu_ratio(1:3)); %0-5
extra_dose_age_est2(:,:,2) = extra_dose_age_est2(:,:,2) * popu_ratio(2)/sum(popu_ratio(1:3)); %5-12

%% Adjust bad first dose data that are lower than 2-doses
for cid = 1:size(first_dose_age_est, 1)
    for gg = 1:size(first_dose_age_est, 3)
        idx = find(squeeze(vacc_num_age_est(cid, 21:end, gg)) > squeeze(first_dose_age_est(cid, 1:end-20, gg)));
        if ~isempty(idx)
            first_dose_age_est(cid, idx, gg) = vacc_num_age_est(cid, idx+20, gg);
        end
    end
end

%% Smooth all vaccines while preserving cumulutaive
for gg = 1:5
    l = first_dose_age_est(:, end, gg);
    first_dose_age_est(:, :, gg) = smooth_epidata(first_dose_age_est(:, :, gg), 1, 0);
    first_dose_age_est(:, :, gg) = first_dose_age_est(:, :, gg).*l./(1e-10 + first_dose_age_est(:, end, gg));
    
    l = vacc_num_age_est(:, end, gg);
    vacc_num_age_est(:, :, gg) = smooth_epidata(vacc_num_age_est(:, :, gg), 7, 1, 0);
    vacc_num_age_est(:, :, gg) =vacc_num_age_est(:, :, gg).*l./(1e-10 + vacc_num_age_est(:, end, gg));
    
    l = extra_dose_age_est(:, end, gg);
    extra_dose_age_est(:, :, gg) = smooth_epidata(extra_dose_age_est(:, :, gg), 7, 1, 0);
    extra_dose_age_est(:, :, gg) =extra_dose_age_est(:, :, gg).*l./(1e-10 + extra_dose_age_est(:, end, gg));

    l = extra_dose_age_est2(:, end, gg);
    extra_dose_age_est2(:, :, gg) = smooth_epidata(extra_dose_age_est2(:, :, gg), 7, 1, 0);
    extra_dose_age_est2(:, :, gg) =extra_dose_age_est2(:, :, gg).*l./(1e-10 + extra_dose_age_est2(:, end, gg));
end


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
