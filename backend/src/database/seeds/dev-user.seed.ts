import * as bcrypt from 'bcrypt';
import { DataSource } from 'typeorm';
import { User, UserPlan } from '../../entities/user.entity';

const DEV_USERS = [
  {
    email: 'chogarfils3@gmail.com',
    password: 'Hassouni1',
    name: 'Chogar',
    phone: '+23566000000',
    plan: UserPlan.FREE,
  },
  {
    email: 'amina.test@souk-tchad.com',
    password: 'TestAmina1',
    name: 'Amina Test',
    phone: '+23566000001',
    plan: UserPlan.FREE,
  },
  {
    email: 'oumar@gmail.com',
    password: 'Oumar1',
    name: 'Oumar',
    phone: '+23566000002',
    plan: UserPlan.FREE,
  },
] as const;

export async function seedDevUser(dataSource: DataSource) {
  const usersRepository = dataSource.getRepository(User);

  for (const account of DEV_USERS) {
    const passwordHash = await bcrypt.hash(account.password, 10);
    const existing = await usersRepository.findOne({
      where: { email: account.email },
    });

    if (existing) {
      existing.passwordHash = passwordHash;
      existing.isEmailVerified = true;
      existing.name = account.name;
      existing.phone = account.phone;
      await usersRepository.save(existing);
      continue;
    }

    await usersRepository.save(
      usersRepository.create({
        email: account.email,
        name: account.name,
        passwordHash,
        plan: account.plan,
        phone: account.phone,
        isEmailVerified: true,
      }),
    );
  }

  // Sans SMTP configuré, débloquer les comptes créés mais non vérifiés.
  const smtpConfigured = process.env.SMTP_USER?.trim();
  if (!smtpConfigured) {
    await usersRepository
      .createQueryBuilder()
      .update(User)
      .set({ isEmailVerified: true })
      .where('isEmailVerified = :pending', { pending: false })
      .execute();
  }
}
