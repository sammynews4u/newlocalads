import { SignJWT, jwtVerify } from 'jose';
import bcrypt from 'bcryptjs';
import { cookies } from 'next/headers';
import { db } from '@/db';
import { users, wallets, advertiserProfiles, publisherProfiles } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { createUniqueReferralCode } from '@/lib/referrals';

function getJwtSecret(): Uint8Array {
  const secret = process.env.JWT_SECRET || process.env.AUTH_SECRET;

  if (!secret && process.env.NODE_ENV === 'production' && process.env.NEXT_PHASE !== 'phase-production-build') {
    throw new Error('JWT_SECRET or AUTH_SECRET is required in production');
  }

  const resolved = secret || 'local-ad-network-secret-key-change-in-development-only';

  if (process.env.NODE_ENV === 'production' && process.env.NEXT_PHASE !== 'phase-production-build' && resolved.length < 32) {
    throw new Error('JWT_SECRET or AUTH_SECRET must be at least 32 characters in production');
  }

  return new TextEncoder().encode(resolved);
}

export interface JWTPayload {
  userId: string;
  email: string;
  role: 'admin' | 'advertiser' | 'publisher';
  iat?: number;
  exp?: number;
}

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password: string, hashedPassword: string): Promise<boolean> {
  return bcrypt.compare(password, hashedPassword);
}

export async function createToken(payload: Omit<JWTPayload, 'iat' | 'exp'>): Promise<string> {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(getJwtSecret());
}

export async function verifyToken(token: string): Promise<JWTPayload | null> {
  try {
    const { payload } = await jwtVerify(token, getJwtSecret());
    return payload as unknown as JWTPayload;
  } catch {
    return null;
  }
}

export async function getSession(): Promise<JWTPayload | null> {
  const cookieStore = await cookies();
  const token = cookieStore.get('auth_token')?.value;
  
  if (!token) return null;
  
  return verifyToken(token);
}

export async function getCurrentUser() {
  const session = await getSession();
  if (!session) return null;

  const user = await db.query.users.findFirst({
    where: eq(users.id, session.userId),
    with: {
      wallet: true,
      advertiserProfile: true,
      publisherProfile: true,
    },
  });

  return user;
}

export async function createUser(
  email: string,
  password: string,
  role: 'admin' | 'advertiser' | 'publisher',
  firstName?: string,
  lastName?: string
) {
  const passwordHash = await hashPassword(password);
  const referralCode = await createUniqueReferralCode();
  
  const [user] = await db.insert(users).values({
    email: email.toLowerCase(),
    passwordHash,
    role,
    firstName,
    lastName,
    status: role === 'admin' ? 'active' : 'pending',
    referralCode,
  }).returning();

  // Create wallet for user
  await db.insert(wallets).values({
    userId: user.id,
    balance: '0.00',
  });

  // Create profile based on role
  if (role === 'advertiser') {
    await db.insert(advertiserProfiles).values({
      userId: user.id,
    });
  } else if (role === 'publisher') {
    await db.insert(publisherProfiles).values({
      userId: user.id,
    });
  }

  return user;
}

export async function setAuthCookie(token: string) {
  const cookieStore = await cookies();
  cookieStore.set('auth_token', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7, // 7 days
    path: '/',
  });
}

export async function clearAuthCookie() {
  const cookieStore = await cookies();
  cookieStore.delete('auth_token');
}

export function requireRole(session: JWTPayload | null, roles: string[]): boolean {
  if (!session) return false;
  return roles.includes(session.role);
}
