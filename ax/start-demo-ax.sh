#!/bin/bash
set -e

echo "=== 1. Проверяем и настраиваем локальные пути ==="
mkdir -p ~/go/bin
export PATH=$PATH:~/go/bin
if ! grep -q 'export PATH=$PATH:~/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
    echo "✓ Путь ~/go/bin добавлен в ~/.bashrc"
fi

echo "=== 2. Проверка и установка Go (Golang) ==="
if ! command -v go &> /dev/null; then
    echo "Go не найден! Накатываем установку..."
    sudo apt-get update
    sudo apt-get install -y golang-go
    echo "✓ Go успешно установлен: $(go version)"
else
    echo "✓ Go уже на месте: $(go version)"
fi

echo "=== 3. Проверка и установка утилиты ko ==="
if ! command -v ko &> /dev/null; then
    echo "Компилятор 'ko' не найден! Собираем актуальную версию через Go..."
    # Ставим ko напрямую через установленный Go
    go install ://github.com
    echo "✓ Утилита ko успешно установлена в ~/go/bin"
else
    echo "✓ Утилита ko уже на месте: $(ko version)"
fi

echo "=== 4. Проверяем, что ядро Agent Substrate живо в K8s ==="
if ! command -v kubectl &> /dev/null; then
    echo "❌ Ошибка: на машине нет утилиты kubectl! Запустите сначала скрипт setup-env.sh"
    exit 1
fi

if ! kubectl get namespace | grep -q "ate-system"; then
    echo "❌ Ошибка: Ядро Substrate не обнаружено в запущенных пространствах Kubernetes!"
    echo "Сначала запустите скрипт ./start-demo.sh в папке ~/substrate"
    exit 1
fi
echo "✓ Базовый кластер Substrate активен"

echo "=== 5. Исправляем блокировки образов в конфигурации .ko.yaml ==="
# Заменяем cgr.dev (Chainguard) на gcr.io (Google Distroless), чтобы обойти 403 ошибку в РФ
if [ -f .ko.yaml ]; then
    if grep -q "cgr.dev/chainguard/static" .ko.yaml; then
        echo "Обнаружен заблокированный Chainguard-образ. Перебиваем настройки на distroless..."
        sed -i 's|cgr.dev/chainguard/static:latest|gcr.io/distroless/static-debian13:latest|g' .ko.yaml
        # Сбрасываем старый кэш, если он умудрился запомнить ошибку 403
        rm -rf ~/.ko/cache/
    fi
fi
echo "✓ Конфигурация .ko.yaml адаптирована под локальный деплой"

echo "=== 6. Компилируем и регистрируем CLI-инструмент 'ax' ==="
go install ./cmd/ax
echo "✓ Бинарник управления 'ax' собран"

echo "=== 7. Запускаем компиляцию и деплой Google AX в Kind ==="
make deploy AX_IMAGE_REPO=localhost:5001

echo "=== 8. Ожидаем полной готовности подов AX ==="
echo "Проверяем статус раллаута системных деплойментов..."
kubectl rollout status deployment/ax-redis -n ax-system --timeout=60s
kubectl rollout status deployment/ax-server -n ax-system --timeout=60s

echo "--------------------------------------------------------"
echo "=== GOOGLE AX УСПЕШНО СОБРАН И ЗАПУЩЕН! ==="
echo "Контур управления ИИ-агентами полностью готов."
echo "Проверьте статус вызова: ax --help"
echo "--------------------------------------------------------"

