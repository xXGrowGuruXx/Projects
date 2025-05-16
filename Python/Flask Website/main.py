from flask import Flask, render_template
from pathlib import Path
from datenbank.models import Event
from datenbank.database import db, create_db
from utils.message import success_message

from routen.admin import admin_bp
from routen.events import events_bp

app = Flask(__name__)

# Datenbank Setup
db_dir = Path(__file__).parent / "databases"
db_dir.mkdir(exist_ok=True)
app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{db_dir / 'events.db'}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

# Blueprints registrieren
app.register_blueprint(admin_bp)
app.register_blueprint(events_bp)

# Zusätzliche Routen
@app.route('/', methods=['GET'])
def dashboard():
    return render_template("dashboard.html")

@app.route('/admin/login', methods=['GET'])
def admin_login_page():
    return render_template("admin_login.html")

if __name__ == '__main__':
    create_db("events")
    success_message("Server is running...")
    app.run(port=7000, host="0.0.0.0")