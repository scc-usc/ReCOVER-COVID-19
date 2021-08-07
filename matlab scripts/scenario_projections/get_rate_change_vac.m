function [rate_change] = get_rate_change_vac(dr_by_age, popu_by_age, vac_effi, vac_given, vacc_given_by_age)
% Output a matrix (one row per region) showing the change in rates because of vaccine
% distribution
% If vaccine distribution over age is not provided, assumes the distribution is from right to left (oldest to yougest)
% If it is provided, still need to provide a dummy vac_given to get the
% number of regions and the horizon
% vacc_given_by_age(:, :, :) is num_reg x horizon x num_age_groups

if nargin < 5
    vacc_given_by_age = [];
end

rate_change = ones(size(vac_given, 1), size(vac_given, 2));
dr_by_age(isnan(dr_by_age)) = 0;
popu_by_age(isnan(popu_by_age)) = 0;
dr_by_age = diag(1./(sum(dr_by_age, 2)+ 1e-10))*dr_by_age;

for j=1:size(vac_given, 2)
    if length(vacc_given_by_age) < 1
     rate_change(:, j) = 1 - (vac_effi)*sum(dr_by_age.*vac_by_age(vac_given(:, j), popu_by_age)./popu_by_age, 2);
    else
     rate_change(:, j) = 1 - (vac_effi)*sum(dr_by_age.*squeeze(vacc_given_by_age(:, j, :))./popu_by_age, 2);   
    end
end

end

function vac_dist = vac_by_age(vac, popu_by_age)
    ng = size(popu_by_age, 2);
    rem_vac = vac;
    for j=ng:-1:1
        vac_dist(:, j) = max([zeros(size(rem_vac)), min([popu_by_age(:, j), rem_vac], [], 2)], [], 2);
        rem_vac = rem_vac - vac_dist(:, j);
    end
end