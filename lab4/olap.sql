-- АГРЕГАЦІЯ

SELECT COUNT(*) AS total_users FROM users;

SELECT COUNT(*) AS total_cars,
       COUNT(*) FILTER (WHERE status = 'available')   AS available,
       COUNT(*) FILTER (WHERE status = 'rented')      AS rented,
       COUNT(*) FILTER (WHERE status = 'maintenance') AS maintenance
FROM cars;

SELECT COUNT(*)  AS total_rentals,
       SUM(total_price)  AS total_revenue,
       AVG(total_price)  AS avg_rental_price,
       MIN(total_price)  AS min_rental_price,
       MAX(total_price)  AS max_rental_price
FROM rentals;

SELECT method,
       COUNT(*)   AS payment_count,
       SUM(amount) AS total_amount
FROM payments
GROUP BY method
ORDER BY total_amount DESC;

SELECT brand,
       COUNT(*)             AS car_count,
       AVG(price_per_day)   AS avg_price,
       MIN(price_per_day)   AS min_price,
       MAX(price_per_day)   AS max_price
FROM cars
GROUP BY brand
ORDER BY avg_price DESC;

SELECT EXTRACT(YEAR FROM start_date)  AS year,
       EXTRACT(MONTH FROM start_date) AS month,
       COUNT(*)                       AS rentals_count,
       SUM(total_price)               AS monthly_revenue
FROM rentals
GROUP BY year, month
ORDER BY year, month;

SELECT status,
       COUNT(*)         AS count,
       SUM(total_price) AS total_price
FROM rentals
GROUP BY status
ORDER BY count DESC;

SELECT u.full_name,
       COUNT(r.rental_id)  AS total_rentals,
       SUM(r.total_price)  AS total_spent,
       AVG(r.total_price)  AS avg_rental_price
FROM users u
JOIN rentals r ON r.client_id = u.user_id
GROUP BY u.user_id, u.full_name
ORDER BY total_spent DESC;

-- HAVING

SELECT u.full_name,
       COUNT(r.rental_id) AS total_rentals
FROM users u
JOIN rentals r ON r.client_id = u.user_id
GROUP BY u.user_id, u.full_name
HAVING COUNT(r.rental_id) > 1;

SELECT u.full_name,
       COUNT(c.car_id)          AS cars_listed,
       AVG(c.price_per_day)     AS avg_price
FROM users u
JOIN cars c ON c.owner_id = u.user_id
GROUP BY u.user_id, u.full_name
HAVING AVG(c.price_per_day) > 1500;

SELECT c.brand, c.model,
       AVG(rv.rating)       AS avg_rating,
       COUNT(rv.review_id)  AS review_count
FROM cars c
JOIN rentals r  ON r.car_id     = c.car_id
JOIN reviews rv ON rv.rental_id = r.rental_id
GROUP BY c.car_id, c.brand, c.model
HAVING AVG(rv.rating) >= 4;

-- JOIN

SELECT r.rental_id,
       u.full_name      AS client,
       c.brand,
       c.model,
       r.start_date,
       r.end_date,
       r.total_price,
       r.status
FROM rentals r
INNER JOIN users u ON u.user_id = r.client_id
INNER JOIN cars c  ON c.car_id  = r.car_id
ORDER BY r.rental_id;

SELECT c.car_id, c.brand, c.model, c.price_per_day,
       COUNT(r.rental_id) AS times_rented
FROM cars c
LEFT JOIN rentals r ON r.car_id = c.car_id
GROUP BY c.car_id, c.brand, c.model, c.price_per_day
ORDER BY times_rented DESC;

SELECT u.full_name,
       rv.rating,
       rv.comment,
       rv.created_at
FROM users u
LEFT JOIN rentals r  ON r.client_id  = u.user_id
LEFT JOIN reviews rv ON rv.rental_id = r.rental_id
ORDER BY u.user_id;

SELECT p.payment_id,
       p.amount,
       p.method,
       r.status   AS rental_status,
       r.start_date,
       r.end_date
FROM rentals r
RIGHT JOIN payments p ON p.rental_id = r.rental_id
ORDER BY p.payment_id;

SELECT r.rental_id,
       r.status      AS rental_status,
       r.total_price,
       rv.rating,
       rv.comment
FROM rentals r
FULL JOIN reviews rv ON rv.rental_id = r.rental_id
ORDER BY r.rental_id;

-- ПІДЗАПИТИ

SELECT rental_id, client_id, car_id, total_price, status
FROM rentals
WHERE total_price > (
    SELECT AVG(total_price) FROM rentals
)
ORDER BY total_price DESC;

SELECT car_id, brand, model, price_per_day, status
FROM cars
WHERE car_id NOT IN (
    SELECT DISTINCT car_id FROM rentals
);

SELECT user_id, full_name, email
FROM users
WHERE user_id IN (
    SELECT r.client_id
    FROM rentals r
    JOIN reviews rv ON rv.rental_id = r.rental_id
);

SELECT c.car_id,
       c.brand,
       c.model,
       c.price_per_day,
       (SELECT COUNT(*) FROM rentals r WHERE r.car_id = c.car_id) AS total_rentals
FROM cars c
ORDER BY total_rentals DESC;

SELECT owner.full_name,
       SUM(r.total_price) AS total_revenue
FROM users owner
JOIN cars c    ON c.owner_id   = owner.user_id
JOIN rentals r ON r.car_id     = c.car_id
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
