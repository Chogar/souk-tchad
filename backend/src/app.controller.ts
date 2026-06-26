import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  health() {
    return {
      status: 'ok',
      name: 'Souk Tchad API',
      version: '1.0.0',
      endpoints: {
        categories: '/api/categories',
        auth: '/api/auth',
        listings: '/api/listings',
      },
    };
  }
}
