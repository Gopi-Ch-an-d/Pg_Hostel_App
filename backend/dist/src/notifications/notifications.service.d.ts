import { PrismaService } from '../prisma/prisma.service';
import { WhatsAppService } from './whatsapp.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
export declare class NotificationsService {
    private prisma;
    private whatsapp;
    constructor(prisma: PrismaService, whatsapp: WhatsAppService);
    create(dto: CreateNotificationDto): Promise<{
        id: string;
        title: string;
        message: string;
        type: import(".prisma/client").$Enums.NotificationType;
        targetAll: boolean;
        roomId: string | null;
        floor: number | null;
        isRead: boolean;
        createdAt: Date;
    }>;
    findAll(query: {
        type?: string;
        unread?: string;
    }): Promise<{
        id: string;
        title: string;
        message: string;
        type: import(".prisma/client").$Enums.NotificationType;
        targetAll: boolean;
        roomId: string | null;
        floor: number | null;
        isRead: boolean;
        createdAt: Date;
    }[]>;
    markRead(id: string): Promise<{
        id: string;
        title: string;
        message: string;
        type: import(".prisma/client").$Enums.NotificationType;
        targetAll: boolean;
        roomId: string | null;
        floor: number | null;
        isRead: boolean;
        createdAt: Date;
    }>;
    markAllRead(): Promise<{
        message: string;
    }>;
    sendWhatsAppToStudent(studentId: string, message: string): Promise<{
        success: boolean;
        id?: string;
        error?: string;
        student: {
            name: string;
            mobile: string;
        };
    }>;
    sendBulkWhatsApp(dto: {
        message: string;
        title?: string;
        targetAll?: boolean;
        floor?: number;
        onlyPending?: boolean;
    }): Promise<{
        total: number;
        students: {
            name: string;
            mobile: string;
        }[];
        sent: number;
        failed: number;
        errors: string[];
    }>;
    sendFeeReminders(): Promise<{
        sent: number;
        failed: number;
        total: number;
        results: any[];
    }>;
}
