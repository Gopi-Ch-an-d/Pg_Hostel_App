import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ComplaintsService } from './complaints.service';
import { CreateComplaintDto, UpdateComplaintDto } from './dto/create-complaint.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('complaints')
export class ComplaintsController {
  constructor(private complaintsService: ComplaintsService) {}

  @Post()
  create(@Body() dto: CreateComplaintDto) { return this.complaintsService.create(dto); }

  @Get()
  findAll(@Query() query: any) { return this.complaintsService.findAll(query); }

  @Get('stats')
  getStats() { return this.complaintsService.getStats(); }

  @Roles('ADMIN', 'SUPERVISOR')
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateComplaintDto) { return this.complaintsService.update(id, dto); }
}
