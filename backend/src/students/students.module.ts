import { Module } from '@nestjs/common';
import { StudentsController } from './students.controller';
import { StudentsService } from './students.service';
import { WhatsAppService } from '../notifications/whatsapp.service';

@Module({
  controllers: [StudentsController],
  providers: [StudentsService, WhatsAppService],
  exports: [StudentsService],
})
export class StudentsModule {}