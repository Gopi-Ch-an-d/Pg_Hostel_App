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
exports.StudentsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const whatsapp_service_1 = require("../notifications/whatsapp.service");
let StudentsService = class StudentsService {
    constructor(prisma, whatsapp) {
        this.prisma = prisma;
        this.whatsapp = whatsapp;
    }
    async create(dto) {
        const room = await this.prisma.room.findUnique({ where: { id: dto.roomId } });
        if (!room)
            throw new common_1.NotFoundException('Room not found');
        if (room.occupiedBeds >= room.capacity) {
            throw new common_1.BadRequestException('Room is fully occupied');
        }
        const existing = await this.prisma.student.findFirst({
            where: {
                OR: [
                    { mobile: dto.mobile },
                    ...(dto.aadhaar ? [{ aadhaar: dto.aadhaar }] : []),
                ],
            },
        });
        if (existing && existing.isActive) {
            const field = existing.mobile === dto.mobile ? 'Mobile number' : 'Aadhaar';
            throw new common_1.BadRequestException(`${field} is already registered with an active student`);
        }
        let student;
        const studentData = {
            name: dto.name,
            mobile: dto.mobile,
            aadhaar: dto.aadhaar || null,
            address: dto.address || '',
            roomId: dto.roomId,
            joiningDate: new Date(dto.joiningDate),
            deposit: dto.deposit,
            monthlyRent: dto.monthlyRent,
            idProofUrl: dto.idProofUrl || null,
            vehicleNumber: dto.vehicleNumber || null,
            vehicleType: dto.vehicleType || null,
            isActive: true,
        };
        if (existing) {
            student = await this.prisma.student.update({
                where: { id: existing.id },
                data: studentData,
                include: { room: true },
            });
        }
        else {
            student = await this.prisma.student.create({
                data: studentData,
                include: { room: true },
            });
        }
        const newOccupied = room.occupiedBeds + 1;
        await this.prisma.room.update({
            where: { id: dto.roomId },
            data: {
                occupiedBeds: newOccupied,
                status: newOccupied >= room.capacity ? 'OCCUPIED' : 'PARTIAL',
            },
        });
        const now = new Date();
        await this.prisma.fee.create({
            data: {
                studentId: student.id,
                month: now.getMonth() + 1,
                year: now.getFullYear(),
                amount: dto.monthlyRent,
                dueDate: new Date(now.getFullYear(), now.getMonth(), 5),
                status: 'PENDING',
            },
        });
        this.whatsapp.sendMessage(student.mobile, this._buildWelcomeMessage(student.name, room.roomNumber, room.floor, dto.monthlyRent, dto.deposit, new Date(dto.joiningDate))).catch(err => console.warn(`WhatsApp welcome failed for ${student.name}: ${err.message}`));
        return student;
    }
    _buildWelcomeMessage(name, roomNumber, floor, rent, deposit, joiningDate) {
        const joinStr = joiningDate.toLocaleDateString('en-IN', {
            day: '2-digit', month: 'long', year: 'numeric',
        });
        const vacatingDate = new Date(joiningDate);
        vacatingDate.setMonth(vacatingDate.getMonth() + 1);
        const vacateStr = vacatingDate.toLocaleDateString('en-IN', {
            day: '2-digit', month: 'long', year: 'numeric',
        });
        return `🏠 *Welcome to Our PG Hostel!* 🎉
\nHi *${name}*! 👋
\nYou have been successfully registered. Here are your details:
\n📋 *Your Details:*
• Room Number: *${roomNumber}* (Floor ${floor})
• Joining Date: *${joinStr}*
• Stay Period: *${joinStr}* → *${vacateStr}*
• Monthly Rent: *₹${rent.toLocaleString('en-IN')}*
• Security Deposit: *₹${deposit.toLocaleString('en-IN')}*
\n💳 *Payment Info:*
• First Rent Due: *${vacateStr}*
• After that: due on *${joiningDate.getDate()}th of every month*
• Pay on time to avoid late charges
\n📞 Contact management for any issues:
  WiFi • Water • Electricity • Cleanliness
\nWe hope you have a comfortable stay! 😊
— *PG Management* 🏠`;
    }
    async findAll(query) {
        const { search, status, floor, page = 1, limit = 50 } = query;
        const where = { isActive: true };
        if (search) {
            where.OR = [
                { name: { contains: search, mode: 'insensitive' } },
                { mobile: { contains: search } },
                { vehicleNumber: { contains: search, mode: 'insensitive' } },
                { room: { roomNumber: { contains: search } } },
            ];
        }
        if (floor)
            where.room = { floor: parseInt(floor) };
        const [students, total] = await Promise.all([
            this.prisma.student.findMany({
                where,
                include: {
                    room: true,
                    fees: { orderBy: { createdAt: 'desc' }, take: 1 },
                },
                skip: (page - 1) * limit,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            this.prisma.student.count({ where }),
        ]);
        let result = students;
        if (status === 'paid')
            result = students.filter(s => s.fees[0]?.status === 'PAID');
        if (status === 'pending')
            result = students.filter(s => s.fees[0]?.status !== 'PAID');
        return { data: result, total, page, limit };
    }
    async findOne(id) {
        const student = await this.prisma.student.findUnique({
            where: { id },
            include: {
                room: true,
                fees: { orderBy: [{ year: 'desc' }, { month: 'desc' }] },
                complaints: { orderBy: { createdAt: 'desc' } },
                messPayments: true,
            },
        });
        if (!student)
            throw new common_1.NotFoundException('Student not found');
        return student;
    }
    async update(id, dto) {
        await this.findOne(id);
        return this.prisma.student.update({
            where: { id },
            data: {
                ...(dto.name && { name: dto.name }),
                ...(dto.mobile && { mobile: dto.mobile }),
                ...(dto.aadhaar !== undefined && { aadhaar: dto.aadhaar || null }),
                ...(dto.address && { address: dto.address }),
                ...(dto.roomId && { roomId: dto.roomId }),
                ...(dto.joiningDate && { joiningDate: new Date(dto.joiningDate) }),
                ...(dto.deposit && { deposit: dto.deposit }),
                ...(dto.monthlyRent && { monthlyRent: dto.monthlyRent }),
                ...(dto.vehicleNumber !== undefined && { vehicleNumber: dto.vehicleNumber || null }),
                ...(dto.vehicleType !== undefined && { vehicleType: dto.vehicleType || null }),
            },
            include: { room: true },
        });
    }
    async remove(id) {
        const student = await this.findOne(id);
        await this.prisma.student.update({
            where: { id },
            data: { isActive: false },
        });
        const room = await this.prisma.room.findUnique({ where: { id: student.roomId } });
        const newOccupied = Math.max(0, room.occupiedBeds - 1);
        await this.prisma.room.update({
            where: { id: student.roomId },
            data: {
                occupiedBeds: newOccupied,
                status: newOccupied === 0
                    ? 'AVAILABLE'
                    : newOccupied < room.capacity
                        ? 'PARTIAL'
                        : 'OCCUPIED',
            },
        });
        return { message: 'Student removed successfully' };
    }
    async uploadIdProof(id, filename) {
        return this.prisma.student.update({
            where: { id },
            data: { idProofUrl: `/uploads/${filename}` },
        });
    }
    async getAvailableRooms() {
        return this.prisma.room.findMany({
            where: { status: { in: ['AVAILABLE', 'PARTIAL'] } },
            include: {
                students: {
                    where: { isActive: true },
                    select: { id: true, name: true },
                },
            },
            orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
        });
    }
    async getMinimal() {
        return this.prisma.student.findMany({
            where: { isActive: true },
            select: { id: true, name: true },
            orderBy: { name: 'asc' },
        });
    }
};
exports.StudentsService = StudentsService;
exports.StudentsService = StudentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        whatsapp_service_1.WhatsAppService])
], StudentsService);
//# sourceMappingURL=students.service.js.map