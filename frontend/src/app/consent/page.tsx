"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { getConsent, addConsent } from "@/lib/api";
import type { ConsentRecord } from "@/lib/api";
import Navbar from "@/components/Navbar";
import { useT } from "@/i18n/context";

const CONSENT_CATEGORIES = ["terms", "privacy", "marketing", "data_collection"];

interface ConsentGroup {
  type: string;
  latest: ConsentRecord | null;
}

export default function ConsentPage() {
  const [loading, setLoading] = useState(true);
  const [records, setRecords] = useState<ConsentRecord[]>([]);
  const [updating, setUpdating] = useState<string | null>(null);

  const t = useT();

  const CATEGORY_LABELS: Record<string, string> = {
    terms: t("consent.terms"),
    privacy: t("consent.privacy"),
    marketing: t("consent.marketing"),
    data_collection: t("consent.dataCollection"),
  };

  useEffect(() => {
    loadConsent();
  }, []);

  async function loadConsent() {
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) { return; }
    const token = session.access_token;

    try {
      const res = await getConsent(token);
      setRecords(res.records);
    } catch {}

    setLoading(false);
  }

  function getGroups(): ConsentGroup[] {
    return CONSENT_CATEGORIES.map((type) => {
      const matching = records
        .filter((r) => r.consent_type === type)
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
      return { type, latest: matching[0] || null };
    });
  }

  async function handleToggle(type: string, consented: boolean) {
    setUpdating(type);

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      const res = await addConsent(session.access_token, { consent_type: type, consented });
      setRecords((prev) => [...prev, res.record]);
    } catch {}

    setUpdating(null);
  }

  const groups = getGroups();

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("consent.title")}</h1>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : (
          <div className="space-y-4 max-w-lg">
            {groups.map((group) => {
              const isAgreed = group.latest?.consented === true;
              const isUpdating = updating === group.type;

              return (
                <div
                  key={group.type}
                  className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5"
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
                        {CATEGORY_LABELS[group.type]}
                      </h3>
                      <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">
                        {group.latest
                          ? `${isAgreed ? t("consent.agreed") : t("consent.withdrawn")} on ${new Date(group.latest.created_at).toLocaleString()}`
                          : "No record"}
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      <span className={`text-xs font-medium ${isAgreed ? "text-green-600 dark:text-green-400" : "text-gray-400"}`}>
                        {isAgreed ? t("consent.agreed") : t("consent.withdrawn")}
                      </span>
                      <button
                        onClick={() => handleToggle(group.type, !isAgreed)}
                        disabled={isUpdating}
                        className={`w-11 h-6 rounded-full relative transition-colors ${isAgreed ? "bg-blue-600" : "bg-gray-300 dark:bg-gray-600"} ${isUpdating ? "opacity-50" : ""}`}
                      >
                        <span className={`block w-5 h-5 bg-white rounded-full shadow transform transition-transform ${isAgreed ? "translate-x-5" : "translate-x-0.5"}`} />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}
