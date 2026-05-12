BEGIN;

WITH new_movies AS (
    SELECT
        'Marvel' AS title,
        'The remaining Avengers try to fix the aftermath of Thanos destruction and bring back the missing heroes.' AS description,
        2011 AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        7 AS rental_duration,
        4.99 AS rental_rate,
        60 AS length,
        'R'::mpaa_rating AS rating

    UNION ALL

    SELECT
        'Avengers',
        'A team of superheroes unite to stop Loki and save the Earth from a global threat.',
        2008,
        (SELECT language_id FROM language WHERE lower(name) = 'english'),
        14,
        9.99,
        47,
        'R'::mpaa_rating

    UNION ALL

    SELECT
        'Batman',
        'A dark story about a young Batman who investigates mysterious murders in Gotham and encounters The Riddler.',
        2011,
        (SELECT language_id FROM language WHERE lower(name) = 'english'),
        21,
        19.99,
        115,
        'PG-13'::mpaa_rating
),

inserted_movies AS (
    INSERT INTO film (
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        length,
        rating,
        last_update
    )
    SELECT
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        length,
        rating,
        CURRENT_DATE
    FROM new_movies nm
    WHERE NOT EXISTS (
        SELECT 1
        FROM film f
        WHERE f.title = nm.title
          AND f.release_year = nm.release_year
    )
    RETURNING film_id, title, release_year
)

SELECT *
FROM inserted_movies;

SELECT
    film_id,
    title,
    release_year,
    rental_duration,
    rental_rate,
    rating,
    last_update
FROM film
WHERE title IN ('Marvel', 'Avengers', 'Batman');



INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Robert', 'Downey Jr.', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Robert'
      AND last_name = 'Downey Jr.'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Chris', 'Evans', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Chris'
      AND last_name = 'Evans'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Christian', 'Bale', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Christian'
      AND last_name = 'Bale'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Adam', 'West', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Adam'
      AND last_name = 'West'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Scarlett', 'Johansson', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Scarlett'
      AND last_name = 'Johansson'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Elizabeth', 'Olsen', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Elizabeth'
      AND last_name = 'Olsen'
);



INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Marvel' AND f.release_year = 2011
WHERE a.first_name = 'Robert'
  AND a.last_name = 'Downey Jr.'
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Marvel' AND f.release_year = 2011
WHERE a.first_name = 'Chris'
  AND a.last_name = 'Evans'
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Batman' AND f.release_year = 2011
WHERE a.first_name = 'Christian'
  AND a.last_name = 'Bale'
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Batman' AND f.release_year = 2011
WHERE a.first_name = 'Adam'
  AND a.last_name = 'West'
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Avengers' AND f.release_year = 2008
WHERE a.first_name = 'Scarlett'
  AND a.last_name = 'Johansson'
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Avengers' AND f.release_year = 2008
WHERE a.first_name = 'Elizabeth'
  AND a.last_name = 'Olsen'
ON CONFLICT DO NOTHING;



INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    f.film_id,
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
FROM film f
WHERE f.title = 'Marvel'
  AND f.release_year = 2011
  AND NOT EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.film_id = f.film_id
  );

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    f.film_id,
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
FROM film f
WHERE f.title = 'Batman'
  AND f.release_year = 2011
  AND NOT EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.film_id = f.film_id
  );

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    f.film_id,
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
FROM film f
WHERE f.title = 'Avengers'
  AND f.release_year = 2008
  AND NOT EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.film_id = f.film_id
  );

COMMIT;