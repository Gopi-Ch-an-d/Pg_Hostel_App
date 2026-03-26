import { PrismaService } from '../prisma/prisma.service';
export declare class DashboardService {
    private prisma;
    constructor(prisma: PrismaService);
    getSummary(): Promise<{
        students: {
            total: number;
        };
        rooms: {
            total: number;
            occupied: number;
            available: number;
            partial: number;
            totalBeds: number;
            vacantBeds: number;
        };
        fees: {
            monthlyRevenue: number;
            pendingAmount: number;
            paidCount: number;
            pendingCount: number;
            todayRevenue: number;
        };
        complaints: {
            open: number;
        };
        inventory: {
            damaged: number;
            missing: number;
        };
    }>;
}
