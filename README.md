# secure-ci-cd-demo

[![Secure CI/CD Demo](https://github.com/Mahen/secure-ci-cd-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/Mahen/secure-ci-cd-demo/actions/workflows/ci.yml)

Pastikan nama repo di GitHub juga **`secure-ci-cd-demo`** (atau ubah kedua URL di badge agar cocok dengan `username/nama-repo` Anda).

Template repositori **Secure CI/CD Pipeline for Startup**: aplikasi Flask kecil, Docker, pengujian otomatis, SAST (Bandit), pemindaian image (Trivy), DAST (OWASP ZAP baseline), dan langkah deploy placeholder—siap di-fork untuk pembelajaran atau portofolio.

## Ringkasan proyek

| Aspek | Penjelasan |
|--------|------------|
| **Masalah** | Tim kecil sering mengirim kode tanpa gate keamanan berurutan; kerentanan baru terlihat terlambat. |
| **Solusi** | Pipeline GitHub Actions yang **berulang** dan **transparan**: test → SAST → scan image → DAST → artefak yang bisa diunduh untuk review. |
| **Hasil** | Satu alur yang bisa dijalankan di akun gratis, tanpa kredensial cloud wajib, dengan laporan Trivy dan ZAP sebagai bukti kerja. |

## Tech stack

- **Runtime:** Python 3.12, Flask  
- **Test:** pytest  
- **Container:** Docker  
- **CI:** GitHub Actions  
- **Keamanan OSS:** Bandit (SAST), Trivy (image scan), OWASP ZAP (baseline DAST)

**Contoh artefak di repo (tanpa menjalankan CI):** [docs/zap_report_example.html](docs/zap_report_example.html) — cuplikan HTML statis; laporan asli dari pipeline ada di artefak GitHub **`zap_report`** (berkas `zap_report.html`).

## Keputusan keamanan (threshold)

| Alat | Kebijakan di template | Alasan singkat |
|------|------------------------|----------------|
| **Bandit** | Gagal bila ada temuan **severity high** pada `app/` (folder `app/tests` dikecualikan) | Menghindari *noise* dari pola `assert` di tes, tetap ketat pada kode aplikasi. |
| **Trivy** | Gagal bila **HIGH** atau **CRITICAL** pada image `demo-app:ci` | Gate realistis untuk supply chain; sesuaikan base image atau digest jika CVE upstream mengganggu demo. |
| **ZAP baseline** | **Tidak** menggagalkan job (`fail_action: false`); laporan tetap diunduh | Baseline sering berisi *low/informational*; tinjau HTML lalu ubah ke `fail_action: true` jika tim siap. |

**Opsi demo jika Trivy sering merah:** pada kedua step `aquasecurity/trivy-action` di `.github/workflows/ci.yml`, tambahkan `ignore-unfixed: "true"` agar hanya CVE yang sudah ada perbaikan vendor yang dihitung—dokumentasikan di commit/PR bahwa ini untuk stabilitas demo, bukan kebijakan produksi.

## Struktur repositori

```
secure-ci-cd-demo/
├─ app/
│  ├─ app.py
│  ├─ requirements.txt
│  ├─ tests/
│  │  └─ test_app.py
├─ Dockerfile
├─ .github/workflows/ci.yml
├─ infra/deploy_example.sh
├─ docs/
│  ├─ architecture.png
│  └─ zap_report_example.html
├─ README.md
└─ LICENSE
```

*(Opsional untuk portofolio: tambahkan berkas `docs/demo.gif` setelah rekam layar pipeline—tidak wajib ada di template awal.)*

## Menjalankan secara lokal

Perintah di bawah ini cocok untuk **Linux/macOS** (dan WSL di Windows). Pastikan Docker dan Python 3.12+ terpasang.

### Build & jalankan kontainer

```bash
docker build -t demo-app:local .
docker run --rm -p 5000:5000 demo-app:local
```

Uji cepat di terminal lain:

```bash
curl -s http://127.0.0.1:5000/
curl -s -X POST http://127.0.0.1:5000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"demo123"}'
```

Kredensial yang **diterima** aplikasi demo hanya `demo` / `demo123`. Kombinasi seperti `admin`/`password` akan mengembalikan **401** (cocok untuk uji negatif).

### Unit test (pytest)

```bash
cd app
python -m pip install -r requirements.txt
pytest tests/ -v
cd ..
```

### SAST — Bandit

Instal Bandit (`pip install bandit`), lalu dari **akar repositori**:

```bash
# Laporan ke layar (abaikan asserts di folder tests)
bandit -r app/ -x app/tests

# Hanya temuan severity **high** ke atas (selaras dengan gate di CI)
bandit -r app/ -x app/tests --severity-level high

# Contoh keluaran JSON untuk dokumentasi
bandit -r app/ -x app/tests -f json -o bandit-report.json
```

> **Gating di CI:** job `security-scan` memanggil `bandit -r app/ -x app/tests --severity-level high` dan akan **gagal** jika ada temuan level tersebut pada kode aplikasi.

### Image scan — Trivy

```bash
# Pasang Trivy: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
trivy image --severity HIGH,CRITICAL demo-app:local
```

### DAST — OWASP ZAP baseline (lokal)

Jalankan aplikasi di port 5000 (Docker atau `python app/app.py` dari folder `app`), lalu:

```bash
docker pull ghcr.io/zaproxy/zaproxy:stable
docker run --rm --network host -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:5000 -J zap-report.json
```

Di **macOS/Windows**, ganti target dengan `http://host.docker.internal:5000` jika `--network host` tidak memetakan ke host Anda:

```bash
docker run --rm -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://host.docker.internal:5000
```

Laporan HTML biasanya ditulis ke berkas seperti `report_html.html` (lihat dokumentasi ZAP untuk opsi `-r`).

## Penjelasan CI (`.github/workflows/ci.yml`)

Alur berjalan **berurutan** dalam tiga job:

1. **`build-test`**  
   Checkout → Python → `pip install` → **pytest** pada `app/tests/`.

2. **`security-scan`** (butuh `build-test` sukses)  
   - **Bandit:** `bandit -r app/ -x app/tests --severity-level high` → gagal bila ada temuan **high**. Artefak JSON opsional (`bandit-report`).  
   - **Docker build** image `demo-app:ci`.  
   - **Trivy:** simpan `trivy-report.txt` (selalu), lalu scan dengan **`--exit-code 1`** untuk **HIGH,CRITICAL** → **gate** ketat.  
   - **Kontainer:** `docker run -d -p 5000:5000`.  
   - **ZAP baseline** ke `http://localhost:5000` dengan **`fail_action: false`** → temuan High/Critical **tidak** menghentikan pipeline secara otomatis.  
   - Nama artefak di GitHub: **`bandit-report`**, **`trivy-report`**, **`zap_scan`** (laporan mentah action), dan **`zap_report`** (berisi **`zap_report.html`** untuk dipamerkan).

3. **`deploy`** (butuh `security-scan` sukses)  
   Menjalankan **`infra/deploy_example.sh`** (hanya *echo* placeholder). Ganti isi script dan tambahkan **GitHub Secrets** untuk deploy nyata (Render/Heroku/AWS, dll.).

### Mengubah ZAP agar mem-fail pada alert tertentu

Secara default `fail_action` bernilai `false`. Untuk menggagalkan job bila ZAP menemukan alert:

- Set `fail_action: true` pada step `zaproxy/action-baseline`, **atau**  
- Tambahkan opsi baris perintah ZAP (misalnya ambang risiko) melalui input `cmd_options` pada action—sesuaikan dengan [dokumentasi ZAP Baseline](https://www.zaproxy.org/docs/docker/baseline-scan/).

**Peringatan:** baseline bisa menghasilkan banyak *low/informational*; untuk portofolio, seringkali lebih masuk akal meninjau HTML dan memutuskan kebijakan tim.

## Memicu workflow di GitHub

- **Otomatis:** push ke branch `main`.  
- **Manual:** tab **Actions** → pilih workflow **Secure CI/CD Demo** → **Run workflow**.

## Mempublikasikan hasil ke LinkedIn

**Hook singkat (3–4 kalimat):**

> Saya merakit pipeline CI/CD “secure by default” untuk startup: setiap merge ke `main` menjalankan test, SAST Bandit, scan image Trivy (gagal pada HIGH/CRITICAL), dan DAST OWASP ZAP baseline terhadap aplikasi kontainer. Artefak run berisi laporan yang bisa saya lampirkan sebagai bukti proses, bukan hanya screenshot hijau. Template ini sengaja provider-agnostic agar mudah di-fork tanpa biaya cloud wajib.

**Artefak visual yang disarankan:**

- `docs/architecture.png` — diagram alur pipeline  
- Screenshot tab **Actions** (tiga job hijau)  
- Unduhan artefak **`zap_report`** (bukan `zap-report`) dan **`trivy-report`**  
- GIF singkat: `curl` ke `/` dan `/login` pada kontainer lokal  

## Checklist sebelum publish

- [ ] Semua unit test lulus lokal (`pytest`).  
- [ ] Image Docker build & run lokal; `curl` ke `/` dan `/login` sesuai ekspektasi.  
- [ ] Workflow GitHub berhasil minimal sekali; artefak **Bandit / Trivy / ZAP** diunduh.  
- [ ] (Opsional) Simpan salinan laporan ke `docs/` untuk portofolio—jangan commit secret; **`docs/zap_report_example.html`** hanya contoh statis.  
- [ ] README: badge mengarah ke repo GitHub yang benar (`Mahen/secure-ci-cd-demo` atau sesuaikan); keputusan threshold terbaca di bagian **Keputusan keamanan**.  
- [ ] Repo **public** + `LICENSE`; `.gitignore` tidak mengabaikan file yang seharusnya ada.  
- [ ] GIF/screenshot demo (mis. `docs/demo.gif`) jika ingin posting LinkedIn kuat.

## Seri commit yang disarankan (milestone)

Gunakan urutan ini agar histori git rapi saat portofolio direview:

| Urutan | Pesan commit (contoh) | Isi perkiraan |
|--------|------------------------|---------------|
| 1 | `chore: initial secure-ci-cd-demo template` | Aplikasi Flask, Dockerfile, pytest, README, LICENSE. |
| 2 | `ci: add GitHub Actions pipeline (test, bandit, trivy, zap)` | `.github/workflows/ci.yml` lengkap. |
| 3 | `docs: add architecture diagram and ZAP example report` | `docs/architecture.png`, `zap_report_example.html`. |
| 4 | `chore: deploy placeholder and gitignore` | `infra/deploy_example.sh`, `.gitignore`. |
| 5 | `docs: README badge, security policy notes, publish checklist` | Perapihan dokumentasi & badge. |
| 6 | `docs: add demo gif for portfolio` | `docs/demo.gif` (setelah Anda rekam layar). |

Sesuaikan pesan dengan gaya tim Anda (Conventional Commits tetap disarankan).

## Estimasi biaya

| Opsi | Keterangan |
|------|------------|
| **GitHub Free** | Actions dengan kuota menit bulanan untuk akun pribadi/organisasi gratis—cukup untuk demo dan tugas kuliah. |
| **Render / Heroku free tier** | Cukup untuk deploy contoh kecil; perhatikan batas tidur/kuota. |
| **Lokal / Minikube** | Build, Trivy, ZAP, dan Docker **tanpa biaya** di mesin sendiri. |
| **Biaya kecil** | Domain sendiri, registry berbayar, atau cloud production skala kecil (beberapa dolar hingga puluhan USD/bulan tergantung trafik). |

Tidak ada kredensial nyata di repo ini—gunakan **GitHub Secrets** untuk token registry dan API cloud.

## Contoh output (verifikasi cepat)

Setelah `pytest`:

```
tests/test_app.py::test_get_root_returns_ok_json PASSED
tests/test_app.py::test_post_login_success PASSED
tests/test_app.py::test_post_login_failure_wrong_password PASSED
tests/test_app.py::test_post_login_failure_missing_fields PASSED
```

Setelah `curl http://127.0.0.1:5000/`:

```json
{"status":"ok"}
```

## Perintah salin-tempel (ringkas)

**Simulasi “pipeline lokal” minimal:**

```bash
cd app && pip install -r requirements.txt && pytest tests/ -v && cd ..
docker build -t demo-app:local .
bandit -r app/ -x app/tests --severity-level high
trivy image --severity HIGH,CRITICAL demo-app:local
```

**GitHub — jalankan workflow manual:** *Actions* → *Secure CI/CD Demo* → *Run workflow*.

---

Lisensi: lihat `LICENSE` (MIT).
