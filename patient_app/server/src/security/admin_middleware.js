// Simple admin access middleware. Expects req.user.roles to contain 'admin'.
export function requireAdmin(req, res, next) {
  const roles = req.user?.roles ?? [];
  if (roles.includes('admin')) {
    return next();
  }
  return res.status(403).json({ error: 'ADMIN_REQUIRED' });
}
