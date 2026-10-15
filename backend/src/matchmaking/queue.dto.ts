import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

/** `MatchAssignment{host, port, token}` (ARCHITECTURE-LAUNCHER §3.3): o Launcher abre `game.exe --connect=host:port --token=...`. */
const MatchAssignmentSchema = z.object({
  host: z.string(),
  port: z.number().int(),
  token: z.string(),
});
export class MatchAssignmentDto extends createZodDto(MatchAssignmentSchema) {}

const QueueTicketSchema = z.object({
  id: z.uuid(),
  status: z.literal('searching'),
  createdAt: z.iso.datetime(),
});
export class QueueTicketDto extends createZodDto(QueueTicketSchema) {}
export type QueueTicketBody = z.infer<typeof QueueTicketSchema>;

/** `matchId` vem em `matched` (para o `abandon`); `assignment`, enquanto a partida existe. */
const TicketStatusSchema = z.object({
  status: z.enum(['searching', 'matched', 'cancelled']),
  elapsedS: z.number().int().min(0),
  matchId: z.uuid().optional(),
  assignment: MatchAssignmentSchema.optional(),
});
export class TicketStatusDto extends createZodDto(TicketStatusSchema) {}
