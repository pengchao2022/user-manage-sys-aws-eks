from flask import Flask, render_template, request, redirect, url_for, flash
import psycopg2
import os
import time
from datetime import datetime
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app():
    app = Flask(__name__)
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
        logger.info("🚀 Starting database initialization...")
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
                    logger.info("✅ Database initialized successfully - users table created/verified")
                    
                    # 验证表是否存在
                    cur.execute("SELECT to_regclass('public.users');")
                    table_exists = cur.fetchone()[0]
                    logger.info(f"📊 Users table exists: {table_exists is not None}")
                    
            except Exception as e:
                logger.error(f"❌ Database initialization error: {e}", exc_info=True)
            finally:
                conn.close()
        else:
            logger.error("❌ Failed to initialize database: no connection")

    # 在应用上下文中初始化数据库
    with app.app_context():
        init_db()

    # 您的路由定义...
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

    # 添加健康检查端点 - 重要！
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

        # 返回正确的状态码
        if db_status == 'healthy':
            return {
                'status': 'healthy',
                'database': db_status,
                'timestamp': datetime.utcnow().isoformat()
            }, 200
        else:
            return {
                'status': 'unhealthy', 
                'database': db_status,
                'timestamp': datetime.utcnow().isoformat()
            }, 503

    # 可选：添加一个简单的健康检查端点
    @app.route('/healthz')
    def healthz():
        """Simple health check endpoint"""
        return {'status': 'ok', 'timestamp': datetime.utcnow().isoformat()}, 200

    # 可选：添加就绪检查端点
    @app.route('/ready')
    def ready():
        """Readiness check endpoint"""
        try:
            conn = get_db_connection(max_retries=1, retry_delay=1)
            if conn:
                with conn.cursor() as cur:
                    cur.execute('SELECT 1')
                conn.close()
                return {'status': 'ready', 'database': 'connected'}, 200
            else:
                return {'status': 'not ready', 'database': 'disconnected'}, 503
        except Exception as e:
            return {'status': 'not ready', 'error': str(e)}, 503

    return app

app = create_app()

if __name__ == '__main__':
    # Warn if using default secret key in production
    if os.environ.get('SECRET_KEY') is None and os.environ.get('FLASK_ENV') == 'production':
        logger.warning("⚠️ WARNING: Using default secret key in production!")
    
    app.run(host='0.0.0.0', port=5000, debug=False)