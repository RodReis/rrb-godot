/** Versão do cliente `vX.Y.Z` (tag do Release, F83/ADR-0023) em números; fora do formato = null. */
export function parseClientVersion(raw: string | undefined): [number, number, number] | null {
  const match = /^v?(\d+)\.(\d+)\.(\d+)$/.exec((raw ?? '').trim());
  return match ? [Number(match[1]), Number(match[2]), Number(match[3])] : null;
}

/** true se `given` é igual ou mais nova que `minimum`; versão ilegível nunca passa. */
export function isClientVersionAtLeast(given: string | undefined, minimum: string): boolean {
  const have = parseClientVersion(given);
  const need = parseClientVersion(minimum);
  if (have === null || need === null) return false;
  const [major, minor, patch] = have;
  const [needMajor, needMinor, needPatch] = need;
  if (major !== needMajor) return major > needMajor;
  if (minor !== needMinor) return minor > needMinor;
  return patch >= needPatch;
}
