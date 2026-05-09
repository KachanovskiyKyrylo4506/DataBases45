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
    rental_id  INTEGER  NOT NULL UNIQUE REFERENCES rentals(rental_id),
    rating     SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
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
