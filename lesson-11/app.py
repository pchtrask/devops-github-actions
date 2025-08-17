#!/usr/bin/env python3
"""
Vulnerable Flask Microservice for DevSecOps Demo
This application contains intentional security vulnerabilities for educational purposes.
DO NOT USE IN PRODUCTION!
"""

import os
import sqlite3
import subprocess
import pickle
import hashlib
from flask import Flask, request, jsonify, render_template_string
import requests

app = Flask(__name__)

# Intentional vulnerability: Hardcoded secret key (SAST will catch this)
app.secret_key = "super_secret_hardcoded_key_123"

# Intentional vulnerability: Database connection without proper error handling
def get_db_connection():
    conn = sqlite3.connect('users.db')
    conn.row_factory = sqlite3.Row
    return conn

# Initialize database
def init_db():
    conn = get_db_connection()
    conn.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            email TEXT
        )
    ''')
    # Insert some test data
    conn.execute("INSERT OR IGNORE INTO users (id, username, password, email) VALUES (1, 'admin', 'password123', 'admin@example.com')")
    conn.execute("INSERT OR IGNORE INTO users (id, username, password, email) VALUES (2, 'user', 'user123', 'user@example.com')")
    conn.commit()
    conn.close()

@app.route('/')
def home():
    return jsonify({
        "message": "Welcome to the Vulnerable Microservice API",
        "endpoints": [
            "/api/users",
            "/api/login",
            "/api/search",
            "/api/execute",
            "/api/deserialize",
            "/api/hash",
            "/api/proxy"
        ]
    })

# Intentional vulnerability: SQL Injection (DAST will catch this)
@app.route('/api/users')
def get_users():
    user_id = request.args.get('id', '')
    conn = get_db_connection()
    
    # Vulnerable SQL query - direct string concatenation
    query = f"SELECT * FROM users WHERE id = {user_id}" if user_id else "SELECT * FROM users"
    
    try:
        cursor = conn.execute(query)
        users = cursor.fetchall()
        conn.close()
        
        return jsonify([dict(user) for user in users])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Intentional vulnerability: Weak authentication
@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username', '')
    password = data.get('password', '')
    
    conn = get_db_connection()
    
    # Vulnerable SQL query - SQL injection possible
    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    
    try:
        cursor = conn.execute(query)
        user = cursor.fetchone()
        conn.close()
        
        if user:
            return jsonify({"message": "Login successful", "user": dict(user)})
        else:
            return jsonify({"message": "Invalid credentials"}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Intentional vulnerability: XSS through template injection
@app.route('/api/search')
def search():
    query = request.args.get('q', '')
    
    # Vulnerable template rendering - XSS possible
    template = f"""
    <html>
    <body>
        <h1>Search Results</h1>
        <p>You searched for: {query}</p>
        <p>Results would be displayed here...</p>
    </body>
    </html>
    """
    
    return render_template_string(template)

# Intentional vulnerability: Command injection
@app.route('/api/execute', methods=['POST'])
def execute_command():
    data = request.get_json()
    command = data.get('command', '')
    
    if not command:
        return jsonify({"error": "No command provided"}), 400
    
    try:
        # Vulnerable command execution - command injection possible
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return jsonify({
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Intentional vulnerability: Insecure deserialization
@app.route('/api/deserialize', methods=['POST'])
def deserialize_data():
    data = request.get_data()
    
    try:
        # Vulnerable deserialization - arbitrary code execution possible
        obj = pickle.loads(data)
        return jsonify({"message": "Deserialized successfully", "data": str(obj)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Intentional vulnerability: Weak cryptographic hash
@app.route('/api/hash', methods=['POST'])
def hash_data():
    data = request.get_json()
    text = data.get('text', '')
    
    if not text:
        return jsonify({"error": "No text provided"}), 400
    
    # Vulnerable hash function - MD5 is cryptographically broken
    md5_hash = hashlib.md5(text.encode()).hexdigest()
    
    return jsonify({
        "original": text,
        "md5_hash": md5_hash
    })

# Intentional vulnerability: Server-Side Request Forgery (SSRF)
@app.route('/api/proxy', methods=['POST'])
def proxy_request():
    data = request.get_json()
    url = data.get('url', '')
    
    if not url:
        return jsonify({"error": "No URL provided"}), 400
    
    try:
        # Vulnerable proxy - SSRF possible
        response = requests.get(url, timeout=10)
        return jsonify({
            "status_code": response.status_code,
            "content": response.text[:1000]  # Limit content length
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Intentional vulnerability: Information disclosure
@app.route('/api/debug')
def debug_info():
    return jsonify({
        "environment_variables": dict(os.environ),
        "current_directory": os.getcwd(),
        "python_path": os.sys.path
    })

if __name__ == '__main__':
    init_db()
    # Intentional vulnerability: Debug mode enabled in production
    app.run(host='0.0.0.0', port=5000, debug=True)
