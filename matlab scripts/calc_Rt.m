function [Rt] = calc_Rt(beta_cell, k_l, jp_l, sus_frac)
    
    num_countries = length(beta_cell);
    Rt = zeros(num_countries, 1);
    
    if nargin < 4
        sus_frac = ones(num_countries, 1);
    end
    
    for j=1:num_countries
        beta = beta_cell{j};
        k  = k_l(j);
        beta = beta(1:k)';
        jp = jp_l(j);
        Rt(j) = sus_frac(j)*sum([0:k-1].*beta)*jp/k + (jp+1)*sum(beta)/2;
    end
end

