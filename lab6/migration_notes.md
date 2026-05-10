# Лабораторна робота 6: Міграції схем за допомогою Prisma ORM

**Система:** Платформа прокату автомобілів  

---

## 1. Налаштування середовища

Проект розгорнуто з використанням Docker Compose. PostgreSQL запущено в контейнері `postgres_db` (образ `postgres:16-alpine`), pgAdmin — у контейнері `pgadmin4_ui`.

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres_db
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: mydatabase
    ports:
      - "5432:5432"
```

Prisma ініціалізовано командами:

```bash
npm init -y
npm install prisma --save-dev
npx prisma init --datasource-provider postgresql
```

Конфігурацію Prisma винесено у `prisma.config.ts`:

```typescript
import "dotenv/config";
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: "npx tsx prisma/seed.ts",
  },
  datasource: {
    url: env("DATABASE_URL"),
  },
});
```

---

## 2. Аналіз існуючої схеми (`db pull`)

Після налаштування `DATABASE_URL` у файлі `.env` виконано команду:

```bash
npx prisma db pull
```

Prisma успішно проаналізувала базу даних і записала 5 моделей у `prisma/schema.prisma`. У терміналі виведено попередження про `CHECK` constraints — Prisma не підтримує їх на рівні клієнта, але вони залишаються активними на рівні PostgreSQL.

**Стан схеми після `db pull` (вихідний):**

```prisma
model cars {
  car_id        Int       @id @default(autoincrement())
  owner_id      Int
  brand         String    @db.VarChar(50)
  model         String    @db.VarChar(50)
  year          Int       @db.SmallInt
  price_per_day Decimal   @db.Decimal(8, 2)
  status        String    @default("available") @db.VarChar(20)
  users         users     @relation(fields: [owner_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  rentals       rentals[]
}

model users {
  user_id        Int       @id @default(autoincrement())
  full_name      String    @db.VarChar(100)
  phone          String    @unique @db.VarChar(20)
  email          String    @unique @db.VarChar(150)
  driver_license String    @unique @db.VarChar(20)
  created_at     DateTime  @default(now()) @db.Timestamp(6)
  cars           cars[]
  rentals        rentals[]
}

// + моделі payments, rentals, reviews
```

---

## 3. Міграції

### 3.1 Міграція 0 — Початковий стан (`create_all_tables`)

**Назва:** `20260510101033_create_all_tables`  
**Команда:**
```bash
npx prisma migrate dev --name create_all_tables
```

**Що зроблено:** Prisma згенерувала початковий SQL на основі підтягнутої схеми — створила всі 5 таблиць з первинними ключами, зовнішніми ключами та унікальними індексами.

**Згенерований SQL:**

```sql
CREATE TABLE "cars" (
    "car_id"        SERIAL        NOT NULL,
    "owner_id"      INTEGER       NOT NULL,
    "brand"         VARCHAR(50)   NOT NULL,
    "model"         VARCHAR(50)   NOT NULL,
    "year"          SMALLINT      NOT NULL,
    "price_per_day" DECIMAL(8,2)  NOT NULL,
    "status"        VARCHAR(20)   NOT NULL DEFAULT 'available',
    CONSTRAINT "cars_pkey" PRIMARY KEY ("car_id")
);

CREATE TABLE "payments" (
    "payment_id" SERIAL        NOT NULL,
    "rental_id"  INTEGER       NOT NULL,
    "amount"     DECIMAL(10,2) NOT NULL,
    "method"     VARCHAR(20)   NOT NULL,
    "paid_at"    TIMESTAMP(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "payments_pkey" PRIMARY KEY ("payment_id")
);

CREATE TABLE "rentals" (
    "rental_id"   SERIAL        NOT NULL,
    "car_id"      INTEGER       NOT NULL,
    "client_id"   INTEGER       NOT NULL,
    "start_date"  DATE          NOT NULL,
    "end_date"    DATE          NOT NULL,
    "total_price" DECIMAL(10,2) NOT NULL,
    "status"      VARCHAR(20)   NOT NULL DEFAULT 'pending',
    CONSTRAINT "rentals_pkey" PRIMARY KEY ("rental_id")
);

CREATE TABLE "reviews" (
    "review_id"  SERIAL    NOT NULL,
    "rental_id"  INTEGER   NOT NULL,
    "rating"     SMALLINT  NOT NULL,
    "comment"    TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "reviews_pkey" PRIMARY KEY ("review_id")
);

CREATE TABLE "users" (
    "user_id"        SERIAL       NOT NULL,
    "full_name"      VARCHAR(100) NOT NULL,
    "phone"          VARCHAR(20)  NOT NULL,
    "email"          VARCHAR(150) NOT NULL,
    "driver_license" VARCHAR(20)  NOT NULL,
    "created_at"     TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "users_pkey" PRIMARY KEY ("user_id")
);

CREATE UNIQUE INDEX "payments_rental_id_key"      ON "payments"("rental_id");
CREATE UNIQUE INDEX "reviews_rental_id_key"        ON "reviews"("rental_id");
CREATE UNIQUE INDEX "users_phone_key"              ON "users"("phone");
CREATE UNIQUE INDEX "users_email_key"              ON "users"("email");
CREATE UNIQUE INDEX "users_driver_license_key"     ON "users"("driver_license");

ALTER TABLE "cars"     ADD CONSTRAINT "cars_owner_id_fkey"      FOREIGN KEY ("owner_id")  REFERENCES "users"("user_id")   ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "payments" ADD CONSTRAINT "payments_rental_id_fkey" FOREIGN KEY ("rental_id") REFERENCES "rentals"("rental_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "rentals"  ADD CONSTRAINT "rentals_car_id_fkey"     FOREIGN KEY ("car_id")    REFERENCES "cars"("car_id")     ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "rentals"  ADD CONSTRAINT "rentals_client_id_fkey"  FOREIGN KEY ("client_id") REFERENCES "users"("user_id")   ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "reviews"  ADD CONSTRAINT "reviews_rental_id_fkey"  FOREIGN KEY ("rental_id") REFERENCES "rentals"("rental_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
```

---

### 3.2 Міграція 1 — Додавання поля `description` (`add_description_to_cars`)

**Назва:** `20260510101202_add_description_to_cars`  
**Команда:**
```bash
npx prisma migrate dev --name add-description-to-cars
```

**Зміна в `schema.prisma`:**

```prisma
// ДО:
model cars {
  car_id        Int     @id @default(autoincrement())
  owner_id      Int
  brand         String  @db.VarChar(50)
  model         String  @db.VarChar(50)
  year          Int     @db.SmallInt
  price_per_day Decimal @db.Decimal(8, 2)
  status        String  @default("available") @db.VarChar(20)
  ...
}

// ПІСЛЯ:
model cars {
  car_id        Int     @id @default(autoincrement())
  owner_id      Int
  brand         String  @db.VarChar(50)
  model         String  @db.VarChar(50)
  year          Int     @db.SmallInt
  price_per_day Decimal @db.Decimal(8, 2)
  status        String  @default("available") @db.VarChar(20)
  description   String?   // ← додано
  ...
}
```

**Згенерований SQL:**

```sql
ALTER TABLE "cars" ADD COLUMN "description" TEXT;
```

**Мета:** Власник авто може додати текстовий опис до оголошення — особливості авто, умови оренди тощо. Поле nullable (`String?`), щоб не ламати існуючі записи.

---

### 3.3 Міграція 2 — Нова таблиця `car_categories` (`add_car_categories`)

**Назва:** `20260510101358_add_car_categories`  
**Команда:**
```bash
npx prisma migrate dev --name add-car-categories
```

**Зміна в `schema.prisma`:**

```prisma
// Нова модель:
model car_categories {
  category_id Int    @id @default(autoincrement())
  name        String @unique @db.VarChar(50)
  cars        cars[]
}

// Зміни в cars — додано поля:
model cars {
  ...
  category_id    Int?
  description    String?
  car_categories car_categories? @relation(fields: [category_id], references: [category_id], onDelete: NoAction, onUpdate: NoAction)
  ...
}
```

**Згенерований SQL:**

```sql
ALTER TABLE "cars" ADD COLUMN "category_id" INTEGER;

CREATE TABLE "car_categories" (
    "category_id" SERIAL      NOT NULL,
    "name"        VARCHAR(50) NOT NULL,
    CONSTRAINT "car_categories_pkey" PRIMARY KEY ("category_id")
);

CREATE UNIQUE INDEX "car_categories_name_key" ON "car_categories"("name");

ALTER TABLE "cars" ADD CONSTRAINT "cars_category_id_fkey"
    FOREIGN KEY ("category_id") REFERENCES "car_categories"("category_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;
```

**Мета:** Виділено категорії авто в окрему довідникову таблицю (Седан, Позашляховик, Мінівен тощо). Зв'язок N:1 — багато авто можуть належати до однієї категорії. `category_id` nullable — існуючі авто без категорії не ламаються.

---

### 3.4 Міграція 3 — Видалення поля `description` (`drop_description_from_cars`)

**Назва:** `20260510101512_drop_description_from_cars`  
**Команда:**
```bash
npx prisma migrate dev --name drop-description-from-cars
```

**Зміна в `schema.prisma`:**

```prisma
// ДО:
model cars {
  ...
  description    String?   // присутнє
  car_categories car_categories? @relation(...)
  ...
}

// ПІСЛЯ:
model cars {
  ...
  // description видалено
  car_categories car_categories? @relation(...)
  ...
}
```

**Згенерований SQL:**

```sql
ALTER TABLE "cars" DROP COLUMN "description";
```

**Мета:** Після аналізу вирішено, що детальний опис авто краще реалізувати через окрему таблицю `car_details` у майбутньому, або об'єднати з полем категорії. Поточне текстове поле `description` без структури не відповідає вимогам масштабування — видалено.

---

## 4. Фінальний стан схеми

```prisma
generator client {
  provider = "prisma-client"
  output   = "./generated"
}

datasource db {
  provider = "postgresql"
}

model cars {
  car_id         Int             @id @default(autoincrement())
  owner_id       Int
  category_id    Int?
  brand          String          @db.VarChar(50)
  model          String          @db.VarChar(50)
  year           Int             @db.SmallInt
  price_per_day  Decimal         @db.Decimal(8, 2)
  status         String          @default("available") @db.VarChar(20)
  users          users           @relation(fields: [owner_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  car_categories car_categories? @relation(fields: [category_id], references: [category_id], onDelete: NoAction, onUpdate: NoAction)
  rentals        rentals[]
}

model payments {
  payment_id Int      @id @default(autoincrement())
  rental_id  Int      @unique
  amount     Decimal  @db.Decimal(10, 2)
  method     String   @db.VarChar(20)
  paid_at    DateTime @default(now()) @db.Timestamp(6)
  rentals    rentals  @relation(fields: [rental_id], references: [rental_id], onDelete: NoAction, onUpdate: NoAction)
}

model rentals {
  rental_id   Int       @id @default(autoincrement())
  car_id      Int
  client_id   Int
  start_date  DateTime  @db.Date
  end_date    DateTime  @db.Date
  total_price Decimal   @db.Decimal(10, 2)
  status      String    @default("pending") @db.VarChar(20)
  payments    payments?
  cars        cars      @relation(fields: [car_id], references: [car_id], onDelete: NoAction, onUpdate: NoAction)
  users       users     @relation(fields: [client_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  reviews     reviews?
}

model reviews {
  review_id  Int      @id @default(autoincrement())
  rental_id  Int      @unique
  rating     Int      @db.SmallInt
  comment    String?
  created_at DateTime @default(now()) @db.Timestamp(6)
  rentals    rentals  @relation(fields: [rental_id], references: [rental_id], onDelete: NoAction, onUpdate: NoAction)
}

model users {
  user_id        Int       @id @default(autoincrement())
  full_name      String    @db.VarChar(100)
  phone          String    @unique @db.VarChar(20)
  email          String    @unique @db.VarChar(150)
  driver_license String    @unique @db.VarChar(20)
  created_at     DateTime  @default(now()) @db.Timestamp(6)
  cars           cars[]
  rentals        rentals[]
}

model car_categories {
  category_id Int    @id @default(autoincrement())
  name        String @unique @db.VarChar(50)
  cars        cars[]
}
```

**Зміни відносно початкової схеми:**
- додано таблицю `car_categories`
- у `cars` додано поле `category_id` (FK → `car_categories`)
- поле `description` додано і видалено в рамках міграцій 1 та 3

---

## 5. Seed-скрипт

Для заповнення бази тестовими даними написано `seed.ts` з використанням Prisma Client:

```bash
npx tsx prisma/seed.ts
```

Скрипт виконує очищення всіх таблиць у правильному порядку (з урахуванням FK) і вставляє:
- 5 користувачів
- 5 автомобілів
- 5 оренд
- 5 платежів
- 3 відгуки

---

## 6. Перевірка через Prisma Studio

```bash
npx prisma studio
```

Prisma Studio доступне за адресою `http://localhost:5555`.

**Скріншот — список таблиць:**

<img width="195" height="499" alt="image" src="https://github.com/user-attachments/assets/0980b6b0-02bf-4227-9a35-4e2fd5c634b1" />

**Скріншот — таблиця `users`:**

<img width="2031" height="298" alt="image" src="https://github.com/user-attachments/assets/fedc26ad-fdad-46bc-9ce2-80693adbe504" />

**Скріншот — таблиця `cars`:**

<img width="2031" height="298" alt="image" src="https://github.com/user-attachments/assets/c22d44c0-ed3f-4536-8262-00e48d10738b" />

**Скріншот — таблиця `payments`:**

<img width="2031" height="298" alt="image" src="https://github.com/user-attachments/assets/c6714687-7ac8-40de-b1f2-175cd915fd4d" />

**Скріншот — таблиця `rentals`:**

<img width="2031" height="298" alt="image" src="https://github.com/user-attachments/assets/89e317f6-35ec-4017-9d2a-943c55e087dd" />

**Скріншот — таблиця `reviews`:**

<img width="2031" height="298" alt="image" src="https://github.com/user-attachments/assets/1cc38a5b-d9c9-4176-a8e6-c193170f1cf6" />

**Скріншот — таблиця `car_categories`:**

<img width="2031" height="298" alt="image" src="https://github.com/user-attachments/assets/63cecd07-022b-4593-a069-b597cd6f5595" />

---

## 7. Структура папки міграцій

```
prisma/
├── migrations/
│   ├── 20260510101033_create_all_tables/
│   │   └── migration.sql
│   ├── 20260510101202_add_description_to_cars/
│   │   └── migration.sql
│   ├── 20260510101358_add_car_categories/
│   │   └── migration.sql
│   └── 20260510101512_drop_description_from_cars/
│       └── migration.sql
├── generated/
├── migration_lock.toml
├── schema.prisma
└── seed.ts
```

---

## 8. Висновки

У ході лабораторної роботи освоєно робочий процес міграцій з Prisma ORM:

- `prisma db pull` дозволяє підтягнути існуючу PostgreSQL-схему в Prisma без переписування з нуля.
- Кожна зміна схеми (`schema.prisma`) → `prisma migrate dev` генерує ізольований SQL-файл міграції з чіткою назвою та зберігає повну історію змін у папці `migrations/`.
- Міграції є атомарними: кожна відповідає за одну логічну зміну, що спрощує відлагодження і відкат.
- Prisma Client і Studio забезпечують зручну перевірку даних без написання SQL вручну.
- `CHECK` constraints, визначені в PostgreSQL, продовжують працювати на рівні БД навіть якщо Prisma їх не відображає в схемі.
