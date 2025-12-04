// Simple HTTPS enforcement middleware.
// Allows HTTP when HTTPS_ONLY is explicitly 'false' or NODE_ENV is development.
export function httpsEnforcer(req, res, next) {
  const httpsOnly =
    (process.env.HTTPS_ONLY ?? 'true').toLowerCase() !== 'false' &&
    process.env.NODE_ENV !== 'development' &&
    process.env.NODE_ENV !== 'test';

  if (!httpsOnly) {
    return next();
  }

  const forwarded = req.header('x-forwarded-proto');
  const isForwardedHttps =
    forwarded &&
    forwarded
      .split(',')
      .map((v) => v.trim().toLowerCase())
      .includes('https');

  const isSecure = req.secure || isForwardedHttps;
  if (isSecure) {
    return next();
  }

  return res.status(403).json({ error: 'HTTPS_REQUIRED' });
}
