"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { getAdminLogs, AdminLog } from "@/lib/api";
import Pagination from "@/components/Pagination";
import { useT } from "@/i18n/context";

const TARGET_TYPES = ["", "user", "device", "firmware", "rollout", "announcement", "system"];

export default function AdminLogsPage() {
  const t = useT();
  const [loading, setLoading] = useState(true);
  const [logs, setLogs] = useState<AdminLog[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [targetType, setTargetType] = useState("");
  const [action, setAction] = useState("");
  const [actionInput, setActionInput] = useState("");
  const limit = 20;

  const load = useCallback(async (p: number, tt: string, act: string) => {
    setLoading(true);
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) { return; }
    const token = session.access_token;

    try {
      const res = await getAdminLogs(token, {
        page: p,
        limit,
        target_type: tt || undefined,
        action: act || undefined,
      });
      setLogs(res.logs);
      setTotal(res.total);
    } catch {}

    setLoading(false);
  }, []);

  useEffect(() => {
    load(page, targetType, action);
  }, [page, targetType, action, load]);

  function handleFilter(e: React.FormEvent) {
    e.preventDefault();
    setPage(1);
    setAction(actionInput);
  }

  function handleTargetTypeChange(value: string) {
    setTargetType(value);
    setPage(1);
  }

  function handlePageChange(p: number) {
    setPage(p);
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("admin.logs")}</h1>

      <form onSubmit={handleFilter} className="mb-4 flex flex-wrap gap-2">
        <select
          value={targetType}
          onChange={(e) => handleTargetTypeChange(e.target.value)}
          className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="">{t("common.all")}</option>
          {TARGET_TYPES.filter((tt) => tt !== "").map((tt) => (
            <option key={tt} value={tt}>{tt.charAt(0).toUpperCase() + tt.slice(1)}</option>
          ))}
        </select>

        <input
          type="text"
          placeholder="Filter by action..."
          value={actionInput}
          onChange={(e) => setActionInput(e.target.value)}
          className="w-full max-w-xs px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />

        <button
          type="submit"
          className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
        >
          {t("common.filter")}
        </button>
      </form>

      {loading ? (
        <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
      ) : (
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.adminName")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.action")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.targetType")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">Target ID</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.date")}</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {log.profiles?.email || log.admin_id}
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800 font-mono text-xs">
                    {log.action}
                  </td>
                  <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                    <span className="inline-block px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300">
                      {log.target_type}
                    </span>
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800 font-mono text-xs">
                    {log.target_id ? log.target_id.substring(0, 8) + "..." : "-"}
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {new Date(log.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
              {logs.length === 0 && (
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
