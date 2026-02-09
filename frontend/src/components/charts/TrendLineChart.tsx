"use client";

import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

interface DataPoint {
  date: string;
  sessions: number;
  avg_duration: number;
}

export default function TrendLineChart({ data, dataKey = "sessions", color = "#8b5cf6", label = "Sessions" }: {
  data: DataPoint[];
  dataKey?: string;
  color?: string;
  label?: string;
}) {
  const formatted = data.map((d) => ({
    ...d,
    name: d.date.substring(5),
  }));

  return (
    <ResponsiveContainer width="100%" height={280}>
      <AreaChart data={formatted}>
        <defs>
          <linearGradient id={`grad-${dataKey}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor={color} stopOpacity={0.3} />
            <stop offset="95%" stopColor={color} stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.3} />
        <XAxis dataKey="name" tick={{ fontSize: 11 }} stroke="#9ca3af" />
        <YAxis tick={{ fontSize: 11 }} stroke="#9ca3af" />
        <Tooltip
          contentStyle={{
            backgroundColor: "var(--tooltip-bg, #1f2937)",
            border: "1px solid #374151",
            borderRadius: "8px",
            color: "#f3f4f6",
          }}
        />
        <Area type="monotone" dataKey={dataKey} name={label} stroke={color} fill={`url(#grad-${dataKey})`} strokeWidth={2} />
      </AreaChart>
    </ResponsiveContainer>
  );
}
