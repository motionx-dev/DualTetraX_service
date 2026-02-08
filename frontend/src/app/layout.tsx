import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'DualTetraX - Smart Beauty Device Management',
  description: 'Manage your DualTetraX devices and track your beauty routine',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
