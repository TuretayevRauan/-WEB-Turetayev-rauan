BEGIN;



WITH new_movies AS (
    SELECT
        'Marvel'   AS title,
        'The remaining Avengers try to fix it '
        || 'the aftermath of Thanos destruction and bring back the missing heroes. '
          AS description,
        2011               AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        7                  AS rental_duration,
        4.99               AS rental_rate,
        60                 AS length,
        'R'::mpaa_rating   AS rating

    UNION ALL

    SELECT
        'Avengers'      AS title,
        'A team of superheroes unite, '
        || 'to stop Loki and save the Earth from a global threat. '
        AS description,
        2008               AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        14                 AS rental_duration,
        9.99               AS rental_rate,
        47                 AS length,
        'R'::mpaa_rating   AS rating

    UNION ALL

    SELECT
        'Batman'              AS title,
        'A dark story about a young Batman '
        || 'who investigates a series of mysterious murders in Gotham  '
        || 'and encounters the dangerous criminal The Riddler.'                    AS description,
        2011               AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        21                 AS rental_duration,
        19.99              AS rental_rate,
        115                AS length,
        'PG-13'::mpaa_rating AS rating
),

inserted_movies AS (
    INSERT INTO film
        (title, description, release_year, language_id,
         rental_duration, rental_rate, length, rating, last_update)
    SELECT
        nm.title, nm.description, nm.release_year, nm.language_id,
        nm.rental_duration, nm.rental_rate, nm.length, nm.rating,
        CURRENT_DATE
    FROM new_movies nm
    WHERE NOT EXISTS (
        SELECT 1 FROM film f
        WHERE f.title = nm.title AND f.release_year = nm.release_year
    )
    RETURNING film_id, title, release_year, rental_duration, rental_rate, last_update
)
SELECT film_id, title, release_year, rental_duration, rental_rate, last_update
FROM inserted_movies;

SELECT film_id, title, release_year, rental_duration, rental_rate, rating, last_update
FROM film
WHERE title IN ('Marvel', 'Avengers', 'Batman')
  AND release_year IN (2011, 2008);



INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Robert', 'Downey Jr.', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Robert' AND last_name = 'Downey Jr');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Chris', 'Evans ', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Chris' AND last_name = 'Evans ');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Christian ', 'Bale ', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Christian  ' AND last_name = 'Bale ');


INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Adam ', 'West ', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Adam ' AND last_name = 'West ');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Scarlett ', 'Johansson ', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Scarlett ' AND last_name = 'Johansson ');


INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Elizabeth', ' Olsen', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Elizabeth' AND last_name = ' Olsen');


SELECT actor_id, first_name, last_name, last_update
FROM actor
WHERE (first_name = 'Robert'   AND last_name = 'Downey Jr')
   OR (first_name = 'Chris'     AND last_name = 'Evans')
   OR (first_name = 'Christian'  AND last_name = 'Bale')
   OR (first_name = 'Adam'  AND last_name = 'West')
   OR (first_name = 'Scarlett' AND last_name = 'Johansson')
   OR (first_name = 'Elizabeth'   AND last_name = 'Olsen');

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Robert' AND last_name = 'Downey Jr'),
    (SELECT film_id  FROM film  WHERE title = 'Marvel' AND release_year = 2011),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Chris' AND last_name = 'Evans'),
    (SELECT film_id  FROM film  WHERE title = 'Marvel' AND release_year = 2011),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Christian' AND last_name = 'Bale'),
    (SELECT film_id  FROM film  WHERE title = 'Batman' AND release_year = 2011),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Adam' AND last_name = 'West'),
    (SELECT film_id  FROM film  WHERE title = 'Batman' AND release_year = 2008),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Scarlett' AND last_name = 'Johansson'),
    (SELECT film_id  FROM film  WHERE title = 'Avengers' AND release_year = 2008),
    CURRENT_DATE
ON CONFLICT DO NOTHING;


INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Elizabeth' AND last_name = 'Olsen'),
    (SELECT film_id  FROM film  WHERE title = 'Avengers' AND release_year = 2011),
    CURRENT_DATE
ON CONFLICT DO NOTHING;


INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Marvel' AND release_year = 2011),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id  = (SELECT film_id FROM film WHERE title = 'Marvel' AND release_year = 2011)
      AND store_id = (SELECT MIN(store_id) FROM store)
);

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Batman' AND release_year = 2008),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id  = (SELECT film_id FROM film WHERE title = 'Batman' AND release_year = 2008)
      AND store_id = (SELECT MIN(store_id) FROM store)
);

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Avengers' AND release_year = 2011),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id  = (SELECT film_id FROM film WHERE title = 'Avengers' AND release_year = 2011)
      AND store_id = (SELECT MIN(store_id) FROM store)
);


SELECT i.inventory_id, f.title, i.store_id, i.last_update
FROM inventory i
JOIN film f ON i.film_id = f.film_id
WHERE f.title IN ('Marvel', 'Batman', 'Avengers')
  AND f.release_year IN (2011, 2008);



SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT r.rental_id)  AS rental_count,
    COUNT(DISTINCT p.payment_id) AS payment_count
FROM customer c
JOIN rental  r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT r.rental_id)  >= 43
   AND COUNT(DISTINCT p.payment_id) >= 43
ORDER BY rental_count DESC
LIMIT 1;


UPDATE customer
SET
    first_name  = 'Rauan',
    last_name   = 'Turetayev',
    email       = 'rturetaev23@apec.edu.kz',
    address_id  = (SELECT MIN(address_id) FROM address),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental  r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id)  >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    ORDER BY COUNT(DISTINCT r.rental_id) DESC
    LIMIT 1
);

SELECT customer_id, first_name, last_name, email, address_id, last_update
FROM customer
WHERE first_name = 'Rauan' AND last_name = 'Turetayev';



SELECT * FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Rauan' AND last_name = 'Turetayev'
);

DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Rauan' AND last_name = 'Turetayev'
);


SELECT * FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Rauan' AND last_name = 'Turetayev'
);

DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Rauan' AND last_name = 'Turetayev'
);


WITH rental_got AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT
        '2017-01-15 10:00:00'::TIMESTAMP,
        (
            SELECT i.inventory_id FROM inventory i
            JOIN film f ON i.film_id = f.film_id
            WHERE f.title = 'Marvel' AND f.release_year = 2011
              AND i.store_id = (SELECT MIN(store_id) FROM store)
            LIMIT 1
        ),
        (SELECT customer_id FROM customer WHERE first_name = 'Rauan' AND last_name = 'Turetayev'),
        '2017-01-15 10:00:00'::TIMESTAMP + 7 * INTERVAL '1 day',
        (SELECT MIN(staff_id) FROM staff),
        CURRENT_DATE
    WHERE NOT EXISTS (
        SELECT 1 FROM rental
        WHERE customer_id  = (SELECT customer_id FROM customer WHERE first_name = 'Rauan' AND last_name = 'Turetayev')
          AND inventory_id = (
              SELECT i.inventory_id FROM inventory i
              JOIN film f ON i.film_id = f.film_id
              WHERE f.title = 'Marvel' AND f.release_year = 2011
                AND i.store_id = (SELECT MIN(store_id) FROM store)
              LIMIT 1
          )
    )
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    r.customer_id,
    (SELECT MIN(staff_id) FROM staff),
    r.rental_id,
    4.99,
    '2017-01-15 10:05:00'::TIMESTAMP
FROM rental_got r
WHERE NOT EXISTS (
    SELECT 1 FROM payment p
    WHERE p.rental_id = r.rental_id AND p.customer_id = r.customer_id
)
RETURNING payment_id, customer_id, rental_id, amount, payment_date;



WITH rental_bb AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT
        '2017-02-10 12:00:00'::TIMESTAMP,
        (
            SELECT i.inventory_id FROM inventory i
            JOIN film f ON i.film_id = f.film_id
            WHERE f.title = 'Batman' AND f.release_year = 2008
              AND i.store_id = (SELECT MIN(store_id) FROM store)
            LIMIT 1
        ),
        (SELECT customer_id FROM customer WHERE first_name = 'Rauan' AND last_name = 'Turetayev'),
        '2017-02-10 12:00:00'::TIMESTAMP + 14 * INTERVAL '1 day',
        (SELECT MIN(staff_id) FROM staff),
        CURRENT_DATE
    WHERE NOT EXISTS (
        SELECT 1 FROM rental
        WHERE customer_id  = (SELECT customer_id FROM customer WHERE first_name = 'Rauan' AND last_name = 'Turetayev')
          AND inventory_id = (
              SELECT i.inventory_id FROM inventory i
              JOIN film f ON i.film_id = f.film_id
              WHERE f.title = 'Batman' AND f.release_year = 2008
                AND i.store_id = (SELECT MIN(store_id) FROM store)
              LIMIT 1
          )
    )
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    r.customer_id,
    (SELECT MIN(staff_id) FROM staff),
    r.rental_id,
    9.99,
    '2017-02-10 12:05:00'::TIMESTAMP
FROM rental_bb r
WHERE NOT EXISTS (
    SELECT 1 FROM payment p
    WHERE p.rental_id = r.rental_id AND p.customer_id = r.customer_id
)
RETURNING payment_id, customer_id, rental_id, amount, payment_date;



WITH rental_thor AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT
        '2017-03-20 15:00:00'::TIMESTAMP,
        (
            SELECT i.inventory_id FROM inventory i
            JOIN film f ON i.film_id = f.film_id
            WHERE f.title = 'Avengers' AND f.release_year = 2011
              AND i.store_id = (SELECT MIN(store_id) FROM store)
            LIMIT 1
        ),
        (SELECT customer_id FROM customer WHERE first_name = 'Rauan' AND last_name = 'Turetayev'),
        '2017-03-20 15:00:00'::TIMESTAMP + 21 * INTERVAL '1 day',
        (SELECT MIN(staff_id) FROM staff),
        CURRENT_DATE
    WHERE NOT EXISTS (
        SELECT 1 FROM rental
        WHERE customer_id  = (SELECT customer_id FROM customer WHERE first_name = 'Rauan' AND last_name = 'Turetayev')
          AND inventory_id = (
              SELECT i.inventory_id FROM inventory i
              JOIN film f ON i.film_id = f.film_id
              WHERE f.title = 'Avengers' AND f.release_year = 2011
                AND i.store_id = (SELECT MIN(store_id) FROM store)
              LIMIT 1
          )
    )
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    r.customer_id,
    (SELECT MIN(staff_id) FROM staff),
    r.rental_id,
    19.99,
    '2017-03-20 15:05:00'::TIMESTAMP
FROM rental_thor r
WHERE NOT EXISTS (
    SELECT 1 FROM payment p
    WHERE p.rental_id = r.rental_id AND p.customer_id = r.customer_id
)
RETURNING payment_id, customer_id, rental_id, amount, payment_date;


SELECT
    r.rental_id,
    f.title,
    r.rental_date,
    r.return_date,
    p.amount,
    p.payment_date
FROM rental r
JOIN inventory i  ON r.inventory_id = i.inventory_id
JOIN film f       ON i.film_id = f.film_id
JOIN payment p    ON p.rental_id = r.rental_id
WHERE r.customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Rauan' AND last_name = 'Turetayev'
)
ORDER BY r.rental_date;

COMMIT;