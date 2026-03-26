"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const path_1 = require("path");
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.useGlobalPipes(new common_1.ValidationPipe({ whitelist: true, transform: true }));
    app.enableCors({ origin: '*' });
    app.setGlobalPrefix('api');
    app.useStaticAssets((0, path_1.join)(__dirname, '..', 'uploads'), { prefix: '/uploads' });
    const port = process.env.PORT || 3000;
    await app.listen(port, '0.0.0.0');
    console.log(`PG Hostel API running on port ${port}`);
}
bootstrap();
//# sourceMappingURL=main.js.map