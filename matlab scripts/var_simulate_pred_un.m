function [infec] = var_simulate_pred_un(data_4, passengerFlowDarpa, beta_all_cell, popu, k_l, horizon, jp_l, un_fact)

    num_countries = size(data_4, 1);
    infec = zeros(num_countries, horizon);

    F = passengerFlowDarpa;
    
    if length(un_fact)==1
        un_fact = un_fact*ones(length(popu), 1);
    end
    
    if length(jp_l) == 1
        jp_l = ones(length(popu), 1)*jp_l;
    end
    
    if length(k_l) == 1
        k_l = ones(length(popu), 1)*k_l;
    end
    
    for j=1:length(beta_all_cell)
        this_beta = beta_all_cell{j};
        if length(this_beta)==k_l(j)
            beta_all_cell{j} = [this_beta; 0];
        end
    end
    
    data_4_s = data_4;
    %%% Smoothing %%%%%%%%%%%%%%%%%%
%      temp = movmean(diff(data_4')', 7, 2);
%      data_4_s = [data_4(:, 1) cumsum(temp, 2)];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    lastinfec = data_4(:,end);
    temp = data_4_s;
    for t=1:horizon
        S = (1-un_fact.*lastinfec./popu);
        yt = zeros(num_countries, 1);
        for j=1:length(popu)
            jp = jp_l(j);
            k = k_l(j);
            jk = jp*k;
            Ikt1 = diff(temp(:, end-jk:end)')';
            Ikt = zeros(1,k);
            for kk=1:k
                Ikt(kk) = sum(Ikt1(j,  (kk-1)*jp+1 : kk*jp), 2);
            end
            Xt = [S(j)*Ikt  (F(:, j)./popu)'*sum(Ikt1, 2)] ;
            yt(j) = sum(beta_all_cell{j}'.*Xt, 2);
        end
        yt(yt<0) = 0;
        lastinfec = lastinfec + yt;
        infec(:, t) = lastinfec;
        temp = [temp lastinfec];
    end
end

