import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('rooms')
export class RoomsController {
  constructor(private roomsService: RoomsService) {}

  @Roles('ADMIN', 'SUPERVISOR')
  @Post()
  create(@Body() dto: CreateRoomDto) { return this.roomsService.create(dto); }

  @Get()
  findAll(@Query() query: any) { return this.roomsService.findAll(query); }

  @Get('summary')
  getSummary() { return this.roomsService.getSummary(); }

  @Get('by-floor')
  getByFloor() { return this.roomsService.getByFloor(); }

  @Get(':id')
  findOne(@Param('id') id: string) { return this.roomsService.findOne(id); }

  @Roles('ADMIN', 'SUPERVISOR')
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: Partial<CreateRoomDto>) {
    return this.roomsService.update(id, dto);
  }

  // ADMIN ONLY - delete
  @Roles('ADMIN')
  @Delete(':id')
  remove(@Param('id') id: string) { return this.roomsService.remove(id); }

  @Roles('ADMIN', 'SUPERVISOR')
  @Post(':studentId/vacate')
  vacate(@Param('studentId') studentId: string) {
    return this.roomsService.vacateStudent(studentId);
  }
}