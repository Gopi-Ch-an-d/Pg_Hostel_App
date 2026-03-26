import { NotificationsService } from './notifications.service';
import { WhatsAppService } from './whatsapp.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
export declare class NotificationsController {
    private notificationsService;
    private whatsappService;
    constructor(notificationsService: NotificationsService, whatsappService: WhatsAppService);
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
    findAll(query: any): Promise<{
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
    testWhatsApp(): Promise<{
        connected: boolean;
        status?: string;
        error?: string;
    }>;
    sendToStudent(id: string, body: {
        message: string;
    }): Promise<{
        success: boolean;
        id?: string;
        error?: string;
        student: {
            name: string;
            mobile: string;
        };
    }>;
    sendBulk(dto: {
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
}
