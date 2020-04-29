%% Script to identify optimal hyperparameters of the model
%% Configure

T_full = size(data_4(:,:), 2); % How many days to train for. Should usually pick total number of days
horizon = 2;
T_val = 7;
T_tr = T_full - T_val - horizon; % Jan 21 is day 0

k_array = (1:14);
jp_array = (1:14);
ff_array = (0.1:0.1:1);
%% Full
inf_thres = -1;
cidx = (data_4(:, end) > inf_thres);


data_4_s = data_4(cidx, 1:T_full);

RMSEval = zeros(length(k_array), length(jp_array), length(ff_array), length(popu));
MAPEval = zeros(length(k_array), length(jp_array), length(ff_array), length(popu));
RMSLEval = zeros(length(k_array), length(jp_array), length(ff_array), length(popu));
MAEval = zeros(length(k_array), length(jp_array), length(ff_array), length(popu));

for k=1:length(k_array)
    for jp=1:ceil(length(jp_array)/k)
        for alpha_i = 1:length(ff_array)
            
            alpha = ff_array(alpha_i);
            F_notravel = passengerFlow(cidx, cidx)*0;
            F_travel = passengerFlow(cidx, cidx);
            data_4_s = movmean(data_4, 3, 2);

                      
%             [yt, Xt] = data_prep(data_4_s, F, popu(cidx), k, jp);
%             [beta_unadjusted] = ind_beta(Xt, yt, alpha, k, T_tr+T_ad, popu(cidx), jp);
%             
%             infec_unad = simulate_pred(data_4_s(:, 1:T_trad), F_travel, beta_unadjusted, popu(cidx), k, horizon, jp);
%            beta_withtravel = var_ind_beta(data_4_s(:, 1:T_tr), F_travel, ones(sum(cidx), 1)*alpha, ones(sum(cidx), 1)*k, T_tr, popu(cidx), ones(sum(cidx), 1)*jp);
            beta_notravel = var_ind_beta(data_4_s(:, 1:T_tr), F_notravel, ones(sum(cidx), 1)*alpha, ones(sum(cidx), 1)*k, T_tr, popu(cidx), ones(sum(cidx), 1)*jp);
                        
%            infec_travel = var_simulate_pred(data_4_s(:, 1:T_tr), F_travel, beta_withtravel, popu(cidx), ones(sum(cidx), 1)*k, T_val, ones(sum(cidx), 1)*jp);
            infec_notravel = var_simulate_pred(data_4_s(:, 1:T_tr), F_notravel, beta_notravel, popu(cidx), ones(sum(cidx), 1)*k, T_val, ones(sum(cidx), 1)*jp);

            RMSEvec = sqrt(mean((infec_notravel - data_4_s(:, T_tr+1 : T_tr + T_val)).^2, 2));
            RMSEval(k, jp, alpha_i, :) = (RMSEvec);
            MAPEvec = mean(abs(infec_notravel - data_4_s(:, T_tr+1 : T_tr + T_val))./data_4_s(:, T_tr+1 : T_tr + T_val), 2);
            MAPEval(k, jp, alpha_i, :) = (MAPEvec);
        end
    end
    fprintf('.');
end
fprintf('\n');


%% Identify best param per country
best_param_list = zeros(length(popu), 5);
alpha_start = 1;
for cid = 1:length(popu)
    thistable = [];
    for k=1:length(k_array)
        for jp=1:ceil(length(jp_array)/k)
            for alpha_i = alpha_start:length(ff_array)
                %thistable = [thistable; [k jp alpha_i MAPEval(k, jp, alpha_i, cid) RMSEval(k, jp, alpha_i, cid) RMSLEval(k, jp, alpha_i, cid) MAEval(k, jp, alpha_i, cid)]];
                thistable = [thistable; [k jp alpha_i MAPEval(k, jp, alpha_i, cid) RMSEval(k, jp, alpha_i, cid)]];
            end
        end
    end
    thistable = sortrows(thistable, 5);
    best_param_list(cid, :) = thistable(1, :);
end

%% Identify single best params
MAPEtable = [];
cidx = data_4_s(:, T_tr)>1;
for k=1:length(k_array)
    for jp=1:ceil(length(jp_array)/k)
        for alpha_i = alpha_start:length(ff_array)
            MAPEtable = [MAPEtable; [k jp alpha_i nanmean(MAPEval(k, jp, alpha_i, cidx)) nanmean(RMSEval(k, jp, alpha_i, cidx))]];
        end
    end
end
MAPEtable_s = sortrows(MAPEtable, 5);

%% Show results
disp('Validation');
disp([mean(best_param_list(cidx, 5)) nanmean(best_param_list(cidx, 4))]);
disp([num2str([MAPEtable_s(1, 5) MAPEtable_s(1, 4)]) ' at ' num2str(MAPEtable_s(1, 1:3))])

%% Run evaluation on test set 
T_trad = T_tr+T_val;


beta_notravel = var_ind_beta(data_4(:, 1:T_trad), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), T_tr, popu, best_param_list(:, 2));

data_4_s = data_4(:, 1:T_trad+horizon);

infec_notravel = var_simulate_pred(data_4(:, 1:T_trad), passengerFlow*0, beta_notravel, popu, best_param_list(:, 1), horizon, best_param_list(:, 2));

inf_thres = 0;
inf_uthres = 10000000000000000;
cidx = (data_4(:, T_trad) > inf_thres & data_4_s(:, T_trad) < inf_uthres);

%%
%cidx = [1];

RMSEvec = sqrt(mean((infec_notravel - data_4_s(:, end-horizon+1:end)).^2, 2));
RMSEtest = mean(RMSEvec(cidx));
MAPEvec = mean(abs(infec_notravel - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
MAPEtest = mean(MAPEvec(cidx));

disp('Test');
disp([num2str(RMSEtest) ' ' num2str(MAPEtest)]);

alpha_l = MAPEtable_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_s(1, 2)*ones(length(popu), 1);

beta_notravel = var_ind_beta(data_4(:, 1:T_trad), passengerFlow*0, alpha_l, k_l, T_tr, popu, jp_l);

infec_notravel_f = var_simulate_pred(data_4(:, 1:T_trad), passengerFlow*0, beta_notravel, popu, k_l, horizon, jp_l);

RMSEvec = sqrt(mean((infec_notravel_f - data_4_s(:, end-horizon+1:end)).^2, 2));
RMSEtest = mean(RMSEvec(cidx));
MAPEvec = mean(abs(infec_notravel_f - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
MAPEtest = mean(MAPEvec(cidx));

disp([num2str(RMSEtest) ' ' num2str(MAPEtest)]);

infec_avg = 0.5*(infec_notravel + infec_notravel_f);
RMSEvec = sqrt(mean((infec_avg - data_4_s(:, end-horizon+1:end)).^2, 2));
RMSEtest = mean(RMSEvec(cidx));
MAPEvec = mean(abs(infec_avg - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
MAPEtest = mean(MAPEvec(cidx));

disp([num2str(RMSEtest) ' ' num2str(MAPEtest)]);