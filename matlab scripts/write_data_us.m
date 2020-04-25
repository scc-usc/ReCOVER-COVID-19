%% Write forecasts
file_prefix = 'us';
writetable(infec2table(infec, countries), [file_prefix '_forecasts_quarantine.csv']);
writetable(infec2table(infec_f, countries), [file_prefix '_forecasts_quarantine1.csv']);
writetable(infec2table(0.5*(infec_f+infec), countries), [file_prefix '_forecasts_quarantine_avg.csv']);
writetable(infec2table(infec_released, countries), [file_prefix '_forecasts_released.csv']);
writetable(infec2table(infec_released_f, countries), [file_prefix '_forecasts_released1.csv']);
writetable(infec2table(0.5*(infec_released+infec_released_f), countries), [file_prefix '_forecasts_released_avg.csv']);

disp('Files written');
