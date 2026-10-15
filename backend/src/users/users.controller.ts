import { Controller, Get, NotFoundException, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';
import type { AuthenticatedRequest } from '../common/jwt.guard';
import { JwtGuard } from '../common/jwt.guard';
import { UsersRepository } from './users.repository';

const UserProfileSchema = z.object({ id: z.uuid(), email: z.email(), createdAt: z.iso.datetime() });
class UserProfileDto extends createZodDto(UserProfileSchema) {}
type UserProfile = z.infer<typeof UserProfileSchema>;

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersRepository) {}

  @Get('me')
  @ApiOkResponse({ type: UserProfileDto })
  @ApiUnauthorizedResponse({ description: 'UNAUTHORIZED' })
  async me(@Req() req: AuthenticatedRequest): Promise<UserProfile> {
    const user = await this.users.findById(req.userId);
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'Conta não encontrada' });
    }
    return { id: user.id, email: user.email, createdAt: user.createdAt.toISOString() };
  }
}
