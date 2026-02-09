"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { getDeviceDetail, transferDevice } from "@/lib/api";
import type { Device } from "@/lib/api";
import Navbar from "@/components/Navbar";
import ConfirmDialog from "@/components/ConfirmDialog";
import Link from "next/link";
import { useT } from "@/i18n/context";

export default function DeviceTransferPage() {
  const { id } = useParams();
  const deviceId = id as string;

  const [loading, setLoading] = useState(true);
  const [device, setDevice] = useState<Device | null>(null);
  const [email, setEmail] = useState("");
  const [transferring, setTransferring] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const t = useT();

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }
      const token = session.access_token;

      try {
        const res = await getDeviceDetail(token, deviceId);
        setDevice(res.device);
      } catch {}

      setLoading(false);
    }
    load();
  }, [deviceId]);

  async function handleTransfer() {
    setConfirmOpen(false);
    if (!email.trim()) { return; }
    setTransferring(true);
    setMessage(null);

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      await transferDevice(session.access_token, deviceId, email.trim());
      setMessage({ type: "success", text: t("transfer.success") });
      setEmail("");
    } catch (err) {
      setMessage({ type: "error", text: err instanceof Error ? err.message : t("transfer.failed") });
    }

    setTransferring(false);
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <Link href={`/devices/${deviceId}`} className="text-sm text-blue-600 dark:text-blue-400 hover:underline mb-4 inline-block">
          &larr; {t("common.back")}
        </Link>

        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("transfer.title")}</h1>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : !device ? (
          <div className="text-center py-20 text-gray-500">Device not found.</div>
        ) : (
          <div className="max-w-lg">
            {/* Device info */}
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 mb-6">
              <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-3">Device Information</h2>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-gray-500 dark:text-gray-400">Serial Number</span>
                  <p className="font-medium text-gray-900 dark:text-white">{device.serial_number}</p>
                </div>
                <div>
                  <span className="text-gray-500 dark:text-gray-400">Model</span>
                  <p className="font-medium text-gray-900 dark:text-white">{device.model_name}</p>
                </div>
              </div>
            </div>

            {/* Transfer form */}
            <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
              <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-3">{t("transfer.title")}</h2>

              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("transfer.recipientEmail")}</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="user@example.com"
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <button
                onClick={() => setConfirmOpen(true)}
                disabled={transferring || !email.trim()}
                className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
              >
                {transferring ? t("transfer.transferring") : t("transfer.confirm")}
              </button>

              {/* Message */}
              {message && (
                <p className={`mt-3 text-sm ${message.type === "error" ? "text-red-500" : "text-green-500"}`}>
                  {message.text}
                </p>
              )}
            </div>
          </div>
        )}

        {/* Confirm dialog */}
        <ConfirmDialog
          open={confirmOpen}
          title={t("transfer.confirm")}
          message={t("transfer.confirmMessage")}
          onConfirm={handleTransfer}
          onCancel={() => setConfirmOpen(false)}
        />
      </main>
    </div>
  );
}
