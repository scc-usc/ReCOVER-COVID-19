function [xx] = nan2zero(xx)
%NAN2ZERO Summary of this function goes here
%   Detailed explanation goes here
xx(isnan(xx)) = 0;
end

