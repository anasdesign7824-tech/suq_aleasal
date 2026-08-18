process.env.NODE_ENV ??= 'production';
process.env.ADMIN_BIND_HOST ??= '127.0.0.1';
process.env.PORT ??= '3210';

await import('../dist/index.js');
