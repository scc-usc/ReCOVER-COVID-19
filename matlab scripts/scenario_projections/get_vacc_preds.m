function [vacc_given_by_age] = get_vacc_preds(vacc_num_age_est, popu_by_age_new, horizon, final_cov)
%GET_VACC_PREDS Summary of this function goes here
%   Detailed explanation goes here

ns = size(vacc_num_age_est, 1);
na = size(vacc_num_age_est, 3);
T = size(vacc_num_age_est, 2);

if size(vacc_num_age_est, 1)==1
    temp = zeros(ns, T, 1);
    temp(:, :, 1) = vacc_num_age_est;
    vacc_num_age_est = temp;
end

vacc_num_age_est_s = vacc_num_age_est;

for idx = 1:na
    vacc_num_age_est_s(:, :, idx) = smooth_epidata(vacc_num_age_est(:, :, idx), 7);
end

if nargin < 4
    final_cov = ones(ns, na);
end

if size(final_cov, 1) == 1
    final_cov = repmat(final_cov, [ns 1]);
end

vacc_given_by_age = zeros(ns, T+horizon, na);
options = optimoptions('lsqlin', 'Display', 'off');

for cid = 1:ns
    ub = 1;
    for ag = na:-1:1
        
        Y = squeeze(vacc_num_age_est_s(cid, :, ag));
        Y = Y(:)'./popu_by_age_new(cid, ag);
        lag = 14; %bad data in last two weeks
        xs = [0 diff(movmean(Y(1:T), 14))]; xs = xs(1: T-lag);
        k = 3; jp = 7;
        f = zeros(k*jp, k);
        for kk = 1:k
            f((kk-1)*jp+1: kk*jp, kk) = 1;
        end
        
        skipdays = T-100; 
        xt = zeros(T-skipdays-lag, k); dx = zeros(T-skipdays-lag, 1);
        for tt=(1+skipdays):T-lag
            w = (0.9^(T-lag - tt));
            xt(tt-skipdays, :) = w*(ub - Y(tt-1)).*(xs(tt-jp*k : tt-1)*f);
            dx(tt-skipdays) = w*xs(tt);
        end
        
        alpha = lsqlin(1000*xt, 1000*dx, [], [], [], [], zeros(k, 1), [], [], options);
        preds = simvac(Y(1:T-lag), xs, alpha, ub, horizon + 14, k, jp);
        
        ub = preds(end);
        preds = preds*popu_by_age_new(cid, ag);
        
        vacc_given_by_age(cid, 1:(T-lag), ag) = vacc_num_age_est(cid, 1:(T-lag), ag);
        %new_vals = vacc_num_age_est(cid, T, ag) - preds(1) + preds(2:end);
        new_vals = preds;
        idx = new_vals/popu_by_age_new(cid, ag) > final_cov(cid, ag);
        new_vals(idx) = final_cov(cid, ag)*popu_by_age_new(cid, ag);
        vacc_given_by_age(cid, (T-(lag)+1):T+horizon, ag) = new_vals;
    end
end
end

function predx = simvac(x, xs, alpha, ub, horizon, k, jp)
T = length(x);
all_dat = zeros(1, T+horizon); all_dat(1, 1: T) = (xs);
predx = zeros(1, horizon);
b = x(end);
f = zeros(k*jp, k);
for kk = 1:k
    f((kk-1)*jp+1: kk*jp, kk) = 1;
end
for tt=1:horizon
    xt = all_dat(tt+T-jp*k : tt+T-1)*f;
    dx = (ub - b)*xt*alpha;
    dx = (dx+abs(dx))/2;
    all_dat(tt+T) = dx;
    b = b + dx;
    predx(tt) = b;
end
end
