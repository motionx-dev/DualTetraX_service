"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useT } from "@/i18n/context";

const ADMIN_KEYS = [
  { href: "/admin", key: "admin.dashboard", exact: true },
  { href: "/admin/analytics", key: "admin.analytics", exact: false },
  { href: "/admin/users", key: "admin.users", exact: false },
  { href: "/admin/devices", key: "admin.devices", exact: false },
  { href: "/admin/firmware", key: "admin.firmware", exact: false },
  { href: "/admin/announcements", key: "admin.announcements", exact: false },
  { href: "/admin/logs", key: "admin.logs", exact: false },
];

export default function AdminNavbar() {
  const pathname = usePathname();
  const t = useT();

  function isActive(link: typeof ADMIN_KEYS[number]) {
    if (link.exact) { return pathname === link.href; }
    return pathname.startsWith(link.href);
  }

  return (
    <aside className="w-52 shrink-0 py-6 pr-6 hidden md:block">
      <h2 className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-3 px-3">{t("admin.title")}</h2>
      <nav className="flex flex-col gap-0.5">
        {ADMIN_KEYS.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
              isActive(link)
                ? "bg-purple-100 text-purple-700 dark:bg-purple-900/50 dark:text-purple-300"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-white dark:hover:bg-gray-800"
            }`}
          >
            {t(link.key)}
          </Link>
        ))}
      </nav>
    </aside>
  );
}
