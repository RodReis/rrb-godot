import heroesJson from "./data/heroes.json";
import historiaJson from "./data/historia.json";
import capturasJson from "./data/capturas.json";
import roadmapJson from "./data/roadmap.json";

export type Skill = { key: "Q" | "E" | "R"; name: string; description: string; icon: string };
export type Hero = { id: string; name: string; role: string; weapon: string; portrait: string; summary: string; skills: Skill[] };
export type Faixa = { de: number; ate: number; rotulo: string; curto?: string; detalhe: string; cor: "gold" | "red" | "purple" };
export type Captura = { arquivo: string; legenda: string; tipo: string; mvp: string };
export type Mvp = {
  id: string; entrega: string; estado: "concluido" | "andamento" | "planejado";
  entregues: number; total: number; titulo: string; pergunta: string;
};
type Historia = {
  projeto: { tagline: string; pitch: string[]; release_url?: string };
  partida: { titulo: string; duracao_total_s: number; faixas: Faixa[]; marcos: { t: number; rotulo: string }[]; regras: string[] };
  pilares: { titulo: string; itens: { nome: string; papel: string; texto: string }[] }[];
  creditos: string[];
};

export const heroes = heroesJson as Hero[];
export const historia = historiaJson as Historia;
export const capturas = capturasJson as Captura[];
export const roadmap = roadmapJson as Mvp[];

export const REPO_URL = "https://github.com/RodReis/rrb-godot";
export const RELEASES_URL = historia.projeto.release_url ?? `${REPO_URL}/releases`;
export const HAS_RELEASE = Boolean(historia.projeto.release_url);
export const img = (file: string) => `${import.meta.env.BASE_URL}img/${file}`;
export const icon = (file: string) => `${import.meta.env.BASE_URL}icons/${file}`;
