import { Mutex } from './mutex';

describe('Mutex', () => {
  it('executa as tarefas uma por vez, na ordem de chegada', async () => {
    const mutex = new Mutex();
    const events: string[] = [];
    const task = (name: string, delayMs: number) => async (): Promise<string> => {
      events.push(`${name}:inicio`);
      await new Promise((resolve) => setTimeout(resolve, delayMs));
      events.push(`${name}:fim`);
      return name;
    };

    const results = await Promise.all([mutex.run(task('a', 20)), mutex.run(task('b', 1)), mutex.run(task('c', 1))]);

    expect(results).toEqual(['a', 'b', 'c']);
    expect(events).toEqual(['a:inicio', 'a:fim', 'b:inicio', 'b:fim', 'c:inicio', 'c:fim']);
  });

  it('tarefa que falha rejeita só para quem a chamou e não trava a fila', async () => {
    const mutex = new Mutex();

    const failed = mutex.run(async () => {
      throw new Error('falhou');
    });
    const next = mutex.run(async () => 'ok');

    await expect(failed).rejects.toThrow('falhou');
    await expect(next).resolves.toBe('ok');
  });
});
