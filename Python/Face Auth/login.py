import cv2
import face_recognition
import dlib
import pickle
import time
import os
import sys

# Funktion, um den Pfad zur Datei unabhängig von .exe oder .py zu finden
def resource_path(relative_path):
    try:
        # Für PyInstaller
        base_path = sys._MEIPASS
    except AttributeError:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, relative_path)

# Lade den Shape Predictor
predictor_path = resource_path("shape_predictor_68_face_landmarks.dat")
predictor = dlib.shape_predictor(predictor_path)
detector = dlib.get_frontal_face_detector()

# Lade die Encodings
def load_encodings():
    path = resource_path("face_encodings.pkl")
    if not os.path.exists(path):
        print("Keine registrierten Nutzer gefunden!")
        return None
    with open(path, "rb") as f:
        return pickle.load(f)

def login_user():
    data = load_encodings()
    if data is None:
        return

    usernames = list(data.keys())
    encodings = list(data.values())

    cap = cv2.VideoCapture(0)
    start_time = time.time()
    print("Starte Login. Bitte ruhig in die Kamera schauen...")

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        dlib_faces = detector(rgb_frame)

        if len(dlib_faces) == 0:
            hint = "Kein Gesicht erkannt. Bitte vor die Kamera."
        elif len(dlib_faces) > 1:
            hint = "Mehrere Gesichter erkannt. Bitte alleine vor die Kamera."
        else:
            face_rect = dlib_faces[0]
            x, y, w, h = face_rect.left(), face_rect.top(), face_rect.width(), face_rect.height()

            if w < 100 or h < 100:
                hint = "Komm näher an die Kamera."
            elif w > 300 or h > 300:
                hint = "Bitte etwas zurücktreten."
            else:
                hint = "Gesicht erkannt, vergleiche..."

                encoding = face_recognition.face_encodings(rgb_frame, known_face_locations=[(y, x+w, y+h, x)], num_jitters=1)

                if encoding:
                    matches = face_recognition.compare_faces(encodings, encoding[0])
                    if True in matches:
                        match_index = matches.index(True)
                        username = usernames[match_index]
                        hint = f"Login erfolgreich! Hallo {username}"
                        cv2.putText(frame, hint, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                        cv2.imshow("Login", frame)
                        cv2.waitKey(2000)
                        break
                    else:
                        hint = "Gesicht nicht erkannt!"

        cv2.putText(frame, hint, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        cv2.imshow("Login", frame)

        if time.time() - start_time > 30:
            print("Timeout: Kein erfolgreicher Login")
            break

        if cv2.waitKey(1) & 0xFF == 27:
            print("Abbruch durch Nutzer")
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    login_user()