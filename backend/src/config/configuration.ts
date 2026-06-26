export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  database: {
    host: process.env.DATABASE_HOST ?? 'localhost',
    port: parseInt(process.env.DATABASE_PORT ?? '5432', 10),
    username: process.env.DATABASE_USER ?? 'souk_tchad',
    password: process.env.DATABASE_PASSWORD ?? 'souk_tchad_dev',
    name: process.env.DATABASE_NAME ?? 'souk_tchad',
  },
  jwt: {
    secret: process.env.JWT_SECRET ?? 'dev-secret-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  },
  google: {
    clientId: process.env.GOOGLE_CLIENT_ID ?? '',
    iosClientId: process.env.GOOGLE_IOS_CLIENT_ID ?? '',
  },
  upload: {
    dir: process.env.UPLOAD_DIR ?? 'uploads',
    maxListingsFreePlan: parseInt(
      process.env.MAX_LISTINGS_FREE_PLAN ?? '3',
      10,
    ),
  },
  smtp: {
    host: process.env.SMTP_HOST ?? 'mail.lws.fr',
    port: parseInt(process.env.SMTP_PORT ?? '587', 10),
    user: process.env.SMTP_USER ?? '',
    pass: process.env.SMTP_PASS ?? '',
    from: process.env.SMTP_FROM ?? 'noreply@souk-tchad.com',
  },
  app: {
    url: process.env.APP_URL ?? 'http://localhost:3000',
  },
  gemini: {
    apiKey: process.env.GEMINI_API_KEY ?? '',
    model: process.env.GEMINI_MODEL ?? 'gemini-2.5-flash',
    visionModel: process.env.GEMINI_VISION_MODEL ?? 'gemini-2.5-flash',
    rpmLimit: parseInt(process.env.GEMINI_RPM_LIMIT ?? '15', 10),
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID ?? '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL ?? '',
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n') ?? '',
  },
});
