from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Event(db.Model):
        __tablename__ = 'events'
        id = db.Column(db.Integer, primary_key=True, autoincrement=True)
        name = db.Column(db.String(100), nullable=False)
        date = db.Column(db.String(100), nullable=False)
        description = db.Column(db.String(200), nullable=False)
        location = db.Column(db.String(100), nullable=False)
        category = db.Column(db.String(100), nullable=False)
        likes = db.Column(db.Integer, default=0)

class Admin(db.Model):
        __tablename__='admins'
        id = db.Column(db.Integer, primary_key=True, autoincrement=True)
        username = db.Column(db.String(100), nullable=False)
        password = db.Column(db.String(100), nullable=False)