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
exports.NotificationsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const whatsapp_service_1 = require("./whatsapp.service");
let NotificationsService = class NotificationsService {
    constructor(prisma, whatsapp) {
        this.prisma = prisma;
        this.whatsapp = whatsapp;
    }
    async create(dto) {
        return this.prisma.notification.create({
            data: { ...dto, type: dto.type || 'GENERAL' },
        });
    }
    async findAll(query) {
        const where = {};
        if (query.type)
            where.type = query.type;
        if (query.unread === 'true')
            where.isRead = false;
        return this.prisma.notification.findMany({
            where,
            orderBy: { createdAt: 'desc' },
            take: 50,
        });
    }
    async markRead(id) {
        return this.prisma.notification.update({
            where: { id },
            data: { isRead: true },
        });
    }
    async markAllRead() {
        await this.prisma.notification.updateMany({ data: { isRead: true } });
        return { message: 'All notifications marked as read' };
    }
    async sendWhatsAppToStudent(studentId, message) {
        const student = await this.prisma.student.findUnique({
            where: { id: studentId },
            include: { room: true },
        });
        if (!student)
            throw new Error('Student not found');
        const result = await this.whatsapp.sendMessage(student.mobile, message);
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
    async sendBulkWhatsApp(dto) {
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
        if (dto.floor) {
            students = students.filter(s => s.room?.floor === dto.floor);
        }
        if (dto.onlyPending) {
            students = students.filter(s => s.fees.length > 0);
        }
        const mobiles = students.map(s => s.mobile);
        const result = await this.whatsapp.sendBulk(mobiles, dto.message);
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
    async sendFeeReminders() {
        const now = new Date();
        const month = now.getMonth() + 1;
        const year = now.getFullYear();
        const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const pendingFees = await this.prisma.fee.findMany({
            where: { status: { in: ['PENDING', 'OVERDUE'] }, month, year },
            include: { student: { include: { room: true } } },
        });
        let sent = 0, failed = 0;
        const results = [];
        for (const fee of pendingFees) {
            const msg = this.whatsapp.buildFeeReminderMessage(fee.student.name, fee.amount, `${monthNames[month]} ${year}`, fee.student.room?.roomNumber || '');
            const result = await this.whatsapp.sendMessage(fee.student.mobile, msg);
            if (result.success)
                sent++;
            else
                failed++;
            results.push({ name: fee.student.name, mobile: fee.student.mobile, ...result });
            await new Promise(r => setTimeout(r, 300));
        }
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
};
exports.NotificationsService = NotificationsService;
exports.NotificationsService = NotificationsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        whatsapp_service_1.WhatsAppService])
], NotificationsService);
//# sourceMappingURL=notifications.service.js.map