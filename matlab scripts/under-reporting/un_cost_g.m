function [L, G] = un_cost_g(xvec, Ul, Uu, yo, N)
M = 0;
nw = length(xvec);
u = xvec(1:nw);
y = u.*yo;
ny = diff(y);
betas = ny(1:nw-2).*(1-y(1:nw-2)./N)./ny(2:nw-1); % Rough estimation of infection rates inverse
L =  sum((diff(u)).^2) + sum((diff(betas)).^2); % Roughly two consecutive weekly infection rate should be close

G = zeros(1, nw);

for t=1:nw
    udel = 0;
    if t>1
        udel = udel+(u(t)-u(t-1));
    end
    if t<nw
        udel =  udel - (u(t+1)-u(t));
    end
    
    beta_grad = 0;
    if t>2 && t < nw
        b1 = (betas(t-1)-betas(t-2))*(yo(t)*(betas(t-1)-betas(t-2))/(y(t)-y(t-1)) - betas(t-1)*yo(t)/(N-y(t)));
        beta_grad = beta_grad + b1;
    end
    
    if t>1 && t<nw-2
        b2 = (betas(t)-betas(t-1))*( (-yo(t)*betas(t)/(y(t+1)-y(t))) - (betas(t-1)*yo(t)/(y(t)-y(t-1))) + (betas(t-1)*yo(t)/(N-y(t))) );
        beta_grad = beta_grad + b2;
    end
    
    G(t) = 2*(udel + beta_grad);
end
end