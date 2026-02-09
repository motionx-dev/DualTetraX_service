"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { getProfile } from "@/lib/api";
import { useT } from "@/i18n/context";
import LanguageSwitcher from "@/components/LanguageSwitcher";
import SocialLoginButtons from "@/components/SocialLoginButtons";

export default function LoginPage() {
  const router = useRouter();
  const t = useT();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    const supabase = createClient();
    const { error: authError } = await supabase.auth.signInWithPassword({ email, password });

    if (authError) {
      setError(authError.message);
      setLoading(false);
      return;
    }

    // Check role and redirect accordingly
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.access_token) {
        const res = await getProfile(session.access_token);
        if (res.profile.role === "admin") {
          router.push("/admin");
          return;
        }
      }
    } catch {}
    router.push("/dashboard");
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-gray-50 dark:bg-gray-950">
      <div className="w-full max-w-sm">
        <div className="flex justify-end mb-2">
          <LanguageSwitcher />
        </div>
        <div className="text-center mb-8">
          <Link href="/" className="text-2xl font-bold text-gray-900 dark:text-white">DualTetraX</Link>
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">{t("auth.signInTitle")}</p>
        </div>

        <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6 space-y-4">
          {error && (
            <div className="p-3 rounded-lg bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-sm">
              {error}
            </div>
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

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("auth.password")}</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
              placeholder={t("auth.passwordPlaceholder")}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
          >
            {loading ? t("auth.signingIn") : t("auth.signIn")}
          </button>

          <div className="flex justify-between text-sm">
            <Link href="/reset-password" className="text-blue-600 dark:text-blue-400 hover:underline">
              {t("auth.forgotPassword")}
            </Link>
            <Link href="/signup" className="text-blue-600 dark:text-blue-400 hover:underline">
              {t("auth.createAccount")}
            </Link>
          </div>

          <div className="relative my-2">
            <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-gray-200 dark:border-gray-700" /></div>
            <div className="relative flex justify-center text-xs"><span className="bg-white dark:bg-gray-900 px-2 text-gray-400">OR</span></div>
          </div>

          <SocialLoginButtons />
        </form>
      </div>
    </div>
  );
}
