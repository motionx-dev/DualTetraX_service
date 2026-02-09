"use client";

import type { FirmwareDistItem } from "@/lib/api";

const COLORS = ["#8b5cf6", "#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#ec4899", "#06b6d4", "#84cc16"];

export default function FirmwareStackedBar({ data, total }: { data: FirmwareDistItem[]; total: number }) {
  if (!data.length) {
    return <div className="text-sm text-gray-400 text-center py-8">No firmware data</div>;
  }

  return (
    <div>
      <div className="flex rounded-lg overflow-hidden h-8 mb-3">
        {data.map((item, i) => (
          <div
            key={item.version}
            className="relative group"
            style={{ width: `${item.percentage}%`, backgroundColor: COLORS[i % COLORS.length] }}
            title={`${item.version}: ${item.count} (${item.percentage}%)`}
          >
            {item.percentage > 8 && (
              <span className="absolute inset-0 flex items-center justify-center text-white text-xs font-medium">
                {item.percentage}%
              </span>
            )}
          </div>
        ))}
      </div>
      <div className="flex flex-wrap gap-3">
        {data.map((item, i) => (
          <div key={item.version} className="flex items-center gap-1.5 text-xs">
            <div className="w-2.5 h-2.5 rounded-sm" style={{ backgroundColor: COLORS[i % COLORS.length] }} />
            <span className="text-gray-600 dark:text-gray-400">{item.version}</span>
            <span className="text-gray-400 dark:text-gray-500">({item.count})</span>
          </div>
        ))}
      </div>
      <p className="text-xs text-gray-400 mt-2">Total: {total} active devices</p>
    </div>
  );
}
