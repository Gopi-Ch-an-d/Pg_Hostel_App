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
exports.FeesController = void 0;
const common_1 = require("@nestjs/common");
const fees_service_1 = require("./fees.service");
const create_fee_dto_1 = require("./dto/create-fee.dto");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/roles.guard");
const roles_decorator_1 = require("../auth/roles.decorator");
let FeesController = class FeesController {
    constructor(feesService) {
        this.feesService = feesService;
    }
    generate(body) {
        return this.feesService.generateMonthlyFees(body.month, body.year);
    }
    incrementFees(body) {
        return this.feesService.incrementFees(body.percentage, body.effectiveMonth, body.effectiveYear);
    }
    recordPayment(dto) {
        return this.feesService.recordPayment(dto);
    }
    getSummary() {
        return this.feesService.getSummary();
    }
    getMonthly(month, year) {
        return this.feesService.getMonthlyFees(parseInt(month), parseInt(year));
    }
    getPending() {
        return this.feesService.getPendingFees();
    }
    getRevenue(year) {
        return this.feesService.getRevenueStats(parseInt(year));
    }
    getStudentFees(id) {
        return this.feesService.getStudentFees(id);
    }
    markOverdue() {
        return this.feesService.markOverdue();
    }
};
exports.FeesController = FeesController;
__decorate([
    (0, roles_decorator_1.Roles)('ADMIN'),
    (0, common_1.Post)('generate'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "generate", null);
__decorate([
    (0, roles_decorator_1.Roles)('ADMIN'),
    (0, common_1.Post)('increment'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "incrementFees", null);
__decorate([
    (0, roles_decorator_1.Roles)('ADMIN'),
    (0, common_1.Post)('payment'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_fee_dto_1.RecordPaymentDto]),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "recordPayment", null);
__decorate([
    (0, common_1.Get)('summary'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "getSummary", null);
__decorate([
    (0, common_1.Get)('monthly'),
    __param(0, (0, common_1.Query)('month')),
    __param(1, (0, common_1.Query)('year')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "getMonthly", null);
__decorate([
    (0, common_1.Get)('pending'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "getPending", null);
__decorate([
    (0, common_1.Get)('revenue/:year'),
    __param(0, (0, common_1.Param)('year')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "getRevenue", null);
__decorate([
    (0, common_1.Get)('student/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "getStudentFees", null);
__decorate([
    (0, roles_decorator_1.Roles)('ADMIN'),
    (0, common_1.Post)('mark-overdue'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], FeesController.prototype, "markOverdue", null);
exports.FeesController = FeesController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)('fees'),
    __metadata("design:paramtypes", [fees_service_1.FeesService])
], FeesController);
//# sourceMappingURL=fees.controller.js.map