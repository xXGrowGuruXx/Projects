import cv2
import face_recognition
import dlib
import pickle
import os
import sys
import tkinter as tk
from tkinter import simpledialog, messagebox

def resource_path(relative_path):
    """Gibt absoluten Pfad zurück – funktioniert auch in .exe."""
    try:
        base_path = sys._MEIPASS  # Wenn gepackt mit PyInstaller
    except Exception:
        base_path = os.path.abspath(".")  # Wenn als .py ausgeführt
    return os.path.join(base_path, relative_path)

detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(resource_path("shape_predictor_68_face_landmarks.dat"))

def register_user():
    # Benutzername abfragen
    username = simpledialog.askstring("Registrierung", "Benutzername eingeben:")

    if not username:
        messagebox.showerror("Abbruch", "Kein Benutzername eingegeben. Registrierung abgebrochen.")
        exit()

    data_path = resource_path("face_encodings.pkl")
    data = {}

    # Wenn bereits Daten existieren
    if os.path.exists(data_path):
        with open(data_path, "rb") as f:
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
                encoding = face_recognition.face_encodings(
                    rgb_frame,
                    known_face_locations=[(y, x+w, y+h, x)],
                    num_jitters=1
                )

                if encoding:
                    data[username] = encoding[0]
                    with open(data_path, "wb") as f:
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