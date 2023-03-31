select * from Consultas
select * from medicos_info
select * from ambulatorios_capacitys
select * from pacientes_info
select * from totalconsultas_by_codm
select * from consultas_relation

--codm, nome, RG e idade dos médicos ortopedistas;
CREATE VIEW medicos_info
AS
SELECT
   codm as Codigo,
   nome as Nome,
   RG,
   idade as Idade	
FROM public.medicos me
WHERE me.especialidade like '%ortopedia%';

--dados de ambulatórios com capacidade superior a 30. Defina esta visão com a opção with check option;
CREATE VIEW ambulatorios_capacitys
AS
SELECT
  nroa as NROA,
  andar as Andar,
  capacidade as Capacidade
FROM public.ambulatorios ambu
WHERE ambu.capacidade > 30
WITH CHECK OPTION;

--nome, idade e problema dos pacientes;
CREATE VIEW pacientes_info
AS
SELECT
   nome as Nome,
   idade as Idade,
   problema as Problema
FROM public.pacientes pa;

--codm e total de consultas marcadas para este codm;
CREATE VIEW totalconsultas_by_codm
AS
SELECT
   codm as Codigo,
   COUNT(*) as TotalConsultas
FROM public.consultas con
GROUP BY con.codm
ORDER BY con.codm;

--codm, nome do médico, RG do paciente, nome do paciente e data da consulta do médico com o paciente.
CREATE OR REPLACE VIEW consultas_relation
AS
SELECT 
	me.codm as CodigoMedico,
	me.nome as NomeMedico,
    	pa.rg as RG, 
	pa.nome as NomePaciente,
	con.dia as "Dia Da Consulta"
FROM Consultas con 
INNER JOIN Pacientes pa on pa.codp = con.codp
INNER JOIN Medicos me on me.codm = con.codm
ORDER BY me.Nome


CREATE OR REPLACE FUNCTION  insert_consultas()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO medicos (codm, nome) VALUES (NEW.CodigoMedico, NEW.NomeMedico);
  INSERT INTO pacientes (rg,nome)VALUES (NEW.rg, NEW.nome);
  INSERT INTO consultas (dia) VALUES (NEW.dia);
END;
$$ LANGUAGE plpgsql;	
						 
CREATE OR REPLACE TRIGGER insert_consultas_relation
INSTEAD OF INSERT ON consultas_relation
FOR EACH ROW
EXECUTE FUNCTION insert_consultas();
--Defina um trigger para a primeira visão. Este trigger deve garantir que sempre que um médico
--for inserido através da visão, a especialidade do médico seja definida como ortopedia

CREATE OR REPLACE FUNCTION definir_especialidade_ortopedia()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO medicos (codm, nome, rg, idade, especialidade)
    VALUES (NEW.codigo, NEW.nome, NEW.rg, NEW.idade, 'ortopedia');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_especialidade_ortopedia_trigger
INSTEAD OF INSERT ON medicos_info
FOR EACH ROW
EXECUTE FUNCTION definir_especialidade_ortopedia();


INSERT INTO medicos_info (codigo,nome,rg,idade) VALUES (6,'Julyane', '123455667',24);
INSERT INTO ambulatorios_capacitys(NROA,andar,capacidade) VALUES (7,3,45);
INSERT INTO pacientes_info(nome,idade,problema) VALUES('Maria Julia', 12,'febre');
INSERT INTO consultas_relation(codigoMedico, nomeMedico, RG, nomePaciente, "Dia Da Consulta")
VALUES (2, 'Maria', 12224545, 'joaquina', '2023-03-08');


UPDATE medicos_info SET nome = 'João Carlos' WHERE codigo = 1;
UPDATE pacientes_info SET problema = 'febre' WHERE nome LIKE 'Ana';
UPDATE ambulatorios_capacitys SET capacidade = 45 WHERE andar= 2;
UPDATE consultas_relation SET nomemedico = 'José Carlos' WHERE codigomedico = 4;
