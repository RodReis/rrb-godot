import { Injectable } from '@nestjs/common';

/** Relógio injetável: os testes avançam o tempo (heartbeat, token vencido) sem esperar. */
export abstract class Clock {
  abstract now(): Date;
}

@Injectable()
export class SystemClock extends Clock {
  now(): Date {
    return new Date();
  }
}
