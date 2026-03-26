import { InventoryService } from './inventory.service';
import { CreateInventoryDto } from './dto/create-inventory.dto';
export declare class InventoryController {
    private inventoryService;
    constructor(inventoryService: InventoryService);
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
    findAll(query: any): Promise<{
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
    getSummary(): Promise<{
        totalItems: number;
        goodItems: number;
        damagedItems: number;
        missingItems: number;
        categories: string[];
    }>;
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
}
