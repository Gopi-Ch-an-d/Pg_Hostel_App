import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { WhatsAppService } from './whatsapp.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(
    private notificationsService: NotificationsService,
    private whatsappService: WhatsAppService,
  ) {}

  @Roles('ADMIN')
  @Post()
  create(@Body() dto: CreateNotificationDto) {
    return this.notificationsService.create(dto);
  }

  @Get()
  findAll(@Query() query: any) {
    return this.notificationsService.findAll(query);
  }

  // ── Test WhatsApp connection ───────────────────────────────────────────────
  @Roles('ADMIN')
  @Get('whatsapp/test')
  testWhatsApp() {
    return this.whatsappService.testConnection();
  }

  // ── Send to single student ────────────────────────────────────────────────
  @Roles('ADMIN')
  @Post('whatsapp/student/:id')
  sendToStudent(
    @Param('id') id: string,
    @Body() body: { message: string },
  ) {
    return this.notificationsService.sendWhatsAppToStudent(id, body.message);
  }

  // ── Bulk send ─────────────────────────────────────────────────────────────
  @Roles('ADMIN')
  @Post('whatsapp/bulk')
  sendBulk(@Body() dto: {
    message: string;
    title?: string;
    targetAll?: boolean;
    floor?: number;
    onlyPending?: boolean;
  }) {
    return this.notificationsService.sendBulkWhatsApp(dto);
  }

  // ── Fee reminders ─────────────────────────────────────────────────────────
  @Roles('ADMIN')
  @Post('whatsapp/fee-reminders')
  sendFeeReminders() {
    return this.notificationsService.sendFeeReminders();
  }

  @Put(':id/read')
  markRead(@Param('id') id: string) {
    return this.notificationsService.markRead(id);
  }

  @Put('mark-all-read')
  markAllRead() {
    return this.notificationsService.markAllRead();
  }
}