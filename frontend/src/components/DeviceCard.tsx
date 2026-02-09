import type { Device } from "@/lib/api";
import Link from "next/link";

export default function DeviceCard({ device }: { device: Device }) {
  const synced = device.last_synced_at
    ? new Date(device.last_synced_at).toLocaleDateString()
    : "Never";

  return (
    <Link
      href={`/devices/${device.id}`}
      className="block bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 hover:border-blue-400 dark:hover:border-blue-500 transition-colors"
    >
      <div className="flex items-start justify-between">
        <div>
          <h3 className="font-semibold text-gray-900 dark:text-white">{device.model_name}</h3>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{device.serial_number}</p>
        </div>
        <span
          className={`px-2 py-0.5 rounded-full text-xs font-medium ${
            device.is_active
              ? "bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300"
              : "bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
          }`}
        >
          {device.is_active ? "Active" : "Inactive"}
        </span>
      </div>
      <div className="mt-3 flex gap-4 text-xs text-gray-500 dark:text-gray-400">
        <span>FW: {device.firmware_version || "-"}</span>
        <span>Sessions: {device.total_sessions}</span>
        <span>Synced: {synced}</span>
      </div>
    </Link>
  );
}
