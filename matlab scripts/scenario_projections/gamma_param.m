function [k, theta] = gamma_param(mm, lb, effi, teffi)
prob = (effi - lb)/(1-lb);

theta = fzero(@(theta)(gamm_prob(teffi, mm, theta) - prob), 100);
theta = abs(theta);
k = mm/theta;
end

function prob = gamm_prob(x, mm, theta)
theta = abs(theta);
k = mm/theta;
prob = 1 - gammainc(x/theta, k);
end
