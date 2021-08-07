alpha = [0.1 0.3 0.4 0.2 0.2 0.15 0.1];
y0 = [1 1 1 1 1 1 1];
sus = ones(100, 1);
% for j=2:length(sus)
%      sus(j) = (1 + 0.1*(rand(1)-1))*sus(j-1)*(1 - 0.01*rand(1));
% end

y = gen_trend(y0, alpha, sus);
y1 = gen_trend(rand(length(alpha), 1), alpha, sus);
ralpha = rand(length(alpha), 1); ralpha = sum(alpha)*ralpha./sum(ralpha);
y2 = gen_trend(rand(length(alpha), 1), ralpha, sus);
y3 = gen_trend(rand(length(alpha), 1), 1.5*ralpha, sus);

figure; plot([y y1 y2 y3])

figure; plot(diff(y)./y(2:end)); hold on;
plot(diff(y1)./y1(2:end)); hold on;
plot(diff(y2)./y2(2:end)); hold on;
plot(diff(y3)./y3(2:end)); hold off; 
ylim([0, 0.5]);

figure;semilogy([y./y2 y1./y2 y3./y2])

%%
[y, z] = gen_trend(y0, alpha, sus*0+1);
%%
function [y, z] = gen_trend(y0, alpha, coeff)
y = zeros(100, 1); y(1:length(y0)) = y0;
z = zeros(100, 1); z(1:length(y0)) = y0;
conv_f = [alpha];
for j = length(y0)+1:length(y)
    y(j) =coeff(j)*dot(y(j-length(y0):j-1),alpha);
    %this_conv = conv(y0, conv_f);
    this_conv = conv_f;
    z(j) = prod(coeff(length(y0)+1:j))*sum(this_conv(j-1));
    conv_f = conv(conv_f, [alpha]);
end
end
