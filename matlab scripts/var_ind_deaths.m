function [beta_all_cell, ci, fittedC] = var_ind_deaths(data_4, death_data, alpha_l, k_l, jp_l, window_size, ret_conf, compute_region, lags)
    
    maxt = size(data_4, 2);
    nn = size(data_4, 1);
    beta_all_cell = cell(nn, 1);
    ci = cell(nn, 1);
    
    if nargin < 8
        compute_region = ones(size(data_4, 1), 1);
    end
    
    if nargin <7
        ret_conf = 0;
    end
    
    if nargin < 6
        window_size = maxt*ones(size(data_4, 1), 1); % By default, use all death data to fit parameters
    end
       
    if length(jp_l) == 1
        jp_l = ones(nn, 1)*jp_l;
    end
    
    if length(k_l) == 1
        k_l = ones(nn, 1)*k_l;
    end
    
    if nargin < 9
        lags = k_l - 1;
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
    
    deldata = diff(data_4')';
    new_deaths = diff(death_data')';
    for j=1:nn
        jp = jp_l(j); 
        k = k_l(j);
        alpha = alpha_l(j);
        jk = jp*k;
        beta_all_cell{j} = zeros(k, 1);
        ci{j} = [zeros(k, 1) zeros(k, 1)];
        fittedC{j} = [0 0];
        if compute_region(j) < 1 % Do not compute for region that are not specified
            continue;
        end
        
        skip_days = maxt - window_size(j);
        if skip_days < 0
            skip_days = 0;
        end
        
        scalefactor = 0.5*nanmean(data_4(j, death_data(j, :)>10)./death_data(j, death_data(j, :)>10)); % Scales deaths so that the parameters learned are not negligible        
                
        if death_data(j, end) < 1
            continue;
        end
        
        alphavec = power(alpha, (maxt-skip_days - jk-1:-1:1)');
        alphamat = repmat(alphavec, [1 k]);
        y = zeros(maxt - jk - skip_days - 1, 1);
        X = zeros(maxt - jk - skip_days - 1, k);
        
        if isempty(y)
            continue;
        end
        
        Ikt = zeros(1,k);
        for t = skip_days+jk+1:maxt-1
            Ikt1 = deldata(:, t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(Ikt1(j, (kk-1)*jp+1 : kk*jp), 2);
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
       else
        mdl = fitnlm(X1, y1, @(w, X1)(X1*(1./(1+exp(-w)))), zeros(k1, 1));
        beta_vec = 1./(1+ exp(-mdl.Coefficients.Estimate));
        beta_CI = 1./(1+ exp(-mdl.coefCI(0.01)));
        ci{j}(1:k1, :) = beta_CI./scalefactor;
       end
        beta_all_cell{j}(1:k1) = beta_vec./scalefactor;
        fittedC{j} = [X1*beta_all_cell{j}(1:k1) y/scalefactor];
    end
    
