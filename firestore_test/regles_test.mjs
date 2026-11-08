// Règles Firestore des favoris (lib/service/firestore.rules), jouées dans
// l'émulateur avec les mêmes lots d'écritures que l'appli
// (favorites_service.dart) et que le site (assets/favoris.js de
// l'extension « SPIPHOTO Site »).
// Lancement : cd firestore_test && npm install && npm test (Java requis).
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, writeBatch, increment, deleteField, serverTimestamp } from 'firebase/firestore';

const fichier = process.argv[2] ?? '../lib/service/firestore.rules';
const env = await initializeTestEnvironment({
  projectId: 'demo-spiphoto',
  firestore: { rules: readFileSync(fichier, 'utf8'), host: '127.0.0.1', port: 8080 },
});

const db = (uid, email = `${uid}@spiphoto.fr`) =>
  env.authenticatedContext(uid, { email }).firestore();
const chemins = { photoPath: '2026/05/a.jpg', vignettePath: '2026/05/a-320x320.jpg', ecranPath: '2026/05/a-1920.jpg' };

function ajout(d, uid, mediaId) {
  return writeBatch(d)
    .set(doc(d, 'favoriteEvents', `${uid}_${mediaId}`), { userId: uid, mediaId, ...chemins, createdAt: serverTimestamp() })
    .set(doc(d, 'photoStats', mediaId), {
      favoriteCount: increment(1), lastAddedAt: serverTimestamp(), ...chemins,
      membres: { [uid]: { ajout: serverTimestamp(), nom: uid } },
    }, { merge: true })
    .commit();
}
function retrait(d, uid, mediaId) {
  return writeBatch(d)
    .delete(doc(d, 'favoriteEvents', `${uid}_${mediaId}`))
    .set(doc(d, 'photoStats', mediaId), { favoriteCount: increment(-1), membres: { [uid]: deleteField() } }, { merge: true })
    .commit();
}
async function compteur(mediaId) {
  let n;
  await env.withSecurityRulesDisabled(async (c) => {
    const s = await getDoc(doc(c.firestore(), 'photoStats', mediaId));
    n = s.exists() ? s.data().favoriteCount : null;
  });
  return n;
}

const resultats = [];
async function cas(nom, attendu, fn) {
  let obtenu;
  try { await fn(); obtenu = 'accepté'; } catch (e) { obtenu = e.code === 'permission-denied' || /PERMISSION_DENIED|false for/.test(e.message) ? 'refusé' : `erreur ${e.code || e.message}`; }
  resultats.push({ nom, attendu, obtenu, ok: obtenu === attendu });
}

await env.clearFirestore();
const alice = db('alice'), bob = db('bob');

// ── Usage normal (appli et site) ──
await cas('1. ajout, fiche inexistante', 'accepté', () => ajout(alice, 'alice', '100'));
await cas('   → compteur = 1', 'accepté', async () => { if (await compteur('100') !== 1) throw new Error('compteur'); });
await cas('2. ajout par un 2e membre', 'accepté', () => ajout(bob, 'bob', '100'));
await cas('3. double ajout (idempotence)', 'refusé', () => ajout(alice, 'alice', '100'));
await cas('4. retrait', 'accepté', () => retrait(alice, 'alice', '100'));
await cas('5. retrait d\'un favori absent (idempotence)', 'refusé', () => retrait(alice, 'alice', '100'));
await cas('6. retrait du dernier membre (compteur → 0)', 'accepté', () => retrait(bob, 'bob', '100'));
await cas('7. ré-ajout sur fiche à 0', 'accepté', () => ajout(alice, 'alice', '100'));
await cas('   → compteur = 1', 'accepté', async () => { if (await compteur('100') !== 1) throw new Error(`compteur ${await compteur('100')}`); });

// ── Écritures directes hors de l'appli : le compteur suit les événements ──
await cas('8. +1 sur la fiche sans événement', 'refusé', () =>
  setDoc(doc(bob, 'photoStats', '100'), { favoriteCount: increment(1) }, { merge: true }));
await cas('9. -1 sur la fiche sans supprimer d\'événement', 'refusé', () =>
  setDoc(doc(bob, 'photoStats', '100'), { favoriteCount: increment(-1) }, { merge: true }));
await cas('10. création de fiche à 1 sans événement', 'refusé', () =>
  setDoc(doc(bob, 'photoStats', '200'), { favoriteCount: 1, ...chemins }));
await cas('11. événement seul, sans toucher au compteur', 'refusé', () =>
  setDoc(doc(bob, 'favoriteEvents', 'bob_100'), { userId: 'bob', mediaId: '100', ...chemins }));
await cas('12. suppression d\'événement seule', 'refusé', () =>
  deleteDoc(doc(alice, 'favoriteEvents', 'alice_100')));
await cas('13. +1 avec l\'événement d\'un autre membre', 'refusé', () =>
  writeBatch(bob)
    .set(doc(bob, 'favoriteEvents', 'bob_100'), { userId: 'bob', mediaId: '100', ...chemins })
    .set(doc(bob, 'photoStats', '100'), { favoriteCount: increment(2) }, { merge: true })
    .commit());
await cas('14. compte hors spiphoto.fr', 'refusé', () => ajout(db('eve', 'eve@gmail.com'), 'eve', '300'));

// ── Favori orphelin (événement sans fiche) : retrait impossible ──
await env.withSecurityRulesDisabled(async (c) =>
  setDoc(doc(c.firestore(), 'favoriteEvents', 'alice_999'), { userId: 'alice', mediaId: '999', ...chemins }));
await cas('15. retrait d\'un favori orphelin (sans fiche)', 'refusé', () => retrait(alice, 'alice', '999'));

console.log(`\nRègles : ${fichier}`);
for (const r of resultats) console.log(`${r.ok ? '✔' : '✘'} ${r.nom.padEnd(48)} attendu ${r.attendu.padEnd(8)} obtenu ${r.obtenu}`);
const echecs = resultats.filter((r) => !r.ok).length;
console.log(`${resultats.length - echecs}/${resultats.length} conformes`);
await env.cleanup();
process.exit(echecs ? 1 : 0);
