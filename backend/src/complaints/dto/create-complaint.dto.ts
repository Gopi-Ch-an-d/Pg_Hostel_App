import { IsString, IsEnum, IsOptional } from 'class-validator';

export class CreateComplaintDto {
  @IsString() studentId: string;
  @IsEnum(['WATER','ELECTRICITY','WIFI','CLEANLINESS','OTHER']) type: string;
  @IsString() description: string;
}

export class UpdateComplaintDto {
  @IsEnum(['PENDING','IN_PROGRESS','RESOLVED']) status: string;
  @IsOptional() @IsString() adminNotes?: string;
}
