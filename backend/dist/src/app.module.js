"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const prisma_module_1 = require("./prisma/prisma.module");
const auth_module_1 = require("./auth/auth.module");
const students_module_1 = require("./students/students.module");
const rooms_module_1 = require("./rooms/rooms.module");
const fees_module_1 = require("./fees/fees.module");
const complaints_module_1 = require("./complaints/complaints.module");
const notifications_module_1 = require("./notifications/notifications.module");
const inventory_module_1 = require("./inventory/inventory.module");
const mess_module_1 = require("./mess/mess.module");
const dashboard_module_1 = require("./dashboard/dashboard.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            prisma_module_1.PrismaModule,
            auth_module_1.AuthModule,
            students_module_1.StudentsModule,
            rooms_module_1.RoomsModule,
            fees_module_1.FeesModule,
            complaints_module_1.ComplaintsModule,
            notifications_module_1.NotificationsModule,
            inventory_module_1.InventoryModule,
            mess_module_1.MessModule,
            dashboard_module_1.DashboardModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map