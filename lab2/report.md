# Лабораторна робота 2: Перетворення ER-діаграми на схему PostgreSQL

**Система:** Платформа прокату автомобілів  

---

## 1. Опис схеми

На основі ER-діаграми з Лабораторної роботи 1 було побудовано реляційну схему з 5 таблиць. Кожна сутність перетворена на окрему таблицю, зв'язки реалізовані через зовнішні ключі. Оскільки в системі відсутні зв'язки "багато до багатьох", таблиці-з'єднання не знадобились — `rentals` є природною асоціативною таблицею між `users` (у ролі клієнта) і `cars`.

---

## 2. Таблиці, стовпці та ключі

### 2.1 `users`

Зберігає всіх зареєстрованих користувачів платформи. Один запис може виступати і орендодавцем (через `cars.owner_id`), і орендарем (через `rentals.client_id`).

| Стовпець | Тип | Обмеження | Опис |
|---|---|---|---|
| `user_id` | `SERIAL` | `PRIMARY KEY` | Унікальний ідентифікатор |
| `full_name` | `VARCHAR(100)` | `NOT NULL` | Повне ім'я |
| `phone` | `VARCHAR(20)` | `NOT NULL UNIQUE` | Номер телефону |
| `email` | `VARCHAR(150)` | `NOT NULL UNIQUE` | Електронна пошта |
| `driver_license` | `VARCHAR(20)` | `NOT NULL UNIQUE` | Номер водійського посвідчення |
| `created_at` | `TIMESTAMP` | `NOT NULL DEFAULT NOW()` | Дата реєстрації |

### 2.2 `cars`

Автомобілі, виставлені для оренди. Кожен автомобіль прив'язаний до одного власника.

| Стовпець | Тип | Обмеження | Опис |
|---|---|---|---|
| `car_id` | `SERIAL` | `PRIMARY KEY` | Унікальний ідентифікатор |
| `owner_id` | `INTEGER` | `NOT NULL REFERENCES users(user_id)` | Власник авто |
| `brand` | `VARCHAR(50)` | `NOT NULL` | Марка |
| `model` | `VARCHAR(50)` | `NOT NULL` | Модель |
| `year` | `SMALLINT` | `NOT NULL CHECK (year >= 1900 AND year <= 2100)` | Рік випуску |
| `price_per_day` | `NUMERIC(8,2)` | `NOT NULL CHECK (price_per_day > 0)` | Ціна за добу |
| `status` | `VARCHAR(20)` | `NOT NULL DEFAULT 'available' CHECK (...)` | `available` / `rented` / `maintenance` |

### 2.3 `rentals`

Асоціативна таблиця між `users` (орендар) і `cars`. Фіксує кожен факт оренди.

| Стовпець | Тип | Обмеження | Опис |
|---|---|---|---|
| `rental_id` | `SERIAL` | `PRIMARY KEY` | Унікальний ідентифікатор |
| `car_id` | `INTEGER` | `NOT NULL REFERENCES cars(car_id)` | Орендоване авто |
| `client_id` | `INTEGER` | `NOT NULL REFERENCES users(user_id)` | Орендар |
| `start_date` | `DATE` | `NOT NULL` | Дата початку |
| `end_date` | `DATE` | `NOT NULL` | Дата закінчення |
| `total_price` | `NUMERIC(10,2)` | `NOT NULL CHECK (total_price > 0)` | Загальна вартість |
| `status` | `VARCHAR(20)` | `NOT NULL DEFAULT 'pending' CHECK (...)` | `pending` / `active` / `completed` / `cancelled` |

Додаткове табличне обмеження: `CONSTRAINT chk_dates CHECK (end_date > start_date)` — гарантує коректність дат.

### 2.4 `payments`

Один платіж на одну оренду. Зв'язок 1:1 із `rentals` забезпечено через `UNIQUE` на `rental_id`.

| Стовпець | Тип | Обмеження | Опис |
|---|---|---|---|
| `payment_id` | `SERIAL` | `PRIMARY KEY` | Унікальний ідентифікатор |
| `rental_id` | `INTEGER` | `NOT NULL UNIQUE REFERENCES rentals(rental_id)` | Оренда |
| `amount` | `NUMERIC(10,2)` | `NOT NULL CHECK (amount > 0)` | Сума платежу |
| `method` | `VARCHAR(20)` | `NOT NULL CHECK (method IN ('card', 'cash', 'online'))` | Спосіб оплати |
| `paid_at` | `TIMESTAMP` | `NOT NULL DEFAULT NOW()` | Час транзакції |

### 2.5 `reviews`

Необов'язковий відгук після завершення оренди. Зв'язок 1:1 із `rentals` також через `UNIQUE`.

| Стовпець | Тип | Обмеження | Опис |
|---|---|---|---|
| `review_id` | `SERIAL` | `PRIMARY KEY` | Унікальний ідентифікатор |
| `rental_id` | `INTEGER` | `NOT NULL UNIQUE REFERENCES rentals(rental_id)` | Оренда |
| `rating` | `SMALLINT` | `NOT NULL CHECK (rating BETWEEN 1 AND 5)` | Оцінка 1–5 |
| `comment` | `TEXT` | — | Текстовий коментар (необов'язковий) |
| `created_at` | `TIMESTAMP` | `NOT NULL DEFAULT NOW()` | Дата публікації |

---

## 3. SQL-скрипт

```sql
CREATE TABLE users (
    user_id        SERIAL PRIMARY KEY,
    full_name      VARCHAR(100) NOT NULL,
    phone          VARCHAR(20)  NOT NULL UNIQUE,
    email          VARCHAR(150) NOT NULL UNIQUE,
    driver_license VARCHAR(20)  NOT NULL UNIQUE,
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE cars (
    car_id        SERIAL PRIMARY KEY,
    owner_id      INTEGER      NOT NULL REFERENCES users(user_id),
    brand         VARCHAR(50)  NOT NULL,
    model         VARCHAR(50)  NOT NULL,
    year          SMALLINT     NOT NULL CHECK (year >= 1900 AND year <= 2100),
    price_per_day NUMERIC(8,2) NOT NULL CHECK (price_per_day > 0),
    status        VARCHAR(20)  NOT NULL DEFAULT 'available'
                               CHECK (status IN ('available', 'rented', 'maintenance'))
);

CREATE TABLE rentals (
    rental_id   SERIAL PRIMARY KEY,
    car_id      INTEGER       NOT NULL REFERENCES cars(car_id),
    client_id   INTEGER       NOT NULL REFERENCES users(user_id),
    start_date  DATE          NOT NULL,
    end_date    DATE          NOT NULL,
    total_price NUMERIC(10,2) NOT NULL CHECK (total_price > 0),
    status      VARCHAR(20)   NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    CONSTRAINT chk_dates CHECK (end_date > start_date)
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    rental_id  INTEGER       NOT NULL UNIQUE REFERENCES rentals(rental_id),
    amount     NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    method     VARCHAR(20)   NOT NULL CHECK (method IN ('card', 'cash', 'online')),
    paid_at    TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE TABLE reviews (
    review_id  SERIAL PRIMARY KEY,
    rental_id  INTEGER   NOT NULL UNIQUE REFERENCES rentals(rental_id),
    rating     SMALLINT  NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO users (full_name, phone, email, driver_license) VALUES
    ('Олег Коваленко',   '+380501234567', 'oleg.kovalenko@gmail.com',   'АА123456'),
    ('Марія Шевченко',   '+380672345678', 'maria.shevchenko@gmail.com', 'ВВ234567'),
    ('Іван Бондаренко',  '+380933456789', 'ivan.bondarenko@gmail.com',  'СС345678'),
    ('Катерина Мельник', '+380504567890', 'kate.melnyk@gmail.com',      'ДД456789'),
    ('Дмитро Лисенко',   '+380675678901', 'dmytro.lysenko@gmail.com',   'ЕЕ567890');

INSERT INTO cars (owner_id, brand, model, year, price_per_day, status) VALUES
    (1, 'Toyota',     'Camry',    2020, 1200.00, 'available'),
    (1, 'Toyota',     'RAV4',     2021, 1800.00, 'rented'),
    (2, 'BMW',        '3 Series', 2019, 2500.00, 'available'),
    (3, 'Volkswagen', 'Golf',     2018,  900.00, 'available'),
    (3, 'Hyundai',    'Tucson',   2022, 1600.00, 'maintenance');

INSERT INTO rentals (car_id, client_id, start_date, end_date, total_price, status) VALUES
    (1, 4, '2025-04-01', '2025-04-05', 4800.00, 'completed'),
    (2, 5, '2025-04-10', '2025-04-15', 9000.00, 'completed'),
    (3, 4, '2025-04-20', '2025-04-22', 5000.00, 'completed'),
    (4, 5, '2025-05-01', '2025-05-03', 1800.00, 'active'),
    (1, 5, '2025-05-10', '2025-05-12', 2400.00, 'pending');

INSERT INTO payments (rental_id, amount, method, paid_at) VALUES
    (1, 4800.00, 'card',   '2025-04-01 10:00:00'),
    (2, 9000.00, 'online', '2025-04-10 09:30:00'),
    (3, 5000.00, 'card',   '2025-04-20 14:15:00'),
    (4, 1800.00, 'cash',   '2025-05-01 11:00:00'),
    (5, 2400.00, 'online', '2025-05-09 16:45:00');

INSERT INTO reviews (rental_id, rating, comment) VALUES
    (1, 5, 'Чудовий автомобіль, все як описано. Рекомендую!'),
    (2, 4, 'Гарне авто, але варто помити перед видачею.'),
    (3, 5, 'BMW справив враження, беру ще раз.');

SELECT * FROM users;
SELECT * FROM cars;
SELECT * FROM rentals;
SELECT * FROM payments;
SELECT * FROM reviews;
```

---

## 4. Зовнішні ключі та зв'язки

| Таблиця | Стовпець FK | Посилається на | Тип зв'язку |
|---|---|---|---|
| `cars` | `owner_id` | `users(user_id)` | N:1 — багато авто у одного власника |
| `rentals` | `car_id` | `cars(car_id)` | N:1 — одне авто в багатьох орендах |
| `rentals` | `client_id` | `users(user_id)` | N:1 — один клієнт у багатьох орендах |
| `payments` | `rental_id` | `rentals(rental_id)` | 1:1 — один платіж на оренду |
| `reviews` | `rental_id` | `rentals(rental_id)` | 1:1 — один відгук на оренду |

---

## 5. Важливі обмеження та припущення

1. **Єдина таблиця користувачів.** `users` об'єднує орендодавців і орендарів. Роль визначається контекстом: `cars.owner_id` — орендодавець, `rentals.client_id` — орендар.
2. **Самооренда.** Умова `client_id ≠ cars.owner_id` не реалізована на рівні БД — вона перевіряється на рівні застосунку, оскільки вимагає join-перевірки між таблицями, що не підтримується простим `CHECK`.
3. **Фіксація ціни.** `rentals.total_price` зберігає вартість, розраховану на момент бронювання. Зміна `cars.price_per_day` не впливає на існуючі оренди.
4. **Платіж обов'язковий.** Кожна оренда повинна мати запис у `payments`. Оренда зі статусом `pending` може тимчасово не мати платежу — це допустимо до підтвердження.
5. **Відгук необов'язковий.** `reviews` не містить `NOT NULL` на рівні `rentals` — відгук може бути відсутнім. Залишати відгук дозволяється лише після переходу оренди в статус `completed` (перевіряється в застосунку).
6. **Рік авто.** Обмеження `CHECK (year >= 1900 AND year <= 2100)` задає статичний діапазон замість динамічного `EXTRACT(YEAR FROM NOW())` для спрощення та передбачуваності.

## 6. Демонстрація заповнення таблиць
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-14" src="https://github.com/user-attachments/assets/a32e8df2-f187-4eb5-aa7b-84750a164fae" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-24" src="https://github.com/user-attachments/assets/fef7e8b6-6e5b-4bef-851b-df2ae3ed83f6" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-35" src="https://github.com/user-attachments/assets/e5145c2a-e721-4f1c-a5f6-69c27d688c94" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-47" src="https://github.com/user-attachments/assets/755f4810-d133-4856-9eea-d647a6817c90" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-59" src="https://github.com/user-attachments/assets/402f549d-5f0f-4ccf-98c8-b84029eb67b7" />




