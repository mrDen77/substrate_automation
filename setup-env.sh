#!/bin/bash
set -e

echo "=== 1. Проверка и настройка путей в ~/.bashrc ==="
if ! grep -q 'export PATH=$PATH:~/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
    echo "✓ Путь ~/go/bin добавлен в ~/.bashrc"
else
    echo "✓ Путь ~/go/bin уже прописан в ~/.bashrc"
fi
# Применяем пути для текущего процесса скрипта
export PATH=$PATH:~/go/bin
mkdir -p ~/go/bin

echo "=== 2. Проверка и установка Go (Golang) ==="
if ! command -v go &> /dev/null; then
    echo "Go не найден. Устанавливаем..."
    sudo apt update && sudo apt install golang-go -y
    echo "✓ Go успешно установлен"
else
    echo "✓ Go уже установлен: $(go version)"
fi

echo "=== 3. Проверка и установка kubectl ==="
if ! command -v kubectl &> /dev/null; then
    echo "kubectl не найден. Устанавливаем стабильную версию..."
    sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gpg
    
    # Скачиваем официальный ключ и репозиторий Kubernetes
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://k8s.io | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://k8s.io /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
    
    sudo apt-get update && sudo apt-get install -y kubectl
    echo "✓ kubectl успешно установлен"
else
    echo "✓ kubectl уже установлен: $(kubectl version --client --output=yaml | grep gitVersion)"
fi

echo "=== 4. Проверка и установка Kind ==="
if ! command -v kind &> /dev/null; then
    echo "Kind не найден. Скачиваем бинарник..."
    curl -Lo ./kind https://k8s.io
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "✓ Kind успешно установлен"
else
    echo "✓ Kind уже установлен: $(kind version)"
fi

echo "--------------------------------------------------------"
echo "=== ВСЁ ГОТОВО! ==="
echo "Окружение полностью настроено."
echo "ВАЖНО: Выполните команду 'source ~/.bashrc' в терминале,"
echo "а затем запускайте ваш второй скрипт: ./start-demo.sh"
echo "--------------------------------------------------------"

