import type { Session } from "@/lib/api";
import { getShotName, getModeName, getLevelName, formatDuration, formatDateTime, getTerminationName } from "@/lib/utils";

export default function SessionTable({ sessions }: { sessions: Session[] }) {
  if (sessions.length === 0) {
    return <p className="text-gray-500 dark:text-gray-400 text-sm py-4 text-center">No sessions found</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-gray-200 dark:border-gray-700 text-left text-gray-500 dark:text-gray-400">
            <th className="pb-2 pr-3 font-medium">Time</th>
            <th className="pb-2 pr-3 font-medium">Type</th>
            <th className="pb-2 pr-3 font-medium">Mode</th>
            <th className="pb-2 pr-3 font-medium">Lv</th>
            <th className="pb-2 pr-3 font-medium">Duration</th>
            <th className="pb-2 pr-3 font-medium">Complete</th>
            <th className="pb-2 font-medium">End Reason</th>
          </tr>
        </thead>
        <tbody className="text-gray-900 dark:text-gray-100">
          {sessions.map((s) => (
            <tr key={s.id} className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-2 pr-3 whitespace-nowrap">{formatDateTime(s.start_time)}</td>
              <td className="py-2 pr-3">{getShotName(s.shot_type)}</td>
              <td className="py-2 pr-3">{getModeName(s.device_mode)}</td>
              <td className="py-2 pr-3">{getLevelName(s.level)}</td>
              <td className="py-2 pr-3">{formatDuration(s.working_duration)}</td>
              <td className="py-2 pr-3">{s.completion_percent}%</td>
              <td className="py-2">{getTerminationName(s.termination_reason)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
