loc_maps = readtable('locs_map_ihme.csv');

%%
load_data_global;
%%
ihme_countries = cell(length(countries), 1);

for cidx = 1:length(countries)
    
    this_count = countries{cidx};
    
    if strcmpi(this_count, 'Korea, South')
        this_count = 'South Korea';
    elseif strcmpi(this_count, 'Czechia')
        this_count = 'Czech Republic';
    elseif strcmpi(this_count, 'US')
        this_count = 'United States';
    elseif strcmpi(this_count, 'Russia')
        this_count = 'Russian Federation';
    elseif strcmpi(this_count, 'Bahamas')
        this_count = 'The Bahamas';
    elseif strcmpi(this_count, 'Congo (Brazzaville)')
        this_count = 'Congo';        
    elseif strcmpi(this_count, 'Congo (Kinshasa)')
        this_count = 'Democratic Republic of the Congo';   
    elseif strcmpi(this_count, 'Burma')
        this_count = 'Myanmar';
    elseif strcmpi(this_count, 'Gambia')
        this_count = 'The Gambia';
    elseif strcmpi(this_count, 'North Macedonia')
        this_count = 'Macedonia';
    elseif strcmpi(this_count, 'Cabo Verde')
        this_count = 'Cape Verde';
    end
    
    idx = find(strcmpi(loc_maps.location_ascii_name, this_count));
    if length(idx)==0
        disp([countries{cidx} ' not found']);
        ihme_countries{cidx} = this_count;
    else
        ihme_countries{cidx} = loc_maps.location_ascii_name{idx};
    end
end
writecell(ihme_countries, 'ihme_global.txt');
%%
load_data_us
%%
ihme_us_states = cell(length(countries), 1);

for cidx = 1:length(countries)
    
    this_count = countries{cidx};
    
    if strcmpi(this_count, 'Virgin Islands')
        this_count = 'Virgin Islands, U.S.';
    end
    
    idx = find(strcmpi(loc_maps.location_ascii_name, this_count));
    if length(idx)==0
        disp([countries{cidx} ' not found']);
        ihme_us_states{cidx} = this_count;
    else
        ihme_us_states{cidx} = loc_maps.location_ascii_name{idx};
    end
end
writecell(ihme_us_states, 'ihme_us.txt');