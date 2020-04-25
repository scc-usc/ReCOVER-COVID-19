function [beta_all_cell] = var_ind_beta(data_4, passengerFlow, alpha_l, k_l, T_tr, popu, jp_l)
    maxt = size(data_4, 2);
    %F = passengerFlow/(max(max(passengerFlow))+ 1e-10);
    F = passengerFlow;
    beta_all_cell = cell(length(popu), 1);
    deldata = diff(data_4')';
    for j=1:length(popu)
        jp = jp_l(j);
        k = k_l(j);
        alpha = alpha_l(j);
        jk = jp*k;
        
        alphavec = power(alpha, (maxt-jk-1:-1:1)');
        alphamat = repmat(alphavec, [1 k+1]);
        y = zeros(maxt - jk - 1, 1);
        X = zeros(maxt - jk - 1, k+1);
        Ikt = zeros(1,k);
        for t = jk+1:maxt-1
            Ikt1 = deldata(:, t-jk:t-1);
            S = (1-data_4(j,t)./popu(j));
            for kk=1:k
                Ikt(kk) = S*sum(Ikt1(j, (kk-1)*jp+1 : kk*jp), 2);
            end
            X(t-jk, :) = [Ikt (F(:, j)./popu)'*sum(Ikt1, 2)] ;
            y(t-jk) = deldata(j, t)';
        end
        
        opts1=  optimset('display','off');
        beta_all_cell{j} =  lsqlin(alphamat.*X,alphavec.*y,[],[],[],[],zeros(k+1, 1), [ones(k, 1); Inf], [], opts1);
    end
    
