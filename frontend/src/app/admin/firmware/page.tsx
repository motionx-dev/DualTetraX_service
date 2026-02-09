"use client";

import { useEffect, useState, useRef } from "react";
import { createClient } from "@/lib/supabase/client";
import {
  getAdminFirmware,
  createFirmware,
  getRollouts,
  createRollout,
  updateRollout,
  getFirmwareUploadUrl,
  getFirmwareDownloadUrl,
  computeSha256,
  FirmwareVersion,
  Rollout,
} from "@/lib/api";
import { useT } from "@/i18n/context";

function formatBytes(bytes: number): string {
  if (bytes < 1024) { return `${bytes} B`; }
  if (bytes < 1024 * 1024) { return `${(bytes / 1024).toFixed(1)} KB`; }
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

export default function AdminFirmwarePage() {
  const t = useT();
  const [loading, setLoading] = useState(true);
  const [versions, setVersions] = useState<FirmwareVersion[]>([]);
  const [rollouts, setRollouts] = useState<Rollout[]>([]);

  // firmware form
  const [fwVersion, setFwVersion] = useState("");
  const [fwCode, setFwCode] = useState("");
  const [fwChangelog, setFwChangelog] = useState("");
  const [fwActive, setFwActive] = useState(false);
  const [fwSaving, setFwSaving] = useState(false);
  const [fwFile, setFwFile] = useState<File | null>(null);
  const [uploadStatus, setUploadStatus] = useState("");
  const fileInputRef = useRef<HTMLInputElement>(null);

  // rollout form
  const [roFirmwareId, setRoFirmwareId] = useState("");
  const [roPercent, setRoPercent] = useState("100");
  const [roNotes, setRoNotes] = useState("");
  const [roSaving, setRoSaving] = useState(false);

  const [message, setMessage] = useState("");

  async function getToken() {
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    return session?.access_token || null;
  }

  async function loadAll() {
    const token = await getToken();
    if (!token) { return; }

    try {
      const [fwRes, roRes] = await Promise.all([
        getAdminFirmware(token),
        getRollouts(token),
      ]);
      setVersions(fwRes.firmware_versions);
      setRollouts(roRes.rollouts);
    } catch {}

    setLoading(false);
  }

  useEffect(() => {
    loadAll();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function handleCreateFirmware(e: React.FormEvent) {
    e.preventDefault();
    setFwSaving(true);
    setMessage("");
    setUploadStatus("");
    const token = await getToken();
    if (!token) { setFwSaving(false); return; }

    let binaryUrl: string | undefined;
    let binarySize: number | undefined;
    let binaryChecksum: string | undefined;

    if (fwFile) {
      try {
        // 1. Compute checksum
        setUploadStatus(t("admin.computingChecksum"));
        binaryChecksum = await computeSha256(fwFile);

        // 2. Get signed upload URL
        setUploadStatus(t("admin.uploading"));
        const uploadData = await getFirmwareUploadUrl(token, fwFile.name);

        // 3. Upload to Supabase Storage via signed URL
        const supabase = createClient();
        const { error: uploadError } = await supabase.storage
          .from("firmware")
          .uploadToSignedUrl(uploadData.path, uploadData.token, fwFile, {
            contentType: "application/octet-stream",
          });

        if (uploadError) {
          setMessage(t("admin.uploadFailed") + ": " + uploadError.message);
          setFwSaving(false);
          setUploadStatus("");
          return;
        }

        binaryUrl = uploadData.path;
        binarySize = fwFile.size;
        setUploadStatus(t("admin.uploadSuccess"));
      } catch (err) {
        setMessage(t("admin.uploadFailed") + (err instanceof Error ? ": " + err.message : ""));
        setFwSaving(false);
        setUploadStatus("");
        return;
      }
    }

    try {
      await createFirmware(token, {
        version: fwVersion,
        version_code: parseInt(fwCode, 10),
        changelog: fwChangelog || undefined,
        binary_url: binaryUrl,
        binary_size: binarySize,
        binary_checksum: binaryChecksum,
        is_active: fwActive,
      });
      setFwVersion("");
      setFwCode("");
      setFwChangelog("");
      setFwActive(false);
      setFwFile(null);
      if (fileInputRef.current) { fileInputRef.current.value = ""; }
      setMessage("Firmware version created.");
      await loadAll();
    } catch {
      setMessage("Failed to create firmware version.");
    }

    setFwSaving(false);
    setUploadStatus("");
  }

  async function handleDownload(path: string) {
    const token = await getToken();
    if (!token) { return; }
    try {
      const { download_url } = await getFirmwareDownloadUrl(token, path);
      window.open(download_url, "_blank");
    } catch {
      setMessage("Failed to generate download URL.");
    }
  }

  async function handleCreateRollout(e: React.FormEvent) {
    e.preventDefault();
    setRoSaving(true);
    setMessage("");
    const token = await getToken();
    if (!token) { return; }

    try {
      await createRollout(token, {
        firmware_version_id: roFirmwareId,
        target_percentage: parseInt(roPercent, 10),
        notes: roNotes || undefined,
      });
      setRoFirmwareId("");
      setRoPercent("100");
      setRoNotes("");
      setMessage("Rollout created.");
      await loadAll();
    } catch {
      setMessage("Failed to create rollout.");
    }

    setRoSaving(false);
  }

  async function handleUpdateRolloutStatus(rolloutId: string, newStatus: string) {
    const token = await getToken();
    if (!token) { return; }

    try {
      await updateRollout(token, rolloutId, { status: newStatus });
      await loadAll();
    } catch {}
  }

  function getNextStatuses(current: string): string[] {
    switch (current) {
      case "draft": return ["active"];
      case "active": return ["paused", "completed"];
      case "paused": return ["active", "completed"];
      default: return [];
    }
  }

  const statusColors: Record<string, string> = {
    draft: "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300",
    active: "bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-300",
    paused: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-300",
    completed: "bg-blue-100 text-blue-700 dark:bg-blue-900/50 dark:text-blue-300",
  };

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">{t("admin.firmware")}</h1>

      {message && (
        <div className={`mb-4 p-3 rounded-lg text-sm ${message.includes("Failed") || message.includes(t("admin.uploadFailed")) ? "bg-red-50 text-red-600 dark:bg-red-900/20 dark:text-red-400" : "bg-green-50 text-green-600 dark:bg-green-900/20 dark:text-green-400"}`}>
          {message}
        </div>
      )}

      {loading ? (
        <div className="text-center py-20 text-gray-400">{t("common.loading")}</div>
      ) : (
        <div className="space-y-8">
          {/* Firmware Versions */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{t("admin.firmware")}</h2>

            <div className="overflow-x-auto mb-6">
              <table className="w-full text-sm">
                <thead>
                  <tr>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.version")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.versionCode")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.binaryUrl")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("common.active")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.date")}</th>
                  </tr>
                </thead>
                <tbody>
                  {versions.map((v) => (
                    <tr key={v.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                      <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800 font-mono">{v.version}</td>
                      <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">{v.version_code}</td>
                      <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                        {v.binary_url ? (
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => handleDownload(v.binary_url!)}
                              className="text-blue-600 dark:text-blue-400 hover:underline text-xs"
                            >
                              {t("common.download")}
                            </button>
                            {v.binary_size && (
                              <span className="text-gray-400 text-xs">{formatBytes(v.binary_size)}</span>
                            )}
                          </div>
                        ) : (
                          <span className="text-gray-400 text-xs">-</span>
                        )}
                      </td>
                      <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                        <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${
                          v.is_active
                            ? "bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-300"
                            : "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300"
                        }`}>
                          {v.is_active ? t("common.yes") : t("common.no")}
                        </span>
                      </td>
                      <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                        {new Date(v.created_at).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                  {versions.length === 0 && (
                    <tr>
                      <td colSpan={5} className="py-8 text-center text-gray-400">{t("common.noData")}</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("admin.createVersion")}</h3>
            <form onSubmit={handleCreateFirmware} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.version")}</label>
                <input
                  type="text"
                  value={fwVersion}
                  onChange={(e) => setFwVersion(e.target.value)}
                  placeholder="e.g. 1.0.24"
                  required
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.versionCode")}</label>
                <input
                  type="number"
                  value={fwCode}
                  onChange={(e) => setFwCode(e.target.value)}
                  placeholder="e.g. 24"
                  required
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div className="sm:col-span-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.changelog")}</label>
                <textarea
                  value={fwChangelog}
                  onChange={(e) => setFwChangelog(e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              {/* Binary upload */}
              <div className="sm:col-span-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.uploadBinary")}</label>
                <div className="flex items-center gap-3">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept=".bin"
                    onChange={(e) => setFwFile(e.target.files?.[0] || null)}
                    className="block w-full text-sm text-gray-500 dark:text-gray-400
                      file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0
                      file:text-sm file:font-medium
                      file:bg-purple-50 file:text-purple-700
                      dark:file:bg-purple-900/30 dark:file:text-purple-300
                      hover:file:bg-purple-100 dark:hover:file:bg-purple-900/50
                      file:cursor-pointer file:transition-colors"
                  />
                </div>
                {fwFile && (
                  <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    {fwFile.name} ({formatBytes(fwFile.size)})
                  </p>
                )}
                {uploadStatus && (
                  <p className="mt-1 text-xs text-blue-600 dark:text-blue-400">{uploadStatus}</p>
                )}
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="fw-active"
                  checked={fwActive}
                  onChange={(e) => setFwActive(e.target.checked)}
                  className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <label htmlFor="fw-active" className="text-sm text-gray-700 dark:text-gray-300">{t("common.active")}</label>
              </div>

              <div className="flex items-end">
                <button
                  type="submit"
                  disabled={fwSaving}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
                >
                  {fwSaving ? t("admin.uploading") : t("admin.createVersion")}
                </button>
              </div>
            </form>
          </div>

          {/* Rollouts */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{t("admin.rollouts")}</h2>

            <div className="overflow-x-auto mb-6">
              <table className="w-full text-sm">
                <thead>
                  <tr>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.firmware")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.targetPercentage")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.status")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.date")}</th>
                    <th className="text-left py-2 px-3 text-gray-500 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">{t("admin.action")}</th>
                  </tr>
                </thead>
                <tbody>
                  {rollouts.map((ro) => (
                    <tr key={ro.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                      <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800 font-mono">
                        {ro.firmware_versions?.version || ro.firmware_version_id}
                      </td>
                      <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                        {ro.target_percentage}%
                      </td>
                      <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                        <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${statusColors[ro.status] || statusColors.draft}`}>
                          {ro.status}
                        </span>
                      </td>
                      <td className="py-2 px-3 text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800">
                        {new Date(ro.created_at).toLocaleDateString()}
                      </td>
                      <td className="py-2 px-3 border-b border-gray-100 dark:border-gray-800">
                        <div className="flex gap-1">
                          {getNextStatuses(ro.status).map((ns) => (
                            <button
                              key={ns}
                              onClick={() => handleUpdateRolloutStatus(ro.id, ns)}
                              className="px-2 py-1 text-xs bg-blue-600 hover:bg-blue-700 text-white rounded font-medium transition-colors"
                            >
                              {ns.charAt(0).toUpperCase() + ns.slice(1)}
                            </button>
                          ))}
                        </div>
                      </td>
                    </tr>
                  ))}
                  {rollouts.length === 0 && (
                    <tr>
                      <td colSpan={5} className="py-8 text-center text-gray-400">{t("common.noData")}</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">{t("admin.createRollout")}</h3>
            <form onSubmit={handleCreateRollout} className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.firmwareVersionId")}</label>
                <select
                  value={roFirmwareId}
                  onChange={(e) => setRoFirmwareId(e.target.value)}
                  required
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">{t("common.select")}</option>
                  {versions.map((v) => (
                    <option key={v.id} value={v.id}>{v.version} (code: {v.version_code})</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.targetPercentage")}</label>
                <input
                  type="number"
                  min="1"
                  max="100"
                  value={roPercent}
                  onChange={(e) => setRoPercent(e.target.value)}
                  required
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t("admin.notes")}</label>
                <input
                  type="text"
                  value={roNotes}
                  onChange={(e) => setRoNotes(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div className="sm:col-span-3">
                <button
                  type="submit"
                  disabled={roSaving}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
                >
                  {roSaving ? t("common.loading") : t("admin.createRollout")}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
