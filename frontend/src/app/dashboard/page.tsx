'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';

interface Device {
  id: string;
  serial_number: string;
  model_name: string;
  firmware_version: string;
  ble_mac_address?: string;
  is_active: boolean;
  registered_at: string;
}

export default function DashboardPage() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [userEmail, setUserEmail] = useState('');
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    checkAuthAndLoadDevices();
  }, []);

  const checkAuthAndLoadDevices = async () => {
    try {
      const { data: { session }, error: authError } = await supabase.auth.getSession();

      if (authError || !session) {
        router.push('/login');
        return;
      }

      setUserEmail(session.user.email || '');

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/devices/list`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch devices');
      }

      const data = await response.json();
      setDevices(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load devices');
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();

      if (session) {
        await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/logout`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${session.access_token}`,
            'Content-Type': 'application/json',
          },
        });
      }

      await supabase.auth.signOut();
      router.push('/login');
    } catch (err: any) {
      setError('Logout failed');
    }
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-lg">로딩 중...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-primary-600">DualTetraX</h1>
            </div>
            <div className="flex items-center gap-4">
              <span className="text-sm text-gray-600">{userEmail}</span>
              <button
                onClick={handleLogout}
                className="px-4 py-2 text-sm text-gray-700 hover:text-gray-900"
              >
                로그아웃
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h2 className="text-3xl font-bold mb-2">내 디바이스</h2>
          <p className="text-gray-600">등록된 DualTetraX 디바이스를 관리하세요</p>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-600">
            {error}
          </div>
        )}

        <div className="mb-6">
          <button
            onClick={() => router.push('/devices/register')}
            className="px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition"
          >
            + 디바이스 등록
          </button>
        </div>

        {devices.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            <div className="text-gray-400 text-6xl mb-4">📱</div>
            <h3 className="text-xl font-semibold mb-2">등록된 디바이스가 없습니다</h3>
            <p className="text-gray-600 mb-6">
              새 디바이스를 등록하여 관리를 시작하세요
            </p>
            <button
              onClick={() => router.push('/devices/register')}
              className="px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition"
            >
              첫 디바이스 등록하기
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {devices.map((device) => (
              <div
                key={device.id}
                className="bg-white rounded-lg shadow hover:shadow-lg transition p-6"
              >
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-lg font-semibold mb-1">{device.model_name}</h3>
                    <p className="text-sm text-gray-500">S/N: {device.serial_number}</p>
                  </div>
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-medium ${
                      device.is_active
                        ? 'bg-green-100 text-green-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {device.is_active ? '활성' : '비활성'}
                  </span>
                </div>

                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">펌웨어:</span>
                    <span className="font-medium">{device.firmware_version}</span>
                  </div>
                  {device.ble_mac_address && (
                    <div className="flex justify-between">
                      <span className="text-gray-600">BLE MAC:</span>
                      <span className="font-mono text-xs">{device.ble_mac_address}</span>
                    </div>
                  )}
                  <div className="flex justify-between">
                    <span className="text-gray-600">등록일:</span>
                    <span className="font-medium">
                      {new Date(device.registered_at).toLocaleDateString('ko-KR')}
                    </span>
                  </div>
                </div>

                <div className="mt-4 pt-4 border-t border-gray-100">
                  <button
                    className="w-full py-2 text-sm text-primary-600 hover:text-primary-700 font-medium"
                    onClick={() => router.push(`/devices/${device.id}`)}
                  >
                    상세 보기
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
