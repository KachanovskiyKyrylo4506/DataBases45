-- SELECT

SELECT * FROM users;

SELECT * FROM cars WHERE status = 'available';

SELECT car_id, brand, model, price_per_day
FROM cars
WHERE price_per_day <= 1500.00;

SELECT car_id, brand, model, price_per_day
FROM cars
ORDER BY price_per_day DESC;

SELECT u.full_name, c.brand, c.model, r.start_date, r.end_date, r.total_price, r.status
FROM rentals r
JOIN users u ON u.user_id = r.client_id
JOIN cars c ON c.car_id = r.car_id;

SELECT r.rental_id, u.full_name, r.total_price, p.method, p.paid_at
FROM rentals r
JOIN payments p ON p.rental_id = r.rental_id
JOIN users u ON u.user_id = r.client_id
WHERE r.status = 'completed';

SELECT rv.review_id, u.full_name, c.brand, c.model, rv.rating, rv.comment, rv.created_at
FROM reviews rv
JOIN rentals r ON r.rental_id = rv.rental_id
JOIN users u ON u.user_id = r.client_id
JOIN cars c ON c.car_id = r.car_id;

SELECT u.full_name, COUNT(r.rental_id) AS total_rentals, SUM(r.total_price) AS total_spent
FROM users u
JOIN rentals r ON r.client_id = u.user_id
GROUP BY u.user_id, u.full_name
ORDER BY total_spent DESC;

SELECT u.full_name, COUNT(c.car_id) AS cars_listed, AVG(c.price_per_day) AS avg_price
FROM users u
JOIN cars c ON c.owner_id = u.user_id
GROUP BY u.user_id, u.full_name;

SELECT c.brand, c.model, AVG(rv.rating) AS avg_rating, COUNT(rv.review_id) AS review_count
FROM cars c
JOIN rentals r ON r.car_id = c.car_id
JOIN reviews rv ON rv.rental_id = r.rental_id
GROUP BY c.car_id, c.brand, c.model
ORDER BY avg_rating DESC;

-- INSERT

INSERT INTO users (full_name, phone, email, driver_license)
VALUES ('Андрій Савченко', '+380501112233', 'andriy.savchenko@gmail.com', 'ФФ678901');

SELECT * FROM users WHERE email = 'andriy.savchenko@gmail.com';

INSERT INTO users (full_name, phone, email, driver_license)
VALUES ('Олена Кравченко', '+380671234000', 'olena.kravchenko@gmail.com', 'ГГ789012');

SELECT * FROM users ORDER BY created_at DESC LIMIT 3;

INSERT INTO cars (owner_id, brand, model, year, price_per_day, status)
VALUES (2, 'Mercedes-Benz', 'C-Class', 2021, 3200.00, 'available');

SELECT * FROM cars WHERE owner_id = 2;

INSERT INTO cars (owner_id, brand, model, year, price_per_day, status)
VALUES (6, 'Kia', 'Sportage', 2023, 1400.00, 'available');

SELECT * FROM cars WHERE owner_id = 6;

INSERT INTO cars (owner_id, brand, model, year, price_per_day, status)
VALUES (1, 'Honda', 'Civic', 2017, 800.00, 'maintenance');

SELECT car_id, brand, model, status FROM cars WHERE owner_id = 1;

INSERT INTO rentals (car_id, client_id, start_date, end_date, total_price, status)
VALUES (6, 7, '2025-05-15', '2025-05-18', 9600.00, 'pending');

SELECT r.rental_id, u.full_name, c.brand, r.start_date, r.end_date, r.status
FROM rentals r
JOIN users u ON u.user_id = r.client_id
JOIN cars c ON c.car_id = r.car_id
WHERE r.rental_id = 6;

INSERT INTO rentals (car_id, client_id, start_date, end_date, total_price, status)
VALUES (7, 4, '2025-05-20', '2025-05-23', 4200.00, 'pending');

SELECT * FROM rentals ORDER BY rental_id DESC LIMIT 3;

INSERT INTO payments (rental_id, amount, method, paid_at)
VALUES (6, 9600.00, 'card', '2025-05-15 12:00:00');

SELECT p.payment_id, r.rental_id, p.amount, p.method, p.paid_at
FROM payments p
JOIN rentals r ON r.rental_id = p.rental_id
WHERE p.rental_id = 6;

INSERT INTO payments (rental_id, amount, method, paid_at)
VALUES (7, 4200.00, 'online', '2025-05-20 09:00:00');

SELECT * FROM payments ORDER BY payment_id DESC LIMIT 3;

INSERT INTO reviews (rental_id, rating, comment)
VALUES (6, 5, 'Відмінний сервіс, авто в ідеальному стані!');

SELECT rv.review_id, rv.rating, rv.comment, rv.created_at
FROM reviews rv
WHERE rv.rental_id = 6;

-- UPDATE

UPDATE cars
SET status = 'available'
WHERE car_id = 2;

SELECT car_id, brand, model, status FROM cars WHERE car_id = 2;

UPDATE cars
SET price_per_day = 1350.00
WHERE car_id = 4;

SELECT car_id, brand, model, price_per_day FROM cars WHERE car_id = 4;

UPDATE cars
SET status = 'maintenance'
WHERE car_id = 8;

SELECT car_id, brand, model, status FROM cars WHERE car_id = 8;

UPDATE rentals
SET status = 'active'
WHERE rental_id = 6;

SELECT rental_id, status FROM rentals WHERE rental_id = 6;

UPDATE rentals
SET status = 'completed'
WHERE rental_id = 4;

SELECT rental_id, client_id, car_id, status FROM rentals WHERE rental_id = 4;

UPDATE rentals
SET status = 'cancelled'
WHERE rental_id = 7;

SELECT rental_id, status FROM rentals WHERE rental_id = 7;

UPDATE users
SET phone = '+380501112244'
WHERE user_id = 6;

SELECT user_id, full_name, phone FROM users WHERE user_id = 6;

UPDATE users
SET email = 'oleg.kovalenko.new@gmail.com'
WHERE user_id = 1;

SELECT user_id, full_name, email FROM users WHERE user_id = 1;

UPDATE cars
SET price_per_day = price_per_day * 1.10
WHERE year < 2019;

SELECT car_id, brand, model, year, price_per_day FROM cars WHERE year < 2019;

UPDATE reviews
SET comment = 'Все чудово, але є подряпина на бампері.'
WHERE review_id = 2;

SELECT review_id, rating, comment FROM reviews WHERE review_id = 2;

-- DELETE

DELETE FROM reviews
WHERE review_id = 3;

SELECT * FROM reviews;

DELETE FROM payments
WHERE rental_id = 7;

SELECT * FROM payments;

DELETE FROM rentals
WHERE status = 'cancelled';

SELECT * FROM rentals;

DELETE FROM cars
WHERE status = 'maintenance' AND car_id = 8;

SELECT car_id, brand, model, status FROM cars;

DELETE FROM reviews
WHERE rental_id = 6;

DELETE FROM payments
WHERE rental_id = 6;

DELETE FROM rentals
WHERE client_id = 7;

DELETE FROM users
WHERE user_id = 7;

SELECT * FROM users;

DELETE FROM reviews
WHERE rental_id IN (
    SELECT rental_id FROM rentals WHERE client_id = 5
);

SELECT rv.review_id, rv.rental_id, rv.rating
FROM reviews rv
JOIN rentals r ON r.rental_id = rv.rental_id
WHERE r.client_id = 5;

DELETE FROM payments
WHERE method = 'cash' AND paid_at < '2025-05-02 00:00:00';

SELECT * FROM payments;

DELETE FROM cars
WHERE owner_id = 6;

SELECT * FROM cars WHERE owner_id = 6;
