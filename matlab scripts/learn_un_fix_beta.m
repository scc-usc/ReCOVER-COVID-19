function [un_prob, fittedC, initdat] = learn_un_fix_beta(data_4, popu, k_l, jp_l, alpha_l, beta_init, mode)
    un_prob = zeros(length(popu), 1);
    fittedC = cell(length(popu), 1);
    initdat = zeros(length(popu), 50);
    
    if nargin < 7
        mode = 'i';
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
    
    if isempty(beta_init)
        for j=1:length(popu)
            beta_init{j} = 0.5*ones(k_l(j), 1);
        end
    else
        for j=1:length(popu)
            this_beta = beta_init{j};
            beta_init{j} = this_beta(1:k_l(j));
        end
    end
    
    %%% Smoothing %%%%%%%%%%%%%%%%%%
%      temp = movmean(diff(data_4')', 7, 2);
%      data_4_s = [data_4(:, 1) cumsum(temp, 2)];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for j=1:length(popu)
        jp = jp_l(j);
        k = k_l(j);
        alpha = alpha_l(j);
        jk = jp*k;
        
        thisdata = data_4(j, :)';
        thisdata(thisdata==0) = [];
        thisinc = diff(thisdata);
        maxt = length(thisdata);
        
        alphavec = power(alpha, (maxt-jk-1:-1:1)');
        alphamat = repmat(alphavec, [1 k]);
        
        y = zeros(maxt - jk - 1, 1);
        X = zeros(maxt - jk - 1, k);
        
        beta_vec = beta_init{j};
        un_prob(j) = 0.5;
        
        Ikt = zeros(1,k);
        for t = jk+1:maxt-1
            Ikt1 = thisinc(t-jk:t-1);
            for kk=1:k
                Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp));
            end
            
            X(t-jk, :) = Ikt.*alphamat(t-jk, :);
            y(t-jk) = thisinc(t).*alphavec(t-jk);
        end
        X1 = thisdata(jk+1:maxt-1)./(popu(j)).* (X*beta_vec);
        y1 = (X*beta_vec) - y;
        
        opts1=  optimset('display','off');
        
        initdat(j, end-jk:end) = data_4(j, 1:jk+1);
        
        if mode == 'i'
        un_fact = lsqlin(X1,y1,[],[],[],[],1, Inf, [], opts1);
        un_prob(j) = 1./un_fact;
        fittedC{j} = [X1*un_fact(j)+(X*beta_vec), y];
        else
            ww = lsqnonlin(@(w)(func3(w, popu(j), k, jp, length(y), beta_vec, data_4(j, 1)) - [diff(data_4(j, 1:jk+1))'; y]), [ 0.5; diff(data_4(j, 1:jk+1))'], zeros(jk+1, 1), [ones(1, 1); Inf(jk, 1)]);
            un_prob(j) = ww(1);
            fittedC{j} = [func3(ww, popu(j), k, jp, length(y),beta_vec,  data_4(j, 1)), [diff(data_4(j, 1:jk+1))'; y]];
            initdat(j, end-jk:end) = [data_4(j, 1), data_4(j, 1) + cumsum(ww(2:1+jk)')];
        end
    end
end

function yy = func3(w, N, k, jp, horizon, beta_vec, start_data)
    un_prob = w(1);
    previnc = w(2 : 1+jp*k)';
    prevdata = [start_data start_data+cumsum(previnc)];
    
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