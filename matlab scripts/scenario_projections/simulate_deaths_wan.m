function [pred_deaths, pred_new_deaths_ag] = simulate_deaths_wan(data_4_ag, reinfec_frac_ag, P_ag, beta_all_cell, k_l, jp_l, horizon, base_deaths, T_start, rate_change_ag)
%SIMULATE_PRED Summary of this function goes here
%   Detailed explanation goes here

num_countries = size(data_4_ag, 1);
maxt = size(data_4_ag, 2);
ag = size(data_4_ag, 3);
pred_deaths = zeros(num_countries, horizon);
pred_new_deaths_ag = zeros(num_countries, horizon, ag);

if nargin < 8
    rate_change_ag = ones(num_countries, horizon, ag);
end

if length(jp_l) == 1
    jp_l = ones(num_countries, 1)*jp_l;
end

if length(k_l) == 1
    k_l = ones(num_countries, 1)*k_l;
end

if length(P_ag) == 1
    P_ag = repmat(P_ag, [ag 1]);
end

for g = 1:ag
    data_4 = squeeze(data_4_ag(:, :, g));
    reinfec_frac = squeeze(reinfec_frac_ag(:, :, ag));
    P = P_ag(g);
    
    deldata = diff(data_4')';
    delre = diff(reinfec_frac')';
    % Pad rate_change in case the horizon is longer than rates available
    rate_change = squeeze(rate_change_ag(:, :, g));
    rate_change = movmean([rate_change repmat(rate_change(:, end), ...
        [1 horizon-size(rate_change, 2)+1])], 14);
    
    for j=1:num_countries

        if sum(beta_all_cell{j, g})==0
            pred_deaths(j, :) = base_deaths(j);
            pred_new_deaths_ag(j, :, g) = 0;
            continue;
        end
        jp = jp_l(j);
        k = k_l(j);
        
        jk = jp*k;
        thisT = zeros(jk, k);
        for kkk=1:k
            thisT((kkk-1)*jp+1:(kkk)*jp, kkk) = 1;
        end
        %Ikt = zeros(1,k); Ikt1 = zeros(1,jk);
        for t = T_start:maxt-1
            Ikt = [deldata(j, t-jk:t-1).*(1 - P*delre(j, t-jk:t-1))]*thisT;
            X = Ikt ;
            new_deaths = rate_change(j, t-T_start+1)*sum(beta_all_cell{j, g}'.*X, 2);
            new_deaths = (new_deaths+abs(new_deaths))/2; % If negative, replace it with zero
            pred_new_deaths_ag(j, t-T_start+1, g) = new_deaths;
        end
    end
end
pred_deaths = base_deaths + cumsum(squeeze(sum(pred_new_deaths_ag, 3)), 2);







