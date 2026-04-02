
/* 
   Convenção:
    1. cria a entidade
    2. popula com dados iniciais
 */

create table cargos (
    id    integer primary key autoincrement,
    nome  text not null
);


insert into cargos (nome) values ('Recepcionista');
insert into cargos (nome) values ('Gerente');

create table funcionarios (
    id       integer primary key autoincrement,
    nome     text not null,
    id_cargo integer not null,
    ativo    integer,

    foreign key(id_cargo) references cargos(id)
);

insert into funcionarios (nome, id_cargo, ativo) values ('Cristiane Barros', 1, 1);


