## Forecasting

To generate forecasts, run
`daily_run.m`

The code is divided into sections for US state-level forecasts and global country-level forecasts that can be individually run
Population data , travel data, and country names are included here. COVID-19 related data is pulled from https://github.com/CSSEGISandData/COVID-19


### Visualizing Reported Cases in Matlab

Run live script `death_forecasts.mlx` to visualize forecasts instead of writing forecasts in files.

### Comparing death forecasts

To compare death forecasts of our approach and various other models used by CDC on US states, use the live script: `evaluate_deaths.mlx`

### Unreported Cases

To test the code for estimation of unreported cases, use the live script: `daily_explore_unrep.mlx`