import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const targets = {petition: ["petitions", "signatures"], poll: ["polls", "votes"],
  survey: ["surveys", "responses"]} as const;
type Data = Record<string, any>;
const isAdmin = (request: CallableRequest) =>
  request.auth?.token.email === "service@trainvent.com";
function id(value: unknown): string {
  if (typeof value !== "string" || !value || value.includes("/") || value.length > 1500) {
    throw new HttpsError("invalid-argument", "Invalid document ID.");
  }
  return value;
}
export function publicProfile(uid: string, profile: Data): Data {
  return {uid, displayName: profile.displayName ?? null,
    profilePictureUrl: profile.profilePictureUrl ?? null};
}
export function publicParticipant(uid: string, profile: Data | undefined, participation: Data): Data {
  // Missing or malformed preferences must never reveal an identity.
  if (!profile || (profile.signAnonymously !== undefined && profile.signAnonymously !== false)) {
    return {profile: {uid: "", signAnonymously: true}};
  }
  return {profile: publicProfile(uid, profile),
    reason: typeof participation.reason === "string" ? participation.reason : null,
    signedAt: participation.signedAt?.toMillis?.() ?? null};
}
export function assertEvaluator(request: CallableRequest, form: Data): void {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  if (!isAdmin(request) && form.createdBy !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Only the creator or an administrator can export identities.");
  }
}
function encode(value: any): any {
  if (value instanceof admin.firestore.Timestamp) return {timestampMillis: value.toMillis()};
  if (Array.isArray(value)) return value.map(encode);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, field]) => [key, encode(field)]));
  }
  return value;
}
async function formFor(request: CallableRequest) {
  const type = request.data?.type as keyof typeof targets;
  if (!Object.prototype.hasOwnProperty.call(targets, type)) {
    throw new HttpsError("invalid-argument", "Invalid form type.");
  }
  const [collection, participation] = targets[type];
  const ref = admin.firestore().collection(collection).doc(id(request.data?.formId));
  const snapshot = await ref.get();
  if (!snapshot.exists) throw new HttpsError("not-found", "Form not found.");
  const form = snapshot.data()!;
  if (form.visibility === "group" && !isAdmin(request) && form.createdBy !== request.auth?.uid) {
    if (!request.auth || typeof form.groupId !== "string") {
      throw new HttpsError("permission-denied", "Group membership required.");
    }
    const group = await admin.firestore().collection("pollGroups").doc(form.groupId).get();
    if (!group.data()?.memberIds?.includes(request.auth.uid)) {
      throw new HttpsError("permission-denied", "Group membership required.");
    }
  }
  return {ref, participation, form};
}
async function participants(request: CallableRequest, evaluator: boolean) {
  const {ref, participation, form} = await formFor(request);
  if (evaluator) assertEvaluator(request, form);
  const offset = request.data?.offset ?? 0;
  if (!Number.isSafeInteger(offset) || offset < 0) {
    throw new HttpsError("invalid-argument", "Invalid pagination offset.");
  }
  const snapshot = await ref.collection(participation).orderBy(admin.firestore.FieldPath.documentId())
    .offset(offset).limit(200).get();
  const profiles = snapshot.empty ? [] : await admin.firestore().getAll(
    ...snapshot.docs.map(doc => admin.firestore().collection("users").doc(doc.id)));
  const entries = snapshot.docs.map((doc, index) => evaluator ?
    {...encode(doc.data()), profile: encode({...profiles[index].data(), uid: doc.id})} :
    publicParticipant(doc.id, profiles[index].data(), doc.data()));
  return {entries, nextOffset: snapshot.size === 200 ? offset + 200 : null};
}
export const getPublicParticipants = onCall(request => participants(request, false));
export const getParticipantResults = onCall(request => participants(request, true));
export const getPublicProfile = onCall(async request => {
  const uid = id(request.data?.uid);
  const snapshot = await admin.firestore().collection("users").doc(uid).get();
  return snapshot.exists ? publicProfile(uid, snapshot.data()!) : null;
});
