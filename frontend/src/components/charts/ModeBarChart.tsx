"use client";

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from "recharts";

interface Item {
  name: string;
  count: number;
  percentage: number;
}

const COLORS = ["#8b5cf6", "#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#ec4899", "#06b6d4", "#84cc16"];

export default function ModeBarChart({ data, label = "Count" }: { data: Item[]; label?: string }) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <BarChart data={data} layout="vertical" margin={{ left: 60 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.3} />
        <XAxis type="number" tick={{ fontSize: 11 }} stroke="#9ca3af" />
        <YAxis type="category" dataKey="name" tick={{ fontSize: 11 }} stroke="#9ca3af" width={80} />
        <Tooltip
          contentStyle={{
            backgroundColor: "var(--tooltip-bg, #1f2937)",
            border: "1px solid #374151",
            borderRadius: "8px",
            color: "#f3f4f6",
          }}
          formatter={(value) => [`${value}`, label]}
        />
        <Bar dataKey="count" name={label} radius={[0, 4, 4, 0]}>
          {data.map((_, i) => (
            <Cell key={i} fill={COLORS[i % COLORS.length]} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
