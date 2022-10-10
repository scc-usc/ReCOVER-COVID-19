function [all_betas, all_cont, fittedC, immune_infec, ALL_STATS] = Sp_multivar_beta_escape(all_vars_data, F, popu, k_l, alpha_l, ...
    jp_l, un_fact, ag_case_frac, ag_popu_frac, waned_impact, booster_age, booster_delay, ...
    rel_booster_effi, cross_protect, rlag)


num_countries = size(all_vars_data, 1);
nl = size(all_vars_data, 2);
T = size(all_vars_data, 3);
opts1=  optimset('display','off');
all_betas = cell(nl, 1);
ALL_STATS = struct;

for l=1:nl
    all_betas{l} = cell(num_countries, 1);
    all_cont{l} = cell(num_countries, 1);
    fittedC{l} = cell(num_countries, 1);
end

if length(alpha_l) == 1
    alpha_l = ones(length(popu), 1)*alpha_l;
end

if nargin < 8
    ag = 1;
    ag_case_frac = ones(num_countries, T, ag)/ag;
end
ag_case_frac(isnan(ag_case_frac)) = 0;

ag = size(ag_case_frac, 3);
immune_infec = nan(length(popu), nl, T, ag); % Infected but with prior protection

if nargin < 9
    ag_popu_frac = repmat(1/ag, [length(popu) ag]);
end

if nargin < 10
    waned_impact = zeros(nl, ceil(T/7)+1, ceil(T/7)+1, ag);
end

%waned_impact = waned_impact(1:T, 1:T, :);

if nargin < 11
    booster_age = zeros(length(popu), T, ag);
end

if nargin < 12  % booster mean delay from previous dose
    booster_delay = 7*30;
end

if nargin < 13
    rel_booster_effi = ones(nl, 1);
end

if nargin < 14
    cross_protect = ones(nl, nl);
end

if nargin < 15
    rlag = 0;
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
        rel_booster_effi{bb} = repmat(rel_booster_effi{bb}, [1 T]);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
deltemp = zeros(num_countries, nl, T);
deltemp(:, :, 2:T) = diff(all_vars_data, 1, 3);

func1 = @(b, k, ag, S, X)(S'.*((b(k+1:end) * b(k+1:end)') * reshape(X, [ag k]) * b(1:k))');
options = optimoptions('lsqnonlin', 'Display','off');

new_boosters = cell(num_boosters, 1);
for bb = 1:num_boosters
    new_boosters{bb} = zeros(num_countries, 1+floor((T-3)/7), ag);
    new_boosters{bb}(:, 2:end, :) = diff(booster_age{bb}(:, 3:7:T, :), 1, 2);
    new_boosters{bb}(new_boosters{bb}<0) = 0;
    rel_booster_effi{bb} = rel_booster_effi{bb}(:,  3:7:end);
end

for j=1:length(popu)
    jp = jp_l(j);
    k = k_l(j);
    jk = jp*k;
    alpha = alpha_l(j);
    skip_days = max(0, T-jk-100);
    alphavec = power(alpha, (T-skip_days - jk-1:-1:1)');
    alphamat = repmat(alphavec, [1 k]);

    this_case_frac = squeeze(ag_case_frac(j, 1:T, :))';
    if ag>1
        true_new_counts_ts = zeros(l, T, ag);
        for gg  = 1:ag
            true_new_counts_ts(:, :, gg) = this_case_frac(gg, :).*[ zeros(nl, 1),  diff(un_fact(j)*squeeze(all_vars_data(j, :, :)), 1, 2)];
        end
    else
        true_new_counts_ts = [ zeros(nl, 1),  diff(un_fact(j)*all_vars_data(j, :, :), 1, 3)];
    end
    %%%%%%%%%%%%%%%% Converting to weekly data for fast processing
    true_counts_ts = cumsum(true_new_counts_ts, 2);
    true_counts_ts = true_counts_ts(:, 3:7:end, :);
    true_new_counts_ts = zeros(size(true_counts_ts));
    for gg  = 1:ag
        true_new_counts_ts(:, :, gg) = [ zeros(nl, 1),  diff(true_counts_ts(:, :, gg), 1, 2)];
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    I1 = zeros(size(true_counts_ts)); % # new first infections naive
    I2 = zeros(size(true_counts_ts)); % # new 2nd+ infections

    Ib = cell(num_boosters, 1); B = cell(num_boosters, 1); Bi = cell(num_boosters, 1);
    for bb = 1:num_boosters
        Ib{bb} = zeros(size(true_counts_ts)); % # new infections after boosting
        B{bb} = zeros(size(true_counts_ts)); % # new boosted
        Bi{bb} = zeros(size(true_counts_ts)); % # new boosted
    end

    infec_immunity = zeros(size(true_counts_ts));
    vacc_immunity = zeros(size(true_counts_ts));
    mix_immunity = zeros(size(true_counts_ts));
    immune_infec_temp = zeros(size(true_counts_ts));
    Md = nan(nl, T, ag);
    M = zeros(size(true_counts_ts));
    protected_popu_temp = zeros(size(true_counts_ts, 2), size(true_counts_ts, 3));

    booster_first_week = zeros(num_boosters, 1);
    for bb=1:num_boosters
        idx = find(squeeze(sum(booster_age{bb}(j, :, :), 3))>=1);
        if isempty(idx)
            booster_first_week(bb) = T;
        else
            booster_first_week(bb) = floor((idx(1)-3)/7);
        end
    end

    for gg = 1:ag
        if ag_popu_frac(j, gg) < 1e-10
            continue;
        end

        I1(:, 1, gg) = true_new_counts_ts(:, 1, gg);
        nv_pop = ag_popu_frac(j, gg)*popu(j) - sum(I1(:, 1, gg), 'all');
        for tt = 2:size(M, 2)
            coeff = squeeze(waned_impact(:, tt, :, gg));
            %%% Change in immunity:
            if tt < booster_first_week(1)  
            % Vaccine related transistions will happen only after first day
            % of first dose. This way, we will save some computation

                % Previously infected person got reinfected
                I1_susc = (1 - cross_protect)*sum(I1(:, 1:tt-1, gg), 2) + cross_protect*I1(:, 1:tt-1, gg).*coeff(:, 1:tt-1);
                I2_susc = (1 - cross_protect)*sum(I2(:, 1:tt-1, gg), 2) + cross_protect*I2(:, 1:tt-1, gg).*coeff(:, 1:tt-1);
                tot_susc = sum(I1_susc, [2, 3]) + sum(I2_susc, [2 3]) + nv_pop;
                
                % Transitions In (who is infected)
                I2(:, tt, gg) = true_new_counts_ts(:, tt, gg) .* sum(I1_susc + I2_susc, 2)./(tot_susc+ 1e-20);
                I1(:, tt, gg) = true_new_counts_ts(:, tt, gg) .* (nv_pop)./(tot_susc+ 1e-20);
                
                % Transitions Out (where did they come from?)
                I1(:, 1:tt-1, gg)  = takeaway(I1(:, 1:tt-1, gg), true_new_counts_ts(:, tt, gg) .* (I1_susc)./(tot_susc+ 1e-20));
                %%% came from I2?
                I2(:, 1:tt-1, gg)  = takeaway(I2(:, 1:tt-1, gg), true_new_counts_ts(:, tt, gg) .* (I2_susc)./(tot_susc+ 1e-20));
                
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
                I2(:, tt, gg) = true_new_counts_ts(:, tt, gg) .* sum(I1_susc + I2_susc, 2)./(tot_susc+ 1e-20);
                I1(:, tt, gg) = true_new_counts_ts(:, tt, gg) .* (nv_pop)./(tot_susc+ 1e-20);
                
                % Transitions Out (where did they come from?)
                I1(:, 1:tt-1, gg)  = takeaway(I1(:, 1:tt-1, gg), true_new_counts_ts(:, tt, gg) .* (I1_susc)./(tot_susc+ 1e-20));
                %%% came from I2?
                I2(:, 1:tt-1, gg)  = takeaway(I2(:, 1:tt-1, gg), true_new_counts_ts(:, tt, gg) .* (I2_susc)./(tot_susc+ 1e-20));
                
                nv_pop = takeaway(nv_pop, sum(I1(:, tt, gg), 'all'));

                for bb=1:num_boosters
                     % Transitions In (who is infected)
                    Ib{bb}(:, tt, gg) = true_new_counts_ts(:, tt, gg) .* sum(susc_B{bb}+susc_Bi{bb}+susc_Ib{bb}, 2)./(tot_susc+ 1e-20);

                    % Transitions Out (where did they come from?)
                    Ib{bb}(:, 1:tt-1, gg)  = takeaway(Ib{bb}(:, 1:tt-1, gg), true_new_counts_ts(:, tt, gg) .* (susc_Ib{bb})./(tot_susc+ 1e-20));
                    Bi{bb}(:, 1:tt-1, gg)  = takeaway(Bi{bb}(:, 1:tt-1, gg), true_new_counts_ts(:, tt, gg) .* (susc_Bi{bb})./(tot_susc+ 1e-20));
                    B{bb}(1, 1:tt-1, gg)  = takeaway(B{bb}(1, 1:tt-1, gg), sum(true_new_counts_ts(:, tt, gg) .* (susc_B{bb})./(tot_susc+ 1e-20), 1));
                    B{bb}(:, 1:tt-1, gg) = repmat(B{bb}(1, 1:tt-1, gg), [nl 1]);
                end


            end


            infec_immunity(:, tt, gg) = sum(cross_protect*(I1(:, 1:tt, gg)+I2(:, 1:tt, gg)) .* (1-coeff(:, 1:tt)), 2);
            vacc_immunity(:, tt, gg) = sum((cell_pw_sum(rel_booster_effi, '.*', B, 1, 1:tt, gg)).*(1-coeff(:, 1:tt)), 2);
            mix_immunity(:, tt, gg) = sum((max(cell_pw_sum(rel_booster_effi, '.*', Bi, 1:nl, 1:tt, gg), cell_pw_sum(cross_protect,'*',Bi,1:nl, 1:tt, gg))...
                + max(cell_pw_sum(rel_booster_effi,'.*',Ib,1:nl, 1:tt, gg), cell_pw_sum(cross_protect,'*',Ib,1:nl, 1:tt, gg))...
                ).*(1-coeff(:, 1:tt)), 2);
%             mix_immunity(:, tt, gg) = (cell_pw_sum(rel_booster_effi, '.*', Bi, 1:nl, 1:tt, gg)...
%                 + cell_pw_sum(cross_protect,'*',Ib,1:nl, 1:tt, gg))*(1-coeff(:, 1:tt)');


            M(:, tt, gg) = (infec_immunity(:, tt, gg) + vacc_immunity(:, tt, gg) + mix_immunity(:, tt, gg))./(popu(j));
            % Infected today after a prior infection, vaxing or boosting
            immune_infec_temp(:, tt, gg) = I2(:, tt, gg) + cell_pw_sum(1, '*',Ib, 1:nl, tt, gg);
            
            M(:, tt, gg) = min(M(:, tt, gg), ag_popu_frac(j, gg).*popu(j));

            protected_popu_temp(tt, gg) = (sum(I1(:, 1:tt,gg) + I2(:, 1:tt, gg)+ cell_pw_sum(1, '*', Ib, 1:nl, 1:tt, gg) ...
                + cell_pw_sum(1, '*', Bi, 1:nl, 1:tt, gg), 'all')  ...
                + sum(cell_pw_sum(1, '*', B, 1, 1:tt, gg), 'all'))./(popu(j)*ag_popu_frac(j, gg));
        end
    end

    Md(:, 3:7:end, :) = M;
    Md = fillmissing(Md, 'linear', 2); Md = fillmissing(Md, 'previous', 2);

    immune_infec(j, :,  3:7:end, :) = cumsum(immune_infec_temp/un_fact(j), 2);
    immune_infec(j, :, :, :) = fillmissing(squeeze(immune_infec(j, :, :, :)), 'linear', 2);
    immune_infec(j, :, :, :) = fillmissing(squeeze(immune_infec(j, :, :, :)), 'previous', 2);
    immune_infec(j, :, 2:end, :) = diff(immune_infec(j, :, :, :), 1, 3);
    ALL_STATS(j).Md = Md;
    ALL_STATS(j).M = M;
    ALL_STATS(j).I1 = I1;
    ALL_STATS(j).I2 = I2;
    ALL_STATS(j).Ib = Ib;
    ALL_STATS(j).B = B;
    ALL_STATS(j).Bi = Bi;
    ALL_STATS(j).immune_infec_temp = immune_infec_temp;
    ALL_STATS(j).protected_popu_temp = protected_popu_temp;

    % Get the contact matrix using the most prevelant variant
    if ag ==2 && ag_popu_frac(j, gg) < 1e-10% This means that the second age group is dummy
        beta_cont = [1; 0];
        C = beta_cont * beta_cont';
    else
        [~, Ml] = max(squeeze(sum(deltemp(j, :, T-13:T), 3)));
        l = Ml;
        all_betas{l}{j} = zeros(k, 1);
        all_cont{l}{j} = zeros(ag, 1);

        y_ag = zeros(T - jk - skip_days - 1, ag);
        X_ag = zeros(T - jk - skip_days - 1, k*ag);
        Smat = y_ag;
        if ag > 1
            thisdel = squeeze(deltemp(j, l, 1:end))'.*this_case_frac(:, 1:end);
        else
            thisdel = squeeze(deltemp(j, l, 1:end))'.*this_case_frac(:, 1:end)';
        end

        for t=(skip_days+jk+1):(T-1-rlag)
            if t<1
                continue;
            end
            Ikt1 = thisdel(:, t-jk:t-1);
            S = ag_popu_frac(j, :)' - squeeze(Md(l, t-1, :));

            neg_S = S<0;
            if length(S)>1 && sum(neg_S) > 0
                S(~neg_S) = S(~neg_S) + sum(abs(S(neg_S)))/(sum(neg_S));
                S(neg_S) = 0;
            end

            Ikt = zeros(ag, k);
            for kk=1:k
                Ikt(:, kk) = sum(Ikt1(:, (kk-1)*jp+1 : kk*jp), 2);
            end
            tt = t-jk-skip_days;
            y_ag(tt, :) = (thisdel(:, t))'.*alphavec(tt);
            Ikt = Ikt.*alphamat(tt, :);
            X_ag(tt, :) = Ikt(:)';
            Smat(tt, :) = S';
        end

        b = lsqnonlin(@(x)(func(x, k, ag, X_ag, Smat)-y_ag), [rand(ag+k-1, 1)], [zeros(ag+k-1, 1)], [inf(k+ag-1, 1)], options);
        beta_vec = b(1:k);
        beta_cont = [b(k+1:end); 1];
        C = beta_cont * beta_cont';
    end
    %%%%%%%%%%%% Contact Matrix calculated %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for l = 1:nl
        all_betas{l}{j} = zeros(k, 1);
        all_cont{l}{j} = beta_cont;
        y = zeros(T - jk - skip_days - 1, 1);
        X = zeros(T - jk - skip_days - 1, k);

        if ag > 1
            thisdel = squeeze(deltemp(j, l, 1:end))'.*this_case_frac(:, 1:end);
        else
            thisdel = squeeze(deltemp(j, l, 1:end))'.*this_case_frac(:, 1:end)';
        end

        if all(thisdel < 1)
            continue;
        end
        for t=(skip_days+jk+1):(T-1-rlag)
            Ikt1 = thisdel(:, t-jk:t-1);

            S = ag_popu_frac(j, :)' - squeeze(Md(l, t-1, :));
            neg_S = S<0;
            if length(S)>1 && sum(neg_S) > 0
                S(~neg_S) = S(~neg_S) + sum(abs(S(neg_S)))/(sum(neg_S));
                S(neg_S) = 0;
            end

            Ikt = zeros(ag, k);
            for kk=1:k
                Ikt(:, kk) = sum(Ikt1(:, (kk-1)*jp+1 : kk*jp), 2);
            end
            Xt = S.*(C*(Ikt));
            tt = t-jk-skip_days;

            X(tt, :) = sum(Xt, 1).*alphamat(tt, :) ;
            y(tt) = sum(thisdel(:, t)).*alphavec(tt);

        end

        if ~isempty(X) && ~isempty(y)
            beta_vec =  lsqlin(X, y,[],[],[],[],zeros(k, 1), [], [], opts1);
            all_betas{l}{j} = beta_vec;
            fittedC{l}{j} = [(X./alphamat)*beta_vec y./alphavec];
        end
    end
end
end


function y = func(b, k, ag, X, Smat)
y = zeros(size(X, 1), ag);
C = [b(k+1:end); 1];
C = C * C';
bb = b(1:k);
for i=1:size(X, 1)
    y(i, :) = Smat(i, :).*(C * reshape(X(i, :), [ag k]) * bb)';
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