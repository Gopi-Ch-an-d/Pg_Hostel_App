import { DashboardService } from './dashboard.service';
export declare class DashboardController {
    private dashboardService;
    constructor(dashboardService: DashboardService);
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
