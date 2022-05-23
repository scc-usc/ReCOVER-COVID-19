clear; warning off;
addpath('./hyper_params');
addpath('./utils/');

%% Update vaccination data
clear;
try
    get_vacc_data;
catch thisErr
    fprintf('Error in creating vaccine data\n');
    fprintf('%s\n', thisErr.message);
end
%% All Variant data
try
    %all_variants_data;
    %all_variants_data_cov;
    gisaid_load_inc;
catch thisErr
    fprintf('Error in Preparing Variants Data\n');
    fprintf('%s\n', thisErr.message);
end
%% For US forecasts
try
    all_variants_us_forecasts;
catch thisErr
    fprintf('Error in US states forecasts\n');
    fprintf('%s\n', thisErr.message);
end

% %% Global Variant data
% try
%     all_variants_data_global_cov;
% catch thisErr
%     fprintf('Error in Preparing Global Variants Data\n');
%     fprintf('%s\n', thisErr.message);
% end

%% For Global forecasts
clear;
try 
    multivar_global_vacc_pred;
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

clear; addpath('./utils/');
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

%% Generate submission file for US forecast hub

clear;
try
     
    if weekday(now)==1
        quant_gen_base;
        hospitalization_us;
    end
catch thisErr
    fprintf('Error in creating US FH submission\n');
    fprintf('%s\n', thisErr.message);
end