import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Hardcoded admin email matching IConst.adminEmail in your Dart code
const ADMIN_EMAIL = 'service@stimmapp.org';

export const deleteUserByAdmin = onCall(async (request) => {
	// 1. Ensure the caller is authenticated
	if (!request.auth) {
		throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
	}

	// 2. Ensure the caller is the Admin
	const callerEmail = request.auth.token.email;
	if (callerEmail !== ADMIN_EMAIL) {
		throw new HttpsError('permission-denied', 'Only admins can delete users.');
	}

	const uid = request.data.uid;
	if (!uid) {
		throw new HttpsError('invalid-argument', 'The function must be called with a "uid" argument.');
	}

	try {
		// 3. Delete from Authentication (this triggers onAccountDelete in user_cleanup.ts)
		await admin.auth().deleteUser(uid);

		// 4. Delete from Firestore immediately so the UI updates instantly
		await admin.firestore().collection('users').doc(uid).delete();

		return { success: true };
	} catch (error) {
		console.error("Error deleting user:", error);
		throw new HttpsError('internal', 'Unable to delete user.');
	}
});
