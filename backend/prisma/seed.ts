import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  // Create users
  const adminPassword = await bcrypt.hash('admin123', 10);
  const supervisorPassword = await bcrypt.hash('super123', 10);

  await prisma.user.upsert({
    where: { username: 'admin' },
    update: {},
    create: { username: 'admin', password: adminPassword, role: 'ADMIN', name: 'Admin User' },
  });
  await prisma.user.upsert({
    where: { username: 'supervisor' },
    update: {},
    create: { username: 'supervisor', password: supervisorPassword, role: 'SUPERVISOR', name: 'Supervisor' },
  });

  // Create rooms
  const rooms = [
    { roomNumber: '101', floor: 1, capacity: 3, monthlyRent: 8000 },
    { roomNumber: '102', floor: 1, capacity: 2, monthlyRent: 9000 },
    { roomNumber: '201', floor: 2, capacity: 3, monthlyRent: 8500 },
    { roomNumber: '202', floor: 2, capacity: 4, monthlyRent: 7500 },
    { roomNumber: '301', floor: 3, capacity: 2, monthlyRent: 10000 },
    { roomNumber: '302', floor: 3, capacity: 3, monthlyRent: 9000 },
  ];
  for (const room of rooms) {
    await prisma.room.upsert({ where: { roomNumber: room.roomNumber }, update: {}, create: room });
  }

  // Inventory seed
  const items = [
    { name: 'Beds', category: 'Furniture', total: 72, good: 68, damaged: 4, missing: 0 },
    { name: 'Mattresses', category: 'Furniture', total: 72, good: 70, damaged: 2, missing: 0 },
    { name: 'Study Tables', category: 'Furniture', total: 60, good: 58, damaged: 2, missing: 0 },
    { name: 'Chairs', category: 'Furniture', total: 60, good: 56, damaged: 4, missing: 0 },
    { name: 'WiFi Routers', category: 'Electronics', total: 10, good: 9, damaged: 1, missing: 0 },
  ];
  for (const item of items) {
    await prisma.inventoryItem.create({ data: item }).catch(() => {});
  }

  console.log('Seed completed!');
  console.log('Admin: admin / admin123');
  console.log('Supervisor: supervisor / super123');
}

main().catch(console.error).finally(() => prisma.$disconnect());
