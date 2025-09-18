from flask import Flask, jsonify
app = Flask(__name__)

@app.route("/backend/health")
def health():
    return jsonify({"status":"ok"})

@app.route("/backend/hello")
def hello():
    return jsonify({"message":"Hello from backend!"})