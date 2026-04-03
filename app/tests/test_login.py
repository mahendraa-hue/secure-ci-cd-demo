# Test endpoint login aplikasi Flask.
from app.app import app as flask_app


def test_post_login_success():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        res = client.post(
            "/login",
            json={"username": "demo", "password": "demo123"},
            content_type="application/json",
        )
        assert res.status_code == 200
        assert res.get_json().get("ok") is True


def test_post_login_failure_wrong_password():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        res = client.post(
            "/login",
            json={"username": "demo", "password": "salah"},
            content_type="application/json",
        )
        assert res.status_code == 401
        assert res.get_json().get("ok") is False
