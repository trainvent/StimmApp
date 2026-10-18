const assert = require('node:assert/strict');
const {test} = require('node:test');
const privacy = require('../../functions/lib/participant_privacy');
const profile = {
  displayName: 'Creator', websiteUrl: 'https://example.org/me',
  email: 'private@example.org', address: 'Private address',
  givenName: 'Ada', surname: 'Example', dateOfBirth: 'Never public',
};

test('default profile is minimal; personal fields and saved links are omitted', () => {
  assert.deepEqual(privacy.publicProfile('author', profile), {
    uid: 'author', displayName: 'Creator', profilePictureUrl: null,
    hidePublications: false,
  });
});

test('each personal field requires its own explicit opt-in', () => {
  const name = privacy.publicProfile('author', {...profile, publicProfileShowFullName: true});
  assert.equal(name.givenName, 'Ada');
  assert.equal(name.surname, 'Example');
  assert.equal(Object.hasOwn(name, 'address'), false);
  assert.equal(Object.hasOwn(name, 'websiteUrl'), false);
  const address = privacy.publicProfile('author', {...profile, publicProfileShowAddress: true});
  assert.equal(address.address, 'Private address');
  assert.equal(Object.hasOwn(address, 'givenName'), false);
  const link = privacy.publicProfile('author', {...profile, publicProfileShowLink: true});
  assert.equal(link.websiteUrl, 'https://example.org/me');
  assert.equal(Object.hasOwn(link, 'email'), false);
  assert.equal(Object.hasOwn(link, 'dateOfBirth'), false);
});

test('false and malformed opt-ins never reveal details', () => {
  for (const enabled of [false, undefined, null, 'true', 1]) {
    const result = privacy.publicProfile('author', {...profile,
      publicProfileShowAddress: enabled, publicProfileShowFullName: enabled,
      publicProfileShowLink: enabled});
    for (const key of ['address', 'givenName', 'surname', 'websiteUrl']) {
      assert.equal(Object.hasOwn(result, key), false);
    }
  }
});

test('participant lists remain minimal even when profile details are opted in', () => {
  const shared = {...profile, publicProfileShowAddress: true, publicProfileShowFullName: true,
    publicProfileShowLink: true, signAnonymously: false};
  assert.deepEqual(privacy.publicParticipant('author', shared, {}).profile, {
    uid: 'author', displayName: 'Creator', profilePictureUrl: null,
  });
  assert.deepEqual(privacy.publicParticipant('author', {...shared, signAnonymously: true}, {}),
    {profile: {uid: '', signAnonymously: true}});
});

test('the public profile exposes the publications visibility preference', () => {
  assert.equal(privacy.publicProfile('author', {}).hidePublications, false);
  assert.equal(privacy.publicProfile('author', {hidePublications: true}).hidePublications, true);
});
