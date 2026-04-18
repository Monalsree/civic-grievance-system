from flask import Flask, jsonify, send_from_directory  # type: ignore
from flask_cors import CORS  # type: ignore
from config import Config  # type: ignore
from api_routes import api, init_db  # type: ignore
import os

app = Flask(__name__)
# Enable CORS to allow frontend requests from different origins
CORS(app, resources={r"/api/*": {"origins": ["*"]}})
app.config.from_object(Config)

# Register API blueprint
app.register_blueprint(api, url_prefix='/api')

# Ensure upload folder exists
os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)

# Initialize DB on first run
if not os.path.exists(Config.DATABASE_PATH):
    os.makedirs(os.path.dirname(Config.DATABASE_PATH), exist_ok=True)
    with app.app_context():
        init_db()
        print("✅ Database initialized from schema.sql")


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "Civic Grievance Backend"}), 200


@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "online",
        "message": "Welcome to Civic Grievance System API",
        "endpoints": {
            "health": "/health",
            "complaints":     "/api/complaints",
            "search":         "/api/complaints/search?q=<id_or_phone>",
            "complaint":      "/api/complaints/<id>",
            "update_status":  "/api/complaints/<id>/status",
            "notifications":  "/api/notifications",
            "analytics":      "/api/analytics/summary",
        }
    }), 200


if __name__ == '__main__':
    host = os.environ.get('FLASK_RUN_HOST', '0.0.0.0')
    port = int(os.environ.get('FLASK_RUN_PORT', '5000'))
    app.run(debug=True, port=port, host=host)
