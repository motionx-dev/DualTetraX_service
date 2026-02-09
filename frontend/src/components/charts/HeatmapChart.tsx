"use client";

import type { HeatmapCell } from "@/lib/api";

const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function getColor(count: number, max: number): string {
  if (max === 0 || count === 0) return "bg-gray-100 dark:bg-gray-800";
  const ratio = count / max;
  if (ratio < 0.25) return "bg-purple-100 dark:bg-purple-900/30";
  if (ratio < 0.5) return "bg-purple-200 dark:bg-purple-800/50";
  if (ratio < 0.75) return "bg-purple-400 dark:bg-purple-600/70";
  return "bg-purple-600 dark:bg-purple-500";
}

export default function HeatmapChart({ data }: { data: HeatmapCell[] }) {
  const grid: number[][] = Array.from({ length: 7 }, () => Array(24).fill(0));
  let max = 0;
  for (const cell of data) {
    grid[cell.day][cell.hour] = cell.count;
    if (cell.count > max) max = cell.count;
  }

  return (
    <div className="overflow-x-auto">
      <div className="min-w-[600px]">
        <div className="flex items-center mb-1">
          <div className="w-10" />
          {Array.from({ length: 24 }, (_, h) => (
            <div key={h} className="flex-1 text-center text-[10px] text-gray-400">{h}</div>
          ))}
        </div>
        {DAYS.map((day, di) => (
          <div key={day} className="flex items-center gap-0.5 mb-0.5">
            <div className="w-10 text-xs text-gray-500 dark:text-gray-400 text-right pr-1">{day}</div>
            {Array.from({ length: 24 }, (_, h) => (
              <div
                key={h}
                className={`flex-1 aspect-square rounded-sm ${getColor(grid[di][h], max)}`}
                title={`${day} ${h}:00 — ${grid[di][h]} sessions`}
              />
            ))}
          </div>
        ))}
        <div className="flex items-center justify-end gap-1 mt-2 text-xs text-gray-400">
          <span>Less</span>
          <div className="w-3 h-3 rounded-sm bg-gray-100 dark:bg-gray-800" />
          <div className="w-3 h-3 rounded-sm bg-purple-100 dark:bg-purple-900/30" />
          <div className="w-3 h-3 rounded-sm bg-purple-200 dark:bg-purple-800/50" />
          <div className="w-3 h-3 rounded-sm bg-purple-400 dark:bg-purple-600/70" />
          <div className="w-3 h-3 rounded-sm bg-purple-600 dark:bg-purple-500" />
          <span>More</span>
        </div>
      </div>
    </div>
  );
}
