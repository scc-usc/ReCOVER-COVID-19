function [all_betas, immune_infec, ALL_STATS] = state_space(all_vars_data, popu, un_fact, ...
    vac_ag, ag_case_frac, ag_popu_frac, waned_impact, booster_age, booster_delay, ...
    rel_vacc_effi, rel_booster_effi, cross_protect, fd_given_by_age, fd_effi)


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

if nargin < 4
    % This needs to be for the whole period, not just for the future
    vac_ag = zeros(num_countries, T, 1);
end

ag = size(vac_ag, 3);
immune_infec = nan(length(popu), nl, T, ag); % Infected but with prior protection

if nargin < 5
    ag_case_frac = ones(num_countries, T, ag)/ag;
end
ag_case_frac(isnan(ag_case_frac)) = 0;
if nargin < 6
    ag_popu_frac = repmat(1/ag, [length(popu) ag]);
end

if nargin < 7
    waned_impact = zeros(T, T, ag);
end

waned_impact = waned_impact(1:T, 1:T, :);

if nargin < 8
    booster_age = zeros(size(vac_ag));
end

if nargin < 9  % booster mean delay from second dose
    booster_delay = 7*30;
end

if nargin < 10
    rel_vacc_effi = ones(nl, 1);
end

if nargin < 11
    rel_booster_effi = ones(nl, 1);
end

if nargin < 12
    cross_protect = ones(nl, nl);
end


if nargin < 13
    fd_given_by_age = nan(size(vac_ag));
    fd_given_by_age(:, 1:end-21, :) = vac_ag(:, 22:end, :);
    fd_given_by_age = fillmissing(fd_given_by_age, 'previous', 2);
end

if nargin < 14
    fd_effi = 0.5;
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

deltemp = zeros(num_countries, nl, T);
deltemp(:, :, 2:T) = diff(all_vars_data, 1, 3);

func1 = @(b, k, ag, S, X)(S'.*((b(k+1:end) * b(k+1:end)') * reshape(X, [ag k]) * b(1:k))');
options = optimoptions('lsqnonlin', 'Display','off');

new_boosters = zeros(num_countries, 1+floor((T-3)/7), ag);
new_vac_ag = zeros(num_countries, 1+floor((T-3)/7), ag);
new_fds = zeros(num_countries, 1+floor((T-3)/7), ag);

new_boosters(:, 2:end, :) = diff(booster_age(:, 3:7:T, :), 1, 2);
new_boosters(new_boosters<0) = 0;
new_vac_ag(:, 2:end, :) = diff(vac_ag(:, 3:7:T, :), 1, 2);
new_vac_ag(new_vac_ag<0) = 0;
new_fds(:, 2:end, :) = diff(fd_given_by_age(:, 3:7:T, :), 1, 2);
new_fds(new_fds<0) = 0;

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
    F = zeros(size(true_counts_ts)); % # new first dose but no 2nd
    VnB = zeros(size(true_counts_ts)); % # new vaccinated but not boosted
    VnBi = zeros(size(true_counts_ts)); % # new vaccinated but not boosted after infection
    Fi = zeros(size(true_counts_ts)); % # new first dose but not 2nd after infection
    B = zeros(size(true_counts_ts)); % # new boosted
    Bi = zeros(size(true_counts_ts)); % # new boosted
    I2 = zeros(size(true_counts_ts)); % # new 2nd+ infections
    Iv = zeros(size(true_counts_ts)); % # new infections after vaxing but not boosting
    If = zeros(size(true_counts_ts)); % # new infections after first dose but not second
    Ib = zeros(size(true_counts_ts)); % # new infections after boosting


    infec_immunity = zeros(size(true_counts_ts));
    vacc_immunity = zeros(size(true_counts_ts));
    mix_immunity = zeros(size(true_counts_ts));
    immune_infec_temp = zeros(size(true_counts_ts));
    Md = nan(nl, T, ag);
    M = zeros(size(true_counts_ts));
    protected_popu_temp = zeros(size(true_counts_ts, 2), size(true_counts_ts, 3));

    idx = find(squeeze(sum(fd_given_by_age(j, :, :), 3))>=1);
    if isempty(idx)
        first_dose_week = T;
    else
        first_dose_week = floor((idx(1)-3)/7);
    end

    for gg = 1:ag
        if ag_popu_frac(j, gg) < 1e-10
            continue;
        end
        coeff = squeeze(waned_impact(3:7:end, 3:7:end, gg));

        I1(:, 1, gg) = true_new_counts_ts(:, 1, gg);

        for tt = 2:size(M, 2)
            %%% Change in immunity:

            % Previously infected person got reinfected
            I1_susc = (1 - cross_protect)*sum(I1(:, 1:tt-1, gg)*(1 - coeff(tt, 1:tt-1)'), 2) + I1(:, 1:tt-1, gg)*coeff(tt, 1:tt-1)';
            I2_susc = (1 - cross_protect)*sum(I2(:, 1:tt-1, gg)*(1 - coeff(tt, 1:tt-1)'), 2) + I2(:, 1:tt-1, gg)*coeff(tt, 1:tt-1)';
            I_I = true_new_counts_ts(:, tt, gg) .* (I1_susc + I2_susc)./(ag_popu_frac(j, gg)*popu(j));
            I_I_change = I_I.*coeff(tt, 1:tt-1)./sum(coeff(tt, 1:tt-1) + 1e-20);
            %%% came from I1?
            I1(:, 1:tt-1, gg)  = max(0, I1(:, 1:tt-1, gg) - I_I_change.*(I1_susc./sum(I1_susc+I2_susc + 1e-20)));
            %%% came from I2?
            I2(:, 1:tt-1, gg)  = max(0, I2(:, 1:tt-1, gg) - I_I_change.*(I2_susc./sum(I1_susc+I2_susc + 1e-20)));
            I2(:, tt, gg) = I_I;


            if tt >= first_dose_week  % Vaccine related transistions will happen only after first day of first dose

                % Previously infected person got first dose
                I_V = new_fds(j, tt, gg) * sum(I1(:, 1:tt-1, gg) + I2(:, 1:tt-1, gg), 2)./(ag_popu_frac(j, gg)*popu(j));
                I_V_change_1 = I_V.*I1(:, 1:tt-1, gg)./sum(1e-20 + I1(:, 1:tt-1, gg) + I2(:, 1:tt-1, gg), 2);
                I_V_change_2 = I_V.*I2(:, 1:tt-1, gg)./sum(1e-20 + I1(:, 1:tt-1, gg) + I2(:, 1:tt-1, gg), 2);
                Fi(:, tt, gg) = I_V;
                %                 I1(:, 1:tt-1, gg)  = max(0, I1(:, 1:tt-1, gg) - I_V_change_1);
                %                 I2(:, 1:tt-1, gg)  = max(0, I2(:, 1:tt-1, gg) - I_V_change_2);
                I1(:, 1:tt-1, gg) = takeaway( I1(:, 1:tt-1, gg), I_V_change_1, 1);
                I2(:, 1:tt-1, gg) = takeaway( I2(:, 1:tt-1, gg), I_V_change_2, 1);

                % Previously vaccinated got boosted
                if tt > (booster_delay+30)/7
                    pp = 1:floor(tt-(booster_delay-120)/7);
                    a = VnBi(:, pp ,gg); sa = sum(a, 2);
                    b = VnB(1, pp,gg); sb = sum(b, 2);% The first dim of VnB is redunadant
                    %%% previously infected?
                    Bi(:, tt, gg) = new_boosters(j, tt, gg).* sa./(sum(sa)+sb + 1e-20);
                    %VnBi(:, pp, gg) = max(0, VnBi(:, pp, gg) - new_boosters(j, tt, gg).* a./(sa+sb + 1e-20));
                    VnBi(:, pp, gg) = takeaway(VnBi(:, pp, gg), new_boosters(j, tt, gg).* a./(sa+sb + 1e-20), 0);
                    %%% previously not infected?
                    B(:, tt, gg) = (new_boosters(j, tt, gg)) .* sb./(sum(sa)+sb + 1e-20);
                    %VnB(:, pp, gg) = max(0, VnB(:, pp, gg) - new_boosters(j, tt, gg).* b./(sa+sb + 1e-20));
                    VnB(1, pp, gg) = takeaway(VnB(1, pp, gg), new_boosters(j, tt, gg).* b./(sum(sa)+sb + 1e-20), 0);
                    VnB(:, pp, gg) = repmat(VnB(1, pp, gg), [nl 1]);
                end

                % Previously first dosed but not second, got infected
                %%% first time?
                a = (1-fd_effi*rel_vacc_effi).*F(1, 1:tt-1, gg).*(1-coeff(tt, 1:tt-1)); sa = sum(a, 1);
                b = F(1, 1:tt-1, gg).*coeff(tt, 1:tt-1); sb = sum(b);
                susc = sum(sa) + sb;
                VnB_I = true_new_counts_ts(:, tt, gg).*susc./(ag_popu_frac(j, gg)*popu(j));
                VnB_I_change = sum(VnB_I, 1).*(sa+b)./(1e-20 + sum(sa)+b);
                If(:, tt, gg) = VnB_I;
                %F(:, 1:tt-1, gg) = max(0, F(:, 1:tt-1, gg) - VnB_I_change);
                F(1, 1:tt-1, gg) = takeaway(F(1, 1:tt-1, gg), VnB_I_change, 0);
                F(:, 1:tt-1, gg) = repmat(F(1, 1:tt-1, gg), [nl 1]);
                %%% not the first time
                susc = min((1 - cross_protect)*If(:, 1:tt-1, gg).*(1-coeff(tt, 1:tt-1)) + If(:, 1:tt-1, gg).*coeff(tt, 1:tt-1), ...
                    (1-fd_effi*rel_vacc_effi).*sum(If(:, 1:tt-1, gg), 1).*(1-coeff(tt, 1:tt-1)) + sum(If(:, 1:tt-1, gg), 1).*coeff(tt, 1:tt-1));
                VnB_I = true_new_counts_ts(:, tt, gg).*sum(susc, 2)./(ag_popu_frac(j, gg)*popu(j));
                VnB_I_change = VnB_I.*susc./(sum(susc, 2) + 1e-20);
                If(:, tt, gg) = If(:, tt, gg) + VnB_I;
                %If(:, 1:tt-1, gg) = max(0, If(:, 1:tt-1, gg) - VnB_I_change);
                If(:, 1:tt-1, gg) = takeaway(If(:, 1:tt-1, gg), VnB_I_change, 0);

                % Previously vaccinated but not boosted got infected
                %%% first time?
                a = (1-rel_vacc_effi).*VnB(1, 1:tt-1, gg).*(1 - coeff(tt, 1:tt-1)); sa = sum(a, 1);
                b = VnB(1, 1:tt-1, gg).*coeff(tt, 1:tt-1); sb = sum(b);
                susc = sum(sa) + sb;
                VnB_I = true_new_counts_ts(:, tt, gg).*susc./(ag_popu_frac(j, gg)*popu(j));
                VnB_I_change = sum(VnB_I, 1).*(sa+b)./(1e-20 + sum(sa)+b);
                Iv(:, tt, gg) = VnB_I;
                %VnB(:, 1:tt-1, gg) = max(0, VnB(:, 1:tt-1, gg) - VnB_I_change);
                VnB(1, 1:tt-1, gg) = takeaway(VnB(1, 1:tt-1, gg), VnB_I_change, 0);
                VnB(:, 1:tt-1, gg) = repmat(VnB(1, 1:tt-1, gg), [nl 1]);
                %%% not the first time
                susc = min((1 - cross_protect)*Iv(:, 1:tt-1, gg).*(1-coeff(tt, 1:tt-1)) + Iv(:, 1:tt-1, gg).*coeff(tt, 1:tt-1), ...
                    (1-rel_vacc_effi).*sum(Iv(:, 1:tt-1, gg), 1).*(1-coeff(tt, 1:tt-1)) + sum(Iv(:, 1:tt-1, gg), 1).*coeff(tt, 1:tt-1));
                VnB_I = true_new_counts_ts(:, tt, gg).*sum(susc, 2)./(ag_popu_frac(j, gg)*popu(j));
                VnB_I_change = VnB_I.*susc./(sum(susc, 2) + 1e-20);
                Iv(:, tt, gg) = Iv(:, tt, gg) + VnB_I;
                %Iv(:, 1:tt-1, gg) = max(0, Iv(:, 1:tt-1, gg) - VnB_I_change);
                Iv(:, 1:tt-1, gg) = takeaway(Iv(:, 1:tt-1, gg), VnB_I_change, 0);

                % Previously boosted got infected
                a = (1-rel_booster_effi).*B(1, 1:tt-1, gg).*(1-coeff(tt, 1:tt-1)); sa = sum(a, 2);
                b = B(1, 1:tt-1, gg).*coeff(tt, 1:tt-1); sb = sum(b);
                susc = sa + sb;
                B_I = true_new_counts_ts(:, tt, gg).*susc./(ag_popu_frac(j, gg)*popu(j));
                B_I_change = (B_I.*(a+b))./(sa+sb + 1e-20);
                Ib(:, tt, gg) = VnB_I;
                B(1, 1:tt-1, gg) = takeaway(B(1, 1:tt-1, gg), sum(B_I_change, 1));
                B(:, 1:tt-1, gg) = repmat(B(1, 1:tt-1, gg), [nl 1]);
                %%% not the first time
                susc = min((1 - cross_protect)*Ib(:, 1:tt-1, gg).*(1-coeff(tt, 1:tt-1)) + Ib(:, 1:tt-1, gg).*coeff(tt, 1:tt-1), ...
                    (1-rel_vacc_effi).*sum(Ib(:, 1:tt-1, gg), 1).*(1-coeff(tt, 1:tt-1)) + sum(Ib(:, 1:tt-1, gg), 1).*coeff(tt, 1:tt-1));
                B_I = true_new_counts_ts(:, tt, gg).*sum(susc, 2)./(ag_popu_frac(j, gg)*popu(j));
                B_I_change = B_I.*susc./(sum(susc, 2) + 1e-20);
                Ib(:, tt, gg) = Ib(:, tt, gg) + B_I;
                Ib(:, 1:tt-1, gg) = takeaway(Ib(:, 1:tt-1, gg), B_I_change);

                % A first dose got 2nd dose (could have been infected before!)
                full_delay = 14;
                if tt > (full_delay+30)/7
                    pp = first_dose_week:floor(tt-(full_delay)/7);
                    a = Fi(:, pp ,gg); sa = sum(a, 2);
                    b = F(1, pp,gg); sb = sum(b, 2);% The first dim of F is redunadant
                    %%% previously infected?
                    VnBi(:, tt, gg) = new_vac_ag(j, tt, gg).* sa./(sum(sa)+sb + 1e-20);
                    Fi(:, pp, gg) = takeaway(Fi(:, pp, gg), new_vac_ag(j, tt, gg).* a./(sa+sb + 1e-20));
                    %%% previously not infected?
                    VnB(:, tt, gg) = (new_vac_ag(j, tt, gg)) .* sb./(sum(sa)+sb + 1e-20);
                    F(1, pp, gg) = takeaway(F(1, pp, gg), new_vac_ag(j, tt, gg).* b./(sum(sa)+sb + 1e-20));
                    F(:, pp, gg) = repmat(F(1, pp, gg), [nl 1]);
                end

                % A naive first dose: note -- creates redundant entries
                F(:, tt, gg) = (new_fds(j, tt, gg))*(1 - sum(sum(I1(:, 1:tt, gg)+I2(:, 1:tt, gg)))./(ag_popu_frac(j, gg)*popu(j)));

            end


            % Naive new infections
            I1(:, tt, gg) = max(0, true_new_counts_ts(:, tt, gg) - I2(:, tt, gg) - Iv(:, tt, gg)- Ib(:, tt, gg)- If(:, tt, gg));



            infec_immunity(:, tt, gg) = (cross_protect*(I1(:, 1:tt, gg)+I2(:, 1:tt, gg)))*(1-coeff(tt, 1:tt)');
            vacc_immunity(:, tt, gg) = (rel_vacc_effi.*VnB(1, 1:tt, gg) + rel_booster_effi.*B(1, 1:tt, gg)...
                + fd_effi*rel_vacc_effi.*F(1, 1:tt, gg))*(1-coeff(tt, 1:tt)');
            mix_immunity(:, tt, gg) = (max(rel_vacc_effi.*sum(VnBi(:, 1:tt, gg), 1), cross_protect*VnBi(:, 1:tt, gg)) ...
                + max(rel_booster_effi.*sum(Bi(:, 1:tt, gg), 1), cross_protect*Bi(:, 1:tt, gg))...
                + max(rel_booster_effi.*sum(Ib(:, 1:tt, gg), 1), cross_protect*Ib(:, 1:tt, gg))...
                + max(fd_effi*rel_vacc_effi.*sum(Fi(:, 1:tt, gg), 1), cross_protect*Fi(:, 1:tt, gg))...
                + max(fd_effi*rel_vacc_effi.*sum(If(:, 1:tt, gg), 1), cross_protect*If(:, 1:tt, gg))...
                + max(rel_vacc_effi.*sum(Iv(:, 1:tt, gg), 1), cross_protect*Iv(:, 1:tt, gg))...
                + max(rel_vacc_effi.*sum(VnBi(:, 1:tt, gg), 1), cross_protect*VnBi(:, 1:tt, gg))...
                )*(1-coeff(tt, 1:tt)');


            M(:, tt, gg) = (infec_immunity(:, tt, gg) + vacc_immunity(:, tt, gg) + mix_immunity(:, tt, gg))./(popu(j));
            % Infected today after a prior infection, vaxing or boosting
            immune_infec_temp(:, tt, gg) = I2(:, tt, gg)+ Iv(:, tt, gg) + Ib(:, tt, gg) + If(:, tt, gg);
            protected_popu_temp(tt, gg) = (sum(I1(:, 1:tt,gg) + I2(:, 1:tt, gg)+ Iv(:, 1:tt, gg) + Ib(:, 1:tt, gg) + If(:, 1:tt, gg) ...
                + VnBi(:, 1:tt, gg) + Bi(:, 1:tt, gg) + Fi(:, 1:tt, gg), 'all') - sum(I1(:, tt, gg), 'all') + ...
                + sum(VnB(1, 1:tt, gg) + B(1, 1:tt, gg) + F(1, 1:tt, gg), 'all'))./(popu(j)*ag_popu_frac(j, gg));
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
    ALL_STATS(j).VnB = VnB;
    ALL_STATS(j).Iv = Iv;
    ALL_STATS(j).Ib = Ib;
    ALL_STATS(j).If = If;
    ALL_STATS(j).VnBi = VnBi;
    ALL_STATS(j).Fi = Fi;
    ALL_STATS(j).F = F;
    ALL_STATS(j).B = B;
    ALL_STATS(j).Bi = Bi;
    ALL_STATS(j).immune_infec_temp = immune_infec_temp;
    ALL_STATS(j).protected_popu_temp = protected_popu_temp;
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