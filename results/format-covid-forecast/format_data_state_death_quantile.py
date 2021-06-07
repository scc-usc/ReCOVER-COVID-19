import math
import datetime
import pytz
import pandas as pd
import csv
import urllib.request
import io

FORECAST_DATE = datetime.datetime.now(pytz.timezone('US/Pacific'))
FORECAST_DATE = FORECAST_DATE.replace(tzinfo=None)
# FIRST_WEEK is the first Saturday after forecast date.
FIRST_WEEK = FORECAST_DATE
for i in range(0, 8):
    if FIRST_WEEK.weekday() == 5:
        break
    FIRST_WEEK += datetime.timedelta(1)
INPUT_FILENAME_STATE = "./us_deaths_quants.csv"
OUTPUT_FILENAME = FORECAST_DATE.strftime("%Y-%m-%d") + "-USC-SI_kJalpha.csv"
COLUMNS = ["forecast_date", "target", "target_end_date", "location", "type", "quantile", "value"]
ID_STATE_MAPPING = {}
STATE_ID_MAPPING = {}

def load_state_id_mapping():
    """
    Return a mapping of <state name, state id>.
    """

    MAPPING_CSV = "./locations_state.csv"
    with open(MAPPING_CSV) as f:
        reader = csv.reader(f)
        state_id_mapping = {}

        # Skip the header
        next(reader)

        for row in reader:
            state_id = row[1]
            state_name = row[2]
            state_id_mapping[state_name] = state_id

        return state_id_mapping


def load_id_state_mapping():
    """
    Return a mapping of <state id, state name>.
    """

    MAPPING_CSV = "./locations.csv"
    with open(MAPPING_CSV) as f:
        reader = csv.reader(f)
        id_state_mapping = {}

        # Skip the header
        next(reader)

        for row in reader:
            state_id = row[1]
            state_name = row[2]
            id_state_mapping[state_id] = state_name

        return id_state_mapping



def load_truth_cumulative_deaths():
    """
    Load the observed cumulative deaths from the data source.
    Return A 2D dictionary structuring of <date_str, <state_id, value>>
    An example looks like:
    {
        "2020-06-17" : {
            "10": 1000,
            "11": 2000,
            ...
        },
        "2020-06-18" : {
            "10": 1100,
            "11": 2100,
            ...
        },
    }
    """
    dataset = {}
    us_death_timeseries = "us_deaths.csv"
    global_death_timeseries = "global_deaths.csv"
    with open(us_death_timeseries) as f:
        reader = csv.reader(f)
        header = next(reader, None)

        for row in reader:
            state = row[1]
            if state not in STATE_ID_MAPPING:
                continue
            state_id = STATE_ID_MAPPING[state]
            date = header[-1]
            val = int(row[-1])
            if date not in dataset:
                dataset[date] = {}

            dataset[date][state_id] = val

    with open(global_death_timeseries) as f:
        reader = csv.reader(f)
        header = next(reader, None)

        for row in reader:
            country = row[1]
            if country != "US":
                continue
            date = header[-1]
            val = int(row[-1])
            if date not in dataset:
                dataset[date] = {}

            dataset[date][country] = val

    return dataset


def load_csv(input_filename_state):
    """
    Read our forecast reports and return a dictionary structuring
    of <week_ahead, <state_id, <quantile, weekly_inc_death>>>
    e.g:
    {
        1: {
            '10':{
                0.05: 2000.0,
                0.10: 2100.0,
                ...

            },
            '11': {
                0.05: 3000.0,
                0.10: 3100.0,
                ...
            }
            ...
        },
    }
    """
    dataset = {}
    with open(input_filename_state) as f:
        reader = csv.reader(f)
        header = next(reader, None)

        location_col = -1
        week_ahead_col = -1
        quantile_col = -1
        value_col = -1


        for i in range(len(header)):
            if header[i] == "place":
                location_col = i
            elif header[i] == "week_ahead":
                week_ahead_col = i
            elif header[i] == "quantile":
                quantile_col = i
            elif header[i] == "value":
                value_col = i

        for row in reader:
            state = row[location_col]

            # Skip the state if it is not listed in reichlab's state list.
            if state not in STATE_ID_MAPPING:
                continue
            state_id = STATE_ID_MAPPING[state]
            week_ahead = int(row[week_ahead_col])
            quantile = row[quantile_col]
            val = max(float(row[value_col]), 0)
            if math.isnan(val):
                val = 0
            if week_ahead not in dataset:
                dataset[week_ahead] = {}
            if state_id not in dataset[week_ahead]:
                dataset[week_ahead][state_id] = {}
            dataset[week_ahead][state_id][quantile] = val
    return dataset


def generate_new_row(forecast_date, target, target_end_date,
                    location, type, quantile, value):
    """
    Return a new row to be added to the pandas dataframe.
    """
    new_row = {}
    new_row["forecast_date"] = forecast_date
    new_row["target"] = target
    new_row["target_end_date"] = target_end_date
    new_row["location"] = location
    new_row["type"] = type
    new_row["quantile"] = quantile
    new_row["value"] = value
    return new_row



def generate_dataframe(forecast, observed):
    """
    Given our forecast and observed data, generate a pandas dataframe according to reichlab's required format.
    """
    dataframe = pd.DataFrame(columns=COLUMNS, dtype=str)

    # Write cumulative forecasts.
    forecast_date_str = FORECAST_DATE.strftime("%Y-%m-%d")
    for cum_week in sorted(forecast.keys()):
        target_end_date = FIRST_WEEK + ((cum_week - 1) * datetime.timedelta(7))
        target_end_date_str = target_end_date.strftime("%Y-%m-%d")
        # Terminate the loop after 8 weeks of forecasts.
        if cum_week >= 8:
            break

        # Skip forecasts before the forecast date.
        if target_end_date <= FORECAST_DATE:
            continue

        # Write a row for "weeks ahead" if forecast end day is a Saturday.
        if target_end_date >= FIRST_WEEK and target_end_date.weekday() == 5:
            target = str(cum_week) + " wk ahead cum death"
            for state_id in forecast[cum_week].keys():
                for quantile in forecast[cum_week][state_id].keys():
                    val = observed[(FORECAST_DATE - datetime.timedelta(1)).strftime("%Y-%m-%d")][state_id]
                    for i in range(1, cum_week + 1):
                        val += forecast[i][state_id][quantile]
                    if quantile == "point":
                        dataframe = dataframe.append(
                            generate_new_row(
                                forecast_date=forecast_date_str,
                                target=target,
                                target_end_date=target_end_date_str,
                                location=str(state_id),
                                type="point",
                                quantile="NA",
                                value=val
                            ), ignore_index=True)
                    else:
                        dataframe = dataframe.append(
                            generate_new_row(
                                forecast_date=forecast_date_str,
                                target=target,
                                target_end_date=target_end_date_str,
                                location=str(state_id),
                                type="quantile",
                                quantile=quantile,
                                value=val
                            ), ignore_index=True)

    # Write incident forecasts.
    forecast_date_str = FORECAST_DATE.strftime("%Y-%m-%d")
    for cum_week in sorted(forecast.keys()):
        target_end_date = FIRST_WEEK + ((cum_week - 1) * datetime.timedelta(7))
        target_end_date_str = target_end_date.strftime("%Y-%m-%d")
        # Terminate the loop after 8 weeks of forecasts.
        if cum_week >= 8:
            break

        # Skip forecasts before the forecast date.
        if target_end_date <= FORECAST_DATE:
            continue

        if target_end_date >= FIRST_WEEK and target_end_date.weekday() == 5:
            target = str(cum_week) + " wk ahead inc death"
            for state_id in forecast[cum_week].keys():
                for quantile in forecast[cum_week][state_id].keys():
                    if quantile == "point":
                        dataframe = dataframe.append(
                            generate_new_row(
                                forecast_date=forecast_date_str,
                                target=target,
                                target_end_date=target_end_date_str,
                                location=str(state_id),
                                type="point",
                                quantile="NA",
                                value=forecast[cum_week][state_id][quantile]
                            ), ignore_index=True)
                    else:
                        dataframe = dataframe.append(
                            generate_new_row(
                                forecast_date=forecast_date_str,
                                target=target,
                                target_end_date=target_end_date_str,
                                location=str(state_id),
                                type="quantile",
                                quantile=quantile,
                                value=forecast[cum_week][state_id][quantile]
                            ), ignore_index=True)

    return dataframe

# Main function
if __name__ == "__main__":
    STATE_ID_MAPPING = load_state_id_mapping()
    ID_STATE_MAPPING = load_id_state_mapping()
    print("loading forecast...")
    forecast = load_csv(INPUT_FILENAME_STATE)
    observed = load_truth_cumulative_deaths()
    dataframe = generate_dataframe(forecast, observed)
    print("writing files...")
    dataframe.to_csv(OUTPUT_FILENAME, index=False)
    print("done")