# Instructions

`fetch_forecast.py` will convert any forecast file that follows the Reichlab Covid Forecast Hub format into a report that shows the incident death in the next 14 days after its forecast day.

1. Copy the foreign forecast reports into the `input` folder.

2. Add the the filenames of the foreign reports into `JHU.txt`, `NYT.txt` or `USF.txt` depending on the data source the reports are using.

3. Run 
    ```
    python fetch_forecasts.py
    ```

4. The new reports will be created under `output` folder, the report's name will be `<model_name>_<number_of_epidemic_days>.csv`.