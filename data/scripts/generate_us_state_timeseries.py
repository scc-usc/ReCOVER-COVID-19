from scripts.settings import COVID_19_CSV_PATH, US_STATE_DATA_PATH
import csv
import datetime


def main():
    with open(COVID_19_CSV_PATH) as covid_file, open(US_STATE_DATA_PATH) as us_file:
        covid_reader = csv.reader(covid_file)
        us_reader = csv.reader(us_file)

        # Skip header for US states file.
        next(us_reader, None)

        # Save COVID-19 header so we can map dates properly.
        covid_header = next(covid_reader, None)
        date_to_idx = {}
        for i in range(4, len(covid_header)):
            date = covid_header[i]
            date_to_idx[date] = i

        # Map of US State -> timeseries csv row that we want to write.
        state_to_row = {}

        for row in us_reader:
            raw_date = row[0]
            state = row[1]
            val = row[3]

            date_obj = datetime.datetime.strptime(raw_date, "%Y-%m-%d")
            fmt_date = '{m}/{d}/{y}'.format(
                m=date_obj.month,
                d=date_obj.day,
                y=str(date_obj.year)[-2:])

            if state not in state_to_row:
                state_to_row[state] = [0] * len(covid_header)
                state_to_row[state][0] = state
                state_to_row[state][1] = "US"
                # Write zeros for lat/long since they're not used by frontend.
                state_to_row[state][2] = 0
                state_to_row[state][3] = 0

            # We need to check if the date from the US state csv exists in the
            # covid-19 timeseries csv. If it doesn't, it's most likely that this
            # date occured before the covid-19 timeseries, and it should be safe
            # to discard this data.
            if fmt_date in date_to_idx:
                date_idx = date_to_idx[fmt_date]
                state_to_row[state][date_idx] = val

    with open(COVID_19_CSV_PATH, 'a') as f:
        writer = csv.writer(f, lineterminator="\n")
        for row in state_to_row.values():
            writer.writerow(row)


if __name__ == "__main__":
    main()
