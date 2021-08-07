function [Re,S,I,R] = sir_sim(betas,gammas,delta,N,I0,T,un)
    % if delta = 0 we assume a model without immunity loss
    if length(betas) == 1
        betas = ones(T, 1)*betas;
    end
    
    if length(un) == 1
        un = ones(T, 1)*un;
    end
    
    dt = 1/4;
    max_lag = 10/dt;
    
    S = zeros(1,T/dt);
    S(1) = N;
    I = zeros(1,T/dt);
    I(1) = I0;
    R = zeros(1,T/dt);
    Re = zeros(1,T/dt + max_lag);
    
    for tt = 1:(T/dt)-1
        % Equations of the model
        thisbeta = betas(ceil(tt*dt));
        thisun = un(ceil(tt*dt));
        newI = thisbeta*I(tt)*S(tt)/N;
        dS = (-newI + delta*R(tt)) * dt;
        dI = (newI - gammas*I(tt)) * dt;
        dR = (gammas*I(tt) - delta*R(tt)) * dt;
        S(tt+1) = S(tt) + dS;
        I(tt+1) = I(tt) + dI;
        R(tt+1) = R(tt) + dR;
        
        % The new infections today will be randomly reported over the next
        % "max_lag" number of days, and in total only 1/un(tt) fraction
        % will be reported
        dist_vec = rand(1, max_lag);
        re_lag = (dist_vec/sum(dist_vec))*(newI*dt/thisun);
        
        
        Re(tt+1:tt+max_lag) = Re(tt+1:tt+max_lag) + re_lag;
        
%         if I(tt+1) - I(tt) < 0
%             break;
%         end
%         
        if S(tt+1) < 1
            break;
        end
    end
    %I(tt+1:end) = I(tt); S(tt+1:end) = S(tt); R(tt+1:end) = R(tt);
    %disp(['Exit at ' num2str(tt) ' dS = ' num2str(dS) ' dI = ' num2str(dI)]);
    Re = cumsum([Re]);
    I = I(1:ceil(1/dt):end);
    Re = Re(1:ceil(1/dt):end);
    S = S(1:ceil(1/dt):end);
    R = R(1:ceil(1/dt):end);
end