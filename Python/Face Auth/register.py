import cv2
import face_recognition
import dlib
import pickle
import time

# Lade dlib's face detector und shape predictor
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

def register_user():
    cap = cv2.VideoCapture(0)
    start_time = time.time()

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # dlib Gesichter erkennen (liefert Rechtecke)
        dlib_faces = detector(rgb_frame)

        # Anzeige "Bitte still halten" etc.
        if len(dlib_faces) == 0:
            hint = "Kein Gesicht erkannt, bitte ins Bild schauen"
        elif len(dlib_faces) > 1:
            hint = "Mehrere Gesichter erkannt, bitte alleine vor der Kamera"
        else:
            # Nur ein Gesicht erkannt -> weiter prüfen Größe / Position
            face_rect = dlib_faces[0]
            x, y, w, h = face_rect.left(), face_rect.top(), face_rect.width(), face_rect.height()

            # Hinweis, wenn Gesicht zu klein (zu weit weg)
            if w < 100 or h < 100:
                hint = "Bitte näher an die Kamera"
            else:
                hint = "Gesicht erkannt, bitte still halten"

                # Landmarken berechnen
                shape = predictor(rgb_frame, face_rect)

                # Face Encoding (auf Basis dlib Rechteck)
                encoding = face_recognition.face_encodings(rgb_frame, known_face_locations=[(y, x+w, y+h, x)], num_jitters=1)

                if encoding:
                    # Encoding speichern
                    with open("face_encoding.pkl", "wb") as f:
                        pickle.dump(encoding[0], f)

                    print("Registrierung erfolgreich!")
                    hint = "Registrierung erfolgreich!"
                    cv2.putText(frame, hint, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                    cv2.imshow("Register", frame)
                    cv2.waitKey(2000)  # 2 Sekunden Erfolg anzeigen
                    break

        # Text anzeigen
        cv2.putText(frame, hint, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        cv2.imshow("Register", frame)

        # Automatischer Timeout nach 30 Sekunden
        if time.time() - start_time > 30:
            print("Timeout: Kein Gesicht erkannt")
            break

        if cv2.waitKey(1) & 0xFF == 27:  # Escape zum Abbrechen
            print("Abbruch durch Nutzer")
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    register_user()