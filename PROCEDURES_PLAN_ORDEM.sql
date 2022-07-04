--PROCEDURE ORDEM_PROD
--SELECT * FROM PED_VENDAS
--SELECT * FROM PED_VENDAS_ITENS
--SELECT * FROM ORDEM_PROD
--MAT 1 QTD 35
--MAT 2 QTD 40
--PROCEDURE QUE GERA ORDENS DE PRODUCAO COM BASE EM PEDIDOS DE VENDAS
USE MINIERP_MULT
GO
CREATE PROCEDURE PROC_PLAN_ORDEM (@COD_EMPRESA INT,
                                  @MES VARCHAR(2), 
                                  @ANO  VARCHAR(4)) 
AS 
 BEGIN 
 --Se ativada esta instru��o tem por objetivo informar 
 --em tela a quantidade de linhas afetadas pela transa��o 
    SET nocount ON 
	DECLARE @ERRO_INTERNO INT;
 BEGIN TRANSACTION 
 --VERIFICANDO SE EXISTE PEDIDOS ABERTO PARA MES E ANO SELECIONADO EMPRESA

 SELECT A.COD_EMPRESA,A.NUM_PEDIDO 
	FROM PED_VENDAS A
	WHERE A.COD_EMPRESA=@COD_EMPRESA
	AND A.SITUACAO='A'
	AND MONTH(A.DATA_ENTREGA)=@MES
    AND YEAR(A.DATA_ENTREGA)=@ANO 

  IF @@ROWCOUNT = 0 
 BEGIN  
	SET @ERRO_INTERNO=1;
 END
	ELSE 
    	BEGIN 
			INSERT INTO ORDEM_PROD 
			OUTPUT 'ORDEM PLANEJADA' MSG,INSERTED.COD_EMPRESA,INSERTED.ID_ORDEM ,INSERTED.COD_MAT_PROD
			SELECT A.COD_EMPRESA,B.COD_MAT,SUM(B.QTD) AS QTD_PLAN,0 QTD_PROD, 
			@ANO+'-'+@MES+'-01' AS DATA_INI,
			EOMONTH(@ANO+'-'+@MES+'-01') AS DATA_FIM,'A' --EOMONTH TRAZ ULTIMO DIA DO MES DA DATA PARAM
			FROM PED_VENDAS A
				INNER JOIN PED_VENDAS_ITENS B
				ON A.NUM_PEDIDO=B.NUM_PEDIDO
				AND A.COD_EMPRESA=B.COD_EMPRESA
				WHERE A.COD_EMPRESA=@COD_EMPRESA
				AND A.SITUACAO='A' --APENAS PEDIDO EM ABERTO
				AND MONTH(A.DATA_ENTREGA)=@MES
				AND YEAR(A.DATA_ENTREGA)=@ANO
				GROUP BY A.COD_EMPRESA,B.COD_MAT;
		PRINT 'INSERT ORDEM PROD REALIZADO';
   --ATUALIZANDO STATUS PEDIDO
   UPDATE PED_VENDAS  SET SITUACAO='P'
   OUTPUT 'PEDIDO PLANEJADO' MSG,INSERTED.NUM_PEDIDO,DELETED.SITUACAO DE,INSERTED.SITUACAO PARA
   WHERE COD_EMPRESA=@COD_EMPRESA
   AND SITUACAO='A'
   AND MONTH(DATA_ENTREGA)=@MES
   AND YEAR(DATA_ENTREGA)=@ANO;
   
   PRINT 'PEDIDOS SITUACAO ATUALIZADA'; 
  END --FINAL ELSE 
 --TESTES FINAIS
    IF @ERRO_INTERNO=1
		BEGIN
		 ROLLBACK
		 RAISERROR ('NAO EXISTEM MATERIAIS PARA PLANEJ. ORDEM', -- Message text.  
                      10, -- Severity.  
                      1 -- State.  
                      ); 
		  PRINT 'OPER. CANCELADA ROLLBACK';
        END
     ELSE IF @@ERROR <> 0
		BEGIN
		  ROLLBACK
		  PRINT 'OPERACAO CANCELADA'
		  PRINT @@error 
		END
		ELSE
		BEGIN
		      COMMIT  
		      PRINT 'OPERACAO REALIZADA COM SUCESSO';
     	END
	END 

--SELECT * FROM PED_VENDAS
--SELECT * FROM ORDEM_PROD 
--PARAMETROS EMPRESA MES ANO
EXEC PROC_PLAN_ORDEM 1,2,2018 
--OBJETIVO GERAR ORDENS DE PRODUCAO DE ACORDO COM DEMANDA DE VENDAS
--DROP PROCEDURE PROC_PLAN_ORDEM
--SELECT * FROM ORDEM_PROD
--SELECT * FROM PED_VENDAS