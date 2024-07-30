function [un_mid, un_lb, un_ub] = get_underreporting(hosps_3D_s, pop_by_age, val_tt)
ag = size(hosps_3D_s, 3);
ns = size(hosps_3D_s, 1);
un_ub = zeros(ns, ag);
un_lb = zeros(ns, ag);
un_mid = zeros(ns, ag);

s_rates = zeros(ag, 1); s_rates(1) = 0.5/52;

for gg=1:ag
    for cid = 1:ns
        dd = squeeze(hosps_3D_s(cid,:, gg)); data_4 = cumsum(dd, 2);
        [~, un_prob, ~, ~, ci, ~] = learn_nonlin(data_4(:, val_tt), pop_by_age(cid, gg), 1, 1, 1, {0.5}, 'i', [0 1], s_rates(gg));
        un_mid(cid, gg) = un_prob;
        un_lb(cid, gg) = ci{1}(1, 1);
        un_ub(cid, gg) = ci{1}(1, 2);
    end
end

end

