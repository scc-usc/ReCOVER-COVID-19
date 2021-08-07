function dd = fill_zero_data(data_4)
% Fills in missing data in a cumulative setting
nn = size(data_4, 1);
dd = data_4;
for jj=1:nn
    nzidx = find(data_4(jj, :)>0);
    for nz = 2:length(nzidx)
        dd(jj, nzidx(nz-1)+1: nzidx(nz)-1) = data_4(jj, nzidx(nz-1));
    end
end
end

