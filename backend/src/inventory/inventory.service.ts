import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInventoryDto } from './dto/create-inventory.dto';

@Injectable()
export class InventoryService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateInventoryDto) {
    const existing = await this.prisma.inventoryItem.findFirst({
      where: { name: { equals: dto.name, mode: 'insensitive' }, category: { equals: dto.category, mode: 'insensitive' } },
    });
    if (existing) {
      throw new BadRequestException(`Item "${dto.name}" already exists in ${dto.category}`);
    }
    return this.prisma.inventoryItem.create({ data: dto });
  }

  async findAll(query: { category?: string }) {
    return this.prisma.inventoryItem.findMany({
      where: query.category ? { category: query.category } : {},
      orderBy: { category: 'asc' },
    });
  }

  async update(id: string, dto: Partial<CreateInventoryDto>) {
    const item = await this.prisma.inventoryItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Item not found');
    return this.prisma.inventoryItem.update({ where: { id }, data: dto });
  }

  async remove(id: string) {
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
}
