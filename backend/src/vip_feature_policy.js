/** Server-side VIP entitlement check for premium room Teacher AI.
 * Backdated/expired paid memberships do not grant access.
 * Existing admin/test grants with isVip true and no expiration remain valid.
 */
export function isActiveVipProfile(profile, now = Date.now()) {
  if (profile?.isVip !== true) return false;
  const expiry = profile.vipExpiresAt;
  if (expiry == null) return true;
  const date = typeof expiry.toDate === 'function'
    ? expiry.toDate()
    : expiry instanceof Date ? expiry : new Date(expiry);
  return Number.isFinite(date?.getTime()) && date.getTime() > now;
}

export async function requireRoomTeacherVip(db, uid) {
  if (!uid) {
    const error = new Error('Authentication required for Teacher AI.');
    error.status = 401;
    throw error;
  }
  const snap = await db.collection('users').doc(uid).get();
  if (!snap.exists || !isActiveVipProfile(snap.data())) {
    const error = new Error('VIP_REQUIRED: Room Teacher AI requires an active VIP membership.');
    error.status = 403;
    throw error;
  }
}
