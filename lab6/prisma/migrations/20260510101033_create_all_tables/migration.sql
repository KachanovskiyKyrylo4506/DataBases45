-- CreateTable
CREATE TABLE "cars" (
    "car_id" SERIAL NOT NULL,
    "owner_id" INTEGER NOT NULL,
    "brand" VARCHAR(50) NOT NULL,
    "model" VARCHAR(50) NOT NULL,
    "year" SMALLINT NOT NULL,
    "price_per_day" DECIMAL(8,2) NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'available',

    CONSTRAINT "cars_pkey" PRIMARY KEY ("car_id")
);

-- CreateTable
CREATE TABLE "payments" (
    "payment_id" SERIAL NOT NULL,
    "rental_id" INTEGER NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "method" VARCHAR(20) NOT NULL,
    "paid_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("payment_id")
);

-- CreateTable
CREATE TABLE "rentals" (
    "rental_id" SERIAL NOT NULL,
    "car_id" INTEGER NOT NULL,
    "client_id" INTEGER NOT NULL,
    "start_date" DATE NOT NULL,
    "end_date" DATE NOT NULL,
    "total_price" DECIMAL(10,2) NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'pending',

    CONSTRAINT "rentals_pkey" PRIMARY KEY ("rental_id")
);

-- CreateTable
CREATE TABLE "reviews" (
    "review_id" SERIAL NOT NULL,
    "rental_id" INTEGER NOT NULL,
    "rating" SMALLINT NOT NULL,
    "comment" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reviews_pkey" PRIMARY KEY ("review_id")
);

-- CreateTable
CREATE TABLE "users" (
    "user_id" SERIAL NOT NULL,
    "full_name" VARCHAR(100) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "email" VARCHAR(150) NOT NULL,
    "driver_license" VARCHAR(20) NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("user_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "payments_rental_id_key" ON "payments"("rental_id");

-- CreateIndex
CREATE UNIQUE INDEX "reviews_rental_id_key" ON "reviews"("rental_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_driver_license_key" ON "users"("driver_license");

-- AddForeignKey
ALTER TABLE "cars" ADD CONSTRAINT "cars_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_rental_id_fkey" FOREIGN KEY ("rental_id") REFERENCES "rentals"("rental_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_car_id_fkey" FOREIGN KEY ("car_id") REFERENCES "cars"("car_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_rental_id_fkey" FOREIGN KEY ("rental_id") REFERENCES "rentals"("rental_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
