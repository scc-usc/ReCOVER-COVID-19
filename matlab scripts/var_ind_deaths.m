function [beta_all_cell, ci, fittedC] = var_ind_deaths(data_4, death_data, alpha_l, k_l, jp_l, window_size, ret_conf, compute_region)
    
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
        window_size = maxt; % By default, use all death data to fit parameters
    end
       
    if length(jp_l) == 1
        jp_l = ones(nn, 1)*jp_l;
    end
    
    if length(k_l) == 1
        k_l = ones(nn, 1)*k_l;
    end
    
    if length(alpha_l) == 1
        alpha_l = ones(nn, 1)*alpha_l;
    end
    
    skip_days = maxt - window_size;
    if skip_days < 0
        skip_days = 0;
    end
    deldata = diff(data_4')';
    new_deaths = diff(death_data')';
    for j=1:nn
        jp = jp_l(j); 
        k = k_l(j);
        alpha = alpha_l(j);
        jk = jp*k;
        beta_all_cell{j} = zeros(k, 1);
        ci{j} = [zeros(k, 1) ones(k, 1)];
        
        if compute_region(j) < 1 % Do not compute for region that are not specified
            continue;
        end
        
        scalefactor = 0.5*nanmean(data_4(j, death_data(j, :)>10)./death_data(j, death_data(j, :)>10)); % Scales deaths so that the parameters learned are not negligible        
        
        lag = 0; % To enforce there is a delay between positive report and death
        jk = jk+lag;
        
        if death_data(j, end) < 1
            continue;
        end
        
        alphavec = power(alpha, (maxt-skip_days - jk-1:-1:1)');
        alphamat = repmat(alphavec, [1 k]);
        y = zeros(maxt - jk - skip_days - 1, 1);
        X = zeros(maxt - jk - skip_days - 1, k);
        
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
       opts1=  optimset('display','off');
       if ret_conf == 0    % If confidence intervals are not required, we will run this as this seems to be faster
        beta_vec =  lsqlin(X1, y1,[],[],[],[],zeros(k, 1), [ones(k, 1)], [], opts1);
       else
        mdl = fitnlm(X1, y1, @(w, X1)(X1*(1./(1+exp(-w)))), zeros(k, 1));
        beta_vec = 1./(1+ exp(-mdl.Coefficients.Estimate));
        beta_CI = 1./(1+ exp(-mdl.coefCI));
        ci{j} = beta_CI./scalefactor;
       end
        beta_all_cell{j} = beta_vec./scalefactor;
        fittedC{j} = [X*beta_all_cell{j} y/scalefactor];
    end
    
