%% Set dates and file name prefix

%file_prefix = 'us'; % To be used to name generate forecast files
file_prefix = 'global';
data_4_s = data_4;
T_tr = 60; % Set reference day (Jan 21 is day 0)
T_full = size(data_4, 2); % Set reference day (Jan 21 is day 0)
horizon = 15;

%% Train with hyperparams before and after
beta_travel = var_ind_beta(data_4(:, 1:T_tr), passengerFlow, best_param_list_yes(:, 3)*0.1, best_param_list_yes(:, 1), T_tr, popu, best_param_list_yes(:, 2));
beta_notravel = var_ind_beta(data_4(:, 1:T_tr), passengerFlow*0, best_param_list_no(:, 3)*0.1, best_param_list_no(:, 1), T_tr, popu, best_param_list_no(:, 2));
beta_after = var_ind_beta(data_4(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), T_tr, popu, best_param_list(:, 2));

alpha_l = MAPEtable_travel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_travel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_travel_fixed_s(1, 2)*ones(length(popu), 1);
beta_travel_f = var_ind_beta(data_4(:, 1:T_tr), passengerFlow, alpha_l, k_l, T_tr, popu, jp_l);

alpha_l = MAPEtable_notravel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
beta_notravel_f = var_ind_beta(data_4(:, 1:T_tr), passengerFlow*0, alpha_l, k_l, T_tr, popu, jp_l);

alpha_l = MAPEtable_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_s(1, 2)*ones(length(popu), 1);
beta_after_f = var_ind_beta(data_4(:, 1:T_full), passengerFlow*0, alpha_l, k_l, T_tr, popu, jp_l);

disp('trained');

%% Predict with hyperparams before and after
% infec_travel = var_simulate_pred(data_4(:, 1:T_tr), passengerFlow, beta_travel, popu, best_param_list_yes(:, 1), horizon, best_param_list_yes(:, 2));
% infec_notravel = var_simulate_pred(data_4(:, 1:T_tr), passengerFlow*0, beta_notravel, popu, best_param_list_no(:, 1), horizon, best_param_list_no(:, 2));

infec = var_simulate_pred(data_4(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2));
infec_released = var_simulate_pred(data_4(:, 1:T_full), passengerFlow*0, beta_notravel, popu, best_param_list_no(:, 1), horizon, best_param_list_no(:, 2));

k_l = MAPEtable_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_s(1, 2)*ones(length(popu), 1);
infec_f = var_simulate_pred(data_4(:, 1:T_full), passengerFlow*0, beta_after_f, popu, k_l, horizon, jp_l);

k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
infec_released_f = var_simulate_pred(data_4(:, 1:T_full), passengerFlow*0, beta_notravel_f, popu, k_l, horizon, jp_l);


disp('predicted')

%% Write forecasts

csvwrite([file_prefix '_forecasts_quarantine.csv'], infec);
csvwrite([file_prefix '_forecasts_quarantine1.csv'], infec_f);
csvwrite([file_prefix '_forecasts_released.csv'], infec_released);
csvwrite([file_prefix '_forecasts_released1.csv'], infec_released_f);

disp('Files written');

% %% Plot New
% 
% figure('DefaultAxesFontSize',15);
% cidx = [156];
% for j=1:length(cidx)
%     subplot(1, length(cidx), j)
%     cid = cidx(j);
%     offset = 60;
%     trueshow = (offset:T_full);
%     Tx = datetime(2020, 1, 21)+ caldays(trueshow);
%     plot(Tx, data_4_s(cid, trueshow), 'LineWidth', 3);
%     hold on;
%     
%     Tx = datetime(2020, 1, 21)+caldays(T_full+1:T_full+size(infec, 2));
%     yy = [infec(cid,:)' infec_f(cid,:)'];
%     %plot(Tx, yy, 'g','LineStyle', 'none', 'Marker', 'o', 'LineWidth', 4, 'MarkerSize', 0.1); hold on;
%     h = fill([Tx fliplr(Tx)], [yy(:, 1)' fliplr(yy(:, 2)')], 'g', 'LineWidth', 1, 'EdgeColor', 'g');
%     set(h,'facealpha',.35)
%     yy = [infec_released(cid,:)' infec_released_f(cid,:)'];
%     %plot(Tx, yy , 'r', 'LineStyle', 'none', 'Marker', 'x', 'LineWidth', 4, 'MarkerSize', 0.1);
%     h = fill([Tx fliplr(Tx)], [yy(:, 1)' fliplr(yy(:, 2)')], 'r', 'LineWidth', 1, 'EdgeColor', 'r');
%     set(h,'facealpha',.25)
%     title(countries{cid})
%     xlabel('Day');
%     ylabel('Cases');
%     %legend({'True', 'Adjusted', 'Unadjusted', 'Released'}, 'Location','northwest');
%     legend({'True', 'forecast', 'released'}, 'Location','northwest');
%     hold off;
% end
% %% Plot Past
% 
% figure('DefaultAxesFontSize',18);
% cid = [1];
% offset = 10;
% Tx = datetime(2020, 1, 21)+ caldays(offset:T_tr+horizon);
% plot(Tx, data_4_s(cid, offset:T_tr+horizon), 'LineWidth', 3);
% hold on;
% Tx = datetime(2020, 1, 21)+caldays(T_tr+1:T_tr+size(infec, 2));
% plot(Tx, infec_travel(cid,:), 'LineStyle', 'none', 'Marker', 'x', 'LineWidth', 4, 'MarkerSize', 10); hold on;
% plot(Tx, infec_notravel(cid,:), 'LineStyle', 'none', 'Marker', 'x', 'LineWidth', 4, 'MarkerSize', 10); 
% title(countries{cid});
% xlabel('Day'); 
% ylabel('Cases');
% hold off;
% %legend({'True', 'Adjusted', 'Unadjusted', 'Released'}, 'Location','northwest');
% legend({'True', 'travel', 'no travel'}, 'Location','northwest');