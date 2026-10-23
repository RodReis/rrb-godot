import { describe, expect, it } from 'vitest';
import { formatDuration, formatKpiValue } from './format';

describe('format', () => {
  it.each([
    [{ value: 66.36, unit: 'ms' as const }, '66,36 ms'],
    [{ value: 27.27, unit: 'percent' as const }, '27,27 %'],
    [{ value: 540, unit: 's' as const }, '9 min 0 s'],
    [{ value: 1.75, unit: 'count' as const }, '1,75'],
    [{ value: 0, unit: 'ms' as const }, '0 ms'],
    [{ value: null, unit: 'percent' as const }, '—'],
  ])('KPI %j → %s', (kpi, text) => {
    expect(formatKpiValue(kpi)).toBe(text);
  });

  it('duração arredonda e aceita nulo', () => {
    expect(formatDuration(619.6)).toBe('10 min 20 s');
    expect(formatDuration(null)).toBe('—');
  });
});
