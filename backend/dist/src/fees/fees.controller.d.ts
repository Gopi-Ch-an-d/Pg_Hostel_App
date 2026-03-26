import { FeesService } from './fees.service';
import { RecordPaymentDto } from './dto/create-fee.dto';
export declare class FeesController {
    private feesService;
    constructor(feesService: FeesService);
    generate(body: {
        month: number;
        year: number;
    }): Promise<{
        generated: number;
        message: string;
    }>;
    incrementFees(body: {
        percentage: number;
        effectiveMonth: number;
        effectiveYear: number;
    }): Promise<{
        message: string;
        effectiveFrom: string;
        students: any[];
    }>;
    recordPayment(dto: RecordPaymentDto): Promise<{
        student: {
            name: string;
            room: {
                roomNumber: string;
            };
        };
    } & {
        id: string;
        studentId: string;
        month: number;
        year: number;
        amount: number;
        dueDate: Date;
        paidDate: Date | null;
        status: import(".prisma/client").$Enums.FeeStatus;
        paymentMode: string | null;
        notes: string | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    getSummary(): Promise<{
        today: {
            revenue: number;
            count: number;
        };
        monthly: {
            month: number;
            year: number;
            revenue: number;
            pending: number;
            paidCount: number;
            pendingCount: number;
            total: number;
        };
        yearly: {
            year: number;
            revenue: number;
            pending: number;
            paidCount: number;
            pendingCount: number;
        };
        overdue: {
            amount: number;
            count: number;
            fees: ({
                student: {
                    name: string;
                    mobile: string;
                    room: {
                        roomNumber: string;
                    };
                };
            } & {
                id: string;
                studentId: string;
                month: number;
                year: number;
                amount: number;
                dueDate: Date;
                paidDate: Date | null;
                status: import(".prisma/client").$Enums.FeeStatus;
                paymentMode: string | null;
                notes: string | null;
                createdAt: Date;
                updatedAt: Date;
            })[];
        };
        deposits: {
            total: number;
            count: number;
        };
    }>;
    getMonthly(month: string, year: string): Promise<{
        fees: ({
            student: {
                name: string;
                mobile: string;
                room: {
                    roomNumber: string;
                    floor: number;
                };
            };
        } & {
            id: string;
            studentId: string;
            month: number;
            year: number;
            amount: number;
            dueDate: Date;
            paidDate: Date | null;
            status: import(".prisma/client").$Enums.FeeStatus;
            paymentMode: string | null;
            notes: string | null;
            createdAt: Date;
            updatedAt: Date;
        })[];
        summary: {
            total: number;
            paid: number;
            pending: number;
            collectedAmount: number;
            pendingAmount: number;
        };
    }>;
    getPending(): Promise<({
        student: {
            name: string;
            mobile: string;
            room: {
                roomNumber: string;
            };
        };
    } & {
        id: string;
        studentId: string;
        month: number;
        year: number;
        amount: number;
        dueDate: Date;
        paidDate: Date | null;
        status: import(".prisma/client").$Enums.FeeStatus;
        paymentMode: string | null;
        notes: string | null;
        createdAt: Date;
        updatedAt: Date;
    })[]>;
    getRevenue(year: string): Promise<any[]>;
    getStudentFees(id: string): Promise<{
        id: string;
        studentId: string;
        month: number;
        year: number;
        amount: number;
        dueDate: Date;
        paidDate: Date | null;
        status: import(".prisma/client").$Enums.FeeStatus;
        paymentMode: string | null;
        notes: string | null;
        createdAt: Date;
        updatedAt: Date;
    }[]>;
    markOverdue(): Promise<{
        updated: number;
    }>;
}
