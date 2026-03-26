export declare class CreateFeeDto {
    studentId: string;
    month: number;
    year: number;
    amount: number;
    dueDate: string;
}
export declare class RecordPaymentDto {
    studentId: string;
    month: number;
    year: number;
    paymentMode?: string;
    notes?: string;
}
