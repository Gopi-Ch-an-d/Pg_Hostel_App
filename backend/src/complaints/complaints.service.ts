import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateComplaintDto, UpdateComplaintDto } from './dto/create-complaint.dto';

@Injectable()
export class ComplaintsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateComplaintDto) {
    return this.prisma.complaint.create({
      data: { ...dto, type: dto.type as any, status: 'PENDING' },
      include: { student: { select: { name: true, room: { select: { roomNumber: true } } } } },
    });
  }

  async findAll(query: { status?: string; type?: string }) {
    const where: any = {};
    if (query.status) where.status = query.status;
    if (query.type) where.type = query.type;
    return this.prisma.complaint.findMany({
      where,
      include: { student: { select: { name: true, mobile: true, room: { select: { roomNumber: true, floor: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async update(id: string, dto: UpdateComplaintDto) {
    const complaint = await this.prisma.complaint.findUnique({ where: { id } });
    if (!complaint) throw new NotFoundException('Complaint not found');
    return this.prisma.complaint.update({
      where: { id },
      data: { status: dto.status as any, adminNotes: dto.adminNotes, resolvedAt: dto.status === 'RESOLVED' ? new Date() : null },
      include: { student: { select: { name: true, room: { select: { roomNumber: true } } } } },
    });
  }

  async getStats() {
    const [pending, inProgress, resolved] = await Promise.all([
      this.prisma.complaint.count({ where: { status: 'PENDING' } }),
      this.prisma.complaint.count({ where: { status: 'IN_PROGRESS' } }),
      this.prisma.complaint.count({ where: { status: 'RESOLVED' } }),
    ]);
    return { pending, inProgress, resolved, total: pending + inProgress + resolved };
  }
}
