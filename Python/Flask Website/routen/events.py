from flask import Blueprint, request, jsonify
from datenbank.database import add_like, create_event, delete_event
from datenbank.models import Event

events_bp = Blueprint('events', __name__, url_prefix='/events')

@events_bp.route('/addlike/<int:id>', methods=['POST'])
def route_add_like(id):
    return add_like(id)

@events_bp.route('/create', methods=['POST'])
def route_create_event():
    data = request.get_json()
    return create_event(
        data.get('name'),
        data.get('description'),
        data.get('date'),
        data.get('location'),
        data.get('category')
    )

@events_bp.route('/delete/<int:id>', methods=['POST'])
def route_delete_event(id):
    return delete_event(id)

@events_bp.route('/getall', methods=['GET'])
def get_events():
    allEvents = Event.query.all()
    return jsonify([
        {
            'id': e.id,
            'name': e.name,
            'date': e.date,
            'description': e.description,
            'location': e.location,
            'category': e.category,
            'likes': e.likes
        } for e in allEvents
    ])

@events_bp.route('/getlikes', methods=['GET'])
def get_likes():
    allEvents = Event.query.all()
    return jsonify([{'likes': e.likes, 'id': e.id} for e in allEvents])