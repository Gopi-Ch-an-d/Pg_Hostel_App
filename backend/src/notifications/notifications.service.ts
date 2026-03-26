import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WhatsAppService } from './whatsapp.service';
import { CreateNotificationDto } from './dto/create-notification.dto';

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private whatsapp: WhatsAppService,
  ) {}

  async create(dto: CreateNotificationDto) {
    return this.prisma.notification.create({
      data: { ...dto, type: (dto.type as any) || 'GENERAL' },
    });
  }

  async findAll(query: { type?: string; unread?: string }) {
    const where: any = {};
    if (query.type) where.type = query.type;
    if (query.unread === 'true') where.isRead = false;
    return this.prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markRead(id: string) {
    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async markAllRead() {
    await this.prisma.notification.updateMany({ data: { isRead: true } });
    return { message: 'All notifications marked as read' };
  }

  // ── Send WhatsApp to single student ───────────────────────────────────────
  async sendWhatsAppToStudent(studentId: string, message: string) {
    const student = await this.prisma.student.findUnique({
      where: { id: studentId },
      include: { room: true },
    });
    if (!student) throw new Error('Student not found');

    const result = await this.whatsapp.sendMessage(student.mobile, message);

    // Save record to DB
    await this.prisma.notification.create({
      data: {
        title: 'WhatsApp Sent',
        message: `Sent to ${student.name} (${student.mobile}): ${message.substring(0, 50)}...`,
        type: 'GENERAL',
        targetAll: false,
      },
    });

    return {
      student: { name: student.name, mobile: student.mobile },
      ...result,
    };
  }

  // ── Send bulk WhatsApp ────────────────────────────────────────────────────
  async sendBulkWhatsApp(dto: {
    message: string;
    title?: string;
    targetAll?: boolean;
    floor?: number;
    onlyPending?: boolean;
  }) {
    let students = await this.prisma.student.findMany({
      where: { isActive: true },
      include: {
        room: true,
        fees: {
          where: { status: { in: ['PENDING', 'OVERDUE'] } },
          take: 1,
        },
      },
    });

    // Filter by floor
    if (dto.floor) {
      students = students.filter(s => s.room?.floor === dto.floor);
    }

    // Filter only students with pending fees
    if (dto.onlyPending) {
      students = students.filter(s => s.fees.length > 0);
    }

    const mobiles = students.map(s => s.mobile);
    const result  = await this.whatsapp.sendBulk(mobiles, dto.message);

    // Save notification record
    await this.prisma.notification.create({
      data: {
        title: dto.title || 'Bulk WhatsApp',
        message: `Sent to ${result.sent} students. Failed: ${result.failed}`,
        type: 'ANNOUNCEMENT',
        targetAll: dto.targetAll ?? true,
        floor: dto.floor,
      },
    });

    return {
      ...result,
      total: mobiles.length,
      students: students.map(s => ({ name: s.name, mobile: s.mobile })),
    };
  }

  // ── Send fee reminders via WhatsApp ───────────────────────────────────────
  async sendFeeReminders() {
    const now   = new Date();
    const month = now.getMonth() + 1;
    const year  = now.getFullYear();
    const monthNames = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    const pendingFees = await this.prisma.fee.findMany({
      where: { status: { in: ['PENDING', 'OVERDUE'] }, month, year },
      include: { student: { include: { room: true } } },
    });

    let sent = 0, failed = 0;
    const results = [];

    for (const fee of pendingFees) {
      const msg = this.whatsapp.buildFeeReminderMessage(
        fee.student.name,
        fee.amount,
        `${monthNames[month]} ${year}`,
        fee.student.room?.roomNumber || '',
      );
      const result = await this.whatsapp.sendMessage(fee.student.mobile, msg);
      if (result.success) sent++; else failed++;
      results.push({ name: fee.student.name, mobile: fee.student.mobile, ...result });
      await new Promise(r => setTimeout(r, 300));
    }

    // Save notification record
    await this.prisma.notification.create({
      data: {
        title: 'Fee Reminders Sent via WhatsApp',
        message: `${sent} sent successfully, ${failed} failed`,
        type: 'FEE_REMINDER',
        targetAll: false,
      },
    });

    return { sent, failed, total: pendingFees.length, results };
  }
}