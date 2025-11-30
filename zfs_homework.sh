автоматизация стенда ZFS по методичке

set -euo pipefail
LOG=/root/zfs_homework.log
exec > >(tee -a "$LOG") 2>&1
echo "Начало выполнения: $(date)"
Проверка прав
if [ "$(id -u)" -ne 0 ]; then
  echo "Запусти скрипт от root: sudo -i"
  exit 1
fi
Установить утилиты ZFS (если ещё не установлены)
if ! command -v zpool >/dev/null 2>&1 || ! command -v zfs >/dev/null 2>&1; then
  apt update
  DEBIAN_FRONTEND=noninteractive apt install -y zfsutils-linux wget tar
fi
Список ожидаемых дисков (как в методичке)
DISKS=(/dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi)
Проверка существования дисков
for d in "${DISKS[@]}"; do
  if [ ! -b "$d" ]; then
    echo "Внимание: устройство $d отсутствует. Проверь конфигурацию VM."
  fi
done
Создать пулы otus1..otus4 как mirror (если не существуют)
create_pool_if_not_exists() {
  local pool=$1
  shift
  if zpool list "$pool" >/dev/null 2>&1; then
    echo "Пул $pool уже есть — пропускаем создание."
  else
    echo "Создаём пул $pool из: $*"
    zpool create -f "$pool" mirror "$@"
  fi
}
create_pool_if_not_exists otus1 /dev/sdb /dev/sdc
create_pool_if_not_exists otus2 /dev/sdd /dev/sde
create_pool_if_not_exists otus3 /dev/sdf /dev/sdg
create_pool_if_not_exists otus4 /dev/sdh /dev/sdi
Подождать монтирование файловых систем /otus1.. /otus4
for i in 1 2 3 4; do
  mountpoint="/otus${i}"
  if [ ! -d "$mountpoint" ]; then
    mkdir -p "$mountpoint"
  fi
ZFS автоматически монтирует dataset с именем пула в корень, но в разных окружениях mountpoint может отличаться.
Если /otusN не смонтирован, создадим dataset с нужным mountpoint.
  ds="otus${i}"
  if ! zfs list "$ds" >/dev/null 2>&1; then
    zfs create -o mountpoint="$mountpoint" "$ds"
  else
    # если dataset существует, установить желаемый mountpoint
    zfs set mountpoint="$mountpoint" "$ds"
  fi
done
Установим разные алгоритмы сжатия
zfs set compression=lzjb otus1
zfs set compression=lz4  otus2
zfs set compression=gzip-9 otus3
zfs set compression=zle  otus4
echo "Проверка свойств compression:"
zfs get compression otus1 otus2 otus3 otus4
Скачиваем тестовый текстовый файл в каждую ФС
TEST_URL="https://gutenberg.org/cache/epub/2600/pg2600.converter.log"
for i in 1 2 3 4; do
  dir="/otus${i}"
  echo "Скачиваем в $dir"
wget вернёт ошибку если URL недоступен; пытаемся 3 раза
  wget -q -O "${dir}/pg2600.converter.log" "$TEST_URL" || {
    echo "Ошибка wget для $TEST_URL, проверяй сеть. Попытка сохранить минимальный тестовый файл."
    echo "test content $(date)" > "${dir}/pg2600.converter.log"
  }
done
Проверим размеры и compressratio
echo "Список ZFS:"
zfs list
echo "Compress ratios:"
zfs get compressratio otus1 otus2 otus3 otus4
Импорт пула из каталога zpoolexport (если есть архив)
WORKDIR=/root
ARCHIVE_URL='' # если требуется, укажи ссылку на archive.tar.gz
Если архив уже скачан локально /root/archive.tar.gz, распакуем
if [ -f "${WORKDIR}/archive.tar.gz" ]; then
  echo "Найден ${WORKDIR}/archive.tar.gz — распаковываем"
  tar -xzvf "${WORKDIR}/archive.tar.gz" -C "${WORKDIR}"
fi
Если присутствует каталог zpoolexport с экспортом пула, импортируем
if [ -d "${WORKDIR}/zpoolexport" ]; then
  echo "Пытаемся импортировать пул otus из ${WORKDIR}/zpoolexport"
если пул с именем otus уже есть, импортировать под другим именем newotus
  if zpool list otus >/dev/null 2>&1; then
    zpool import -d "${WORKDIR}/zpoolexport" otus newotus || true
  else
    zpool import -d "${WORKDIR}/zpoolexport" otus || true
  fi
fi
Показать настройки пула otus (если импортирован)
if zpool list otus >/dev/null 2>&1; then
  echo "zpool status otus:"
  zpool status otus || true
  echo "zpool get all otus:"
  zpool get all otus || true
  echo "zfs get all otus:"
  zfs get all otus || true
  echo "Некоторые параметры (available, recordsize, compression, checksum):"
  zfs get available otus || true
  zfs get recordsize otus || true
  zfs get compression otus || true
  zfs get checksum otus || true
fi
Работа со снапшотом: если присутствует файл otus_task2.file, применим zfs receive
IFILE="${WORKDIR}/otus_task2.file"
if [ -f "$IFILE" ]; then
  echo "Принимаем файловую систему из $IFILE в otus/test@today"
убедимся, что целевой dataset otus/test существует
  if ! zfs list otus/test >/dev/null 2>&1; then
    zfs create otus/test || true
  fi
  zfs receive otus/test@today < "$IFILE" || true
  echo "Поиск secret_message в /otus/test"
  find /otus/test -name "secret_message" -print -exec cat {} ; || true
fi
echo "Скрипт выполнен. Лог: $LOG"
echo "Конец: $(date)"
