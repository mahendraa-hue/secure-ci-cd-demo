# Aplikasi demo Flask untuk pipeline CI/CD aman (uji unit & DAST).
from flask import Flask, jsonify, request

app = Flask(__name__)

# Kredensial demo statis — hanya untuk lingkungan contoh, jangan dipakai di produksi.
DEMO_USER = "demo"
DEMO_PASSWORD = "demo123"


@app.route("/")
def index():
    """Endpoint kesehatan sederhana untuk smoke test dan ZAP baseline."""
    return jsonify(status="ok")


@app.route("/login", methods=["POST"])
def login():
    """
    Endpoint login JSON untuk pengujian DAST (alur sukses / gagal).
    Body: {"username": "...", "password": "..."}
    """
    data = request.get_json(silent=True)
    # Hanya tolak bila body bukan JSON valid (bukan {} kosong — itu tetap 401).
    if data is None:
        return jsonify(error="invalid_json"), 400

    username = data.get("username")
    password = data.get("password")

    if username == DEMO_USER and password == DEMO_PASSWORD:
        return jsonify(ok=True, message="login_ok"), 200

    return jsonify(ok=False, message="unauthorized"), 401


if __name__ == "__main__":
    # host 0.0.0.0 agar kontainer Docker dapat menerima koneksi dari luar.
    app.run(host="0.0.0.0", port=5000)
