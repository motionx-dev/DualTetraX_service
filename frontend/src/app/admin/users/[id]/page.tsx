"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { getAdminUser, updateAdminUser, Profile } from "@/lib/api";
import { useT } from "@/i18n/context";

export default function AdminUserDetailPage() {
  const t = useT();
  const params = useParams();
  const id = params.id as string;

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [deviceCount, setDeviceCount] = useState(0);
  const [sessionCount, setSessionCount] = useState(0);
  const [role, setRole] = useState("user");
  const [message, setMessage] = useState("");

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }
      const token = session.access_token;

      try {
        const res = await getAdminUser(token, id);
        setProfile(res.profile);
        setDeviceCount(res.device_count);
        setSessionCount(res.session_count);
        setRole(res.profile.role);
      } catch {}

      setLoading(false);
    }
    load();
  }, [id]);

  async function handleSave() {
    setSaving(true);
    setMessage("");
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) { return; }

    try {
      const res = await updateAdminUser(session.access_token, id, { role });
      setProfile(res.profile);
      setMessage("Saved successfully.");
    } catch {
      setMessage("Failed to save.");
    }

    setSaving(false);
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("admin.detail")}</h1>

      {loading ? (
        <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
      ) : profile ? (
        <div className="space-y-6">
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Profile</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
                <p className="text-gray-900 dark:text-white">{profile.email}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Name</label>
                <p className="text-gray-900 dark:text-white">{profile.name || "-"}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Gender</label>
                <p className="text-gray-900 dark:text-white">{profile.gender || "-"}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Timezone</label>
                <p className="text-gray-900 dark:text-white">{profile.timezone}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Created</label>
                <p className="text-gray-900 dark:text-white">{new Date(profile.created_at).toLocaleDateString()}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.deviceCount")}</label>
                <p className="text-gray-900 dark:text-white">{deviceCount}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.sessionCount")}</label>
                <p className="text-gray-900 dark:text-white">{sessionCount}</p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{t("admin.role")}</h2>
            <div className="flex items-end gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.role")}</label>
                <select
                  value={role}
                  onChange={(e) => setRole(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="user">{t("admin.user")}</option>
                  <option value="admin">{t("admin.adminRole")}</option>
                </select>
              </div>

              <button
                onClick={handleSave}
                disabled={saving}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
              >
                {saving ? t("common.saving") : t("common.save")}
              </button>
            </div>

            {message && (
              <p className={`mt-3 text-sm ${message.includes("Failed") ? "text-red-500" : "text-green-500"}`}>
                {message}
              </p>
            )}
          </div>
        </div>
      ) : (
        <div className="text-center py-20 text-gray-400">{t("common.noData")}</div>
      )}
    </div>
  );
}
