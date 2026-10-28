// Owner-only data. Keep authorization here so callers cannot accidentally
// expose viewer identities or private reaction totals to another viewer.
export async function readStoryActivity(ref, ownerId, viewerId, cursor = '') {
  if (viewerId !== ownerId) return {};
  const views = ref.collection('views');
  let query = views.orderBy('viewedAt', 'desc').limit(60);
  if (cursor) {
    if (typeof cursor !== 'string' || cursor.length > 150 || cursor.includes('/')) {
      const error = new Error('Invalid viewer cursor.'); error.status = 400; throw error;
    }
    const previous = await views.doc(cursor).get();
    if (previous.exists) query = query.startAfter(previous);
  }
  const [page, total] = await Promise.all([query.get(), views.count().get()]);
  const viewers = await Promise.all(page.docs.map(async doc => {
    const liked = await ref.collection('likes').doc(doc.id).get();
    const data = doc.data();
    return {uid: doc.id, displayName: data.displayName || 'WorldVoice',
      photoUrl: data.photoUrl || '', viewedAt: data.viewedAt?.toMillis?.() || 0,
      liked: liked.exists};
  }));
  return {viewsCount: total.data().count, viewers,
    nextViewCursor: page.docs.length === 60 ? page.docs.at(-1).id : null};
}
