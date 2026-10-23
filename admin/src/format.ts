import type { Kpi } from './api/client';

const EMPTY = '—';
const SECONDS_PER_MINUTE = 60;
const nf = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 2 });

export function formatNumber(value: number | null): string {
  return value === null ? EMPTY : nf.format(value);
}

/** `540` vira `9 min 0 s`; nulo vira traço. */
export function formatDuration(seconds: number | null): string {
  if (seconds === null) return EMPTY;
  const total = Math.round(seconds);
  return `${Math.floor(total / SECONDS_PER_MINUTE)} min ${total % SECONDS_PER_MINUTE} s`;
}

export function formatKpiValue(kpi: Pick<Kpi, 'value' | 'unit'>): string {
  if (kpi.value === null) return EMPTY;
  switch (kpi.unit) {
    case 'ms':
      return `${formatNumber(kpi.value)} ms`;
    case 'percent':
      return `${formatNumber(kpi.value)} %`;
    case 's':
      return formatDuration(kpi.value);
    case 'count':
      return formatNumber(kpi.value);
  }
}

export function formatDateTime(iso: string | null): string {
  if (iso === null) return EMPTY;
  return new Date(iso).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'medium' });
}
