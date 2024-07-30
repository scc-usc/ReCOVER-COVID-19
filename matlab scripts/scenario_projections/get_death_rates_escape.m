function [beta_all_cell, ci, fittedC, Mdl] = get_death_rates_escape(all_del_data, immune_infec, rel_lineage_rates, P_ag, death_data_ag, alpha_l, k_l, jp_l, window_size, ret_conf, compute_region, lags)

% all_del_data: new cases in region 1st dim, caused by 2nd dim at time 3rd dim to
% age group in 4th dim

maxt = size(death_data_ag, 2);
nn = size(death_data_ag, 1);
ag = size(death_data_ag, 3);
nl = size(all_del_data, 2);
beta_all_cell = cell(nn, ag);
ci = cell(nn, ag);
fittedC = cell(nn, ag);
Mdl = cell(nn, ag);

if length(jp_l) == 1
    jp_l = ones(nn, 1)*jp_l;
end

if length(k_l) == 1
    k_l = ones(nn, 1)*k_l;
end

if length(lags) == 1
    lags = ones(nn, 1)*lags;
end

if length(alpha_l) == 1
    alpha_l = ones(nn, 1)*alpha_l;
end

if length(window_size) == 1
    window_size = ones(nn, 1)*window_size;
end

if length(P_ag) == 1
    P_ag = repmat(P_ag, [ag nl]);
end

if length(rel_lineage_rates)<2
    rel_lineage_rates = ones(nn, nl);
end

if size(rel_lineage_rates, 1) ~= nn
    rel_lineage_rates = rel_lineage_rates(:)'; % converting to row matrix
    rel_lineage_rates = repmat(rel_lineage_rates, [nn, 1]);
end




for g = 1:ag
    death_data = squeeze(death_data_ag(:, :, g));
    P = P_ag(g, :);
    new_deaths = diff(death_data')';
    for j=1:nn
        
        jp = jp_l(j);
        k = k_l(j);
        alpha = alpha_l(j);
        jk = jp*k;
        beta_all_cell{j, g} = zeros(k, 1);
        ci{j, g} = [zeros(k, 1) zeros(k, 1)];
        fittedC{j, g} = [0 0];
        
        if compute_region(j) < 1 || death_data(j, end) < 1 || isnan(death_data(j, end))% Do not compute for region that are not specified
            continue;
        end

        skip_days = maxt - window_size(j);
        if skip_days < 0
            skip_days = 0;
        end

        del_data = squeeze(all_del_data(j, :, :, g));
        reinfec_popu = squeeze(immune_infec(j, :, :, g));

        alphavec = power(alpha, (maxt-skip_days - jk-1:-1:1)');
        alphamat = repmat(alphavec, [1 k]);
        y = zeros(maxt - jk - skip_days - 1, 1);
        X = zeros(maxt - jk - skip_days - 1, k);

        if isempty(y)
            continue;
        end

        Ikt = zeros(1,k);
        for t = skip_days+jk+1:maxt-1
            Ikt1 = del_data(:, t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(rel_lineage_rates(j, :)*Ikt1(:, (kk-1)*jp+1 : kk*jp) +...
                    (1 - P - rel_lineage_rates(j, :))*reinfec_popu(:, (kk-1)*jp+1 : kk*jp), 2);
            end
            X(t-jk-skip_days, :) = [Ikt] ;
            y(t-jk-skip_days) = new_deaths(j, t)';
        end
        scalefactor = 1;
        X1 = (alphamat.*X); y1 = scalefactor*(alphavec.*y);

        lag = lags(j);
        k1 = k - lag;
        X1 = X1(:, 1:k1);


        opts1=  optimset('display','off');
        if ret_conf == 0    % If confidence intervals are not required, we will run this as this seems to be faster
            beta_vec =  lsqlin(X1, y1,[],[],[],[],zeros(k1, 1), [ones(k1, 1)], [], opts1);
            beta_all_cell{j, g}(1:k1) = beta_vec./scalefactor;
            fittedC{j, g} = [(X(:, 1:k1))*beta_all_cell{j,g}(1:k1) y];
        else
            try
                mdl = fitnlm(X1, y1, @(w, X1)(X1*(1./(1+exp(-w)))), zeros(k1, 1));
            catch
                thiserror = 1;
                continue
            end
            beta_vec = 1./(1+ exp(-mdl.Coefficients.Estimate));
            beta_all_cell{j, g}(1:k1) = beta_vec./scalefactor;
            beta_CI = 1./(1+ exp(-mdl.coefCI(1-ret_conf)));
            ci{j, g}(1:k1, :) = beta_CI./scalefactor;
            ci{j, g}(isnan(ci{j, g})) = 0;
            Mdl{j, g} = mdl;
            %%%%%%%%% Fixing bad intervals
            % Sometimes upper bound is very large
            % If the upper diff is more than 2*lower diff than update
            % upper diff
            ub_diff = (ci{j, g}(:, 2) - beta_all_cell{j, g});
            lb_diff = (beta_all_cell{j, g} - ci{j, g}(:, 1));

            bad_diffs = ub_diff > 2*lb_diff;
            ci{j, g}(bad_diffs, 2) = 2*lb_diff(bad_diffs) + beta_all_cell{j, g}(bad_diffs);

            % Some ranges are too wide
            if sum(ci{j, g}(:, 2) - ci{j, g}(:, 1))/sum(1e-20 + ci{j, g}(:, 1)) > 5
                beta_vec =  lsqlin(X1, y1,[],[],[],[],zeros(k1, 1), [ones(k1, 1)], [], opts1);
                beta_all_cell{j, g}(1:k1) = beta_vec./scalefactor;
                ci{j, g}(:, 1) = beta_all_cell{j, g};
                ci{j, g}(:, 2) = beta_all_cell{j, g};
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%

            fittedC{j, g} = [(X(:, 1:k1))*[ci{j,g}(1:k1, :) beta_all_cell{j, g}(1:k1)] y];

        end
    end
end

