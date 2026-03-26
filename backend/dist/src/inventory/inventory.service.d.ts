import { PrismaService } from '../prisma/prisma.service';
import { CreateInventoryDto } from './dto/create-inventory.dto';
export declare class InventoryService {
    private prisma;
    constructor(prisma: PrismaService);
    create(dto: CreateInventoryDto): Promise<{
        id: string;
        name: string;
        category: string;
        total: number;
        good: number;
        damaged: number;
        missing: number;
        notes: string | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    findAll(query: {
        category?: string;
    }): Promise<{
        id: string;
        name: string;
        category: string;
        total: number;
        good: number;
        damaged: number;
        missing: number;
        notes: string | null;
        createdAt: Date;
        updatedAt: Date;
    }[]>;
    update(id: string, dto: Partial<CreateInventoryDto>): Promise<{
        id: string;
        name: string;
        category: string;
        total: number;
        good: number;
        damaged: number;
        missing: number;
        notes: string | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    remove(id: string): Promise<{
        message: string;
    }>;
    getSummary(): Promise<{
        totalItems: number;
        goodItems: number;
        damagedItems: number;
        missingItems: number;
        categories: string[];
    }>;
}
