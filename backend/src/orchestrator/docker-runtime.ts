import { Inject, Injectable } from '@nestjs/common';
import Docker from 'dockerode';
import { APP_CONFIG } from '../common/app-config';
import type { AppConfig } from '../config';
import { ContainerRuntime } from './container-runtime';

const MANAGED_LABEL = 'rrb.gameserver';
/** Porta UDP dentro do container (`PORT` do entrypoint em infra/gameserver). */
const CONTAINER_PORT = '7000';
/** Daemon pendurado não pode segurar o mutex do orquestrador (e a fila atrás dele) para sempre. */
const DOCKER_TIMEOUT_MS = 30_000;
const PIDS_LIMIT = 512;

@Injectable()
export class DockerRuntime extends ContainerRuntime {
  // Conecta no socket padrão (DOCKER_HOST ou /var/run/docker.sock) só na primeira chamada.
  private readonly docker = new Docker({ timeout: DOCKER_TIMEOUT_MS });

  constructor(@Inject(APP_CONFIG) private readonly config: AppConfig) {
    super();
  }

  async start(hostPort: number): Promise<string> {
    const container = await this.docker.createContainer({
      Image: this.config.GAMESERVER_IMAGE,
      Labels: { [MANAGED_LABEL]: String(hostPort) },
      Env: [
        `PORT=${CONTAINER_PORT}`,
        `BACKEND_URL=${this.config.GAMESERVER_BACKEND_URL}`,
        `INTERNAL_SECRET=${this.config.INTERNAL_SECRET}`,
      ],
      ExposedPorts: { [`${CONTAINER_PORT}/udp`]: {} },
      HostConfig: {
        PortBindings: { [`${CONTAINER_PORT}/udp`]: [{ HostPort: String(hostPort) }] },
        ExtraHosts: ['host.docker.internal:host-gateway'],
        // O servidor recebe UDP da internet: sem capabilities, sem escalada e com teto de processos.
        CapDrop: ['ALL'],
        SecurityOpt: ['no-new-privileges'],
        PidsLimit: PIDS_LIMIT,
      },
    });
    try {
      await container.start();
    } catch (error) {
      // Porta ocupada etc.: o container criado e não iniciado não pode ficar para trás.
      await container.remove({ force: true }).catch(() => undefined);
      throw error;
    }
    return container.id;
  }

  async remove(containerId: string): Promise<void> {
    await this.docker.getContainer(containerId).remove({ force: true });
  }

  async removeAllManaged(): Promise<void> {
    const managed = await this.docker.listContainers({ all: true, filters: { label: [MANAGED_LABEL] } });
    // allSettled: um container que sumiu no meio (404) não impede de limpar os outros.
    await Promise.allSettled(managed.map((info) => this.remove(info.Id)));
  }
}
