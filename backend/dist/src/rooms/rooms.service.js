"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RoomsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let RoomsService = class RoomsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(dto) {
        const existing = await this.prisma.room.findUnique({ where: { roomNumber: dto.roomNumber } });
        if (existing)
            throw new common_1.BadRequestException('Room number already exists');
        return this.prisma.room.create({ data: dto });
    }
    async findAll(query) {
        const where = {};
        if (query.floor)
            where.floor = parseInt(query.floor);
        if (query.status)
            where.status = query.status;
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
        const grouped = {};
        for (const room of rooms) {
            if (!grouped[room.floor])
                grouped[room.floor] = [];
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
    async findOne(id) {
        const room = await this.prisma.room.findUnique({
            where: { id },
            include: {
                students: {
                    where: { isActive: true },
                    include: { fees: { orderBy: { createdAt: 'desc' }, take: 1 } },
                },
            },
        });
        if (!room)
            throw new common_1.NotFoundException('Room not found');
        return room;
    }
    async update(id, dto) {
        await this.findOne(id);
        return this.prisma.room.update({ where: { id }, data: dto });
    }
    async remove(id) {
        const room = await this.findOne(id);
        if (room.occupiedBeds > 0)
            throw new common_1.BadRequestException('Cannot delete room with active students');
        await this.prisma.room.delete({ where: { id } });
        return { message: 'Room deleted successfully' };
    }
    async vacateStudent(studentId) {
        const student = await this.prisma.student.findUnique({ where: { id: studentId }, include: { room: true } });
        if (!student)
            throw new common_1.NotFoundException('Student not found');
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
};
exports.RoomsService = RoomsService;
exports.RoomsService = RoomsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], RoomsService);
//# sourceMappingURL=rooms.service.js.map