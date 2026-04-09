
/* 
   Convenção:
    1. cria a entidade
    2. popula com dados iniciais
 */

/*  
   USUÁRIOS
*/

create table usuarios (
    id       integer primary key autoincrement, 
    usuario  text not null,
    senha    text not null,
    ativo    integer
);


/*  
   CARGOS
*/
create table cargos (
    id    integer primary key autoincrement,
    nome  text not null
);


insert into cargos (nome) values ('Recepcionista');
insert into cargos (nome) values ('Gerente');

/*  
   FUNCIONÁRIOS
*/
create table funcionarios (
    id          integer primary key autoincrement,
    nome        text not null,
    id_cargo    integer not null,
    id_usuario  integer,
    ativo       integer,

    foreign key(id_cargo) references cargos(id),
    foreign key(id_usuario) references usuarios(id)
);

insert into funcionarios (nome, id_cargo, ativo) values ('Cristiane Barros', 1, 1);



/*  
   CLIENTES
*/
create table clientes(
    id          integer primary key autoincrement,
    nome        text not null,
    celular     text,
    contato     text,
    cadastro    text  /* ISO8601 strings ("YYYY-MM-DD HH:MM:SS.SSS") */
);


/*  
   CONTRATOS
   ------   
   todo: levantar os atributos do contrado
*/
create table contratos (
    id           integer primary key autoincrement
);


/*  
   CLIENTES
   ------
   tipo (C = carro, M = moto)
*/
create table veiculos (
    id           integer primary key autoincrement,
    tipo         text(1) not null check( tipo in ('C', 'M') ),
    marca        text,
    modelo       text,
    ano          integer,
    placa        text not null,
    cadastro     text,  /* ISO8601 strings ("YYYY-MM-DD HH:MM:SS.SSS") */

    id_cliente   integer,
    id_contrato  integer,

    foreign key(id_cliente) references clientes(id),
    foreign key(id_contrato) references contratos(id)
);



/*  
   MOVIMENTAÇÕES
   ------
   controla as movimentações de entrada e saída dos veículos
   tipo (E = entrada, S = saída)
*/
create table movimentacoes (
    id              integer primary key autoincrement,
    data            text,  /* ISO8601 strings ("YYYY-MM-DD HH:MM:SS.SSS") */
    tipo            text(1) not null check( tipo in ('E', 'S') ),
    id_veiculo      int not null,  
    id_funcionario  int not null,  

    foreign key(id_veiculo) references veiculos(id),
    foreign key(id_funcionario) references funcionarios(id)
);


