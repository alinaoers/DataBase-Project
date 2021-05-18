create schema if not exists
    carsharing_db;
set search_path = carsharing_db, public;

create table if not exists
    cars (
        car_txt         varchar(6) NOT NULL
        , mark_txt      varchar(1) NOT NULL
        , category_id   integer NOT NULL
        , damag_cnt     integer default 0,
        primary key (car_txt)
);

create table if not exists
    clients (
        first_nm varchar(12) NOT NULL,
        last_nm varchar(12) NOT NULL,
        reg_dt date NOT NULL,
        exp_value integer,
        phone_no varchar(20),
        primary key (first_nm, last_nm, reg_dt)
);
create table if not exists
    location(
    loc_id integer NOT NULL,
    car_cnt integer default 0,
    km_value integer default 10,
    primary key (loc_id)
);

create table if not exists
    state_car (
        car_txt varchar(6) NOT NULL,
        date_dt date NOT NULL,
        time_dt time NOT NULL,
        loc_id integer default 4,
        last_act_id bool,
    primary key (car_txt, date_dt, time_dt),
    foreign key (loc_id) references location (loc_id)
);

create table if not exists
    rent_fact (
        rent_id integer NOT NULL,
        client_nm varchar(12) NOT NULL,
        client_reg_dt date NOT NULL,
        car_txt varchar(6) NOT NULL,
        time_min integer,
        total_sum_value integer,
    primary key (rent_id),
    foreign key (car_txt) references cars (car_txt)
);

create table if not exists
    category (
        category_id integer NOT NULL UNIQUE,
        price_value_6 integer NOT NULL,
        price_value_12 integer NOT NULL,
        price_value_18 integer NOT NULL,
        exp_value integer,
        primary key (category_id)
);

create table if not exists
    lock_facts (
        rent_id integer NOT NULL UNIQUE,
        time_dt time NOT NULL,
        date_dt date NOT NULL,
        primary key (rent_id),
        foreign key (rent_id) references rent_fact (rent_id)
);

create table if not exists
    unlock_facts (
        rent_id integer NOT NULL UNIQUE,
        time_dt time NOT NULL,
        date_dt date NOT NULL,
        primary key (rent_id),
        foreign key (rent_id) references rent_fact (rent_id)
);

--------- заполнение -----------
insert into category
values (0, 5, 6, 7, 0),
       (1, 8, 8, 9, 2);

insert into cars values
    ('a100aa', 'L', 0, 0),
    ('a200aa', 'L', 0, 1),
    ('d300dd', 'R', 0, 1),
    ('d400dd', 'R', 0, 2),
    ('c500cc', 'B', 1, 0);

insert into clients values
    ('Ivan', 'Ivanov', '04-17-2021', 2, '89851468879'),
    ('Petr', 'Petrov', '12-11-2020', 1, '88005553535'),
    ('Vlad', 'Komissarenko', '01-03-2021', 0, '898989898');
insert into clients values
    ('Masha', 'Oreshina', '06-17-2020', 2, '999999999'),
    ('Ilya', 'Gusarov', '06-08-2020', 1, '3333333333');
alter table clients add column pers_discount_value integer default 0;
update clients
set pers_discount_value = 5
where exp_value >= 2;

insert into rent_fact values (0, 'Masha', '06-17-2020', 'a100aa'),
                        (1, 'Ilya', '06-08-2020', 'a100aa'),
                        (3, 'Ivan', '04-17-2021', 'c500cc'),
                        (2, 'Masha', '06-17-2020', 'a200aa');

insert into lock_facts values
    (0, '12:10', '05-14-2021'),
    (1, '18:50', '05-14-2021'),
    (2, '00:07', '05-15-2021'),
    (3, '06:12', '05-15-2021');
alter table lock_facts add loc_id integer NOT NULL default 4;
alter table unlock_facts add loc_id integer NOT NULL default 1;
insert into unlock_facts values
    (0, '14:10', '05-14-2021'),
    (1, '19:40', '05-14-2021'),
    (2, '00:50', '05-15-2021'),
    (3, '07:38', '05-15-2021');
update unlock_facts set loc_id = 4 where rent_id >= 3;
update unlock_facts set loc_id = 1 where rent_id = 0;
update unlock_facts set loc_id = 2 where rent_id = 1;
update unlock_facts set loc_id = 3 where rent_id = 2;

insert into location values (0, 0, 50),
                            (1, 1, 10),
                            (2, 1, 12),
                            (3, 1, 5),
                            (4, 0, 1);
update location set car_cnt = 2 where loc_id = 4;
update rent_fact set time_min = 120 where rent_id = 0;
update rent_fact set time_min = 50 where rent_id = 1;
update rent_fact set time_min = 43 where rent_id = 2;
update rent_fact set time_min = 86 where rent_id = 3;
update rent_fact set total_sum_value = (120 * 6) where rent_id = 0;
update rent_fact set total_sum_value = (50 * 7) where rent_id = 1;
update rent_fact set total_sum_value = (43 * 8 * 0.95) where rent_id = 3;
update rent_fact set total_sum_value = (86 * 5) where rent_id = 2;

insert into state_car
select r.car_txt, lf.date_dt, lf.time_dt, lf.loc_id, true
from rent_fact r inner join lock_facts lf on r.rent_id = lf.rent_id;
insert into state_car
select r.car_txt, uf.date_dt, uf.time_dt, uf.loc_id, false
from rent_fact r inner join unlock_facts uf on r.rent_id = uf.rent_id;


------------- запросы -------------
-- Где чаще всего оставляют и бронируют машины (в какой области)
select loc_id, count(*) as cnt from unlock_facts
group by loc_id
order by cnt;
select loc_id, count(*) as cnt from lock_facts
group by loc_id
order by cnt;

-- статистика дохода компании по дням
create view rent_with_date as (
    select r.rent_id, r.client_nm, r.car_txt, r.total_sum_value, lf.date_dt from rent_fact r
    inner join lock_facts lf on r.rent_id = lf.rent_id
    );

select date_dt, sum(total_sum_value)
from rent_with_date
group by date_dt
order by date_dt asc;

-- понять, кто больше бронирует машины (опытные водители или нет) ----
select count(rent_id), 'experience more then 2' as statistic from rent_fact
where client_nm in (select first_nm from client
    where exp_value >= 2)
union all
select count(rent_id), 'less the 2 experience' from rent_fact
where client_nm in (select last_nm from client
    where exp_value < 2);