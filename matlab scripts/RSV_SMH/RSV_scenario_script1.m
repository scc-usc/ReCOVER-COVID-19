% sampling multiple underreporting between lower and mid, as they are
% better in retrospective analysis
un_list_idx = [1:4]; 
un_list = cell(length(un_list_idx), 1);
for j=1:length(un_list_idx)
    un_list{j} = un_lb + (j - 1)*(un_mid - un_lb)/(length(un_list_idx) - 1);
end

alpha_list = [0.85, 0.87, 0.89]; %  mostly around 0.9 is good, 0.95 not good. Results most sensitive to this
wan_lb_list = [0 0.3 0.6];
wan_med_list = [30, 60, 90];
wan_eff_frac_list = [0.2, 0.5]; %if x, then x*wan_med is the effi_week of 0.99
[X1, X2, X3, X4, X5] = ndgrid(un_list_idx, alpha_list, wan_lb_list, wan_med_list, wan_eff_frac_list);
scen_list = [X1(:) X2(:), X3(:), X4(:), X5(:)];
num_sims = size(scen_list, 1)



%% Scenario A: optim both
% For seniors, VE values considered are 70% (scenarios B, D) and 90% (scenarios A, C). 
% For infants, VE values considered are 60% (scenarios C, D) and 80% (scenarios A, B).

all_boosters_ts{1} = zeros(ns, T + horizon, ag);
all_boosters_ts{1}(:, :, 1) = 0.8*infants_dose_opt;
all_boosters_ts{1}(:, :, 7) = 0.9*from60_65_dose_opt;
all_boosters_ts{1}(:, :, 8) = 0.9*over65_dose_opt;
reuse_betas = 0;
fprintf('Running Scenario A');
tic; RSV_scenario_simulator_1; toc;
fprintf('\n');
net_hosp_A = net_hosp_0;
err_A = err;

reuse_betas = 1;
%% Scenario B:: optim infant pes senior
% For seniors, VE values considered are 70% (scenarios B, D) and 90% (scenarios A, C). 
% For infants, VE values considered are 60% (scenarios C, D) and 80% (scenarios A, B).

all_boosters_ts{1} = zeros(ns, T + horizon, ag);
all_boosters_ts{1}(:, :, 1) = 0.8*infants_dose_opt;
all_boosters_ts{1}(:, :, 7) = 0.7*from60_65_dose_pes;
all_boosters_ts{1}(:, :, 8) = 0.7*over65_dose_pes;

fprintf('Running Scenario B');
tic; RSV_scenario_simulator_1; toc;
fprintf('\n');
net_hosp_B = net_hosp_0;
err_B = err;
%% Scenario C:: pes infant opt senior
% For seniors, VE values considered are 70% (scenarios B, D) and 90% (scenarios A, C). 
% For infants, VE values considered are 60% (scenarios C, D) and 80% (scenarios A, B).

all_boosters_ts{1} = zeros(ns, T + horizon, ag);
all_boosters_ts{1}(:, :, 1) = 0.6*infants_dose_pes;
all_boosters_ts{1}(:, :, 7) = 0.9*from60_65_dose_opt;
all_boosters_ts{1}(:, :, 8) = 0.9*over65_dose_opt;

fprintf('Running Scenario C');
tic; RSV_scenario_simulator_1; toc;
fprintf('\n');
net_hosp_C = net_hosp_0;

err_C = err;
%% Scenario D:: pes infant pes senior
% For seniors, VE values considered are 70% (scenarios B, D) and 90% (scenarios A, C). 
% For infants, VE values considered are 60% (scenarios C, D) and 80% (scenarios A, B).

all_boosters_ts{1} = zeros(ns, T + horizon, ag);
all_boosters_ts{1}(:, :, 1) = 0.6*infants_dose_pes;
all_boosters_ts{1}(:, :, 7) = 0.7*from60_65_dose_pes;
all_boosters_ts{1}(:, :, 8) = 0.7*over65_dose_pes;

fprintf('Running Scenario D');
tic; RSV_scenario_simulator_1; toc;
fprintf('\n');
net_hosp_D = net_hosp_0;

err_D = err;

%% Scenario E: counterfactual

all_boosters_ts{1} = zeros(ns, T + horizon, ag);
tic;
fprintf('Running Scenario E');
tic; RSV_scenario_simulator_1; toc;
fprintf('\n');
toc
net_hosp_E = net_hosp_0;
err_E = err;
%%
%save RSV_round1.mat -v7
save RSV_round1_update_A_2.mat -v7