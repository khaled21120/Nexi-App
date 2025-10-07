const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendRoomNotification = functions.firestore
  .document('rooms/{roomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const roomId = context.params.roomId;
    if (!message) return null;

    // get room doc
    const roomRef = admin.firestore().collection('rooms').doc(roomId);
    const roomSnap = await roomRef.get();
    if (!roomSnap.exists) return null;
    const room = roomSnap.data();

    // members array, exclude sender
    const members = Array.isArray(room?.users) ? room.users : [];
    const recipients = members.filter(uid => uid !== message.authorId);
    if (recipients.length === 0) return null;

    // collect tokens
    const tokens = [];
    for (const uid of recipients) {
      const userSnap = await admin.firestore().collection('users').doc(uid).get();
      if (!userSnap.exists) continue;
      const userData = userSnap.data();
      if (userData?.fcmToken) tokens.push(userData.fcmToken);
    }
    if (tokens.length === 0) return null;

    // get sender name (optional)
    let senderName = 'Unknown';
    try {
      const senderSnap = await admin.firestore().collection('users').doc(message.authorId).get();
      if (senderSnap.exists) senderName = senderSnap.data().name || senderName;
    } catch (e) { /* ignore */ }

    // notification payload
    const payload = {
      notification: {
        title: `${senderName} • ${room?.name ?? 'Room'}`,
        body: message.text || '',
      },
      data: {
        type: 'room_chat',
        roomId: roomId,
        senderId: message.authorId || '',
        text: message.text || '',
      },
    };

    // send multicast
    const response = await admin.messaging().sendMulticast({
      tokens,
      ...payload,
    });

    // optionally: clean up invalid tokens (response.results)
    // (iterate response.responses and remove tokens that are invalid)
    return null;
  });
