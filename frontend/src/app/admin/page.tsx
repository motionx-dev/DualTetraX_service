"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import {
  getAnalyticsOverview, AnalyticsOverview,
  getUsageTrends, UsageTrend,
  getFeatureUsage, FeatureUsageItem,
  getTermination, TerminationData,
} from "@/lib/api";
import StatCard from "@/components/StatCard";
import TrendLineChart from "@/components/charts/TrendLineChart";
import ModeBarChart from "@/components/charts/ModeBarChart";
import DonutChart from "@/components/charts/DonutChart";
import { useT } from "@/i18n/context";

function fmtDuration(seconds: number): string {
  if (seconds < 60) return `${Math.round(seconds)}s`;
  const m = Math.floor(seconds / 60);
  const s = Math.round(seconds % 60);
  return s > 0 ? `${m}m ${s}s` : `${m}m`;
}

export default function AdminDashboard() {
  const t = useT();
  const [loading, setLoading] = useState(true);
  const [overview, setOverview] = useState<AnalyticsOverview | null>(null);
  const [trends, setTrends] = useState<UsageTrend[]>([]);
  const [modes, setModes] = useState<FeatureUsageItem[]>([]);
  const [termination, setTermination] = useState<TerminationData | null>(null);

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) return;
      const token = session.access_token;

      try {
        const [ov, tr, fu, te] = await Promise.all([
          getAnalyticsOverview(token),
          getUsageTrends(token, 14),
          getFeatureUsage(token, 30),
          getTermination(token, 30),
        ]);
        setOverview(ov);
        setTrends(tr.trends);
        setModes(fu.modes);
        setTermination(te);
      } catch {}
      setLoading(false);
    }
    load();
  }, []);

  if (loading) {
    return <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>;
  }

  if (!overview) {
    return <div className="text-center py-20 text-gray-400">{t("admin.failedToLoad")}</div>;
  }

  const terminationDonut = (termination?.reasons || []).map((r) => ({
    name: r.name,
    value: r.count,
  }));

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("admin.dashboard")}</h1>

      {/* KPI Cards - Row 1 */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 mb-3">
        <StatCard label={t("admin.totalUsers")} value={overview.total_users} sub={`+${overview.new_users_7d} ${t("analytics.last7d")}`} />
        <StatCard label={t("analytics.activeUsers30d")} value={overview.active_users_30d} />
        <StatCard label={t("admin.totalDevices")} value={overview.total_devices} sub={`${overview.active_devices} ${t("analytics.active")}`} />
        <StatCard label={t("admin.totalSessions")} value={overview.total_sessions} />
        <StatCard label={t("admin.todaySessions")} value={overview.today_sessions} />
      </div>

      {/* KPI Cards - Row 2 */}
      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mb-6">
        <StatCard label={t("analytics.avgSessionsDay")} value={overview.avg_sessions_per_day_7d} />
        <StatCard label={t("analytics.avgDuration")} value={fmtDuration(overview.avg_duration_seconds)} />
        <StatCard label={t("analytics.avgCompletion")} value={`${overview.avg_completion_percent}%`} />
      </div>

      {/* Charts - Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
          <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.sessionTrend")}</h3>
          <TrendLineChart data={trends} dataKey="sessions" color="#8b5cf6" label={t("analytics.sessions")} />
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
          <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.modeUsage")}</h3>
          <ModeBarChart data={modes} label={t("analytics.sessions")} />
        </div>
      </div>

      {/* Charts - Row 2 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
          <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.durationTrend")}</h3>
          <TrendLineChart data={trends} dataKey="avg_duration" color="#3b82f6" label={t("analytics.avgDurationSec")} />
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
          <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.terminationReasons")}</h3>
          {terminationDonut.length > 0 ? (
            <DonutChart data={terminationDonut} label={t("analytics.sessions")} />
          ) : (
            <div className="flex items-center justify-center h-[280px] text-gray-400 text-sm">{t("common.noData")}</div>
          )}
        </div>
      </div>
    </div>
  );
}
