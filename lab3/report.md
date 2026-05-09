# Лабораторна робота 3: Маніпулювання даними SQL (OLTP)

**Система:** Платформа прокату автомобілів  

---

## 1. Опис

У цій лабораторній роботі виконано OLTP-запити до бази даних платформи прокату автомобілів, побудованої в лабораторних роботах 1–2. Усі операції виконувались у pgAdmin на локальній PostgreSQL-базі. Для кожної операції зміни даних (`INSERT`, `UPDATE`, `DELETE`) одразу виконувався `SELECT`-запит для підтвердження результату.

---

## 2. SELECT — вибірка даних

### 2.1 Всі користувачі системи

```sql
SELECT * FROM users;
```

Перевірка наявності всіх зареєстрованих користувачів. Повертає 5 рядків із усіма полями таблиці `users`.

### 2.2 Доступні автомобілі

```sql
SELECT * FROM cars WHERE status = 'available';
```

Фільтрація за статусом — лише авто, доступні для оренди. Повертає 3 рядки (Toyota Camry, BMW 3 Series, VW Golf).

### 2.3 Бюджетні автомобілі

```sql
SELECT car_id, brand, model, price_per_day
FROM cars
WHERE price_per_day <= 1500.00;
```

Вибірка авто з ціною до 1500 грн/день. Повертає Toyota Camry та VW Golf.

### 2.4 Сортування за ціною

```sql
SELECT car_id, brand, model, price_per_day
FROM cars
ORDER BY price_per_day DESC;
```

Повний список авто від найдорожчого до найдешевшого. Дозволяє швидко оцінити діапазон цін на платформі.

### 2.5 Оренди з деталями клієнта та авто

```sql
SELECT u.full_name, c.brand, c.model, r.start_date, r.end_date, r.total_price, r.status
FROM rentals r
JOIN users u ON u.user_id = r.client_id
JOIN cars c ON c.car_id = r.car_id;
```

JOIN по трьох таблицях. Повертає зрозумілий перелік оренд: хто, що і на який термін орендував.

### 2.6 Завершені оренди з платежами

```sql
SELECT r.rental_id, u.full_name, r.total_price, p.method, p.paid_at
FROM rentals r
JOIN payments p ON p.rental_id = r.rental_id
JOIN users u ON u.user_id = r.client_id
WHERE r.status = 'completed';
```

Фільтрація завершених оренд із деталями оплати. Повертає 3 записи зі способом і часом оплати.

### 2.7 Відгуки з іменами клієнтів і авто

```sql
SELECT rv.review_id, u.full_name, c.brand, c.model, rv.rating, rv.comment, rv.created_at
FROM reviews rv
JOIN rentals r ON r.rental_id = rv.rental_id
JOIN users u ON u.user_id = r.client_id
JOIN cars c ON c.car_id = r.car_id;
```

JOIN по чотирьох таблицях. Повертає читабельний список відгуків з ім'ям автора та авто.

### 2.8 Рейтинг клієнтів за кількістю оренд і сумою витрат

```sql
SELECT u.full_name, COUNT(r.rental_id) AS total_rentals, SUM(r.total_price) AS total_spent
FROM users u
JOIN rentals r ON r.client_id = u.user_id
GROUP BY u.user_id, u.full_name
ORDER BY total_spent DESC;
```

Агрегація для аналізу активності клієнтів. Корисно для програм лояльності.

### 2.9 Орендодавці з кількістю авто і середньою ціною

```sql
SELECT u.full_name, COUNT(c.car_id) AS cars_listed, AVG(c.price_per_day) AS avg_price
FROM users u
JOIN cars c ON c.owner_id = u.user_id
GROUP BY u.user_id, u.full_name;
```

Дозволяє побачити, скільки авто розмістив кожен власник і яка середня ціна його пропозицій.

### 2.10 Середній рейтинг по кожному автомобілю

```sql
SELECT c.brand, c.model, AVG(rv.rating) AS avg_rating, COUNT(rv.review_id) AS review_count
FROM cars c
JOIN rentals r ON r.car_id = c.car_id
JOIN reviews rv ON rv.rental_id = r.rental_id
GROUP BY c.car_id, c.brand, c.model
ORDER BY avg_rating DESC;
```

Рейтингова таблиця авто на основі відгуків орендарів.

---

## 3. INSERT — додавання даних

### 3.1 Новий користувач — Андрій Савченко

```sql
INSERT INTO users (full_name, phone, email, driver_license)
VALUES ('Андрій Савченко', '+380501112233', 'andriy.savchenko@gmail.com', 'ФФ678901');

SELECT * FROM users WHERE email = 'andriy.savchenko@gmail.com';
```

Додано нового користувача. `SELECT` підтвердив появу запису з `user_id = 6`.

### 3.2 Новий користувач — Олена Кравченко

```sql
INSERT INTO users (full_name, phone, email, driver_license)
VALUES ('Олена Кравченко', '+380671234000', 'olena.kravchenko@gmail.com', 'ГГ789012');

SELECT * FROM users ORDER BY created_at DESC LIMIT 3;
```

Додано другого нового користувача (`user_id = 7`). `SELECT` показав останні 3 записи за датою реєстрації.

### 3.3 Нове авто — Mercedes-Benz C-Class

```sql
INSERT INTO cars (owner_id, brand, model, year, price_per_day, status)
VALUES (2, 'Mercedes-Benz', 'C-Class', 2021, 3200.00, 'available');

SELECT * FROM cars WHERE owner_id = 2;
```

Марія Шевченко (`owner_id = 2`) виставила новий автомобіль. `SELECT` показав усі авто цього власника.

### 3.4 Нове авто — Kia Sportage

```sql
INSERT INTO cars (owner_id, brand, model, year, price_per_day, status)
VALUES (6, 'Kia', 'Sportage', 2023, 1400.00, 'available');

SELECT * FROM cars WHERE owner_id = 6;
```

Андрій Савченко розмістив своє авто одразу після реєстрації.

### 3.5 Нове авто — Honda Civic (на техобслуговуванні)

```sql
INSERT INTO cars (owner_id, brand, model, year, price_per_day, status)
VALUES (1, 'Honda', 'Civic', 2017, 800.00, 'maintenance');

SELECT car_id, brand, model, status FROM cars WHERE owner_id = 1;
```

Третє авто Олега Коваленка додане зі статусом `maintenance` — тимчасово недоступне.

### 3.6 Нова оренда — Kia Sportage, клієнт Олена

```sql
INSERT INTO rentals (car_id, client_id, start_date, end_date, total_price, status)
VALUES (6, 7, '2025-05-15', '2025-05-18', 9600.00, 'pending');

SELECT r.rental_id, u.full_name, c.brand, r.start_date, r.end_date, r.status
FROM rentals r
JOIN users u ON u.user_id = r.client_id
JOIN cars c ON c.car_id = r.car_id
WHERE r.rental_id = 6;
```

Олена Кравченко забронювала Kia Sportage на 3 дні. `SELECT` з JOIN підтвердив коректність даних.

### 3.7 Нова оренда — Mercedes-Benz, клієнт Катерина

```sql
INSERT INTO rentals (car_id, client_id, start_date, end_date, total_price, status)
VALUES (7, 4, '2025-05-20', '2025-05-23', 4200.00, 'pending');

SELECT * FROM rentals ORDER BY rental_id DESC LIMIT 3;
```

Катерина Мельник забронювала Mercedes-Benz C-Class. Перевірка: останні 3 оренди в таблиці.

### 3.8 Платіж за оренду №6

```sql
INSERT INTO payments (rental_id, amount, method, paid_at)
VALUES (6, 9600.00, 'card', '2025-05-15 12:00:00');

SELECT p.payment_id, r.rental_id, p.amount, p.method, p.paid_at
FROM payments p
JOIN rentals r ON r.rental_id = p.rental_id
WHERE p.rental_id = 6;
```

Оплата карткою за оренду Kia Sportage. `SELECT` з JOIN підтвердив суму та метод.

### 3.9 Платіж за оренду №7

```sql
INSERT INTO payments (rental_id, amount, method, paid_at)
VALUES (7, 4200.00, 'online', '2025-05-20 09:00:00');

SELECT * FROM payments ORDER BY payment_id DESC LIMIT 3;
```

Онлайн-оплата за Mercedes-Benz. Перевірка: останні 3 записи в `payments`.

### 3.10 Відгук на оренду №6

```sql
INSERT INTO reviews (rental_id, rating, comment)
VALUES (6, 5, 'Відмінний сервіс, авто в ідеальному стані!');

SELECT rv.review_id, rv.rating, rv.comment, rv.created_at
FROM reviews rv
WHERE rv.rental_id = 6;
```

Олена залишила відгук на Kia Sportage. Використано `rental_id = 6` — для нього ще не існувало відгуку, що відповідає обмеженню `UNIQUE`.

---

## 4. UPDATE — оновлення даних

### 4.1 Статус авто → available

```sql
UPDATE cars SET status = 'available' WHERE car_id = 2;

SELECT car_id, brand, model, status FROM cars WHERE car_id = 2;
```

Toyota RAV4 повернена після оренди і знову доступна.

### 4.2 Ціна VW Golf

```sql
UPDATE cars SET price_per_day = 1350.00 WHERE car_id = 4;

SELECT car_id, brand, model, price_per_day FROM cars WHERE car_id = 4;
```

Власник знизив ціну на VW Golf з 900 до 1350 грн/день (після апгрейду умов).

### 4.3 Статус авто → maintenance

```sql
UPDATE cars SET status = 'maintenance' WHERE car_id = 8;

SELECT car_id, brand, model, status FROM cars WHERE car_id = 8;
```

Honda Civic переведена на техобслуговування і тимчасово прибрана з пошуку.

### 4.4 Статус оренди → active

```sql
UPDATE rentals SET status = 'active' WHERE rental_id = 6;

SELECT rental_id, status FROM rentals WHERE rental_id = 6;
```

Оренда Kia Sportage підтверджена власником і перейшла в активний стан.

### 4.5 Статус оренди → completed

```sql
UPDATE rentals SET status = 'completed' WHERE rental_id = 4;

SELECT rental_id, client_id, car_id, status FROM rentals WHERE rental_id = 4;
```

Оренда VW Golf завершена після повернення авто.

### 4.6 Статус оренди → cancelled

```sql
UPDATE rentals SET status = 'cancelled' WHERE rental_id = 7;

SELECT rental_id, status FROM rentals WHERE rental_id = 7;
```

Катерина скасувала бронювання Mercedes-Benz до початку оренди.

### 4.7 Телефон користувача

```sql
UPDATE users SET phone = '+380501112244' WHERE user_id = 6;

SELECT user_id, full_name, phone FROM users WHERE user_id = 6;
```

Андрій Савченко змінив номер телефону в профілі.

### 4.8 Email користувача

```sql
UPDATE users SET email = 'oleg.kovalenko.new@gmail.com' WHERE user_id = 1;

SELECT user_id, full_name, email FROM users WHERE user_id = 1;
```

Олег Коваленко оновив email-адресу.

### 4.9 Масове підвищення цін на старі авто

```sql
UPDATE cars SET price_per_day = price_per_day * 1.10 WHERE year < 2019;

SELECT car_id, brand, model, year, price_per_day FROM cars WHERE year < 2019;
```

Усі авто до 2019 року отримали підвищення ціни на 10%. `SELECT` підтвердив нові значення для VW Golf (2018) та Honda Civic (2017).

### 4.10 Текст відгуку

```sql
UPDATE reviews SET comment = 'Все чудово, але є подряпина на бампері.' WHERE review_id = 2;

SELECT review_id, rating, comment FROM reviews WHERE review_id = 2;
```

Орендар уточнив коментар після додаткового огляду авто.

---

## 5. DELETE — видалення даних

### 5.1 Видалення відгуку

```sql
DELETE FROM reviews WHERE review_id = 3;

SELECT * FROM reviews;
```

Видалено відгук на BMW 3 Series. `SELECT` підтвердив, що залишилось 2 записи.

### 5.2 Видалення платежу скасованої оренди

```sql
DELETE FROM payments WHERE rental_id = 7;

SELECT * FROM payments;
```

Платіж за скасовану оренду Mercedes-Benz видалено перед очищенням самої оренди.

### 5.3 Видалення скасованих оренд

```sql
DELETE FROM rentals WHERE status = 'cancelled';

SELECT * FROM rentals;
```

Масове очищення всіх скасованих оренд. `WHERE` гарантує, що активні та завершені оренди не зачеплені.

### 5.4 Видалення авто на техобслуговуванні

```sql
DELETE FROM cars WHERE status = 'maintenance' AND car_id = 8;

SELECT car_id, brand, model, status FROM cars;
```

Honda Civic видалена з платформи. Умова по `car_id` запобігає випадковому видаленню інших авто зі статусом `maintenance`.

### 5.5 Каскадне видалення користувача

```sql
DELETE FROM reviews  WHERE rental_id = 6;
DELETE FROM payments WHERE rental_id = 6;
DELETE FROM rentals  WHERE client_id = 7;
DELETE FROM users    WHERE user_id = 7;

SELECT * FROM users;
```

Видалення Олени Кравченко вимагало попереднього очищення всіх залежних записів у правильному порядку: відгук → платіж → оренда → користувач. Порушення цього порядку призвело б до помилки зовнішнього ключа.

### 5.6 Видалення відгуків конкретного клієнта через підзапит

```sql
DELETE FROM reviews
WHERE rental_id IN (
    SELECT rental_id FROM rentals WHERE client_id = 5
);

SELECT rv.review_id, rv.rental_id, rv.rating
FROM reviews rv
JOIN rentals r ON r.rental_id = rv.rental_id
WHERE r.client_id = 5;
```

Видалено всі відгуки Дмитра Лисенка через підзапит. `SELECT` підтвердив відсутність результатів.

### 5.7 Видалення готівкових платежів за старий період

```sql
DELETE FROM payments
WHERE method = 'cash' AND paid_at < '2025-05-02 00:00:00';

SELECT * FROM payments;
```

Видалення готівкових транзакцій до 2 травня. Використано складену умову `WHERE` для точної фільтрації.

### 5.8 Видалення авто власника

```sql
DELETE FROM cars WHERE owner_id = 6;

SELECT * FROM cars WHERE owner_id = 6;
```

Андрій Савченко зняв своє авто з платформи. `SELECT` повернув порожній результат — авто видалено успішно.

---

## 6. Висновки

У ході лабораторної роботи виконано 38 SQL-запитів у PostgreSQL. Основні спостереження:

- Обмеження `UNIQUE` на `reviews.rental_id` не дозволяє додати два відгуки на одну оренду — відповідає бізнес-логіці платформи.
- Обмеження `FOREIGN KEY` вимагає каскадного порядку видалення залежних записів: спочатку дочірні таблиці, потім батьківські.
- Масові операції (`UPDATE ... WHERE year < 2019`, `DELETE ... WHERE status = 'cancelled'`) виконуються коректно за рахунок точних умов фільтрації.
- Перевірка результату через `SELECT` після кожної DML-операції є обов'язковою практикою для виявлення помилок до їх накопичення.
## 7. Демонстрація заповнення таблиць
Спочатку після 2 лаби отакий стан був
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-14" src="https://github.com/user-attachments/assets/617ff9c6-3f06-4f51-9ec0-363fa5263c98" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-24" src="https://github.com/user-attachments/assets/faa2342d-3ef7-4a42-8075-a4626e420699" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-35" src="https://github.com/user-attachments/assets/b9832ea4-092b-434a-9a56-2854ead95d1c" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-47" src="https://github.com/user-attachments/assets/13c9ad41-5bdc-4429-980a-a52d520e8510" />
<img width="956" height="171" alt="Screenshot From 2026-05-09 17-28-59" src="https://github.com/user-attachments/assets/47c21bad-8b2d-4b72-80f9-e7835ac3a561" />
Тепер після цієї лаби так 
<img width="960" height="202" alt="Screenshot From 2026-05-10 00-07-26" src="https://github.com/user-attachments/assets/580905f8-5988-4235-be3f-63b68331994d" />
<img width="960" height="202" alt="Screenshot From 2026-05-10 00-07-37" src="https://github.com/user-attachments/assets/2e4003fe-5c3f-4947-9905-827efe914df1" />
<img width="960" height="202" alt="Screenshot From 2026-05-10 00-07-57" src="https://github.com/user-attachments/assets/4ea9b753-b0c3-4d1f-8244-1ce055254fad" />
<img width="960" height="202" alt="Screenshot From 2026-05-10 00-08-11" src="https://github.com/user-attachments/assets/3ad389d9-e274-47b3-9516-5f7fae5777a7" />
<img width="960" height="202" alt="Screenshot From 2026-05-10 00-08-33" src="https://github.com/user-attachments/assets/d4d77f63-0ee3-495d-9cd3-54607884a5c0" />
Після цієї лаби візьму всі insert з другої і третьої лаби, а update та delete виконувати не буду, щоб зробити заповнені таблички







