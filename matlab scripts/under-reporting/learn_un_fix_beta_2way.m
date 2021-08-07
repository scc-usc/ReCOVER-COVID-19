function [beta_cell, un_prob, E, initdat, ci, del, fittedC] = learn_un_fix_beta_2way(data_4, popu, k_l, jp_l, alpha_l, a_T, min_pts, mode, ret_conf)
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
    
    maxt = length(thisdata);
    
    beta_cell{j} = 0.5*ones(k, 1);
    un_prob(j) = 0.5;
    ci{j} = [-1 -1];
    
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
    
    a_f = (data_4(j, breakpt) + 1e-10)./popu(j);
    a_0 = (data_4(j, jk)+ 1e-10)./popu(j);
    max_iter = 1; mu_ub = 1; g_ub = 1; mu_lb = a_0; g_lb = 0.01; mu = mu_ub;
    bad_low = 0; bad_high = 0;
    for iter = 1:max_iter
        
        %%% New Lower Bound %%%%%%%%%%%%%%%%%%%%
        [beta_vec, Ef, ferrs] = train_beta(mu_ub, g_ub, breakpt, jp, k, thisdata, popu(j), opts1, a_0, 0);
        %%%%%%% Train for gamma
        [un_fact, Et, terrs] = train_gamma(maxt, thisdata, jp, k, popu(j), beta_vec, opts1, a_0);
        %%%%%%%%% Identify delta
        
        e_lim = 0.1;
        if any(abs(ferrs) > e_lim) || any(abs(terrs) > e_lim)
            bad_low = 1;
            break;
        end
        
        E = sum(1-terrs)./sum(1-ferrs);
        mu = 1./un_fact(1);
        g = 1./un_fact(2);
        Q0 = a_0/mu_ub;
        Q1 = a_0/mu;
        Qf = a_0/mu + (a_f - a_0)/g;
        QT = a_0/mu + (a_T - a_0)/g;
        
        pval = 0.75; 
        t_conf = sqrt(-e_lim^2 * log(pval/2)/(2*length(terrs)));
        f_conf = sqrt(-e_lim^2 * log(pval/2)/(2*length(ferrs)));
        
        E_star1 = ((1-t_conf)/(1+f_conf))*length(terrs)/length(ferrs);
        E_star2 = ((1+t_conf)/(1-f_conf))*length(terrs)/length(ferrs);
        
        del_low1 = 1 - (E*(QT*(1-Q0) - E_star1*Qf*(1-Q1))/(E*(1-Q0)-E_star1*(1-Q1)));
        del_low2 = 1 - (E*(QT*(1-Q0) - E_star2*Qf*(1-Q1))/(E*(1-Q0)-E_star2*(1-Q1)));
        
        del_low = max([del_low1 del_low2]);
        
        if del_low <= 0 || 1-del_low < QT %|| (E_star1-E)*(E_star2-E) < 0
            bad_low = 1;
            break;
        end
        mu_lb = max([mu_lb (1-del_low)*mu]); 
        g_lb = max([g_lb (1-del_low)*g]);

        g_ub = g; mu_ub = mu;
        
%         %%% New Upper Bound %%%%%%%%%%%%%%%%%%%%
%         [beta_vec, ~, ferrs] = train_beta(mu_lb, g_lb, breakpt, jp, k, thisdata, popu(j), opts1, a_0, 0);
%         %%%%%%% Train for gamma
%         [un_fact1, ~, terrs] = train_gamma(maxt, thisdata, jp, k, popu(j), beta_vec, opts1, a_0);
%         %%%%%%%%% Identify delta
%         Ef = (1-max(abs(ferrs)))/(1-ferrs(end));
%         Et = (1+max(abs(terrs)))/(1-terrs(end));
%         E = Et/Ef;
%         if E < 0
%             bad_high = 1;
%             break;
%         end
%         mu = 1./un_fact1(1);
%         g = 1./un_fact1(2);
%         Q0 = a_0/mu_lb + (a_f - a_0)/g_lb;
%         Qf = a_0/mu + (a_f - a_0)/g;
%         QT = a_0/mu + (a_T - a_0)/g;
%         del_high = ((QT*(1-Q0) - Qf*E*(1-QT))/((1-Q0)-E*(1-QT)))-1;
%         if mu*(1+del_high)>mu_ub || del_high < 0 || Ef < 0 || Et < 0 || 1-Q0 < E*(1-QT) || QT*(1-Q0) < Qf*E*(1-QT)
%             bad_high = 1;
%             break;
%         end
%                 
%         mu_ub = min([mu_ub, (1+del_high)*mu]); 
%         g_ub = min([g_ub, (1+del_high)*g]);
% %        mu_lb = max([mu_lb mu_ub]);
% %        g_lb = max([g_lb g_ub]);
%         if bad_high == 1 || bad_low == 1
%             mu_lb = a_0; mu_ub = 1;
%         end
    end
    beta_cell{j} = beta_vec;
    %del(j) = del_low;
    un_prob(j) = (mu_lb+mu_ub)/2;
    ci{j}(1, :) = [mu_lb, mu_ub];
end
end

function [beta_vec, Ef, ferrs] = train_beta(mu, g, breakpt, jp, k, thisdata, N, opts1, a0, low_high)
jk = jp*k;
y = zeros(breakpt - jk, 1);
X = zeros(breakpt - jk, k);
thisinc = diff(thisdata);
for t = jk+1:breakpt
    Ikt1 = thisinc(t-jk:t-1);
    for kk=1:k
        Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp));
    end
    
    X(t-jk, :) = (1 - a0/mu -(thisdata(t)/N -a0)./(g)).*Ikt;
    y(t-jk) = thisinc(t);
end
X = X./(y + 1e-10); y = y./(y + 1e-10);
if low_high == 0
    beta_vec = lsqlin(X,y,[],[],[],[],0, 1, [], opts1);
else
    func_nlm = @(w, x)(x*(1./(1+exp(-w(1:end)))));
    mdl = fitnlm(X, y, func_nlm, zeros(k, 1));
    beta_ci = 1./(1+exp(-mdl.coefCI(0.05)));
    beta_ci = clean_ci(beta_ci, [0 1]);
    beta_vec = beta_ci(low_high);
end
%%%%%%% beta trained, now calculate error terms
fvals = X*beta_vec;
ferrs = (y-fvals)./y;
Ef = ((1-max(abs(ferrs)))./(1-min(ferrs)));
%Ef = (1+max(abs(ferrs)))/(1-ferrs(end));
Ef = (1+max(abs(ferrs)))/(1-max(abs(ferrs)));
end

function [un_fact, Et, ferrs] = train_gamma(maxt, thisdata, jp, k, N, beta_vec, opts1, a_0)
thisinc = diff(thisdata);
jk = jp*k;
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
X = X./(y + 1e-10); y = y./(y + 1e-10);

X1 = [a_0*ones(size(X, 1), 1), (thisdata(jk+1:maxt-1)./(N)-a_0)].* (X*beta_vec);
y1 = (X*beta_vec) - y;
un_fact = lsqlin(X1,y1,[],[],[],[],[1 1], [Inf Inf], [], opts1);
fittedC = [X1*un_fact+(X*beta_vec), y];

%%%%%% Done training for gamma, now find error
fvals = fittedC(:, 1);
y = fittedC(:, 2);
ferrs = (y-fvals)./y;
%Et = (1-min(ferrs))./(1-max(abs(ferrs)));
%Et = (1-max(abs(ferrs)))/(1-ferrs(end));
Et = (1-max(abs(ferrs)))/(1-max(abs(ferrs)));
end