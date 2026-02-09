/** Device mode value → display name */
const MODE_NAMES: Record<number, string> = {
  0x01: "Glow",
  0x02: "Toneup",
  0x03: "Renew",
  0x04: "Volume",
  0x11: "Clean",
  0x12: "Firm",
  0x13: "Line",
  0x14: "Lift",
  0x21: "LED Mode",
};

/** Shot type value → display name */
const SHOT_NAMES: Record<number, string> = {
  0: "U-Shot",
  1: "E-Shot",
  2: "LED Care",
};

/** Shot type → color for charts */
const SHOT_COLORS: Record<number, string> = {
  0: "#3b82f6", // blue
  1: "#f59e0b", // amber
  2: "#10b981", // emerald
};

export function getModeName(mode: number): string {
  return MODE_NAMES[mode] || `Unknown (0x${mode.toString(16).padStart(2, "0")})`;
}

export function getShotName(shotType: number): string {
  return SHOT_NAMES[shotType] || "Unknown";
}

export function getShotColor(shotType: number): string {
  return SHOT_COLORS[shotType] || "#6b7280";
}

/** Seconds → "Xh Ym" or "Xm Ys" */
export function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m < 60) return s > 0 ? `${m}m ${s}s` : `${m}m`;
  const h = Math.floor(m / 60);
  const rm = m % 60;
  return rm > 0 ? `${h}h ${rm}m` : `${h}h`;
}

/** ISO date string → "2026-02-08" */
export function formatDate(iso: string): string {
  return iso.substring(0, 10);
}

/** ISO date string → "02/08 10:30" */
export function formatDateTime(iso: string): string {
  const d = new Date(iso);
  const mo = String(d.getMonth() + 1).padStart(2, "0");
  const da = String(d.getDate()).padStart(2, "0");
  const h = String(d.getHours()).padStart(2, "0");
  const mi = String(d.getMinutes()).padStart(2, "0");
  return `${mo}/${da} ${h}:${mi}`;
}

/** Level number → display string */
export function getLevelName(level: number): string {
  return `Lv.${level}`;
}

/** Termination reason code → display name */
const TERMINATION_NAMES: Record<number, string> = {
  0: "Timeout (8min)",
  1: "Manual Stop",
  2: "Battery Drain",
  3: "Overheat",
  4: "Charging Started",
  5: "Pause Timeout",
  6: "Mode Changed",
  7: "Power On",
  8: "US Overheat",
  9: "Body Overheat",
  255: "Other",
};

export function getTerminationName(reason: number | null): string {
  if (reason === null || reason === undefined) return "-";
  return TERMINATION_NAMES[reason] || `Unknown (${reason})`;
}
