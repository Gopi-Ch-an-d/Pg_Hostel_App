import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { StudentsModule } from './students/students.module';
import { RoomsModule } from './rooms/rooms.module';
import { FeesModule } from './fees/fees.module';
import { ComplaintsModule } from './complaints/complaints.module';
import { NotificationsModule } from './notifications/notifications.module';
import { InventoryModule } from './inventory/inventory.module';
import { MessModule } from './mess/mess.module';
import { DashboardModule } from './dashboard/dashboard.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    StudentsModule,
    RoomsModule,
    FeesModule,
    ComplaintsModule,
    NotificationsModule,
    InventoryModule,
    MessModule,
    DashboardModule,
  ],
})
export class AppModule {}
