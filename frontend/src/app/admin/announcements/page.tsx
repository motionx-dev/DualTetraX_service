"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import {
  getAnnouncements,
  createAnnouncement,
  updateAnnouncement,
  deleteAnnouncement,
  Announcement,
} from "@/lib/api";
import ConfirmDialog from "@/components/ConfirmDialog";
import { useT } from "@/i18n/context";

interface FormData {
  title: string;
  content: string;
  type: string;
  is_published: boolean;
}

const EMPTY_FORM: FormData = { title: "", content: "", type: "notice", is_published: false };

export default function AdminAnnouncementsPage() {
  const t = useT();
  const [loading, setLoading] = useState(true);
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormData>(EMPTY_FORM);
  const [creating, setCreating] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

  // confirm dialog
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  async function getToken() {
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    return session?.access_token || null;
  }

  async function loadAll() {
    const token = await getToken();
    if (!token) { return; }

    try {
      const res = await getAnnouncements(token);
      setAnnouncements(res.announcements);
    } catch {}

    setLoading(false);
  }

  useEffect(() => {
    loadAll();
  }, []);

  function startCreate() {
    setCreating(true);
    setEditingId(null);
    setForm(EMPTY_FORM);
    setMessage("");
  }

  function startEdit(ann: Announcement) {
    setCreating(false);
    setEditingId(ann.id);
    setForm({
      title: ann.title,
      content: ann.content,
      type: ann.type,
      is_published: ann.is_published,
    });
    setMessage("");
  }

  function cancelEdit() {
    setCreating(false);
    setEditingId(null);
    setForm(EMPTY_FORM);
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setMessage("");
    const token = await getToken();
    if (!token) { return; }

    try {
      if (creating) {
        await createAnnouncement(token, form);
        setMessage("Announcement created.");
      } else if (editingId) {
        await updateAnnouncement(token, editingId, form);
        setMessage("Announcement updated.");
      }
      cancelEdit();
      await loadAll();
    } catch {
      setMessage("Failed to save announcement.");
    }

    setSaving(false);
  }

  function confirmDelete(id: string) {
    setDeleteId(id);
    setConfirmOpen(true);
  }

  async function handleDelete() {
    setConfirmOpen(false);
    if (!deleteId) { return; }
    const token = await getToken();
    if (!token) { return; }

    try {
      await deleteAnnouncement(token, deleteId);
      setMessage("Announcement deleted.");
      if (editingId === deleteId) { cancelEdit(); }
      await loadAll();
    } catch {
      setMessage("Failed to delete announcement.");
    }

    setDeleteId(null);
  }

  const typeColors: Record<string, string> = {
    notice: "bg-blue-100 text-blue-700 dark:bg-blue-900/50 dark:text-blue-300",
    maintenance: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-300",
    update: "bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-300",
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t("admin.announcements")}</h1>
        {!creating && !editingId && (
          <button
            onClick={startCreate}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
          >
            {t("admin.createAnnouncement")}
          </button>
        )}
      </div>

      {message && (
        <div className={`mb-4 p-3 rounded-lg text-sm ${message.includes("Failed") ? "bg-red-50 text-red-600 dark:bg-red-900/20 dark:text-red-400" : "bg-green-50 text-green-600 dark:bg-green-900/20 dark:text-green-400"}`}>
          {message}
        </div>
      )}

      {/* Create / Edit form */}
      {(creating || editingId) && (
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            {creating ? t("admin.createAnnouncement") : t("admin.editAnnouncement")}
          </h2>
          <form onSubmit={handleSave} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.titleField")}</label>
              <input
                type="text"
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                required
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.content")}</label>
              <textarea
                value={form.content}
                onChange={(e) => setForm({ ...form, content: e.target.value })}
                rows={4}
                required
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.type")}</label>
                <select
                  value={form.type}
                  onChange={(e) => setForm({ ...form, type: e.target.value })}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="notice">{t("admin.notice")}</option>
                  <option value="maintenance">{t("admin.maintenance")}</option>
                  <option value="update">{t("admin.updateType")}</option>
                </select>
              </div>

              <div className="flex items-center gap-2 pt-6">
                <input
                  type="checkbox"
                  id="ann-published"
                  checked={form.is_published}
                  onChange={(e) => setForm({ ...form, is_published: e.target.checked })}
                  className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <label htmlFor="ann-published" className="text-sm text-gray-700 dark:text-gray-300">{t("admin.published")}</label>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                type="submit"
                disabled={saving}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
              >
                {saving ? t("common.loading") : t("common.save")}
              </button>
              <button
                type="button"
                onClick={cancelEdit}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
              >
                {t("common.cancel")}
              </button>
            </div>
          </form>
        </div>
      )}

      {loading ? (
        <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
      ) : (
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.titleField")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.type")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.published")}</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">Created</th>
                <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody>
              {announcements.map((ann) => (
                <tr key={ann.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">{ann.title}</td>
                  <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${typeColors[ann.type] || typeColors.notice}`}>
                      {ann.type}
                    </span>
                  </td>
                  <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${
                      ann.is_published
                        ? "bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-300"
                        : "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300"
                    }`}>
                      {ann.is_published ? t("admin.published") : t("admin.draft")}
                    </span>
                  </td>
                  <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                    {new Date(ann.created_at).toLocaleDateString()}
                  </td>
                  <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                    <div className="flex gap-1">
                      <button
                        onClick={() => startEdit(ann)}
                        className="px-2 py-1 text-xs bg-blue-600 hover:bg-blue-700 text-white rounded font-medium transition-colors"
                      >
                        {t("common.edit")}
                      </button>
                      <button
                        onClick={() => confirmDelete(ann.id)}
                        className="px-2 py-1 text-xs bg-red-600 hover:bg-red-700 text-white rounded font-medium transition-colors"
                      >
                        {t("common.delete")}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {announcements.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-gray-400">{t("common.noData")}</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      <ConfirmDialog
        open={confirmOpen}
        title="Delete Announcement"
        message="Are you sure you want to delete this announcement? This action cannot be undone."
        onConfirm={handleDelete}
        onCancel={() => { setConfirmOpen(false); setDeleteId(null); }}
      />
    </div>
  );
}
