const STORAGE_KEYS = {
  PLAYER_COUNT: 'flipout_player_count',
  PLAYER_NAMES: 'flipout_player_names',
  COLOR_MODE: 'flipout_color_mode',
  SAMPLE_COUNT: 'flipout_sample_count',
};

export function savePlayerCount(count: number): void {
  localStorage.setItem(STORAGE_KEYS.PLAYER_COUNT, count.toString());
}

export function loadPlayerCount(): number {
  const saved = localStorage.getItem(STORAGE_KEYS.PLAYER_COUNT);
  return saved ? parseInt(saved, 10) : 2;
}

export function savePlayerNames(names: Record<number, string>): void {
  localStorage.setItem(STORAGE_KEYS.PLAYER_NAMES, JSON.stringify(names));
}

export function loadPlayerNames(): Record<number, string> {
  const saved = localStorage.getItem(STORAGE_KEYS.PLAYER_NAMES);
  return saved ? JSON.parse(saved) : {};
}

export function saveColorMode(mode: number): void {
  localStorage.setItem(STORAGE_KEYS.COLOR_MODE, mode.toString());
}

export function loadColorMode(): number {
  const saved = localStorage.getItem(STORAGE_KEYS.COLOR_MODE);
  return saved ? parseInt(saved, 10) : 2;
}

export function saveSampleCount(count: number): void {
  localStorage.setItem(STORAGE_KEYS.SAMPLE_COUNT, count.toString());
}

export function loadSampleCount(): number {
  const saved = localStorage.getItem(STORAGE_KEYS.SAMPLE_COUNT);
  return saved ? parseInt(saved, 10) : 10_000;
}
