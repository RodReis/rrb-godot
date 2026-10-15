/** Fronteira com o Docker: o e2e troca por um dublê (critério de aceite do F22: "Docker mock"). */
export abstract class ContainerRuntime {
  /** Cria e inicia um game server publicando `hostPort` (UDP). Devolve o id do container. */
  abstract start(hostPort: number): Promise<string>;
  abstract remove(containerId: string): Promise<void>;
  /** Remove todo container criado por este backend (boot limpo). */
  abstract removeAllManaged(): Promise<void>;
}
