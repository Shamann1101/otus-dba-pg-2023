# Homework 7

## Task:

1. создайте новый кластер PostgresSQL 14

2. зайдите в созданный кластер под пользователем postgres
    ```shell
    sudo -u postgres psql
    ```

3. создайте новую базу данных testdb
    ```postgresql
    create database testdb;
    ```

4. зайдите в созданную базу данных под пользователем postgres
    ```postgresql
    \c testdb
    ```

5. создайте новую схему testnm
    ```postgresql
    create schema testnm;
    ```

6. создайте новую таблицу t1 с одной колонкой c1 типа integer
    ```postgresql
    create table t1 (c1 int);
    ```

7. вставьте строку со значением c1=1
    ```postgresql
    insert into t1 (c1) values (1);
    ```

8. создайте новую роль readonly
    ```postgresql
    create role readonly;
    ```

9. дайте новой роли право на подключение к базе данных testdb
    ```postgresql
    grant connect on database testdb to readonly;
    ```

10. дайте новой роли право на использование схемы testnm
    ```postgresql
    grant usage on schema testnm to readonly;
    ```

11. дайте новой роли право на select для всех таблиц схемы testnm
    ```postgresql
    grant select on all tables in schema testnm to readonly;
    ```

12. создайте пользователя testread с паролем test123
    ```postgresql
    create user testread with password 'test123';
    ```

13. дайте роль readonly пользователю testread
    ```postgresql
    grant readonly to testread;
    ```

14. зайдите под пользователем testread в базу данных testdb
    ```shell
    psql -h localhost -U testread -W testdb
    ```

15. сделайте select * from t1;
    ```postgresql
    select * from t1;
    ```

16. получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)
    > ERROR:  permission denied for table t1

17. напишите что именно произошло в тексте домашнего задания
    > Попытка чтения данных из таблицы, к которой нет доступа 

18. у вас есть идеи почему? ведь права то дали?
    > Таблица была создана без явного указания схемы, поэтому она была создана на основании search_path, из-за чего
    попала в схему public 

19. посмотрите на список таблиц

    | Schema | Name | Type  | Owner    |
    |--------|------|-------|----------|
    | public | t1   | table | postgres |

20. подсказка в шпаргалке под пунктом 20

21. а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)

22. вернитесь в базу данных testdb под пользователем postgres

23. удалите таблицу t1
    ```postgresql
    drop table t1;
    ```

24. создайте ее заново но уже с явным указанием имени схемы testnm
    ```postgresql
    create table testnm.t1 (c1 int);
    ```

25. вставьте строку со значением c1=1
    ```postgresql
    insert into testnm.t1 (c1) values (1);
    ```

26. зайдите под пользователем testread в базу данных testdb

27. сделайте select * from testnm.t1;

28. получилось?
    > ERROR:  permission denied for table t1

29. есть идеи почему? если нет - смотрите шпаргалку
    > Права на чтение были выданы до момента создания таблицы, поэтому на неё не распространяются

30. как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку
    ```postgresql
    alter default privileges in schema testnm grant select on tables to readonly;
    ```

31. сделайте select * from testnm.t1;

32. получилось?
    > ERROR:  permission denied for table t1

33. есть идеи почему? если нет - смотрите шпаргалку
    > alter default privileges распространяется на новые таблицы, права к существующим не изменяются
    ```postgresql
    grant select on all tables in schema testnm to readonly;
    ```

34. сделайте select * from testnm.t1;

35. получилось?

    | c1 |
    |----|
    | 1  |

36. ура!

37. теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
    ```postgresql
    create table t2(c1 integer);
    insert into t2 values (2);
    ```
    > ERROR:  permission denied for schema public

38. а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
    > В 15 версии для public доступны только права уровня usage

39. есть идеи как убрать эти права? если нет - смотрите шпаргалку

40. если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему
выполнив указанные в ней команды

41. теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);

42. расскажите что получилось и почему
    > Судя по контексту, в 14 версии в 37 пункте должна была создаться таблица, в 39 пункте права должны быть отозваны,
    а в 41 пункте должны получить Permission Denied, но в 15 версии по дефолту права usage, поэтому отзывать права нет
    смысла
