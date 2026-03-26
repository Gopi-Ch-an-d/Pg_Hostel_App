import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { FeesService } from './fees.service';
import { RecordPaymentDto } from './dto/create-fee.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('fees')
export class FeesController {
  constructor(private feesService: FeesService) {}

  @Roles('ADMIN')
  @Post('generate')
  generate(@Body() body: { month: number; year: number }) {
    return this.feesService.generateMonthlyFees(body.month, body.year);
  }

  @Roles('ADMIN')
  @Post('increment')
  incrementFees(@Body() body: { percentage: number; effectiveMonth: number; effectiveYear: number }) {
    return this.feesService.incrementFees(body.percentage, body.effectiveMonth, body.effectiveYear);
  }

  @Roles('ADMIN')
  @Post('payment')
  recordPayment(@Body() dto: RecordPaymentDto) {
    return this.feesService.recordPayment(dto);
  }

  @Get('summary')
  getSummary() {
    return this.feesService.getSummary();
  }

  @Get('monthly')
  getMonthly(@Query('month') month: string, @Query('year') year: string) {
    return this.feesService.getMonthlyFees(parseInt(month), parseInt(year));
  }

  @Get('pending')
  getPending() {
    return this.feesService.getPendingFees();
  }

  @Get('revenue/:year')
  getRevenue(@Param('year') year: string) {
    return this.feesService.getRevenueStats(parseInt(year));
  }

  @Get('student/:id')
  getStudentFees(@Param('id') id: string) {
    return this.feesService.getStudentFees(id);
  }

  @Roles('ADMIN')
  @Post('mark-overdue')
  markOverdue() {
    return this.feesService.markOverdue();
  }
}