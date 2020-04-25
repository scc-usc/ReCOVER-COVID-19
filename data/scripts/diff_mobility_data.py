from scripts.settings import COVID_19_CSV_PATH, MOBILITY_CSV_PATH
import csv


def main():
    covid_file = open(COVID_19_CSV_PATH)
    mob_file = open(MOBILITY_CSV_PATH)

    covid_reader = csv.reader(covid_file)
    mob_reader = csv.reader(mob_file)

    covid_csv_countries = set()

    next(covid_reader, None)
    for row in covid_reader:
        state = row[0]
        country = row[1]
        covid_csv_countries.add(country)

    mob_csv_countries = set()

    next(mob_reader, None)
    for row in mob_reader:
        from_country = row[1]
        to_country = row[2]

        mob_csv_countries.add(from_country)
        mob_csv_countries.add(to_country)

    to_remove = []
    for country in mob_csv_countries:
        if any(c.isdigit() for c in country):
            to_remove.append(country)

    for c in to_remove:
        mob_csv_countries.remove(c)

    print(sorted(list(covid_csv_countries - mob_csv_countries)))
    print(sorted(list(mob_csv_countries - covid_csv_countries)))


if __name__ == "__main__":
    main()
