import { IsString, IsInt, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreateFeeDto {
  @IsString() studentId: string;
  @IsInt() @Min(1) @Max(12) month: number;
  @IsInt() year: number;
  @IsNumber() amount: number;
  @IsString() dueDate: string;
}

export class RecordPaymentDto {
  @IsString() studentId: string;
  @IsInt() @Min(1) @Max(12) month: number;
  @IsInt() year: number;
  @IsOptional() @IsString() paymentMode?: string;
  @IsOptional() @IsString() notes?: string;
}
