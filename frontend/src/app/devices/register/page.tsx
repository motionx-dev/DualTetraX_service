'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';

export default function RegisterDevicePage() {
  const [serialNumber, setSerialNumber] = useState('');
  const [modelName, setModelName] = useState('DualTetraX-01');
  const [firmwareVersion, setFirmwareVersion] = useState('');
  const [bleMacAddress, setBleMacAddress] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      router.push('/login');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const { data: { session } } = await supabase.auth.getSession();

      if (!session) {
        router.push('/login');
        return;
      }

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/devices/register`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          serial_number: serialNumber,
          model_name: modelName,
          firmware_version: firmwareVersion,
          ble_mac_address: bleMacAddress || undefined,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        if (response.status === 409) {
          setError('이미 등록된 시리얼 번호입니다');
        } else {
          setError(errorData.message || '디바이스 등록에 실패했습니다');
        }
        return;
      }

      alert('디바이스가 성공적으로 등록되었습니다!');
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.message || '디바이스 등록 중 오류가 발생했습니다');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <button
                onClick={() => router.push('/dashboard')}
                className="text-gray-600 hover:text-gray-900 mr-4"
              >
                ← 뒤로
              </button>
              <h1 className="text-2xl font-bold text-primary-600">DualTetraX</h1>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <div className="mb-8">
            <h2 className="text-3xl font-bold mb-2">디바이스 등록</h2>
            <p className="text-gray-600">새로운 DualTetraX 디바이스를 등록하세요</p>
          </div>

          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-600">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="serialNumber" className="block text-sm font-medium mb-2">
                시리얼 번호 *
              </label>
              <input
                id="serialNumber"
                type="text"
                required
                value={serialNumber}
                onChange={(e) => setSerialNumber(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                placeholder="예: DTX-20240101-001"
              />
              <p className="mt-1 text-xs text-gray-500">
                디바이스 뒷면에 표시된 시리얼 번호를 입력하세요
              </p>
            </div>

            <div>
              <label htmlFor="modelName" className="block text-sm font-medium mb-2">
                모델명 *
              </label>
              <select
                id="modelName"
                required
                value={modelName}
                onChange={(e) => setModelName(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              >
                <option value="DualTetraX-01">DualTetraX-01</option>
                <option value="DualTetraX-02">DualTetraX-02</option>
                <option value="DualTetraX-Pro">DualTetraX-Pro</option>
              </select>
            </div>

            <div>
              <label htmlFor="firmwareVersion" className="block text-sm font-medium mb-2">
                펌웨어 버전 *
              </label>
              <input
                id="firmwareVersion"
                type="text"
                required
                value={firmwareVersion}
                onChange={(e) => setFirmwareVersion(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                placeholder="예: v1.0.0"
              />
              <p className="mt-1 text-xs text-gray-500">
                설정 &gt; 정보에서 확인할 수 있습니다
              </p>
            </div>

            <div>
              <label htmlFor="bleMacAddress" className="block text-sm font-medium mb-2">
                BLE MAC 주소 (선택)
              </label>
              <input
                id="bleMacAddress"
                type="text"
                value={bleMacAddress}
                onChange={(e) => setBleMacAddress(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                placeholder="예: AA:BB:CC:DD:EE:FF"
              />
              <p className="mt-1 text-xs text-gray-500">
                블루투스 연결을 위한 MAC 주소 (선택사항)
              </p>
            </div>

            <div className="pt-4">
              <button
                type="submit"
                disabled={loading}
                className="w-full py-3 px-4 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition disabled:opacity-50"
              >
                {loading ? '등록 중...' : '디바이스 등록'}
              </button>
            </div>
          </form>

          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <h4 className="font-semibold text-blue-900 mb-2">💡 등록 안내</h4>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>• 시리얼 번호는 디바이스당 고유하며 한 번만 등록 가능합니다</li>
              <li>• 등록 후 모바일 앱에서 디바이스를 연결하여 사용할 수 있습니다</li>
              <li>• 펌웨어 업데이트 시 자동으로 버전이 갱신됩니다</li>
            </ul>
          </div>
        </div>
      </main>
    </div>
  );
}
