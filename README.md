# koha-sql-reports-misc

Miscellaneous saved SQL reports for [Koha ILS](https://koha-community.org/), written by [L2C2 Technologies](https://github.com/l2c2technologies) for the libraries we support.

Each report is built for a real request, so some depend on local conventions such as relabelled patron fields or card number formats. Every report's own README lists what it assumes and how to adapt it.

## Layout

One folder per report:

```
<report-name>/
├── report.sql   # paste into Koha as-is
└── README.md    # columns, parameters, prerequisites, adapting, limitations
```

## Using a report

1. In the staff interface, go to **Reports → New report → New SQL report**.
2. Paste the contents of `report.sql`, give it a name and group, and save.
3. Check the report's `README.md` for prerequisites (authorised value categories, system preferences, field relabelling) before running it.

The reports are read-only `SELECT` statements. Some use window functions or other newer SQL features, so check the database version listed in each report's README.
