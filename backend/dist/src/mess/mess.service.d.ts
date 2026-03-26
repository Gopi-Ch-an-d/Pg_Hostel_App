import { PrismaService } from '../prisma/prisma.service';
export declare class MessService {
    private prisma;
    constructor(prisma: PrismaService);
    getWeekMenu(weekOf: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        dayOfWeek: number;
        breakfast: string;
        lunch: string;
        dinner: string;
        weekOf: Date;
    }[]>;
    upsertDayMenu(data: {
        dayOfWeek: number;
        breakfast: string;
        lunch: string;
        dinner: string;
        weekOf: string;
    }): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        dayOfWeek: number;
        breakfast: string;
        lunch: string;
        dinner: string;
        weekOf: Date;
    }>;
    generateMonthlyMessFees(month: number, year: number, amount: number): Promise<{
        generated: number;
    }>;
    recordMessPayment(studentId: string, month: number, year: number): Promise<{
        id: string;
        createdAt: Date;
        status: import(".prisma/client").$Enums.FeeStatus;
        month: number;
        year: number;
        amount: number;
        paidDate: Date | null;
        studentId: string;
    }>;
    getMonthlyMessFees(month: number, year: number): Promise<({
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
