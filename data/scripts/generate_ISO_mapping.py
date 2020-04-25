from scripts.settings import \
    COVID_19_CSV_PATH, \
    ISO_LOOKUP_TABLE_PATH, \
    ISO_MAPPING_OUTPUT_PATH, \
    STATE_ISO_MAPPING_PATH
import csv


def load_state_mapping():
    """
    :return: A 2-level dictionary where the 1st key is the country/region name
    and the 2nd key is the state/province name. The value stored is the ISO2
    code used by Amcharts 4.
    """
    with open(STATE_ISO_MAPPING_PATH) as f:
        reader = csv.reader(f)
        next(reader, None)

        state_mapping = {}
        for row in reader:
            state = row[0]
            country = row[1]
            iso2 = row[2]

            if country not in state_mapping:
                state_mapping[country] = {}
            state_mapping[country][state] = iso2

        return state_mapping


def main():
    iso_file = open(ISO_LOOKUP_TABLE_PATH)
    covid_file = open(COVID_19_CSV_PATH)

    covid_reader = csv.reader(covid_file)
    iso_reader = csv.reader(iso_file)

    area_to_iso = {}
    # Skip header.
    next(iso_reader, None)
    for row in iso_reader:
        iso_2 = row[1]
        state = row[6]
        country = row[7]

        if country not in area_to_iso:
            area_to_iso[country] = {}
        area_to_iso[country][state] = iso_2

    errors = []

    state_mapping = load_state_mapping()

    # Skip header.
    next(covid_reader, None)

    # Check for errors. Ensure that all regions in the COVID-19 data have a
    # valid mapping.
    for row in covid_reader:
        state = row[0]
        country = row[1]

        if country in area_to_iso and state in area_to_iso[country]:
            continue
        if country in state_mapping and state in state_mapping[country]:
            continue

        errors.append(state + country)

    # Write the entire ISO2 mapping file (this helps in case we need to
    # extrapolate country-level data) from regional data later on.
    with open(ISO_MAPPING_OUTPUT_PATH, "w") as f:
        writer = csv.writer(f)

        header = ["Province/State", "Country/Region", "ISO2"]
        writer.writerow(header)

        # Skip header.
        next(covid_reader, None)
        for country in area_to_iso:
            for state in area_to_iso[country]:
                try:
                    iso_2 = area_to_iso[country][state]

                    if country in state_mapping and state in state_mapping[
                        country]:
                        iso_2 = state_mapping[country][state]

                    writer.writerow([state, country, iso_2])
                except Exception:
                    writer.writerow([state, country, "UNKNOWN"])

    print("Finished writing.")
    print("Encountered " + str(len(errors)) + " errors: ")
    for msg in errors:
        print("\t - " + msg)


if __name__ == "__main__":
    main()
