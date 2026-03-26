import { IsString, IsInt, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreateRoomDto {
  @IsString() roomNumber: string;
  @IsInt() @Min(1) floor: number;
  @IsInt() @Min(1) @Max(10) capacity: number;
  @IsNumber() monthlyRent: number;
  @IsOptional() @IsString() description?: string;
}