"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { getSessions } from "@/lib/api";
import type { Session } from "@/lib/api";
import Navbar from "@/components/Navbar";
import SessionTable from "@/components/SessionTable";
import Link from "next/link";
import { useT } from "@/i18n/context";

interface DeviceInfo {
  id: string;
  serial_number: string;
  model_name: string;
  firmware_version: string | null;
  ble_mac_address: string | null;
  is_active: boolean;
  last_synced_at: string | null;
  total_sessions: number;
  registered_at: string;
}

export default function DeviceDetailPage() {
  const t = useT();
  const params = useParams();
  const deviceId = params.id as string;

  const [device, setDevice] = useState<DeviceInfo | null>(null);
  const [sessions, setSessions] = useState<Session[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) return;

      // Load device info via Supabase directly (RLS applies)
      const { data: dev } = await supabase
        .from("devices")
        .select("*")
        .eq("id", deviceId)
        .single();

      if (dev) setDevice(dev);

      // Load sessions
      try {
        const res = await getSessions(session.access_token, { device_id: deviceId, limit: 50 });
        setSessions(res.sessions);
        setTotal(res.total);
      } catch {}

      setLoading(false);
    }
    load();
  }, [deviceId]);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <Link href="/devices" className="text-sm text-blue-600 dark:text-blue-400 hover:underline mb-4 inline-block">
          &larr; {t("common.back")}
        </Link>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : !device ? (
          <div className="text-center py-20 text-gray-500">{t("common.noData")}</div>
        ) : (
          <>
            {/* Device info */}
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 mb-6">
              <div className="flex items-start justify-between">
                <div>
                  <h1 className="text-xl font-bold text-gray-900 dark:text-white">{device.model_name}</h1>
                  <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{device.serial_number}</p>
                </div>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                  device.is_active
                    ? "bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300"
                    : "bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
                }`}>
                  {device.is_active ? t("common.active") : t("common.inactive")}
                </span>
              </div>
              <div className="mt-4 grid sm:grid-cols-4 gap-4 text-sm">
                <div>
                  <span className="text-gray-500 dark:text-gray-400">{t("devices.firmwareVersion")}</span>
                  <p className="font-medium text-gray-900 dark:text-white">{device.firmware_version || "-"}</p>
                </div>
                <div>
                  <span className="text-gray-500 dark:text-gray-400">BLE MAC</span>
                  <p className="font-medium text-gray-900 dark:text-white">{device.ble_mac_address || "-"}</p>
                </div>
                <div>
                  <span className="text-gray-500 dark:text-gray-400">{t("devices.totalSessions")}</span>
                  <p className="font-medium text-gray-900 dark:text-white">{device.total_sessions}</p>
                </div>
                <div>
                  <span className="text-gray-500 dark:text-gray-400">{t("devices.lastSynced")}</span>
                  <p className="font-medium text-gray-900 dark:text-white">
                    {device.last_synced_at ? new Date(device.last_synced_at).toLocaleString() : "Never"}
                  </p>
                </div>
              </div>
            </div>

            {/* Sessions */}
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Sessions ({total})
                </h2>
              </div>
              <SessionTable sessions={sessions} />
            </div>
          </>
        )}
      </main>
    </div>
  );
}
