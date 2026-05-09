# Лабораторна робота 4: Аналітичні SQL-запити (OLAP)

**Система:** Платформа прокату автомобілів  

---

## 1. Опис

У цій лабораторній роботі написано аналітичні SQL-запити до бази даних платформи прокату автомобілів. На відміну від OLTP-запитів лабораторної роботи 3, тут акцент зроблено на агрегації, групуванні та аналізі даних — підрахунок виручки, рейтинги авто, активність клієнтів тощо. Усі запити виконувались у pgAdmin на стані бази після вставки даних з лабораторних робіт 2 та 3 (без UPDATE та DELETE).

---

## 2. Агрегація

### 2.1 Загальна кількість користувачів

```sql
SELECT COUNT(*) AS total_users FROM users;
```

Підраховує загальну кількість зареєстрованих користувачів на платформі. Повертає один рядок зі значенням `7`.

### 2.2 Розподіл авто за статусами

```sql
SELECT COUNT(*) AS total_cars,
       COUNT(*) FILTER (WHERE status = 'available')   AS available,
       COUNT(*) FILTER (WHERE status = 'rented')      AS rented,
       COUNT(*) FILTER (WHERE status = 'maintenance') AS maintenance
FROM cars;
```

Одним запитом отримує загальну кількість авто та їх розподіл за статусами. Використовує `FILTER` — PostgreSQL-розширення агрегатних функцій для умовного підрахунку без підзапитів.

### 2.3 Фінансова статистика оренд

```sql
SELECT COUNT(*)         AS total_rentals,
       SUM(total_price) AS total_revenue,
       AVG(total_price) AS avg_rental_price,
       MIN(total_price) AS min_rental_price,
       MAX(total_price) AS max_rental_price
FROM rentals;
```

Зведена фінансова картина: кількість оренд, загальна виручка, середня, мінімальна та максимальна вартість. Корисно для фінансового звіту платформи.

### 2.4 Платежі за методом оплати

```sql
SELECT method,
       COUNT(*)    AS payment_count,
       SUM(amount) AS total_amount
FROM payments
GROUP BY method
ORDER BY total_amount DESC;
```

Групує платежі за методом (`card`, `cash`, `online`) і підраховує кількість та суму по кожному. Дозволяє визначити найпопулярніший спосіб оплати.

### 2.5 Статистика по марках авто

```sql
SELECT brand,
       COUNT(*)           AS car_count,
       AVG(price_per_day) AS avg_price,
       MIN(price_per_day) AS min_price,
       MAX(price_per_day) AS max_price
FROM cars
GROUP BY brand
ORDER BY avg_price DESC;
```

Для кожної марки показує кількість авто і ціновий діапазон. Дозволяє побачити, які бренди домінують на платформі та як відрізняються їх ціни.

### 2.6 Помісячна виручка

```sql
SELECT EXTRACT(YEAR FROM start_date)  AS year,
       EXTRACT(MONTH FROM start_date) AS month,
       COUNT(*)                       AS rentals_count,
       SUM(total_price)               AS monthly_revenue
FROM rentals
GROUP BY year, month
ORDER BY year, month;
```

Групує оренди по місяцях і підраховує кількість та виручку за кожен. Типовий OLAP-запит для аналізу сезонності попиту.

### 2.7 Розподіл оренд за статусами

```sql
SELECT status,
       COUNT(*)         AS count,
       SUM(total_price) AS total_price
FROM rentals
GROUP BY status
ORDER BY count DESC;
```

Показує, скільки оренд перебуває у кожному статусі і яка загальна сума по ним. Дозволяє оцінити частку завершених, активних і скасованих оренд.

### 2.8 Топ клієнтів за витратами

```sql
SELECT u.full_name,
       COUNT(r.rental_id) AS total_rentals,
       SUM(r.total_price) AS total_spent,
       AVG(r.total_price) AS avg_rental_price
FROM users u
JOIN rentals r ON r.client_id = u.user_id
GROUP BY u.user_id, u.full_name
ORDER BY total_spent DESC;
```

Рейтинг клієнтів за загальними витратами з додатковими метриками: кількість оренд і середня вартість. Основа для програми лояльності.

---

## 3. HAVING — фільтрація груп

### 3.1 Активні клієнти (більше 1 оренди)

```sql
SELECT u.full_name,
       COUNT(r.rental_id) AS total_rentals
FROM users u
JOIN rentals r ON r.client_id = u.user_id
GROUP BY u.user_id, u.full_name
HAVING COUNT(r.rental_id) > 1;
```

Відфільтровує лише тих клієнтів, що орендували більше одного разу. `HAVING` застосовується після групування, на відміну від `WHERE`, який фільтрує рядки до агрегації.

### 3.2 Власники з преміальними авто

```sql
SELECT u.full_name,
       COUNT(c.car_id)      AS cars_listed,
       AVG(c.price_per_day) AS avg_price
FROM users u
JOIN cars c ON c.owner_id = u.user_id
GROUP BY u.user_id, u.full_name
HAVING AVG(c.price_per_day) > 1500;
```

Показує власників, чия середня ціна авто перевищує 1500 грн/день. Дозволяє виділити преміум-сегмент орендодавців.

### 3.3 Авто з високим рейтингом

```sql
SELECT c.brand, c.model,
       AVG(rv.rating)      AS avg_rating,
       COUNT(rv.review_id) AS review_count
FROM cars c
JOIN rentals r  ON r.car_id     = c.car_id
JOIN reviews rv ON rv.rental_id = r.rental_id
GROUP BY c.car_id, c.brand, c.model
HAVING AVG(rv.rating) >= 4;
```

Повертає лише авто із середнім рейтингом 4 і вище. Може використовуватись для розділу "Рекомендовані авто" на платформі.

---

## 4. JOIN — об'єднання таблиць

### 4.1 INNER JOIN — повна картина оренд

```sql
SELECT r.rental_id,
       u.full_name AS client,
       c.brand, c.model,
       r.start_date, r.end_date,
       r.total_price, r.status
FROM rentals r
INNER JOIN users u ON u.user_id = r.client_id
INNER JOIN cars c  ON c.car_id  = r.car_id
ORDER BY r.rental_id;
```

Об'єднує три таблиці для отримання повного опису кожної оренди. `INNER JOIN` повертає лише записи, що мають відповідники в усіх таблицях. Повертає 7 рядків.

### 4.2 LEFT JOIN — авто з кількістю оренд (включно з тими, що не орендувались)

```sql
SELECT c.car_id, c.brand, c.model, c.price_per_day,
       COUNT(r.rental_id) AS times_rented
FROM cars c
LEFT JOIN rentals r ON r.car_id = c.car_id
GROUP BY c.car_id, c.brand, c.model, c.price_per_day
ORDER BY times_rented DESC;
```

`LEFT JOIN` гарантує, що в результаті будуть усі авто — навіть ті, що жодного разу не орендувались (для них `times_rented = 0`). `INNER JOIN` приховав би такі записи.

### 4.3 LEFT JOIN — користувачі та їхні відгуки

```sql
SELECT u.full_name,
       rv.rating, rv.comment, rv.created_at
FROM users u
LEFT JOIN rentals r  ON r.client_id  = u.user_id
LEFT JOIN reviews rv ON rv.rental_id = r.rental_id
ORDER BY u.user_id;
```

Показує всіх користувачів і їхні відгуки. Якщо користувач не залишав відгуків або взагалі не орендував — `rating` і `comment` будуть `NULL`. Корисно для аналізу залученості.

### 4.4 RIGHT JOIN — всі платежі з деталями оренди

```sql
SELECT p.payment_id, p.amount, p.method,
       r.status AS rental_status,
       r.start_date, r.end_date
FROM rentals r
RIGHT JOIN payments p ON p.rental_id = r.rental_id
ORDER BY p.payment_id;
```

`RIGHT JOIN` гарантує, що в результаті всі платежі — навіть якби існував платіж без оренди. Тут демонструє протилежну точку зору порівняно з `LEFT JOIN`.

### 4.5 FULL JOIN — оренди і відгуки

```sql
SELECT r.rental_id,
       r.status AS rental_status,
       r.total_price,
       rv.rating, rv.comment
FROM rentals r
FULL JOIN reviews rv ON rv.rental_id = r.rental_id
ORDER BY r.rental_id;
```

`FULL JOIN` повертає всі рядки з обох таблиць, заповнюючи `NULL` там, де немає відповідника. Оренди без відгуків та відгуки без оренд (якщо такі є) — всі потраплять у результат.

---

## 5. Підзапити

### 5.1 WHERE — оренди дорожчі за середню

```sql
SELECT rental_id, client_id, car_id, total_price, status
FROM rentals
WHERE total_price > (
    SELECT AVG(total_price) FROM rentals
)
ORDER BY total_price DESC;
```

Підзапит обчислює середню вартість оренди, а зовнішній запит фільтрує лише ті оренди, що перевищують цей поріг. Дозволяє виявити дорогі оренди без хардкоду числа.

### 5.2 WHERE NOT IN — авто, які жодного разу не орендували

```sql
SELECT car_id, brand, model, price_per_day, status
FROM cars
WHERE car_id NOT IN (
    SELECT DISTINCT car_id FROM rentals
);
```

Підзапит будує список `car_id` що фігурують в орендах, а зовнішній запит повертає всі авто поза цим списком. Корисно для виявлення "мертвих" оголошень.

### 5.3 WHERE IN — клієнти, що залишали відгуки

```sql
SELECT user_id, full_name, email
FROM users
WHERE user_id IN (
    SELECT r.client_id
    FROM rentals r
    JOIN reviews rv ON rv.rental_id = r.rental_id
);
```

Підзапит з `JOIN` повертає `client_id` усіх клієнтів, що мають хоча б один відгук. Зовнішній запит отримує їхні профілі.

### 5.4 SELECT — кількість оренд для кожного авто

```sql
SELECT c.car_id, c.brand, c.model, c.price_per_day,
       (SELECT COUNT(*) FROM rentals r WHERE r.car_id = c.car_id) AS total_rentals
FROM cars c
ORDER BY total_rentals DESC;
```

Корельований підзапит у `SELECT` — для кожного рядка `cars` виконується окремий підзапит, який рахує оренди цього авто. Альтернатива `LEFT JOIN + GROUP BY`, але читабельніша для простих випадків.

### 5.5 HAVING — власники з доходом вище середнього

```sql
SELECT owner.full_name,
       SUM(r.total_price) AS total_revenue
FROM users owner
JOIN cars c    ON c.owner_id = owner.user_id
JOIN rentals r ON r.car_id   = c.car_id
GROUP BY owner.user_id, owner.full_name
HAVING SUM(r.total_price) > (
    SELECT AVG(rev_per_owner)
    FROM (
        SELECT SUM(r2.total_price) AS rev_per_owner
        FROM cars c2
        JOIN rentals r2 ON r2.car_id = c2.car_id
        GROUP BY c2.owner_id
    ) sub
);
```

Вкладений підзапит у `HAVING`: внутрішній підзапит групує виручку по власниках і обчислює середнє, зовнішній `HAVING` фільтрує лише тих власників, чий дохід перевищує це середнє. Найскладніший запит у роботі.

---

## 6. Висновки

У ході лабораторної роботи написано 21 аналітичний SQL-запит, що охоплюють усі вимоги завдання. Основні спостереження:

- Агрегатні функції (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) у поєднанні з `GROUP BY` дозволяють отримати бізнес-аналітику без будь-якого постобробки даних поза БД.
- `FILTER (WHERE ...)` є зручною PostgreSQL-альтернативою до `CASE WHEN` у агрегатах — дозволяє обчислювати кілька умовних агрегатів в одному рядку.
- Різниця між `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN` і `FULL JOIN` критична для коректності результатів: `INNER JOIN` приховує записи без пари, тоді як `LEFT/FULL JOIN` зберігають їх із `NULL`.
- Підзапити у `WHERE`, `SELECT` та `HAVING` дозволяють будувати динамічні умови без хардкоду — наприклад, фільтр "дорожче за середнє" автоматично адаптується при зміні даних.
- `HAVING` фільтрує результати після агрегації, на відміну від `WHERE`, який працює до неї — ця різниця є принциповою і часто є джерелом помилок.
