import { existsSync } from 'node:fs';
import { loadEnvFile } from 'node:process';
import { fileURLToPath } from 'node:url';

const defaultEnvPath = fileURLToPath(new URL('../.env', import.meta.url));
const envPath = process.env.ASSALKOM_ADMIN_ENV_FILE ?? defaultEnvPath;
if (existsSync(envPath)) {
  loadEnvFile(envPath);
}

process.env.NODE_ENV ??= 'production';
process.env.ADMIN_BIND_HOST ??= '127.0.0.1';
process.env.PORT ??= '3210';

await import('../dist/index.js');
