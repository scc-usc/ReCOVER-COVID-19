function [Re,S,dI] = epimodel_sim(betas,alpha,N,I0,T,un, V)   
    nv = size(alpha, 1);
    P = size(alpha, 2);
    
    
    if size(I0, 2) < P
        I0 = [I0; zeros(nv, P-size(I0, 2))];
    end
    
    if length(betas) == 1
        betas = ones(T, 1)*betas;
    end
    
    if length(un) == 1
        un = ones(T, 1)*un;
    end
    
    
    if length(V) == 1
        V = zeros(T, 1);
    end
    max_lag = 10;
    Re = zeros(1,T + max_lag);
    S = zeros(1,T);
    I = zeros(nv,T);
    if nv ~= size(I0, 1)
        disp('parameters should have the same size');
        return;
    end
    
    S(1:P) = N - sum(I0, 1);
    dI = zeros(nv,T);
    I(:, 1:P) = I0; dI(:, 2:P) = diff(I0, 1, 2);
    
    
    for tt = (P+1):T
        % Equations of the model
        thisbeta = betas(tt);
        thisun = un(tt);
        dI(:, tt) = (thisbeta*S(tt-1)/N)*sum(alpha.*dI(:, tt-P:tt-1), 2);
        I(:, tt) = I(:, tt-1) + dI(:, tt);
        newI = sum(dI(:, tt));
        dS = -newI - V(tt);
        
        S(tt) = S(tt-1) + dS;
                
        % The new infections today will be randomly reported over the next
        % "max_lag" number of days, and in total only 1/un(tt) fraction
        % will be reported
        dist_vec = rand(1, max_lag);
        re_lag = (dist_vec/sum(dist_vec))*(newI/thisun);
        Re(tt+1:tt+max_lag) = Re(tt+1:tt+max_lag) + re_lag;
              
        if S(tt) < 1
            break;
        end
    end
    Re = cumsum([Re(1:T)]);
end