
import os
import pytz
import datetime
import shutil

FORECAST_DATE = datetime.datetime.now(pytz.timezone('US/Pacific'))
FORECAST_DATE = FORECAST_DATE.replace(tzinfo=None)
DATE_PREFIX = FORECAST_DATE.strftime("%Y-%m-%d")

shutil.copy("../forecasts/county_data.csv", "./")
shutil.copy("../forecasts/county_forecasts_quarantine_0", "./")
shutil.copy("../forecasts/us_deaths.csv", "./")
shutil.copy("../forecasts/global_deaths.csv", "./")

exec(open("format_data_state_death_quantile.py").read())
exec(open("format_data_state_case_quantile.py").read())
exec(open("format_data_county_case.py").read())

os.system("cat us_hosp_quants.csv >> {}-USC-SI_kJalpha.csv".format(DATE_PREFIX))