"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import {
  getUsageTrends, UsageTrend,
  getFeatureUsage, FeatureUsageItem,
  getDemographics, DemographicsData,
  getHeatmap, HeatmapCell,
  getTermination, TerminationData,
  getFirmwareDist, FirmwareDistItem,
} from "@/lib/api";
import TrendLineChart from "@/components/charts/TrendLineChart";
import ModeBarChart from "@/components/charts/ModeBarChart";
import HeatmapChart from "@/components/charts/HeatmapChart";
import DonutChart from "@/components/charts/DonutChart";
import FirmwareStackedBar from "@/components/charts/FirmwareStackedBar";
import { useT } from "@/i18n/context";

type Period = 7 | 30 | 90;

export default function AnalyticsPage() {
  const t = useT();
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<Period>(30);

  const [trends, setTrends] = useState<UsageTrend[]>([]);
  const [shotTypes, setShotTypes] = useState<FeatureUsageItem[]>([]);
  const [modes, setModes] = useState<FeatureUsageItem[]>([]);
  const [demographics, setDemographics] = useState<DemographicsData | null>(null);
  const [heatmap, setHeatmap] = useState<HeatmapCell[]>([]);
  const [termination, setTermination] = useState<TerminationData | null>(null);
  const [firmware, setFirmware] = useState<FirmwareDistItem[]>([]);
  const [fwTotal, setFwTotal] = useState(0);

  async function loadData(days: Period) {
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) return;
    const token = session.access_token;

    setLoading(true);
    try {
      const [tr, fu, dem, hm, te, fw] = await Promise.all([
        getUsageTrends(token, days),
        getFeatureUsage(token, days),
        getDemographics(token),
        getHeatmap(token, days),
        getTermination(token, days),
        getFirmwareDist(token),
      ]);
      setTrends(tr.trends);
      setShotTypes(fu.shot_types);
      setModes(fu.modes);
      setDemographics(dem);
      setHeatmap(hm.heatmap);
      setTermination(te);
      setFirmware(fw.firmware);
      setFwTotal(fw.total_devices);
    } catch {}
    setLoading(false);
  }

  useEffect(() => {
    loadData(period);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function changePeriod(p: Period) {
    setPeriod(p);
    loadData(p);
  }

  const terminationDonut = (termination?.reasons || []).map((r) => ({
    name: r.name,
    value: r.count,
  }));

  const ageDonut = (demographics?.age_distribution || []).map((a) => ({
    name: a.group,
    value: a.count,
  }));

  const genderDonut = (demographics?.gender_distribution || []).map((g) => ({
    name: g.gender || "Unknown",
    value: g.count,
  }));

  const PERIODS: { value: Period; label: string }[] = [
    { value: 7, label: t("analytics.period7d") },
    { value: 30, label: t("analytics.period30d") },
    { value: 90, label: t("analytics.period90d") },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t("analytics.title")}</h1>
        <div className="flex gap-1 bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
          {PERIODS.map((p) => (
            <button
              key={p.value}
              onClick={() => changePeriod(p.value)}
              className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                period === p.value
                  ? "bg-white dark:bg-gray-700 text-purple-700 dark:text-purple-300 shadow-sm"
                  : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
      ) : (
        <div className="space-y-4">
          {/* Row 1: Usage Trends + Shot Type */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.sessionTrend")}</h3>
              <TrendLineChart data={trends} dataKey="sessions" color="#8b5cf6" label={t("analytics.sessions")} />
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.shotTypeUsage")}</h3>
              <ModeBarChart data={shotTypes} label={t("analytics.sessions")} />
            </div>
          </div>

          {/* Row 2: Mode Usage + Duration Trend */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.modeUsage")}</h3>
              <ModeBarChart data={modes} label={t("analytics.sessions")} />
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.durationTrend")}</h3>
              <TrendLineChart data={trends} dataKey="avg_duration" color="#3b82f6" label={t("analytics.avgDurationSec")} />
            </div>
          </div>

          {/* Row 3: Demographics */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.ageDistribution")}</h3>
              {ageDonut.length > 0 ? (
                <DonutChart data={ageDonut} label={t("analytics.users")} />
              ) : (
                <div className="flex items-center justify-center h-[280px] text-gray-400 text-sm">{t("common.noData")}</div>
              )}
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.genderDistribution")}</h3>
              {genderDonut.length > 0 ? (
                <DonutChart data={genderDonut} label={t("analytics.users")} />
              ) : (
                <div className="flex items-center justify-center h-[280px] text-gray-400 text-sm">{t("common.noData")}</div>
              )}
            </div>
          </div>

          {/* Row 4: Heatmap */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.usageHeatmap")}</h3>
            <HeatmapChart data={heatmap} />
          </div>

          {/* Row 5: Termination + Firmware */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.terminationReasons")}</h3>
              {terminationDonut.length > 0 ? (
                <>
                  <DonutChart data={terminationDonut} label={t("analytics.sessions")} />
                  <p className="text-xs text-gray-400 text-center mt-2">
                    {t("analytics.avgCompletion")}: {termination?.avg_completion_percent}%
                  </p>
                </>
              ) : (
                <div className="flex items-center justify-center h-[280px] text-gray-400 text-sm">{t("common.noData")}</div>
              )}
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("analytics.firmwareDistribution")}</h3>
              <FirmwareStackedBar data={firmware} total={fwTotal} />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
