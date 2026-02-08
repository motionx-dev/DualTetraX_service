import Link from 'next/link';

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-center font-mono text-sm">
        <h1 className="text-6xl font-bold text-center mb-8">
          DualTetraX
        </h1>

        <p className="text-xl text-center mb-12 text-gray-600">
          스마트 뷰티 디바이스 관리 플랫폼
        </p>

        <div className="flex gap-4 justify-center">
          <Link
            href="/login"
            className="px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition"
          >
            로그인
          </Link>

          <Link
            href="/signup"
            className="px-6 py-3 border border-primary-600 text-primary-600 rounded-lg hover:bg-primary-50 transition"
          >
            회원가입
          </Link>
        </div>

        <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
          <div className="p-6 border rounded-lg">
            <h3 className="text-xl font-bold mb-2">디바이스 관리</h3>
            <p className="text-gray-600">
              DualTetraX 디바이스를 등록하고 관리하세요
            </p>
          </div>

          <div className="p-6 border rounded-lg">
            <h3 className="text-xl font-bold mb-2">사용 통계</h3>
            <p className="text-gray-600">
              일별, 주별, 월별 사용 통계를 확인하세요
            </p>
          </div>

          <div className="p-6 border rounded-lg">
            <h3 className="text-xl font-bold mb-2">개인화 추천</h3>
            <p className="text-gray-600">
              피부 타입에 맞는 맞춤형 추천을 받으세요
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
