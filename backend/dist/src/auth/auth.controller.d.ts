import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
    login(dto: LoginDto): Promise<{
        access_token: string;
        user: {
            id: string;
            name: string;
            username: string;
            role: import(".prisma/client").$Enums.Role;
        };
    }>;
    getProfile(req: any): any;
    changePassword(req: any, body: {
        oldPassword: string;
        newPassword: string;
    }): Promise<{
        message: string;
    }>;
}
