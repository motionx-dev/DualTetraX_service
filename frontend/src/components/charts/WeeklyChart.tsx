"use client";

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

interface DataPoint {
  period: string;
  ushot_sessions: number;
  eshot_sessions: number;
  led_sessions: number;
}

export default function WeeklyChart({ data }: { data: DataPoint[] }) {
  const formatted = data.map((d) => ({
    ...d,
    name: d.period.substring(5), // MM-DD
  }));

  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={formatted}>
        <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.3} />
        <XAxis dataKey="name" tick={{ fontSize: 12 }} stroke="#9ca3af" />
        <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
        <Tooltip
          contentStyle={{
            backgroundColor: "var(--tooltip-bg, #1f2937)",
            border: "1px solid #374151",
            borderRadius: "8px",
            color: "#f3f4f6",
          }}
        />
        <Legend />
        <Bar dataKey="ushot_sessions" name="U-Shot" fill="#3b82f6" radius={[4, 4, 0, 0]} />
        <Bar dataKey="eshot_sessions" name="E-Shot" fill="#f59e0b" radius={[4, 4, 0, 0]} />
        <Bar dataKey="led_sessions" name="LED" fill="#10b981" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
