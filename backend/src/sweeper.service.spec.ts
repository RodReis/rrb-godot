import type { AppConfig } from './config';
import type { MatchesService } from './matches/matches.service';
import type { QueueService } from './matchmaking/queue.service';
import { SweeperService } from './sweeper.service';

describe('SweeperService', () => {
  let matches: { sweep: jest.Mock };
  let queue: { sweep: jest.Mock };

  function build(intervalMs: number): SweeperService {
    return new SweeperService(
      matches as unknown as MatchesService,
      queue as unknown as QueueService,
      { SWEEP_INTERVAL_MS: intervalMs } as AppConfig,
    );
  }

  beforeEach(() => {
    jest.useFakeTimers();
    matches = { sweep: jest.fn().mockResolvedValue(undefined) };
    queue = { sweep: jest.fn().mockResolvedValue(undefined) };
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('tick varre as partidas e depois a fila (liberar vaga antes de parear)', async () => {
    const order: string[] = [];
    matches.sweep.mockImplementation(async () => void order.push('matches'));
    queue.sweep.mockImplementation(async () => void order.push('queue'));

    await build(0).tick();

    expect(order).toEqual(['matches', 'queue']);
  });

  it('erro numa varredura não escapa nem impede a outra', async () => {
    matches.sweep.mockRejectedValueOnce(new Error('banco caiu'));

    await expect(build(0).tick()).resolves.toBeUndefined();

    expect(queue.sweep).toHaveBeenCalledTimes(1);
  });

  it('tick em andamento não é reentrado (daemon lento não empilha varreduras)', async () => {
    let release: () => void = () => undefined;
    matches.sweep.mockReturnValueOnce(new Promise<void>((resolve) => (release = resolve)));
    const sweeper = build(0);

    const first = sweeper.tick();
    await sweeper.tick(); // ignorado
    release();
    await first;

    expect(matches.sweep).toHaveBeenCalledTimes(1);
    await sweeper.tick(); // liberado depois que o primeiro terminou
    expect(matches.sweep).toHaveBeenCalledTimes(2);
  });

  it('SWEEP_INTERVAL_MS > 0 agenda o tick periódico e o shutdown para o timer', async () => {
    const sweeper = build(2_000);

    sweeper.onApplicationBootstrap();
    await jest.advanceTimersByTimeAsync(6_000);
    expect(matches.sweep).toHaveBeenCalledTimes(3);

    sweeper.onApplicationShutdown();
    await jest.advanceTimersByTimeAsync(6_000);
    expect(matches.sweep).toHaveBeenCalledTimes(3);
  });

  it('SWEEP_INTERVAL_MS = 0 não agenda nada', async () => {
    build(0).onApplicationBootstrap();

    await jest.advanceTimersByTimeAsync(60_000);

    expect(matches.sweep).not.toHaveBeenCalled();
  });
});
