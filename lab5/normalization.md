# Лабораторна робота 5: Нормалізація бази даних

**Система:** Платформа прокату автомобілів  

---

## 1. Вступ

У цій лабораторній роботі проведено аналіз схеми бази даних платформи прокату автомобілів на відповідність нормальним формам (1НФ, 2НФ, 3НФ). За результатами аналізу встановлено, що **поточна схема вже знаходиться у третій нормальній формі (3НФ)**. У звіті наведено функціональні залежності кожної таблиці, доведено відповідність кожній нормальній формі, а також детально описано типові помилки проектування, яких було свідомо уникнуто під час розробки схеми.

---

## 2. Схема бази даних (фінальна)

```mermaid
erDiagram
    users ||--o{ cars    : "розміщує"
    users ||--o{ rentals : "орендує"
    cars  ||--o{ rentals : "входить у"
    rentals ||--|| payments : "має"
    rentals ||--o| reviews  : "отримує"

    users {
        int     user_id        PK
        string  full_name
        string  phone          UK
        string  email          UK
        string  driver_license UK
        timestamp created_at
    }
    cars {
        int     car_id        PK
        int     owner_id      FK
        string  brand
        string  model
        int     year
        decimal price_per_day
        string  status
    }
    rentals {
        int     rental_id   PK
        int     car_id      FK
        int     client_id   FK
        date    start_date
        date    end_date
        decimal total_price
        string  status
    }
    payments {
        int     payment_id PK
        int     rental_id  FK UK
        decimal amount
        string  method
        timestamp paid_at
    }
    reviews {
        int     review_id  PK
        int     rental_id  FK UK
        int     rating
        text    comment
        timestamp created_at
    }
```

---

## 3. Функціональні залежності

### 3.1 `users`

```
user_id        → full_name, phone, email, driver_license, created_at
phone          → user_id, full_name, email, driver_license, created_at
email          → user_id, full_name, phone, driver_license, created_at
driver_license → user_id, full_name, phone, email, created_at
```

Первинний ключ: `user_id`.  
Альтернативні ключі (candidate keys): `phone`, `email`, `driver_license` — кожен з них унікально ідентифікує користувача.  
Усі неключові атрибути (`full_name`, `created_at`) залежать безпосередньо від первинного ключа.

### 3.2 `cars`

```
car_id → owner_id, brand, model, year, price_per_day, status
```

Первинний ключ: `car_id`.  
`owner_id` — зовнішній ключ до `users`, а не дані про власника. Жоден атрибут не залежить від іншого неключового атрибута.

### 3.3 `rentals`

```
rental_id → car_id, client_id, start_date, end_date, total_price, status
```

Первинний ключ: `rental_id`.  
`car_id` і `client_id` — зовнішні ключі, а не дублювання даних. `total_price` залежить безпосередньо від `rental_id` (зафіксована на момент бронювання).

### 3.4 `payments`

```
payment_id → rental_id, amount, method, paid_at
rental_id  → payment_id, amount, method, paid_at
```

Первинний ключ: `payment_id`.  
Альтернативний ключ: `rental_id` (UNIQUE). Зв'язок 1:1 з `rentals`.

### 3.5 `reviews`

```
review_id → rental_id, rating, comment, created_at
rental_id → review_id, rating, comment, created_at
```

Первинний ключ: `review_id`.  
Альтернативний ключ: `rental_id` (UNIQUE). Зв'язок 1:1 з `rentals`.

---

## 4. Аналіз нормальних форм

### 4.1 Перша нормальна форма (1НФ)

**Вимога:** усі атрибути атомарні, немає повторюваних груп.

| Таблиця | Відповідність | Обґрунтування |
|---|---|---|
| `users` | ✅ | Кожне поле містить одне значення. `phone` і `email` — одиничні рядки |
| `cars` | ✅ | Жодного списку чи складеного значення в атрибутах |
| `rentals` | ✅ | Кожна оренда — окремий рядок. Один клієнт, одне авто, один діапазон дат |
| `payments` | ✅ | Один платіж — один рядок |
| `reviews` | ✅ | Один відгук — один рядок |

**Висновок:** усі таблиці знаходяться в 1НФ.

### 4.2 Друга нормальна форма (2НФ)

**Вимога:** таблиця в 1НФ і жоден неключовий атрибут не залежить лише від частини складеного ключа.

У жодній таблиці немає складеного первинного ключа — всі PK є одиночними (`SERIAL`). Тому часткові залежності апріорі неможливі.

| Таблиця | Відповідність | Обґрунтування |
|---|---|---|
| `users` | ✅ | PK — `user_id` (одиночний) |
| `cars` | ✅ | PK — `car_id` (одиночний) |
| `rentals` | ✅ | PK — `rental_id` (одиночний) |
| `payments` | ✅ | PK — `payment_id` (одиночний) |
| `reviews` | ✅ | PK — `review_id` (одиночний) |

**Висновок:** усі таблиці знаходяться в 2НФ.

### 4.3 Третя нормальна форма (3НФ)

**Вимога:** таблиця в 2НФ і жоден неключовий атрибут не залежить від іншого неключового атрибута (немає транзитивних залежностей).

| Таблиця | Відповідність | Обґрунтування |
|---|---|---|
| `users` | ✅ | `full_name`, `phone`, `email`, `driver_license`, `created_at` — всі залежать лише від `user_id` |
| `cars` | ✅ | `brand`, `model`, `year`, `price_per_day`, `status` залежать від `car_id`. `owner_id` — FK, а не дані власника |
| `rentals` | ✅ | `car_id`, `client_id` — FK. `total_price` залежить від `rental_id`, не від `car_id` або `client_id` |
| `payments` | ✅ | `amount`, `method`, `paid_at` залежать від `payment_id`, не один від одного |
| `reviews` | ✅ | `rating`, `comment`, `created_at` залежать від `review_id`, не від `rating` |

**Висновок:** усі таблиці знаходяться в 3НФ.

---

## 5. Потенційні порушення та як їх уникнули

### 5.1 Денормалізована "суперталиця" (порушення 1НФ, 2НФ, 3НФ)

Найпоширеніша помилка початківців — зібрати всі дані в одну таблицю:

```sql
-- ПОГАНО: одна таблиця на всі випадки
CREATE TABLE rental_records (
    rental_id       INTEGER,
    client_name     VARCHAR(100),   -- дублювання
    client_phone    VARCHAR(20),    -- дублювання
    client_email    VARCHAR(150),   -- дублювання
    car_brand       VARCHAR(50),    -- дублювання
    car_model       VARCHAR(50),    -- дублювання
    car_price_day   NUMERIC(8,2),   -- дублювання
    owner_name      VARCHAR(100),   -- дублювання
    start_date      DATE,
    end_date        DATE,
    total_price     NUMERIC(10,2),
    payment_method  VARCHAR(20),    -- порушення 3НФ (окрема сутність)
    payment_amount  NUMERIC(10,2),  -- порушення 3НФ
    rating          SMALLINT,       -- порушення 3НФ (окрема сутність)
    comment         TEXT            -- порушення 3НФ
);
```

**Проблеми цього підходу:**

- **Аномалія оновлення:** якщо клієнт змінив телефон, треба оновити десятки рядків замість одного в `users`.
- **Аномалія вставки:** неможливо додати авто без оренди (або треба заповнювати `NULL` у полях клієнта).
- **Аномалія видалення:** видалення єдиної оренди клієнта знищує всю інформацію про нього.
- **Надлишковість:** ім'я та контакти клієнта повторюються в кожному рядку оренди.

**Як уникнули:** розбили дані на 5 окремих таблиць з FK-зв'язками.

---

### 5.2 Зберігання даних власника в таблиці `cars` (порушення 3НФ)

```sql
-- ПОГАНО: транзитивна залежність через owner_name
CREATE TABLE cars (
    car_id        SERIAL PRIMARY KEY,
    owner_name    VARCHAR(100),  -- car_id → owner_id → owner_name (транзитивна!)
    owner_phone   VARCHAR(20),   -- car_id → owner_id → owner_phone
    owner_email   VARCHAR(150),  -- car_id → owner_id → owner_email
    brand         VARCHAR(50),
    model         VARCHAR(50),
    price_per_day NUMERIC(8,2)
);
```

Тут `car_id → owner_name` є транзитивною залежністю через неключовий атрибут `owner_id`. Якщо власник змінює email — треба оновити всі його авто.

**Як уникнули:** зберігаємо лише `owner_id FK → users(user_id)`. Дані власника живуть в `users` в єдиному місці.

---

### 5.3 Зберігання даних авто і клієнта в `rentals` (порушення 3НФ)

```sql
-- ПОГАНО: дублювання даних в оренді
CREATE TABLE rentals (
    rental_id    SERIAL PRIMARY KEY,
    car_brand    VARCHAR(50),    -- транзитивна: rental_id → car_id → brand
    car_model    VARCHAR(50),    -- транзитивна: rental_id → car_id → model
    client_name  VARCHAR(100),   -- транзитивна: rental_id → client_id → full_name
    client_phone VARCHAR(20),    -- транзитивна: rental_id → client_id → phone
    start_date   DATE,
    end_date     DATE,
    total_price  NUMERIC(10,2)
);
```

**Як уникнули:** зберігаємо лише `car_id` і `client_id` як FK. Дані отримуємо через `JOIN`.

---

### 5.4 Зберігання платежу і відгуку безпосередньо в `rentals` (порушення 3НФ)

```sql
-- ПОГАНО: payment і review змішані з rentals
CREATE TABLE rentals (
    rental_id      SERIAL PRIMARY KEY,
    car_id         INTEGER,
    client_id      INTEGER,
    start_date     DATE,
    end_date       DATE,
    total_price    NUMERIC(10,2),
    payment_method VARCHAR(20),   -- транзитивна через payment_id
    payment_amount NUMERIC(10,2), -- транзитивна через payment_id
    paid_at        TIMESTAMP,     -- транзитивна через payment_id
    rating         SMALLINT,      -- транзитивна через review_id
    comment        TEXT           -- транзитивна через review_id
);
```

`payment_method` залежить від неключового набору "платіж цієї оренди", а не від `rental_id` напряму. Це транзитивна залежність.

Крім того, якщо платіж відсутній або відгук ще не залишено — поля заповнюються `NULL`, що ускладнює запити та порушує семантику.

**Як уникнули:** `payments` і `reviews` — окремі таблиці зі зв'язком 1:1 через `rental_id UNIQUE FK`.

---

### 5.5 Список телефонів через кому в одному полі (порушення 1НФ)

```sql
-- ПОГАНО: неатомарне значення
INSERT INTO users (phone) VALUES ('+380501234567, +380671234567');
```

Зберігання кількох значень в одному рядку порушує атомарність — перше правило 1НФ. Такі дані неможливо коректно фільтрувати або індексувати.

**Як уникнули:** `phone VARCHAR(20) NOT NULL UNIQUE` — одне значення, одне поле.

---

### 5.6 Окремі таблиці `owners` і `clients` замість єдиної `users` (надлишковість)

Якби `owners` і `clients` були окремими таблицями, і один користувач захотів і здавати, і орендувати — його дані зберігалися б двічі з ризиком розсинхронізації (різні email в двох таблицях).

**Як уникнули:** єдина таблиця `users`. Роль визначається контекстом: `cars.owner_id` або `rentals.client_id`.

---

### 5.7 `total_price` як обчислюване поле — чи це порушення?

```
total_price = price_per_day × (end_date − start_date)
```

На перший погляд, `total_price` виглядає як похідне значення і могло б свідчити про надлишковість. Але це свідома денормалізація з бізнес-причини: **`price_per_day` може змінитися після бронювання**, тому фіксація ціни на момент оренди є обов'язковою для коректності рахунків. Це стандартна практика в фінансових системах.

---

## 6. Висновок

Схема платформи прокату автомобілів відповідає вимогам третьої нормальної форми:

- **1НФ:** усі атрибути атомарні, повторюваних груп немає.
- **2НФ:** усі первинні ключі одиночні, часткові залежності неможливі.
- **3НФ:** відсутні транзитивні залежності — кожен неключовий атрибут залежить виключно від первинного ключа своєї таблиці.

Коректна 3НФ-схема досягнута завдяки чіткому розмежуванню сутностей на етапі ER-моделювання: окремі таблиці для користувачів, авто, оренд, платежів і відгуків з FK-зв'язками замість дублювання даних. Усі описані вище потенційні порушення були усунуті ще на стадії проектування, що виключило необхідність додаткової декомпозиції на етапі нормалізації.
