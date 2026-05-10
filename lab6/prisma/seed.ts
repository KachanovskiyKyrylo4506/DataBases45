import 'dotenv/config';
import { PrismaClient } from "./generated/client";
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('⏳ Очищення старих даних...');
  
  await prisma.reviews.deleteMany();
  await prisma.payments.deleteMany();
  await prisma.rentals.deleteMany();
  await prisma.cars.deleteMany();
  await prisma.users.deleteMany();
  await prisma.car_categories.deleteMany();

  console.log('✅ Очищено. Починаємо запис нових даних...');

  await prisma.users.createMany({
    data: [
      { user_id: 1, full_name: 'Олег Коваленко', phone: '+380501234567', email: 'oleg.kovalenko@gmail.com', driver_license: 'АА123456' },
      { user_id: 2, full_name: 'Марія Шевченко', phone: '+380672345678', email: 'maria.shevchenko@gmail.com', driver_license: 'ВВ234567' },
      { user_id: 3, full_name: 'Іван Бондаренко', phone: '+380933456789', email: 'ivan.bondarenko@gmail.com', driver_license: 'СС345678' },
      { user_id: 4, full_name: 'Катерина Мельник', phone: '+380504567890', email: 'kate.melnyk@gmail.com', driver_license: 'ДД456789' },
      { user_id: 5, full_name: 'Дмитро Лисенко', phone: '+380675678901', email: 'dmytro.lysenko@gmail.com', driver_license: 'ЕЕ567890' },
    ],
  });

  await prisma.car_categories.createMany({
    data: [
      { category_id: 1, name: 'Седан' },
      { category_id: 2, name: 'Позашляховик' },
      { category_id: 3, name: 'Хетчбек' },
    ],
  });

  await prisma.cars.createMany({
    data: [
      { car_id: 1, owner_id: 1, category_id: 1, brand: 'Toyota', model: 'Camry', year: 2020, price_per_day: 1200.00, status: 'available' },
      { car_id: 2, owner_id: 1, category_id: 2, brand: 'Toyota', model: 'RAV4', year: 2021, price_per_day: 1800.00, status: 'rented' },
      { car_id: 3, owner_id: 2, category_id: 1, brand: 'BMW', model: '3 Series', year: 2019, price_per_day: 2500.00, status: 'available' },
      { car_id: 4, owner_id: 3, category_id: 3, brand: 'Volkswagen', model: 'Golf', year: 2018, price_per_day: 900.00, status: 'available' },
      { car_id: 5, owner_id: 3, category_id: 2, brand: 'Hyundai', model: 'Tucson', year: 2022, price_per_day: 1600.00, status: 'maintenance' },
    ],
  });

  await prisma.rentals.createMany({
    data: [
      { rental_id: 1, car_id: 1, client_id: 4, start_date: new Date('2025-04-01'), end_date: new Date('2025-04-05'), total_price: 4800.00, status: 'completed' },
      { rental_id: 2, car_id: 2, client_id: 5, start_date: new Date('2025-04-10'), end_date: new Date('2025-04-15'), total_price: 9000.00, status: 'completed' },
      { rental_id: 3, car_id: 3, client_id: 4, start_date: new Date('2025-04-20'), end_date: new Date('2025-04-22'), total_price: 5000.00, status: 'completed' },
      { rental_id: 4, car_id: 4, client_id: 5, start_date: new Date('2025-05-01'), end_date: new Date('2025-05-03'), total_price: 1800.00, status: 'active' },
      { rental_id: 5, car_id: 1, client_id: 5, start_date: new Date('2025-05-10'), end_date: new Date('2025-05-12'), total_price: 2400.00, status: 'pending' },
    ],
  });

  await prisma.payments.createMany({
    data: [
      { payment_id: 1, rental_id: 1, amount: 4800.00, method: 'card', paid_at: new Date('2025-04-01T10:00:00Z') },
      { payment_id: 2, rental_id: 2, amount: 9000.00, method: 'online', paid_at: new Date('2025-04-10T09:30:00Z') },
      { payment_id: 3, rental_id: 3, amount: 5000.00, method: 'card', paid_at: new Date('2025-04-20T14:15:00Z') },
      { payment_id: 4, rental_id: 4, amount: 1800.00, method: 'cash', paid_at: new Date('2025-05-01T11:00:00Z') },
      { payment_id: 5, rental_id: 5, amount: 2400.00, method: 'online', paid_at: new Date('2025-05-09T16:45:00Z') },
    ],
  });

  await prisma.reviews.createMany({
    data: [
      { review_id: 1, rental_id: 1, rating: 5, comment: 'Чудовий автомобіль, все як описано. Рекомендую!' },
      { review_id: 2, rental_id: 2, rating: 4, comment: 'Гарне авто, але варто помити перед видачею.' },
      { review_id: 3, rental_id: 3, rating: 5, comment: 'BMW справив враження, беру ще раз.' },
    ],
  });

  console.log('🚀 Базу успішно заповнено!');
}

main()
  .catch((e) => {
    console.error('Помилка під час сідінгу:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
