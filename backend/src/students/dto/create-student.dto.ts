import { IsString, IsNotEmpty, IsNumber, IsDateString, IsOptional } from 'class-validator';

export class CreateStudentDto {
  @IsString() @IsNotEmpty() name: string;
  @IsString() @IsNotEmpty() mobile: string;
  @IsOptional() @IsString() aadhaar?: string;
  @IsString() @IsNotEmpty() roomId: string;
  @IsDateString() joiningDate: string;
  @IsNumber() deposit: number;
  @IsNumber() monthlyRent: number;
  @IsString() @IsNotEmpty() address: string;
  @IsOptional() @IsString() idProofUrl?: string;
  @IsOptional() @IsString() vehicleNumber?: string;
  @IsOptional() @IsString() vehicleType?: string;
}