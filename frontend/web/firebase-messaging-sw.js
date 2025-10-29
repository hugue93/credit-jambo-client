importScripts('https://www.gstatic.com/firebasejs/12.4.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.4.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDucjCR_QAtWQuyHnGlQsGFUpKR6EMobzA",
  authDomain: "savings-management-system.firebaseapp.com",
  projectId: "savings-management-system",
  storageBucket: "savings-management-system.appspot.com",
  messagingSenderId: "1042133409461",
  appId: "1:1042133409461:web:35a0174a86b804e53de8fc",
});

const messaging = firebase.messaging();

// Optional: show background notifications
messaging.onBackgroundMessage((payload) => {
  // eslint-disable-next-line no-console
  console.log('[fcm-sw] background payload:', payload);
  const n = payload.notification || {};
  self.registration.showNotification(n.title || 'Notification', {
    body: n.body || '',
    icon: '/favicon.png'
  });
});