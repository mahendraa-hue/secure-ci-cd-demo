# Test endpoint kesehatan aplikasi Flask.
from app.app import app as flask_app


def test_get_root_returns_ok_json():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        res = client.get("/")
        assert res.status_code == 200
        assert res.is_json
        assert res.get_json() == {"status": "ok"}
