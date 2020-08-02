function [beta_all_cell, fittedC, ci] = var_ind_beta_un(data_4, passengerFlow, alpha_l, k_l, un_fact, popu, jp_l, ret_conf, compute_region, window_size)
    
    maxt = size(data_4, 2);    

    if nargin < 9
        compute_region = ones(length(popu), 1);
    end

    if nargin <8
        ret_conf = 0;
    end
    
    if nargin < 10
        window_size = maxt*ones(size(data_4, 1), 1); % By default, use all death data to fit parameters
    end
    
    F = passengerFlow;
    beta_all_cell = cell(length(popu), 1);
    fittedC = cell(length(popu), 1);
    ci = cell(length(popu), 1);
    nn = length(popu);
    
    if length(un_fact)==1
        un_fact = un_fact*ones(length(popu), 1);
    end
    
    if length(jp_l) == 1
        jp_l = ones(length(popu), 1)*jp_l;
    end
    
    if length(k_l) == 1
        k_l = ones(length(popu), 1)*k_l;
    end
    
    if length(alpha_l) == 1
        alpha_l = ones(length(popu), 1)*alpha_l;
    end
    
    if length(window_size) == 1
        window_size = ones(nn, 1)*window_size;
    end
    
    deldata = diff(data_4')';
    opts1=  optimset('display','off');
    
    for j=1:length(popu)
        jp = jp_l(j);
        k = k_l(j);
        alpha = alpha_l(j);
        jk = jp*k;
        
        beta_all_cell{j} = zeros(k+1, 1);
        ci{j} = zeros(k+1, 2);
        
        if data_4(j, end) < 1 || compute_region(j) < 1 % if there is no data or explictly told not to compute
            continue;
        end
        
        skip_days = maxt - window_size(j);
        if skip_days < 0
            skip_days = 0;
        end
        
        alphavec = power(alpha, (maxt-skip_days - jk-1:-1:1)');
        alphamat = repmat(alphavec, [1 k+1]);
        y = zeros(maxt - jk - skip_days - 1, 1);
        X = zeros(maxt - jk - skip_days - 1, k+1);
        Ikt = zeros(1,k);
        
        
        for t = skip_days+jk+1:maxt-1
            Ikt1 = deldata(j, t-jk:t-1);
            S = (1-un_fact(j)*data_4(j,t)./popu(j));
            for kk=1:k
                Ikt(kk) = S*sum(Ikt1((kk-1)*jp+1 : kk*jp), 2);
            end
            
            if size(F, 1) ~= length(popu)   % Avoids unnecessary computation
                incoming_travel = 0;
            else
                incoming_travel = (F(:, j)./popu)' * sum(Ikt1, 2);
            end

            X(t-jk-skip_days, :) = [Ikt incoming_travel] ;
            y(t-jk-skip_days) = deldata(j, t)';
        end
        
        X = alphamat.*X; y = alphavec.*y;
        
        if ~isempty(X) && ~isempty(y)
            if ret_conf == 0    % If confidence intervals are not required, we will run this as this seems to be faster
                beta_vec =  lsqlin(X, y,[],[],[],[],zeros(k+1, 1), [ones(k, 1); Inf], [], opts1);
            else
                %mdl = fitnlm(X, y, @(w, X)(X*[(1./(1+exp(-w(1:k)))); w(k+1)]), zeros(k+1, 1));
                mdl = fitnlm(X, y, @(w, X)(X*(1./(1+exp(-w)))), zeros(k+1, 1));
                beta_vec = [1./(1+ exp(-mdl.Coefficients.Estimate))];
                beta_CI = [1./(1+ exp(-mdl.coefCI))];
                ci{j} = beta_CI;
            end
        end
        
        beta_all_cell{j} = beta_vec;
        fittedC{j} = [X*beta_all_cell{j},y];
    end
    
