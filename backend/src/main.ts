import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { join } from 'path';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.enableCors({ origin: '*' });
  app.setGlobalPrefix('api');

  // Serve uploaded files
  app.useStaticAssets(join(__dirname, '..', 'uploads'), { prefix: '/uploads' });

  const port = process.env.PORT || 3000;

  await app.listen(port, '0.0.0.0'); // ✅ FIXED

  console.log(`PG Hostel API running on port ${port}`);
}
bootstrap();
