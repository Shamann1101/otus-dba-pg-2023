# Homework 6

## Task:

создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере

поставьте на нее PostgreSQL 15 через sudo apt

проверьте что кластер запущен через sudo -u postgres pg_lsclusters
```shell
sudo -u postgres pg_lsclusters
# Ver Cluster Port Status Owner    Data directory               Log file
# 15  main    5432 online postgres /var/lib/postgresql/15/main  /var/log/postgresql/postgresql-15-main.log
```

зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым
```shell
sudo -u postgres psql
```
```postgresql
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |
| 4  | sveta      | svetova     |

остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop
```shell
sudo -u postgres pg_ctlcluster 15 main stop
```
> 15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

создайте новый диск к ВМ размером 10GB
```shell
yc compute disk create \
--name spare-disk \
--zone ru-central1-a \
--type network-ssd \
--size 10 \
--description "Spare disk for vm-otus"
```

добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach
existing disk
```shell
yc compute instance attach-disk vm-ubuntu \
--disk-name spare-disk \
--mode rw
```

проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на
актуальное, в вашем случае это скорее всего будет /dev/sdb -
https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
```shell
ls -la /dev/disk/by-id/
sudo fdisk /dev/vdb
sudo mkfs.ext4 /dev/vdb1
sudo mkdir /mnt/vdb1
sudo mount /dev/vdb1/ /mnt/vdb1/
sudo chmod a+w /mnt/vdb1/
sudo blkid /dev/vdb1
```
> /dev/vdb1: UUID="39f228dd-7780-487a-9099-19d2f3fdf6ec" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="c2313d3f-01"
```shell
echo "/dev/disk/by-uuid/39f228dd-7780-487a-9099-19d2f3fdf6ec /mnt/vdb1 ext4 defaults 0 2" >> /etc/fstab
```

перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)
```shell
yc compute instance restart vm-ubuntu
```

сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/
```shell
sudo chown -R postgres:postgres /mnt/vdb1/
```

перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15 /mnt/data
```shell
sudo -u postgres pg_ctlcluster 15 main stop
mv /var/lib/postgres/15 /mnt/vdb1/postgresql/
```

попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
```shell
sudo -u postgres pg_ctlcluster 15 main start
```

напишите получилось или нет и почему
> Error: /var/lib/postgresql/15/main is not accessible or does not exist

задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и
поменяйте его
```shell
grep /var/lib/postgresql/15/main -iRI /etc/postgresql/15/main/
```

напишите что и почему поменяли
```shell
vim /etc/postgresql/15/main/postgresql.conf
# Указываем целевую директорию
# data_directory = '/mnt/vdb1/postgresql/15/main'
```
> Конфиг data_directory отвечает за физическое расположение данных на диске.
> Переместив данные на примонтированный диск, postgres не знает об этом перемещении, поэтому необходимо указать новое 
> расположение файлов 

попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
```shell
sudo -u postgres pg_ctlcluster 15 main start
```

напишите получилось или нет и почему
```shell
sudo -u postgres pg_lsclusters
# Ver Cluster Port Status Owner    Data directory               Log file
# 15  main    5432 online postgres /mnt/vdb1/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

зайдите через через psql и проверьте содержимое ранее созданной таблицы
```shell
sudo -u postgres psql iso
```
```postgresql
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |
| 4  | sveta      | svetova     |

задание со звездочкой *: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с
данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и
запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и
что в итоге получилось.

> Для монтирования директорий воспользовался NFS
> https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-22-04


```shell
# На хост машине
echo '/mnt/vdb1/postgresql/15 vm-ubuntu-second(rw,sync,no_root_squash,no_subtree_check)' >> /etc/exports
```

```shell
# На клиент машине
echo 'vm-ubuntu:/mnt/vdb1/postgresql/15 /nfs/postgresql/15 nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0' >> /etc/fstab
vim /etc/postgresql/15/main/postgresql.conf
# Указываем целевую директорию
# data_directory = '/nfs/postgresql/15/main'
sudo -u postgres psql iso
```

```postgresql
-- На клиент машине
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |
| 4  | sveta      | svetova     |

```postgresql
-- На клиент машине
insert into persons (first_name, second_name) values ('anton', 'antonov');
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |
| 4  | sveta      | svetova     |
| 5  | anton      | antonov     |

```postgresql
-- На хост машине
select * from persons;
```
| id | first_name | second_name |
|----|------------|-------------|
| 1  | ivan       | ivanov      |
| 2  | petr       | petrov      |
| 3  | sergey     | sergeev     |
| 4  | sveta      | svetova     |
| 5  | anton      | antonov     |
