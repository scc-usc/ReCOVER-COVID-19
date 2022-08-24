function [d, m]=dtw_w(s,t,w)
% s: signal 1, size is ns*k, row for time, colume for channel 
% t: signal 2, size is nt*k, row for time, colume for channel 
% w: window parameter
%      if s(i) is matched with t(j) then |i-j|<=w
% d: resulting distance
if nargin<3
    w=Inf;
end
ns=size(s,1);
nt=size(t,1);
m = zeros(ns, 1);
if size(s,2)~=size(t,2)
    error('Error in dtw(): the dimensions of the two input signals do not match.');
end
w=max(w, abs(ns-nt)); % adapt window size
% initialization
D=zeros(ns+1,nt+1)+Inf; % cache matrix
D(1,1)=0;
% begin dynamic programming
for i=1:ns
    for j=max(i,1):min(i+w,nt)
        oost=norm(s(i,:)-t(j,:));
        [mval, midx]= min( [D(i,j+1), D(i+1,j), D(i,j)]);
        D(i+1,j+1) = mval + oost;
    end
end
d=D(ns+1,nt+1);

