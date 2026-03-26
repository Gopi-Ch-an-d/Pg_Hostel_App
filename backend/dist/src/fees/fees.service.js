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
exports.FeesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let FeesService = class FeesService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getSummary() {
        const now = new Date();
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        const month = now.getMonth() + 1;
        const year = now.getFullYear();
        const todayPaid = await this.prisma.fee.findMany({
            where: { status: 'PAID', paidDate: { gte: todayStart, lt: todayEnd } },
        });
        const monthFees = await this.prisma.fee.findMany({ where: { month, year } });
        const monthPaid = monthFees.filter(f => f.status === 'PAID');
        const monthPending = monthFees.filter(f => f.status !== 'PAID');
        const yearFees = await this.prisma.fee.findMany({ where: { year } });
        const yearPaid = yearFees.filter(f => f.status === 'PAID');
        const yearPending = yearFees.filter(f => f.status !== 'PAID');
        const overdueFees = await this.prisma.fee.findMany({
            where: { status: 'OVERDUE' },
            include: { student: { select: { name: true, mobile: true, room: { select: { roomNumber: true } } } } },
        });
        const students = await this.prisma.student.findMany({
            where: { isActive: true },
            select: { deposit: true },
        });
        return {
            today: {
                revenue: todayPaid.reduce((s, f) => s + f.amount, 0),
                count: todayPaid.length,
            },
            monthly: {
                month,
                year,
                revenue: monthPaid.reduce((s, f) => s + f.amount, 0),
                pending: monthPending.reduce((s, f) => s + f.amount, 0),
                paidCount: monthPaid.length,
                pendingCount: monthPending.length,
                total: monthFees.length,
            },
            yearly: {
                year,
                revenue: yearPaid.reduce((s, f) => s + f.amount, 0),
                pending: yearPending.reduce((s, f) => s + f.amount, 0),
                paidCount: yearPaid.length,
                pendingCount: yearPending.length,
            },
            overdue: {
                amount: overdueFees.reduce((s, f) => s + f.amount, 0),
                count: overdueFees.length,
                fees: overdueFees,
            },
            deposits: {
                total: students.reduce((s, st) => s + st.deposit, 0),
                count: students.length,
            },
        };
    }
    async generateMonthlyFees(month, year) {
        const students = await this.prisma.student.findMany({ where: { isActive: true } });
        const dueDate = new Date(year, month - 1, 5);
        const results = [];
        for (const student of students) {
            const existing = await this.prisma.fee.findUnique({
                where: { studentId_month_year: { studentId: student.id, month, year } },
            });
            if (!existing) {
                const fee = await this.prisma.fee.create({
                    data: { studentId: student.id, month, year, amount: student.monthlyRent, dueDate, status: 'PENDING' },
                });
                results.push(fee);
            }
        }
        return { generated: results.length, message: `Generated fees for ${results.length} students` };
    }
    async incrementFees(percentage, effectiveMonth, effectiveYear) {
        const students = await this.prisma.student.findMany({ where: { isActive: true } });
        const multiplier = 1 + percentage / 100;
        const updated = [];
        for (const student of students) {
            const newRent = Math.round(student.monthlyRent * multiplier);
            await this.prisma.student.update({ where: { id: student.id }, data: { monthlyRent: newRent } });
            const dueDate = new Date(effectiveYear, effectiveMonth - 1, 5);
            await this.prisma.fee.upsert({
                where: { studentId_month_year: { studentId: student.id, month: effectiveMonth, year: effectiveYear } },
                create: { studentId: student.id, month: effectiveMonth, year: effectiveYear, amount: newRent, dueDate, status: 'PENDING' },
                update: { amount: newRent },
            });
            updated.push({ name: student.name, oldRent: student.monthlyRent, newRent });
        }
        return {
            message: `Fee incremented by ${percentage}% for ${updated.length} students`,
            effectiveFrom: `${effectiveMonth}/${effectiveYear}`,
            students: updated,
        };
    }
    async recordPayment(dto) {
        const student = await this.prisma.student.findUnique({ where: { id: dto.studentId } });
        if (!student)
            throw new common_1.NotFoundException('Student not found');
        const dueDate = new Date(dto.year, dto.month - 1, 5);
        return this.prisma.fee.upsert({
            where: { studentId_month_year: { studentId: dto.studentId, month: dto.month, year: dto.year } },
            create: {
                studentId: dto.studentId,
                month: dto.month,
                year: dto.year,
                amount: student.monthlyRent,
                dueDate,
                status: 'PAID',
                paidDate: new Date(),
                paymentMode: dto.paymentMode,
                notes: dto.notes,
            },
            update: {
                status: 'PAID',
                paidDate: new Date(),
                paymentMode: dto.paymentMode,
                notes: dto.notes,
            },
            include: { student: { select: { name: true, room: { select: { roomNumber: true } } } } },
        });
    }
    async getStudentFees(studentId) {
        return this.prisma.fee.findMany({
            where: { studentId },
            orderBy: [{ year: 'desc' }, { month: 'desc' }],
        });
    }
    async getMonthlyFees(month, year) {
        const fees = await this.prisma.fee.findMany({
            where: { month, year },
            include: {
                student: { select: { name: true, mobile: true, room: { select: { roomNumber: true, floor: true } } } },
            },
            orderBy: { student: { name: 'asc' } },
        });
        const paid = fees.filter(f => f.status === 'PAID');
        const pending = fees.filter(f => f.status !== 'PAID');
        return {
            fees,
            summary: {
                total: fees.length,
                paid: paid.length,
                pending: pending.length,
                collectedAmount: paid.reduce((s, f) => s + f.amount, 0),
                pendingAmount: pending.reduce((s, f) => s + f.amount, 0),
            },
        };
    }
    async getPendingFees() {
        return this.prisma.fee.findMany({
            where: { status: { in: ['PENDING', 'OVERDUE'] } },
            include: { student: { select: { name: true, mobile: true, room: { select: { roomNumber: true } } } } },
            orderBy: { dueDate: 'asc' },
        });
    }
    async markOverdue() {
        const today = new Date();
        const result = await this.prisma.fee.updateMany({
            where: { status: 'PENDING', dueDate: { lt: today } },
            data: { status: 'OVERDUE' },
        });
        return { updated: result.count };
    }
    async getRevenueStats(year) {
        const months = Array.from({ length: 12 }, (_, i) => i + 1);
        const stats = [];
        for (const month of months) {
            const paid = await this.prisma.fee.findMany({ where: { month, year, status: 'PAID' } });
            const pending = await this.prisma.fee.findMany({ where: { month, year, status: { in: ['PENDING', 'OVERDUE'] } } });
            stats.push({
                month,
                collected: paid.reduce((s, f) => s + f.amount, 0),
                pending: pending.reduce((s, f) => s + f.amount, 0),
                count: paid.length,
            });
        }
        return stats;
    }
};
exports.FeesService = FeesService;
exports.FeesService = FeesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], FeesService);
//# sourceMappingURL=fees.service.js.map