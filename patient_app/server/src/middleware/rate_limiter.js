const limitConfig = {
  minute: { limit: 10, windowMs: 60 * 1000 },
  hour: { limit: 100, windowMs: 60 * 60 * 1000 },
  day: { limit: 500, windowMs: 24 * 60 * 60 * 1000 },
};

const buckets = {
  minute: new Map(),
  hour: new Map(),
  day: new Map(),
};

function now() {
  return Date.now();
}

function prune(map, windowMs) {
  const cutoff = now() - windowMs;
  for (const [key, timestamps] of map.entries()) {
    const filtered = timestamps.filter((t) => t >= cutoff);
    if (filtered.length === 0) {
      map.delete(key);
    } else {
      map.set(key, filtered);
    }
  }
}

function record(map, key) {
  const existing = map.get(key) || [];
  existing.push(now());
  map.set(key, existing);
}

function isOverLimit(map, key, windowMs, limit) {
  const cutoff = now() - windowMs;
  const timestamps = (map.get(key) || []).filter((t) => t >= cutoff);
  map.set(key, timestamps);
  return timestamps.length >= limit;
}

export function rateLimiter(req, res, next) {
  const key = req.ip || req.headers['x-forwarded-for'] || 'unknown';

  prune(buckets.minute, limitConfig.minute.windowMs);
  prune(buckets.hour, limitConfig.hour.windowMs);
  prune(buckets.day, limitConfig.day.windowMs);

  const hitLimit =
    isOverLimit(buckets.minute, key, limitConfig.minute.windowMs, limitConfig.minute.limit) ||
    isOverLimit(buckets.hour, key, limitConfig.hour.windowMs, limitConfig.hour.limit) ||
    isOverLimit(buckets.day, key, limitConfig.day.windowMs, limitConfig.day.limit);

  if (hitLimit) {
    return res.status(429).json({
      error: {
        code: 'RATE_LIMIT',
        message: 'Too many requests. Please wait a moment.',
        retryable: true,
        correlationId: req.correlationId,
      },
    });
  }

  record(buckets.minute, key);
  record(buckets.hour, key);
  record(buckets.day, key);

  next();
}
