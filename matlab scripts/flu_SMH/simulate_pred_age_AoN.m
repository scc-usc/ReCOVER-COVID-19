function [pred_deaths, pred_new_deaths_ag] = simulate_pred_age_AoN(all_del_data, immune_infec, rel_lineage_rates, P_ag, beta_all_cell, k_l, jp_l, horizon, base_deaths, T_start, rate_change_ag, M_0, vac_ag, un_ag, popu_ag, IC,t_prime)
%SIMULATE_PRED Summary of this function goes here
%   Detailed explanation goes here

num_countries = size(all_del_data , 1);
nl = size(all_del_data, 2);
maxt = size(all_del_data, 3);
ag = size(all_del_data, 4);
m= maxt;
current_data = datetime(2021,9,1) + days(size(all_del_data,3));
% overlap = days(current_data - datetime(2022,8,8))+1;
% vac_ag = vac_ag(:,1:horizon+overlap,:);
overlap = 0;
%%% Updated %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if maxt < T_start+horizon
	temp = all_del_data;
	all_del_data = zeros(num_countries, nl, T_start+horizon, ag);
    vac_data = zeros(num_countries, T_start+horizon, ag);
    vac_data(:,maxt-overlap+1:end,:) = vac_ag(:, 1:horizon, :);
	all_del_data(:, :, 1:maxt, :) = temp;
	maxt = T_start + horizon;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pred_deaths = zeros(num_countries, horizon);
pred_new_deaths_ag = zeros(num_countries, horizon, ag);

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

if size(rel_lineage_rates, 1) < num_countries
    rel_lineage_rates = rel_lineage_rates(:)'; % converting to row matrix
    rel_lineage_rates = repmat(rel_lineage_rates, [num_countries, 1]);
end

if size(M_0, 1) == 1
    M_0 = repmat(M_0, [num_countries 1]);
end

for g = 1:ag
    
    P = P_ag(g, :);
    
    % Pad rate_change in case the horizon is longer than rates available
    rate_change = squeeze(rate_change_ag(:, 1:horizon, g));
%     rate_change = movmean([rate_change repmat(rate_change(:, end), ...
%         [1 horizon-size(rate_change, 2)+10])], 14);
    
    for j=1:num_countries

        if sum(beta_all_cell{j, g})==0
            pred_deaths(j, :) = base_deaths(j);
            pred_new_deaths_ag(j, :, g) = 0;
            continue;
        end
        death_data = cumsum(squeeze(all_del_data),2);% Maybe - that of T_start
        death_data = squeeze(death_data(:,:,g));
        death_data = death_data-death_data(:,T_start-1);

        del_data = squeeze(all_del_data(j, :, :, g))';
        reinfec_popu = squeeze(immune_infec(j, :, :, g))';

        jp = jp_l(j);
        k = k_l(j);
        
        jk = jp*k;

        Ikt = zeros(1,k); %Ikt1 = zeros(1,jk);
        flag = 0;
        count = 0;
        t_window = T_start + [(1+t_prime(j, g)):(size(IC, 2) + t_prime(j, g))];
        insert_val = squeeze(IC(j, :, g));
        if all(t_window < T_start+horizon)
            del_data(:, t_window) = del_data(:, t_window) + insert_val;
        end

        
        for t = T_start:maxt-1
%             if flag 
%                 count = count +1;
%                 if count<14
%                     continue;
%                 else
%                     flag = 0;
%                 end
%             end
            Ikt1 = del_data(:, t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(rel_lineage_rates(j, :)*Ikt1(:, (kk-1)*jp+1 : kk*jp) +...
                    (1 - P - rel_lineage_rates(j, :))*reinfec_popu(:, (kk-1)*jp+1 : kk*jp), 2);
            end
 
            if(isnan(vac_data(j, t-1, g)))
                vac_data(j, t-1, g) = 0;
            end
            M = (M_0(j, g)) + (death_data(j, t-1).*un_ag(g) + vac_data(j, t-1, g))./popu_ag(j,g);
            X = (1 - M)*Ikt;
            
            new_deaths = rate_change(j, t-T_start+1)*sum(beta_all_cell{j, g}'.*X, 2);
            new_deaths = (new_deaths+abs(new_deaths))/2; % If negative, replace it with zero
            if(isnan(new_deaths))
               new_deaths = 0;
               continue;
            end
            pred_new_deaths_ag(j, t-T_start+1, g) = new_deaths;
%             if new_deaths < IC(j, end) && t > t_window(1)
%                 del_data(:, t+1:t+length(IC(j, :))) = IC(j, :);
%             end
           
            %%% Updated %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            death_data(j, t) = death_data(j, t-1) + new_deaths;
            del_data(:, t) = del_data(:, t) + rel_lineage_rates(j,:).*new_deaths;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
end
pred_new_deaths_ag = pred_new_deaths_ag(:,1:horizon,:);
pred_deaths = base_deaths + cumsum(squeeze(sum(pred_new_deaths_ag(:,1:horizon,:), 3)), 2);
end












