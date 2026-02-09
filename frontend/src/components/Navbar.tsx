"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import ThemeToggle from "./ThemeToggle";
import LanguageSwitcher from "./LanguageSwitcher";
import { logout, getProfile } from "@/lib/api";
import { useEffect, useState } from "react";
import { useT } from "@/i18n/context";

const NAV_KEYS = [
  { href: "/dashboard", key: "nav.dashboard" },
  { href: "/devices", key: "nav.devices" },
  { href: "/stats", key: "nav.stats" },
  { href: "/goals", key: "nav.goals" },
];

const USER_KEYS = [
  { href: "/profile", key: "nav.profile" },
  { href: "/settings", key: "nav.settings" },
];

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const t = useT();
  const [loggingOut, setLoggingOut] = useState(false);
  const [role, setRole] = useState<string | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);

  const isAdmin = role === "admin";

  useEffect(() => {
    async function loadRole() {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) { return; }
      try {
        const res = await getProfile(session.access_token);
        setRole(res.profile.role);
      } catch {}
    }
    loadRole();
  }, []);

  async function handleLogout() {
    setLoggingOut(true);
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.access_token) {
        await logout(session.access_token).catch(() => {});
      }
      await supabase.auth.signOut();
    } catch {}
    router.push("/login");
  }

  return (
    <nav className="border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <div className="flex items-center gap-6">
          <Link href={isAdmin ? "/admin" : "/dashboard"} className="font-bold text-lg text-gray-900 dark:text-white">
            DualTetraX
          </Link>
          {!isAdmin && (
            <div className="hidden sm:flex items-center gap-1">
              {NAV_KEYS.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                    pathname.startsWith(item.href)
                      ? "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300"
                      : "text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
                  }`}
                >
                  {t(item.key)}
                </Link>
              ))}
            </div>
          )}
        </div>

        <div className="flex items-center gap-2">
          <LanguageSwitcher />
          <ThemeToggle />

          <div className="relative">
            <button
              onClick={() => setMenuOpen(!menuOpen)}
              className="p-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            >
              <svg className="w-5 h-5 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </button>

            {menuOpen && (
              <div className="absolute right-0 mt-2 w-44 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg z-50">
                {!isAdmin && USER_KEYS.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMenuOpen(false)}
                    className="block px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 first:rounded-t-lg"
                  >
                    {t(item.key)}
                  </Link>
                ))}
                <button
                  onClick={handleLogout}
                  disabled={loggingOut}
                  className="w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-b-lg"
                >
                  {loggingOut ? t("nav.loggingOut") : t("nav.logout")}
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
