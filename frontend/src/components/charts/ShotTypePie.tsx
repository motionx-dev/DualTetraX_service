"use client";

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from "recharts";

interface Props {
  ushot: number;
  eshot: number;
  led: number;
}

const COLORS = ["#3b82f6", "#f59e0b", "#10b981"];

export default function ShotTypePie({ ushot, eshot, led }: Props) {
  const data = [
    { name: "U-Shot", value: ushot },
    { name: "E-Shot", value: eshot },
    { name: "LED", value: led },
  ].filter((d) => d.value > 0);

  if (data.length === 0) {
    return (
      <div className="flex items-center justify-center h-[250px] text-gray-400 dark:text-gray-500 text-sm">
        No data
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={250}>
      <PieChart>
        <Pie
          data={data}
          cx="50%"
          cy="50%"
          innerRadius={50}
          outerRadius={90}
          paddingAngle={3}
          dataKey="value"
        >
          {data.map((_, i) => (
            <Cell key={i} fill={COLORS[i % COLORS.length]} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{
            backgroundColor: "#1f2937",
            border: "1px solid #374151",
            borderRadius: "8px",
            color: "#f3f4f6",
          }}
        />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}
