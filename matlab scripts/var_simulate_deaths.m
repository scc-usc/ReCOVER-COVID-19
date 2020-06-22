function [pred_deaths] = var_simulate_deaths(data_4, beta_all_cell, k_l, jp_l, horizon, base_deaths)
    %SIMULATE_PRED Summary of this function goes here
    %   Detailed explanation goes here
    num_countries = size(data_4, 1);
    maxt = size(data_4, 2);
    pred_deaths = zeros(num_countries, horizon);

        
    if length(jp_l) == 1
        jp_l = ones(num_countries, 1)*jp_l;
    end
    
    if length(k_l) == 1
        k_l = ones(num_countries, 1)*k_l;
    end
    
    deldata = diff(data_4')';
    
    for j=1:num_countries
        jp = jp_l(j);
        k = k_l(j);
    
        jk = jp*k;
        %lag = 7;
        lag = 0;
        jk = jk + lag;
        X = zeros(maxt - jk - 1, k);
        Ikt = zeros(1,k);
        for t = jk+1:maxt-1
            Ikt1 = deldata(:, t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(Ikt1(j, (kk-1)*jp+1 : kk*jp), 2);
            end
            X(t-jk, :) = [Ikt] ;
            new_deaths = sum(beta_all_cell{j}'.*X(t-jk, :), 2);
            
            pred_deaths(j, t-jk) = base_deaths(j) + new_deaths;
            base_deaths(j) = pred_deaths(j, t-jk);
        end
    end
    
    
    
    
    
    
  