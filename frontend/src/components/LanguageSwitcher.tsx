"use client";

import { useState } from "react";
import { useLocale, LOCALES, LOCALE_NAMES } from "@/i18n/context";
import type { Locale } from "@/i18n/context";

export default function LanguageSwitcher() {
  const { locale, setLocale } = useLocale();
  const [open, setOpen] = useState(false);

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="px-2 py-1.5 text-xs font-medium rounded-lg border border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
      >
        {LOCALE_NAMES[locale]}
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute right-0 mt-1 w-32 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg z-50">
            {LOCALES.map((l) => (
              <button
                key={l}
                onClick={() => { setLocale(l as Locale); setOpen(false); }}
                className={`w-full text-left px-3 py-2 text-sm transition-colors first:rounded-t-lg last:rounded-b-lg ${
                  l === locale
                    ? "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300"
                    : "text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                }`}
              >
                {LOCALE_NAMES[l as Locale]}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
