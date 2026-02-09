"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { getSkinProfile, updateSkinProfile } from "@/lib/api";
import Navbar from "@/components/Navbar";
import { useT } from "@/i18n/context";

const SKIN_TYPES = ["dry", "oily", "combination", "sensitive", "normal"];
const CONCERN_OPTIONS = ["wrinkles", "acne", "pigmentation", "pores", "dryness", "elasticity"];

const SKIN_TYPE_KEYS: Record<string, string> = {
  dry: "skinProfile.dry",
  oily: "skinProfile.oily",
  combination: "skinProfile.combination",
  sensitive: "skinProfile.sensitive",
  normal: "skinProfile.normal",
};

const CONCERN_KEYS: Record<string, string> = {
  wrinkles: "skinProfile.wrinkles",
  acne: "skinProfile.acne",
  pigmentation: "skinProfile.pigmentation",
  pores: "skinProfile.pores",
  dryness: "skinProfile.dryness",
  elasticity: "skinProfile.redness",
};

export default function SkinProfilePage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState("");

  const [skinType, setSkinType] = useState("");
  const [concerns, setConcerns] = useState<string[]>([]);
  const [memo, setMemo] = useState("");

  const t = useT();

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }
      const token = session.access_token;

      try {
        const res = await getSkinProfile(token);
        if (res.skin_profile) {
          setSkinType(res.skin_profile.skin_type || "");
          setConcerns(res.skin_profile.concerns || []);
          setMemo(res.skin_profile.memo || "");
        }
      } catch {}

      setLoading(false);
    }
    load();
  }, []);

  function toggleConcern(concern: string) {
    setConcerns((prev) =>
      prev.includes(concern)
        ? prev.filter((c) => c !== concern)
        : [...prev, concern]
    );
  }

  async function handleSave() {
    setSaving(true);
    setToast("");

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }

      await updateSkinProfile(session.access_token, {
        skin_type: skinType || null,
        concerns,
        memo: memo || null,
      });
      setToast(t("skinProfile.saved"));
      setTimeout(() => setToast(""), 3000);
    } catch {
      setToast(t("skinProfile.failed"));
      setTimeout(() => setToast(""), 3000);
    }

    setSaving(false);
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("skinProfile.title")}</h1>

        {loading ? (
          <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
        ) : (
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 max-w-lg">
            {/* Skin Type */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">{t("skinProfile.skinType")}</label>
              <div className="flex flex-wrap gap-3">
                {SKIN_TYPES.map((type) => (
                  <label key={type} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="skin_type"
                      value={type}
                      checked={skinType === type}
                      onChange={() => setSkinType(type)}
                      className="w-4 h-4 text-blue-600 border-gray-300 dark:border-gray-600 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-700 dark:text-gray-300">{t(SKIN_TYPE_KEYS[type])}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Concerns */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">{t("skinProfile.concerns")}</label>
              <div className="flex flex-wrap gap-3">
                {CONCERN_OPTIONS.map((concern) => (
                  <label key={concern} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={concerns.includes(concern)}
                      onChange={() => toggleConcern(concern)}
                      className="w-4 h-4 text-blue-600 border-gray-300 dark:border-gray-600 rounded focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-700 dark:text-gray-300">{t(CONCERN_KEYS[concern])}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Memo */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("skinProfile.memo")}</label>
              <textarea
                value={memo}
                onChange={(e) => setMemo(e.target.value.slice(0, 500))}
                maxLength={500}
                rows={4}
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
              />
              <p className="text-xs text-gray-400 mt-1">{memo.length}/500</p>
            </div>

            {/* Save button */}
            <button
              onClick={handleSave}
              disabled={saving}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
            >
              {saving ? t("common.saving") : t("common.save")}
            </button>

            {/* Toast */}
            {toast && (
              <p className={`mt-3 text-sm ${toast === t("skinProfile.failed") ? "text-red-500" : "text-green-500"}`}>
                {toast}
              </p>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
