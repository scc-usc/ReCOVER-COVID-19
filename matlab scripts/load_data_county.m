%% Load FIPS and UID mappings
FIP_data = readtable('UID_ISO_FIPS_LookUp_Table.csv');
count_ids = ~isnan(FIP_data.FIPS);
FIP_data = FIP_data(count_ids, :);
fips_map = containers.Map(FIP_data.FIPS, (1:sum(count_ids)));
countries = FIP_data.Combined_Key;
popu = FIP_data.Population;
popu(isnan(popu)) = 0.5; % pseudo assugnment to continue to the computations without nan errors 
passengerFlow = sparse(length(countries), length(countries));
passengerFlow = passengerFlow - diag(diag(passengerFlow));

%% Load confirmed and deaths
[tableConfirmed, tableDeaths] = getDataCOVID_US();


%% Load confirmed cases
vals = table2array(tableConfirmed(:, 13:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end

data_4 = zeros(length(countries), size(vals, 2));
nf = 0; nf_idx =  zeros(size(tableConfirmed, 1), 1);
for idx = 1:size(tableConfirmed, 1)
    thisfips = str2num(tableConfirmed.FIPS(idx));
    if fips_map.isKey(thisfips)
        data_4(fips_map(thisfips), :) = vals(idx, :);
    else
        nf = nf + 1;
        nf_idx(idx) = 1;
    end
end

%% Load deaths
vals = table2array(tableDeaths(:, 14:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end

deaths = zeros(length(countries), size(vals, 2));
nf = 0; nf_idx =  zeros(size(tableConfirmed, 1), 1);
for idx = 1:size(tableDeaths, 1)
    thisfips = str2num(tableDeaths.FIPS(idx));
    if fips_map.isKey(thisfips)
        deaths(fips_map(thisfips), :) = vals(idx, :);
    else
        nf = nf + 1;
        nf_idx(idx) = 1;
    end
end
%% Create county-to-state mapping
state_list = readcell('us_states_list.txt');
state_map = containers.Map(state_list, (1:length(state_list)));
county_to_state = zeros(length(countries), 1);

for idx = 1:size(FIP_data, 1)
    thisfips = FIP_data.FIPS(idx);
    if fips_map.isKey(thisfips)
        if state_map.isKey(FIP_data.Province_State{idx})
            county_to_state(fips_map(thisfips)) = state_map(FIP_data.Province_State{idx});
        end
    end
end    

county_to_state(county_to_state==0) = 1; % Default assignment (Diamond and Grand Princess), only for bug-free execution
%% Create county hyper-parameters

first_day = 52; last_day = 170; skipdays = 7;

for dd = first_day:skipdays:last_day
    eval(['load ./hyper_params/us_hyperparam_ref_' num2str(dd)]);
    param_state = best_param_list_no;
    best_param_list_no = zeros(length(countries), size(param_state, 2));
    
    for idx = 1:length(countries)
        best_param_list_no(idx, :) = param_state(county_to_state(idx), :);
    end
    eval(['save ./hyper_params/county_hyperparam_ref_' num2str(dd) ' best_param_list_no MAPEtable_notravel_fixed_s']);
end


