import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { SkipThrottle, ThrottlerGuard } from '@nestjs/throttler';
import { AuthTokens, AuthTokensDto, LoginDto, RefreshDto, RegisterDto } from './auth.dto';
import { AuthService } from './auth.service';

@ApiTags('auth')
@ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
@SkipThrottle({ queue: true })
@UseGuards(ThrottlerGuard)
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  @ApiCreatedResponse({ type: AuthTokensDto })
  @ApiBadRequestResponse({ description: 'WEAK_PASSWORD | PASSWORD_TOO_LONG | INVALID_EMAIL | VALIDATION_FAILED' })
  @ApiConflictResponse({ description: 'EMAIL_TAKEN' })
  register(@Body() body: RegisterDto): Promise<AuthTokens> {
    return this.auth.register(body.email, body.password);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: AuthTokensDto })
  @ApiUnauthorizedResponse({ description: 'INVALID_CREDENTIALS' })
  login(@Body() body: LoginDto): Promise<AuthTokens> {
    return this.auth.login(body.email, body.password);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: AuthTokensDto })
  @ApiUnauthorizedResponse({ description: 'INVALID_REFRESH_TOKEN' })
  refresh(@Body() body: RefreshDto): Promise<AuthTokens> {
    return this.auth.refresh(body.refreshToken);
  }
}
