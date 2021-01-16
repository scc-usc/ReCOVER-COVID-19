clear; warning off;
addpath('./hyper_params');

%% For US
try
    
    load_data_us;
    lowidx = popu < 1;
    smooth_factor = 14;
    data_4_s = smooth_epidata(data_4, smooth_factor);
    deaths_s = smooth_epidata(deaths, smooth_factor);
    
    xx = load(['../results/unreported/' prefix '_all_unreported.csv']);
    un_from_file = xx(2:end, end);
    %[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un_from_file, size(data_4, 2));
    [best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un_from_file, size(data_4, 2), 0, [3], [7], [10], 50);
    
    dhyperparams;
    write_unreported;
    save us_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;
    add_to_history;
    disp('Finished updating US forecasts');
    
catch thisErr
    fprintf('Error in US states forecasts\n');
    fprintf('%s\n', thisErr.message);
end

%% For Global
clear;
try
    load_data_global;
    smooth_factor = 14;
    data_4_s = smooth_epidata(data_4, smooth_factor);
    deaths_s = smooth_epidata(deaths, smooth_factor);
    
    xx = load(['../results/unreported/' prefix '_all_unreported.csv']);
    un_from_file = xx(2:end, end);
    %[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un_from_file, size(data_4, 2));
    [best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un_from_file, size(data_4, 2), 0, [3], [7], [10], 50);
    
    dhyperparams;
    write_unreported;
    save global_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;
    add_to_history;
    disp('Finished updating Global forecasts');
catch thisErr
    fprintf('Error in global forecasts\n');
    fprintf('%s\n', thisErr.message);
end
%% For US counties
clear;
try
    write_county_files;
catch thisErr
    fprintf('Error in county forecasts\n');
    fprintf('%s\n', thisErr.message);
end

%% For "Others": Specifically for Germany, Poland states

clear;
try
    load_data_other;
    do_other_forecasts;
    add_to_history;
    disp('Writing quantile files for KIT hub');
    KIT_submit;
    disp('Finished other forecasts');
catch thisErr
    fprintf('Error in GM/PL forecasts\n');
    fprintf('%s\n', thisErr.message);
end

%% For every location available in Google Data
clear;
try
    all_google_forecasts;
catch thisErr
    fprintf('Error in all location forecasts\n');
    fprintf('%s\n', thisErr.message);
end

%% Add global forecasts lower and upper bounds
clear;
try
    quant_gen_sampled;
catch thisErr
    fprintf('Error in generating quantiles for global forecasts\n');
    fprintf('%s\n', thisErr.message);
end

%% Update vaccination data
clear;
try
    get_vacc_data;
catch thiErr
    fprintf('Error in creating vaccine data\n');
    fprintf('%s\n', thisErr.message);
end

