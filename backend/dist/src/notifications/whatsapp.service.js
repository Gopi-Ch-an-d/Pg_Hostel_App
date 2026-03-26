"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var WhatsAppService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.WhatsAppService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const axios_1 = require("axios");
let WhatsAppService = WhatsAppService_1 = class WhatsAppService {
    constructor(config) {
        this.config = config;
        this.logger = new common_1.Logger(WhatsAppService_1.name);
        this.instanceId = this.config.get('ULTRAMSG_INSTANCE_ID') || 'instance166564';
        this.token = this.config.get('ULTRAMSG_TOKEN') || 'gpn2bpn122wyrj1l';
        this.baseUrl = `https://api.ultramsg.com/${this.instanceId}`;
    }
    formatNumber(mobile) {
        const digits = mobile.replace(/\D/g, '');
        let clean = digits;
        if (clean.startsWith('0'))
            clean = clean.substring(1);
        if (!clean.startsWith('91'))
            clean = `91${clean}`;
        if (clean.length > 12)
            clean = clean.substring(clean.length - 12);
        return `+${clean}`;
    }
    async sendMessage(toMobile, message) {
        try {
            const formattedTo = this.formatNumber(toMobile);
            this.logger.log(`Sending WhatsApp to: ${formattedTo}`);
            const params = new URLSearchParams({
                token: this.token,
                to: formattedTo,
                body: message,
                priority: '1',
            });
            const res = await axios_1.default.post(`${this.baseUrl}/messages/chat`, params.toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
            this.logger.log(`UltraMsg response: ${JSON.stringify(res.data)}`);
            if (res.data?.sent === 'true' || res.data?.id) {
                this.logger.log(`✅ WhatsApp sent to ${formattedTo}`);
                return { success: true, id: String(res.data.id) };
            }
            else {
                throw new Error(res.data?.error || JSON.stringify(res.data));
            }
        }
        catch (err) {
            const msg = err.response?.data?.error || err.message;
            this.logger.error(`❌ WhatsApp failed to ${toMobile}: ${msg}`);
            return { success: false, error: msg };
        }
    }
    async sendBulk(mobiles, message) {
        let sent = 0, failed = 0;
        const errors = [];
        for (const mobile of mobiles) {
            const result = await this.sendMessage(mobile, message);
            if (result.success)
                sent++;
            else {
                failed++;
                errors.push(`${mobile}: ${result.error}`);
            }
            await new Promise(r => setTimeout(r, 500));
        }
        return { sent, failed, errors };
    }
    buildFeeReminderMessage(studentName, amount, month, roomNumber) {
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
    buildGeneralMessage(title, body) {
        return `🏠 *PG Hostel*\n\n📢 *${title}*\n\n${body}\n\n— PG Management`;
    }
    buildWelcomeMessage(studentName, roomNumber, rent) {
        return `🏠 *Welcome to Our PG!* 🎉\n\nHi *${studentName}*! 👋\n\nRoom: *${roomNumber}*\nRent: *₹${rent}/month*\n\nWe hope you have a comfortable stay! 😊\n— PG Management`;
    }
    async testConnection() {
        try {
            const res = await axios_1.default.get(`${this.baseUrl}/instance/status?token=${this.token}`);
            return {
                connected: true,
                status: res.data?.instance?.status || 'connected',
            };
        }
        catch (err) {
            return { connected: false, error: err.message };
        }
    }
};
exports.WhatsAppService = WhatsAppService;
exports.WhatsAppService = WhatsAppService = WhatsAppService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], WhatsAppService);
//# sourceMappingURL=whatsapp.service.js.map