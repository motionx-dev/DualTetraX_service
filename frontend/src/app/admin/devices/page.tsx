"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { getAdminDevices, Device } from "@/lib/api";
import Pagination from "@/components/Pagination";
import { useT } from "@/i18n/context";

type AdminDevice = Device & { profiles: { email: string; name: string | null } };

export default function AdminDevicesPage() {
  const t = useT();
  const [loading, setLoading] = useState(true);
  const [devices, setDevices] = useState<AdminDevice[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [searchInput, setSearchInput] = useState("");
  const limit = 20;

  const load = useCallback(async (p: number, s: string) => {
    setLoading(true);
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) { return; }
    const token = session.access_token;

    try {
      const res = await getAdminDevices(token, { page: p, limit, search: s || undefined });
      setDevices(res.devices);
      setTotal(res.total);
    } catch {}

    setLoading(false);
  }, []);

  useEffect(() => {
    load(page, search);
  }, [page, search, load]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    setPage(1);
    setSearch(searchInput);
  }

  function handlePageChange(p: number) {
    setPage(p);
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("admin.devices")}</h1>

      <form onSubmit={handleSearch} className="mb-4 flex gap-2">
        <input
          type="text"
          placeholder="Search by serial number..."
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="w-full max-w-sm px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
        <button
          type="submit"
          className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
        >
          {t("admin.search")}
        </button>
      </form>

      {loading ? (
        <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
      ) : (
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.serialNumber")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.model")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.owner")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.status")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">Registered</th>
              </tr>
            </thead>
            <tbody>
              {devices.map((device) => (
                <tr key={device.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800 font-mono">
                    {device.serial_number}
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {device.model_name || "-"}
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {device.profiles?.email || "-"}
                  </td>
                  <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${
                      device.is_active
                        ? "bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-300"
                        : "bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-300"
                    }`}>
                      {device.is_active ? t("common.active") : t("common.inactive")}
                    </span>
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {new Date(device.registered_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
              {devices.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-gray-400">{t("common.noData")}</td>
                </tr>
              )}
            </tbody>
          </table>

          <Pagination page={page} total={total} limit={limit} onPageChange={handlePageChange} />
        </div>
      )}
    </div>
  );
}
