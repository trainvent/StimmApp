import assert from 'node:assert/strict';
import test from 'node:test';
import { pidResultPage } from '../lib/pid_verification_result_page.js';

test('wallet return page localizes recovery without claiming verified or saved data', () => {
  const german = pidResultPage('stimmapp://pid-verification', 'de');
  assert.match(german, /lang="de"/);
  assert.match(german, /Falls die App nicht geöffnet wird/);
  assert.match(german, /keine Profildaten gespeichert/);
  const english = pidResultPage('https://example.test/pid-verification', 'en');
  assert.match(english, /lang="en"/);
  assert.match(english, /does not save profile data/);
  assert.match(english, /href="https:\/\/example.test\/pid-verification"/);
});
