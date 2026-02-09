"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

const PROVIDERS = [
  {
    id: "google" as const,
    label: "Google",
    bg: "bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600",
    text: "text-gray-700 dark:text-gray-300",
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24">
        <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" />
        <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
        <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
        <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
      </svg>
    ),
  },
  {
    id: "apple" as const,
    label: "Apple",
    bg: "bg-black dark:bg-white",
    text: "text-white dark:text-black",
    icon: (
      <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
        <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
      </svg>
    ),
  },
  {
    id: "kakao" as const,
    label: "Kakao",
    bg: "bg-[#FEE500]",
    text: "text-[#191919]",
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24">
        <path fill="#191919" d="M12 3C6.48 3 2 6.36 2 10.44c0 2.62 1.75 4.93 4.38 6.24l-1.12 4.1c-.1.36.32.64.62.43l4.84-3.2c.42.04.84.06 1.28.06 5.52 0 10-3.36 10-7.5S17.52 3 12 3z" />
      </svg>
    ),
  },
];

export default function SocialLoginButtons() {
  const [loadingId, setLoadingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSocialLogin(provider: "google" | "apple" | "kakao") {
    setError(null);
    setLoadingId(provider);
    try {
      const supabase = createClient();
      const { data, error: oauthError } = await supabase.auth.signInWithOAuth({
        provider,
        options: {
          redirectTo: `${window.location.origin}/auth/callback`,
        },
      });
      if (oauthError) {
        setError(oauthError.message);
        setLoadingId(null);
      } else if (!data?.url) {
        setError("OAuth redirect URL not received");
        setLoadingId(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
      setLoadingId(null);
    }
  }

  return (
    <div className="space-y-2">
      {error && (
        <div className="p-2 rounded-lg bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs">
          {error}
        </div>
      )}
      {PROVIDERS.map((p) => (
        <button
          key={p.id}
          onClick={() => handleSocialLogin(p.id)}
          disabled={loadingId !== null}
          className={`w-full flex items-center justify-center gap-3 py-2.5 rounded-lg font-medium text-sm transition-opacity disabled:opacity-50 ${p.bg} ${p.text}`}
        >
          {p.icon}
          {loadingId === p.id ? "..." : p.label}
        </button>
      ))}
    </div>
  );
}
