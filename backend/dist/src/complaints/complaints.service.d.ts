import { PrismaService } from '../prisma/prisma.service';
import { CreateComplaintDto, UpdateComplaintDto } from './dto/create-complaint.dto';
export declare class ComplaintsService {
    private prisma;
    constructor(prisma: PrismaService);
    create(dto: CreateComplaintDto): Promise<{
        student: {
            name: string;
            room: {
                roomNumber: string;
            };
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.ComplaintStatus;
        studentId: string;
        type: import(".prisma/client").$Enums.ComplaintType;
        description: string;
        resolvedAt: Date | null;
        adminNotes: string | null;
    }>;
    findAll(query: {
        status?: string;
        type?: string;
    }): Promise<({
        student: {
            name: string;
            room: {
                roomNumber: string;
                floor: number;
            };
            mobile: string;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.ComplaintStatus;
        studentId: string;
        type: import(".prisma/client").$Enums.ComplaintType;
        description: string;
        resolvedAt: Date | null;
        adminNotes: string | null;
    })[]>;
    update(id: string, dto: UpdateComplaintDto): Promise<{
        student: {
            name: string;
            room: {
                roomNumber: string;
            };
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.ComplaintStatus;
        studentId: string;
        type: import(".prisma/client").$Enums.ComplaintType;
        description: string;
        resolvedAt: Date | null;
        adminNotes: string | null;
    }>;
    getStats(): Promise<{
        pending: number;
        inProgress: number;
        resolved: number;
        total: number;
    }>;
}
