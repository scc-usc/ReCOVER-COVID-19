clear; warning off;
addpath('./hyper_params');

%% For US
load_data_us;
data_4_s = data_4;
deaths_s = deaths;
for j=1:size(data_4, 1)
    data_4_s(j, :) = [data_4(j, 1) cumsum(smooth(diff(data_4(j, :))', 7)')];
    deaths_s(j, :)= [deaths(j, 1) cumsum(smooth(diff(deaths(j, :))', 7)')];
end
load us_hyperparam_ref_64.mat
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dk = 3; djp = 7; dalpha = 1; dwin = 50; % Choose a lower number if death rates evolve
write_unreported;
save us_hyperparam_latest.mat best_param_list MAPEtable_s;

disp('Finished updating US forecasts');
%% For Global
clear;
load_data_global;
data_4_s = data_4;
deaths_s = deaths;
for j=1:size(data_4, 1)
    data_4_s(j, :) = [data_4(j, 1) cumsum(smooth(diff(data_4(j, :))', 7)')];
    deaths_s(j, :)= [deaths(j, 1) cumsum(smooth(diff(deaths(j, :))', 7)')];
end
load global_hyperparam_ref_64.mat
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dk = 3; djp = 7; dalpha = 1; dwin = 50; % Choose a lower number if death rates evolve
write_unreported;
save global_hyperparam_latest.mat best_param_list MAPEtable_s;

disp('Finished updating Global forecasts');