import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MessService {
  constructor(private prisma: PrismaService) {}

  async getWeekMenu(weekOf: string) {
    const date = new Date(weekOf);
    return this.prisma.messMenu.findMany({
      where: { weekOf: date },
      orderBy: { dayOfWeek: 'asc' },
    });
  }

  async upsertDayMenu(data: { dayOfWeek: number; breakfast: string; lunch: string; dinner: string; weekOf: string }) {
    const weekOf = new Date(data.weekOf);
    return this.prisma.messMenu.upsert({
      where: { dayOfWeek_weekOf: { dayOfWeek: data.dayOfWeek, weekOf } },
      create: { ...data, weekOf },
      update: { breakfast: data.breakfast, lunch: data.lunch, dinner: data.dinner },
    });
  }

  async generateMonthlyMessFees(month: number, year: number, amount: number) {
    const students = await this.prisma.student.findMany({ where: { isActive: true } });
    let created = 0;
    for (const student of students) {
      const existing = await this.prisma.messPayment.findUnique({
        where: { studentId_month_year: { studentId: student.id, month, year } },
      });
      if (!existing) {
        await this.prisma.messPayment.create({ data: { studentId: student.id, month, year, amount, status: 'PENDING' } });
        created++;
      }
    }
    return { generated: created };
  }

  async recordMessPayment(studentId: string, month: number, year: number) {
    const payment = await this.prisma.messPayment.findUnique({
      where: { studentId_month_year: { studentId, month, year } },
    });
    if (!payment) throw new Error('Mess payment record not found');
    return this.prisma.messPayment.update({ where: { id: payment.id }, data: { status: 'PAID', paidDate: new Date() } });
  }

  async getMonthlyMessFees(month: number, year: number) {
    return this.prisma.messPayment.findMany({
      where: { month, year },
      include: { student: { select: { name: true, room: { select: { roomNumber: true } } } } },
    });
  }
}
