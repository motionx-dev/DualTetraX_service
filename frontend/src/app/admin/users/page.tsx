"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { getAdminUsers, AdminUser } from "@/lib/api";
import Pagination from "@/components/Pagination";
import { useT } from "@/i18n/context";

export default function AdminUsersPage() {
  const t = useT();
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<AdminUser[]>([]);
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
      const res = await getAdminUsers(token, { page: p, limit, search: s || undefined });
      setUsers(res.users);
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
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("admin.users")}</h1>

      <form onSubmit={handleSearch} className="mb-4 flex gap-2">
        <input
          type="text"
          placeholder="Search by email or name..."
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
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">Email</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">Name</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.role")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.deviceCount")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">Created</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr
                  key={user.id}
                  onClick={() => router.push(`/admin/users/${user.id}`)}
                  className="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                >
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">{user.email}</td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">{user.name || "-"}</td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${
                      user.role === "admin"
                        ? "bg-purple-100 text-purple-700 dark:bg-purple-900/50 dark:text-purple-300"
                        : "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300"
                    }`}>
                      {user.role === "admin" ? t("admin.adminRole") : t("admin.user")}
                    </span>
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {user.devices?.[0]?.count ?? 0}
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
              {users.length === 0 && (
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
