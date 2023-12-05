# Course project

## Task:

Дана БД по пассажирским автобусным перевозкам в Тайланде [link](https://github.com/aeuge/postgres16book/tree/main/database)

Есть исходный запрос, который нужно оптимизировать

```postgresql
SELECT r.id,
       r.startdate                as depart_date,
       bs.city || ', ' || bs.name as busstation,
       count(t.id)                as order_place,
       count(st.id)               as all_place
FROM book.ride r
         JOIN book.schedule as s
              on r.fkschedule = s.id
         JOIN book.busroute br
              on s.fkroute = br.id
         JOIN book.busstation bs
              on br.fkbusstationfrom = bs.id
         JOIN book.tickets t
              on t.fkride = r.id
         JOIN book.seat st
              on r.fkbus = st.fkbus
GROUP BY r.id, r.startdate, bs.city || ', ' || bs.name
ORDER BY r.startdate
limit 10;
```

Для тестирования были развернуты 2 стенда:
* Docker based (Postgres 15.5), thai_small
* VM Ubuntu (Postgres 15.4), thai_medium

Схема БД:

![DB Schema](media/book.png)

## Тестирование на локальном стенде

### Гипотеза: CTE

Вывод планировщика по исходному запросу

```text
Limit  (cost=12210030.61..12210030.64 rows=10 width=56) (actual time=84648.658..84648.723 rows=10 loops=1)
"  Output: r.id, r.startdate, (((bs.city || ', '::text) || bs.name)), (count(t.id)), (count(st.id))"
  ->  Sort  (cost=12210030.61..12213630.61 rows=1440000 width=56) (actual time=84276.018..84276.081 rows=10 loops=1)
"        Output: r.id, r.startdate, (((bs.city || ', '::text) || bs.name)), (count(t.id)), (count(st.id))"
        Sort Key: r.startdate
        Sort Method: top-N heapsort  Memory: 25kB
        ->  Finalize GroupAggregate  (cost=1610179.42..12178912.73 rows=1440000 width=56) (actual time=23197.992..84227.201 rows=144000 loops=1)
"              Output: r.id, r.startdate, (((bs.city || ', '::text) || bs.name)), count(t.id), count(st.id)"
"              Group Key: r.id, (((bs.city || ', '::text) || bs.name))"
              ->  Gather Merge  (cost=1610179.42..12128512.73 rows=2880000 width=56) (actual time=23197.699..84041.894 rows=432000 loops=1)
"                    Output: r.id, (((bs.city || ', '::text) || bs.name)), r.startdate, (PARTIAL count(t.id)), (PARTIAL count(st.id))"
                    Workers Planned: 2
                    Workers Launched: 2
                    ->  Partial GroupAggregate  (cost=1609179.39..11795089.25 rows=1440000 width=56) (actual time=22993.137..74774.224 rows=144000 loops=3)
"                          Output: r.id, (((bs.city || ', '::text) || bs.name)), r.startdate, PARTIAL count(t.id), PARTIAL count(st.id)"
"                          Group Key: r.id, (((bs.city || ', '::text) || bs.name))"
                          Worker 0:  actual time=22891.495..70398.674 rows=144000 loops=1
                            JIT:
                              Functions: 49
"                              Options: Inlining true, Optimization true, Expressions true, Deforming true"
"                              Timing: Generation 2.111 ms, Inlining 60.876 ms, Optimization 183.873 ms, Emission 120.854 ms, Total 367.715 ms"
                          Worker 1:  actual time=22898.968..70083.838 rows=144000 loops=1
                            JIT:
                              Functions: 49
"                              Options: Inlining true, Optimization true, Expressions true, Deforming true"
"                              Timing: Generation 2.065 ms, Inlining 59.918 ms, Optimization 184.899 ms, Emission 120.822 ms, Total 367.705 ms"
                          ->  Incremental Sort  (cost=1609179.39..10909238.90 rows=86425035 width=52) (actual time=22992.763..64775.967 rows=69140067 loops=3)
"                                Output: r.id, (((bs.city || ', '::text) || bs.name)), r.startdate, t.id, st.id"
"                                Sort Key: r.id, (((bs.city || ', '::text) || bs.name))"
                                Presorted Key: r.id
                                Full-sort Groups: 144000  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB
                                Pre-sorted Groups: 144000  Sort Method: quicksort  Average Memory: 90kB  Peak Memory: 90kB
                                Worker 0:  actual time=22891.170..61291.503 rows=63953600 loops=1
                                  Full-sort Groups: 144000  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB
                                  Pre-sorted Groups: 144000  Sort Method: quicksort  Average Memory: 61kB  Peak Memory: 62kB
                                Worker 1:  actual time=22898.571..60975.358 rows=62984920 loops=1
                                  Full-sort Groups: 144000  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB
                                  Pre-sorted Groups: 144000  Sort Method: quicksort  Average Memory: 61kB  Peak Memory: 62kB
                                ->  Merge Join  (cost=1609123.24..3359189.15 rows=86425035 width=52) (actual time=22992.403..47895.726 rows=69140067 loops=3)
"                                      Output: r.id, ((bs.city || ', '::text) || bs.name), r.startdate, t.id, st.id"
                                      Merge Cond: (t.fkride = r.id)
                                      Worker 0:  actual time=22890.891..45676.339 rows=63953600 loops=1
                                      Worker 1:  actual time=22898.200..45520.916 rows=62984920 loops=1
                                      ->  Sort  (cost=381712.72..387114.28 rows=2160626 width=12) (actual time=3905.271..4187.444 rows=1728502 loops=3)
"                                            Output: t.id, t.fkride"
                                            Sort Key: t.fkride
                                            Sort Method: external merge  Disk: 43376kB
                                            Worker 0:  actual time=3802.107..4061.558 rows=1598840 loops=1
                                              Sort Method: external merge  Disk: 34496kB
                                            Worker 1:  actual time=3749.137..4008.021 rows=1574623 loops=1
                                              Sort Method: external merge  Disk: 33976kB
                                            ->  Parallel Seq Scan on book.tickets t  (cost=0.00..80532.26 rows=2160626 width=12) (actual time=283.274..587.265 rows=1728502 loops=3)
"                                                  Output: t.id, t.fkride"
                                                  Worker 0:  actual time=424.470..706.106 rows=1598840 loops=1
                                                  Worker 1:  actual time=425.264..708.999 rows=1574623 loops=1
                                      ->  Materialize  (cost=1227409.44..1256209.44 rows=5760000 width=76) (actual time=19087.067..24376.488 rows=69140055 loops=3)
"                                            Output: r.id, r.startdate, bs.city, bs.name, st.id"
                                            Worker 0:  actual time=19088.736..23985.630 rows=63953593 loops=1
                                            Worker 1:  actual time=19148.976..24010.078 rows=62984910 loops=1
                                            ->  Sort  (cost=1227409.44..1241809.44 rows=5760000 width=76) (actual time=19087.063..19858.291 rows=5760000 loops=3)
"                                                  Output: r.id, r.startdate, bs.city, bs.name, st.id"
                                                  Sort Key: r.id
                                                  Sort Method: external merge  Disk: 230376kB
                                                  Worker 0:  actual time=19088.732..19855.623 rows=5760000 loops=1
                                                    Sort Method: external merge  Disk: 230376kB
                                                  Worker 1:  actual time=19148.972..19916.437 rows=5760000 loops=1
                                                    Sort Method: external merge  Disk: 230376kB
                                                  ->  Hash Join  (cost=53.48..68754.49 rows=5760000 width=76) (actual time=1.293..590.070 rows=5760000 loops=3)
"                                                        Output: r.id, r.startdate, bs.city, bs.name, st.id"
                                                        Hash Cond: (r.fkbus = st.fkbus)
                                                        Worker 0:  actual time=1.278..587.725 rows=5760000 loops=1
                                                        Worker 1:  actual time=2.191..589.641 rows=5760000 loops=1
                                                        ->  Hash Join  (cost=46.98..3587.99 rows=144000 width=76) (actual time=0.934..101.339 rows=144000 loops=3)
"                                                              Output: r.id, r.startdate, r.fkbus, bs.city, bs.name"
                                                              Inner Unique: true
                                                              Hash Cond: (br.fkbusstationfrom = bs.id)
                                                              Worker 0:  actual time=0.985..103.590 rows=144000 loops=1
                                                              Worker 1:  actual time=1.482..103.266 rows=144000 loops=1
                                                              ->  Hash Join  (cost=45.75..3048.56 rows=144000 width=16) (actual time=0.776..76.738 rows=144000 loops=3)
"                                                                    Output: r.id, r.startdate, r.fkbus, br.fkbusstationfrom"
                                                                    Inner Unique: true
                                                                    Hash Cond: (s.fkroute = br.id)
                                                                    Worker 0:  actual time=0.819..79.357 rows=144000 loops=1
                                                                    Worker 1:  actual time=1.192..78.741 rows=144000 loops=1
                                                                    ->  Hash Join  (cost=43.40..2641.51 rows=144000 width=16) (actual time=0.608..52.831 rows=144000 loops=3)
"                                                                          Output: r.id, r.startdate, r.fkbus, s.fkroute"
                                                                          Inner Unique: true
                                                                          Hash Cond: (r.fkschedule = s.id)
                                                                          Worker 0:  actual time=0.632..55.225 rows=144000 loops=1
                                                                          Worker 1:  actual time=0.900..54.984 rows=144000 loops=1
                                                                          ->  Seq Scan on book.ride r  (cost=0.00..2219.00 rows=144000 width=16) (actual time=0.154..14.485 rows=144000 loops=3)
"                                                                                Output: r.id, r.startdate, r.fkbus, r.fkschedule"
                                                                                Worker 0:  actual time=0.175..14.686 rows=144000 loops=1
                                                                                Worker 1:  actual time=0.285..14.837 rows=144000 loops=1
                                                                          ->  Hash  (cost=25.40..25.40 rows=1440 width=8) (actual time=0.443..0.443 rows=1440 loops=3)
"                                                                                Output: s.id, s.fkroute"
                                                                                Buckets: 2048  Batches: 1  Memory Usage: 73kB
                                                                                Worker 0:  actual time=0.445..0.445 rows=1440 loops=1
                                                                                Worker 1:  actual time=0.602..0.603 rows=1440 loops=1
                                                                                ->  Seq Scan on book.schedule s  (cost=0.00..25.40 rows=1440 width=8) (actual time=0.161..0.273 rows=1440 loops=3)
"                                                                                      Output: s.id, s.fkroute"
                                                                                      Worker 0:  actual time=0.162..0.275 rows=1440 loops=1
                                                                                      Worker 1:  actual time=0.317..0.432 rows=1440 loops=1
                                                                    ->  Hash  (cost=1.60..1.60 rows=60 width=8) (actual time=0.160..0.161 rows=60 loops=3)
"                                                                          Output: br.id, br.fkbusstationfrom"
                                                                          Buckets: 1024  Batches: 1  Memory Usage: 11kB
                                                                          Worker 0:  actual time=0.179..0.179 rows=60 loops=1
                                                                          Worker 1:  actual time=0.283..0.284 rows=60 loops=1
                                                                          ->  Seq Scan on book.busroute br  (cost=0.00..1.60 rows=60 width=8) (actual time=0.146..0.151 rows=60 loops=3)
"                                                                                Output: br.id, br.fkbusstationfrom"
                                                                                Worker 0:  actual time=0.164..0.169 rows=60 loops=1
                                                                                Worker 1:  actual time=0.269..0.273 rows=60 loops=1
                                                              ->  Hash  (cost=1.10..1.10 rows=10 width=68) (actual time=0.149..0.150 rows=10 loops=3)
"                                                                    Output: bs.city, bs.name, bs.id"
                                                                    Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                                                    Worker 0:  actual time=0.157..0.157 rows=10 loops=1
                                                                    Worker 1:  actual time=0.281..0.281 rows=10 loops=1
                                                                    ->  Seq Scan on book.busstation bs  (cost=0.00..1.10 rows=10 width=68) (actual time=0.144..0.145 rows=10 loops=3)
"                                                                          Output: bs.city, bs.name, bs.id"
                                                                          Worker 0:  actual time=0.150..0.152 rows=10 loops=1
                                                                          Worker 1:  actual time=0.275..0.276 rows=10 loops=1
                                                        ->  Hash  (cost=4.00..4.00 rows=200 width=8) (actual time=0.327..0.327 rows=200 loops=3)
"                                                              Output: st.id, st.fkbus"
                                                              Buckets: 1024  Batches: 1  Memory Usage: 16kB
                                                              Worker 0:  actual time=0.250..0.250 rows=200 loops=1
                                                              Worker 1:  actual time=0.663..0.664 rows=200 loops=1
                                                              ->  Seq Scan on book.seat st  (cost=0.00..4.00 rows=200 width=8) (actual time=0.284..0.299 rows=200 loops=3)
"                                                                    Output: st.id, st.fkbus"
                                                                    Worker 0:  actual time=0.208..0.223 rows=200 loops=1
                                                                    Worker 1:  actual time=0.620..0.636 rows=200 loops=1
Planning Time: 1.440 ms
JIT:
  Functions: 151
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 8.280 ms, Inlining 135.412 ms, Optimization 590.232 ms, Emission 378.346 ms, Total 1112.271 ms"
Execution Time: 84683.808 ms
```

Можно заметить, что в исходном запросе неверно считается кол-во мест в автобусе и проданных билетов.

Для оптимизации запроса было принято решение вынести редко изменяемые данные в материализованные представления.

```postgresql
create materialized view if not exists book.busstation_material as
(
select bs.id, bs.city || ', ' || bs.name as busstation
from book.busstation bs);
create unique index on book.busstation_material (id);
```

```postgresql
create materialized view if not exists book.bus_capacity as
(
select b.id, count(s.id) as capacity
from book.bus b
         join book.seat s on b.id = s.fkbus
group by b.id);
create unique index on book.bus_capacity (id);
```

![Materialized views](media/docker/cte/materialized_views.png)

Сам запрос было решено оптимизировать при помощи CTE.

```postgresql
with busstation as
         (select sch.id, bs.busstation
          from book.schedule sch
                   JOIN book.busroute br
                        on br.id = sch.fkroute
                   JOIN book.busstation_material bs
                        on bs.id = br.fkbusstationfrom),
     total_seats as
         (select r.id, bc.capacity total_seats
          from book.ride r
                   join book.bus_capacity bc on bc.id = r.fkbus),
     bought_seats as
         (select r.id, r.startdate, count(t.id) as bought_seats
          from book.ride r
                   left join book.tickets t on r.id = t.fkride
          group by r.id, r.startdate)
select r.id, r.startdate, bst.busstation, ts.total_seats, bs.bought_seats
from book.ride r
         left join busstation bst on r.fkschedule = bst.id
         left join total_seats ts on r.id = ts.id
         left join bought_seats bs on r.id = bs.id
order by r.startdate, r.id;
```

![CTE request](media/docker/cte/request.png)

Также для оптимизации работы с памятью был увеличен параметр _work_mem_.
```postgresql
set work_mem to '64MB';
```

Вывод планировщика по оптимизированному запросу.

![CTE request](media/docker/cte/request_explain.png)

```text
Sort  (cost=182688.75..183048.75 rows=144000 width=42) (actual time=4350.298..4367.626 rows=144000 loops=1)
"  Output: r.id, r.startdate, bs.busstation, bc.capacity, (count(t.id))"
"  Sort Key: r.startdate, r.id"
  Sort Method: quicksort  Memory: 18182kB
  ->  Hash Left Join  (cost=163133.03..170351.04 rows=144000 width=42) (actual time=4044.005..4255.397 rows=144000 loops=1)
"        Output: r.id, r.startdate, bs.busstation, bc.capacity, (count(t.id))"
        Hash Cond: (r.id = r_1.id)
        ->  Hash Left Join  (cost=158414.52..163652.53 rows=144000 width=34) (actual time=3967.238..4110.327 rows=144000 loops=1)
"              Output: r.id, r.startdate, bs.busstation, (count(t.id))"
              Hash Cond: (r.fkschedule = sch.id)
              ->  Hash Right Join  (cost=158358.12..161616.13 rows=144000 width=20) (actual time=3965.498..4068.420 rows=144000 loops=1)
"                    Output: r.id, r.startdate, r.fkschedule, (count(t.id))"
                    Inner Unique: true
                    Hash Cond: (r_2.id = r.id)
                    ->  HashAggregate  (cost=154339.12..155779.12 rows=144000 width=16) (actual time=3885.154..3921.885 rows=144000 loops=1)
"                          Output: r_2.id, r_2.startdate, count(t.id)"
                          Group Key: r_2.id
                          Batches: 1  Memory Usage: 18449kB
                          ->  Hash Right Join  (cost=4019.00..128411.82 rows=5185459 width=16) (actual time=47.168..2502.966 rows=5185505 loops=1)
"                                Output: r_2.id, r_2.startdate, t.id"
                                Inner Unique: true
                                Hash Cond: (t.fkride = r_2.id)
                                ->  Seq Scan on book.tickets t  (cost=0.00..110780.59 rows=5185459 width=12) (actual time=0.027..596.796 rows=5185505 loops=1)
"                                      Output: t.id, t.fkride, t.fio, t.contact, t.fkseat"
                                ->  Hash  (cost=2219.00..2219.00 rows=144000 width=8) (actual time=46.261..46.262 rows=144000 loops=1)
"                                      Output: r_2.id, r_2.startdate"
                                      Buckets: 262144  Batches: 1  Memory Usage: 7673kB
                                      ->  Seq Scan on book.ride r_2  (cost=0.00..2219.00 rows=144000 width=8) (actual time=0.030..16.314 rows=144000 loops=1)
"                                            Output: r_2.id, r_2.startdate"
                    ->  Hash  (cost=2219.00..2219.00 rows=144000 width=12) (actual time=80.218..80.219 rows=144000 loops=1)
"                          Output: r.id, r.startdate, r.fkschedule"
                          Buckets: 262144  Batches: 1  Memory Usage: 8236kB
                          ->  Seq Scan on book.ride r  (cost=0.00..2219.00 rows=144000 width=12) (actual time=28.298..45.919 rows=144000 loops=1)
"                                Output: r.id, r.startdate, r.fkschedule"
              ->  Hash  (cost=38.40..38.40 rows=1440 width=22) (actual time=1.704..1.707 rows=1440 loops=1)
"                    Output: sch.id, bs.busstation"
                    Buckets: 2048  Batches: 1  Memory Usage: 93kB
                    ->  Hash Join  (cost=3.58..38.40 rows=1440 width=22) (actual time=0.077..1.249 rows=1440 loops=1)
"                          Output: sch.id, bs.busstation"
                          Inner Unique: true
                          Hash Cond: (br.fkbusstationfrom = bs.id)
                          ->  Hash Join  (cost=2.35..31.80 rows=1440 width=8) (actual time=0.040..0.808 rows=1440 loops=1)
"                                Output: sch.id, br.fkbusstationfrom"
                                Inner Unique: true
                                Hash Cond: (sch.fkroute = br.id)
                                ->  Seq Scan on book.schedule sch  (cost=0.00..25.40 rows=1440 width=8) (actual time=0.003..0.171 rows=1440 loops=1)
"                                      Output: sch.id, sch.fkroute, sch.starttime, sch.price, sch.validfrom, sch.validto"
                                ->  Hash  (cost=1.60..1.60 rows=60 width=8) (actual time=0.027..0.027 rows=60 loops=1)
"                                      Output: br.id, br.fkbusstationfrom"
                                      Buckets: 1024  Batches: 1  Memory Usage: 11kB
                                      ->  Seq Scan on book.busroute br  (cost=0.00..1.60 rows=60 width=8) (actual time=0.007..0.013 rows=60 loops=1)
"                                            Output: br.id, br.fkbusstationfrom"
                          ->  Hash  (cost=1.10..1.10 rows=10 width=22) (actual time=0.029..0.029 rows=10 loops=1)
"                                Output: bs.busstation, bs.id"
                                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                ->  Seq Scan on book.busstation_material bs  (cost=0.00..1.10 rows=10 width=22) (actual time=0.013..0.015 rows=10 loops=1)
"                                      Output: bs.busstation, bs.id"
        ->  Hash  (cost=2918.51..2918.51 rows=144000 width=12) (actual time=76.488..76.490 rows=144000 loops=1)
"              Output: r_1.id, bc.capacity"
              Buckets: 262144  Batches: 1  Memory Usage: 8798kB
              ->  Hash Join  (cost=1.11..2918.51 rows=144000 width=12) (actual time=0.071..45.493 rows=144000 loops=1)
"                    Output: r_1.id, bc.capacity"
                    Inner Unique: true
                    Hash Cond: (r_1.fkbus = bc.id)
                    ->  Seq Scan on book.ride r_1  (cost=0.00..2219.00 rows=144000 width=8) (actual time=0.011..11.485 rows=144000 loops=1)
"                          Output: r_1.id, r_1.startdate, r_1.fkbus, r_1.fkschedule"
                    ->  Hash  (cost=1.05..1.05 rows=5 width=12) (actual time=0.036..0.037 rows=5 loops=1)
"                          Output: bc.capacity, bc.id"
                          Buckets: 1024  Batches: 1  Memory Usage: 9kB
                          ->  Seq Scan on book.bus_capacity bc  (cost=0.00..1.05 rows=5 width=12) (actual time=0.020..0.022 rows=5 loops=1)
"                                Output: bc.capacity, bc.id"
Planning Time: 0.645 ms
JIT:
  Functions: 66
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 1.888 ms, Inlining 0.000 ms, Optimization 0.958 ms, Emission 27.539 ms, Total 30.385 ms"
Execution Time: 4378.474 ms
```

По сравнению с исходным запросом получаем прирост в скорости в 19.34 раз.

### Гипотеза: columnar storage

Для тестирования на локальном стенде было принято решение использовать готовый образ
[citus](https://hub.docker.com/r/citusdata/citus).

Развернув образ, добавляем необходимое нам расширение.

```postgresql
CREATE EXTENSION IF NOT EXISTS citus;
\dx
```

![Citus extensions](media/docker/citus/extensions.png)

| Name           | Version | Schema     | Description                  |
|----------------|---------|------------|------------------------------|
| citus          | 12.1-1  | pg_catalog | Citus distributed database   |
| citus_columnar | 11.3-1  | pg_catalog | Citus Columnar extension     |
| plpgsql        | 1.0     | pg_catalog | PL/pgSQL procedural language |

Для сравнения с предыдущей гипотезой был установлен идентичный параметр _work_mem_.
```postgresql
set work_mem to '64MB';
```

По аналогии с гипотезой CTE выделяем редко используемые данные в материализованные представления.

```postgresql
create materialized view if not exists book.busstation_material as
(
select bs.id, bs.city || ', ' || bs.name as busstation
from book.busstation bs);
create unique index on book.busstation_material (id);
```

```postgresql
create materialized view if not exists book.bus_capacity as
(
select b.id, count(s.id) as capacity
from book.bus b
         join book.seat s on b.id = s.fkbus
group by b.id);
create unique index on book.bus_capacity (id);
```

![Materialized views](media/docker/citus/materialized_views.png)

Известно, что таблицы с колоночным типом хранения более эффективны на больших наборах данных, поэтому выделяем самые
объемные таблицы и создаем на их основе колоночные.

```postgresql
create table book.tickets_row (like book.tickets) using columnar;
create table book.ride_row (like book.ride) using columnar;
```

![Relations](media/docker/citus/relations.png)

Исследовав запросы в предыдущей гипотезе, выделяем запрос на подсчет купленных билетов во временную таблицу с колоночным
хранением на основе созданных выше таблиц.

```postgresql
create temporary table bought_seats using columnar as
select r.id, r.startdate, count(t.id) as bought_seats
from book.ride_row r
         left join book.tickets_row t on r.id = t.fkride
group by r.id, r.startdate;
```

![Temporary table](media/docker/citus/temporary_table.png)

Получается достаточно тяжелый запрос, но эта временная таблица может пригодиться для других запросов, выходящих за рамки
данного курсового проекта.

```text
HashAggregate  (cost=115888.65..117328.65 rows=144000 width=16) (actual time=5698.359..5738.275 rows=144000 loops=1)
"  Output: r.id, r.startdate, count(t.id)"
"  Group Key: r.id, r.startdate"
  Batches: 1  Memory Usage: 18449kB
  ->  Hash Right Join  (cost=1832.99..76997.37 rows=5185505 width=16) (actual time=91.895..3881.759 rows=5185505 loops=1)
"        Output: r.id, r.startdate, t.id"
        Hash Cond: (t.fkride = r.id)
        ->  Custom Scan (ColumnarScan) on book.tickets_row t  (cost=0.00..3863.69 rows=5185505 width=12) (actual time=1.235..1286.039 rows=5185505 loops=1)
"              Output: t.id, t.fkride"
"              Columnar Projected Columns: id, fkride"
        ->  Hash  (cost=32.99..32.99 rows=144000 width=8) (actual time=88.928..88.929 rows=144000 loops=1)
"              Output: r.id, r.startdate"
              Buckets: 262144  Batches: 1  Memory Usage: 7673kB
              ->  Custom Scan (ColumnarScan) on book.ride_row r  (cost=0.00..32.99 rows=144000 width=8) (actual time=11.431..43.515 rows=144000 loops=1)
"                    Output: r.id, r.startdate"
"                    Columnar Projected Columns: id, startdate"
Planning Time: 3.389 ms
JIT:
  Functions: 13
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 0.847 ms, Inlining 0.000 ms, Optimization 0.569 ms, Emission 8.771 ms, Total 10.188 ms"
Execution Time: 5856.030 ms
```

Результирующий запрос похож на запрос из предыдущей гипотезы, но он выполняется ощутимо быстрее.

```postgresql
with busstation as
         (select sch.id, bs.busstation
          from book.schedule sch
                   join book.busroute br
                        on br.id = sch.fkroute
                   join book.busstation_material bs
                        on bs.id = br.fkbusstationfrom)
select r.id, r.startdate, bst.busstation, bc.capacity total_seats, bs.bought_seats
from book.ride r
         left join busstation bst on r.fkschedule = bst.id
         left join bought_seats bs on r.id = bs.id
         left join book.bus_capacity bc on bc.id = r.fkbus
order by r.startdate, r.id;
```

![Columnar request](media/docker/citus/request.png)

Вывод планировщика по оптимизированному запросу.

![Columnar request](media/docker/citus/request_explain.png)

```text
Sort  (cost=19526.47..19886.47 rows=144000 width=42) (actual time=335.936..355.387 rows=144000 loops=1)
"  Output: r.id, r.startdate, bs_1.busstation, bc.capacity, bs.bought_seats"
"  Sort Key: r.startdate, r.id"
  Sort Method: quicksort  Memory: 18182kB
  ->  Hash Left Join  (cost=4076.52..7188.76 rows=144000 width=42) (actual time=60.144..243.064 rows=144000 loops=1)
"        Output: r.id, r.startdate, bs_1.busstation, bc.capacity, bs.bought_seats"
        Inner Unique: true
        Hash Cond: (r.fkbus = bc.id)
        ->  Hash Left Join  (cost=4075.40..6489.25 rows=144000 width=38) (actual time=60.130..207.125 rows=144000 loops=1)
"              Output: r.id, r.startdate, r.fkbus, bs_1.busstation, bs.bought_seats"
              Hash Cond: (r.fkschedule = sch.id)
              ->  Hash Right Join  (cost=4019.00..4452.84 rows=144000 width=24) (actual time=58.788..159.518 rows=144000 loops=1)
"                    Output: r.id, r.startdate, r.fkschedule, r.fkbus, bs.bought_seats"
                    Inner Unique: true
                    Hash Cond: (bs.id = r.id)
                    ->  Custom Scan (ColumnarScan) on pg_temp.bought_seats bs  (cost=0.00..55.83 rows=144000 width=12) (actual time=0.629..32.702 rows=144000 loops=1)
"                          Output: bs.bought_seats, bs.id"
"                          Columnar Projected Columns: id, bought_seats"
                    ->  Hash  (cost=2219.00..2219.00 rows=144000 width=16) (actual time=58.064..58.066 rows=144000 loops=1)
"                          Output: r.id, r.startdate, r.fkschedule, r.fkbus"
                          Buckets: 262144  Batches: 1  Memory Usage: 8798kB
                          ->  Seq Scan on book.ride r  (cost=0.00..2219.00 rows=144000 width=16) (actual time=0.007..23.790 rows=144000 loops=1)
"                                Output: r.id, r.startdate, r.fkschedule, r.fkbus"
              ->  Hash  (cost=38.40..38.40 rows=1440 width=22) (actual time=1.334..1.338 rows=1440 loops=1)
"                    Output: sch.id, bs_1.busstation"
                    Buckets: 2048  Batches: 1  Memory Usage: 93kB
                    ->  Hash Join  (cost=3.58..38.40 rows=1440 width=22) (actual time=0.038..1.045 rows=1440 loops=1)
"                          Output: sch.id, bs_1.busstation"
                          Inner Unique: true
                          Hash Cond: (br.fkbusstationfrom = bs_1.id)
                          ->  Hash Join  (cost=2.35..31.80 rows=1440 width=8) (actual time=0.025..0.696 rows=1440 loops=1)
"                                Output: sch.id, br.fkbusstationfrom"
                                Inner Unique: true
                                Hash Cond: (sch.fkroute = br.id)
                                ->  Seq Scan on book.schedule sch  (cost=0.00..25.40 rows=1440 width=8) (actual time=0.003..0.197 rows=1440 loops=1)
"                                      Output: sch.id, sch.fkroute, sch.starttime, sch.price, sch.validfrom, sch.validto"
                                ->  Hash  (cost=1.60..1.60 rows=60 width=8) (actual time=0.018..0.019 rows=60 loops=1)
"                                      Output: br.id, br.fkbusstationfrom"
                                      Buckets: 1024  Batches: 1  Memory Usage: 11kB
                                      ->  Seq Scan on book.busroute br  (cost=0.00..1.60 rows=60 width=8) (actual time=0.004..0.010 rows=60 loops=1)
"                                            Output: br.id, br.fkbusstationfrom"
                          ->  Hash  (cost=1.10..1.10 rows=10 width=22) (actual time=0.011..0.011 rows=10 loops=1)
"                                Output: bs_1.busstation, bs_1.id"
                                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                ->  Seq Scan on book.busstation_material bs_1  (cost=0.00..1.10 rows=10 width=22) (actual time=0.006..0.008 rows=10 loops=1)
"                                      Output: bs_1.busstation, bs_1.id"
        ->  Hash  (cost=1.05..1.05 rows=5 width=12) (actual time=0.009..0.009 rows=5 loops=1)
"              Output: bc.capacity, bc.id"
              Buckets: 1024  Batches: 1  Memory Usage: 9kB
              ->  Seq Scan on book.bus_capacity bc  (cost=0.00..1.05 rows=5 width=12) (actual time=0.006..0.007 rows=5 loops=1)
"                    Output: bc.capacity, bc.id"
Planning Time: 0.711 ms
Execution Time: 362.676 ms
```

По сравнению с исходным запросом получаем прирост в скорости в 13.62 раза, учитывая создания временной таблицы.
Если брать "чистое" время выполнения запроса, то прирост в 233.5 раз.
