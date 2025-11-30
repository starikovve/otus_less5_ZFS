# otus_less5_ZFS

Administrator Linux. Professional

1. Определить алгоритм с наилучшим сжатием:

Смотрим список всех дисков, которые есть в виртуальной машине: lsblk

<img width="776" height="585" alt="image" src="https://github.com/user-attachments/assets/91f1ab79-fadc-42c3-8c78-a329ffc4dcb2" />


Установим пакет утилит для ZFS:

<img width="605" height="141" alt="image" src="https://github.com/user-attachments/assets/86c0a4e2-9c62-45d5-b68a-5ec7337fb87a" />

Создаём пул из двух дисков в режиме RAID 1:

root@ubuntu:/home/starikov# zpool create otus1 mirror /dev/sdj /dev/sdk

Создадим ещё 3 пула: 

zpool create otus2 mirror /dev/sda /dev/sdb
zpool create otus3 mirror /dev/sdl /dev/sdm
zpool create otus4 mirror /dev/sde /dev/sdn

Смотрим информацию о пулах: zpool list

<img width="871" height="142" alt="image" src="https://github.com/user-attachments/assets/958ccd7e-5a09-441f-9a9c-8e60d60b7e95" />

Установим разные алгоритмы сжатия

zfs set compression=lzjb otus1
zfs set compression=lz4  otus2
zfs set compression=gzip-9 otus3
zfs set compression=zle  otus4

Проверим, что все файловые системы имеют разные методы сжатия:

zfs get all | grep compression

<img width="671" height="120" alt="image" src="https://github.com/user-attachments/assets/5c64606c-75de-42fa-a387-4b5c49fba87d" />

Скачиваем тестовый текстовый файл в каждую ФС

for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done

Проверим, что файл был скачан во все пулы:

ls -l /otus*

<img width="720" height="341" alt="image" src="https://github.com/user-attachments/assets/d386b8f8-5b07-4e4a-9a04-de9c5c96829f" />

Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:

zfs list

<img width="463" height="137" alt="image" src="https://github.com/user-attachments/assets/1006628e-7547-46cd-ac5e-52150586171c" />

zfs get all | grep compressratio | grep -v ref

<img width="951" height="122" alt="image" src="https://github.com/user-attachments/assets/82c5ee86-50ab-49a0-8fa7-30a82d535069" />

Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию. 

2. Определение настроек пула:

Скачиваем архив в домашний каталог: 

<img width="856" height="59" alt="image" src="https://github.com/user-attachments/assets/53010781-6a28-4bea-af9c-60ee8fc0ca23" />

Разархивируем его:

tar -xzvf archive.tar.gz

<img width="418" height="71" alt="image" src="https://github.com/user-attachments/assets/8ca121b5-e31e-480f-8425-153cd3680e3a" />

Сделаем импорт данного пула к нам в ОС:

zpool import -d zpoolexport/ otus
zpool status

<img width="893" height="361" alt="image" src="https://github.com/user-attachments/assets/68c32243-ebdb-48f7-99ab-dc0f11c98cef" />

Команда zpool status выдаст нам информацию о составе импортированного пула.

Получение свойств пула/файловой системы
zpool get all otus
zfs get all otus

<img width="800" height="713" alt="image" src="https://github.com/user-attachments/assets/621bc9a6-80fd-4b2b-bc52-b1668da79549" />

<img width="645" height="683" alt="image" src="https://github.com/user-attachments/assets/013c028b-176f-4f78-9d4b-03c32435517e" />

Примеры нужных параметров:

zfs get available otus
zfs get recordsize otus
zfs get compression otus
zfs get checksum otus

<img width="686" height="247" alt="image" src="https://github.com/user-attachments/assets/80e93fda-5b7e-424b-9b7a-a6624b98af04" />


3. Работа со снапшотом, поиск сообщения от преподавателя:

Скачаем файл, указанный в задании:

wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download

Восстановим файловую систему из снапшота:

zfs receive otus/test@today < otus_task2.file

Поиск secret_message:

find /otus/test -name "secret_message"


<img width="699" height="72" alt="image" src="https://github.com/user-attachments/assets/59002031-af3e-4bf4-9808-5f741b255a90" />

Смотрим содержимое найденного файла:
cat /otus/test/task1/file_mess/secret_message

<img width="776" height="92" alt="image" src="https://github.com/user-attachments/assets/b36f4382-3906-48b9-99df-95c19f9a3e07" />











