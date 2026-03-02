import firebase_admin
from firebase_admin import credentials, messaging
import sys
import os

def send_test_notification(token_or_topic, is_topic=False):
    # Usar el archivo de# cred_path = '/tmp/firebase-auth.json' # local
    cred_path = '/tmp/firebase-auth-correct.json' # absolute path fix
    
    if not os.path.exists(cred_path):
        print(f"Error: No se encuentra el archivo de credenciales en {cred_path}")
        return

    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

    message = messaging.Message(
        notification=messaging.Notification(
            title='🚀 Prueba de ManiGraB',
            body='¡Felicidades! El sistema de notificaciones push está activo y funcionando.',
        ),
        topic='all' if is_topic else None,
        token=token_or_topic if not is_topic else None,
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                icon='stock_ticker_update',
                color='#FFD700',
                sound='default'
            ),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    alert=messaging.ApsAlert(
                        title='🚀 Prueba de ManiGraB',
                        body='¡Felicidades! El sistema de notificaciones push está activo y funcionando.',
                    ),
                    sound='default',
                ),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        print(f'✅ Mensaje enviado exitosamente: {response}')
    except Exception as e:
        print(f'❌ Error enviando mensaje: {e}')

if __name__ == '__main__':
    target = 'all' # Por defecto a un topic para que sea más fácil probar
    is_topic = True
    
    if len(sys.argv) > 1:
        target = sys.argv[1]
        is_topic = not target.startswith('topic:')
        if target.startswith('topic:'):
            target = target.replace('topic:', '')
            is_topic = True

    send_test_notification(target, is_topic)
