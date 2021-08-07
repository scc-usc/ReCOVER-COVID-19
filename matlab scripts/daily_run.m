clear; warning off;
addpath('./hyper_params');

%% US Variant data
try
    all_variants_data;
catch thisErr
    fprintf('Error in Preparing US Variants Data\n');
    fprintf('%s\n', thisErr.message);
end
%% For US forecasts
try
    all_variants_us_forecasts;
catch thisErr
    fprintf('Error in US states forecasts\n');
    fprintf('%s\n', thisErr.message);
end

%% Global Variant data
try
    all_variants_data_global;
catch thisErr
    fprintf('Error in Preparing Global Variants Data\n');
    fprintf('%s\n', thisErr.message);
end

%% For Global forecasts
clear;
try 
    global_vacc_pred;
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
catch thisErr
    fprintf('Error in creating vaccine data\n');
    fprintf('%s\n', thisErr.message);
end

%% Genrate submission file for EU hub
clear;
try
     
    if weekday(now)==1
        quant_gen_eu;
    end
catch thisErr
    fprintf('Error in creating EU submission\n');
    fprintf('%s\n', thisErr.message);
end