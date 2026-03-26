import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { CreateInventoryDto } from './dto/create-inventory.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('inventory')
export class InventoryController {
  constructor(private inventoryService: InventoryService) {}

  @Roles('ADMIN')
  @Post()
  create(@Body() dto: CreateInventoryDto) { return this.inventoryService.create(dto); }

  @Get()
  findAll(@Query() query: any) { return this.inventoryService.findAll(query); }

  @Get('summary')
  getSummary() { return this.inventoryService.getSummary(); }

  @Roles('ADMIN')
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: Partial<CreateInventoryDto>) { return this.inventoryService.update(id, dto); }

  @Roles('ADMIN')
  @Delete(':id')
  remove(@Param('id') id: string) { return this.inventoryService.remove(id); }
}
