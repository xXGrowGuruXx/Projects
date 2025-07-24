import cv2
import face_recognition
import dlib
import pickle
import os

detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

def register_user():
    username = input("Benutzername für Registrierung: ").strip()
    if not username:
        print("Ungültiger Benutzername.")
        return

    data = {}
    if os.path.exists("face_encodings.pkl"):
        with open("face_encodings.pkl", "rb") as f:
            data = pickle.load(f)
        if username in data:
            print("Benutzername existiert bereits!")
            return

    cap = cv2.VideoCapture(0)
    print(f"Registrierung für {username}. Bitte still halten...")

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        faces = detector(rgb_frame)

        if len(faces) == 1:
            face = faces[0]
            x, y, w, h = face.left(), face.top(), face.width(), face.height()

            if w < 100 or h < 100:
                hint = "Komm näher an die Kamera."
            elif w > 300 or h > 300:
                hint = "Bitte etwas zurücktreten."
            else:
                hint = "Gesicht erkannt, Aufnahme läuft..."

                shape = predictor(rgb_frame, face)
                encoding = face_recognition.face_encodings(rgb_frame, known_face_locations=[(y, x+w, y+h, x)], num_jitters=1)

                if encoding:
                    data[username] = encoding[0]
                    with open("face_encodings.pkl", "wb") as f:
                        pickle.dump(data, f)
                    hint = f"Registrierung von {username} erfolgreich!"
                    cv2.putText(frame, hint, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                    cv2.imshow("Registrierung", frame)
                    cv2.waitKey(2000)
                    break
        else:
            hint = "Bitte genau 1 Gesicht vor die Kamera."

        cv2.putText(frame, hint, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        cv2.imshow("Registrierung", frame)

        if cv2.waitKey(1) & 0xFF == 27:
            print("Abbruch durch Nutzer")
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    register_user()