create table if not exists persons
(
    id          smallserial,
    first_name  text,
    second_name text
);
insert into persons(first_name, second_name)
values ('ivan', 'ivanov'),
       ('petr', 'petrov');
