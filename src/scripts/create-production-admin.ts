import 'dotenv/config';
import { db } from '../db';
import { users, wallets } from '../db/schema';
import { hashPassword } from '../lib/auth';
import { createUniqueReferralCode } from '../lib/referrals';
import { eq } from 'drizzle-orm';

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

async function ensureWallet(userId: string) {
  const existingWallet = await db.query.wallets.findFirst({
    where: eq(wallets.userId, userId),
  });

  if (!existingWallet) {
    await db.insert(wallets).values({
      userId,
      balance: '0.00',
      pendingBalance: '0.00',
      totalEarnings: '0.00',
      totalSpent: '0.00',
    });
  }
}

async function main() {
  const email = requiredEnv('ADMIN_EMAIL').toLowerCase();
  const password = requiredEnv('ADMIN_PASSWORD');

  if (password.length < 12) {
    throw new Error('ADMIN_PASSWORD must be at least 12 characters for production safety');
  }

  const passwordHash = await hashPassword(password);
  const existingUser = await db.query.users.findFirst({
    where: eq(users.email, email),
  });

  if (existingUser) {
    await db.update(users)
      .set({
        passwordHash,
        role: 'admin',
        status: 'active',
        emailVerified: true,
        updatedAt: new Date(),
        referralCode: existingUser.referralCode || await createUniqueReferralCode(),
      })
      .where(eq(users.id, existingUser.id));

    await ensureWallet(existingUser.id);
    console.log(`✅ Admin account updated: ${email}`);
    return;
  }

  const [admin] = await db.insert(users).values({
    email,
    passwordHash,
    role: 'admin',
    status: 'active',
    firstName: process.env.ADMIN_FIRST_NAME?.trim() || 'Admin',
    lastName: process.env.ADMIN_LAST_NAME?.trim() || 'User',
    emailVerified: true,
    referralCode: await createUniqueReferralCode(),
  }).returning();

  await ensureWallet(admin.id);
  console.log(`✅ Admin account created: ${email}`);
}

main()
  .catch((error) => {
    console.error('❌ Admin bootstrap failed:', error);
    process.exit(1);
  });
