function [beta_cell, un_prob, E, initdat, ci, del, fittedC] = learn_un_fix_beta_imm(data_4, popu, k_l, jp_l, alpha_l, a_T, min_pts, mode, ret_conf)
un_prob = zeros(length(popu), 1);
del = -1*ones(length(popu), 1);
err = zeros(length(popu), 1);
fittedC = cell(length(popu), 1);
initdat = zeros(length(popu), 50);
ci = cell(length(popu), 1);
beta_cell = cell(length(popu), 1);

if nargin < 7
    mode = 'i';
end

if nargin < 8
    ret_conf = 1;
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

opts1=  optimset('display','off');

for j=1:length(popu)
    rng default;
    
    jp = jp_l(j);
    k = k_l(j);
    alpha = alpha_l(j);
    jk = jp*k;
    
    thisdata = data_4(j, :)';
    thisdata(thisdata==0) = [];
    
       
    thisinc = diff(thisdata);
    maxt = length(thisdata);
    
    beta_cell{j} = 0.5*ones(k, 1);
    un_prob(j) = 0.5;
    ci{j} = [-1 -1];
    beta_CI = [0 1];
    E = Inf;
    Ikt = zeros(1,k);
        
    if min_pts(j) < 1
        continue;
    end
    
    idx = (1: jk + min_pts(j));
    breakpt = idx(end);
    
    if length(thisdata) < jk+min_pts(j)+4    % At least 4 points to learn gamma and mu
        continue;
    end
    
    a_f = data_4(j, breakpt)./popu(j);
    a_0 = data_4(j, jk)./popu(j);
    y = zeros(breakpt - jk, 1);
    X = zeros(breakpt - jk, k);
    alphavec = power(alpha, (breakpt-jk:-1:1)');
    alphamat = repmat(alphavec, [1 k]);
    for t = jk+1:breakpt
        Ikt1 = thisinc(t-jk:t-1);
        for kk=1:k
            Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp));
        end
        
        X(t-jk, :) = (1 - thisdata(t)./(popu(j))).*Ikt.*alphamat(t-jk, :);
        y(t-jk) = thisinc(t).*alphavec(t-jk);
    end
    if ret_conf ~= 1
        beta_vec = lsqlin(X,y,[],[],[],[],0, 1, [], opts1);
    else
        mdl = fitnlm(X, y, @(w, X)(X*(1./(1+exp(-w)))), 0);
        beta_vec = 1./(1+ exp(-mdl.Coefficients.Estimate));
        beta_CI = 1./(1+ exp(-mdl.coefCI(0.05)));
        beta_CI = [nanmin(beta_CI) nanmax(beta_CI)];
        beta_CI = clean_ci(beta_CI, [0 1]);
    
        if beta_CI(1) == 0
            return;
        end
    end
    
    beta_cell{j} = beta_vec;
%%%%%%% beta trained, now calculate error terms
fvals = X*beta_vec;
% eps = sqrt(sum(((y-fvals)).^2)*sum(1./(y.^2))/length(y)^2);
% Ef = sum(1-(y-fvals)./y)./(length(y)*(1-eps));
ferrs = (y-fvals)./y;
Ef = (1-max(abs(ferrs)))./(1-min(ferrs));

%%%%%%% Train for gamma

    y = zeros(maxt - jk - 1, 1);
    X = zeros(maxt - jk - 1, k);
    for t = jk+1:maxt-1
        Ikt1 = thisinc(t-jk:t-1);
        for kk=1:k
            Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp));
        end
        
        X(t-jk, :) = Ikt;
        y(t-jk) = thisinc(t);
    end
    X1 = [a_0*ones(size(X, 1), 1), (thisdata(jk+1:maxt-1)./(popu(j))-a_0)].* (X*beta_vec);
    y1 = (X*beta_vec) - y;
    
    initdat(j, end-jk:end) = data_4(j, 1:jk+1);
    
    if mode == 'i'
        ci{j} = [a_T 1];
        if ret_conf==0
            un_fact = lsqlin(X1,y1,[],[],[],[],1, Inf, [], opts1);
            un_prob(j) = 1./un_fact(1);
        else
            beta_vec = beta_CI(1);
            mdl = fitnlm(y1, X1, @(w, X)(X*(a_T + (1-a_T)./(1+exp(-w)))), zeros(k, 1));
            un_prob(j) = a_T + (1-a_T)./(1+ exp(-mdl.Coefficients.Estimate));
            ci1 = a_T + (1-a_T)./(1+ exp(-mdl.coefCI(0.01)));
            ci1 = clean_ci(ci1(1, :), [a_T 1]);
            
            beta_vec = beta_CI(2);
            mdl = fitnlm(y1, X1, @(w, X)(X*(a_T + (1-a_T)./(1+exp(-w)))), zeros(k, 1));
            un_prob(j) = a_T + (1-a_T)./(1+ exp(-mdl.Coefficients.Estimate));
            ci2 = a_T + (1-a_T)./(1+ exp(-mdl.coefCI(0.01)));
            ci2 = clean_ci(ci2(1, :), [a_T 1]);
            
            ci{j} = [min([ci1(1, :) ci2(1, :)]) max([ci1(1, :) ci2(1, :)])];
            un_fact = 1./un_prob(j);
        end
        
        fittedC{j} = [X1*un_fact+(X*beta_vec), y];
    elseif mode == 'f'
        ci{j} = [a_T 1];
        if ret_conf==0
            un_fact = lsqlin(X1,y1,[],[],[],[],1, Inf, [], opts1);
            un_prob(j) = 1./un_fact(1);
        else
            mdl = fitnlm(X1, y1, @(w, X)(X*(a_T+ (1-a_T)./(1+exp(-w)))), zeros(2, 1));
            un_fact = 1./(a_T + (1-a_T)./(1+ exp(-mdl.Coefficients.Estimate)));
            ci_full = a_T + (1-a_T)./(1+ exp(-mdl.coefCI(0.01)));
            ci{j} = ci_full(1, :);
            un_prob(j) = 1./un_fact(1);
        end
        
        fittedC{j} = [X1*un_fact+(X*beta_vec), y];
    else
        [ww, ~, res{j}, ~, ~, ~, jacob{j}] = lsqnonlin(@(w)(func3(w, popu(j), k, jp, length(y), beta_vec, data_4(j, 1)) - [diff(data_4(j, 1:jk+1))'; y]), [ 0.5; diff(data_4(j, 1:jk+1))'], zeros(jk+1, 1), [ones(1, 1); Inf(jk, 1)], opts1);
        un_prob(j) = ww(1);
        fittedC{j} = [func3(ww, popu(j), k, jp, length(y),beta_vec,  data_4(j, 1)), [diff(data_4(j, 1:jk+1))'; y]];
        initdat(j, end-jk:end) = [data_4(j, 1), data_4(j, 1) + cumsum(ww(2:1+jk)')];
        
        if ret_conf == 1
            [ww, ~, res{j}, ~, ~, ~, jacob{j}] = lsqnonlin(@(w)(func3(w, popu(j), k, jp, length(y), beta_CI(1), data_4(j, 1)) - [diff(data_4(j, 1:jk+1))'; y]), [ 0.5; diff(data_4(j, 1:jk+1))'], zeros(jk+1, 1), [ones(1, 1); Inf(jk, 1)], opts1);
            ci1 = nlparci(ww, res{j}, 'jacobian', jacob{j}, 'alpha', 0.01);
            [ww, ~, res{j}, ~, ~, ~, jacob{j}] = lsqnonlin(@(w)(func3(w, popu(j), k, jp, length(y), beta_CI(2), data_4(j, 1)) - [diff(data_4(j, 1:jk+1))'; y]), [ 0.5; diff(data_4(j, 1:jk+1))'], zeros(jk+1, 1), [ones(1, 1); Inf(jk, 1)], opts1);
            ci2 = nlparci(ww, res{j}, 'jacobian', jacob{j}, 'alpha', 0.01);
            ci{j} = [min([ci1(1, :) un_prob(j) ci2(1, :)]) max([ci1(1, :) un_prob(j) ci2(1, :)])];
        else
            ci{j} = [-1 -1];
        end
    end
   
%%%%%% Done training for gamma, now find error
    fvals = fittedC{j}(:, 1);
    y = fittedC{j}(:, 2);
    
%     eps = sqrt(sum(((y-fvals)).^2)*sum(1./(y.^2))/length(y)^2);
%     Et = sum(1-(y-fvals)./y)./(length(y)*(1-eps));

    ferrs = (y-fvals)./y;
    Et = (1-min(ferrs))./(1-max(abs(ferrs)));
    
    err(j) = 2*mean(abs(fittedC{j}(:, 1) -  fittedC{j}(:, 2))./(1e-5+fittedC{j}(:, 1) +  fittedC{j}(:, 2)));
    ci{j} = clean_ci(ci{j}(1, :), [a_T 1]);
    
    
%%%%%%%%% Identify delta 
    E = Et/Ef;
    
    if E < 1 || E >2
        del(j) = -1;
        return;
    end
    
    mu = 1./un_fact(1); 
    g = 1./un_fact(2); 
    
    Qf = a_0*g + (a_f - a_0)*mu;
    QT = a_0*g + (a_T - a_0)*mu;
    delvec = 1 - sqrt((Qf*(mu*g-QT) - Qf*E*(1-a_f)*mu*g)/(mu*g*(mu*g-QT)-E*(1-a_f)*(mu*g)^2));
    del(j) = delvec;
    if g < a_f || g < a_T
        del(j) = -1;
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