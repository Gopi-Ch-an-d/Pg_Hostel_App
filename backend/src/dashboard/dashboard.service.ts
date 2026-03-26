import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getSummary() {
    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();
    const [totalStudents, rooms, fees, complaints, inventory] = await Promise.all([
      this.prisma.student.count({ where: { isActive: true } }),
      this.prisma.room.findMany(),
      this.prisma.fee.findMany({ where: { month, year } }),
      this.prisma.complaint.findMany({ where: { status: { not: 'RESOLVED' } } }),
      this.prisma.inventoryItem.findMany(),
    ]);
    const paidFees = fees.filter(f => f.status === 'PAID');
    const pendingFees = fees.filter(f => f.status !== 'PAID');
    
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);
    const todayFees = paidFees.filter(f => f.paidDate && f.paidDate >= todayStart && f.paidDate <= todayEnd);

    return {
      students: { total: totalStudents },
      rooms: {
        total: rooms.length,
        occupied: rooms.filter(r => r.status === 'OCCUPIED').length,
        available: rooms.filter(r => r.status === 'AVAILABLE').length,
        partial: rooms.filter(r => r.status === 'PARTIAL').length,
        totalBeds: rooms.reduce((s, r) => s + r.capacity, 0),
        vacantBeds: rooms.reduce((s, r) => s + (r.capacity - r.occupiedBeds), 0),
      },
      fees: {
        monthlyRevenue: paidFees.reduce((s, f) => s + f.amount, 0),
        pendingAmount: pendingFees.reduce((s, f) => s + f.amount, 0),
        paidCount: paidFees.length,
        pendingCount: pendingFees.length,
        todayRevenue: todayFees.reduce((s, f) => s + f.amount, 0),
      },
      complaints: { open: complaints.length },
      inventory: {
        damaged: inventory.reduce((s, i) => s + i.damaged, 0),
        missing: inventory.reduce((s, i) => s + i.missing, 0),
      },
    };
  }
}
