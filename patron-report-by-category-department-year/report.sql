/*
 * Patron Report (by Category, Department & Year)
 * Koha 22.11+ / MariaDB 10.2+ or MySQL 8.0+ (uses window functions)
 * See README.md for field mapping, parameters and customisation.
 */
SELECT
  x.cardnumber                                                        AS `Card No.`,
  CONCAT_WS(' ', NULLIF(x.firstname,''), NULLIF(x.middle_name,''),
                 NULLIF(x.surname,''))                                AS `Name`,
  DATE_FORMAT(x.dateofbirth, '%d-%m-%Y')                              AS `DOB`,
  x.othernames                                                        AS `Blood Gr.`,
  x.pronouns                                                          AS `ABC Reg. No.`,
  CONCAT_WS(', ', NULLIF(x.address,''), NULLIF(x.address2,''),
                  NULLIF(x.city,''), NULLIF(x.state,''),
                  NULLIF(x.zipcode,''))                               AS `Address`,
  COALESCE(NULLIF(x.mobile,''), NULLIF(x.phone,''))                   AS `Mob. No.`,
  x.email                                                             AS `Email Id`,
  DATE_FORMAT(x.dateenrolled, '%d-%m-%Y')                             AS `Registration Dt.`,
  DATE_FORMAT(x.dateexpiry,   '%d-%m-%Y')                             AS `Expiry Dt.`,
  CONCAT('<a href="/cgi-bin/koha/members/moremember.pl?borrowernumber=',
         x.borrowernumber, '" target="_blank">View</a>')              AS ``
FROM (
  SELECT b.*,
    COALESCE(NULLIF(b.sort1,''), m.dept, '')                          AS dept_x,
    CASE WHEN b.cardnumber REGEXP '^[A-Z]{2}(UG|PG)/[0-9]+/[0-9]{2}$'
         THEN 2000 + CAST(SUBSTRING_INDEX(b.cardnumber,'/',-1) AS UNSIGNED)
         ELSE YEAR(b.dateenrolled)
    END                                                               AS year_x
  FROM borrowers b
  /* prefix -> department, learnt from patrons whose sort1 is already filled */
  LEFT JOIN (
    SELECT pfx, dept FROM (
      SELECT LEFT(cardnumber,2) AS pfx, sort1 AS dept,
             ROW_NUMBER() OVER (PARTITION BY LEFT(cardnumber,2)
                                ORDER BY COUNT(*) DESC) AS rn
      FROM borrowers
      WHERE sort1 <> ''
        AND cardnumber REGEXP '^[A-Z]{2}(UG|PG)/[0-9]+/[0-9]{2}$'
      GROUP BY LEFT(cardnumber,2), sort1
    ) t WHERE rn = 1
  ) m ON  b.cardnumber REGEXP '^[A-Z]{2}(UG|PG)/[0-9]+/[0-9]{2}$'
      AND m.pfx = LEFT(b.cardnumber,2)
) x
WHERE x.categorycode LIKE <<Patron category|categorycode:all>>
  AND x.dept_x       LIKE <<Department|Bsort1:all>>
  AND x.year_x       LIKE <<Year (YYYY or % for all)>>
ORDER BY x.cardnumber
