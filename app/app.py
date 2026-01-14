from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>CI/CD Demo App</title>
        <style>
            body {
                font-family: 'Segoe UI', Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                margin: 0;
            }
            .container {
                background: white;
                padding: 40px 60px;
                border-radius: 16px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                text-align: center;
            }
            h1 {
                color: #333;
                margin-bottom: 10px;
            }
            .status {
                background: #4CAF50;
                color: white;
                padding: 8px 20px;
                border-radius: 20px;
                display: inline-block;
                margin: 20px 0;
            }
            .info {
                color: #666;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 CI/CD Demo App</h1>
            <div class="status">✓ Running</div>
            <p class="info">Deployed via Jenkins Pipeline on GKE</p>
            <p class="info">Version: 2.0.0</p>
        </div>
    </body>
    </html>
    """

@app.route("/health")
def health():
    return {"status": "healthy"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8090)
