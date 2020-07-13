# Instructions

1. Copy the paste the following files into the current folder.
    ```
    global_deaths_quarantine_20.csv
    global_forecasts_quarantine_20.csv
    county_forecasts_quarantine_20.csv
    ```

2. In the files `format_data_state_death.py`, `format_data_state_case.py`, `format_data_county_case.py`, please change 
    ```
    FORECAST_DATE = datetime.datetime(2020, 7, 12) #CURRENT DATE, USUALLY SUNDAY
    FIRST_WEEK = datetime.datetime(2020, 7, 18) #THE NEXT SATURDAY
    ```

3. Run 
    ```
    python format_data_state_death.py
    python format_data_state_case.py
    python format_data_county_case.py.py
    ```

4. The re-formatted reports should be located at the current folder with the name `<FORECAST DATE>-USC-SI_kJalpha.csv`.