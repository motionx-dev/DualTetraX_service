"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { getDevices, getExportUrl } from "@/lib/api";
import type { Device } from "@/lib/api";
import Navbar from "@/components/Navbar";
import { useT } from "@/i18n/context";

export default function SessionExportPage() {
  const [loading, setLoading] = useState(true);
  const [devices, setDevices] = useState<Device[]>([]);

  const [deviceId, setDeviceId] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [downloading, setDownloading] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const t = useT();

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }
      const token = session.access_token;

      try {
        const res = await getDevices(token);
        setDevices(res.devices);
      } catch {}

      setLoading(false);
    }
    load();
  }, []);

  async function handleExport() {
    setDownloading(true);
    setMessage(null);

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      const url = getExportUrl(session.access_token, {
        device_id: deviceId || undefined,
        start_date: startDate || undefined,
        end_date: endDate || undefined,
      });

      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${session.access_token}` },
      });

      if (!res.ok) {
        throw new Error(`Export failed: ${res.status}`);
      }

      const blob = await res.blob();
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "sessions.csv";
      a.click();

      setMessage({ type: "success", text: "Export downloaded successfully." });
    } catch (err) {
      setMessage({ type: "error", text: err instanceof Error ? err.message : "Export failed." });
    }

    setDownloading(false);
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("export.title")}</h1>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 max-w-lg">
            {/* Device selector */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("export.device")}</label>
              <select
                value={deviceId}
                onChange={(e) => setDeviceId(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">{t("export.allDevices")}</option>
                {devices.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.model_name} ({d.serial_number})
                  </option>
                ))}
              </select>
            </div>

            {/* Start date */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("export.startDate")}</label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            {/* End date */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("export.endDate")}</label>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            {/* Download button */}
            <button
              onClick={handleExport}
              disabled={downloading}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
            >
              {downloading ? t("export.downloading") : t("export.download")}
            </button>

            {/* Message */}
            {message && (
              <p className={`mt-3 text-sm ${message.type === "error" ? "text-red-500" : "text-green-500"}`}>
                {message.text}
              </p>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
