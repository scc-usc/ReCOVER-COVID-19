function [k, theta] = gamma_param_med(med, lb, effi, teffi, target)
if nargin < 5
    target = 0.5;
end
y = [(1-effi)/(1-lb); target];
x = [teffi; med];
options = optimoptions('fsolve', 'Display','off');
k_theta = fsolve(@(params)(gamm_prob(x, params) - y), [2; 50], options);
k = (k_theta(1));
theta = k_theta(2);
end

function prob = gamm_prob(x, k_theta)
k = (k_theta(1));
theta = k_theta(2);
prob = gammainc(x/theta, k);
end