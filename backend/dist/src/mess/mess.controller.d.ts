import { MessService } from './mess.service';
export declare class MessController {
    private messService;
    constructor(messService: MessService);
    getMenu(weekOf: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        dayOfWeek: number;
        breakfast: string;
        lunch: string;
        dinner: string;
        weekOf: Date;
    }[]>;
    upsertMenu(data: any): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        dayOfWeek: number;
        breakfast: string;
        lunch: string;
        dinner: string;
        weekOf: Date;
    }>;
    generateFees(body: {
        month: number;
        year: number;
        amount: number;
    }): Promise<{
        generated: number;
    }>;
    recordPayment(body: {
        studentId: string;
        month: number;
        year: number;
    }): Promise<{
        id: string;
        createdAt: Date;
        status: import(".prisma/client").$Enums.FeeStatus;
        month: number;
        year: number;
        amount: number;
        paidDate: Date | null;
        studentId: string;
    }>;
    getMonthlyFees(month: string, year: string): Promise<({
        student: {
            name: string;
            room: {
                roomNumber: string;
            };
        };
    } & {
        id: string;
        createdAt: Date;
        status: import(".prisma/client").$Enums.FeeStatus;
        month: number;
        year: number;
        amount: number;
        paidDate: Date | null;
        studentId: string;
    })[]>;
}
