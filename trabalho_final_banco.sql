CREATE DATABASE campeonato_amador
GO

USE campeonato_amador

CREATE TABLE time_futebol
(
    nome_time VARCHAR(50),
    apelido_time VARCHAR(50) not null,
    data_criacao date not null,
    quantidade_jogos INT DEFAULT 0,
    vitorias INT DEFAULT 0,
    empates INT DEFAULT 0,
    derrotas INT DEFAULT 0,
    gols_favor INT DEFAULT 0,
    gols_contra INT DEFAULT 0,
    saldo_gols INT DEFAULT 0,
    pontos_totais INT DEFAULT 0,

    CONSTRAINT pk_nome_time PRIMARY KEY(nome_time)
    -- colocar apelido como not null

)

CREATE TABLE jogo
(
    visitante VARCHAR(50),
    mandante VARCHAR(50),
    gols_visitante INT DEFAULT 0,
    gols_mandante INT DEFAULT 0,
    pontos_visitante INT DEFAULT 0,
    pontos_mandante INT DEFAULT 0,

    CONSTRAINT pk_visitante_mandante PRIMARY KEY(visitante,mandante),
    CONSTRAINT fk_visitante FOREIGN KEY(visitante) REFERENCES time_futebol(nome_time),
    CONSTRAINT fk_mandante FOREIGN KEY(mandante) REFERENCES time_futebol(nome_time),
    CONSTRAINT chk_visitante_mandante CHECK(visitante <> mandante)

)
GO

/****************************************************TRIGGERS*********************************************************/
CREATE OR ALTER PROCEDURE InsercaoTimes @nome_time varchar(50), @apelido_time varchar(50), @data_criacao date
AS
BEGIN
    INSERT INTO time_futebol(nome_time, apelido_time, data_criacao) VALUES (@nome_time, @apelido_time, @data_criacao);
    PRINT 'Time criado com sucesso !'
END
GO

CREATE OR ALTER PROCEDURE DeletarTime @nome_time varchar(50)
AS
BEGIN
   DELETE FROM time_futebol WHERE nome_time = @nome_time
   PRINT 'Time excluído com sucesso !'
END
GO

CREATE OR ALTER PROCEDURE InserirJogo @visitante varchar(50), @mandante varchar(50), @gols_visitante int, @gols_mandante int
AS
BEGIN

INSERT INTO jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES(@visitante, @mandante, @gols_visitante, @gols_mandante);

END
GO

CREATE OR ALTER PROCEDURE DeletarJogo @visitante varchar(50), @mandante varchar(50)
AS
BEGIN
   DELETE FROM jogo WHERE visitante = @visitante AND mandante = @mandante;
END
GO

CREATE OR ALTER PROCEDURE SaldoGols @visitante VARCHAR(50), @mandante VARCHAR(50)
AS
BEGIN
  update time_futebol set saldo_gols = (gols_favor - gols_contra) where nome_time = @visitante;
  update time_futebol set saldo_gols = (gols_favor - gols_contra) where nome_time = @mandante;
END
GO

CREATE OR ALTER PROCEDURE AtualizarTabelaTime @pontos_visitante INT, @pontos_mandante INT, @visitante VARCHAR(50), @mandante VARCHAR(50),
@gols_visitante INT, @gols_mandante INT
AS
BEGIN
   if(@pontos_visitante = @pontos_mandante)
   --empate
   BEGIN
     -- visitante
     UPDATE time_futebol SET empates = empates + 1, 
      quantidade_jogos = quantidade_jogos + 1, 
      pontos_totais = pontos_totais + 1,
      gols_favor = gols_favor + @gols_visitante,
      gols_contra = gols_contra + @gols_mandante
      where nome_time = @visitante;

      --mandante
      UPDATE time_futebol SET empates = empates + 1, 
      quantidade_jogos = quantidade_jogos + 1, 
      pontos_totais = pontos_totais + 1,
      gols_favor = gols_favor + @gols_mandante,
      gols_contra = gols_contra + @gols_visitante
      where nome_time = @mandante;
   END

   if(@pontos_visitante > @pontos_mandante)
   BEGIN
        UPDATE time_futebol SET 
            quantidade_jogos = quantidade_jogos + 1, 
            pontos_totais = pontos_totais + 5,
            gols_favor = gols_favor + @gols_visitante,
            gols_contra = gols_contra + @gols_mandante,
            vitorias = vitorias + 1
            where nome_time = @visitante;

        UPDATE time_futebol SET  
            quantidade_jogos = quantidade_jogos + 1, 
            gols_favor = gols_favor + @gols_mandante,
            gols_contra = gols_contra + @gols_visitante,
            derrotas = derrotas + 1
            where nome_time = @mandante;
    END

    if(@pontos_visitante < @pontos_mandante)
    BEGIN
      UPDATE time_futebol SET 
            quantidade_jogos = quantidade_jogos + 1, 
            gols_favor = gols_favor + @gols_visitante,
            gols_contra = gols_contra + @gols_mandante,
            derrotas = derrotas + 1
            where nome_time = @visitante;

        UPDATE time_futebol SET  
            quantidade_jogos = quantidade_jogos + 1, 
            gols_favor = gols_favor + @gols_mandante,
            gols_contra = gols_contra + @gols_visitante,
            vitorias = vitorias + 1,
            pontos_totais = pontos_totais + 3
            where nome_time = @mandante;
    END

    EXEC.SaldoGols @visitante, @mandante
END
GO

CREATE OR ALTER TRIGGER tgr_calculo_pontuacao ON jogo AFTER INSERT
AS
BEGIN
IF(UPDATE(gols_visitante) AND UPDATE(gols_mandante))
  BEGIN
    DECLARE @gols_visitante INT, @gols_mandante INT, @visitante VARCHAR(50), @mandante VARCHAR(50), @pontos_visitante INT, @pontos_mandante INT
    SELECT @gols_visitante = gols_visitante, @gols_mandante = gols_mandante, @visitante = visitante, @mandante = mandante
    FROM inserted

    IF(@gols_visitante = @gols_mandante)
    BEGIN
      -- empate
      -- update na tabela de visitante
      update jogo set pontos_visitante = 1,pontos_mandante = 1 where visitante = @visitante and mandante = @mandante;
      set @pontos_visitante = 1
      set @pontos_mandante = 1
    END

   IF(@gols_visitante > @gols_mandante)
   BEGIN
    update jogo set pontos_visitante = 5,pontos_mandante = 0 where visitante = @visitante and mandante = @mandante;
    set @pontos_visitante = 5
    set @pontos_mandante = 0
   END

   IF(@gols_visitante < @gols_mandante)
   BEGIN
    update jogo set pontos_visitante = 0,pontos_mandante = 3 where visitante = @visitante and mandante = @mandante;
    set @pontos_visitante = 0
    set @pontos_mandante = 3
   END
  END

  EXEC.AtualizarTabelaTime @pontos_visitante, @pontos_mandante, @visitante, @mandante, @gols_visitante, @gols_mandante
END
GO

CREATE OR ALTER PROCEDURE MaiorNumeroGolsJogo @nome_time VARCHAR(50)
AS
BEGIN
  declare @max_visitante INT, @max_mandante INT
  select @max_visitante = max(gols_visitante) from jogo where visitante = @nome_time
  select @max_mandante = max(gols_mandante) from jogo where mandante = @nome_time

  if(@max_mandante > @max_visitante)
   print 'O maior número de gols do ' + @nome_time + ' é ' + convert(varchar(50),@max_mandante) 
  if(@max_mandante < @max_visitante)
   print 'O maior número de gols do ' + @nome_time + ' é ' + convert(varchar(50),@max_visitante) 
  if(@max_mandante = @max_visitante)
   print 'O maior número de gols do ' + @nome_time + ' é ' + convert(varchar(50),@max_visitante) 
END
GO

/**********************************************************************************************************************/

/*
INSERT INTO time_futebol(nome_time, apelido_time) 
                  VALUES('Time 1','Apelido do time 1'),
                        ('Time 2','Apelido do time 2'),
                        ('Time 3','Apelido do time 3'),
                        ('Time 4','Apelido do time 4'),
                        ('Time 5','Apelido do time 5');
GO
*/

EXEC.InsercaoTimes 'Time 1', 'Apelido do time 1', '2002-02-1'
EXEC.InsercaoTimes 'Time 2', 'Apelido do time 2', '2003-02-1'
EXEC.InsercaoTimes 'Time 3', 'Apelido do time 3', '2004-02-1'
EXEC.InsercaoTimes 'Time 4', 'Apelido do time 4', '2005-02-1'
EXEC.InsercaoTimes 'Time 5', 'Apelido do time 5', '2006-02-1'
select * from time_futebol

/*
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 1','Time 2',3,3);
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 1','Time 3',2,1);               
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 1','Time 4',1,2);                
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 1','Time 5',4,5);
*/
InserirJogo 'Time 1','Time 2',3,3
InserirJogo 'Time 1','Time 3',2,1
InserirJogo 'Time 1','Time 4',1,2
InserirJogo 'Time 1','Time 5',4,5
/*
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 2','Time 1',0,0);
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 2','Time 3',1,1);               
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 2','Time 4',1,1);                
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 2','Time 5',0,0); 
*/
InserirJogo 'Time 2','Time 1',0,0
InserirJogo 'Time 2','Time 3',1,1
InserirJogo 'Time 2','Time 4',1,1
InserirJogo 'Time 2','Time 5',0,0
/*
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 3','Time 1',0,1);
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 3','Time 2',1,2);               
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 3','Time 4',1,2);                
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 3','Time 5',0,7);
*/
InserirJogo 'Time 3','Time 1',0,1
InserirJogo 'Time 3','Time 2',1,2
InserirJogo 'Time 3','Time 4',1,2
InserirJogo 'Time 3','Time 5',0,7
/*
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 4','Time 1',2,1);
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 4','Time 2',3,2);               
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 4','Time 3',4,2);                
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 4','Time 5',4,0); 
*/
InserirJogo 'Time 4','Time 1',2,1
InserirJogo 'Time 4','Time 2',3,2
InserirJogo 'Time 4','Time 3',4,2
InserirJogo 'Time 4','Time 5',4,0

/*
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 5','Time 1',0,0);
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 5','Time 2',3,3);               
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 5','Time 3',4,5);                
insert into jogo(visitante, mandante, gols_visitante, gols_mandante)VALUES('Time 5','Time 4',4,0);              
GO
*/

InserirJogo 'Time 5','Time 1',0,0
InserirJogo 'Time 5','Time 2',3,3
InserirJogo 'Time 5','Time 3',4,5
InserirJogo 'Time 5','Time 4',4,0


select * from jogo
delete from jogo

CREATE OR ALTER PROCEDURE Campeao
AS
BEGIN
  select  top(1) nome_time as 'Campeão', pontos_totais as 'Pontos', vitorias as 'Vitórias', saldo_gols as 'Saldo de gols' 
  from time_futebol 
  order by pontos_totais desc, vitorias desc, saldo_gols desc
END
GO

EXEC.Campeao

/*
--campeão
select  top(1) nome_time as 'Campeão', pontos_totais as 'Pontos', vitorias as 'Vitórias', saldo_gols as 'Saldo de gols' 
from time_futebol 
order by pontos_totais desc, vitorias desc, saldo_gols desc
*/

CREATE OR ALTER PROCEDURE Classificacao
AS
BEGIN
     select nome_time, pontos_totais, vitorias, saldo_gols 
     from time_futebol 
    order by pontos_totais desc, vitorias desc, saldo_gols desc
END
GO

EXEC.Classificacao
/*
-- classificação
select nome_time, pontos_totais, vitorias, saldo_gols 
from time_futebol 
order by pontos_totais desc, vitorias desc, saldo_gols desc
*/

CREATE OR ALTER PROCEDURE Time_maior_gols_favor
AS
BEGIN
   select top (1) nome_time as 'Time', gols_favor as 'Gols a favor' from time_futebol order by gols_favor desc
END
GO

EXEC.Time_maior_gols_favor
/*
-- times com maior número de gols a favor
select top (1) nome_time as 'Time', gols_favor as 'Gols a favor' from time_futebol order by gols_favor desc
*/


CREATE OR ALTER PROCEDURE Time_maior_gols_contra
AS
BEGIN
   select top(1) nome_time as 'Time', gols_contra as 'Gols sofridos' from time_futebol order by gols_contra desc
END
GO

/*
-- times com maior número de gols sofridos
select top(1) nome_time as 'Time', gols_contra as 'Gols sofridos' from time_futebol order by gols_contra desc
*/

EXEC.Time_maior_gols_contra
--maior número de gols de cada time em um jogo
EXEC.MaiorNumeroGolsJogo 'Time 1'
EXEC.MaiorNumeroGolsJogo 'Time 2'
EXEC.MaiorNumeroGolsJogo 'Time 3'
EXEC.MaiorNumeroGolsJogo 'Time 4'
EXEC.MaiorNumeroGolsJogo 'Time 5'


CREATE OR ALTER PROCEDURE Jogo_com_maior_gols
AS
BEGIN
   select top (1)(gols_visitante + gols_mandante) as 'Soma de gols',concat(mandante,' ',visitante) as 'Jogo' 
   from jogo order by 'Soma de gols' desc
END
GO

EXEC.Jogo_com_maior_gols

/*
-- jogo com mais gols
select top (1)(gols_visitante + gols_mandante) as 'Soma de gols',concat(mandante,' ',visitante) as 'Jogo' 
from jogo order by 'Soma de gols' desc
*/



