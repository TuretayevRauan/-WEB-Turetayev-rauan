-- ============================================================
--  Online Tutoring Database
--  PostgreSQL Lab — Data Modeling & Constraints
-- ============================================================

-- Step 1: Create the database (run this separately in DBeaver or CLI)
-- CREATE DATABASE online_tutoring;

-- ============================================================
-- TABLE 1: tutors
-- ============================================================
CREATE TABLE tutors (
    tutor_id    SERIAL          PRIMARY KEY,
    full_name   VARCHAR(120)    NOT NULL,
    email       VARCHAR(150)    NOT NULL UNIQUE,
    subject     VARCHAR(80)     NOT NULL,
    hourly_rate NUMERIC(8,2)    NOT NULL CHECK (hourly_rate >= 0),
    is_active   BOOLEAN         NOT NULL DEFAULT true,
    joined_date DATE            NOT NULL DEFAULT CURRENT_DATE
                                CHECK (joined_date >= '2026-01-01')
);

-- ============================================================
-- TABLE 2: students
-- ============================================================
CREATE TABLE students (
    student_id  SERIAL          PRIMARY KEY,
    full_name   VARCHAR(120)    NOT NULL,
    email       VARCHAR(150)    NOT NULL UNIQUE,
    grade_level VARCHAR(20)     NOT NULL,
    age         INT             NOT NULL CHECK (age >= 0),
    enrolled_on DATE            NOT NULL DEFAULT CURRENT_DATE
                                CHECK (enrolled_on >= '2026-01-01')
);

-- ============================================================
-- TABLE 3: sessions
-- ============================================================
CREATE TABLE sessions (
    session_id      SERIAL          PRIMARY KEY,
    tutor_id        INT             NOT NULL REFERENCES tutors(tutor_id),
    student_id      INT             NOT NULL REFERENCES students(student_id),
    session_date    DATE            NOT NULL CHECK (session_date >= '2026-01-01'),
    duration_min    INT             NOT NULL CHECK (duration_min >= 0),
    topic           VARCHAR(200)    NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'scheduled'
);

-- ============================================================
-- TABLE 4: payments
-- ============================================================
CREATE TABLE payments (
    payment_id      SERIAL          PRIMARY KEY,
    session_id      INT             NOT NULL REFERENCES sessions(session_id),
    student_id      INT             NOT NULL REFERENCES students(student_id),
    amount          NUMERIC(10,2)   NOT NULL CHECK (amount >= 0),
    payment_date    DATE            NOT NULL DEFAULT CURRENT_DATE
                                    CHECK (payment_date >= '2026-01-01'),
    method          VARCHAR(30)     NOT NULL DEFAULT 'card',
    is_confirmed    BOOLEAN         NOT NULL DEFAULT false
);

-- ============================================================
-- SAMPLE DATA — tutors
-- ============================================================
INSERT INTO tutors (full_name, email, subject, hourly_rate, joined_date) VALUES
    ('Asel Nurlanovna',  'asel@tutornet.kz',   'Mathematics',       8000.00, '2026-01-10'),
    ('Dmitry Volkov',    'dvolkov@tutornet.kz', 'Physics',           9500.00, '2026-02-01'),
    ('Sara Johnson',     'sara.j@tutornet.kz',  'English Language',  7500.00, '2026-01-15'),
    ('Alibek Dzhaksybekov', 'alibek@tutornet.kz', 'Computer Science', 11000.00, '2026-03-01');

-- ============================================================
-- SAMPLE DATA — students
-- ============================================================
INSERT INTO students (full_name, email, grade_level, age, enrolled_on) VALUES
    ('Madina Bekova',   'madina@mail.kz',   'Grade 10', 16, '2026-01-20'),
    ('Timur Omarov',    'timur@mail.kz',    'Grade 11', 17, '2026-02-05'),
    ('Zarina Akhmetova','zarina@mail.kz',   'Grade 9',  15, '2026-01-25'),
    ('Ruslan Seitkali', 'ruslan@mail.kz',   'Grade 12', 18, '2026-03-10'),
    ('Aigerim Tuleova', 'aigerim@mail.kz',  'Grade 10', 16, '2026-03-15');

-- ============================================================
-- SAMPLE DATA — sessions
-- ============================================================
INSERT INTO sessions (tutor_id, student_id, session_date, duration_min, topic, status) VALUES
    (1, 1, '2026-02-01', 60,  'Algebra — Quadratic Equations',  'completed'),
    (2, 2, '2026-02-10', 90,  'Newton Laws of Motion',          'completed'),
    (3, 3, '2026-02-15', 60,  'Essay Writing Basics',           'completed'),
    (4, 4, '2026-03-05', 120, 'Python — Lists and Loops',       'completed'),
    (1, 5, '2026-03-20', 60,  'Geometry — Triangles',           'scheduled');

-- ============================================================
-- SAMPLE DATA — payments
-- ============================================================
INSERT INTO payments (session_id, student_id, amount, payment_date, method, is_confirmed) VALUES
    (1, 1, 8000.00,  '2026-02-01', 'card',         true),
    (2, 2, 14250.00, '2026-02-10', 'bank_transfer', true),
    (3, 3, 7500.00,  '2026-02-15', 'card',         true),
    (4, 4, 22000.00, '2026-03-05', 'card',         true),
    (5, 5, 8000.00,  '2026-03-20', 'cash',         false);

-- ============================================================
-- CONSTRAINT VIOLATION EXAMPLES (intentional — do NOT run)
-- ============================================================

-- 1. Violates CHECK (hourly_rate >= 0):
-- INSERT INTO tutors (full_name, email, subject, hourly_rate, joined_date)
-- VALUES ('Bad Tutor', 'bad@mail.kz', 'Math', -500.00, '2026-01-01');
-- ERROR: new row for relation "tutors" violates check constraint "tutors_hourly_rate_check"

-- 2. Violates CHECK (joined_date >= '2026-01-01'):
-- INSERT INTO tutors (full_name, email, subject, hourly_rate, joined_date)
-- VALUES ('Old Tutor', 'old@mail.kz', 'Physics', 5000.00, '2025-06-01');
-- ERROR: new row for relation "tutors" violates check constraint "tutors_joined_date_check"

-- 3. Violates UNIQUE on email:
-- INSERT INTO students (full_name, email, grade_level, age, enrolled_on)
-- VALUES ('Duplicate', 'madina@mail.kz', 'Grade 10', 16, '2026-02-01');
-- ERROR: duplicate key value violates unique constraint "students_email_key"

-- 4. Violates CHECK (age >= 0):
-- INSERT INTO students (full_name, email, grade_level, age, enrolled_on)
-- VALUES ('Negative Age', 'neg@mail.kz', 'Grade 9', -3, '2026-01-01');
-- ERROR: new row for relation "students" violates check constraint "students_age_check"

-- 5. Violates FOREIGN KEY (tutor_id does not exist):
-- INSERT INTO sessions (tutor_id, student_id, session_date, duration_min, topic)
-- VALUES (999, 1, '2026-04-01', 60, 'Fake session');
-- ERROR: insert or update on table "sessions" violates foreign key constraint "sessions_tutor_id_fkey"
