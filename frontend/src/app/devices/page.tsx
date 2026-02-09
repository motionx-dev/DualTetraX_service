"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { getDevices, registerDevice } from "@/lib/api";
import type { Device } from "@/lib/api";
import Navbar from "@/components/Navbar";
import DeviceCard from "@/components/DeviceCard";
import { useT } from "@/i18n/context";

export default function DevicesPage() {
  const t = useT();
  const [devices, setDevices] = useState<Device[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [serial, setSerial] = useState("");
  const [firmware, setFirmware] = useState("");
  const [mac, setMac] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function loadDevices() {
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) return;

    try {
      const res = await getDevices(session.access_token);
      setDevices(res.devices);
    } catch {}
    setLoading(false);
  }

  useEffect(() => { loadDevices(); }, []);

  async function handleRegister(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setSubmitting(true);

    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) return;

    try {
      await registerDevice(session.access_token, {
        serial_number: serial,
        firmware_version: firmware || undefined,
        ble_mac_address: mac || undefined,
      });
      setShowForm(false);
      setSerial("");
      setFirmware("");
      setMac("");
      await loadDevices();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Registration failed");
    }
    setSubmitting(false);
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t("devices.title")}</h1>
          <button
            onClick={() => setShowForm(!showForm)}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
          >
            {showForm ? "Cancel" : t("devices.registerDevice")}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleRegister} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 mb-6 space-y-4">
            {error && (
              <div className="p-3 rounded-lg bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-sm">{error}</div>
            )}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("devices.serialNumber")} *</label>
              <input
                value={serial}
                onChange={(e) => setSerial(e.target.value)}
                required
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
                placeholder="e.g. DT-2026-001"
              />
            </div>
            <div className="grid sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("devices.firmwareVersion")}</label>
                <input
                  value={firmware}
                  onChange={(e) => setFirmware(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="e.g. 1.0.23"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("devices.bleMac")}</label>
                <input
                  value={mac}
                  onChange={(e) => setMac(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="e.g. AA:BB:CC:DD:EE:FF"
                />
              </div>
            </div>
            <button
              type="submit"
              disabled={submitting}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
            >
              {submitting ? t("devices.registering") : t("devices.register")}
            </button>
          </form>
        )}

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : devices.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-gray-500 dark:text-gray-400">{t("devices.noDevices")}</p>
            <button
              onClick={() => setShowForm(true)}
              className="mt-3 text-sm text-blue-600 dark:text-blue-400 hover:underline"
            >
              {t("devices.registerDevice")}
            </button>
          </div>
        ) : (
          <div className="grid sm:grid-cols-2 gap-4">
            {devices.map((d) => (
              <DeviceCard key={d.id} device={d} />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
