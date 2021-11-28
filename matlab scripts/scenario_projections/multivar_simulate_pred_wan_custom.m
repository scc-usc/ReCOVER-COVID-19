function [infec, waned_popu, deltemp, reinfec_frac] = multivar_simulate_pred_wan_custom(all_vars_data, F, ...
    all_betas, popu, k_l, horizon, jp_l, un_fact, base_infec, vac_ag, rate_change, ...
    ag_case_frac, ag_popu_frac, waned_impact, ag_wan_lb, all_cont, external_infec_perc, booster_age, booster_delay)

num_countries = size(all_vars_data, 1);
nl = size(all_vars_data, 2);
T = size(all_vars_data, 3);
infec = zeros(num_countries, horizon);

data_4 = squeeze(sum(all_vars_data, 2));

if nargin < 10
    % This needs to be for the whole period, not just for the future
    vac_ag = zeros(num_countries, T+horizon, 1);
end
vac_ag = vac_ag(:, 1:T+horizon, :);

ag = size(vac_ag, 3);
reinfec_frac = zeros(num_countries, T+horizon, ag);

if nargin < 12
    ag_case_frac = ones(num_countries, T, ag)/ag;
end
ag_case_frac(isnan(ag_case_frac)) = 0;

if nargin < 13
    ag_popu_frac = repmat(1/ag, [length(popu) ag]);
end

if nargin < 14
    waned_impact = zeros(T+horizon, T+horizon, ag);
end
waned_impact = waned_impact(1:T+horizon, 1:T+horizon, :);

if nargin < 15
    ag_wan_lb = ones(ag, 1);
end

if nargin < 16
    all_cont = cell(nl, 1);
    for l=1:nl
        all_cont{l} = cell(num_countries, 1);
        for i = 1:num_countries
            all_cont{l}{i} = ones(ag, ag);
        end
    end
end

if nargin < 17
    external_infec_perc = zeros(num_countries, nl, horizon, ag);
end

if length(external_infec_perc)==1   % If improper size provided, consider it zero
    external_infec_perc = zeros(num_countries, nl, horizon, ag);
end

if nargin < 11
    rate_change = ones(num_countries, horizon);
end

if nargin < 9
    base_infec = data_4(:, end);
end

if isempty(rate_change)
    rate_change = ones(num_countries, horizon);
end

if length(un_fact)==1
    un_fact = un_fact*ones(length(popu), 1);
end

if length(jp_l) == 1
    jp_l = ones(length(popu), 1)*jp_l;
end

if length(k_l) == 1
    k_l = ones(length(popu), 1)*k_l;
end

new_boosters = diff(booster_age, 1, 2);
new_boosters(new_boosters<0) = 0;

new_vacc = diff(vac_ag, 1, 2);
new_vacc(new_vacc<0) = 0;

temp = data_4;
deltemp = zeros(num_countries, nl, T+horizon, ag);

waned_popu = zeros(length(popu), T+horizon, ag);

for j=1:length(popu)
    lastinfec = base_infec(j, end);
    jp = jp_l(j);
    k = k_l(j);
    jk = jp*k;
    
    this_case_frac = squeeze(ag_case_frac(j, :, :))';
    if size(this_case_frac, 2) == 1
        this_case_frac = this_case_frac';
    end
    true_new_infec_ts = this_case_frac .*[ 0,  diff(un_fact(j)*data_4(j, :))];
    true_new_infec_ts = [true_new_infec_ts, zeros(ag, horizon)];
    true_infec_ts = cumsum(true_new_infec_ts, 2);
    this_vac = squeeze(vac_ag(j, :, :));
    if size(this_vac, 1) > size(this_vac, 2)
        this_vac = this_vac';
    end

    for l=1:nl
        temp = squeeze(ag_case_frac(j, 2:end, :));
        if size(temp, 1) == 1
            temp = temp';
        end
        thisdel = squeeze(diff(all_vars_data(j, l, :), 1, 3)) .* temp;
        deltemp(j, l, 2:T, :) = thisdel;
    end

    M = true_infec_ts/popu(j) + ((1-true_infec_ts./popu(j)) .* this_vac)./popu(j);
    newM = [zeros(ag, 1) diff(M, 1, 2)];
    for idx = 1:ag
        xx = newM(idx, :)';
        %        waned_popu(j, :, idx) = (squeeze(waned_impact(:, :, idx))*xx);
        for t=1:T+horizon
            if t > booster_delay
                xx(t-booster_delay) = xx(t-booster_delay) - new_boosters(j, t-1, idx)/popu(j);
                xx(t) = xx(t) + new_boosters(j, t-1, idx)/popu(j);
            end
            waned_popu(j, t, idx) = (squeeze(waned_impact(t, :, idx))*xx);
        end
    end

    temp = squeeze(waned_popu(j, :, :));
    if ag==1
        temp = temp';
    end
    reinfec_frac(j, :, :) = temp./(1e-50 + M');
    for t=1:horizon
        
        S = ag_popu_frac(j, :)' - (M(:, T+t-1) - squeeze(waned_popu(j, T+t, :)));
        neg_S = S<0;
        if length(S)>1 && sum(neg_S) > 0
            S(~neg_S) = S(~neg_S) + sum(abs(S(neg_S)))/(sum(neg_S));
            S(S<0) = 0;
        end
        nyt_ag = 0;
        prev_new_infec = squeeze(sum(deltemp(j, :, T+t-1, :), 2));
        for l = 1:nl
            C = all_cont{l}{j}*all_cont{l}{j}';
            if sum(all_betas{l}{j}) < 1e-20
                continue;
            end
            
            Ikt1 = squeeze(deltemp(j, l, T+t-jk:T+t-1, :))';
            if all(Ikt1(:)< 1) && l < nl
                continue;
            end
            
            Ikt = zeros(ag, k);
            for kk=1:k
                Ikt(:, kk) = sum(Ikt1(:, (kk-1)*jp+1 : kk*jp), 2);
            end
            Xt = S.*(C*(Ikt));
            yt_ag = rate_change(j, t).*(Xt*(all_betas{l}{j}(1:k)));
            this_external_inf = squeeze(external_infec_perc(j, l, t, :));
            
            yt_external = prev_new_infec(:) .* this_external_inf;
            yt_ag = yt_ag + yt_external;
            
            yt_ag(yt_ag < 0) = 0;
            nyt_ag = nyt_ag + yt_ag(:);
            yt = sum(yt_ag);
            deltemp(j, l, T+t, :) = yt_ag;
            lastinfec = lastinfec + yt;
        end
        true_infec_ts(:, T+t) = true_infec_ts(:, T+t) + un_fact(j)*nyt_ag(:);
        nM = un_fact(j)*nyt_ag(:)/popu(j) + ((1- un_fact(j)*true_infec_ts(:, T+t)/popu(j))...
            .*squeeze(vac_ag(j, T+t, :)-vac_ag(j, T+t-1, :)))./popu(j);
        
        M(:, T+t) = min(1, M(:, T+t-1) + nM); nM = M(:, T+t) - M(:, T+t-1);
        for idx = 1:ag
            %eff_boosters = min(new_boosters(j, T+t-1, idx), new_vacc(j, T+t-1, idx))/popu(j);
            eff_boosters = new_boosters(j, T+t-1, idx)/popu(j);
            rec_imm = (squeeze(waned_impact(T+t:end, T+t-booster_delay, idx)))'*eff_boosters; % removing lost immunity now recovered due to boosters
            lost_imm = (squeeze(waned_impact(T+t:end, T+t-1, idx)))'*(nM(idx) + eff_boosters); % adding lost immunity of newly immune into the future
            waned_popu(j, T+t:end, idx) = waned_popu(j, T+t:end, idx) + lost_imm - rec_imm;     
        end
        infec(j, t) = lastinfec;
        temp = (squeeze(waned_popu(j, T+t, :)));
        reinfec_frac(j, T+t, :) = temp(:)./(M(:, T+t));
    end
end
end

