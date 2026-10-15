import { randomUUID } from 'node:crypto';
import type { Match, QueueTicket } from '../../drizzle/schema';
import { Clock } from '../../src/common/clock';
import { MatchesRepository, MatchResult, NewMatch } from '../../src/matches/matches.repository';
import { QueueRepository } from '../../src/matchmaking/queue.repository';
import { ContainerRuntime } from '../../src/orchestrator/container-runtime';

export class FakeClock extends Clock {
  constructor(private current = new Date('2026-01-01T12:00:00.000Z')) {
    super();
  }

  now(): Date {
    return new Date(this.current);
  }

  advance(ms: number): void {
    this.current = new Date(this.current.getTime() + ms);
  }
}

/** "Docker mock": registra o que o orquestrador pediu, sem tocar no Docker. */
export class FakeContainerRuntime extends ContainerRuntime {
  readonly running = new Map<string, number>();
  readonly started: number[] = [];
  readonly removed: string[] = [];
  removeAllCalls = 0;
  failStart = false;
  /** Portas em que `start` falha (ex.: ocupada por container que não saiu). */
  readonly failPorts = new Set<number>();
  private counter = 0;

  async start(hostPort: number): Promise<string> {
    if (this.failStart || this.failPorts.has(hostPort)) throw new Error('docker indisponível');
    const id = `container-${++this.counter}`;
    this.running.set(id, hostPort);
    this.started.push(hostPort);
    return id;
  }

  async remove(containerId: string): Promise<void> {
    this.running.delete(containerId);
    this.removed.push(containerId);
  }

  async removeAllManaged(): Promise<void> {
    this.removeAllCalls++;
    this.running.clear();
  }
}

export class InMemoryMatchesRepository extends MatchesRepository {
  readonly rows = new Map<string, Match>();
  readonly players = new Map<string, Map<string, Record<string, unknown>>>();
  private readonly tokenHashes = new Map<string, string>();

  async createAssigned(match: NewMatch): Promise<void> {
    this.rows.set(match.id, {
      id: match.id,
      status: 'assigned',
      serverHost: match.serverHost,
      serverPort: match.serverPort,
      seed: match.seed,
      createdAt: match.now,
      startedAt: null,
      lastHeartbeatAt: null,
      endedAt: null,
      winnerUserId: null,
      endReason: null,
      durationS: null,
    });
    this.players.set(match.id, new Map(match.players.map(({ userId }) => [userId, {}])));
    for (const { userId, tokenHash } of match.players) this.tokenHashes.set(`${match.id}:${userId}`, tokenHash);
  }

  async findById(id: string): Promise<Match | null> {
    return this.rows.get(id) ?? null;
  }

  async playerIds(matchId: string): Promise<string[]> {
    return [...(this.players.get(matchId)?.keys() ?? [])];
  }

  async playerTokenHash(matchId: string, userId: string): Promise<string | null> {
    return this.tokenHashes.get(`${matchId}:${userId}`) ?? null;
  }

  async userHasActiveMatch(userId: string): Promise<boolean> {
    return [...this.rows.values()].some(
      (m) => (m.status === 'assigned' || m.status === 'running') && this.players.get(m.id)?.has(userId),
    );
  }

  async markRunning(id: string, now: Date): Promise<boolean> {
    return this.transition(id, ['assigned'], { status: 'running', startedAt: now, lastHeartbeatAt: now });
  }

  async touchHeartbeat(id: string, now: Date): Promise<boolean> {
    return this.transition(id, ['running'], { lastHeartbeatAt: now });
  }

  async finish(id: string, result: MatchResult, now: Date): Promise<boolean> {
    const ok = this.transition(id, ['running'], {
      status: 'finished',
      endedAt: now,
      winnerUserId: result.winnerUserId,
      endReason: result.endReason,
      durationS: result.durationS,
    });
    if (ok) {
      for (const { userId, ...stats } of result.players) this.players.get(id)?.set(userId, stats);
    }
    return ok;
  }

  async abort(id: string, reason: string, now: Date): Promise<boolean> {
    return this.transition(id, ['assigned', 'running'], { status: 'aborted', endedAt: now, endReason: reason });
  }

  async findAssignedBefore(createdBefore: Date): Promise<Match[]> {
    return [...this.rows.values()].filter((m) => m.status === 'assigned' && m.createdAt < createdBefore);
  }

  async findRunningWithHeartbeatBefore(heartbeatBefore: Date): Promise<Match[]> {
    return [...this.rows.values()].filter(
      (m) => m.status === 'running' && m.lastHeartbeatAt !== null && m.lastHeartbeatAt < heartbeatBefore,
    );
  }

  async abortAllActive(reason: string, now: Date): Promise<number> {
    let count = 0;
    for (const id of this.rows.keys()) {
      if (this.transition(id, ['assigned', 'running'], { status: 'aborted', endedAt: now, endReason: reason })) {
        count++;
      }
    }
    return count;
  }

  private transition(id: string, from: Match['status'][], patch: Partial<Match>): boolean {
    const match = this.rows.get(id);
    if (!match || !from.includes(match.status)) return false;
    this.rows.set(id, { ...match, ...patch });
    return true;
  }
}

export class InMemoryQueueRepository extends QueueRepository {
  readonly rows: QueueTicket[] = [];
  private seq = 0;

  async create(userId: string, now: Date): Promise<QueueTicket | null> {
    if (this.rows.some((t) => t.userId === userId && t.status === 'waiting')) return null;
    const ticket: QueueTicket = {
      id: randomUUID(),
      seq: ++this.seq,
      userId,
      status: 'waiting',
      createdAt: now,
      lastSeenAt: now,
      matchId: null,
    };
    this.rows.push(ticket);
    return ticket;
  }

  async findById(id: string): Promise<QueueTicket | null> {
    return this.rows.find((t) => t.id === id) ?? null;
  }

  async touch(id: string, now: Date): Promise<void> {
    this.patchWaiting([id], { lastSeenAt: now });
  }

  async cancel(id: string): Promise<boolean> {
    return this.patchWaiting([id], { status: 'cancelled' }) === 1;
  }

  async listWaiting(limit: number): Promise<QueueTicket[]> {
    return this.rows
      .filter((t) => t.status === 'waiting')
      .sort((a, b) => a.seq - b.seq)
      .slice(0, limit);
  }

  async markMatched(ids: string[], matchId: string): Promise<boolean> {
    return this.patchWaiting(ids, { status: 'matched', matchId }) === ids.length;
  }

  async expireStale(lastSeenBefore: Date): Promise<number> {
    const stale = this.rows.filter((t) => t.status === 'waiting' && t.lastSeenAt < lastSeenBefore);
    return this.patchWaiting(
      stale.map((t) => t.id),
      { status: 'expired' },
    );
  }

  private patchWaiting(ids: string[], patch: Partial<QueueTicket>): number {
    let count = 0;
    for (const ticket of this.rows) {
      if (ids.includes(ticket.id) && ticket.status === 'waiting') {
        Object.assign(ticket, patch);
        count++;
      }
    }
    return count;
  }
}
