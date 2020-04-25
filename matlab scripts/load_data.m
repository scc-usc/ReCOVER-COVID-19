%% Global Data
data_4 = load('global_data_4_23.txt');
countries = readcell('countries_list.txt');
passengerFlow = load('global_travel_data.txt');
popu = load('global_population_data.txt');
if size(data_4, 1)> length(popu)
    data_4 = data_4(1:length(popu), :);
end
data_pre_smooth = data_4;
data_4 = movmean(data_pre_smooth, 5, 2);
%% US Data
%load us.mat;
data_4 = load('us_states_data_4_23.txt');
countries = readcell('us_states_list.txt');
passengerFlow = load('us_states_travel_data.txt');
popu = load('us_states_population_data.txt');
if size(data_4, 1)> length(popu)
    data_4 = data_4(1:length(popu), :);
end
data_pre_smooth = data_4;
data_4 = movmean(data_pre_smooth, 5, 2);

