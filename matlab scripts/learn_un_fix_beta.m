function [beta_cell, un_prob, err, initdat, ci, del, fittedC] = learn_un_fix_beta(data_4, popu, k_l, jp_l, alpha_l, a_T, min_pts, mode, ret_conf)
un_prob = zeros(length(popu), 1);
del = zeros(length(popu), 1);
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
    
    Ikt = zeros(1,k);
    
    if min_pts(j) < 1
        continue;
    end
    
    idx = (1: jk + min_pts(j));
    breakpt = idx(end);
    a_f = data_4(j, breakpt)./popu(j);
    
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
    beta_vec = lsqlin(X,y,[],[],[],[],0, 1, [], opts1);
    beta_cell{j} = beta_vec;
    
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
    X1 = thisdata(jk+1:maxt-1)./(popu(j)).* (X*beta_vec);
    y1 = (X*beta_vec) - y;
    
    initdat(j, end-jk:end) = data_4(j, 1:jk+1);
    
    if mode == 'i'
        if ret_conf==0
            un_fact = lsqlin(X1,y1,[],[],[],[],1, Inf, [], opts1);
        else
            mdl = fitnlm(X1, y1, @(w, X)(X*(1./(1+exp(-w)))), zeros(k, 1));
            un_fact = 1./(1+ exp(-mdl.Coefficients.Estimate));
            ci{j} = 1./(1+ exp(-mdl.coefCI));
        end
        
        un_prob(j) = 1./un_fact;
        fittedC{j} = [X1*un_fact+(X*beta_vec), y];
    else
        [ww, ~, res{j}, ~, ~, ~, jacob{j}] = lsqnonlin(@(w)(func3(w, popu(j), k, jp, length(y), beta_vec, data_4(j, 1)) - [diff(data_4(j, 1:jk+1))'; y]), [ 0.5; diff(data_4(j, 1:jk+1))'], zeros(jk+1, 1), [ones(1, 1); Inf(jk, 1)], opts1);
        un_prob(j) = ww(1);
        fittedC{j} = [func3(ww, popu(j), k, jp, length(y),beta_vec,  data_4(j, 1)), [diff(data_4(j, 1:jk+1))'; y]];
        initdat(j, end-jk:end) = [data_4(j, 1), data_4(j, 1) + cumsum(ww(2:1+jk)')];
        
        if ret_conf == 1
            ci{j} = nlparci(ww, res{j}, 'jacobian', jacob{j});
        else
            ci{j} = [-1 -1];
        end
    end
       
    err(j) = 2*mean(abs(fittedC{j}(:, 1) -  fittedC{j}(:, 2))./(1e-5+fittedC{j}(:, 1) +  fittedC{j}(:, 2)));
    this_del = ((1-a_f - un_prob(j))- sqrt((1-a_f-un_prob(j))^2 - 4*(1-a_f)*(a_f/a_T(j) - un_prob(j))))/(2*(1-a_f));
    if isreal(this_del)
        del(j) = this_del;
    else
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