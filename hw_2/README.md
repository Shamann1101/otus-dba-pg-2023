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

поставить PostgreSQL

зайти вторым ssh (вторая сессия)

запустить везде psql из под пользователя postgres

выключить auto commit

сделать в первой сессии новую таблицу и наполнить ее данными create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;

посмотреть текущий уровень изоляции: show transaction isolation level

начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции

в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');

сделать select * from persons во второй сессии

видите ли вы новую запись и если да то почему?

завершить первую транзакцию - commit;

сделать select * from persons во второй сессии

видите ли вы новую запись и если да то почему?

завершите транзакцию во второй сессии

начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;

в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');

сделать select * from persons во второй сессии

видите ли вы новую запись и если да то почему?

завершить первую транзакцию - commit;

сделать select * from persons во второй сессии

видите ли вы новую запись и если да то почему?

завершить вторую транзакцию

сделать select * from persons во второй сессии

видите ли вы новую запись и если да то почему? ДЗ сдаем в виде миниотчета в markdown в гите
