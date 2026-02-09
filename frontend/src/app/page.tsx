"use client";

import Link from "next/link";
import ThemeToggle from "@/components/ThemeToggle";
import LanguageSwitcher from "@/components/LanguageSwitcher";
import { useT } from "@/i18n/context";

export default function LandingPage() {
  const t = useT();

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-gray-200 dark:border-gray-800">
        <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
          <span className="font-bold text-lg text-gray-900 dark:text-white">DualTetraX</span>
          <div className="flex items-center gap-3">
            <LanguageSwitcher />
            <ThemeToggle />
            <Link href="/login" className="px-4 py-1.5 text-sm font-medium text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white">
              {t("landing.login")}
            </Link>
            <Link href="/signup" className="px-4 py-1.5 text-sm font-medium bg-blue-600 text-white rounded-lg hover:bg-blue-700">
              {t("landing.signup")}
            </Link>
          </div>
        </div>
      </header>

      <main className="flex-1 flex items-center justify-center px-4">
        <div className="max-w-2xl text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-white leading-tight">
            {t("landing.title")}<br />
            <span className="text-blue-600 dark:text-blue-400">{t("landing.highlight")}</span>
          </h1>
          <p className="mt-4 text-lg text-gray-600 dark:text-gray-400">
            {t("landing.description")}
          </p>
          <div className="mt-8 flex gap-3 justify-center">
            <Link href="/signup" className="px-6 py-2.5 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors">
              {t("landing.getStarted")}
            </Link>
            <Link href="/login" className="px-6 py-2.5 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg font-medium hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors">
              {t("landing.signIn")}
            </Link>
          </div>

          <div className="mt-16 grid sm:grid-cols-3 gap-6 text-left">
            <div className="p-4">
              <div className="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900 flex items-center justify-center mb-3">
                <svg className="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 dark:text-white">{t("landing.statsTitle")}</h3>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{t("landing.statsDesc")}</p>
            </div>
            <div className="p-4">
              <div className="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-900 flex items-center justify-center mb-3">
                <svg className="w-5 h-5 text-amber-600 dark:text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 dark:text-white">{t("landing.deviceTitle")}</h3>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{t("landing.deviceDesc")}</p>
            </div>
            <div className="p-4">
              <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900 flex items-center justify-center mb-3">
                <svg className="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 dark:text-white">{t("landing.syncTitle")}</h3>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{t("landing.syncDesc")}</p>
            </div>
          </div>
        </div>
      </main>

      <footer className="border-t border-gray-200 dark:border-gray-800 py-6 text-center text-xs text-gray-400 dark:text-gray-500">
        {t("landing.copyright")}
      </footer>
    </div>
  );
}
