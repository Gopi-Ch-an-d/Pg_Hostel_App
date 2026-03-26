import { IsString, IsEnum, IsOptional, IsBoolean, IsInt } from 'class-validator';

export class CreateNotificationDto {
  @IsString() title: string;
  @IsString() message: string;
  @IsOptional() @IsEnum(['FEE_REMINDER','ANNOUNCEMENT','COMPLAINT_UPDATE','GENERAL']) type?: string;
  @IsOptional() @IsBoolean() targetAll?: boolean;
  @IsOptional() @IsString() roomId?: string;
  @IsOptional() @IsInt() floor?: number;
}
