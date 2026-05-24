-- Final Project — Cinema Domain
-- Database: cinema_db  /  Schema: cinema

-- Шаг 1 (один раз): CREATE DATABASE cinema_db;
-- Шаг 2: подключитесь к cinema_db, затем запустите этот файл.

CREATE SCHEMA IF NOT EXISTS cinema;

SET search_path TO cinema;

-- PART 2 + 3: CREATE TABLE

CREATE TABLE IF NOT EXISTS cinema.country (
    country_id   SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cinema.city (
    city_id    SERIAL PRIMARY KEY,
    city_name  VARCHAR(100) NOT NULL,
    country_id INT NOT NULL REFERENCES cinema.country(country_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS cinema.customer (
    customer_id    SERIAL PRIMARY KEY,
    email          VARCHAR(120) NOT NULL UNIQUE,
    first_name     VARCHAR(80)  NOT NULL,
    last_name      VARCHAR(80)  NOT NULL,
    phone          VARCHAR(20),
    gender         VARCHAR(10)  NOT NULL CHECK (gender IN ('M', 'F', 'Other')),
    birth_date     DATE,
    city_id        INT REFERENCES cinema.city(city_id) ON DELETE SET NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'regular',
    loyalty_points INT          NOT NULL DEFAULT 0,
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cinema.genre (
    genre_id   SERIAL PRIMARY KEY,
    genre_name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cinema.film (
    film_id      SERIAL PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    release_year INT          NOT NULL,
    duration_min INT          NOT NULL CHECK (duration_min > 0),
    age_rating   VARCHAR(10)  NOT NULL DEFAULT 'PG',
    language     VARCHAR(50)  NOT NULL DEFAULT 'Kazakh',
    description  TEXT
);

CREATE TABLE IF NOT EXISTS cinema.film_genre (
    film_id  INT NOT NULL REFERENCES cinema.film(film_id)   ON DELETE CASCADE,
    genre_id INT NOT NULL REFERENCES cinema.genre(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (film_id, genre_id)
);

CREATE TABLE IF NOT EXISTS cinema.hall (
    hall_id   SERIAL PRIMARY KEY,
    hall_name VARCHAR(50)  NOT NULL UNIQUE,
    capacity  INT          NOT NULL CHECK (capacity > 0),
    hall_type VARCHAR(30)  NOT NULL DEFAULT '2D'
);

CREATE TABLE IF NOT EXISTS cinema.seat (
    seat_id     SERIAL PRIMARY KEY,
    hall_id     INT         NOT NULL REFERENCES cinema.hall(hall_id) ON DELETE CASCADE,
    row_number  INT         NOT NULL CHECK (row_number > 0),
    seat_number INT         NOT NULL CHECK (seat_number > 0),
    seat_type   VARCHAR(20) NOT NULL DEFAULT 'standard',
    UNIQUE (hall_id, row_number, seat_number)
);

CREATE TABLE IF NOT EXISTS cinema.session (
    session_id   SERIAL PRIMARY KEY,
    film_id      INT           NOT NULL REFERENCES cinema.film(film_id)  ON DELETE RESTRICT,
    hall_id      INT           NOT NULL REFERENCES cinema.hall(hall_id)  ON DELETE RESTRICT,
    session_date DATE          NOT NULL CHECK (session_date > DATE '2026-01-01'),
    start_time   TIME          NOT NULL,
    base_price   NUMERIC(10,2) NOT NULL CHECK (base_price >= 0),
    language     VARCHAR(50)   NOT NULL DEFAULT 'Kazakh'
);

CREATE TABLE IF NOT EXISTS cinema.payment_method (
    method_id   SERIAL PRIMARY KEY,
    method_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cinema.booking (
    booking_id   SERIAL PRIMARY KEY,
    customer_id  INT           NOT NULL REFERENCES cinema.customer(customer_id)     ON DELETE RESTRICT,
    method_id    INT           NOT NULL REFERENCES cinema.payment_method(method_id) ON DELETE RESTRICT,
    booking_date DATE          NOT NULL CHECK (booking_date > DATE '2026-01-01'),
    status       VARCHAR(20)   NOT NULL DEFAULT 'confirmed'
                               CHECK (status IN ('confirmed', 'cancelled', 'pending')),
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS cinema.ticket (
    ticket_id      SERIAL PRIMARY KEY,
    booking_id     INT           NOT NULL REFERENCES cinema.booking(booking_id)  ON DELETE CASCADE,
    session_id     INT           NOT NULL REFERENCES cinema.session(session_id)  ON DELETE RESTRICT,
    seat_id        INT           NOT NULL REFERENCES cinema.seat(seat_id)        ON DELETE RESTRICT,
    unit_price     NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    price_with_vat NUMERIC(10,2) GENERATED ALWAYS AS (ROUND(unit_price * 1.12, 2)) STORED,
    UNIQUE (session_id, seat_id)
);

CREATE TABLE IF NOT EXISTS cinema.employee (
    employee_id SERIAL PRIMARY KEY,
    email       VARCHAR(120)  NOT NULL UNIQUE,
    first_name  VARCHAR(80)   NOT NULL,
    last_name   VARCHAR(80)   NOT NULL,
    full_name   VARCHAR(165)  GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    position    VARCHAR(60)   NOT NULL,
    salary      NUMERIC(12,2) NOT NULL CHECK (salary >= 0),
    hired_date  DATE          NOT NULL CHECK (hired_date > DATE '2026-01-01')
);


-- PART 3: ALTER TABLE  

-- Удаление constraints для переиспользования скрипта
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_film_release_year') THEN
        ALTER TABLE cinema.film DROP CONSTRAINT chk_film_release_year;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_booking_status') THEN
        ALTER TABLE cinema.booking DROP CONSTRAINT chk_booking_status;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_customer_status') THEN
        ALTER TABLE cinema.customer DROP CONSTRAINT chk_customer_status;
    END IF;
END $$;

-- 1. ADD CONSTRAINT: год выпуска фильма не раньше 1888 (год изобретения кино)
ALTER TABLE cinema.film
    ADD CONSTRAINT chk_film_release_year CHECK (release_year >= 1888);

-- 2. ADD CONSTRAINT: статус бронирования только из допустимых значений
ALTER TABLE cinema.booking
    ADD CONSTRAINT chk_booking_status CHECK (status IN ('confirmed', 'cancelled', 'pending'));

-- 3. ADD CONSTRAINT: статус клиента только из допустимых значений
ALTER TABLE cinema.customer
    ADD CONSTRAINT chk_customer_status CHECK (status IN ('regular', 'vip', 'inactive'));

-- 4. SET DEFAULT: базовый язык сеанса — казахский
ALTER TABLE cinema.session
    ALTER COLUMN language SET DEFAULT 'Kazakh';

-- 5. SET DEFAULT: базовый рейтинг фильма
ALTER TABLE cinema.film
    ALTER COLUMN age_rating SET DEFAULT 'PG';

-- PART 4: INSERT

-- 4.1 Re-runnable reset: удаляем данные в порядке дочерние → родители
-- RESTART IDENTITY сбрасывает SERIAL-последовательности для одинаковых ID при каждом запуске
TRUNCATE TABLE
    cinema.ticket,
    cinema.booking,
    cinema.film_genre,
    cinema.session,
    cinema.seat,
    cinema.hall,
    cinema.film,
    cinema.genre,
    cinema.payment_method,
    cinema.customer,
    cinema.employee,
    cinema.city,
    cinema.country
RESTART IDENTITY CASCADE;

-- COUNTRIES
WITH new_countries AS (
    SELECT 'Kazakhstan' AS country_name
    UNION ALL SELECT 'Russia'
    UNION ALL SELECT 'USA'
), inserted AS (
    INSERT INTO cinema.country (country_name)
    SELECT country_name FROM new_countries nc
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.country c WHERE c.country_name = nc.country_name
    )
    RETURNING country_id, country_name
) SELECT * FROM inserted;

-- CITIES
WITH new_cities AS (
    SELECT 'Almaty'     AS city_name, 'Kazakhstan' AS country_name
    UNION ALL SELECT 'Nur-Sultan', 'Kazakhstan'
    UNION ALL SELECT 'Atyrau',     'Kazakhstan'
    UNION ALL SELECT 'Moscow',     'Russia'
    UNION ALL SELECT 'New York',   'USA'
), inserted AS (
    INSERT INTO cinema.city (city_name, country_id)
    SELECT nc.city_name, c.country_id
    FROM new_cities nc
    JOIN cinema.country c ON c.country_name = nc.country_name
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.city ci
        WHERE ci.city_name = nc.city_name
    )
    RETURNING city_id, city_name
) SELECT * FROM inserted;

-- GENRES
WITH new_genres AS (
    SELECT 'Action'    AS genre_name
    UNION ALL SELECT 'Drama'
    UNION ALL SELECT 'Comedy'
    UNION ALL SELECT 'Thriller'
    UNION ALL SELECT 'Animation'
    UNION ALL SELECT 'Horror'
), inserted AS (
    INSERT INTO cinema.genre (genre_name)
    SELECT genre_name FROM new_genres ng
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.genre g WHERE g.genre_name = ng.genre_name
    )
    RETURNING genre_id, genre_name
) SELECT * FROM inserted;

-- FILMS
WITH new_films AS (
    SELECT 'Nomad: The Warrior' AS title, 2006 AS release_year, 113 AS duration_min,
           'PG-13' AS age_rating, 'Kazakh'  AS language,
           'Epic story of a Kazakh warrior fighting for freedom.' AS description
    UNION ALL
    SELECT 'Interstellar', 2014, 169, 'PG-13', 'English',
           'A team of explorers travel through a wormhole in space.'
    UNION ALL
    SELECT 'The Dark Knight', 2008, 152, 'PG-13', 'English',
           'Batman faces the Joker in Gotham City.'
    UNION ALL
    SELECT 'Parasite', 2019, 132, 'R', 'Korean',
           'A poor family schemes to become employed by a wealthy family.'
    UNION ALL
    SELECT 'Toy Story 4', 2019, 100, 'G', 'English',
           'Woody and Buzz on a new adventure.'
), inserted AS (
    INSERT INTO cinema.film (title, release_year, duration_min, age_rating, language, description)
    SELECT title, release_year, duration_min, age_rating, language, description
    FROM new_films nf
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.film f WHERE f.title = nf.title
    )
    RETURNING film_id, title
) SELECT * FROM inserted;

-- FILM_GENRE (M:N)
WITH new_fg AS (
    SELECT 'Nomad: The Warrior' AS film_title, 'Action'    AS genre_name
    UNION ALL SELECT 'Nomad: The Warrior', 'Drama'
    UNION ALL SELECT 'Interstellar',       'Drama'
    UNION ALL SELECT 'Interstellar',       'Thriller'
    UNION ALL SELECT 'The Dark Knight',    'Action'
    UNION ALL SELECT 'The Dark Knight',    'Thriller'
    UNION ALL SELECT 'Parasite',           'Drama'
    UNION ALL SELECT 'Parasite',           'Thriller'
    UNION ALL SELECT 'Toy Story 4',        'Animation'
    UNION ALL SELECT 'Toy Story 4',        'Comedy'
), inserted AS (
    INSERT INTO cinema.film_genre (film_id, genre_id)
    SELECT f.film_id, g.genre_id
    FROM new_fg nfg
    JOIN cinema.film  f ON f.title      = nfg.film_title
    JOIN cinema.genre g ON g.genre_name = nfg.genre_name
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.film_genre fg
        WHERE fg.film_id = f.film_id AND fg.genre_id = g.genre_id
    )
    RETURNING film_id, genre_id
) SELECT * FROM inserted;

-- HALLS
WITH new_halls AS (
    SELECT 'Hall 1' AS hall_name, 120 AS capacity, 'IMAX'     AS hall_type
    UNION ALL SELECT 'Hall 2',  80, '2D'
    UNION ALL SELECT 'Hall 3',  60, '3D'
), inserted AS (
    INSERT INTO cinema.hall (hall_name, capacity, hall_type)
    SELECT hall_name, capacity, hall_type
    FROM new_halls nh
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.hall h WHERE h.hall_name = nh.hall_name
    )
    RETURNING hall_id, hall_name
) SELECT * FROM inserted;

-- SEATS (3 ряда x 5 мест на каждый зал)
INSERT INTO cinema.seat (hall_id, row_number, seat_number, seat_type)
SELECT h.hall_id, r.row_num, s.seat_num, 'standard'
FROM cinema.hall h
CROSS JOIN (VALUES (1),(2),(3))         AS r(row_num)
CROSS JOIN (VALUES (1),(2),(3),(4),(5)) AS s(seat_num)
WHERE NOT EXISTS (
    SELECT 1 FROM cinema.seat se
    WHERE se.hall_id     = h.hall_id
      AND se.row_number  = r.row_num
      AND se.seat_number = s.seat_num
);

-- PAYMENT METHODS
WITH new_methods AS (
    SELECT 'Cash'      AS method_name
    UNION ALL SELECT 'Kaspi Pay'
    UNION ALL SELECT 'Visa Card'
), inserted AS (
    INSERT INTO cinema.payment_method (method_name)
    SELECT method_name FROM new_methods nm
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.payment_method pm WHERE pm.method_name = nm.method_name
    )
    RETURNING method_id, method_name
) SELECT * FROM inserted;

-- CUSTOMERS
WITH new_customers AS (
    SELECT 'aizat.bekova@mail.kz'     AS email, 'Aizat'   AS first_name, 'Bekova'    AS last_name,
           '+77071112233' AS phone, 'F' AS gender, DATE '1995-04-12' AS birth_date,
           'Almaty' AS city_name
    UNION ALL
    SELECT 'daniyar.seitkali@mail.kz', 'Daniyar', 'Seitkali',  '+77052223344', 'M', DATE '1990-08-25', 'Nur-Sultan'
    UNION ALL
    SELECT 'gulnaz.akhmetova@mail.kz', 'Gulnaz',  'Akhmetova', '+77013334455', 'F', DATE '2000-01-30', 'Atyrau'
    UNION ALL
    SELECT 'ruslan.ospanov@mail.kz',   'Ruslan',  'Ospanov',   '+77084445566', 'M', DATE '1988-11-05', 'Almaty'
    UNION ALL
    SELECT 'assel.nurova@mail.kz',     'Assel',   'Nurova',    '+77095556677', 'F', DATE '1997-06-18', 'Nur-Sultan'
    UNION ALL
    SELECT 'timur.bekzhanov@mail.kz',  'Timur',   'Bekzhanov', '+77036667788', 'M', DATE '1993-09-22', 'Atyrau'
), inserted AS (
    INSERT INTO cinema.customer (email, first_name, last_name, phone, gender, birth_date, city_id)
    SELECT nc.email, nc.first_name, nc.last_name, nc.phone, nc.gender, nc.birth_date,
           (SELECT city_id FROM cinema.city WHERE city_name = nc.city_name)
    FROM new_customers nc
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.customer c WHERE c.email = nc.email
    )
    RETURNING customer_id, email
) SELECT * FROM inserted;

-- EMPLOYEES
WITH new_employees AS (
    SELECT 'mira.sultanova@cinema.kz'     AS email, 'Mira'   AS first_name, 'Sultanova'    AS last_name,
           'Manager'    AS position, 350000::NUMERIC(12,2) AS salary, DATE '2026-02-01' AS hired_date
    UNION ALL
    SELECT 'arman.dzhaksybekov@cinema.kz', 'Arman',  'Dzhaksybekov', 'Cashier',    180000, DATE '2026-02-15'
    UNION ALL
    SELECT 'zarina.nurova@cinema.kz',      'Zarina', 'Nurova',       'Technician', 200000, DATE '2026-03-01'
    UNION ALL
    SELECT 'bekzat.seilov@cinema.kz',      'Bekzat', 'Seilov',       'Security',   160000, DATE '2026-03-10'
    UNION ALL
    SELECT 'ainur.makhatova@cinema.kz',    'Ainur',  'Makhatova',    'Guide',      170000, DATE '2026-04-01'
    UNION ALL
    SELECT 'dias.akhanov@cinema.kz',       'Dias',   'Akhanov',      'Curator',    220000, DATE '2026-04-15'
), inserted AS (
    INSERT INTO cinema.employee (email, first_name, last_name, position, salary, hired_date)
    SELECT email, first_name, last_name, position, salary, hired_date
    FROM new_employees ne
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.employee e WHERE e.email = ne.email
    )
    RETURNING employee_id, email
) SELECT * FROM inserted;

-- SESSIONS
WITH new_sessions AS (
    SELECT 'Nomad: The Warrior' AS film_title, 'Hall 1' AS hall_name,
           DATE '2026-05-10' AS session_date, '14:00'::TIME AS start_time,
           2500.00::NUMERIC(10,2) AS base_price, 'Kazakh' AS language
    UNION ALL
    SELECT 'Interstellar',    'Hall 2', DATE '2026-05-11', '17:30', 3000.00, 'English'
    UNION ALL
    SELECT 'The Dark Knight', 'Hall 3', DATE '2026-05-12', '20:00', 2800.00, 'English'
    UNION ALL
    SELECT 'Parasite',        'Hall 1', DATE '2026-05-13', '19:00', 2700.00, 'Korean'
    UNION ALL
    SELECT 'Toy Story 4',     'Hall 2', DATE '2026-05-14', '11:00', 2000.00, 'Kazakh'
    UNION ALL
    SELECT 'Nomad: The Warrior', 'Hall 3', DATE '2026-05-15', '16:00', 2500.00, 'Kazakh'
), inserted AS (
    INSERT INTO cinema.session (film_id, hall_id, session_date, start_time, base_price, language)
    SELECT f.film_id, h.hall_id, ns.session_date, ns.start_time, ns.base_price, ns.language
    FROM new_sessions ns
    JOIN cinema.film f ON f.title      = ns.film_title
    JOIN cinema.hall h ON h.hall_name  = ns.hall_name
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.session s
        WHERE s.film_id      = f.film_id
          AND s.hall_id      = h.hall_id
          AND s.session_date = ns.session_date
          AND s.start_time   = ns.start_time
    )
    RETURNING session_id, film_id, session_date
) SELECT * FROM inserted;

-- BOOKINGS
WITH new_bookings AS (
    SELECT 'aizat.bekova@mail.kz'     AS email, 'Kaspi Pay'  AS method_name,
           DATE '2026-05-09' AS booking_date, 'confirmed' AS status
    UNION ALL
    SELECT 'daniyar.seitkali@mail.kz', 'Visa Card',  DATE '2026-05-10', 'confirmed'
    UNION ALL
    SELECT 'gulnaz.akhmetova@mail.kz', 'Cash',       DATE '2026-05-11', 'confirmed'
    UNION ALL
    SELECT 'ruslan.ospanov@mail.kz',   'Kaspi Pay',  DATE '2026-05-08', 'cancelled'
    UNION ALL
    SELECT 'assel.nurova@mail.kz',     'Visa Card',  DATE '2026-05-12', 'confirmed'
    UNION ALL
    SELECT 'timur.bekzhanov@mail.kz',  'Cash',       DATE '2026-05-13', 'confirmed'
), inserted AS (
    INSERT INTO cinema.booking (customer_id, method_id, booking_date, status)
    SELECT c.customer_id, pm.method_id, nb.booking_date, nb.status
    FROM new_bookings nb
    JOIN cinema.customer       c  ON c.email       = nb.email
    JOIN cinema.payment_method pm ON pm.method_name = nb.method_name
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.booking b
        WHERE b.customer_id  = c.customer_id
          AND b.booking_date = nb.booking_date
    )
    RETURNING booking_id, customer_id, booking_date, status
) SELECT * FROM inserted;

-- TICKETS
WITH new_tickets AS (
    SELECT 'aizat.bekova@mail.kz'     AS cust_email, 'Nomad: The Warrior' AS film_title,
           'Hall 1' AS hall_name, 1 AS row_num, 3 AS seat_num
    UNION ALL
    SELECT 'aizat.bekova@mail.kz',     'Nomad: The Warrior', 'Hall 1', 1, 4
    UNION ALL
    SELECT 'daniyar.seitkali@mail.kz', 'Interstellar',       'Hall 2', 2, 1
    UNION ALL
    SELECT 'gulnaz.akhmetova@mail.kz', 'The Dark Knight',    'Hall 3', 1, 2
    UNION ALL
    SELECT 'assel.nurova@mail.kz',     'Parasite',           'Hall 1', 3, 5
    UNION ALL
    SELECT 'timur.bekzhanov@mail.kz',  'Toy Story 4',        'Hall 2', 2, 3
), inserted AS (
    INSERT INTO cinema.ticket (booking_id, session_id, seat_id, unit_price)
    SELECT b.booking_id, se.session_id, st.seat_id, se.base_price
    FROM new_tickets nt
    JOIN cinema.customer  cu ON cu.email       = nt.cust_email
    JOIN cinema.booking   b  ON b.customer_id  = cu.customer_id AND b.status <> 'cancelled'
    JOIN cinema.film      f  ON f.title        = nt.film_title
    JOIN cinema.hall      h  ON h.hall_name    = nt.hall_name
    JOIN cinema.session   se ON se.film_id     = f.film_id AND se.hall_id = h.hall_id
    JOIN cinema.seat      st ON st.hall_id     = h.hall_id
                             AND st.row_number  = nt.row_num
                             AND st.seat_number = nt.seat_num
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.ticket t
        WHERE t.session_id = se.session_id
          AND t.seat_id    = st.seat_id
    )
    RETURNING ticket_id, booking_id, session_id, seat_id
) SELECT * FROM inserted;

-- PART 5.1: ФУНКЦИЯ ОБНОВЛЕНИЯ 

-- Функция принимает: customer_id, имя колонки, новое значение
-- Обновляет любое поле в таблице customer динамически

CREATE OR REPLACE FUNCTION cinema.update_customer_column(
    p_customer_id   INT,
    p_column_name   TEXT,
    p_new_value     TEXT
)
RETURNS VOID AS $$
DECLARE
    affected_rows INT;
BEGIN
    -- Проверка существования колонки
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'cinema'
          AND table_name   = 'customer'
          AND column_name  = p_column_name
    ) THEN
        RAISE NOTICE 'Column "%" does not exist in table "customer".', p_column_name;
        RETURN;
    END IF;

    -- Динамическое обновление
    EXECUTE format(
        'UPDATE cinema.customer SET %I = $1 WHERE customer_id = $2',
        p_column_name
    ) USING p_new_value, p_customer_id;

    GET DIAGNOSTICS affected_rows = ROW_COUNT;

    IF affected_rows = 0 THEN
        RAISE NOTICE 'No row found with customer_id = %', p_customer_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова: обновляем статус клиента
SELECT cinema.update_customer_column(
    (SELECT customer_id FROM cinema.customer WHERE email = 'aizat.bekova@mail.kz'),
    'status',
    'vip'
);

SELECT * FROM cinema.customer;



-- PART 5.2: UPDATE и DELETE 

-- UPDATE: клиенты с 2+ confirmed бронированиями → vip
UPDATE cinema.customer
SET status = 'vip'
WHERE customer_id IN (
    SELECT customer_id
    FROM cinema.booking
    WHERE status = 'confirmed'
    GROUP BY customer_id
    HAVING COUNT(*) >= 2
);

-- UPDATE … FROM: пересчитываем total_amount из билетов (с НДС)
UPDATE cinema.booking b
SET total_amount = sub.total
FROM (
    SELECT booking_id, SUM(price_with_vat) AS total
    FROM cinema.ticket
    GROUP BY booking_id
) sub
WHERE b.booking_id = sub.booking_id;

-- DELETE (в транзакции — данные сохраняются для защиты)
BEGIN;
    DELETE FROM cinema.booking
    WHERE status = 'cancelled'
      AND booking_date < CURRENT_DATE - INTERVAL '90 days'
    RETURNING booking_id, customer_id, booking_date, total_amount;
ROLLBACK;


-- ============================================================
-- PART 6: VIEW — аналитика за последний квартал 
-- ============================================================

-- Детальный view: каждый сеанс, фильм, жанр, клиент
CREATE OR REPLACE VIEW cinema.analytics_recent_quarter AS
SELECT
    f.title                           AS film_title,
    f.language                        AS film_language,
    g.genre_name,
    s.session_date,
    s.start_time,
    EXTRACT(QUARTER FROM s.session_date) AS quarter,
    h.hall_name,
    h.hall_type,
    cu.first_name || ' ' || cu.last_name AS customer_name,
    pm.method_name                    AS payment_method,
    t.unit_price,
    t.price_with_vat,
    b.status                          AS booking_status
FROM cinema.session s
LEFT JOIN cinema.film          f  ON f.film_id    = s.film_id
LEFT JOIN cinema.film_genre    fg ON fg.film_id   = f.film_id
LEFT JOIN cinema.genre         g  ON g.genre_id   = fg.genre_id
LEFT JOIN cinema.hall          h  ON h.hall_id    = s.hall_id
LEFT JOIN cinema.ticket        t  ON t.session_id = s.session_id
LEFT JOIN cinema.booking       b  ON b.booking_id = t.booking_id
LEFT JOIN cinema.customer      cu ON cu.customer_id = b.customer_id
LEFT JOIN cinema.payment_method pm ON pm.method_id = b.method_id
WHERE
    EXTRACT(YEAR    FROM s.session_date) = EXTRACT(YEAR    FROM CURRENT_DATE)
    AND EXTRACT(QUARTER FROM s.session_date) = EXTRACT(QUARTER FROM CURRENT_DATE);

-- Итоговый view: общее число сеансов и выручка за квартал
CREATE OR REPLACE VIEW cinema.total_results_of_quarter AS
SELECT
    COUNT(DISTINCT s.session_id)    AS total_sessions,
    COUNT(DISTINCT b.booking_id)    AS total_bookings,
    SUM(t.price_with_vat)           AS total_revenue
FROM cinema.session s
LEFT JOIN cinema.ticket  t ON t.session_id  = s.session_id
LEFT JOIN cinema.booking b ON b.booking_id  = t.booking_id
WHERE
    EXTRACT(YEAR    FROM s.session_date) = EXTRACT(YEAR    FROM CURRENT_DATE)
    AND EXTRACT(QUARTER FROM s.session_date) = EXTRACT(QUARTER FROM CURRENT_DATE);

SELECT * FROM cinema.analytics_recent_quarter;
SELECT * FROM cinema.total_results_of_quarter;


-- ============================================================
-- PART 7: РОЛЬ ( LOGIN PASSWORD)
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cinema_manager_readonly') THEN
        CREATE ROLE cinema_manager_readonly LOGIN PASSWORD 'secure_password_123';
    END IF;
END $$;

-- CONNECT на базу (выполняется напрямую, не внутри DO — иначе GRANT не применится)
GRANT CONNECT ON DATABASE cinema_db TO cinema_manager_readonly;

-- USAGE на схему + SELECT на все таблицы
GRANT USAGE  ON SCHEMA cinema TO cinema_manager_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA cinema TO cinema_manager_readonly;

-- Проверка: переключаемся на роль и делаем SELECT
SET ROLE cinema_manager_readonly;
SELECT current_user;

SELECT film_id, title, release_year, duration_min, age_rating, language FROM cinema.film;
SELECT session_id, film_id, hall_id, session_date, start_time, base_price FROM cinema.session;
SELECT booking_id, customer_id, method_id, booking_date, status, total_amount FROM cinema.booking;
-- SELECT ticket_id, booking_id, session_id, seat_id, unit_price, price_with_vat FROM cinema.ticket;
-- SELECT customer_id, email, first_name, last_name, gender, status FROM cinema.customer;
-- SELECT employee_id, email, full_name, position, salary FROM cinema.employee;

-- Возвращаемся к суперпользователю
RESET ROLE;


-- ============================================================
-- PART 6: GRANT / REVOKE — вторая роль для сервиса продажи билетов
-- ============================================================

-- Удаление роли для переиспользования скрипта
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'cinema_writer') THEN
        REASSIGN OWNED BY cinema_writer TO CURRENT_USER;
        DROP OWNED BY cinema_writer;
        DROP ROLE cinema_writer;
    END IF;
END $$;

-- Роль для сервиса продажи билетов: может создавать и изменять бронирования
CREATE ROLE cinema_writer;

GRANT USAGE ON SCHEMA cinema TO cinema_writer;

-- Сервис продажи может создавать бронирования и билеты, а также менять статус
GRANT INSERT, UPDATE ON cinema.booking TO cinema_writer;
GRANT INSERT         ON cinema.ticket  TO cinema_writer;

-- После security review: изменение статуса бронирования должно идти
-- только через хранимую процедуру с аудит-логом, не напрямую
REVOKE UPDATE ON cinema.booking FROM cinema_writer;
