"use client";

import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from "recharts";

interface DataItem {
  name: string;
  value: number;
}

const COLORS = ["#8b5cf6", "#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#ec4899", "#06b6d4", "#84cc16"];

export default function DonutChart({ data, label = "Count" }: { data: DataItem[]; label?: string }) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <PieChart>
        <Pie
          data={data}
          cx="50%"
          cy="50%"
          innerRadius={60}
          outerRadius={100}
          paddingAngle={2}
          dataKey="value"
          nameKey="name"
        >
          {data.map((_, i) => (
            <Cell key={i} fill={COLORS[i % COLORS.length]} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{
            backgroundColor: "var(--tooltip-bg, #1f2937)",
            border: "1px solid #374151",
            borderRadius: "8px",
            color: "#f3f4f6",
          }}
          formatter={(value) => [`${value}`, label]}
        />
        <Legend
          wrapperStyle={{ fontSize: "12px" }}
        />
      </PieChart>
    </ResponsiveContainer>
  );
}
