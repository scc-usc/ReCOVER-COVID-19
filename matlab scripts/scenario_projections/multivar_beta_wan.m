function [all_betas, all_cont, fittedC] = multivar_beta_wan(all_vars_data, F, popu, k_l, alpha_l, ...
    jp_l, un_fact, vac_ag, ag_case_frac, ag_popu_frac, ag_wan_param, ag_wan_lb, Contact_Matrix)

ret_conf = 0;
num_countries = size(all_vars_data, 1);
nl = size(all_vars_data, 2);
T = size(all_vars_data, 3);
opts1=  optimset('display','off');
all_betas = cell(nl, 1);
data_4 = squeeze(nansum(all_vars_data, 2));

for l=1:nl
    all_betas{l} = cell(num_countries, 1);
    all_cont{l} = cell(num_countries, 1);
    fittedC{l} = cell(num_countries, 1);
end

if length(alpha_l) == 1
    alpha_l = ones(length(popu), 1)*alpha_l;
end

if nargin < 8
    % This needs to be for the whole period, not just for the future
    vac_ag = zeros(num_countries, T, 1);
end
vac = sum(vac_ag(:, T+1:end, :), 3);
ag = size(vac_ag, 3);

if nargin < 9
    ag_case_frac = ones(num_countries, T, ag)/ag;
end
ag_case_frac(isnan(ag_case_frac)) = 0;
if nargin < 10
    ag_popu_frac = repmat(1/ag, [length(popu) ag]);
end

if nargin < 11
    ag_wan_param = zeros(size(vac_ag, 3), 1);
end

if nargin < 12
    ag_wan_lb = ones(size(vac_ag, 3), 1);
end

if nargin < 13
    Contact_Matrix = ones(num_countries, ag, ag);
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

waned_impact = zeros(T, T, ag);
tdiff_matrix = (1:(T))' - (1:(T));
tdiff_matrix(tdiff_matrix < 0) = -Inf;

for idx = 1:ag
    waned_impact(:, :, idx) = (1-ag_wan_lb(idx)).*(1-exp(-1./ag_wan_param(idx) .* tdiff_matrix));
end
waned_impact(isinf(waned_impact)) = 0;
waned_impact(isnan(waned_impact)) = 0;
waned_popu = zeros(length(popu), T, length(ag_wan_param));

func1 = @(b, k, ag, S, X)(S'.*((b(k+1:end) * b(k+1:end)') * reshape(X, [ag k]) * b(1:k))');
options = optimoptions('lsqnonlin', 'Display','off');

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
        true_new_infec_ts = this_case_frac .*[ 0,  diff(un_fact(j)*data_4(j, :))];
    else
        true_new_infec_ts = [ 0,  diff(un_fact(j)*data_4(j, :))];
    end
    true_infec_ts = cumsum(true_new_infec_ts, 2);
    this_vac = squeeze(vac_ag(j, :, :));
    if size(this_vac, 1) > size(this_vac, 2)
        this_vac = this_vac';
    end
    
    M = true_infec_ts/popu(j) + ((1-true_infec_ts./popu(j)) .* this_vac(:, 1:T))./popu(j);
    newM = [zeros(length(ag_wan_param), 1) diff(M, 1, 2)];
    % Calculate expected inc. count of population with waned immunity
    for idx = 1:ag
        waned_popu(j, :, idx) = (squeeze(waned_impact(:, :, idx))*newM(idx, :)');
    end
    
    % Get the contact matrix using the most prevelant variant
    if ag==1
        beta_cont = 1;
        C = 1;
    else
    [~, Ml] = max(squeeze(deltemp(j, :, T)));
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
    
    for t=skip_days+jk+1:T-1
        Ikt1 = thisdel(:, t-jk:t-1);
        S = ag_popu_frac(j, :)' - (M(:,t-1) - squeeze(waned_popu(j, t, :)));
        
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
        for t=skip_days+jk+1:T-1
            Ikt1 = thisdel(:, t-jk:t-1);
            
            S = ag_popu_frac(j, :)' - (M(:,t-1) - squeeze(waned_popu(j, t, :)));
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
            % If confidence intervals are not required, we will use lsqlin.
            % code for confidence intervals is not written yet
            if ret_conf == 0
                beta_vec =  lsqlin(X, y,[],[],[],[],zeros(k, 1), [], [], opts1);
            end
            all_betas{l}{j} = beta_vec;
            fittedC{l}{j}{1} = (X./alphamat)*beta_vec;
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