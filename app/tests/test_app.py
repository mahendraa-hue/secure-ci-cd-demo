# Pengujian endpoint utama aplikasi demo dengan pytest + Flask test client.
import pytest

# Modul app.py mengekspor instance Flask bernama `app`.
from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as c:
        yield c


def test_get_root_returns_ok_json(client):
    res = client.get("/")
    assert res.status_code == 200
    assert res.is_json
    assert res.get_json() == {"status": "ok"}


def test_post_login_success(client):
    res = client.post(
        "/login",
        json={"username": "demo", "password": "demo123"},
        content_type="application/json",
    )
    assert res.status_code == 200
    body = res.get_json()
    assert body.get("ok") is True


def test_post_login_failure_wrong_password(client):
    res = client.post(
        "/login",
        json={"username": "demo", "password": "salah"},
        content_type="application/json",
    )
    assert res.status_code == 401
    assert res.get_json().get("ok") is False


def test_post_login_failure_missing_fields(client):
    res = client.post("/login", json={}, content_type="application/json")
    assert res.status_code == 401
