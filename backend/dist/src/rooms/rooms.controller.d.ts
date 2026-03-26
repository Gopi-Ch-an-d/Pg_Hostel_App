import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './dto/create-room.dto';
export declare class RoomsController {
    private roomsService;
    constructor(roomsService: RoomsService);
    create(dto: CreateRoomDto): Promise<{
        id: string;
        roomNumber: string;
        floor: number;
        capacity: number;
        occupiedBeds: number;
        status: import(".prisma/client").$Enums.RoomStatus;
        monthlyRent: number;
        createdAt: Date;
        updatedAt: Date;
    }>;
    findAll(query: any): Promise<({
        students: {
            id: string;
            name: string;
            mobile: string;
        }[];
    } & {
        id: string;
        roomNumber: string;
        floor: number;
        capacity: number;
        occupiedBeds: number;
        status: import(".prisma/client").$Enums.RoomStatus;
        monthlyRent: number;
        createdAt: Date;
        updatedAt: Date;
    })[]>;
    getSummary(): Promise<{
        totalRooms: number;
        occupiedRooms: number;
        availableRooms: number;
        partialRooms: number;
        totalBeds: number;
        occupiedBeds: number;
        vacantBeds: number;
    }>;
    getByFloor(): Promise<{
        floor: number;
        totalRooms: number;
        occupiedRooms: number;
        partialRooms: number;
        availableRooms: number;
        totalBeds: any;
        occupiedBeds: any;
        vacantBeds: any;
        rooms: any[];
    }[]>;
    findOne(id: string): Promise<{
        students: ({
            fees: {
                id: string;
                status: import(".prisma/client").$Enums.FeeStatus;
                createdAt: Date;
                updatedAt: Date;
                studentId: string;
                month: number;
                year: number;
                amount: number;
                dueDate: Date;
                paidDate: Date | null;
                paymentMode: string | null;
                notes: string | null;
            }[];
        } & {
            id: string;
            monthlyRent: number;
            createdAt: Date;
            updatedAt: Date;
            name: string;
            mobile: string;
            aadhaar: string | null;
            address: string;
            roomId: string;
            joiningDate: Date;
            deposit: number;
            idProofUrl: string | null;
            vehicleNumber: string | null;
            vehicleType: string | null;
            isActive: boolean;
        })[];
    } & {
        id: string;
        roomNumber: string;
        floor: number;
        capacity: number;
        occupiedBeds: number;
        status: import(".prisma/client").$Enums.RoomStatus;
        monthlyRent: number;
        createdAt: Date;
        updatedAt: Date;
    }>;
    update(id: string, dto: Partial<CreateRoomDto>): Promise<{
        id: string;
        roomNumber: string;
        floor: number;
        capacity: number;
        occupiedBeds: number;
        status: import(".prisma/client").$Enums.RoomStatus;
        monthlyRent: number;
        createdAt: Date;
        updatedAt: Date;
    }>;
    remove(id: string): Promise<{
        message: string;
    }>;
    vacate(studentId: string): Promise<{
        message: string;
    }>;
}
