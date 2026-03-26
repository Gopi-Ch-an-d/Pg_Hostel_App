import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class WhatsAppService {
  private readonly logger = new Logger(WhatsAppService.name);
  private readonly instanceId: string;
  private readonly token: string;
  private readonly baseUrl: string;

  constructor(private config: ConfigService) {
    this.instanceId = this.config.get('ULTRAMSG_INSTANCE_ID') || 'instance166564';
    this.token      = this.config.get('ULTRAMSG_TOKEN') || 'gpn2bpn122wyrj1l';
    this.baseUrl    = `https://api.ultramsg.com/${this.instanceId}`;
  }

  private formatNumber(mobile: string): string {
    const digits = mobile.replace(/\D/g, '');
    // Handle all cases: 10 digit, with 0, with 91, with +91
    let clean = digits;
    if (clean.startsWith('0'))  clean = clean.substring(1);       // remove leading 0
    if (!clean.startsWith('91')) clean = `91${clean}`;            // add country code
    if (clean.length > 12)      clean = clean.substring(clean.length - 12); // keep last 12
    return `+${clean}`; // UltraMsg needs +91XXXXXXXXXX format
  }

  async sendMessage(
    toMobile: string,
    message: string,
  ): Promise<{ success: boolean; id?: string; error?: string }> {
    try {
      const formattedTo = this.formatNumber(toMobile);
      this.logger.log(`Sending WhatsApp to: ${formattedTo}`);

      const params = new URLSearchParams({
        token:    this.token,
        to:       formattedTo,
        body:     message,
        priority: '1',
      });

      const res = await axios.post(
        `${this.baseUrl}/messages/chat`,
        params.toString(),
        { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
      );

      this.logger.log(`UltraMsg response: ${JSON.stringify(res.data)}`);

      if (res.data?.sent === 'true' || res.data?.id) {
        this.logger.log(`✅ WhatsApp sent to ${formattedTo}`);
        return { success: true, id: String(res.data.id) };
      } else {
        throw new Error(res.data?.error || JSON.stringify(res.data));
      }
    } catch (err) {
      const msg = err.response?.data?.error || err.message;
      this.logger.error(`❌ WhatsApp failed to ${toMobile}: ${msg}`);
      return { success: false, error: msg };
    }
  }

  async sendBulk(
    mobiles: string[],
    message: string,
  ): Promise<{ sent: number; failed: number; errors: string[] }> {
    let sent = 0, failed = 0;
    const errors: string[] = [];
    for (const mobile of mobiles) {
      const result = await this.sendMessage(mobile, message);
      if (result.success) sent++;
      else { failed++; errors.push(`${mobile}: ${result.error}`); }
      await new Promise(r => setTimeout(r, 500)); // 500ms gap
    }
    return { sent, failed, errors };
  }

  buildFeeReminderMessage(
    studentName: string,
    amount: number,
    month: string,
    roomNumber: string,
  ): string {
    return `🏠 *PG Hostel Fee Reminder*

Hi *${studentName}*! 👋

Your rent for *${month}* is pending.

📋 *Details:*
• Room: *${roomNumber}*
• Amount Due: *₹${amount}*
• Due Date: *5th of this month*

⚠️ Please pay at the earliest.

Thank you! 🙏
— PG Management`;
  }

  buildGeneralMessage(title: string, body: string): string {
    return `🏠 *PG Hostel*\n\n📢 *${title}*\n\n${body}\n\n— PG Management`;
  }

  buildWelcomeMessage(studentName: string, roomNumber: string, rent: number): string {
    return `🏠 *Welcome to Our PG!* 🎉\n\nHi *${studentName}*! 👋\n\nRoom: *${roomNumber}*\nRent: *₹${rent}/month*\n\nWe hope you have a comfortable stay! 😊\n— PG Management`;
  }

  async testConnection(): Promise<{ connected: boolean; status?: string; error?: string }> {
    try {
      const res = await axios.get(
        `${this.baseUrl}/instance/status?token=${this.token}`,
      );
      return {
        connected: true,
        status: res.data?.instance?.status || 'connected',
      };
    } catch (err) {
      return { connected: false, error: err.message };
    }
  }
}