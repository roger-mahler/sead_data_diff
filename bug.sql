
WITH categories(category, lower, upper) AS (
(
    SELECT n::text || ' => ' || (n + 6377)::text, n, n + 6377
    FROM generate_series(290, 765600, 6377) as a(n)
    WHERE n < 765600
)
), outerbounds(lower, upper) AS (
    SELECT MIN(lower), MAX(upper)
    FROM categories
)
    SELECT c.category, c.lower, c.upper, COALESCE(r.count_column, 0) as count_column
    FROM categories c
    LEFT JOIN (
        SELECT category, COUNT(DISTINCT tbl_analysis_entities.analysis_entity_id) AS count_column
        FROM tbl_geochronology
        CROSS JOIN outerbounds
        JOIN categories
            ON categories.lower <= cast(tbl_geochronology.age as decimal(15, 6))
            AND categories.upper >= cast(tbl_geochronology.age as decimal(15, 6))
            AND (NOT (categories.upper < outerbounds.upper AND cast(tbl_geochronology.age as decimal(15, 6)) = categories.upper))
            INNER JOIN tbl_analysis_entities ON tbl_analysis_entities."analysis_entity_id" = tbl_geochronology."analysis_entity_id" 
            INNER JOIN tbl_datasets ON tbl_datasets."dataset_id" = tbl_analysis_entities."dataset_id" 
        WHERE TRUE
            AND tbl_datasets.method_id in (3, 6)
        GROUP BY category
    ) AS r
        ON r.category = c.category
    ORDER BY c.lower
