%% At reference point (with/without travel)
T_tr = 57; % Choose reference day here
T_ad = 0; % Ignore this
T_trad = T_tr + T_ad;
inf_thres = -1;
cidx = (data_4(:, T_trad) > inf_thres);
k_array = (1:14);
jp_array = (1:14);
ff_array = (0.1:0.1:1);

horizon = 3;
data_4_s = data_4(cidx, 1:T_trad+horizon);
%%
RMSEval_no = zeros(length(k_array), length(jp_array), length(ff_array), sum(cidx));
RMSEval_yes = zeros(length(k_array), length(jp_array), length(ff_array), sum(cidx));
MAPEval_no = zeros(length(k_array), length(jp_array), length(ff_array), sum(cidx));
MAPEval_yes = zeros(length(k_array), length(jp_array), length(ff_array), sum(cidx));

for k=1:length(k_array)
    for jp=1:ceil(length(jp_array)/k)
        for alpha_i = 1:length(ff_array)
            alpha = ff_array(alpha_i);
            
            F_notravel = passengerFlow(cidx, cidx)*0;
            F_travel = passengerFlow(cidx, cidx);
            
            %horizon = size(data_4_s, 2) - T_tr-T_ad;
            
%             [yt, Xt] = data_prep(data_4_s, F_travel, popu(cidx), k, jp);
%             [beta_withtravel] = ind_beta(Xt, yt, alpha, k, T_tr+T_ad, popu(cidx), jp);
%             [yt, Xt] = data_prep(data_4_s, F_notravel, popu(cidx), k, jp);
%             [beta_notravel] = ind_beta(Xt, yt, alpha, k, T_tr+T_ad, popu(cidx), jp);
%             
%             infec_notravel = simulate_pred(data_4_s(:, 1:T_trad), F_travel, beta_withtravel, popu(cidx), k, horizon, jp);
%             infec_travel = simulate_pred(data_4_s(:, 1:T_trad), F_notravel, beta_notravel, popu(cidx), k, horizon, jp);
            
            beta_withtravel = var_ind_beta(data_4_s(:, 1:T_tr), F_travel, ones(sum(cidx), 1)*alpha, ones(sum(cidx), 1)*k, T_tr, popu(cidx), ones(sum(cidx), 1)*jp);
            beta_notravel = var_ind_beta(data_4_s(:, 1:T_tr), F_notravel, ones(sum(cidx), 1)*alpha, ones(sum(cidx), 1)*k, T_tr, popu(cidx), ones(sum(cidx), 1)*jp);
                        
            infec_travel = var_simulate_pred(data_4_s(:, 1:T_tr), F_travel, beta_withtravel, popu(cidx), ones(sum(cidx), 1)*k, horizon, ones(sum(cidx), 1)*jp);
            infec_notravel = var_simulate_pred(data_4_s(:, 1:T_tr), F_notravel, beta_notravel, popu(cidx), ones(sum(cidx), 1)*k, horizon, ones(sum(cidx), 1)*jp);
            
            RMSEvec = sqrt(mean((infec_notravel - data_4_s(:, end-horizon+1:end)).^2, 2));
            RMSEval_no(k, jp, alpha_i, :) = (RMSEvec);
            MAPEvec = mean(abs(infec_notravel - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
            MAPEval_no(k, jp, alpha_i, :) = (MAPEvec);
            RMSEvec = sqrt(mean((infec_travel - data_4_s(:, end-horizon+1:end)).^2, 2));
            RMSEval_yes(k, jp, alpha_i, :) = (RMSEvec);
            MAPEvec = mean(abs(infec_travel - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
            MAPEval_yes(k, jp, alpha_i, :) = (MAPEvec);
        end
    end
    fprintf('.');
end
fprintf('\n');


%% Identify best params per country at reference day
best_param_list_no = zeros(length(popu), 5);
best_param_list_yes = zeros(length(popu), 5);
alpha_start = 5;

for cid = 1:length(popu)
    thistable_no = [];
    thistable_yes = [];
    for k=1:length(k_array)
        for jp=1:ceil(length(jp_array)/k)
            for alpha_i = alpha_start:length(ff_array)
                thistable_no = [thistable_no; [k jp alpha_i MAPEval_no(k, jp, alpha_i, cid) RMSEval_no(k, jp, alpha_i, cid)]];
                thistable_yes = [thistable_yes; [k jp alpha_i MAPEval_yes(k, jp, alpha_i, cid) RMSEval_yes(k, jp, alpha_i, cid)]];
            end
        end
    end
    thistable_no = sortrows(thistable_no, 5);
    thistable_yes = sortrows(thistable_yes, 5);
    best_param_list_no(cid, :) = thistable_no(1, :);
    best_param_list_yes(cid, :) = thistable_yes(1, :);
end


%% Identify single best params at reference day
MAPEtable_notravel_fixed = [];
MAPEtable_travel_fixed = [];
T_tr = 57;
inf_thres = 1;
inf_uthres = 100000000000;
cidx = (data_4(:, T_tr) > inf_thres & data_4(:, T_tr) < inf_uthres);

for k=1:length(k_array)
    for jp=1:ceil(length(jp_array)/k)
        for alpha_i = alpha_start:length(ff_array)
            MAPEtable_notravel_fixed = [MAPEtable_notravel_fixed; [k jp alpha_i nanmean(MAPEval_no(k, jp, alpha_i, cidx)) nanmean(RMSEval_no(k, jp, alpha_i, cidx))]];
            MAPEtable_travel_fixed = [MAPEtable_travel_fixed; [k jp alpha_i nanmean(MAPEval_yes(k, jp, alpha_i, cidx)) nanmean(RMSEval_yes(k, jp, alpha_i, cidx))]];
        end
    end
end
MAPEtable_notravel_fixed_s = sortrows(MAPEtable_notravel_fixed, 5);
MAPEtable_travel_fixed_s = sortrows(MAPEtable_travel_fixed, 5);

%% Show results
disp('Validation');
disp([mean(best_param_list_yes(cidx, 5)) mean(best_param_list_yes(cidx, 4)) mean(best_param_list_no(cidx, 5)) mean(best_param_list_no(cidx, 4))]);
disp([MAPEtable_travel_fixed_s(1, 5) MAPEtable_travel_fixed_s(1, 4) MAPEtable_notravel_fixed_s(1, 5) MAPEtable_notravel_fixed_s(1, 4)])

%% Run evaluation on test set 
horizon = 3;
T_trad = 57+horizon;
beta_travel = var_ind_beta(data_4(:, 1:T_trad), passengerFlow, best_param_list_yes(:, 3)*0.1, best_param_list_yes(:, 1), T_tr, popu, best_param_list_yes(:, 2));
beta_notravel = var_ind_beta(data_4(:, 1:T_trad), passengerFlow*0, best_param_list_no(:, 3)*0.1, best_param_list_no(:, 1), T_tr, popu, best_param_list_no(:, 2));
%fprintf('trained');

data_4_s = data_4(:, 1:T_trad+horizon);

infec_travel = var_simulate_pred(data_4(:, 1:T_trad), passengerFlow, beta_travel, popu, best_param_list_yes(:, 1), horizon, best_param_list_yes(:, 2));
infec_notravel = var_simulate_pred(data_4(:, 1:T_trad), passengerFlow*0, beta_notravel, popu, best_param_list_no(:, 1), horizon, best_param_list_no(:, 2));
%fprintf('predicted');

% inf_thres = 1;
% inf_uthres = 10000000000000000;
% cidx = (data_4(:, T_trad) > inf_thres & data_4(:, T_trad) < inf_uthres);

RMSEvec = sqrt(mean((infec_notravel - data_4_s(:, end-horizon+1:end)).^2, 2));
RMSEtest_no = mean(RMSEvec(cidx));
MAPEvec = mean(abs(infec_notravel - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
MAPEtest_no = mean(MAPEvec(cidx));
RMSEvec = sqrt(mean((infec_travel - data_4_s(:, end-horizon+1:end)).^2, 2));
RMSEtest_yes = mean(RMSEvec(cidx));
MAPEvec = mean(abs(infec_travel - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
MAPEtest_yes = mean(MAPEvec(cidx));

disp('Test');
disp([RMSEtest_yes MAPEtest_yes RMSEtest_no MAPEtest_no]);

alpha_l = MAPEtable_travel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_travel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_travel_fixed_s(1, 2)*ones(length(popu), 1);

beta_travel = var_ind_beta(data_4(:, 1:T_trad), passengerFlow, alpha_l, k_l, T_tr, popu, jp_l);
infec_travel = var_simulate_pred(data_4(:, 1:T_trad), passengerFlow, beta_travel, popu, k_l, horizon, jp_l);

alpha_l = MAPEtable_notravel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);

beta_notravel = var_ind_beta(data_4(:, 1:T_trad), passengerFlow*0, alpha_l, k_l, T_tr, popu, jp_l);
infec_notravel = var_simulate_pred(data_4(:, 1:T_trad), passengerFlow*0, beta_notravel, popu, k_l, horizon, jp_l);

RMSEvec = sqrt(mean((infec_notravel - data_4_s(:, end-horizon+1:end)).^2, 2));
RMSEtest_no = mean(RMSEvec(cidx));
MAPEvec = mean(abs(infec_notravel - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
MAPEtest_no = mean(MAPEvec(cidx));
RMSEvec = sqrt(mean((infec_travel - data_4_s(:, end-horizon+1:end)).^2, 2));
RMSEtest_yes = mean(RMSEvec(cidx));
MAPEvec = mean(abs(infec_travel - data_4_s(:, end-horizon+1:end))./data_4_s(:, end-horizon+1:end), 2);
MAPEtest_yes = mean(MAPEvec(cidx));

disp([RMSEtest_yes MAPEtest_yes RMSEtest_no MAPEtest_no]);
%% Plot distribution
% 
% figure('DefaultAxesFontSize',18);
% boxplot(best_param_list(data_4_s(:, end)>1, 1:3), {'k', 'J', 'alpha'});
% ylabel('Value');
% xlabel('hyper-parameter');
% if length(popu) < 60
%     title('US states');
% else
%     title('Global');
% end