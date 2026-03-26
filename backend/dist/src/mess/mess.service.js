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
exports.MessService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let MessService = class MessService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getWeekMenu(weekOf) {
        const date = new Date(weekOf);
        return this.prisma.messMenu.findMany({
            where: { weekOf: date },
            orderBy: { dayOfWeek: 'asc' },
        });
    }
    async upsertDayMenu(data) {
        const weekOf = new Date(data.weekOf);
        return this.prisma.messMenu.upsert({
            where: { dayOfWeek_weekOf: { dayOfWeek: data.dayOfWeek, weekOf } },
            create: { ...data, weekOf },
            update: { breakfast: data.breakfast, lunch: data.lunch, dinner: data.dinner },
        });
    }
    async generateMonthlyMessFees(month, year, amount) {
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
    async recordMessPayment(studentId, month, year) {
        const payment = await this.prisma.messPayment.findUnique({
            where: { studentId_month_year: { studentId, month, year } },
        });
        if (!payment)
            throw new Error('Mess payment record not found');
        return this.prisma.messPayment.update({ where: { id: payment.id }, data: { status: 'PAID', paidDate: new Date() } });
    }
    async getMonthlyMessFees(month, year) {
        return this.prisma.messPayment.findMany({
            where: { month, year },
            include: { student: { select: { name: true, room: { select: { roomNumber: true } } } } },
        });
    }
};
exports.MessService = MessService;
exports.MessService = MessService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MessService);
//# sourceMappingURL=mess.service.js.map