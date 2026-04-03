#!/usr/bin/env bash
# Contoh langkah deploy (placeholder). Ganti nilai berikut dengan GitHub Secrets / variabel lingkungan Anda.
# Contoh secrets: REGISTRY_URL, REGISTRY_USER, REGISTRY_TOKEN, RENDER_API_KEY, AWS_ACCESS_KEY_ID, dll.
#
# Cara pakai di GitHub Actions:
#   - Simpan kredensial di Settings → Secrets and variables → Actions
#   - Injeksikan: echo "${{ secrets.MY_TOKEN }}" | docker login ... (jangan echo token ke log)
#
set -euo pipefail

echo "=== Deploy placeholder: secure-ci-cd-demo ==="
echo "Langkah nyata yang bisa Anda sambungkan:"
echo ""
echo "1) Build & tag image (sudah dilakukan di job security-scan jika perlu ulang):"
echo "   docker build -t YOUR_REGISTRY/demo-app:\${GITHUB_SHA} ."
echo ""
echo "2) Login registry (Docker Hub / GHCR / ECR):"
echo "   # echo \"\${REGISTRY_TOKEN}\" | docker login YOUR_REGISTRY -u \"\${REGISTRY_USER}\" --password-stdin"
echo ""
echo "3) Push image:"
echo "   # docker push YOUR_REGISTRY/demo-app:\${GITHUB_SHA}"
echo ""
echo "4) Render (contoh CLI — periksa dokumentasi terbaru):"
echo "   # render deploy --service YOUR_SERVICE_ID --image YOUR_REGISTRY/demo-app:\${GITHUB_SHA}"
echo ""
echo "5) Heroku (contoh):"
echo "   # heroku container:push web -a YOUR_APP"
echo "   # heroku container:release web -a YOUR_APP"
echo ""
echo "6) AWS (contoh ECS/Fargate):"
echo "   # aws ecs update-service --cluster CLUSTER --service SERVICE --force-new-deployment"
echo ""
echo "Deploy placeholder selesai (tidak ada perubahan infrastruktur nyata)."
