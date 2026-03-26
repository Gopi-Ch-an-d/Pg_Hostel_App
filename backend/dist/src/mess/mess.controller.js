"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessController = void 0;
const common_1 = require("@nestjs/common");
const mess_service_1 = require("./mess.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/roles.guard");
const roles_decorator_1 = require("../auth/roles.decorator");
let MessController = class MessController {
    constructor(messService) {
        this.messService = messService;
    }
    getMenu(weekOf) { return this.messService.getWeekMenu(weekOf); }
    upsertMenu(data) { return this.messService.upsertDayMenu(data); }
    generateFees(body) {
        return this.messService.generateMonthlyMessFees(body.month, body.year, body.amount);
    }
    recordPayment(body) {
        return this.messService.recordMessPayment(body.studentId, body.month, body.year);
    }
    getMonthlyFees(month, year) {
        return this.messService.getMonthlyMessFees(parseInt(month), parseInt(year));
    }
};
exports.MessController = MessController;
__decorate([
    (0, common_1.Get)('menu'),
    __param(0, (0, common_1.Query)('weekOf')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MessController.prototype, "getMenu", null);
__decorate([
    (0, roles_decorator_1.Roles)('ADMIN'),
    (0, common_1.Post)('menu'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MessController.prototype, "upsertMenu", null);
__decorate([
    (0, roles_decorator_1.Roles)('ADMIN'),
    (0, common_1.Post)('generate-fees'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MessController.prototype, "generateFees", null);
__decorate([
    (0, roles_decorator_1.Roles)('ADMIN'),
    (0, common_1.Post)('payment'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MessController.prototype, "recordPayment", null);
__decorate([
    (0, common_1.Get)('fees'),
    __param(0, (0, common_1.Query)('month')),
    __param(1, (0, common_1.Query)('year')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], MessController.prototype, "getMonthlyFees", null);
exports.MessController = MessController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)('mess'),
    __metadata("design:paramtypes", [mess_service_1.MessService])
], MessController);
//# sourceMappingURL=mess.controller.js.map