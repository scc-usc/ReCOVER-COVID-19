function [c, ceq_all] = variant_t_cons_all(st, ii, tvals, cid_all, unique_cid)

eps = 0.1;
d1_all = []; d2_all = [];
ceq_all = [];
nn = length(cid_all);

for j=1:length(unique_cid)
    cid = unique_cid(j);
    this_cid = cid_all==cid;
    this_st = st(this_cid);
    tt = tvals(this_cid);
    
    ceq = (log(ii(this_cid)) - log(1+exp(this_st))).*st(end-1) + this_st + (tt).*st(end) + st(nn+j);
    ceq_all = [ceq_all ceq];
    
    d1 = (this_st(1:end-1)-this_st(2:end))./(tt(1:end-1)-tt(2:end));
    d2 = (d1(1:end-1) - d1(2:end))./(tt(2:end-1)-tt(3:end));
    
    d1_all = [d1_all d1];
    d2_all = [d2_all d2];
end

c = [d1_all d2_all] - eps;
end