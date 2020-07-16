function [beta_all_cell, un_prob, initdat, fittedC, ci] = learn_nonlin(data_4, popu, k_l, jp_l, alpha_l, beta_init, mode)
    
    if nargin < 7
        mode = 'i';
    end
    
    
    if length(jp_l) == 1
        jp_l = ones(length(popu), 1)*jp_l;
    end
    
    if length(k_l) == 1
        k_l = ones(length(popu), 1)*k_l;
    end
        
    if isempty(beta_init) || nargin < 6
        for j=1:length(popu)
            beta_init{j} = 0.5*ones(k_l(j), 1);
        end
    else
        for j=1:length(popu)
            this_beta = beta_init{j};
            beta_init{j} = this_beta(1:k_l(j));
        end
    end
    
    beta_all_cell = cell(length(popu), 1);
    res = cell(length(popu), 1);
    ci = cell(length(popu), 1);
    jacob = cell(length(popu), 1);
    un_prob = zeros(length(popu), 1);
    fittedC = cell(length(popu), 1);
    initdat = zeros(length(popu), 50);
    
    if length(jp_l) == 1
        jp_l = ones(length(popu), 1)*jp_l;
    end
    
    if length(k_l) == 1
        k_l = ones(length(popu), 1)*k_l;
    end
    
    if length(alpha_l) == 1
        alpha_l = ones(length(popu), 1)*alpha_l;
    end
    
    
    func = @(w, x)((1-x(:, 1)/(w(1, 1))).*( x(:, 2:end)*(w(2:end, 1))));
    %func = @(w, x)((1-x(:, 1)/sigfunc(w(1, 1))).*( x(:, 2:end)*sigfunc(w(2:end, 1))));
    
    for j=1:length(popu)
        jp = jp_l(j);
        k = k_l(j);
        alpha = alpha_l(j);
        jk = jp*k;
        
        thisdata = data_4(j, :)';
        first_idx = find(thisdata>0); 
        
        if ~isempty(first_idx)
            first_idx = first_idx(1);
            thisdata(1:first_idx) = [];
        end
        
        thisinc = diff(thisdata);
        maxt = length(thisdata);
        
        alphavec = power(alpha, (maxt-jk-1:-1:1)');
        alphamat = repmat(alphavec, [1 k+1]);
        
        y = zeros(maxt - jk - 1, 1);
        X = zeros(maxt - jk - 1, k+1);
        
        beta_vec = beta_init{j};
        un_prob(j) = 0.5;
        
        Ikt = zeros(1,k);
        for t = jk+1:maxt-1
            Ikt1 = thisinc(t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp));
            end
            
            X(t-jk, :) = [thisdata(t)./popu(j), Ikt].*alphamat(t-jk, :);
            y(t-jk) = thisinc(t).*alphavec(t-jk);
        end
        
        initdat(j, end-jk:end) = data_4(j, 1:jk+1);
        opts1=  optimset('display','off');
        if mode == 'i'
            [ww, ~, res{j}, ~, ~, ~, jacob{j}] = lsqcurvefit(func, [0.5; beta_vec], X, y, zeros(k+1, 1), ones(k+1, 1), opts1);
            fittedC{j} = [func(ww, X) y];
            ci{j} = nlparci(ww, res{j}, 'jacobian', jacob{j});
            %ci{j} = bootci(1000, @(ww)func(ww, X), y);
            
        elseif mode == 'c'
            [ww, ~, res{j}, ~, ~, ~, jacob{j}] = lsqnonlin(@(w)(func2(w, data_4(j, 1:jk+1), popu(j), jp, length(y))-y), [0.5; beta_vec], zeros(k+1, 1), ones(k+1, 1), opts1);
            fittedC{j} = [func2(ww, data_4(j, 1:jk+1), popu(j), jp, length(y)) y];
            ci{j} = nlparci(ww, res{j}, 'jacobian', jacob{j});
        else
            [ww, ~, res{j}, ~, ~, ~, jacob{j}] = lsqnonlin(@(w)(func3(w, popu(j), k, jp, length(y), data_4(j, 1)) - [diff(data_4(j, 1:jk+1))'; y]), [ 0.5; beta_vec; diff(data_4(j, 1:jk+1))'], zeros(jk+k+1, 1), [ones(k+1, 1); Inf(jk, 1)], opts1);
            
            fittedC{j} = [func3(ww, popu(j), k, jp, length(y), data_4(j, 1)), [diff(data_4(j, 1:jk+1))'; y]];
            initdat(j, end-jk:end) = [data_4(j, 1), data_4(j, 1) + cumsum(ww(k+2:k+1+jk)')];
            ci{j} = nlparci(ww, res{j}, 'jacobian', jacob{j});
        end
        
        
        un_prob(j) = ww(1);
        beta_vec = ww(2:k+1);
        beta_all_cell{j} = beta_vec;
        
        
    end
    
end

function yy = func2(w, prevdata, N, jp, horizon)
    lastinfec = prevdata(end);
    temp = prevdata;
    yy = zeros(horizon, 1);
    
    for t=1:horizon
        k = length(w)-1;
        
        Ikt1 = diff(temp(end-jp*k:end)')';
        
        Ikt = zeros(1,k);
        for kk=1:k
            Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp));
        end
        yt = (1 - lastinfec./(N*w(1)))*(Ikt*w(2:end));
        yy(t) = yt;
        lastinfec = lastinfec + yt;
        temp = [temp lastinfec];
    end
end

function yy = func3(w, N, k, jp, horizon, start_data)
    previnc = w(k+2 : k+1+jp*k)';
    prevdata = [start_data start_data+cumsum(previnc)];
    un_prob = (w(1));
    beta_vec = (w(2:k+1));
    lastinfec = prevdata(end);
    temp = prevdata;
    yy = zeros(horizon, 1);
    
    for t=1:horizon
        
        Ikt1 = diff(temp(end-jp*k:end)')';
        
        Ikt = zeros(1,k);
        for kk=1:k
            Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp));
        end
        yt = (1 - lastinfec./(N*un_prob))*(Ikt*beta_vec);
        yy(t) = yt;
        lastinfec = lastinfec + yt;
        temp = [temp lastinfec];
    end
    yy = [previnc'; yy];
end

function s = sigfunc(x)
    s = 1./(1+exp(-x));
end