import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key'
    BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    DATABASE_PATH = os.path.join(BASE_DIR, 'database', 'grievances.db')
    SCHEMA_PATH = os.path.join(BASE_DIR, 'database', 'schema.sql')
    DATASET_PATH = os.path.join(BASE_DIR, 'database', 'complaints_1500.csv')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or f'sqlite:///{DATABASE_PATH}'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    ML_MODEL_PATH = os.path.join(BASE_DIR, 'ml_engine', 'model.pkl')
    VECTORIZER_PATH = os.path.join(BASE_DIR, 'ml_engine', 'vectorizer.pkl')
    UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')
    MAX_CONTENT_LENGTH = 5 * 1024 * 1024  # 5 MB max upload

    # AI provider configuration
    AI_PROVIDER = os.environ.get('AI_PROVIDER') or 'glm'
    GLM_API_KEY = os.environ.get('GLM_API_KEY') or '54e22e49116749b886dbfc677aae7c06.mdRlBJhs12sUPtCg'
    GLM_MODEL = os.environ.get('GLM_MODEL') or 'glm-5v-turbo'
    GLM_API_URL = os.environ.get('GLM_API_URL') or 'https://open.bigmodel.cn/api/paas/v4/chat/completions'

    # Optional Gemini fallback configuration
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY') or ''

    # Admin onboarding security key (must be provided for admin account creation)
    ADMIN_SETUP_KEY = os.environ.get('ADMIN_SETUP_KEY') or 'CHANGE_ME_ADMIN_SETUP_KEY'
