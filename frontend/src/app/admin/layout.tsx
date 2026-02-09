import Navbar from "@/components/Navbar";
import AdminNavbar from "@/components/AdminNavbar";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <div className="flex max-w-7xl mx-auto">
        <AdminNavbar />
        <main className="flex-1 px-6 py-6">{children}</main>
      </div>
    </div>
  );
}
