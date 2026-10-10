#!/usr/bin/env bash
# Готовит SSH-ключ ed25519 для подключения к серверу Hermes.
# Запускать НА СВОЁМ КОМПЬЮТЕРЕ (macOS / Linux), там где стоит Hermes Desktop.
#
#   bash setup-ssh-key.sh
#
# Что делает:
#   1. создаёт ~/.ssh/id_ed25519, если его ещё нет (существующий НЕ перезаписывает);
#   2. выставляет правильные права, чтобы ключом могли пользоваться и ssh, и Hermes Desktop;
#   3. добавляет ключ в ssh-agent;
#   4. печатает публичную часть (~/.ssh/id_ed25519.pub).
# Приватный ключ скрипт нигде не печатает и никуда не отправляет.

set -euo pipefail

KEY="$HOME/.ssh/id_ed25519"
PUB="$KEY.pub"
COMMENT="${1:-hermes-$(whoami)@$(hostname -s 2>/dev/null || hostname)}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY" ]; then
  echo "==> Ключ уже есть, беру существующий: $KEY"
else
  echo "==> Создаю новый ключ ed25519: $KEY"
  # Без парольной фразы: иначе Hermes Desktop не сможет открыть ключ сам,
  # без подсказки пароля. Если парольная фраза нужна — убери -N "" и
  # введи её вручную, ключ всё равно будет добавлен в ssh-agent ниже.
  ssh-keygen -t ed25519 -a 100 -C "$COMMENT" -f "$KEY" -N ""
fi

chmod 600 "$KEY"
[ -f "$PUB" ] && chmod 644 "$PUB"

# ssh-agent: чтобы ключ был доступен без повторного ввода пароля
if ! ssh-add -l >/dev/null 2>&1; then
  echo "==> Запускаю ssh-agent"
  eval "$(ssh-agent -s)" >/dev/null
fi

echo "==> Добавляю ключ в ssh-agent"
if [ "$(uname -s)" = "Darwin" ]; then
  # на macOS --apple-use-keychain сохраняет парольную фразу в Keychain
  ssh-add --apple-use-keychain "$KEY" 2>/dev/null || ssh-add "$KEY"
else
  ssh-add "$KEY"
fi

ssh-add -l || true

echo
echo "================ ПУБЛИЧНЫЙ КЛЮЧ ($PUB) ================"
cat "$PUB"
echo "======================================================="
echo
echo "Приватный ключ лежит в $KEY и остаётся только на этом компьютере."
echo
echo "Дальше, когда появится сервер (IP из .env):"
echo "  ssh-copy-id -i $PUB root@SERVER_IP"
echo "  # либо вручную: добавь строку выше в /root/.ssh/authorized_keys на сервере"
echo "  ssh -i $KEY root@SERVER_IP   # проверка входа без пароля"
