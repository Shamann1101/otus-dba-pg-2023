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
