val_tt = 104:117;
[un_mid, un_lb, un_ub] = get_underreporting(hosps_3D_s, pop_by_age, val_tt);
bad_idx = (un_lb < 1e-7) | (un_ub > 0.2);
un_lb(bad_idx) = nan;
un_mid(bad_idx) = nan;
un_ub(bad_idx) = nan;
%%
meds_lb = nanmedian(un_lb); meds_mid = nanmedian(un_mid); meds_ub = nanmedian(un_ub);
for gg=1:ag
    un_lb(bad_idx(:, gg), gg) = meds_lb(gg);
    un_mid(bad_idx(:, gg), gg) = meds_mid(gg);
    un_ub(bad_idx(:, gg), gg) = meds_ub(gg);
end
%%
save underreporting_facts.mat un_lb un_ub un_mid