# Homework 9

## Task:

1. Настройте выполнение контрольной точки раз в 30 секунд.
    ```shell
    echo "checkpoint_timeout = 30s" >> /etc/postgresql/15/main/postgresql.conf
    ```

2. 10 минут c помощью утилиты pgbench подавайте нагрузку.
    ```shell
    sudo -u postgres pgbench -c 8 -P 6 -T 600 -U postgres postgres
    ```

3. Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на
одну контрольную точку.
   ```postgresql
   SELECT pg_current_wal_insert_lsn();
   ```
   | pg_current_wal_insert_lsn |
   |---------------------------|
   | 3/3F8A63D0                |

   ```postgresql
   select pg_walfile_name('3/3F8A63D0');
   ```
   | pg_walfile_name          |      
   |--------------------------|
   | 00000001000000030000003F |

   ```postgresql
   SELECT pg_current_wal_insert_lsn();
   ```
   | pg_current_wal_insert_lsn |
   |---------------------------|
   | 3/C888F878                |

   ```postgresql
   select pg_walfile_name('3/C888F878');
   ```
   | pg_walfile_name          |      
   |--------------------------|
   | 0000000100000003000000C8 |
   
   ```postgresql
   select pg_size_pretty('3/C888F878'::pg_lsn - '3/3F8A63D0'::pg_lsn);
   ```
   | pg_size_pretty |
   |----------------|
   | 2192 MB        |
   
   ```postgresql
   select pg_size_pretty(('3/C888F878'::pg_lsn - '3/3F8A63D0'::pg_lsn) / 20);
   ```
   | pg_size_pretty |
   |----------------|
   | 110 MB         |

4. Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?
   > Все чекпоинты прошли по расписанию.
   > Мы не вышли за размер _max_wal_size_, поэтому не потребовалось вызывать чекпоинт дополнительно
   ```postgresql
   SELECT * FROM pg_stat_bgwriter \gx
   ```
   | param                 | value                         |
   |-----------------------|-------------------------------|
   | checkpoints_timed     | 22                            |
   | checkpoints_req       | 0                             |
   | checkpoint_write_time | 304468                        |
   | checkpoint_sync_time  | 12960                         |
   | buffers_checkpoint    | 148347                        |
   | buffers_clean         | 105463                        |
   | maxwritten_clean      | 756                           |
   | buffers_backend       | 28993                         |
   | buffers_backend_fsync | 0                             |
   | buffers_alloc         | 469257                        |
   | stats_reset           | 2023-11-19 12:45:16.718056+00 |

5. Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.
   ```postgresql
   ALTER SYSTEM SET synchronous_commit = on;
   ```
   ```shell
   sudo -u postgres pgbench -P 1 -T 10 -U postgres postgres
   ```
   > tps = 222.105331 (without initial connection time)

   ```postgresql
   ALTER SYSTEM SET synchronous_commit = off;
   select pg_reload_conf();
   ```
   ```shell
   sudo pg_ctlcluster 15 main reload
   sudo -u postgres pgbench -P 1 -T 10 -U postgres postgres
   ```
   > tps = 1437.305500 (without initial connection time)

6. Создайте новый кластер с включенной контрольной суммой страниц. Создайте таблицу. Вставьте несколько значений.
Выключите кластер. Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы. Что и почему произошло?
как проигнорировать ошибку и продолжить работу?
   ```shell
   sudo -u postgres /usr/lib/postgresql/15/bin/pg_checksums --enable -D "/mnt/vdb1/postgresql/15/main"
   ```
   ```postgresql
   show data_checksums;
   ```
   | data_checksums |
   |----------------|
   | on             |

   ```shell
   dd if=/dev/zero of=/mnt/vdb1/postgresql/15/main/base/16388/17133 oflag=dsync conv=notrunc bs=1 count=8

      ```
   ```postgresql
   select * from persons;
   ```
   > WARNING:  page verification failed, calculated checksum 23414 but expected 39200
   > 
   > ERROR:  invalid page in block 0 of relation base/16388/17133

   ```postgresql
   SET ignore_checksum_failure = on;
   ```
   > WARNING:  page verification failed, calculated checksum 23414 but expected 39200

   | id | first_name | second_name |
   |----|------------|-------------|
   | 1  | ivan       | ivanov      |
   | 2  | petr       | petrov      |
   | 3  | anton      | antonov     |
