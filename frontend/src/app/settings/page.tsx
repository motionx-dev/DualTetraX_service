"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { getNotifications, updateNotifications } from "@/lib/api";
import type { NotificationSettings } from "@/lib/api";
import Navbar from "@/components/Navbar";
import { useT } from "@/i18n/context";

function Toggle({ label, value, onChange }: { label: string; value: boolean; onChange: (v: boolean) => void }) {
  return (
    <div className="flex items-center justify-between py-3">
      <span className="text-sm text-gray-700 dark:text-gray-300">{label}</span>
      <button onClick={() => onChange(!value)} className={`w-11 h-6 rounded-full relative transition-colors ${value ? "bg-blue-600" : "bg-gray-300 dark:bg-gray-600"}`}>
        <span className={`block w-5 h-5 bg-white rounded-full shadow transform transition-transform ${value ? "translate-x-5" : "translate-x-0.5"}`} />
      </button>
    </div>
  );
}

export default function SettingsPage() {
  const [loading, setLoading] = useState(true);
  const [settings, setSettings] = useState<NotificationSettings | null>(null);

  const t = useT();

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }
      const token = session.access_token;

      try {
        const res = await getNotifications(token);
        setSettings(res.settings);
      } catch {}

      setLoading(false);
    }
    load();
  }, []);

  async function handleToggle(key: keyof NotificationSettings, value: boolean) {
    if (!settings) { return; }

    const updated = { ...settings, [key]: value };
    setSettings(updated);

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      await updateNotifications(session.access_token, { [key]: value });
    } catch {
      // revert on error
      setSettings(settings);
    }
  }

  async function handleReminderTime(time: string) {
    if (!settings) { return; }

    const updated = { ...settings, reminder_time: time };
    setSettings(updated);

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      await updateNotifications(session.access_token, { reminder_time: time });
    } catch {
      setSettings(settings);
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("settings.title")}</h1>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : settings ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 max-w-lg">
            <Toggle
              label={t("settings.pushNotifications")}
              value={settings.push_enabled}
              onChange={(v) => handleToggle("push_enabled", v)}
            />

            <Toggle
              label={t("settings.emailNotifications")}
              value={settings.email_enabled}
              onChange={(v) => handleToggle("email_enabled", v)}
            />

            <Toggle
              label={t("settings.usageReminder")}
              value={settings.usage_reminder}
              onChange={(v) => handleToggle("usage_reminder", v)}
            />

            {/* Reminder time (only shown when usage_reminder is on) */}
            {settings.usage_reminder && (
              <div className="py-3 pl-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("settings.reminderTime")}</label>
                <input
                  type="time"
                  value={settings.reminder_time || "09:00"}
                  onChange={(e) => handleReminderTime(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            )}

            <Toggle
              label={t("settings.marketingEmails")}
              value={settings.marketing_enabled}
              onChange={(v) => handleToggle("marketing_enabled", v)}
            />
          </div>
        ) : (
          <div className="text-center py-20 text-gray-500">{t("settings.failed")}</div>
        )}
      </main>
    </div>
  );
}
