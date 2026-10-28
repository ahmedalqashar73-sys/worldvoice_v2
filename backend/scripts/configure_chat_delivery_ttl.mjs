// Expiry is a fallback for abandoned deliveries; the recipient deletes payload
// immediately after saving locally. TTL covers chunks independently of parents.
import {google} from 'googleapis';
const auth = new google.auth.GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/datastore'],
});
const client = await auth.getClient();
for (const group of ['delivery_queue', 'delivery_chunks']) {
  const name = `projects/worldvoice-37896/databases/(default)/collectionGroups/${group}/fields/expiresAt`;
  const base = `https://firestore.googleapis.com/v1/${name}`;
  const current = await client.request({url: base});
  if (['ACTIVE', 'CREATING'].includes(current.data.ttlConfig?.state)) {
    console.log(`Expiry already configured: ${group}`);
    continue;
  }
  await client.request({url: `${base}?updateMask=ttlConfig`, method: 'PATCH',
    data: {name, ttlConfig: {}}});
  console.log(`Expiry requested: ${group}`);
}
