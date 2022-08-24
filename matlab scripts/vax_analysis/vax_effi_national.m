prepare_us_national_data;

%%

%%
var_filter = [1 3 5]';
gg = 3; un_low = 0; nv = length(sel_var(var_filter));
data_selector1 = data_selector;
oct_day = days(datetime(2021, 10, 15) - datetime(2020, 1, 23));
data_selector1(first_day:last_day) = 1; data_selector1(oct_day:end) = 0;

var_frac_all1 = squeeze(var_frac_all(1, var_filter, data_selector1>0));
Iv = infec_vac(data_selector1>0, gg);
Iu = infec_unvac(data_selector1>0, gg);
infec_ratio1 = infec_ratio(data_selector1>0, gg);
figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_ratio1], 'o'); hold on;
 %% Leaky linear
gg = 5; data_selector2 = data_selector1; data_selector2(1:579) = 0;
V = vax_num_dummy(data_selector2>0, gg);
U = unvax_num_dummy(data_selector2>0, gg);
Cv = cum_vax_infec(data_selector2>0, gg);
Cu = cum_unvax_infec(data_selector2>0, gg);
Iv = infec_vac(data_selector2>0, gg);
Iu = infec_unvac(data_selector2>0, gg);
infec_r = Iv./Iu;
a = [V(2)-V(1); diff(V)]./U;
A = (cumprod(1- a));
% P0 = V(1)*Iu0./U(1);
% P = A.*(P0 + cumsum(a.*Cu./A)/g_u);
P = A.*cumsum(a.*Cu./A); P(:) = 0;
X = [V, -P, -Cv, -ones(length(V), 1), infec_r.*U(1), infec_r.*Cu]; y = infec_r.*U;
lb = zeros(size(X, 2), 1); lb(6) = 1; ub = inf(size(lb)); %ub(2:4) = 0;
num = [V, -P, -Cv, -ones(length(V), 1), zeros(length(V), 2)];
den = [zeros(length(V), 4), U(1)*ones(length(V), 1), Cu]; 
A = []; b= [];
A = [-num; den];b = [zeros(length(V), 1); U];
%A = [-num; den];b = [-Iv; U];
params = lsqlin(X, y, A, b, [], [], lb, ub);
infec_r_fit = (num*params)./(U - den*params);


figure; plot(datetime(2020, 1, 23) + find(data_selector2>0), [infec_r infec_r_fit]); 
%%
%% Unvaxed linear
gg1 = 5; gg2 = 4; 
U1 = unvax_num_dummy(data_selector1>0, gg1);
U2 = unvax_num_dummy(data_selector1>0, gg2);
Cu1 = cum_unvax_infec(data_selector1>0, gg1);
Cu2 = cum_unvax_infec(data_selector1>0, gg2);
Iu1 = infec_unvac(data_selector1>0, gg1);
Iu2 = infec_unvac(data_selector1>0, gg2);
infec_r = Iu1./Iu2;

X = [U1, -ones(length(U1), 1), -U2.*infec_r, infec_r, Cu2.*infec_r]; y = Cu1;
lb = zeros(size(X, 2), 1);
num =  [U1, -ones(length(U1), 1), zeros(length(U1), 3)];
den = [zeros(length(U1), 2), U2, -ones(length(U1), 1), -Cu2];  A = []; b = [];
A = -[num; den]; b = -[Cu1; 0*Cu2];
params = lsqlin(X, y, A, b, [], [], lb); 
infec_r_fit = (num*params - Cu1)./(den*params);


figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_r infec_r_fit]);  


%% AoN/Leaky nLL optimization
gg = 5;
V = vax_num_dummy(data_selector1>0, gg);
U = unvax_num_dummy(data_selector1>0, gg);
Cv = cum_vax_infec(data_selector1>0, gg);
Cu = cum_unvax_infec(data_selector1>0, gg);
Iv = infec_vac(data_selector1>0, gg);
Iu = infec_unvac(data_selector1>0, gg);

lb = zeros(nv+5, 1); ub = 10*ones(nv+5, 1);
ub(nv+1:nv+2) = 1;
lb(nv+3) = 0.001; ub(nv+3) = 1;
lb(nv+4) = 0.2; ub(nv+4) = 0.7;
lb(nv+5) = 0; ub(nv+5) = 10;

model_type = 3;

b_func = @(x)(leaky_guess_un_nLL(x, V, U, Cv, Cu, var_frac_all1, Iv, Iu, model_type));

options = optimoptions("fminunc", 'MaxFunctionEvaluations', 2000, 'Display','none');

max_runs = 50;
param_runs = nan(length(lb), max_runs);
nLLs = nan(max_runs, 1);
for j=1:max_runs
    init_val = lb + (ub-lb).*rand(length(lb), 1);
    try
        [xx1, fval, ~, ~, ~, ~] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), log((init_val -lb + 1e-10)./(ub-init_val + 1e-10)), options);
        nLLs(j) = fval;
        param_runs(:, j) = xx1;
    catch
        continue;
    end
end

[~, idx] = min(nLLs);
xx = param_runs(:, idx);
[xx, ~, ~, ~, ~, H] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), xx, options);

params = lb + (ub-lb).*logsig(xx);
[~, infec_r] = b_func(params);
figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [Iv./Iu], 'o'); hold on;
plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_r]);

err =  sqrt(abs(diag(inv(H))));
params_CI = lb + (ub-lb).*logsig(xx + [-1.96*err, 1.96*err]);

%% Waning fit

V = vax_num_dummy(data_selector1>0, gg);
U = unvax_num_dummy(data_selector1>0, gg);
Cv = cum_vax_infec(data_selector1>0, gg);
Cu = cum_unvax_infec(data_selector1>0, gg);
Iv = infec_vac(data_selector1>0, gg);
Iu = infec_unvac(data_selector1>0, gg);

lb = zeros(2*nv+3, 1); ub = ones(2*nv+3, 1);
ub(1:nv) = 0.5;
lb(nv+3) = 0.5; ub(nv+3) = 0.5;     % Under-reporting
lb(nv+1:nv+2) = data_ag(first_day, gg)./pop_ag(gg); ub(nv+1:nv+2) = 2*data_ag(first_day, gg)./pop_ag(gg);
lb(nv+4 : nv+3+nv) = 0; ub(nv+4 : nv+3+nv) = 1;

f_day = 297; last_day = find(data_selector1 > 0); last_day = last_day(end);

Vdiff = zeros(length(V), 1 + (last_day-f_day));

for t=1:size(Vdiff, 1)
    for tau = 1:size(Vdiff, 2)
        t_rel = t + (first_day- f_day);
        if t_rel - tau -1 > 0
            Vdiff(t, tau) = vac_ag(f_day + (t_rel - tau), gg) - vac_ag(f_day + (t_rel - tau) - 1, gg);
        end
    end
end


b_func = @(x)(waning_guess_un_nLL(x, V, U, Cv, Cu, var_frac_all1, Iv, Iu, Vdiff));

options = optimoptions("fminunc", 'MaxFunctionEvaluations', 2000, 'Display', 'none');

max_runs = 10;
param_runs = nan(length(lb), max_runs);
nLLs = nan(max_runs, 1);
for j=1:max_runs
    init_val = lb + (ub-lb).*rand(nv*2 +3, 1);
    try
        [xx1, fval, ~, ~, ~, ~] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), log((init_val -lb + 1e-10)./(ub-init_val + 1e-10)), options);
        nLLs(j) = fval;
        param_runs(:, j) = xx1;
    catch
        continue;
    end
end

[~, idx] = min(nLLs);
xx = param_runs(:, idx);
[xx, ~, ~, ~, ~, H] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), xx, options);

params = lb + (ub-lb).*logsig(xx);
[~, infec_r] = waning_guess_un_nLL(params, V, U, Cv, Cu, var_frac_all1, Iv, Iu, Vdiff);
%figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_ratio1 infec_r]);
plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_r]);
err =  sqrt(abs(diag(inv(H))));
params_CI = lb + (ub-lb).*logsig(xx + [-1.96*err, 1.96*err]);


%% Redrawing
figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_ratio1], 'o'); hold on;
%% Leaky, delta variant (580, 661) using nLL

data_selector2 = data_selector1; data_selector2(1:579) = 0;
V = vax_num_dummy(data_selector2>0, gg);
U = unvax_num_dummy(data_selector2>0, gg);
Cv = cum_vax_infec(data_selector2>0, gg);
Cu = cum_unvax_infec(data_selector2>0, gg);
Iv = infec_vac(data_selector2>0, gg);
Iu = infec_unvac(data_selector2>0, gg);

lb = zeros(5, 1); ub = ones(5, 1);
ub(1) = 2;
lb(4) = 0.001; ub(4) = 0.7;
lb(5) = 0.2; ub(5) = 1;
lb(6) = 1; ub(6) = 1;
lb(2) = 0.5*data_ag(first_day, gg)./V(1); ub(2) = 1;
lb(3) = 0.5*data_ag(first_day, gg)./U(1); ub(3) = 1;
% ub(2:3) = 0.25;
% lb(1) = 0.1799; ub(1) = 0.2059;
% lb(4) = 0.032; ub(4) = 0.0329;

model_type = 0;
b_func = @(x)(leaky_guess_un_nLL1(x, V, U, Cv, Cu, Iv, Iu, model_type));

options = optimoptions("fminunc", 'MaxFunctionEvaluations', 2000, 'Display','none');

max_runs = 50;
param_runs = nan(length(lb), max_runs);
nLLs = nan(max_runs, 1);
for j=1:max_runs
    init_val = lb + (ub-lb).*rand(length(lb), 1);
    try
        [xx1, fval, ~, ~, ~, ~] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), log((init_val -lb + 1e-10)./(ub-init_val + 1e-10)), options);
        nLLs(j) = fval;
        param_runs(:, j) = xx1;
    catch
        continue;
    end
end
display(['Successes :: ' num2str(sum(~isnan(nLLs)))])
[~, idx] = min(nLLs);
xx = param_runs(:, idx);
[xx, ~, ~, ~, ~, H] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), xx, options);

params = lb + (ub-lb).*logsig(xx);
%[~, infec_r] = leaky_guess_un_nLL1(params, V, U, Cv, Cu,  Iv, Iu);
[~, infec_r] = b_func(params);

%figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_ratio1], 'o'); hold on;
plot(datetime(2020, 1, 23) + find(data_selector2>0), [infec_r]);

err =  sqrt(abs(diag(inv(H))));
params_CI = lb + (ub-lb).*logsig(xx + [-1.96*err, 1.96*err]);



%% Unvaxed comparison for whole period

data_selector2 = data_selector1; gg1 = 4; gg2 = 5;
U1 = unvax_num_dummy(data_selector2>0, gg1);
U2 = unvax_num_dummy(data_selector2>0, gg2);
Cu1 = cum_unvax_infec(data_selector2>0, gg1);
Cu2 = cum_unvax_infec(data_selector2>0, gg2);
Iu1 = infec_unvac(data_selector2>0, gg1);
Iu2 = infec_unvac(data_selector2>0, gg2);

lb = zeros(nv+4, 1); ub = ones(nv+4, 1);
lb(1:nv) = 1; ub(1:nv) = 1;
lb(1) = 0; ub(1) = 10;
lb(nv+1) = 0; ub(nv+1) = 1;
lb(nv+2) = 0; ub(nv+2) = 1;
lb(nv+3) = 0; ub(nv+3) = 1;
lb(nv+4) = 0; ub(nv+4) = 1;
%lb(2:3) = 0.5*data_ag(first_day, gg)./U(1); ub(2:3) = 1;


model_type = 0;
b_func = @(x)(unvaxed_compare_nLL(x, U1, U2, Cu1, Cu2, var_frac_all1, Iu1, Iu2, model_type));

options = optimoptions("fminunc", 'MaxFunctionEvaluations', 2000, 'Display','none');

max_runs = 500;
param_runs = nan(length(lb), max_runs);
nLLs = nan(max_runs, 1);
for j=1:max_runs
    init_val = lb + (ub-lb).*rand(length(lb), 1);
    try
        [xx1, fval, ~, ~, ~, ~] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), log((init_val -lb + 1e-10)./(ub-init_val + 1e-10)), options);
        nLLs(j) = fval;
        param_runs(:, j) = xx1;
    catch
        continue;
    end
    if sum(~isnan(nLLs)) > 20
        break;
    end
end
display(['Successes :: ' num2str(sum(~isnan(nLLs)))])
[~, idx] = min(nLLs);
xx = param_runs(:, idx);
[xx, ~, ~, ~, ~, H] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), xx, options);

params = lb + (ub-lb).*logsig(xx);
%[~, infec_r] = leaky_guess_un_nLL1(params, V, U, Cv, Cu,  Iv, Iu);
[~, infec_r] = b_func(params);

figure; plot(datetime(2020, 1, 23) + find(data_selector2>0), Iu1./Iu2, 'o'); hold on;
plot(datetime(2020, 1, 23) + find(data_selector2>0), [infec_r]);

err =  sqrt(abs(diag(inv(H))));
params_CI = lb + (ub-lb).*logsig(xx + [-1.96*err, 1.96*err]);

%%
%% Unvaxed comparison for whole period, variants specific

data_selector2 = data_selector1; gg = [5 4]; ng = length(gg);
U = unvax_num_dummy(data_selector2>0, gg);
Cu = cum_unvax_infec(data_selector2>0, gg);
Iu = infec_unvac(data_selector2>0, gg);
nl = size(var_frac_all1, 1);
alpha_lb = zeros(ng, nl); alpha_ub = 100*ones(ng, nl); alpha_ub(1, 1) = 1.1; alpha_lb(1, 1) = 0.9;
Iu0_lb = 0.008+zeros(ng, nl); Iu0_ub = 0.01 + zeros(ng, nl); Iu0_ub(:, 1) = 1;
beta_lb = 0.05*ones(ng, nl); beta_ub = 0.8*ones(ng, nl);

lb = [alpha_lb; Iu0_lb; beta_lb]; ub = [alpha_ub; Iu0_ub; beta_ub];
lb = lb(:); ub = ub(:);

model_type = 0;
b_func = @(x)(unvaxed_multicompare_nLL(x, U, Cu, var_frac_all1, Iu, model_type));

options = optimoptions("fminunc", 'MaxFunctionEvaluations', 2000, 'Display','none');

max_runs = 1000;
param_runs = nan(length(lb), max_runs);
nLLs = nan(max_runs, 1);
for j=1:max_runs
    init_val = lb + (ub-lb).*rand(length(lb), 1);
    try
        [xx1, fval, ~, ~, ~, ~] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), log((init_val -lb + 1e-10)./(ub-init_val + 1e-10)), options);
        nLLs(j) = fval;
        param_runs(:, j) = xx1;
    catch
        continue;
    end
    if sum(~isnan(nLLs)) > 20
        break;
    end
end
display(['Successes :: ' num2str(sum(~isnan(nLLs)))])
[~, idx] = min(nLLs);
xx = param_runs(:, idx);
[xx, ~, ~, ~, ~, H] = fminunc(@(x)(boundless_f(b_func, x, lb, ub)), xx, options);

params = lb + (ub-lb).*logsig(xx);
%[~, infec_r] = leaky_guess_un_nLL1(params, V, U, Cv, Cu,  Iv, Iu);
[~, infec_r] = b_func(params);

figure; plot(datetime(2020, 1, 23) + find(data_selector2>0), Iu(:, 2:ng)./Iu(:, 1), 'o'); hold on;
plot(datetime(2020, 1, 23) + find(data_selector2>0), [infec_r]);

err =  sqrt(abs(diag(inv(H))));
params_CI = lb + (ub-lb).*logsig(xx + [-1.96*err, 1.96*err]);


 %% Plot feasible region
% rand_params = params_CI(:, 1) + (params_CI(:, 2) - params_CI(:, 1)).*([0:4]/4);
% [X1, X2, X3, X4, X5, X6] = ndgrid(rand_params(1, :), rand_params(2, :), rand_params(3, :), rand_params(4, :), rand_params(5, :), rand_params(6, :));
% all_params = [X1(:) X2(:) X3(:) X4(:) X5(:) X6(:)];
% 
% all_points = nan(length(V), size(all_params, 1));
% for j=1:size(all_params, 1)
%     thisseries = leaky_guess_un(all_params(j, :)', V, U, Cv, Cu, var_frac_all1);
%     if all(thisseries >=0)
%         all_points(:, j) = thisseries;
%     end
% end
% qq  = quantile(all_points', [0 1]);
% figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_ratio1 infec_r]); hold on;
% plot(datetime(2020, 1, 23) + find(data_selector1>0), qq', '--');
% %
% %%
% max_res = 200;
% hmap = zeros(length(infec_ratio1), max_res);
% pts = linspace(0.01, 1.2, max_res);
% for tt=1:size(all_points, 1)
%     [f, xi] = ksdensity(all_points(tt, :), pts);
%     hmap(tt, :) = f;
% end
% 
% imagesc(datetime(2020, 1, 23) + find(data_selector1>0), pts, hmap)
% 
% qq  = quantile(all_points', [0 1]);
% figure; plot(datetime(2020, 1, 23) + find(data_selector1>0), [infec_ratio1 infec_r]); hold on;
% plot(datetime(2020, 1, 23) + find(data_selector1>0), qq', '--');
% plot(datetime(2020, 1, 23) + find(data_selector1>0), min(all_points, [], 2), '--');
% plot(datetime(2020, 1, 23) + find(data_selector1>0), max(all_points, [], 2), '--');
%% Function for LSE
function [infec_r] = leaky_guess_un(params, V, U, Cv, Cu, var_frac_all)
nl = size(var_frac_all, 1);
leaks = params(1:nl);
Iv0 = params(nl+1)*V(1);
Iu0 = params(nl+2)*U(1);
un_v = 1./params(nl+3);
sus_ratio = (V - Iv0 - un*Cv)./(U - Iu0 - un*Cu);
temp = sum(var_frac_all'./(1 + sus_ratio*leaks'), 2);
infec_r = 1./(temp) - 1;
end

%% Function for nLL
function [nLL, infec_r] = leaky_guess_un_nLL(params, V, U, Cv, Cu, var_frac_all, new_Iv, new_Iu, model_type)
if nargin < 9
    model_type = 0;
end

nl = size(var_frac_all, 1);
leaks = params(1:nl);
Iv0 = params(nl+1)*V(1);
Iu0 = params(nl+2)*U(1);
g_v = params(nl+3);
g_u = params(nl+4);
alpha = params(nl+5);
a = [V(2)-V(1); diff(V)]./U;
A = (cumprod(1- a));
P0 = V(1)*Iu0./U(1);
P = A.*(P0 + cumsum(a.*Cu./A)/g_u);
%P = (Iu0 + Cv/g_u).*V./U;

if model_type == 1 % All or nothing
    sus_ratio = (V - Iv0 - P)./(U - Iu0 - Cu/g_u);
    coeff = (g_v/g_u);
elseif model_type == 2 % Equal reporting between vaxd and unvaxd
    sus_ratio = (V - Iv0 - Cv/g_u - P)./(U - Iu0 - Cu/g_u);
    coeff = 1;
elseif model_type == 3 % Different reporting
    sus_ratio = (V - Iv0 - Cv/g_v - P)./(U - Iu0 - Cu/g_u);
    coeff = (g_v/g_u);
else    % The wierd one
    sus_ratio = (V - Iv0 - Cv/g_v - P)./(U - Iu0 - Cu/g_u);
    coeff = alpha;
end

if any(sus_ratio < 0)
    nLL = nan;
    return;
end

temp = sum(var_frac_all'./(1 + sus_ratio*leaks'), 2);
infec_r =  coeff*(1./(temp) - 1);
nLL = -sum(new_Iv.*log(infec_r./(1+infec_r)) + new_Iu.*log(1./(1+infec_r)));
end

%% Function for nLL for single variant
function [nLL, infec_r] = leaky_guess_un_nLL1(params, V, U, Cv, Cu, new_Iv, new_Iu, model_type)
if nargin < 8
    model_type = 0;
end

nl = 1;
leaks = params(1);
Iv0 = params(nl+1)*V(1);
Iu0 = params(nl+2)*U(1);
g_v = params(nl+3);
g_u = params(nl+4);
a = [V(2)-V(1); diff(V)]./U;
A = (cumprod(1- a));
P0 = V(1)*Iu0./U(1);
P = A.*(P0 + cumsum(a.*Cu./A)/g_u);
%P = (Iu0 + Cv/g_u).*V./U;
if model_type == 1 % All or nothing
    sus_ratio = (V - Iv0 - P)./(U - Iu0 - Cu/g_u);
    infec_r = (g_v/g_u).*leaks.*sus_ratio;
elseif model_type == 2 % Equal reporting between vaxd and unvaxd
    sus_ratio = (V - Iv0 - Cv/g_u - P)./(U - Iu0 - Cu/g_u);
    infec_r = leaks.*sus_ratio;
elseif model_type == 3 % Different reporting
    sus_ratio = (V - Iv0 - Cv/g_v - P)./(U - Iu0 - Cu/g_u);
    infec_r = (g_v/g_u).*leaks.*sus_ratio;
else    % The wierd one
    sus_ratio = (V - Iv0 - Cv/g_v - P)./(U - Iu0 - Cu/g_u);
    infec_r = leaks.*sus_ratio;
end

nLL = -sum(new_Iv.*log(infec_r./(1+infec_r)) + new_Iu.*log(1./(1+infec_r)));
end

%% Function for time waning
function [nLL, infec_r] = waning_guess_un_nLL(params, V, U, Cv, Cu, var_frac_all, new_Iv, new_Iu, Vdiff)
nl = size(var_frac_all, 1);

b = -params(1:nl);
%b(:) = b(1);
Iv0 = params(nl+1)*V(1);
Iu0 = params(nl+2)*U(1);
un = 1./params(nl+3);
a = params(nl+4 : nl+3+nl);
a(:) = params(nl+4);
pre_comp = a'.*(1 - exp(b'.*(1:size(Vdiff, 2))'));
leaked = Vdiff*pre_comp;
sus_ratio = (leaked - Iv0 - un*Cv)./(U - Iu0 - un*Cu) ;
temp = sum(var_frac_all'./(1 + sus_ratio), 2);
infec_r = 1./(temp) - 1;
nLL = -sum(new_Iv.*log(infec_r./(1+infec_r)) + new_Iu.*log(1./(1+infec_r)));
end

%% Function for unvaxed agegroups comparison
function [nLL, infec_r] = unvaxed_compare_nLL(params, U1, U2, Cu1, Cu2, var_frac_all, new_Iv, new_Iu, model_type)
if nargin < 8
    model_type = 0;
end
nl = size(var_frac_all, 1);
leaks = params(1:nl);
Iu1_0 = params(nl+1)*U1(1);
Iu2_0 = params(nl+2)*U2(1);
g1 = params(nl+3);
g2 = params(nl+4);

if model_type == 0
    sus_ratio = (U1 - Iu1_0 - Cu1/g1)./(U2 - Iu2_0 - Cu2/g2);
    coeff = leaks(1);
else
    sus_ratio = (U1 - Iu1_0 - Cu1/g1)./(U2 - Iu2_0 - Cu2/g2);
    coeff = g1/g2;
end

%temp = sum(var_frac_all'./(1 + sus_ratio*leaks'), 2);
temp = sum(var_frac_all'./(1 + sus_ratio), 2);
infec_r =  coeff*(1./(temp) - 1);
nLL = -sum(new_Iv.*log(infec_r./(1+infec_r)) + new_Iu.*log(1./(1+infec_r)));
end
%%
%% Function for multiple unvaxed agegroups comparison
function [nLL, infec_r] = unvaxed_multicompare_nLL(params, U, Cu, var_frac_all, new_Iu, model_type)
if nargin < 6
    model_type = 0;
end
ng = size(U, 2);
nl = size(var_frac_all, 1);
params = reshape(params, [], nl);
leaks = params(1:ng, :);
Iu_0 = params(ng+1 : 2*ng, :).*U(1, :)';
g = params(2*ng+1 : 3*ng, :);

infec_r = zeros(size(U, 1), ng-1);
coeffs = leaks;

if model_type == 1
    coeffs = 1./g;
end

for k=2:ng
    infec_r(:, k-1) = sum(var_frac_all'.*coeffs(k-1, :).*(U(:, k) - (Iu_0(k, 1) + Cu(:, k))./g(k, :)), 2)./...
        sum(var_frac_all'.*coeffs(1, :).*(U(:, 1) - Iu_0(1, 1) - Cu(:, 1)./g(1, :)), 2);
end
probs = [ones(length(U), 1) infec_r]; probs = probs./sum(probs, 2);
nLL = -sum(new_Iu.*log(probs), 'all');
end
%%
function ret_val = boundless_f(func, x, lb, ub)
y = lb + (ub-lb).*logsig(x);
ret_val = func(y);
end