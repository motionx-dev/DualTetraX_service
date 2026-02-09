"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { getGoals, createGoal, updateGoal, deleteGoal } from "@/lib/api";
import type { UserGoal } from "@/lib/api";
import Navbar from "@/components/Navbar";
import ConfirmDialog from "@/components/ConfirmDialog";
import { useT } from "@/i18n/context";

export default function GoalsPage() {
  const [loading, setLoading] = useState(true);
  const [goals, setGoals] = useState<UserGoal[]>([]);
  const [showForm, setShowForm] = useState(false);

  const [goalType, setGoalType] = useState("weekly");
  const [targetMinutes, setTargetMinutes] = useState(30);
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [creating, setCreating] = useState(false);

  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);

  const t = useT();

  useEffect(() => {
    loadGoals();
  }, []);

  async function loadGoals() {
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) { return; }
    const token = session.access_token;

    try {
      const res = await getGoals(token);
      setGoals(res.goals);
    } catch {}

    setLoading(false);
  }

  async function handleCreate() {
    if (!startDate || !endDate || targetMinutes <= 0) { return; }
    setCreating(true);

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      const res = await createGoal(session.access_token, {
        goal_type: goalType,
        target_minutes: targetMinutes,
        start_date: startDate,
        end_date: endDate,
      });
      setGoals((prev) => [...prev, res.goal]);
      setShowForm(false);
      setGoalType("weekly");
      setTargetMinutes(30);
      setStartDate("");
      setEndDate("");
    } catch {}

    setCreating(false);
  }

  async function handleToggleActive(goal: UserGoal) {
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      const res = await updateGoal(session.access_token, goal.id, { is_active: !goal.is_active });
      setGoals((prev) => prev.map((g) => (g.id === goal.id ? res.goal : g)));
    } catch {}
  }

  async function handleDelete() {
    if (!deleteTarget) { return; }

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      await deleteGoal(session.access_token, deleteTarget);
      setGoals((prev) => prev.filter((g) => g.id !== deleteTarget));
    } catch {}

    setDeleteTarget(null);
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t("goals.title")}</h1>
          <button
            onClick={() => setShowForm(!showForm)}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
          >
            {showForm ? "Cancel" : t("goals.createGoal")}
          </button>
        </div>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : (
          <>
            {/* Create form */}
            {showForm && (
              <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 mb-6">
                <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">{t("goals.createGoal")}</h2>

                <div className="grid sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("goals.goalType")}</label>
                    <select
                      value={goalType}
                      onChange={(e) => setGoalType(e.target.value)}
                      className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="weekly">{t("goals.weekly")}</option>
                      <option value="monthly">{t("goals.monthly")}</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("goals.targetMinutes")}</label>
                    <input
                      type="number"
                      min={1}
                      value={targetMinutes}
                      onChange={(e) => setTargetMinutes(Number(e.target.value))}
                      className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("goals.startDate")}</label>
                    <input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("goals.endDate")}</label>
                    <input
                      type="date"
                      value={endDate}
                      onChange={(e) => setEndDate(e.target.value)}
                      className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>
                </div>

                <button
                  onClick={handleCreate}
                  disabled={creating || !startDate || !endDate}
                  className="mt-4 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
                >
                  {creating ? t("common.loading") : t("common.create")}
                </button>
              </div>
            )}

            {/* Goal list */}
            {goals.length === 0 ? (
              <div className="text-center py-20 text-gray-400">{t("goals.noGoals")}</div>
            ) : (
              <div className="space-y-4">
                {goals.map((goal) => (
                  <div key={goal.id} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
                    <div className="flex items-start justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-semibold text-gray-900 dark:text-white capitalize">{goal.goal_type === "weekly" ? t("goals.weekly") : t("goals.monthly")}</span>
                          <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                            goal.is_active
                              ? "bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300"
                              : "bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
                          }`}>
                            {goal.is_active ? t("common.active") : t("common.inactive")}
                          </span>
                        </div>
                        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                          {t("goals.targetMinutes")}: {goal.target_minutes} min
                        </p>
                        <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">
                          {goal.start_date} ~ {goal.end_date}
                        </p>
                      </div>

                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleToggleActive(goal)}
                          className="px-3 py-1.5 text-xs font-medium rounded-lg border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                        >
                          {goal.is_active ? t("common.inactive") : t("common.active")}
                        </button>
                        <button
                          onClick={() => setDeleteTarget(goal.id)}
                          className="px-3 py-1.5 text-xs font-medium rounded-lg bg-red-600 hover:bg-red-700 text-white transition-colors"
                        >
                          {t("common.delete")}
                        </button>
                      </div>
                    </div>

                    {/* Progress bar */}
                    <div className="mt-3">
                      <div className="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-blue-600 rounded-full transition-all"
                          style={{ width: `${Math.min(100, 0)}%` }}
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}

        {/* Confirm delete dialog */}
        <ConfirmDialog
          open={!!deleteTarget}
          title={t("common.delete")}
          message={t("goals.deleteConfirm")}
          onConfirm={handleDelete}
          onCancel={() => setDeleteTarget(null)}
        />
      </main>
    </div>
  );
}
