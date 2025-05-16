from flask import Blueprint, request
from datenbank.database import admin_login, admin_register

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

@admin_bp.route('/<mode>', methods=['POST'])
def route_admin_auth(mode):
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return "[Fehler]: Benutzername und Passwort sind erforderlich.", 400

    if mode == 'login':
        return admin_login(username, password)
    elif mode == 'register':
        return admin_register(username, password)
    else:
        return "Ungültiger Modus.", 400