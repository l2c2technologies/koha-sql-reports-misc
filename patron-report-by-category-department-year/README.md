# Patron Report (by Category, Department & Year)

A Koha saved SQL report that lists patron details, filtered by patron category, department and year. It was written for an academic library that keeps a few non-standard patron fields in otherwise unused `borrowers` columns, and whose student card numbers encode the department and the batch year.

| | |
|---|---|
| **Koha** | 22.11 (should work on 21.05 and later) |
| **Database** | MariaDB 10.2+ / MySQL 8.0+ (needs window functions) |
| **Report group** | Patrons |
| **File** | [`report.sql`](report.sql) |

## Output columns

| Column | Source |
|---|---|
| Card No. | `cardnumber` |
| Name | `firstname` + `middle_name` + `surname` |
| DOB | `dateofbirth` (dd-mm-yyyy) |
| Blood Gr. | `othernames` (relabelled) |
| ABC Reg. No. | `pronouns` (relabelled) |
| Address | `address`, `address2`, `city`, `state`, `zipcode`, comma-joined, blanks skipped |
| Mob. No. | `mobile`, falling back to `phone` |
| Email Id | `email` |
| Registration Dt. | `dateenrolled` (dd-mm-yyyy) |
| Expiry Dt. | `dateexpiry` (dd-mm-yyyy) |
| *(no heading)* | **View** link to the patron record (`members/moremember.pl`), opens in a new tab |

## Runtime parameters

| Prompt | Type | Notes |
|---|---|---|
| Patron category | Dropdown from `categories` | **All** is offered (`:all`) |
| Department | Dropdown from the `Bsort1` authorised values | **All** is offered (`:all`) |
| Year (YYYY or % for all) | Free text | e.g. `2025`, or `%` for every year |

Selecting **All** sends `%`, so every filter is matched with `LIKE` rather than `=`.

## How Department and Year are worked out

### Department

1. The report uses `sort1` (relabelled *Department*) when it has a value.
2. If `sort1` is blank and the card number matches `XXUG/NNN/YY` or `XXPG/NNN/YY`, the department comes from the two-letter prefix (`XX`).
3. The prefix-to-department lookup is **built from the data itself**: for each prefix, the most common `sort1` among patrons with that prefix whose `sort1` is already filled. Nothing is hardcoded. A new department starts resolving as soon as a few of its patrons have `sort1` set.
4. Patrons with neither a `sort1` value nor a matching card number appear only when Department is set to **All**.

### Year

- **Students** (card number matches the pattern above): the batch year from the card suffix, where `YY` becomes `20YY`. So `CHUG/027/25` is in the 2025 batch.
- **Everyone else**: `YEAR(dateenrolled)`.

The batch year was chosen over the registration year because admissions sometimes fall in the calendar year after the batch year (e.g. a 2020 batch registered in early 2021).

## Prerequisites

The relabelling is done in the staff interface through `IntranetUserJS`. The report reads the underlying columns:

```javascript
$(document).ready(function(){
  $('label[for="othernames"]').text( 'Blood Group' );
  $('label[for="pronouns"]').text( 'ABC Reg. No' );
  $('label[for="sort1"]').text( 'Department' );
  $('label[for="sort2"]').text( 'Designation' );
  $('#patron-sort1 > span').text( 'Department' );
  $('#patron-sort2 > span').text( 'Designation' );
});
```

The `Bsort1` authorised value category must hold the department names. If it is empty, the Department dropdown will be empty too. To fill it from the values already in use:

```sql
INSERT INTO authorised_values (category, authorised_value, lib)
SELECT DISTINCT 'Bsort1', sort1, sort1 FROM borrowers WHERE sort1 <> '';
```

Once `Bsort1` has values, Koha also shows `sort1` as a dropdown on the patron entry form, which keeps future entries consistent.

## Installation

1. **Reports → New report → New SQL report**.
2. Name: `Patron Report (by Category, Department & Year)`. Group: *Patrons*.
3. Paste the contents of [`report.sql`](report.sql) and save.
4. Run it, pick the filters, and use **Download** for CSV / tab / ODS.

## Adapting it to another library

| What differs | What to change |
|---|---|
| Different columns hold Blood Group / ABC Reg. No. | The `x.othernames` / `x.pronouns` select lines |
| Different card number format | The regex `'^[A-Z]{2}(UG\|PG)/[0-9]+/[0-9]{2}$'` (it appears **three** times; keep them identical), plus `LEFT(...,2)` if the prefix length differs |
| Department kept in `sort2` or a patron attribute | `b.sort1` in `dept_x`, the inner lookup query, and `Bsort1` in the parameter |
| `phone` is the primary mobile number | Swap the order in the `COALESCE` for *Mob. No.* |

## Known limitations

- **Downloads**: the View column contains the raw `<a href=…>` HTML in CSV/ODS. Delete the column after export if it isn't wanted.
- **No title rows**: Koha exports a plain table, so any institution name or report title header has to be added by hand.
- **Duplicate authorised values**: if `Bsort1` has the same value more than once, the Department dropdown shows it more than once. This is cosmetic; remove the duplicates under *Administration → Authorised values*.
- **Prefix inference is a fallback**: the cleanest fix is a one-off backfill of blank `sort1` values from the card prefix. That needs an `UPDATE` on production data, so it is deliberately left out of this report.
