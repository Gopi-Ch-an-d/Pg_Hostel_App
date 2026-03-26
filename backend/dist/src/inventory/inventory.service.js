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
exports.InventoryService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let InventoryService = class InventoryService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(dto) {
        const existing = await this.prisma.inventoryItem.findFirst({
            where: { name: { equals: dto.name, mode: 'insensitive' }, category: { equals: dto.category, mode: 'insensitive' } },
        });
        if (existing) {
            throw new common_1.BadRequestException(`Item "${dto.name}" already exists in ${dto.category}`);
        }
        return this.prisma.inventoryItem.create({ data: dto });
    }
    async findAll(query) {
        return this.prisma.inventoryItem.findMany({
            where: query.category ? { category: query.category } : {},
            orderBy: { category: 'asc' },
        });
    }
    async update(id, dto) {
        const item = await this.prisma.inventoryItem.findUnique({ where: { id } });
        if (!item)
            throw new common_1.NotFoundException('Item not found');
        return this.prisma.inventoryItem.update({ where: { id }, data: dto });
    }
    async remove(id) {
        await this.prisma.inventoryItem.delete({ where: { id } });
        return { message: 'Item deleted' };
    }
    async getSummary() {
        const items = await this.prisma.inventoryItem.findMany();
        return {
            totalItems: items.reduce((s, i) => s + i.total, 0),
            goodItems: items.reduce((s, i) => s + i.good, 0),
            damagedItems: items.reduce((s, i) => s + i.damaged, 0),
            missingItems: items.reduce((s, i) => s + i.missing, 0),
            categories: [...new Set(items.map(i => i.category))],
        };
    }
};
exports.InventoryService = InventoryService;
exports.InventoryService = InventoryService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], InventoryService);
//# sourceMappingURL=inventory.service.js.map