import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRoomDto } from './dto/create-room.dto';

@Injectable()
export class RoomsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateRoomDto) {
    const existing = await this.prisma.room.findUnique({ where: { roomNumber: dto.roomNumber } });
    if (existing) throw new BadRequestException('Room number already exists');
    return this.prisma.room.create({ data: dto });
  }

  async findAll(query: { floor?: string; status?: string; roomNumber?: string }) {
    const where: any = {};
    if (query.floor) where.floor = parseInt(query.floor);
    if (query.status) where.status = query.status;
    if (query.roomNumber) {
      where.roomNumber = { contains: query.roomNumber, mode: 'insensitive' };
    }
    return this.prisma.room.findMany({
      where,
      include: {
        students: {
          where: { isActive: true },
          select: { id: true, name: true, mobile: true },
        },
      },
      orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
    });
  }

  async getByFloor() {
    const rooms = await this.prisma.room.findMany({
      include: { students: { where: { isActive: true }, select: { id: true, name: true } } },
      orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
    });
    // Group by floor
    const grouped: Record<number, any[]> = {};
    for (const room of rooms) {
      if (!grouped[room.floor]) grouped[room.floor] = [];
      grouped[room.floor].push(room);
    }
    return Object.entries(grouped).map(([floor, rooms]) => ({
      floor: parseInt(floor),
      totalRooms: rooms.length,
      occupiedRooms: rooms.filter(r => r.status === 'OCCUPIED').length,
      partialRooms: rooms.filter(r => r.status === 'PARTIAL').length,
      availableRooms: rooms.filter(r => r.status === 'AVAILABLE').length,
      totalBeds: rooms.reduce((s, r) => s + r.capacity, 0),
      occupiedBeds: rooms.reduce((s, r) => s + r.occupiedBeds, 0),
      vacantBeds: rooms.reduce((s, r) => s + (r.capacity - r.occupiedBeds), 0),
      rooms,
    }));
  }

  async findOne(id: string) {
    const room = await this.prisma.room.findUnique({
      where: { id },
      include: {
        students: {
          where: { isActive: true },
          include: { fees: { orderBy: { createdAt: 'desc' }, take: 1 } },
        },
      },
    });
    if (!room) throw new NotFoundException('Room not found');
    return room;
  }

  async update(id: string, dto: Partial<CreateRoomDto>) {
    await this.findOne(id);
    return this.prisma.room.update({ where: { id }, data: dto });
  }

  async remove(id: string) {
    const room = await this.findOne(id);
    if (room.occupiedBeds > 0) throw new BadRequestException('Cannot delete room with active students');
    await this.prisma.room.delete({ where: { id } });
    return { message: 'Room deleted successfully' };
  }

  async vacateStudent(studentId: string) {
    const student = await this.prisma.student.findUnique({ where: { id: studentId }, include: { room: true } });
    if (!student) throw new NotFoundException('Student not found');
    await this.prisma.student.update({ where: { id: studentId }, data: { isActive: false } });
    const newOccupied = Math.max(0, student.room.occupiedBeds - 1);
    await this.prisma.room.update({
      where: { id: student.roomId },
      data: {
        occupiedBeds: newOccupied,
        status: newOccupied === 0 ? 'AVAILABLE' : newOccupied < student.room.capacity ? 'PARTIAL' : 'OCCUPIED',
      },
    });
    return { message: 'Student vacated successfully' };
  }

  async getSummary() {
    const rooms = await this.prisma.room.findMany();
    return {
      totalRooms: rooms.length,
      occupiedRooms: rooms.filter(r => r.status === 'OCCUPIED').length,
      availableRooms: rooms.filter(r => r.status === 'AVAILABLE').length,
      partialRooms: rooms.filter(r => r.status === 'PARTIAL').length,
      totalBeds: rooms.reduce((s, r) => s + r.capacity, 0),
      occupiedBeds: rooms.reduce((s, r) => s + r.occupiedBeds, 0),
      vacantBeds: rooms.reduce((s, r) => s + (r.capacity - r.occupiedBeds), 0),
    };
  }
}