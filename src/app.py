from flask import Flask, render_template, request, redirect, url_for, flash
import psycopg2
import os
import time
from datetime import datetime
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 使用环境变量或生成默认密钥
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-for-development-only')

# Database configuration
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'database': os.environ.get('DB_NAME', 'userdb'),
    'user': os.environ.get('DB_USER', 'appuser'),
    'password': os.environ.get('DB_PASSWORD', 'password'),
    'port': os.environ.get('DB_PORT', '5432')
}

def get_db_connection(max_retries=5, retry_delay=5):
    """Create and return a database connection with retry logic"""
    for attempt in range(max_retries):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            logger.info(f"Successfully connected to database on attempt {attempt + 1}")
            return conn
        except Exception as e:
            logger.warning(f"Database connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                logger.info(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                logger.error(f"All database connection attempts failed: {e}")
                return None

def init_db():
    """Initialize database tables with retry logic"""
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cur:
                cur.execute('''
                    CREATE TABLE IF NOT EXISTS users (
                        id SERIAL PRIMARY KEY,
                        email VARCHAR(255) UNIQUE NOT NULL,
                        first_name VARCHAR(100) NOT NULL,
                        last_name VARCHAR(100) NOT NULL,
                        phone VARCHAR(20),
                        company VARCHAR(100),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                conn.commit()
                logger.info("Database initialized successfully")
        except Exception as e:
            logger.error(f"Database initialization error: {e}")
        finally:
            conn.close()
    else:
        logger.error("Failed to initialize database: no connection")

@app.route('/')
def index():
    return redirect(url_for('register'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        # Get form data
        email = request.form.get('email')
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        phone = request.form.get('phone')
        company = request.form.get('company')

        # Basic validation
        if not email or not first_name or not last_name:
            flash('Please fill in all required fields', 'error')
            return render_template('register.html')

        # Save to database
        conn = get_db_connection()
        if conn:
            try:
                with conn.cursor() as cur:
                    cur.execute('''
                        INSERT INTO users (email, first_name, last_name, phone, company)
                        VALUES (%s, %s, %s, %s, %s)
                    ''', (email, first_name, last_name, phone, company))
                    conn.commit()
                flash('Registration successful!', 'success')
                return redirect(url_for('success'))
            except psycopg2.IntegrityError:
                flash('Email already exists. Please use a different email.', 'error')
            except Exception as e:
                flash('An error occurred. Please try again.', 'error')
                logger.error(f"Database error: {e}")
            finally:
                conn.close()
        else:
            flash('Database connection failed. Please try again later.', 'error')

    return render_template('register.html')

@app.route('/success')
def success():
    return render_template('success.html')

@app.route('/users')
def users():
    """Admin endpoint to view all registered users"""
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cur:
                cur.execute('SELECT * FROM users ORDER BY created_at DESC')
                users = cur.fetchall()
            return render_template('users.html', users=users)
        except Exception as e:
            flash('Error retrieving users', 'error')
            logger.error(f"Error: {e}")
        finally:
            conn.close()
    return render_template('users.html', users=[])

@app.route('/health')
def health():
    """Health check endpoint with database check"""
    try:
        # 测试数据库连接
        conn = get_db_connection(max_retries=1, retry_delay=1)
        if conn:
            with conn.cursor() as cur:
                cur.execute('SELECT 1')
            conn.close()
            db_status = 'healthy'
        else:
            db_status = 'unhealthy'
    except Exception as e:
        logger.error(f"Health check database error: {e}")
        db_status = 'unhealthy'

    return {
        'status': 'healthy',
        'database': db_status,
        'timestamp': datetime.utcnow().isoformat()
    }

if __name__ == '__main__':
    # Initialize database on startup with retry
    logger.info("Starting application...")
    init_db()
    
    # Warn if using default secret key in production
    if os.environ.get('SECRET_KEY') is None and os.environ.get('FLASK_ENV') == 'production':
        logger.warning("⚠️ WARNING: Using default secret key in production!")
    
    app.run(host='0.0.0.0', port=5000, debug=False)