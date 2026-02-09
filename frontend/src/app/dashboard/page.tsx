"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { getDevices, getDailyStats, getRangeStats, getSessions, getProfile } from "@/lib/api";
import type { Device, DailyStats, Session } from "@/lib/api";
import Navbar from "@/components/Navbar";
import StatCard from "@/components/StatCard";
import SessionTable from "@/components/SessionTable";
import WeeklyChart from "@/components/charts/WeeklyChart";
import ShotTypePie from "@/components/charts/ShotTypePie";
import { formatDuration } from "@/lib/utils";
import { useT } from "@/i18n/context";

export default function DashboardPage() {
  const t = useT();
  const router = useRouter();
  const [devices, setDevices] = useState<Device[]>([]);
  const [stats, setStats] = useState<DailyStats | null>(null);
  const [weeklyData, setWeeklyData] = useState<Array<{ period: string; ushot_sessions: number; eshot_sessions: number; led_sessions: number }>>([]);
  const [recentSessions, setRecentSessions] = useState<Session[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      const token = session.access_token;

      try {
        const profileRes = await getProfile(token);
        if (!profileRes.profile.name) {
          router.replace("/profile");
          return;
        }
      } catch {}

      try {
        const [devRes, statsRes, recentRes] = await Promise.all([
          getDevices(token),
          getDailyStats(token),
          getSessions(token, { limit: 5 }),
        ]);

        setDevices(devRes.devices);
        setStats(statsRes);
        setRecentSessions(recentRes.sessions);

        // Weekly stats (last 7 days)
        const end = new Date();
        const start = new Date();
        start.setDate(end.getDate() - 6);
        const rangeRes = await getRangeStats(token, {
          start_date: start.toISOString().substring(0, 10),
          end_date: end.toISOString().substring(0, 10),
          group_by: "day",
        });
        setWeeklyData(rangeRes.data);
      } catch {}

      setLoading(false);
    }
    load();
  }, [router]);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("dashboard.title")}</h1>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : (
          <>
            {/* Summary cards */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-8">
              <StatCard label={t("dashboard.todaySessions")} value={stats?.total_sessions || 0} />
              <StatCard label={t("dashboard.todayDuration")} value={formatDuration(stats?.total_duration || 0)} />
              <StatCard label={t("dashboard.devices")} value={devices.length} />
              <StatCard
                label={t("dashboard.totalSessions")}
                value={devices.reduce((sum, d) => sum + d.total_sessions, 0)}
              />
            </div>

            {/* Charts */}
            <div className="grid lg:grid-cols-3 gap-6 mb-8">
              <div className="lg:col-span-2 bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
                <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">{t("dashboard.last7Days")}</h2>
                {weeklyData.length > 0 ? (
                  <WeeklyChart data={weeklyData} />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-gray-400 text-sm">{t("common.noData")}</div>
                )}
              </div>
              <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
                <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">{t("dashboard.shotTypeDist")}</h2>
                <ShotTypePie
                  ushot={stats?.ushot_sessions || 0}
                  eshot={stats?.eshot_sessions || 0}
                  led={stats?.led_sessions || 0}
                />
              </div>
            </div>

            {/* Recent sessions */}
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
              <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">{t("dashboard.recentSessions")}</h2>
              <SessionTable sessions={recentSessions} />
            </div>
          </>
        )}
      </main>
    </div>
  );
}
