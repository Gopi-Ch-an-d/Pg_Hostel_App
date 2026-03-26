import { ConfigService } from '@nestjs/config';
export declare class WhatsAppService {
    private config;
    private readonly logger;
    private readonly instanceId;
    private readonly token;
    private readonly baseUrl;
    constructor(config: ConfigService);
    private formatNumber;
    sendMessage(toMobile: string, message: string): Promise<{
        success: boolean;
        id?: string;
        error?: string;
    }>;
    sendBulk(mobiles: string[], message: string): Promise<{
        sent: number;
        failed: number;
        errors: string[];
    }>;
    buildFeeReminderMessage(studentName: string, amount: number, month: string, roomNumber: string): string;
    buildGeneralMessage(title: string, body: string): string;
    buildWelcomeMessage(studentName: string, roomNumber: string, rent: number): string;
    testConnection(): Promise<{
        connected: boolean;
        status?: string;
        error?: string;
    }>;
}
