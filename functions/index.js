const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Эта функция срабатывает автоматически, когда пользователь удаляется
 * из раздела Authentication в консоли Firebase.
 * Она находит документ пользователя в коллекции 'users' и удаляет его.
 */
exports.deleteUserDoc = functions.auth.user().onDelete((user) => {
  const uid = user.uid;
  console.log(`Пользователь ${uid} удален из Auth. Удаляю документ из Firestore...`);

  return admin.firestore().collection('users').doc(uid).delete()
    .then(() => {
      console.log(`Документ пользователя ${uid} успешно удален.`);
      return null;
    })
    .catch((error) => {
      console.error(`Ошибка при удалении документа пользователя ${uid}:`, error);
      return null;
    });
});
