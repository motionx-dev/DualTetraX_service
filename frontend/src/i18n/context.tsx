"use client";

import { createContext, useContext, useState, useCallback, useEffect, type ReactNode } from "react";
import { messages, type Locale, type Messages, LOCALES, LOCALE_NAMES } from "./messages";

interface LocaleContextType {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: string) => string;
}

const LocaleContext = createContext<LocaleContextType | null>(null);

function resolve(obj: Record<string, unknown>, path: string): string {
  const keys = path.split(".");
  let cur: unknown = obj;
  for (const k of keys) {
    if (cur && typeof cur === "object" && k in cur) {
      cur = (cur as Record<string, unknown>)[k];
    } else {
      return path;
    }
  }
  return typeof cur === "string" ? cur : path;
}

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>("ko");

  useEffect(() => {
    const stored = localStorage.getItem("locale") as Locale | null;
    if (stored && LOCALES.includes(stored)) {
      setLocaleState(stored);
    } else {
      const browserLang = navigator.language.split("-")[0] as Locale;
      if (LOCALES.includes(browserLang)) {
        setLocaleState(browserLang);
      }
    }
  }, []);

  const setLocale = useCallback((l: Locale) => {
    setLocaleState(l);
    localStorage.setItem("locale", l);
    document.documentElement.lang = l;
  }, []);

  const t = useCallback((key: string): string => {
    return resolve(messages[locale] as unknown as Record<string, unknown>, key);
  }, [locale]);

  return (
    <LocaleContext.Provider value={{ locale, setLocale, t }}>
      {children}
    </LocaleContext.Provider>
  );
}

export function useLocale() {
  const ctx = useContext(LocaleContext);
  if (!ctx) { throw new Error("useLocale must be used within LocaleProvider"); }
  return ctx;
}

export function useT() {
  const { t } = useLocale();
  return t;
}

export { LOCALES, LOCALE_NAMES };
export type { Locale, Messages };
