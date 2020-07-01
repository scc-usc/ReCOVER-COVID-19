# Instructions

`format_data.py` will re-format our US state-level death forecast reports under the requirement of Reichlab Covid Forecast Hub.

1. Generate the forecast using the matlab script, copy the file `us_deaths_quarantine_20.csv` into the current directory `ReCOVER-COVID-19/results/format-covid-forecast/`.

2. Use text editor to edit `format_data.py`, you must make sure that
```FORECAST_DATE``` has been set to the current date, and ```FIRST_WEEK``` has been set to the Saturday of the next epidemic week. Usually, we update the forecast on Sunday, and the next Saturday is ```FIRST_WEEK```.
```
FORECAST_DATE = datetime.datetime(2020, 6, 28)  # e.g. Today is Sunday.
FIRST_WEEK = datetime.datetime(2020, 7, 4)      # e.g. Saturday on the next week.
```

3. Run the python script to generate the re-formatted report:
```
python format_data.py
```