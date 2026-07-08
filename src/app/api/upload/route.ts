export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

import { NextResponse } from 'next/server';

export async function POST() {
  return NextResponse.json(
    {
      error: 'Direct file uploads are disabled. Campaign images must be uploaded with the Cloudinary Upload Widget using /api/upload/config and /api/upload/sign.',
      uploadMode: 'cloudinary_widget_only',
    },
    { status: 410 }
  );
}
