# Homework 3

## Task:

создать ВМ с Ubuntu 20.04/22.04 или развернуть докер любым удобным способом

поставить на нем Docker Engine

сделать каталог /var/lib/postgres
> Согласно Docker Best Practices, монтировать в проект стоит либо анонимные тома,
> либо директории из проекта, поэтому монтируем в проект директорию _./tmp/postgres/data_

развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql
> Для минимизации использования дискового пространства монтируется только директория с данными
> _/var/lib/postgresql/data_

развернуть контейнер с клиентом postgres
> Для удобства взаимодействия с проектом создан [Makefile](Makefile)

подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк
```shell
cp .env.example .env
# Необходимо заполнить файл с переменными окружения
vim .env
make build-up
make seeds
```
> Для посева данных используется скрипт [entrypoint.sql](initdb/entrypoint.sql)

подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера
```shell
source .env && \
psql -U ${POSTGRES_USER} -h localhost -p 5432 -w ${POSTGRES_DB} 
```
```postgresql
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |

удалить контейнер с сервером
```shell
make down
```

создать его заново
```shell
make up
```

подключится снова из контейнера с клиентом к контейнеру с сервером
```shell
make client
```

проверить, что данные остались на месте
```postgresql
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |

оставляйте в ЛК ДЗ комментарии что и как вы делали и как боролись с проблемами
