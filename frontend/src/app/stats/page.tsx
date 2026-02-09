"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { getRangeStats, getDevices } from "@/lib/api";
import type { Device } from "@/lib/api";
import Navbar from "@/components/Navbar";
import StatCard from "@/components/StatCard";
import WeeklyChart from "@/components/charts/WeeklyChart";
import ShotTypePie from "@/components/charts/ShotTypePie";
import { formatDuration } from "@/lib/utils";
import { useT } from "@/i18n/context";

type Period = "week" | "month" | "3months";

function getDateRange(period: Period) {
  const end = new Date();
  const start = new Date();
  if (period === "week") start.setDate(end.getDate() - 6);
  else if (period === "month") start.setDate(end.getDate() - 29);
  else start.setDate(end.getDate() - 89);
  return {
    start_date: start.toISOString().substring(0, 10),
    end_date: end.toISOString().substring(0, 10),
  };
}

export default function StatsPage() {
  const t = useT();
  const [period, setPeriod] = useState<Period>("week");
  const [devices, setDevices] = useState<Device[]>([]);
  const [selectedDevice, setSelectedDevice] = useState<string>("");
  const [chartData, setChartData] = useState<Array<{ period: string; ushot_sessions: number; eshot_sessions: number; led_sessions: number }>>([]);
  const [summary, setSummary] = useState({ total_sessions: 0, total_duration: 0, avg_sessions_per_day: 0 });
  const [pieTotals, setPieTotals] = useState({ ushot: 0, eshot: 0, led: 0 });
  const [loading, setLoading] = useState(true);

  async function loadStats() {
    setLoading(true);
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) return;

    const token = session.access_token;

    try {
      const range = getDateRange(period);
      const groupBy = period === "week" ? "day" : period === "month" ? "day" : "week";

      const res = await getRangeStats(token, {
        ...range,
        device_id: selectedDevice || undefined,
        group_by: groupBy,
      });

      setChartData(res.data);
      setSummary(res.summary);

      const pie = res.data.reduce(
        (acc, d) => ({
          ushot: acc.ushot + d.ushot_sessions,
          eshot: acc.eshot + d.eshot_sessions,
          led: acc.led + d.led_sessions,
        }),
        { ushot: 0, eshot: 0, led: 0 }
      );
      setPieTotals(pie);
    } catch {}

    setLoading(false);
  }

  useEffect(() => {
    async function init() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) return;
      const res = await getDevices(session.access_token);
      setDevices(res.devices);
    }
    init();
  }, []);

  useEffect(() => { loadStats(); }, [period, selectedDevice]);

  const PERIODS: { key: Period; label: string }[] = [
    { key: "week", label: t("stats.daily") },
    { key: "month", label: t("stats.weekly") },
    { key: "3months", label: t("stats.monthly") },
  ];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("stats.title")}</h1>

        {/* Filters */}
        <div className="flex flex-wrap gap-3 mb-6">
          <div className="flex rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
            {PERIODS.map((p) => (
              <button
                key={p.key}
                onClick={() => setPeriod(p.key)}
                className={`px-4 py-2 text-sm font-medium transition-colors ${
                  period === p.key
                    ? "bg-blue-600 text-white"
                    : "bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                {p.label}
              </button>
            ))}
          </div>

          {devices.length > 1 && (
            <select
              value={selectedDevice}
              onChange={(e) => setSelectedDevice(e.target.value)}
              className="px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm outline-none"
            >
              <option value="">All Devices</option>
              {devices.map((d) => (
                <option key={d.id} value={d.id}>{d.serial_number}</option>
              ))}
            </select>
          )}
        </div>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : (
          <>
            {/* Summary */}
            <div className="grid grid-cols-3 gap-4 mb-8">
              <StatCard label="Total Sessions" value={summary.total_sessions} />
              <StatCard label="Total Duration" value={formatDuration(summary.total_duration)} />
              <StatCard label="Avg / Day" value={summary.avg_sessions_per_day} />
            </div>

            {/* Charts */}
            <div className="grid lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2 bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
                <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">Sessions Over Time</h2>
                {chartData.length > 0 ? (
                  <WeeklyChart data={chartData} />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-gray-400 text-sm">{t("common.noData")}</div>
                )}
              </div>
              <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
                <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">Shot Type Distribution</h2>
                <ShotTypePie ushot={pieTotals.ushot} eshot={pieTotals.eshot} led={pieTotals.led} />
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  );
}
