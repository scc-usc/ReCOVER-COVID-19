function [infec, deltemp, immune_infec, ALL_STATS_new, protected_popu_frac] = Sp_multivar_pred_escape(all_vars_data, F, ...
    all_betas, popu, k_l, horizon, jp_l, un_fact, base_infec, rate_change, ...
    ag_case_frac, ag_popu_frac, waned_impact, all_cont, external_infec_perc, ...
    booster_age, booster_delay, rel_booster_effi, cross_protect, ALL_STAT)

num_countries = size(all_vars_data, 1);
nl = size(all_vars_data, 2);
T = size(all_vars_data, 3);
infec = zeros(num_countries, horizon);
ALL_STATS_new = struct;
data_4 = squeeze(sum(all_vars_data, 2));

if nargin < 9
    base_infec = data_4(:, end);
end

ag = size(ag_case_frac, 3);

immune_infec = nan(num_countries, nl, T+horizon, ag);
protected_popu_frac = nan(num_countries, T+horizon, ag);

if nargin < 10
    rate_change = ones(num_countries, horizon);
end

if nargin < 11
    ag_case_frac = ones(num_countries, T, ag)/ag;
end
ag_case_frac(isnan(ag_case_frac)) = 0;
deltemp = zeros(num_countries, nl, T+horizon, ag);

if nargin < 12
    ag_popu_frac = repmat(1/ag, [length(popu) ag]);
end

if nargin < 13
    waned_impact = zeros(1+ceil(T+horizon)/7, 1+ceil(T+horizon)/7, ag);
end
%waned_impact = waned_impact(1:T+horizon, 1:T+horizon, :);

if nargin < 14
    all_cont = cell(nl, 1);
    for l=1:nl
        all_cont{l} = cell(num_countries, 1);
        for i = 1:num_countries
            all_cont{l}{i} = ones(ag, ag);
        end
    end
end

if nargin < 15
    external_infec_perc = zeros(num_countries, nl, horizon, ag);
end

if nargin < 16
    booster_age = zeros(size(vac_ag));
end

if nargin < 17  % booster mean delay from second dose
    booster_delay = 7*30;
end

if nargin < 18
    rel_booster_effi = ones(nl, 1);
end

if nargin < 19
    cross_protect = ones(nl, nl);
end

recalc_STATUS = 0;
if nargin < 20
    recalc_STATUS = 1;
end

if length(external_infec_perc)==1   % If improper size provided, consider it zero
    external_infec_perc = zeros(num_countries, nl, horizon, ag);
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

if ~iscell(booster_age)
    xx = booster_age;
    booster_age = cell(1,1);
    booster_age{1} = xx;
end

if ~iscell(booster_delay)
    xx = booster_delay;
    booster_delay = cell(1,1);
    booster_delay{1} = xx;
end

if ~iscell(rel_booster_effi)
    xx = rel_booster_effi;
    rel_booster_effi = cell(1,1);
    rel_booster_effi{1} = xx;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_boosters = length(rel_booster_effi); % number of shots in the booster series
for bb = 1:num_boosters
    if size(rel_booster_effi{bb}, 2) == 1
        rel_booster_effi{bb} = repmat(rel_booster_effi{bb}, [1 T+horizon]);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

new_boosters = cell(num_boosters, 1);
for bb = 1:num_boosters
    new_boosters{bb} = zeros(num_countries, 1+floor((T+horizon-3)/7), ag);
    new_boosters{bb}(:, 2:end, :) = diff(booster_age{bb}(:, 3:7:T+horizon, :), 1, 2);
    new_boosters{bb}(new_boosters{bb}<0) = 0;
    rel_booster_effi{bb} = rel_booster_effi{bb}(:,  3:7:end);
end

for j=1:length(popu)
    temp = squeeze(sum(external_infec_perc(j, :, :, :), [1 3 4]));
    is_wild_card = temp > 0;

    lastinfec = base_infec(j, end);
    jp = jp_l(j);
    k = k_l(j);
    jk = jp*k;

    this_case_frac = squeeze(ag_case_frac(j, :, :))';
    if size(this_case_frac, 2) == 1
        this_case_frac = this_case_frac';
    end

    for l=1:nl
        temp = squeeze(ag_case_frac(j, 2:end, :));
        if size(temp, 1) == 1
            temp = temp';
        end
        thisdel = squeeze(diff(all_vars_data(j, l, :), 1, 3)) .* temp;
        deltemp(j, l, 2:T, :) = thisdel;
    end

    %%%% WILL LATER INSERT CODE TO REBUILD ALL_STAR IF NOT PROVIDED
    % For now we will reuse pre_computed values
    Tw = 1 + floor((T+horizon-3)/7);
    I1 = zeros(nl, Tw, ag); % # new first infections naive
    I2 = zeros(nl, Tw, ag);  % # new 2nd+ infections

    Ib = cell(num_boosters, 1); B = cell(num_boosters, 1); Bi = cell(num_boosters, 1);
    for bb = 1:num_boosters
        Ib{bb} = zeros(nl, Tw, ag); % # new infections after boosting
        B{bb} = zeros(nl, Tw, ag); % # new boosted
        Bi{bb} = zeros(nl, Tw, ag); % # new boosted
    end

    M = zeros(nl, Tw, ag);  % Expected immune weekly version
    infec_immunity = zeros(nl, Tw, ag);
    vacc_immunity = zeros(nl, Tw, ag);
    mix_immunity = zeros(nl, Tw, ag);
    immune_infec_temp = zeros(nl, Tw, ag); % New infections who has prior immunity
    protected_popu_temp = zeros(Tw, ag); % Total population with prior protection

    Md = nan(nl, T+horizon, ag);    % Expected imuune daily version

    Twt = 1+floor((T-3)/7);
    I1(:, 1:Twt, :) = ALL_STAT(j).I1;
    I2(:, 1:Twt, :) = ALL_STAT(j).I2;
    for bb=1:num_boosters
        Ib{bb}(:, 1:Twt, :) = ALL_STAT(j).Ib{bb};
        Bi{bb}(:, 1:Twt, :) = ALL_STAT(j).Bi{bb};
        B{bb}(:, 1:Twt, :) = ALL_STAT(j).B{bb};
    end

    M(:, 1:Twt, :) = ALL_STAT(j).M;
    protected_popu_temp(1:Twt, :) = ALL_STAT(j).protected_popu_temp;

    booster_first_week = zeros(num_boosters, 1);
    for bb=1:num_boosters
        idx = find(squeeze(sum(booster_age{bb}(j, :, :), 3))>=1);
        if isempty(idx)
            booster_first_week(bb) = T;
        else
            booster_first_week(bb) = floor((idx(1)-3)/7);
        end
    end


    currentM = squeeze(ALL_STAT(j).Md(:, T, :));
    immune_infec_temp(:, 1:Twt, :) = ALL_STAT(j).immune_infec_temp;
    tempM = currentM*0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for t=1:horizon
        nyt_ag = 0;
        tt = ceil(Twt + t/7);
        prev_new_infec = squeeze(sum(deltemp(j, :, T+t-1, :), 2));
        for l = 1:nl
            C = all_cont{l}{j}*all_cont{l}{j}';
            if sum(all_betas{l}{j}) < 1e-20
                continue;
            end

            S = ag_popu_frac(j, :)' - currentM(l, :)' - tempM(l, :)';
            neg_S = S<0;
            if length(S)>1 && sum(neg_S) > 0
                S(~neg_S) = S(~neg_S) + sum(abs(S(neg_S)))/(sum(neg_S));
                S(S<0) = 0;
            end

            Ikt1 = squeeze(deltemp(j, l, T+t-jk:T+t-1, :))';
            if all(Ikt1(:)< 1) && ~is_wild_card(l)
                continue;
            end

            Ikt = zeros(ag, k);
            for kk=1:k
                Ikt(:, kk) = sum(Ikt1(:, (kk-1)*jp+1 : kk*jp), 2);
            end
            Xt = S.*(C*(Ikt));
            yt_ag = rate_change(j, t).*(Xt*(all_betas{l}{j}(1:k)));
            this_external_inf = squeeze(external_infec_perc(j, l, t, :));

            if this_external_inf > 0 % non-negative indicates relative numbers
                yt_external = ceil(prev_new_infec(:) .* this_external_inf);
            else    % -ve indicates absolute numbers
                yt_external = -this_external_inf;
            end

            yt_ag = yt_ag + yt_external;

            yt_ag(yt_ag < 0) = 0;
            %yt_ag(isnan(yt_ag)) = 0;
            nyt_ag = nyt_ag + yt_ag(:);
            yt = sum(yt_ag);
            deltemp(j, l, T+t, :) = yt_ag;
            lastinfec = lastinfec + yt;
            infec_imm_approx = un_fact(j)*cross_protect(:, l)*yt_ag'./popu(j);
            if tt > Tw
                tt = Tw;
            end
            %             infec_imm_approx = 0;
            booster_imm_approx = 0;
            for bb=1:num_boosters
                booster_imm_approx = rel_booster_effi{bb}(:, tt)*((squeeze(new_boosters{bb}(j, tt, :)/7).*squeeze(waned_impact(l, ceil((T+t)/7), ceil((T+t-booster_delay{bb})/7), :)))')./popu(j);
            end
            tempM = tempM + infec_imm_approx + (1-infec_imm_approx).*booster_imm_approx;
        end
        infec(j, t) = lastinfec;

        if mod(t, 7)==0
            tt = Twt + t/7;
            new_cases_w = un_fact(j)*squeeze(sum(deltemp(j, :, T+t-6:T+t, :), 3));

            for gg = 1:ag
                coeff = squeeze(waned_impact(:, tt, :, gg));
                nv_pop = max(0, ag_popu_frac(j, gg)*popu(j) - protected_popu_temp(tt, gg));
                %%% Change in immunity:
                if tt < booster_first_week(1)
                    % Vaccine related transistions will happen only after first day
                    % of first dose. This way, we will save some computation

                    % Previously infected person got reinfected
                    I1_susc = (1 - cross_protect)*sum(I1(:, 1:tt-1, gg), 2) + cross_protect*I1(:, 1:tt-1, gg).*coeff(:, 1:tt-1);
                    I2_susc = (1 - cross_protect)*sum(I2(:, 1:tt-1, gg), 2) + cross_protect*I2(:, 1:tt-1, gg).*coeff(:, 1:tt-1);
                    tot_susc = sum(I1_susc, [2, 3]) + sum(I2_susc, [2 3]) + nv_pop;

                    % Transitions In (who is infected)
                    I2(:, tt, gg) = new_cases_w(:, gg) .* sum(I1_susc + I2_susc, 2)./(tot_susc+ 1e-20);
                    I1(:, tt, gg) = new_cases_w(:, gg) .* (nv_pop)./(tot_susc+ 1e-20);

                    % Transitions Out (where did they come from?)
                    I1(:, 1:tt-1, gg)  = takeaway(I1(:, 1:tt-1, gg), new_cases_w(:, gg) .* (I1_susc)./(tot_susc+ 1e-20));
                    %%% came from I2?
                    I2(:, 1:tt-1, gg)  = takeaway(I2(:, 1:tt-1, gg), new_cases_w(:, gg) .* (I2_susc)./(tot_susc+ 1e-20));

                    nv_pop = takeaway(nv_pop, sum(I1(:, tt, gg), 'all'));
                else
                    susc_I1 = I1(:, 1:tt, gg); susc_I2 = I2(:, 1:tt, gg);
                    % A naive first dose: note -- creates redundant entries
                    B{1}(:, tt, gg) = (new_boosters{1}(j, tt, gg))*(nv_pop)./(nv_pop+sum(susc_I1+susc_I2, 'all'));
                    % Previously infected person got first dose
                    Bi{1}(:, tt, gg) = new_boosters{1}(j, tt, gg) *sum(susc_I1+susc_I2, 'all')./(nv_pop+sum(susc_I1+susc_I2, 'all'));
                    I1(:, 1:tt-1, gg) = takeaway( I1(:, 1:tt-1, gg), I1(:, 1:tt-1, gg).*sum(susc_I1, 2)/(nv_pop+sum(susc_I1+susc_I2, 'all')));
                    I2(:, 1:tt-1, gg) = takeaway( I2(:, 1:tt-1, gg), I2(:, 1:tt-1, gg).*sum(susc_I2, 2)/(nv_pop+sum(susc_I1+susc_I2, 'all')));
                    nv_pop = takeaway(nv_pop, sum(B{1}(1, tt, gg), 'all'));
                    for bb=2:num_boosters
                        if tt > booster_first_week(bb)
                            % Previously boosted/vaccinated got boosted (again)
                            serial_boost = 0; % if the same time-series encodes multiple boosters
                            if bb == num_boosters
                                serial_boost = 1;
                            end
                            pp = 1:min(floor(tt-(booster_delay{bb}-120)/7), tt-1);
                            a_prev = Bi{bb-1}(:, pp ,gg); a_this = serial_boost*Bi{bb}(:, pp ,gg); sa = sum(a_prev+a_this, 2);
                            b_prev = B{bb-1}(1, pp,gg); b_this = serial_boost*B{bb-1}(1, pp,gg); sb = sum(b_prev+b_this, 2);% The first dim of VnB is redunadant
                            c_prev = Ib{bb-1}(1, pp,gg); c_this = serial_boost*Ib{bb-1}(1, pp,gg); sc = sum(c_prev+c_this, 2);

                            %%% Transition Out
                            %%% previously infected, last action boosting?
                            Bi{bb-1}(:, pp, gg) = takeaway(Bi{bb-1}(:, pp, gg), new_boosters{bb}(j, tt, gg).* a_prev./(sa+sb+sc + 1e-20), 0);
                            Bi{bb}(:, pp, gg) = takeaway(Bi{bb}(:, pp, gg), new_boosters{bb}(j, tt, gg).* a_this./(sa+sb+sc + 1e-20), 0);
                            %%% previously infected, last action infection?
                            Bi{bb-1}(:, pp, gg) = takeaway(Ib{bb-1}(:, pp, gg), new_boosters{bb}(j, tt, gg).* c_prev./(sa+sb+sc + 1e-20), 0);
                            Bi{bb}(:, pp, gg) = takeaway(Ib{bb}(:, pp, gg), new_boosters{bb}(j, tt, gg).* c_this./(sa+sb+sc + 1e-20), 0);
                            %%% previously not infected?
                            B{bb-1}(1, pp, gg) = takeaway(B{bb-1}(1, pp, gg), new_boosters{bb}(j, tt, gg).* b_prev./(sum(sa)+sb+sum(sc) + 1e-20), 0);
                            B{bb}(1, pp, gg) = takeaway(B{bb}(1, pp, gg), new_boosters{bb}(j, tt, gg).* b_this./(sum(sa)+sb+sum(sc) + 1e-20), 0);
                            B{bb-1}(:, pp, gg) = repmat(B{bb-1}(1, pp, gg), [nl 1]);
                            B{bb}(:, pp, gg) = repmat(B{bb}(1, pp, gg), [nl 1]);

                            %%% Transition In
                            %%% previously infected?
                            Bi{bb}(:, tt, gg) = new_boosters{bb}(j, tt, gg).* (sa+sc)./(sum(sa+sc)+sb + 1e-20);
                            %%% previously not infected?
                            B{bb}(:, tt, gg) = (new_boosters{bb}(j, tt, gg)) .* sb./(sum(sa)+sb + 1e-20);
                        end
                    end

                    susc_B = cell(num_boosters); susc_Bi = cell(num_boosters); susc_Ib = cell(num_boosters);
                    tot_susc = 0;
                    for bb=1:num_boosters
                        % No prior infection & prior vaccine (B)
                        susc_B{bb} = (1-rel_booster_effi{bb}(:, 1:tt-1)).*B{bb}(1, 1:tt-1, gg).*(1-coeff(:, 1:tt-1)) + B{bb}(1, 1:tt-1, gg).*coeff(:, 1:tt-1);

                        % Prior infection before prior vaccine (Bi)
                        susc_Bi{bb} = min((1 - cross_protect)*Bi{bb}(:, 1:tt-1, gg).*(1-coeff(:, 1:tt-1)) + Bi{bb}(:, 1:tt-1, gg).*coeff(:, 1:tt-1), ...
                            (1-rel_booster_effi{bb}(:, 1:tt-1)).*sum(Bi{bb}(:, 1:tt-1, gg), 1).*(1-coeff(:, 1:tt-1)) + sum(Bi{bb}(:, 1:tt-1, gg), 1).*coeff(:, 1:tt-1));
                        %susc_Bi{bb} = (1-rel_booster_effi{bb}(:, 1:tt-1)).*sum(Bi{bb}(:, 1:tt-1, gg), 1).*(1-coeff(:, 1:tt-1)) + sum(Bi{bb}(:, 1:tt-1, gg), 1).*coeff(:, 1:tt-1);

                        % Prior infection after prior vaccine (Ib)
                        susc_Ib{bb} = min((1 - cross_protect)*Ib{bb}(:, 1:tt-1, gg).*(1-coeff(:, 1:tt-1)) + Ib{bb}(:, 1:tt-1, gg).*coeff(:, 1:tt-1), ...
                            (1-rel_booster_effi{bb}(:, 1:tt-1)).*sum(Ib{bb}(:, 1:tt-1, gg), 1).*(1-coeff(:, 1:tt-1)) + sum(Ib{bb}(:, 1:tt-1, gg), 1).*coeff(:, 1:tt-1));
                        %susc_Ib{bb} = (1 - cross_protect)*Ib{bb}(:, 1:tt-1, gg).*(1-coeff(:, 1:tt-1)) + Ib{bb}(:, 1:tt-1, gg).*coeff(:, 1:tt-1);

                        tot_susc = tot_susc + sum(susc_B{bb}, [2 3]) + sum(susc_Bi{bb}, [2 3]) + sum(susc_Ib{bb}, [2 3]);
                    end
                    % Previously infected person got reinfected
                    I1_susc = (1 - cross_protect)*sum(I1(:, 1:tt-1, gg), 2) + cross_protect*I1(:, 1:tt-1, gg).*coeff(:, 1:tt-1);
                    I2_susc = (1 - cross_protect)*sum(I2(:, 1:tt-1, gg), 2) + cross_protect*I2(:, 1:tt-1, gg).*coeff(:, 1:tt-1);
                    tot_susc = tot_susc + sum(I1_susc, [2, 3]) + sum(I2_susc, [2 3]) + nv_pop;

                    % Transitions In (who is infected)
                    I2(:, tt, gg) = new_cases_w(:, gg) .* sum(I1_susc + I2_susc, 2)./(tot_susc+ 1e-20);
                    I1(:, tt, gg) = new_cases_w(:, gg) .* (nv_pop)./(tot_susc+ 1e-20);

                    % Transitions Out (where did they come from?)
                    I1(:, 1:tt-1, gg)  = takeaway(I1(:, 1:tt-1, gg), new_cases_w(:, gg) .* (I1_susc)./(tot_susc+ 1e-20));
                    %%% came from I2?
                    I2(:, 1:tt-1, gg)  = takeaway(I2(:, 1:tt-1, gg), new_cases_w(:, gg) .* (I2_susc)./(tot_susc+ 1e-20));

                    nv_pop = takeaway(nv_pop, sum(I1(:, tt, gg), 'all'));

                    for bb=1:num_boosters
                        % Transitions In (who is infected)
                        Ib{bb}(:, tt, gg) = new_cases_w(:, gg) .* sum(susc_B{bb}+susc_Bi{bb}+susc_Ib{bb}, 2)./(tot_susc+ 1e-20);

                        % Transitions Out (where did they come from?)
                        Ib{bb}(:, 1:tt-1, gg)  = takeaway(Ib{bb}(:, 1:tt-1, gg), new_cases_w(:, gg) .* (susc_Ib{bb})./(tot_susc+ 1e-20));
                        Bi{bb}(:, 1:tt-1, gg)  = takeaway(Bi{bb}(:, 1:tt-1, gg), new_cases_w(:, gg) .* (susc_Bi{bb})./(tot_susc+ 1e-20));
                        B{bb}(1, 1:tt-1, gg)  = takeaway(B{bb}(1, 1:tt-1, gg), sum(new_cases_w(:, gg) .* (susc_B{bb})./(tot_susc+ 1e-20), 1));
                        B{bb}(:, 1:tt-1, gg) = repmat(B{bb}(1, 1:tt-1, gg), [nl 1]);
                    end

                    infec_immunity(:, tt, gg) = sum(cross_protect*(I1(:, 1:tt, gg)+I2(:, 1:tt, gg)) .* (1-coeff(:, 1:tt)), 2);
                    vacc_immunity(:, tt, gg) = sum((cell_pw_sum(rel_booster_effi, '.*', B, 1, 1:tt, gg)).*(1-coeff(:, 1:tt)), 2);
                    mix_immunity(:, tt, gg) = sum((max(cell_pw_sum(rel_booster_effi, '.*', Bi, 1:nl, 1:tt, gg), cell_pw_sum(cross_protect,'*',Bi,1:nl, 1:tt, gg))...
                        + max(cell_pw_sum(rel_booster_effi,'.*',Ib,1:nl, 1:tt, gg), cell_pw_sum(cross_protect,'*',Ib,1:nl, 1:tt, gg))...
                        ).*(1-coeff(:, 1:tt)), 2);
                    %mix_immunity(:, tt, gg) = (cell_pw_sum(rel_booster_effi, '.*', Bi, 1:nl, 1:tt, gg)...
                    %+ cell_pw_sum(cross_protect,'*',Ib,1:nl, 1:tt, gg))*(1-coeff(:, 1:tt)');

                    M(:, tt, gg) = (infec_immunity(:, tt, gg) + vacc_immunity(:, tt, gg) + mix_immunity(:, tt, gg))./(popu(j));
                    % Infected today after a prior infection, vaxing or boosting
                    immune_infec_temp(:, tt, gg) = I2(:, tt, gg) + cell_pw_sum(1, '*',Ib, 1:nl, tt, gg);

                    M(:, tt, gg) = min(M(:, tt, gg), ag_popu_frac(j, gg).*popu(j));

                    protected_popu_temp(tt, gg) = (sum(I1(:, 1:tt,gg) + I2(:, 1:tt, gg)+ cell_pw_sum(1, '*', Ib, 1:nl, 1:tt, gg) ...
                        + cell_pw_sum(1, '*', Bi, 1:nl, 1:tt, gg), 'all') ...
                        + sum(cell_pw_sum(1, '*', B, 1, 1:tt, gg), 'all'))./(popu(j)*ag_popu_frac(j, gg));
                end
            end
            currentM = M(:, tt, :);
            tempM = tempM*0;
        end
    end
    Md(:, 3:7:end, :) = M;
    Md = fillmissing(Md, 'linear', 2); Md = fillmissing(Md, 'previous', 2);

    immune_infec(j, :,  3:7:end, :) = cumsum(immune_infec_temp/un_fact(j), 2);
    immune_infec(j, :, :, :) = fillmissing(squeeze(immune_infec(j, :, :, :)), 'linear', 2);
    immune_infec(j, :, :, :) = fillmissing(squeeze(immune_infec(j, :, :, :)), 'previous', 2);
    immune_infec(j, :, 2:end, :) = diff(immune_infec(j, :, :, :), 1, 3);

    protected_popu_frac(j, 3:7:end, :) = protected_popu_temp;
    protected_popu_frac = fillmissing(protected_popu_frac, 'linear', 2);
    protected_popu_frac = fillmissing(protected_popu_frac, 'previous', 2);


    ALL_STATS_new(j).Md = Md;
    ALL_STATS_new(j).M = M;
    ALL_STATS_new(j).I1 = I1;
    ALL_STATS_new(j).I2 = I2;
    ALL_STATS_new(j).Ib = Ib;
    ALL_STATS_new(j).B = B;
    ALL_STATS_new(j).Bi = Bi;
    ALL_STATS_new(j).immune_infec_temp = immune_infec_temp;

end

end

function C = takeaway(A, B, isdebug)
if nargin < 3
    isdebug = 0;
end
C1 = A - B;
if any(C1(:) < -0.1) && isdebug >0
    ;
end
bad_idx = C1 < 0;
res = abs(sum(C1.*bad_idx, 2));
C1(bad_idx) = 0;
cc = sum(C1, 2) + 1e-6;
if all(res < cc)
    C = C1.*( 1 - res./cc);
    return;
end

C = max(0, A-B);

end

function res = cell_pw_sum(coeff, op, B, l_idx, t_idx, g_idx)
% multiplies (op) coeff to each matrix in the cell B and sums
res = zeros(length(l_idx), length(t_idx), length(g_idx));
for bb=1:length(B)
    if iscell(coeff)
        if op == '*'
            res = res + coeff{bb}*B{bb}(l_idx, t_idx, g_idx);
        else
            if size(coeff{bb}, 2) > 1
                res = res + coeff{bb}(l_idx, t_idx).*B{bb}(l_idx, t_idx, g_idx);
            else
                res = res + coeff{bb}.*B{bb}(l_idx, t_idx, g_idx);
            end
        end
    else
        if op == '*'
            res = res + coeff*B{bb}(l_idx, t_idx, g_idx);
        else
            if size(coeff, 2) > 1
                res = res + coeff(l_idx, t_idx).*B{bb}(l_idx, t_idx, g_idx);
            else
                res = res + coeff.*B{bb}(l_idx, t_idx, g_idx);
            end
        end
    end
end
end