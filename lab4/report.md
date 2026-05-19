# Лабораторна робота 4: Аналітичні SQL-запити (OLAP)

**Система:** Платформа прокату автомобілів  

---

## 1. Опис

У цій лабораторній роботі написано аналітичні SQL-запити до бази даних платформи прокату автомобілів. На відміну від OLTP-запитів лабораторної роботи 3, тут акцент зроблено на агрегації, групуванні та аналізі даних — підрахунок виручки, рейтинги авто, активність клієнтів тощо. Усі запити виконувались у pgAdmin на стані бази після вставки даних з лабораторних робіт 2 та 3 (без UPDATE та DELETE).

<img width="837" height="248" alt="image" src="https://github.com/user-attachments/assets/71a0877a-0209-425f-8e38-7758ffffb7b6" />
<img width="803" height="254" alt="image" src="https://github.com/user-attachments/assets/da8f6149-209b-48a0-9695-e940c62d0f24" />
<img width="803" height="254" alt="image" src="https://github.com/user-attachments/assets/637839a3-ac05-43e1-a92f-13fefe22abc6" />
<img width="803" height="254" alt="image" src="https://github.com/user-attachments/assets/9e53c0f7-7652-4cc1-8a8e-f12bdea13dde" />
<img width="964" height="239" alt="image" src="https://github.com/user-attachments/assets/05a1e691-e8ba-4d5f-8075-5db4e3461432" />

---

## 2. Агрегація

### 2.1 Загальна кількість користувачів

```sql
SELECT COUNT(*) AS total_users FROM users;
```
<img width="216" height="116" alt="image" src="https://github.com/user-attachments/assets/530c01b9-30de-4203-bbf5-24ddc297be07" />

Підраховує загальну кількість зареєстрованих користувачів на платформі. Повертає один рядок зі значенням `7`.

### 2.2 Розподіл авто за статусами

```sql
SELECT COUNT(*) AS total_cars,
       COUNT(*) FILTER (WHERE status = 'available')   AS available,
       COUNT(*) FILTER (WHERE status = 'rented')      AS rented,
       COUNT(*) FILTER (WHERE status = 'maintenance') AS maintenance
FROM cars;
```
<img width="387" height="87" alt="image" src="https://github.com/user-attachments/assets/0ded4137-cd68-43e9-8204-a341c85bd8f3" />

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
<img width="664" height="83" alt="image" src="https://github.com/user-attachments/assets/4de90fb1-82dc-43b7-8d95-4ba0ced08525" />

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
<img width="436" height="138" alt="image" src="https://github.com/user-attachments/assets/9febac4e-c241-47a5-9863-d29b5b32ee69" />

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
<img width="603" height="225" alt="image" src="https://github.com/user-attachments/assets/6304673a-cd3c-45d2-a4a2-ac87aa47148c" />

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

<img width="443" height="108" alt="image" src="https://github.com/user-attachments/assets/b6190a8f-088b-4ad7-9d12-2196fddd2374" />

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
<img width="360" height="133" alt="image" src="https://github.com/user-attachments/assets/191090ff-2ac1-4ce2-89d0-cdbd1899b440" />

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
<img width="556" height="130" alt="image" src="https://github.com/user-attachments/assets/30600a53-12bc-4d9c-b90c-1863bcd4e729" />

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
<img width="314" height="109" alt="image" src="https://github.com/user-attachments/assets/f134eb71-9c97-4c7f-b5f0-f06c21cde156" />

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
<img width="471" height="92" alt="image" src="https://github.com/user-attachments/assets/6a0a8e0f-deb7-4459-912b-7704380b073f" />

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
<img width="607" height="159" alt="image" src="https://github.com/user-attachments/assets/968d6dc0-3760-44f9-a428-97e19a1bd34b" />

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
<img width="1014" height="238" alt="image" src="https://github.com/user-attachments/assets/47c9b267-30f8-4e0b-b8b4-8ddc94aabe44" />

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
<img width="680" height="260" alt="image" src="https://github.com/user-attachments/assets/453acddd-dd30-4d3a-b6e2-fed404fbfb46" />

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
<img width="792" height="333" alt="image" src="https://github.com/user-attachments/assets/c9e0892f-ff38-4bfd-9132-202453a9ddc0" />

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
<img width="746" height="240" alt="image" src="https://github.com/user-attachments/assets/033d7e89-46d1-4f18-ac26-271237813ab6" />

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
<img width="783" height="238" alt="image" src="https://github.com/user-attachments/assets/57754913-d1da-43f8-9d65-78dd70ea01c8" />

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
<img width="569" height="115" alt="image" src="https://github.com/user-attachments/assets/c17cfdf7-9f7a-4ecc-a0fb-803d50db1b74" />

Підзапит обчислює середню вартість оренди, а зовнішній запит фільтрує лише ті оренди, що перевищують цей поріг. Дозволяє виявити дорогі оренди без хардкоду числа.

### 5.2 WHERE NOT IN — авто, які жодного разу не орендували

```sql
SELECT car_id, brand, model, price_per_day, status
FROM cars
WHERE car_id NOT IN (
    SELECT DISTINCT car_id FROM rentals
);
```
<img width="711" height="99" alt="image" src="https://github.com/user-attachments/assets/23346259-3fe8-48e9-bcd7-861c39408986" />

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
<img width="499" height="141" alt="image" src="https://github.com/user-attachments/assets/9ac9e344-c4e5-4b11-b3c1-802a8deaae6f" />

Підзапит з `JOIN` повертає `client_id` усіх клієнтів, що мають хоча б один відгук. Зовнішній запит отримує їхні профілі.

### 5.4 SELECT — кількість оренд для кожного авто

```sql
SELECT c.car_id, c.brand, c.model, c.price_per_day,
       (SELECT COUNT(*) FROM rentals r WHERE r.car_id = c.car_id) AS total_rentals
FROM cars c
ORDER BY total_rentals DESC;
```
<img width="652" height="260" alt="image" src="https://github.com/user-attachments/assets/24c14abf-a2ab-4c5c-b348-f4b6605439b8" />

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
<img width="335" height="108" alt="image" src="https://github.com/user-attachments/assets/ba6a6f7c-f22c-4d46-a944-15975d257822" />

Вкладений підзапит у `HAVING`: внутрішній підзапит групує виручку по власниках і обчислює середнє, зовнішній `HAVING` фільтрує лише тих власників, чий дохід перевищує це середнє. Найскладніший запит у роботі.

---

## 6. Висновки

У ході лабораторної роботи написано 21 аналітичний SQL-запит, що охоплюють усі вимоги завдання. Основні спостереження:

- Агрегатні функції (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) у поєднанні з `GROUP BY` дозволяють отримати бізнес-аналітику без будь-якого постобробки даних поза БД.
- `FILTER (WHERE ...)` є зручною PostgreSQL-альтернативою до `CASE WHEN` у агрегатах — дозволяє обчислювати кілька умовних агрегатів в одному рядку.
- Різниця між `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN` і `FULL JOIN` критична для коректності результатів: `INNER JOIN` приховує записи без пари, тоді як `LEFT/FULL JOIN` зберігають їх із `NULL`.
- Підзапити у `WHERE`, `SELECT` та `HAVING` дозволяють будувати динамічні умови без хардкоду — наприклад, фільтр "дорожче за середнє" автоматично адаптується при зміні даних.
- `HAVING` фільтрує результати після агрегації, на відміну від `WHERE`, який працює до неї — ця різниця є принциповою і часто є джерелом помилок.
