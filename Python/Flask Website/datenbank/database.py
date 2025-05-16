from flask_sqlalchemy import SQLAlchemy
from datenbank.models import db, Event, Admin
from flask import Flask, request
from werkzeug.security import generate_password_hash, check_password_hash
from datenbank.config import get_database_uri
from pathlib import Path
from utils.message import success_message, error_message, info_message


def create_db(shop: str):
    uri = get_database_uri(shop)
    app = Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI'] = uri
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    db.init_app(app)

    with app.app_context():
        db_path = Path(get_database_uri(shop).replace("sqlite:///", ""))
        if not db_path.exists():
            db.create_all()
            init_database()
            success_message(f"[Database] ⚙️ Erstellt DB für '{shop}' unter {db_path}")

def init_database():
    info_message("[Database] Initialdaten werden gefüllt...")

    try:
        if not Event.query.first():
            eventsList = [
                Event(name='Python Workshop', date='2023-10-01', description='Learn Python from scratch', location='Room 101', category='workshops'),
                Event(name='Flask Workshop', date='2023-10-02', description='Learn Flask for web development', location='Room 102', category='workshops'),
                Event(name='Football Match', date='2023-10-03', description='Local team vs. rivals', location='Stadium', category='sport'),
                Event(name='Basketball Game', date='2023-10-04', description='Local team vs. rivals', location='Arena', category='sport'),
                Event(name='Rock Concert', date='2023-10-05', description='Live rock music', location='Concert Hall', category='concerts')
            ]
            db.session.add_all(eventsList)

        db.session.commit()
        success_message("[Database] Initialdaten wurden erfolgreich eingefügt.")
    except Exception as e:
        error_message(f"[Database] Initial-Fill fehlgeschlagen: {str(e)}")

def add_like(id):
    try:
        event = Event.query.get(id)
        if not event:
            error_message(f"Kein Event mit ID {id} gefunden.")
            return "[Datenbank Fehler]: Kein passendes Event gefunden!", 404

        event.likes = event.likes + 1 if event.likes else 1
        db.session.commit()
        success_message(f"Like für Event-ID {id} erfolgreich hinzugefügt.")
        return "[Datenbank Erfolg]: Like wurde erfolgreich vergeben.", 200
    except Exception as e:
        error_message(f"Fehler beim Hinzufügen des Likes: {str(e)}")
        return "[Datenbank Fehler]: beim einfügen ist ein Fehler aufgetreten.", 500
    
def create_event(name, description, date, location, category):
    try:
        new_event = Event(
            name=name,
            description=description,
            date=date,
            location=location,
            category=category,
            likes=0
        )

        db.session.add(new_event)
        db.session.commit()

        success_message(f"Event '{name}' wurde erfolgreich erstellt.")
        return "[Datenbank Erfolg]: Event wurde erstellt.", 201

    except Exception as e:
        error_message(f"Fehler beim Erstellen des Events: {str(e)}")
        return "[Datenbank Fehler]: Event konnte nicht erstellt werden.", 500
    
def delete_event(id):
    try:
        event = Event.query.get(id)
        if not event:
            error_message(f"[Datenbank Fehler]: Kein Event mit ID {id} gefunden.")
            return "Kein passendes Event gefunden!", 404

        db.session.delete(event)
        db.session.commit()

        success_message(f"[Datenbank Erfolg]: Event mit ID {id} erfolgreich gelöscht.")
        return "Event wurde gelöscht.", 200

    except Exception as e:
        error_message(f"[Datenbank Fehler]: Fehler beim Löschen des Events: {str(e)}")
        return "Event konnte nicht gelöscht werden.", 500
    
def admin_register(username, password):
    try:
        if Admin.query.filter_by(username=username).first():
            error_message(f"[Datenbank Fehler]: Registrierung fehlgeschlagen: Benutzer '{username}' existiert bereits.")
            return "Benutzername bereits vergeben.", 409

        hashed_pw = generate_password_hash(password)
        new_admin = Admin(username=username, password=hashed_pw)
        db.session.add(new_admin)
        db.session.commit()

        success_message(f"[Datenbank Erfolg]: Admin '{username}' erfolgreich registriert.")
        return "Registrierung erfolgreich.", 201

    except Exception as e:
        error_message(f"[Datenbank Fehler]: Fehler bei Registrierung: {str(e)}")
        return "Interner Fehler bei Registrierung.", 500

def admin_login(username, password):
    try:
        admin = Admin.query.filter_by(username=username).first()
        if not admin or not check_password_hash(admin.password, password):
            error_message(f"[Datenbank Fehler]: Login fehlgeschlagen für Benutzer '{username}'.")
            return "Ungültiger Benutzername oder Passwort.", 401

        success_message(f"[Datenbank Erfolg]: Admin '{username}' erfolgreich eingeloggt.")
        return "Login erfolgreich.", 200

    except Exception as e:
        error_message(f"[Datenbank Fehler]: Fehler beim Login: {str(e)}")
        return "Interner Fehler beim Login.", 500