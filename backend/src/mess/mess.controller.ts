import { Controller, Get, Post, Put, Body, Query, UseGuards } from '@nestjs/common';
import { MessService } from './mess.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('mess')
export class MessController {
  constructor(private messService: MessService) {}

  @Get('menu')
  getMenu(@Query('weekOf') weekOf: string) { return this.messService.getWeekMenu(weekOf); }

  @Roles('ADMIN')
  @Post('menu')
  upsertMenu(@Body() data: any) { return this.messService.upsertDayMenu(data); }

  @Roles('ADMIN')
  @Post('generate-fees')
  generateFees(@Body() body: { month: number; year: number; amount: number }) {
    return this.messService.generateMonthlyMessFees(body.month, body.year, body.amount);
  }

  @Roles('ADMIN')
  @Post('payment')
  recordPayment(@Body() body: { studentId: string; month: number; year: number }) {
    return this.messService.recordMessPayment(body.studentId, body.month, body.year);
  }

  @Get('fees')
  getMonthlyFees(@Query('month') month: string, @Query('year') year: string) {
    return this.messService.getMonthlyMessFees(parseInt(month), parseInt(year));
  }
}
