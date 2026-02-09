import en from "./en";
import ko from "./ko";
import zh from "./zh";
import th from "./th";
import ja from "./ja";
import pt from "./pt";

export const LOCALES = ["ko", "en", "zh", "th", "ja", "pt"] as const;
export type Locale = (typeof LOCALES)[number];
type DeepStringify<T> = { [K in keyof T]: T[K] extends object ? DeepStringify<T[K]> : string };
export type Messages = DeepStringify<typeof en>;

export const LOCALE_NAMES: Record<Locale, string> = {
  ko: "한국어",
  en: "English",
  zh: "中文",
  th: "ไทย",
  ja: "日本語",
  pt: "Português",
};

export const messages: Record<Locale, Messages> = { en, ko, zh, th, ja, pt };
