import { Body, Controller, Get, HttpCode, HttpStatus, Put, Req, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthenticatedRequest } from '../common/jwt.guard';
import { JwtGuard } from '../common/jwt.guard';
import { SetNicknameDto, UserProfile, UserProfileDto } from './users.dto';
import { UsersService } from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  @ApiOkResponse({ type: UserProfileDto, description: '`nickname` nulo = falta definir (1º login)' })
  @ApiUnauthorizedResponse({ description: 'UNAUTHORIZED' })
  @ApiNotFoundResponse({ description: 'USER_NOT_FOUND' })
  me(@Req() req: AuthenticatedRequest): Promise<UserProfile> {
    return this.users.profile(req.userId);
  }

  @Put('me/nickname')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: UserProfileDto })
  @ApiBadRequestResponse({ description: 'INVALID_NICKNAME | VALIDATION_FAILED' })
  @ApiUnauthorizedResponse({ description: 'UNAUTHORIZED' })
  @ApiNotFoundResponse({ description: 'USER_NOT_FOUND' })
  @ApiConflictResponse({ description: 'NICKNAME_TAKEN | NICKNAME_ALREADY_SET' })
  setNickname(@Req() req: AuthenticatedRequest, @Body() body: SetNicknameDto): Promise<UserProfile> {
    return this.users.setNickname(req.userId, body.nickname);
  }
}
