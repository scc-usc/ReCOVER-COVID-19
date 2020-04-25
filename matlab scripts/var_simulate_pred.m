function [infec] = var_simulate_pred(data_4, passengerFlowDarpa, beta_all_cell, popu, k_l, horizon, jp_l)
    %SIMULATE_PRED Summary of this function goes here
    %   Detailed explanation goes here
    num_countries = size(data_4, 1);
    infec = zeros(num_countries, horizon);
    %F = passengerFlowDarpa/(max(max(passengerFlowDarpa))+ 1e-10);
    F = passengerFlowDarpa;
    lastinfec = data_4(:,end);
    temp = data_4;
    
    for t=1:horizon
        S = (1-lastinfec./popu);
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
        lastinfec = lastinfec + yt;
        infec(:, t) = lastinfec;
        temp = [temp lastinfec];
    end
end

