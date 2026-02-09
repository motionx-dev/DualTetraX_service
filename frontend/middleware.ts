import { updateSession } from "@/lib/supabase/middleware";
import type { NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  matcher: ["/dashboard/:path*", "/devices/:path*", "/stats/:path*", "/login", "/signup", "/reset-password", "/profile/:path*", "/settings/:path*", "/goals/:path*", "/skin-profile/:path*", "/consent/:path*", "/sessions/:path*", "/admin/:path*"],
};
