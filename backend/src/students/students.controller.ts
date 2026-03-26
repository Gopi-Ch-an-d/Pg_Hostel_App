import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, UseInterceptors, UploadedFile } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { StudentsService } from './students.service';
import { CreateStudentDto } from './dto/create-student.dto';
import { UpdateStudentDto } from './dto/update-student.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('students')
export class StudentsController {
  constructor(private studentsService: StudentsService) {}

  @Roles('ADMIN', 'SUPERVISOR')
  @Post()
  create(@Body() dto: CreateStudentDto) { return this.studentsService.create(dto); }

  @Get()
  findAll(@Query() query: any) { return this.studentsService.findAll(query); }

  // ✅ Available rooms for add student form
  @Get('available-rooms')
  getAvailableRooms() { return this.studentsService.getAvailableRooms(); }

  @Get('minimal')
  getMinimal() { return this.studentsService.getMinimal(); }

  @Get(':id')
  findOne(@Param('id') id: string) { return this.studentsService.findOne(id); }

  @Roles('ADMIN', 'SUPERVISOR')
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateStudentDto) {
    return this.studentsService.update(id, dto);
  }

  @Roles('ADMIN')
  @Delete(':id')
  remove(@Param('id') id: string) { return this.studentsService.remove(id); }

  @Roles('ADMIN', 'SUPERVISOR')
  @Post(':id/upload-id')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => cb(null, `${Date.now()}${extname(file.originalname)}`),
    }),
  }))
  uploadId(@Param('id') id: string, @UploadedFile() file: Express.Multer.File) {
    return this.studentsService.uploadIdProof(id, file.filename);
  }
}