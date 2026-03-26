import { IsString, IsInt, IsOptional, Min } from 'class-validator';

export class CreateInventoryDto {
  @IsString() name: string;
  @IsString() category: string;
  @IsInt() @Min(0) total: number;
  @IsInt() @Min(0) good: number;
  @IsInt() @Min(0) damaged: number;
  @IsInt() @Min(0) missing: number;
  @IsOptional() @IsString() notes?: string;
}
