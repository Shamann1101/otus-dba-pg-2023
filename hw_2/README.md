# Homework 2

## Task:

создать новый проект в Google Cloud Platform, Яндекс облако или на любых ВМ, докере

далее создать инстанс виртуальной машины с дефолтными параметрами
```shell
ssh-keygen -t rsa -b 2048
echo ubuntu: > $HOME/.ssh/id_rsa_yc_shm.txt && cat $HOME/.ssh/id_rsa_yc_shm.pub >> $HOME/.ssh/id_rsa_yc_shm.txt
yc compute instance create \
--name vm-ubuntu \
--hostname vm-ubuntu \
--zone ru-central1-a \
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
--memory 4G \
--cores 2 \
--zone ru-central1-a \
--create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts,auto-delete=true \
--metadata-from-file ssh-keys=$HOME/.ssh/id_rsa_yc_shm.txt
```

добавить свой ssh ключ в metadata ВМ

зайти удаленным ssh (первая сессия), не забывайте про ssh-add
```shell
yc compute instance list
ssh ubuntu@otus_vm_ubuntu
```

поставить PostgreSQL
```shell
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && \
sudo apt-get update && \
sudo apt-get -y install postgresql-15
sudo su - postgres
psql
```
```postgresql
CREATE DATABASE iso;
```


зайти вторым ssh (вторая сессия)

запустить везде psql из под пользователя postgres
```shell
sudo -u postgres psql iso
```

выключить auto commit
```postgresql
\set AUTOCOMMIT OFF
```
сделать в первой сессии новую таблицу и наполнить ее данными
create table persons(id serial, first_name text, second_name text);
insert into persons(first_name, second_name) values('ivan', 'ivanov');
insert into persons(first_name, second_name) values('petr', 'petrov');
commit;
```postgresql
create table persons(id serial, first_name text, second_name text);
insert into persons(first_name, second_name) values('ivan', 'ivanov'), ('petr', 'petrov');
```

посмотреть текущий уровень изоляции: show transaction isolation level
```postgresql
show transaction isolation level;
```

```
transaction_isolation
-----------------------
read committed
(1 row)
```

начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
```postgresql
begin;
```
в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');
```postgresql
insert into persons(first_name, second_name) values('sergey', 'sergeev');
```

сделать select * from persons во второй сессии
```postgresql
iso=*# select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |

видите ли вы новую запись и если да то почему?
> Нет

завершить первую транзакцию - commit;

сделать select * from persons во второй сессии
```postgresql
iso=*# select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |

видите ли вы новую запись и если да то почему?
> Да. Транзакции с дефолтным уровнем изоляции соответствуют уровню Read Committed.
> 
> Согласно документации, два последовательных оператора SELECT могут видеть разные данные даже в рамках одной
> транзакции, если какие-то другие транзакции зафиксируют изменения после запуска первого SELECT, но до запуска второго.
> 
> В этом случае воспроизводится ситуация неповторяемого чтения.

завершите транзакцию во второй сессии

начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;
```postgresql
begin transaction isolation level repeatable read;
```

в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');
```postgresql
insert into persons(first_name, second_name) values('sveta', 'svetova');
```

сделать select * from persons во второй сессии
```postgresql
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |

видите ли вы новую запись и если да то почему?
> Нет

завершить первую транзакцию - commit;

сделать select * from persons во второй сессии
```postgresql
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |

видите ли вы новую запись и если да то почему?
> Нет

завершить вторую транзакцию

сделать select * from persons во второй сессии
```postgresql
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |
| 4  | sveta      | svetova     |

видите ли вы новую запись и если да то почему? ДЗ сдаем в виде миниотчета в markdown в гите
> Да. Запрос в транзакции данного уровня видит снимок данных на момент начала первого оператора в транзакции,
> а не начала текущего оператора.
> 
> Таким образом, последовательные команды SELECT в одной транзакции видят одни и те же данные;
> они не видят изменений, внесённых и зафиксированных другими транзакциями после начала их текущей транзакции.
>
> В этом случае не воспроизводится ситуация неповторяемого чтения.
