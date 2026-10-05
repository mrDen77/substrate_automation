#!/bin/bash
set -e

echo "=== 1. Проверяем и запускаем локальный кластер Kind ==="
if ! kind get clusters | grep -q "substrate-local"; then
    echo "Кластер не найден. Перезапускаем базовый скрипт..."
    hack/create-kind-cluster.sh
else
    echo "Кластер 'substrate-local' уже существует. Убедитесь, что контейнеры запущены в Docker Desktop."
fi

echo "=== 2. Применяем ядро Substrate (без тяжелого Envoy) ==="
./hack/install-ate-kind.sh --deploy-ate-system --credential-provider='{"enabled":false}'

echo "=== 3. Применяем демонстрационный счетчик ==="
# Накатываем манифесты напрямую, минуя зависающий на Windows шаг генерации golden-снапшота
kubectl apply -f demos/counter/manifests/ || ./hack/install-ate-kind.sh --deploy-demo-counter || true

echo "=== 4. Настраиваем локальный CLI-плагин ==="
export PATH=$PATH:~/go/bin

echo "=== 5. Создаем тестового актора (если еще не создан) ==="
if ! kubectl ate get actors --atespace ate-demo-counter | grep -q "my-counter-1"; then
    kubectl ate create actor my-counter-1 --atespace ate-demo-counter --template counter
else
    echo "Актор my-counter-1 уже существует и ждет запросов."
fi

echo "=== 6. Пробрасываем порт роутера на http://localhost:8000 ==="
echo "Теперь вы можете открыть второе окно терминала и выполнять:"
echo "curl -X POST -H \"ate-target-actor: ate-demo-counter/my-counter-1\" -i http://localhost:8000/"
echo "--------------------------------------------------------"
kubectl port-forward -n ate-system svc/atenet-router 8000:80

