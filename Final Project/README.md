#  Cinema Database — Final Project

Учебный финальный проект: реляционная база данных кинотеатра, реализованная на PostgreSQL.

---

```
cinema_db/
└── schema: cinema
    ├── Tables (12)
    ├── Views (2)
    ├── Functions (1)
    └── Roles (2)
```

---

## Схема базы данных

### Таблицы

| Таблица | Описание |
|---|---|
| `country` | Страны |
| `city` | Города (FK → country) |
| `customer` | Клиенты кинотеатра |
| `genre` | Жанры фильмов |
| `film` | Фильмы |
| `film_genre` | Связь M:N — фильм ↔ жанр |
| `hall` | Залы кинотеатра |
| `seat` | Места в залах |
| `session` | Сеансы (фильм + зал + дата/время) |
| `payment_method` | Способы оплаты |
| `booking` | Бронирования клиентов |
| `ticket` | Билеты (бронирование + сеанс + место) |
| `employee` | Сотрудники кинотеатра |

### ER-диаграмма (упрощённая)

```
country ──< city ──< customer ──< booking ──< ticket
                                                 │
film ──< film_genre >── genre          session ──┘
film ──< session ──< hall ──< seat ────────────┘
                    payment_method ──< booking
```

---

##  Установка и запуск

### Предварительные требования

- PostgreSQL 14+
- psql или любой SQL-клиент (DBeaver, pgAdmin)

### Шаги

```sql
-- 1. Создайте базу данных
CREATE DATABASE cinema_db;

-- 2. Подключитесь к cinema_db
\c cinema_db

-- 3. Запустите скрипт
\i 51-final-assignment-release.sql
```

---

##  Содержимое скрипта

### Part 2–3 — DDL: CREATE TABLE + ALTER TABLE

- Созданы все 13 таблиц со связями, CHECK-ограничениями и дефолтными значениями
- Добавлены constraints через `ALTER TABLE`:
  - `chk_film_release_year` — год выпуска ≥ 1888
  - `chk_booking_status` — статусы: `confirmed`, `cancelled`, `pending`
  - `chk_customer_status` — статусы: `regular`, `vip`, `inactive`
- Используются вычисляемые (GENERATED) колонки:
  - `ticket.price_with_vat` = `unit_price × 1.12`
  - `employee.full_name` = `first_name || ' ' || last_name`

### Part 4 — DML: INSERT

Тестовые данные:

- 3 страны, 5 городов
- 5 фильмов, 6 жанров
- 3 зала, 45 мест (3 × 5 на каждый зал)
- 3 способа оплаты
- 6 клиентов, 6 сотрудников
- 6 сеансов, 6 бронирований, 6 билетов

### Part 5 — UPDATE / DELETE + Функция

**Функция `update_customer_column`** — динамическое обновление любого поля клиента:

```sql
SELECT cinema.update_customer_column(
    <customer_id>,
    'status',
    'vip'
);
```

**UPDATE:** клиенты с 2+ подтверждёнными бронированиями получают статус `vip`

**UPDATE…FROM:** пересчёт `total_amount` в `booking` из суммы билетов (с НДС)

**DELETE (в транзакции с ROLLBACK):** удаление отменённых бронирований старше 90 дней

### Part 6 — Views

| View | Описание |
|---|---|
| `analytics_recent_quarter` | Детальная аналитика: фильм, жанр, клиент, оплата — за текущий квартал |
| `total_results_of_quarter` | Итоги квартала: число сеансов, бронирований, выручка |

```sql
SELECT * FROM cinema.analytics_recent_quarter;
SELECT * FROM cinema.total_results_of_quarter;
```

### Part 7 — Роли и права доступа

| Роль | Права |
|---|---|
| `cinema_manager_readonly` | `LOGIN`, `SELECT` на все таблицы схемы `cinema` |
| `cinema_writer` | `INSERT` на `booking` и `ticket`; `UPDATE` отозван после security review |

---

##  Безопасность

- `cinema_manager_readonly` — только чтение, подходит для аналитиков
- `cinema_writer` — право на `UPDATE booking` отозвано; изменение статуса должно проходить через хранимую процедуру с аудит-логом
- Все пароли ролей хранятся в PostgreSQL pg_authid; не включайте их в публичные репозитории

---

##  Тестовые данные

### Клиенты

| Email | Город | Статус |
|---|---|---|
| aizat.bekova@mail.kz | Almaty | vip |
| daniyar.seitkali@mail.kz | Nur-Sultan | regular |
| gulnaz.akhmetova@mail.kz | Atyrau | regular |
| ruslan.ospanov@mail.kz | Almaty | regular |
| assel.nurova@mail.kz | Nur-Sultan | regular |
| timur.bekzhanov@mail.kz | Atyrau | regular |

### Фильмы

| Название | Год | Жанры |
|---|---|---|
| Nomad: The Warrior | 2006 | Action, Drama |
| Interstellar | 2014 | Drama, Thriller |
| The Dark Knight | 2008 | Action, Thriller |
| Parasite | 2019 | Drama, Thriller |
| Toy Story 4 | 2019 | Animation, Comedy |

---



## 👤 Автор

Финальный проект по курсу баз данных — Cinema Domain.
