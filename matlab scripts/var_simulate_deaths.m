function [pred_deaths] = var_simulate_deaths(data_4, beta_all_cell, k_l, jp_l, horizon, base_deaths, T_start)
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
        
        if sum(beta_all_cell{j})==0
            pred_deaths(j, :) = base_deaths(j);
            continue;
        end
        jp = jp_l(j);
        k = k_l(j);
    
        jk = jp*k;
        %lag = 7;
        lag = 0;
        jk = jk + lag;
        
        Ikt = zeros(1,k);
        for t = T_start:maxt-1
            Ikt1 = deldata(j, t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp), 2);
            end
            X = [Ikt] ;
            new_deaths = sum(beta_all_cell{j}'.*X, 2);
            
            new_deaths = (new_deaths+abs(new_deaths))/2; % If negative, replace it with zero
            
            pred_deaths(j, t-T_start+1) = base_deaths(j) + new_deaths;
            base_deaths(j) = pred_deaths(j, t-T_start+1);
        end
    end
    
    
    
    
    
    
  