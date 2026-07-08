export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

import { redirect } from 'next/navigation';
import { getCurrentUser } from '@/lib/auth';
import { DisputeCentre } from '@/components/features/dispute-centre';

export const metadata = {
  title: 'Dispute Centre | Local Ads',
};

export default async function DisputesPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect('/login');
  }

  return <DisputeCentre role={user.role} />;
}
