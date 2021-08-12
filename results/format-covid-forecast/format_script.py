
import os
import pytz
import datetime
import shutil

FORECAST_DATE = datetime.datetime.now(pytz.timezone('US/Pacific'))
FORECAST_DATE = FORECAST_DATE.replace(tzinfo=None)
for i in range(0, 8):
    if FORECAST_DATE.weekday() == 6:
        break
    FORECAST_DATE -= datetime.timedelta(1)
DATE_PREFIX = FORECAST_DATE.strftime("%Y-%m-%d")

shutil.copy("../forecasts/county_data.csv", "./")
shutil.copy("../forecasts/county_forecasts_quarantine_0.csv", "./")
shutil.copy("../forecasts/us_deaths.csv", "./")
shutil.copy("../forecasts/global_deaths.csv", "./")

print("Format state death quantile forecasts:")
exec(open("format_data_state_death_quantile.py").read())
print("Format state case quantile forecasts:")
exec(open("format_data_state_case_quantile.py").read())
print("Format county case forecasts:")
exec(open("format_data_county_case.py").read())

os.system("cat us_hosp_quants.csv >> {}-USC-SI_kJalpha.csv".format(DATE_PREFIX))