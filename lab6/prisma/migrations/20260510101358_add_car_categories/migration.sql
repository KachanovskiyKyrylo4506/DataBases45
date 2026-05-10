-- AlterTable
ALTER TABLE "cars" ADD COLUMN     "category_id" INTEGER;

-- CreateTable
CREATE TABLE "car_categories" (
    "category_id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,

    CONSTRAINT "car_categories_pkey" PRIMARY KEY ("category_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "car_categories_name_key" ON "car_categories"("name");

-- AddForeignKey
ALTER TABLE "cars" ADD CONSTRAINT "cars_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "car_categories"("category_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
