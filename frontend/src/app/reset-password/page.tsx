"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { useT } from "@/i18n/context";
import LanguageSwitcher from "@/components/LanguageSwitcher";

export default function ResetPasswordPage() {
  const t = useT();
  const [email, setEmail] = useState("");
  const [error, setError] = useState("");
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    const supabase = createClient();
    const { error: authError } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/login`,
    });

    if (authError) {
      setError(authError.message);
      setLoading(false);
      return;
    }

    setSent(true);
    setLoading(false);
  }

  if (sent) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4 bg-gray-50 dark:bg-gray-950">
        <div className="w-full max-w-sm text-center">
          <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-8">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t("auth.resetSent")}</h2>
            <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
              {t("auth.resetDesc")}
            </p>
            <Link href="/login" className="mt-4 inline-block text-sm text-blue-600 dark:text-blue-400 hover:underline">
              {t("auth.backToLogin")}
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-gray-50 dark:bg-gray-950">
      <div className="w-full max-w-sm">
        <div className="flex justify-end mb-2">
          <LanguageSwitcher />
        </div>
        <div className="text-center mb-8">
          <Link href="/" className="text-2xl font-bold text-gray-900 dark:text-white">DualTetraX</Link>
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">{t("auth.resetTitle")}</p>
        </div>

        <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6 space-y-4">
          {error && (
            <div className="p-3 rounded-lg bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-sm">{error}</div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("auth.email")}</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
              placeholder={t("auth.emailPlaceholder")}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
          >
            {loading ? t("auth.sendingReset") : t("auth.sendReset")}
          </button>

          <p className="text-center text-sm">
            <Link href="/login" className="text-blue-600 dark:text-blue-400 hover:underline">{t("auth.backToLogin")}</Link>
          </p>
        </form>
      </div>
    </div>
  );
}
