function [pred_deaths, pred_new_deaths_ag] = simulate_deaths_escape(all_del_data, immune_infec, rel_lineage_rates, P_ag, beta_all_cell, k_l, jp_l, horizon, base_deaths, T_start, rate_change_ag)
%SIMULATE_PRED Summary of this function goes here
%   Detailed explanation goes here

num_countries = size(all_del_data , 1);
nl = size(all_del_data, 2);
maxt = size(all_del_data, 3);
ag = size(all_del_data, 4);
pred_deaths = zeros(num_countries, horizon);
pred_new_deaths_ag = zeros(num_countries, horizon, ag);

if length(base_deaths) == 1
    temp = base_deaths;
    base_deaths  = zeros(num_countries, 1);
    base_deaths(:) = temp;
end

if nargin < 11
    rate_change_ag = ones(num_countries, horizon, ag);
end

if length(jp_l) == 1
    jp_l = ones(num_countries, 1)*jp_l;
end

if length(k_l) == 1
    k_l = ones(num_countries, 1)*k_l;
end

if length(P_ag) == 1
    P_ag = repmat(P_ag, [ag nl]);
end

if length(rel_lineage_rates)<2
    rel_lineage_rates = ones(num_countries, nl);
end

if size(rel_lineage_rates, 1) ~= num_countries
    rel_lineage_rates = rel_lineage_rates(:)'; % converting to row matrix
    rel_lineage_rates = repmat(rel_lineage_rates, [num_countries, 1]);
end


for g = 1:ag
    
    P = P_ag(g, :);
    
    % Pad rate_change in case the horizon is longer than rates available
    rate_change = squeeze(rate_change_ag(:, :, g));
    rate_change = movmean([rate_change repmat(rate_change(:, end), ...
        [1 horizon-size(rate_change, 2)+10])], 14);
    
    for j=1:num_countries

        if sum(beta_all_cell{j, g})==0
            pred_deaths(j, :) = base_deaths(j);
            pred_new_deaths_ag(j, :, g) = 0;
            continue;
        end

        del_data = squeeze(all_del_data(j, :, :, g));
        reinfec_popu = squeeze(immune_infec(j, :, :, g));

        jp = jp_l(j);
        k = k_l(j);
        
        jk = jp*k;
%         thisT = zeros(jk, k);
%         for kkk=1:k
%             thisT((kkk-1)*jp+1:(kkk)*jp, kkk) = 1;
%         end
        Ikt = zeros(1,k); %Ikt1 = zeros(1,jk);
        for t = T_start:maxt-1
            Ikt1 = del_data(:, t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(rel_lineage_rates(j, :)*Ikt1(:, (kk-1)*jp+1 : kk*jp) +...
                    (1 - P - rel_lineage_rates(j, :))*reinfec_popu(:, (kk-1)*jp+1 : kk*jp), 2);
            end
            X = Ikt ;
            new_deaths = rate_change(j, t-T_start+1)*sum(beta_all_cell{j, g}'.*X, 2);
            new_deaths = (new_deaths+abs(new_deaths))/2; % If negative, replace it with zero
            pred_new_deaths_ag(j, t-T_start+1, g) = new_deaths;
        end
    end
end
pred_deaths = base_deaths + cumsum(squeeze(sum(pred_new_deaths_ag, 3)), 2);