function [infec] = var_simulate_pred_un(data_4, passengerFlowDarpa, beta_all_cell, popu, k_l, horizon, jp_l, un_fact, base_infec)

num_countries = size(data_4, 1);
infec = zeros(num_countries, horizon);
F = passengerFlowDarpa;

if nargin < 9
    base_infec = data_4(:, end);
end

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
temp = data_4_s;
deltemp = diff(temp')';

if length(F) <= 1    % Optimized code when mobility not considered
    for j=1:length(popu)
        if sum(beta_all_cell{j})==0
            yt(j) = 0;
            continue;
        end
        jp = jp_l(j);
        k = k_l(j);
        jk = jp*k;
        Ikt1 = deltemp(j, end-jk+1:end);
        Ikt = zeros(k, 1);
        lastinfec = base_infec(j,end);
        
        for t=1:horizon
            S = (1 - un_fact(j)*lastinfec./popu(j));
            for kk=1:k
                Ikt(kk) = sum(Ikt1((kk-1)*jp+1 : kk*jp), 2);
            end
            Xt = [S*Ikt; 0];
            yt = sum(beta_all_cell{j}'*Xt);
            yt(yt < 0) = 0;
            lastinfec = lastinfec + yt;
            infec(j, t) = lastinfec;
            Ikt1 = [Ikt1 yt];
            Ikt1(1) = [];
        end 
    end
    
else    % Above optimization not possible when mobility considered
    for t=1:horizon
        S = (1-un_fact.*lastinfec./popu);
        yt = zeros(num_countries, 1);
        
        for j=1:length(popu)
            if sum(beta_all_cell{j})==0
                yt(j) = 0;
                continue;
            end
            
            jp = jp_l(j);
            k = k_l(j);
            jk = jp*k;
            Ikt1 = deltemp(:, end-jk+1:end);
            Ikt = zeros(1,k);
            
            if size(F, 1) ~= length(popu)   % Avoids unnecessary computation
                incoming_travel = 0;
            else
                incoming_travel = (F(:, j)./popu)' * sum(Ikt1, 2);
            end
            
            for kk=1:k
                Ikt(kk) = sum(Ikt1(j,  (kk-1)*jp+1 : kk*jp), 2);
            end
            Xt = [S(j)*Ikt  incoming_travel] ;
            yt(j) = sum(beta_all_cell{j}'.*Xt, 2);
        end
        yt(yt<0) = 0;
        lastinfec = lastinfec + yt;
        infec(:, t) = lastinfec;
        temp = [temp lastinfec];
    end
end
end

