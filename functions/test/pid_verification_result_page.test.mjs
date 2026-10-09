import assert from 'node:assert/strict';
import test from 'node:test';
import { pidResultLanguage, pidResultPage } from '../lib/pid_verification_result_page.js';

test('callback uses German for StimmApp and English for Vivot, with a German fallback', () => {
  for (const [brand, language] of [['stimmapp', 'de'], ['vivot', 'en'], [undefined, 'de']]) {
    assert.match(pidResultPage('stimmapp://pid-verification', pidResultLanguage(brand)),
      new RegExp(`lang="${language}"`));
  }
});

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
