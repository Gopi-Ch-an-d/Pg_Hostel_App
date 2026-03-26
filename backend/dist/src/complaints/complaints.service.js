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
exports.ComplaintsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let ComplaintsService = class ComplaintsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(dto) {
        return this.prisma.complaint.create({
            data: { ...dto, type: dto.type, status: 'PENDING' },
            include: { student: { select: { name: true, room: { select: { roomNumber: true } } } } },
        });
    }
    async findAll(query) {
        const where = {};
        if (query.status)
            where.status = query.status;
        if (query.type)
            where.type = query.type;
        return this.prisma.complaint.findMany({
            where,
            include: { student: { select: { name: true, mobile: true, room: { select: { roomNumber: true, floor: true } } } } },
            orderBy: { createdAt: 'desc' },
        });
    }
    async update(id, dto) {
        const complaint = await this.prisma.complaint.findUnique({ where: { id } });
        if (!complaint)
            throw new common_1.NotFoundException('Complaint not found');
        return this.prisma.complaint.update({
            where: { id },
            data: { status: dto.status, adminNotes: dto.adminNotes, resolvedAt: dto.status === 'RESOLVED' ? new Date() : null },
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
};
exports.ComplaintsService = ComplaintsService;
exports.ComplaintsService = ComplaintsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ComplaintsService);
//# sourceMappingURL=complaints.service.js.map