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
exports.DashboardService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let DashboardService = class DashboardService {
    constructor(prisma) {
        this.prisma = prisma;
    }
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
};
exports.DashboardService = DashboardService;
exports.DashboardService = DashboardService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], DashboardService);
//# sourceMappingURL=dashboard.service.js.map