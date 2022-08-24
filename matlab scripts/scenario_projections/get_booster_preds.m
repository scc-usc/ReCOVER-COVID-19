function [booster_given_by_age] = get_booster_preds(extra_dose_age_est, vacc_given_by_age, popu_by_age_new, rel_booster_coverage, blag, exact_ub, sat_day)
%GET_VACC_PREDS Summary of this function goes here
%   Detailed explanation goes here
ns = size(extra_dose_age_est, 1);
na = size(extra_dose_age_est, 3);
T = size(extra_dose_age_est, 2);
horizon = size(vacc_given_by_age, 2) - T;

if nargin < 7
    sat_day = -1;
end

if nargin < 6
    exact_ub = 0;
end

if nargin < 5
    blag = 6*30; % min lag between 2nd dose and boosters
end

if nargin < 4
    rel_booster_coverage = ones(ns, na);
end

if length(rel_booster_coverage(:))==1
    rel_booster_coverage = repmat(rel_booster_coverage, [1 na]);
end
if size(rel_booster_coverage, 1) == 1
    rel_booster_coverage = repmat(rel_booster_coverage, [ns 1]);
end

booster_given_by_age = zeros(ns, T+horizon, na);
options = optimoptions('lsqlin', 'Display', 'off');
prev_alpha = 0.1; 

extra_dose_age_est_s = extra_dose_age_est;

for idx = 1:na
    extra_dose_age_est_s(:, :, idx) = smooth_epidata(extra_dose_age_est(:, :, idx), 7);
end


for cid = 1:ns
    for ag = na:-1:1
        ub = rel_booster_coverage(cid, ag);%*vacc_given_by_age(cid, end, ag)./popu_by_age_new(cid, ag);
        Y_raw = squeeze(extra_dose_age_est(cid, :, ag))./popu_by_age_new(cid, ag);
        Y = squeeze(extra_dose_age_est(cid, :, ag));
        Y = Y(:)'./popu_by_age_new(cid, ag);
        lag = 7; %bad data in last weeks
        xs = [0 diff(movmean(Y(1:T), lag))]; xs = xs(1: T-lag);
        x_fd = vacc_given_by_age(cid, :, ag)./popu_by_age_new(cid, ag);
        
        if ub > 0.95*x_fd(end) % Upper bound too small
            ub = 1;
        end

        k = 2; jp = 7;
        f = zeros(k*jp, k);
        for kk = 1:k
            f((kk-1)*jp+1: kk*jp, kk) = 1;
        end
        
        skipdays = T-100; 
        xt = zeros(T-skipdays-lag, k); dx = zeros(T-skipdays-lag, 1);
        for tt=(1+skipdays):T-lag
            w = (0.9^(T-lag - tt));
            xt(tt-skipdays, :) = w*(ub*x_fd(tt-blag) - Y(tt-1)).*(xs(tt-jp*k : tt-1)*f);
            dx(tt-skipdays) = w*xs(tt);
        end
        
        alpha = lsqlin(1000*xt, 1000*dx, [], [], [], [], zeros(k, 1), [], [], options);
        
        % If the learned value of alpha is 0, assume it is 0.5
        if sum(alpha) < 1e-1
            alpha = alpha.*0 + 0.35;
        end
        
        preds = simvac(Y_raw(1:T-lag), xs, x_fd, alpha, ub, horizon + lag, k, jp, blag, exact_ub, sat_day);
        bad_idx = (preds > ub.*x_fd(end));
        new_preds = [preds(1) - Y_raw(T-lag), diff(preds)];
        new_preds(bad_idx) = 0;
        preds = Y_raw(T-lag) + cumsum(new_preds);
        preds = preds*popu_by_age_new(cid, ag);
        
        booster_given_by_age(cid, 1:(T-lag), ag) = extra_dose_age_est(cid, 1:(T-lag), ag);
        new_vals = preds;

        booster_given_by_age(cid, (T-(lag)+1):T+horizon, ag) = new_vals;
        prev_alpha = alpha;
    end
end
end

function predx = simvac(x, xs, x_fd, alpha, rel_ub, horizon, k, jp, blag, exact_ub, b_sat_day)
T = length(x);

if nargin < 10
    exact_ub = 0;
end

if b_sat_day < 0
% sat_day = find(diff(x_fd) < 0.005); % Saturation day of the 2-dose vaccine
% if ~isempty(sat_day)
%     sat_day = sat_day(1);
%     b_sat_day = sat_day+blag - T;
% else
%     b_sat_day = horizon;
% end
b_sat_day = horizon;
end


all_dat = zeros(1, T+horizon); all_dat(1, 1: T) = (xs);
predx = zeros(1, horizon);
b = x(end);

f = zeros(k*jp, k);
for kk = 1:k
    f((kk-1)*jp+1: kk*jp, kk) = 1;
end
accel = 1;
for tt=1:horizon
    xt = all_dat(tt+T-jp*k : tt+T-1)*f;
    dx = (rel_ub*x_fd(T+tt-blag) - b)*xt*(alpha.*accel);
    dx = (dx+abs(dx))/2 + 1e-5;
    all_dat(tt+T) = dx;
    if exact_ub > 0 && rel_ub < 1
        %accel = exp((b_sat_day./(b_sat_day-tt+1)).^2)/exp(1);
        accel = (b_sat_day./(b_sat_day-tt+1)).^2;
    else
        accel = 1;
    end
    b = b + dx;
    predx(tt) = b;
end

end
