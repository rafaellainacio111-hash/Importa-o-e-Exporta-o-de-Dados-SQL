USE master;
GO

IF DB_ID('aeronautica_db') IS NOT NULL
BEGIN
    ALTER DATABASE aeronautica_db
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE aeronautica_db;
END;
GO

CREATE DATABASE aeronautica_db;
GO

USE aeronautica_db;
GO

-- TABELA DE MATERIAIS

CREATE TABLE materiais (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(250) NOT NULL,
    descricao VARCHAR(MAX),
    medida VARCHAR(25) NOT NULL,
    estoque_minimo INT DEFAULT 0,
    ativo INT NOT NULL DEFAULT 1
);
GO

-- TABELA DE FORNECEDORES

CREATE TABLE fornecedores (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(250) NOT NULL,
    contato VARCHAR(250),
    telefone VARCHAR(25),
    ativo INT NOT NULL DEFAULT 1
);
GO

-- TABELAS DE ENTRADAS E SAIDAS

CREATE TABLE entradas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    id_material INT NOT NULL,
    id_fornecedor INT NOT NULL,
    data_entrada DATE NOT NULL,
    quantidade INT NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    nota_fiscal VARCHAR(50),

    FOREIGN KEY (id_material)
        REFERENCES materiais(id),

    FOREIGN KEY (id_fornecedor)
        REFERENCES fornecedores(id)
);
GO

CREATE TABLE saidas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    id_material INT NOT NULL,
    data_saida DATE NOT NULL,
    quantidade INT NOT NULL,
    destino VARCHAR(50),

    FOREIGN KEY (id_material)
        REFERENCES materiais(id)
);
GO


USE aeronautica_db;
GO

-- IMPORTAR MATERIAIS

SET IDENTITY_INSERT dbo.materiais ON;

BULK INSERT dbo.materiais
FROM 'C:\Importacao\materiais.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

SET IDENTITY_INSERT dbo.materiais OFF;
GO

-- IMPORTAR FORNECEDORES

SET IDENTITY_INSERT dbo.fornecedores ON;

BULK INSERT dbo.fornecedores
FROM 'C:\Importacao\fornecedores.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

SET IDENTITY_INSERT dbo.fornecedores OFF;
GO

-- CONFERIR A IMPORTAÇÃO

SELECT * FROM dbo.materiais;
SELECT * FROM dbo.fornecedores;
GO


-- PASSO 9: PROCEDIMENTO DE ENTRADA

USE aeronautica_db;
GO

CREATE OR ALTER PROCEDURE dbo.registrar_entrada
    @p_id_material INT,
    @p_id_fornecedor INT,
    @p_data_entrada DATE,
    @p_quantidade INT,
    @p_preco DECIMAL(10,2),
    @p_nota_fiscal VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.entradas (
        id_material,
        id_fornecedor,
        data_entrada,
        quantidade,
        preco,
        nota_fiscal
    )
    VALUES (
        @p_id_material,
        @p_id_fornecedor,
        @p_data_entrada,
        @p_quantidade,
        @p_preco,
        @p_nota_fiscal
    );
END;
GO

-- PASSO 10: REGISTRAR TRES ENTRADAS

EXEC dbo.registrar_entrada
    1, 1, '2023-10-25', 100, 5.50, 'NF001';

EXEC dbo.registrar_entrada
    2, 2, '2023-10-26', 50, 12.00, 'NF002';

EXEC dbo.registrar_entrada
    7, 7, '2023-10-27', 40, 18.90, 'NF150';
GO

SELECT * FROM dbo.entradas;
GO


-- PASSO 11: PROCEDIMENTO DE SAIDA

CREATE OR ALTER PROCEDURE dbo.registrar_saida
    @p_id_material INT,
    @p_data_saida DATE,
    @p_quantidade INT,
    @p_destino VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.saidas (
        id_material,
        data_saida,
        quantidade,
        destino
    )
    VALUES
    ('@p_id_material'),
    ('@p_data_saida'),
    ('@p_quantidade'),
    ('@p_destino');
END;
GO

-- PASSO 12: REGISTRAR DUAS SAIDAS

EXEC dbo.registrar_saida
    3, '2023-11-01', 50, 'OP003';

EXEC dbo.registrar_saida
    6, '2023-11-05', 20, 'OP010';
GO

SELECT * FROM dbo.saidas;
GO


-- PASSO 13: PROCEDIMENTO PARA INATIVAR MATERIAL

CREATE OR ALTER PROCEDURE dbo.inativar_material
    @p_id_material INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.materiais
    SET ativo = 0
    WHERE id = @p_id_material;
END;
GO

-- PASSO 14: INATIVAR DOIS MATERIAIS

EXEC dbo.inativar_material 4;
EXEC dbo.inativar_material 10;
GO

SELECT * FROM dbo.materiais;
GO


-- PASSO 15: PROCEDIMENTO PARA INATIVAR FORNECEDOR

CREATE OR ALTER PROCEDURE dbo.inativar_fornecedor
    @p_id_fornecedor INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.fornecedores
    SET ativo = 0
    WHERE id = @p_id_fornecedor;
END;
GO

-- PASSO 16: INATIVAR DOIS FORNECEDORES

EXEC dbo.inativar_fornecedor 4;
EXEC dbo.inativar_fornecedor 10;
GO

SELECT * FROM dbo.fornecedores;
GO


-- PASSO 17: FUNCAO PARA CALCULAR O ESTOQUE

CREATE OR ALTER FUNCTION dbo.calcular_estoque (
    @p_id_material INT
)
RETURNS INT
AS
BEGIN
    DECLARE @total_entradas INT;
    DECLARE @total_saidas INT;

    SELECT @total_entradas =
        ISNULL(SUM(quantidade), 0)
    FROM dbo.entradas
    WHERE id_material = @p_id_material;

    SELECT @total_saidas =
        ISNULL(SUM(quantidade), 0)
    FROM dbo.saidas
    WHERE id_material = @p_id_material;

    RETURN @total_entradas - @total_saidas;
END;
GO

-- PASSO 18: TESTAR A FUNCAO

SELECT dbo.calcular_estoque(1) AS estoque_material_1;
SELECT dbo.calcular_estoque(2) AS estoque_material_2;
SELECT dbo.calcular_estoque(7) AS estoque_material_7;
GO


-- PASSO 19: CRIAR A VIEW DO ESTOQUE

CREATE OR ALTER VIEW dbo.consultar_estoque
AS
SELECT
    id,
    nome,
    medida,
    estoque_minimo,
    dbo.calcular_estoque(id) AS estoque_atual
FROM dbo.materiais;
GO

-- CONSULTAR TODOS OS MATERIAIS EM ORDEM ALFABETICA

SELECT *
FROM dbo.consultar_estoque
ORDER BY nome ASC;
GO


USE aeronautica_db;
GO

-- MATERIAIS
SELECT * FROM dbo.materiais;

-- FORNECEDORES
SELECT * FROM dbo.fornecedores;

-- ENTRADAS
SELECT * FROM dbo.entradas;

-- SAIDAS
SELECT * FROM dbo.saidas;

-- ESTOQUE CALCULADO
SELECT * FROM dbo.consultar_estoque
ORDER BY nome;
GO
