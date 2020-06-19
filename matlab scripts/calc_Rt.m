function [Rt, Rt_conf] = calc_Rt(beta_cell, k_l, jp_l, sus_frac, beta_confs)
    
    num_countries = length(beta_cell);
    Rt = zeros(num_countries, 1);
    Rt_conf = zeros(num_countries, 2);
    
    if nargin < 4
        sus_frac = ones(num_countries, 1);
    end
    
    if nargin > 4
        beta_min = cell(num_countries);
        beta_max = cell(num_countries);
        for j=1:num_countries
           beta_min{j} = beta_confs{j}(:, 1);
           beta_max{j} = beta_confs{j}(:, 2);
        end
        Rt1 = calc_Rt(beta_min, k_l, jp_l, sus_frac);
        Rt2 = calc_Rt(beta_max, k_l, jp_l, sus_frac);
        Rt_conf = [Rt1 Rt2];
    end
    
    for j=1:num_countries
        beta = beta_cell{j};
        k  = k_l(j);
        beta = beta(1:k);
        jp = jp_l(j);
        Rt(j) = sus_frac(j) * jp * sum(beta);
    end
end

