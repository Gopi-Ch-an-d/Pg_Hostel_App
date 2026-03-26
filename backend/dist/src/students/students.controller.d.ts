import { StudentsService } from './students.service';
import { CreateStudentDto } from './dto/create-student.dto';
import { UpdateStudentDto } from './dto/update-student.dto';
export declare class StudentsController {
    private studentsService;
    constructor(studentsService: StudentsService);
    create(dto: CreateStudentDto): Promise<any>;
    findAll(query: any): Promise<{
        data: ({
            room: {
                id: string;
                monthlyRent: number;
                createdAt: Date;
                updatedAt: Date;
                status: import(".prisma/client").$Enums.RoomStatus;
                roomNumber: string;
                floor: number;
                capacity: number;
                occupiedBeds: number;
            };
            fees: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                studentId: string;
                month: number;
                year: number;
                amount: number;
                dueDate: Date;
                paidDate: Date | null;
                status: import(".prisma/client").$Enums.FeeStatus;
                paymentMode: string | null;
                notes: string | null;
            }[];
        } & {
            id: string;
            name: string;
            mobile: string;
            aadhaar: string | null;
            address: string;
            roomId: string;
            joiningDate: Date;
            deposit: number;
            monthlyRent: number;
            idProofUrl: string | null;
            vehicleNumber: string | null;
            vehicleType: string | null;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
        })[];
        total: number;
        page: number;
        limit: number;
    }>;
    getAvailableRooms(): Promise<({
        students: {
            id: string;
            name: string;
        }[];
    } & {
        id: string;
        monthlyRent: number;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.RoomStatus;
        roomNumber: string;
        floor: number;
        capacity: number;
        occupiedBeds: number;
    })[]>;
    getMinimal(): Promise<{
        id: string;
        name: string;
    }[]>;
    findOne(id: string): Promise<{
        room: {
            id: string;
            monthlyRent: number;
            createdAt: Date;
            updatedAt: Date;
            status: import(".prisma/client").$Enums.RoomStatus;
            roomNumber: string;
            floor: number;
            capacity: number;
            occupiedBeds: number;
        };
        fees: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            studentId: string;
            month: number;
            year: number;
            amount: number;
            dueDate: Date;
            paidDate: Date | null;
            status: import(".prisma/client").$Enums.FeeStatus;
            paymentMode: string | null;
            notes: string | null;
        }[];
        complaints: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            studentId: string;
            status: import(".prisma/client").$Enums.ComplaintStatus;
            type: import(".prisma/client").$Enums.ComplaintType;
            description: string;
            resolvedAt: Date | null;
            adminNotes: string | null;
        }[];
        messPayments: {
            id: string;
            createdAt: Date;
            studentId: string;
            month: number;
            year: number;
            amount: number;
            paidDate: Date | null;
            status: import(".prisma/client").$Enums.FeeStatus;
        }[];
    } & {
        id: string;
        name: string;
        mobile: string;
        aadhaar: string | null;
        address: string;
        roomId: string;
        joiningDate: Date;
        deposit: number;
        monthlyRent: number;
        idProofUrl: string | null;
        vehicleNumber: string | null;
        vehicleType: string | null;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
    update(id: string, dto: UpdateStudentDto): Promise<{
        room: {
            id: string;
            monthlyRent: number;
            createdAt: Date;
            updatedAt: Date;
            status: import(".prisma/client").$Enums.RoomStatus;
            roomNumber: string;
            floor: number;
            capacity: number;
            occupiedBeds: number;
        };
    } & {
        id: string;
        name: string;
        mobile: string;
        aadhaar: string | null;
        address: string;
        roomId: string;
        joiningDate: Date;
        deposit: number;
        monthlyRent: number;
        idProofUrl: string | null;
        vehicleNumber: string | null;
        vehicleType: string | null;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
    remove(id: string): Promise<{
        message: string;
    }>;
    uploadId(id: string, file: Express.Multer.File): Promise<{
        id: string;
        name: string;
        mobile: string;
        aadhaar: string | null;
        address: string;
        roomId: string;
        joiningDate: Date;
        deposit: number;
        monthlyRent: number;
        idProofUrl: string | null;
        vehicleNumber: string | null;
        vehicleType: string | null;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
}
