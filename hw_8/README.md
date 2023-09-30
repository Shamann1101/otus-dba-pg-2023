# Homework 8

## Task:

Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB

Установить на него PostgreSQL 15 с дефолтными настройками

Создать БД для тестов: выполнить pgbench -i postgres
```shell
sudo -u postgres pgbench -i postgres -s 100
```

    dropping old tables...
    creating tables...
    generating data (client-side)...
    10000000 of 10000000 tuples (100%) done (elapsed 204.93 s, remaining 0.00 s)
    vacuuming...
    creating primary keys...
    done in 379.67 s (drop tables 0.02 s, create tables 0.02 s, client-side generate 206.60 s, vacuum 105.57 s, primary keys 67.45 s).

Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres
```shell
sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres postgres
```

    pgbench (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
    starting vacuum...end.
    progress: 6.0 s, 380.3 tps, lat 20.915 ms stddev 20.689, 0 failed
    progress: 12.0 s, 487.8 tps, lat 16.393 ms stddev 9.239, 0 failed
    progress: 18.0 s, 507.3 tps, lat 15.785 ms stddev 9.789, 0 failed
    progress: 24.0 s, 408.8 tps, lat 19.554 ms stddev 12.092, 0 failed
    progress: 30.0 s, 571.8 tps, lat 13.936 ms stddev 10.480, 0 failed
    progress: 36.0 s, 396.5 tps, lat 20.259 ms stddev 19.302, 0 failed
    progress: 42.0 s, 579.0 tps, lat 13.816 ms stddev 7.938, 0 failed
    progress: 48.0 s, 517.8 tps, lat 15.428 ms stddev 10.109, 0 failed
    progress: 54.0 s, 528.3 tps, lat 15.154 ms stddev 11.874, 0 failed
    progress: 60.0 s, 618.2 tps, lat 12.883 ms stddev 8.669, 0 failed
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 1
    query mode: simple
    number of clients: 8
    number of threads: 1
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 29984
    number of failed transactions: 0 (0.000%)
    latency average = 16.008 ms
    latency stddev = 12.415 ms
    initial connection time = 21.923 ms
    tps = 499.509811 (without initial connection time)

Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла

Протестировать заново
```shell
sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres postgres
```

    pgbench (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
    starting vacuum...end.
    progress: 6.0 s, 467.2 tps, lat 17.033 ms stddev 10.152, 0 failed
    progress: 12.0 s, 447.0 tps, lat 17.894 ms stddev 11.629, 0 failed
    progress: 18.0 s, 502.3 tps, lat 15.929 ms stddev 10.257, 0 failed
    progress: 24.0 s, 522.3 tps, lat 15.312 ms stddev 10.912, 0 failed
    progress: 30.0 s, 322.5 tps, lat 24.794 ms stddev 25.393, 0 failed
    progress: 36.0 s, 456.3 tps, lat 17.518 ms stddev 12.375, 0 failed
    progress: 42.0 s, 429.3 tps, lat 18.650 ms stddev 14.653, 0 failed
    progress: 48.0 s, 492.3 tps, lat 16.151 ms stddev 10.427, 0 failed
    progress: 54.0 s, 275.2 tps, lat 29.251 ms stddev 17.487, 0 failed
    progress: 60.0 s, 294.8 tps, lat 26.971 ms stddev 31.413, 0 failed
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 1
    query mode: simple
    number of clients: 8
    number of threads: 1
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 25264
    number of failed transactions: 0 (0.000%)
    latency average = 19.011 ms
    latency stddev = 16.259 ms
    initial connection time = 24.139 ms
    tps = 420.051710 (without initial connection time)

Что изменилось и почему?
    <!---
    FIXME: Add answer
    -->

Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
```postgresql
CREATE TABLE test(i int);
INSERT INTO test(i) SELECT * FROM generate_series(1, 1000000);
```

Посмотреть размер файла с таблицей
```postgresql
SELECT pg_size_pretty(pg_total_relation_size('test'));
```
| pg_size_pretty |
|----------------|
| 35 MB          |


5 раз обновить все строчки и добавить к каждой строчке любой символ
```postgresql
do $$
begin
    for counter in 1..5
        loop
            update test set i = i + 1;
        end loop;
end; $$;
```

Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум
```postgresql
SELECT relname, n_live_tup, n_dead_tup, trunc(100 * n_dead_tup / (n_live_tup + 1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'test';
```
| relname | n_live_tup | n_dead_tup | ratio% | last_autovacuum               |
|---------|------------|------------|--------|-------------------------------|
| test    | 1000000    | 5000000    | 499    | 2023-09-30 11:19:43.539523+00 |

Подождать некоторое время, проверяя, пришел ли автовакуум

| relname | n_live_tup | n_dead_tup | ratio% | last_autovacuum               |
|---------|------------|------------|--------|-------------------------------|
| test    | 1000000    | 0          | 0      | 2023-09-30 11:32:44.968843+00 |

5 раз обновить все строчки и добавить к каждой строчке любой символ

Посмотреть размер файла с таблицей

| pg_size_pretty |
|----------------|
| 173 MB         |

Отключить Автовакуум на конкретной таблице
```postgresql
alter table test set (autovacuum_enabled = off);
```

10 раз обновить все строчки и добавить к каждой строчке любой символ

Посмотреть размер файла с таблицей

| pg_size_pretty |
|----------------|
| 380 MB         |

Объясните полученный результат
> Вакуум отмечает мертвые строки как неиспользованные, но физически место на диске не освобождается

Не забудьте включить автовакуум)
```postgresql
alter table test set (autovacuum_enabled = on);
```

Задание со *:

Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице.

Не забыть вывести номер шага цикла.
```postgresql
do $$
begin
    for counter in 1..10
        loop
            raise notice 'Loop #%', counter;
            update test set i = i + 1;
        end loop;
end; $$;
```
