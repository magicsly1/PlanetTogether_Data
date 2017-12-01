SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










-- =============================================
-- Author:      Bryan Eddy
-- Create date: 11/15/2017
-- Description: Procedure to aggregate the fiber count for all cables by operation
-- Version: 2
-- Update:	Replaced delete and insert with Merge
-- =============================================

CREATE PROCEDURE [Setup].[usp_GetFiberCountByOperation]

@RunType INT
AS


	SET NOCOUNT ON;
BEGIN


DECLARE @sql NVARCHAR(MAX);

	BEGIN TRY
		BEGIN TRAN
	
				IF OBJECT_ID(N'tempdb..##BomExplode', N'U') IS NOT NULL
				DROP TABLE ##BomExplode;

				--DECLARE @RunType INT;
				--SET @RunType = 1

				--Run type 1 updates/inserts all item BOM's into dataset
				IF @RunType = 1
					BEGIN
						--DELETE FROM Setup.ItemFiberCountByOperation  --Replaced by Merge statement

			
						SET @sql = 'SELECT E.*
						INTO ##BomExplode
						FROM dbo.Oracle_Items G CROSS APPLY dbo.fn_ExplodeBOM(G.item_number) E
						'--WHERE g.item_number in (''RD2016-0040'',''DNO-9671'',''DNO-1558'')'
					END
				ELSE --Else update only open order items to greatly reduce the time to run procedure
					BEGIN
						--DELETE Setup.ItemFiberCountByOperation   --Replaced by Merge statement
						--FROM Setup.ItemFiberCountByOperation K INNER JOIN dbo.Oracle_Orders G ON G.assembly_item = K.ItemNumber
						SET @sql = 'SELECT e.* 
						INTO ##BomExplode
						FROM (SELECT distinct assembly_item FROM dbo.Oracle_Orders) G CROSS APPLY dbo.fn_ExplodeBOM(G.assembly_item) E
						'--WHERE G.assembly_item = ''DNA-32817'''
					END

				EXEC(@sql)

				CREATE INDEX iBomXplode ON ##BomExplode (comp_item, FinishedGood, ExtendedQuantityPer)

				IF OBJECT_ID(N'tempdb..#FiberCount', N'U') IS NOT NULL
				DROP TABLE #FiberCount;
				;WITH cteFiber
				AS(
					SELECT FinishedGood,p.comp_item, part, position ,make_buy, ExtendedQuantityPer, p.FinishedGoodOpSeq, P.alternate_designator
					FROM dbo.Oracle_Items G CROSS APPLY dbo.usf_SplitString(g.product_class,'.')  
					INNER JOIN ##BomExplode P ON P.comp_item = G.item_number
					WHERE  ((part IN ('Fiber','Ribbon') AND position = 4)  OR (part ='Bare Ribbon' AND position = 5)) AND make_buy = 'buy' --AND p.alternate_designator = 'primary'
				),
				cteFiberCount
				AS(
				--INSERT INTO Setup.ItemAttributes(ItemNumber,FiberCount, FiberMeters)
				SELECT FinishedGood,SUM(CAST(ExtendedQuantityPer AS INT)) AS FiberCount, SUM(ExtendedQuantityPer) AS FiberMeters,cteFiber.FinishedGoodOpSeq,cteFiber.alternate_designator
				FROM cteFiber
				GROUP BY FinishedGood,cteFiber.FinishedGoodOpSeq,alternate_designator
					)
				SELECT k.FinishedGood, k.FinishedGoodOpSeq,alternate_designator,SUM(k.FiberCount) OVER (PARTITION BY FinishedGood,alternate_designator ORDER BY  alternate_designator,FinishedGoodOpSeq,FinishedGoodOpSeq  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) FiberCount
				INTO #FiberCount
				FROM cteFiberCount K

				CREATE INDEX IX_FiberCount ON #FiberCount (FinishedGood, FinishedGoodOpSeq, alternate_designator)

				;WITH cteFiberCountByOp
				AS(
				SELECT DISTINCT G.true_operation_code, J.FiberCount, G.item_number, G.department_code, J.alternate_designator,FinishedGoodOpSeq,true_operation_seq_num
				, MIN(G.true_operation_seq_num) OVER (PARTITION BY J.FiberCount, G.item_number, J.alternate_designator, FinishedGoodOpSeq) Min_true_operation_seq_num
				FROM dbo.Oracle_Routes G 
				INNER JOIN #FiberCount J ON J.alternate_designator = G.alternate_routing_designator AND J.FinishedGood = G.item_number AND G.operation_seq_num >= j.FinishedGoodOpSeq
				INNER JOIN Setup.DepartmentIndicator B ON B.department_code = G.department_code
				)
				,cteUniqueFiberCountByOp
				AS(
				SELECT item_number,cteFiberCountByOp.true_operation_code,cteFiberCountByOp.FiberCount,alternate_designator, cteFiberCountByOp.true_operation_seq_num, cteFiberCountByOp.department_code
				,ROW_NUMBER() OVER (PARTITION BY item_number,cteFiberCountByOp.true_operation_code,alternate_designator ORDER BY cteFiberCountByOp.FiberCount DESC) RowNumber
				FROM cteFiberCountByOp INNER JOIN Setup.DepartmentIndicator B ON B.department_code = cteFiberCountByOp.department_code
				WHERE cteFiberCountByOp.true_operation_seq_num = cteFiberCountByOp.Min_true_operation_seq_num
				)
				--INSERT INTO Setup.ItemFiberCountByOperation(ItemNumber,TrueOperationCode,FiberCount, PrimaryAlternate)
				SELECT G.item_number, G.true_operation_code, G.FiberCount, G.alternate_designator
				INTO #FiberCountByOp
				FROM cteUniqueFiberCountByOp G
				WHERE RowNumber = 1

				--Merge data set into setup.ItemFiberCountByOperation for fiber count
				MERGE setup.ItemFiberCountByOperation AS Target
				USING (
						SELECT item_number, true_operation_code, FiberCount, alternate_designator 
						FROM #FiberCountByOp
						) AS Source ON (Source.item_number = Target.ItemNumber AND Source.true_operation_code = Target.TrueOperationCode
						AND Target.PrimaryAlternate = Source.alternate_designator)
				WHEN MATCHED THEN
					UPDATE SET Target.FiberCount = Source.FiberCount
				WHEN NOT MATCHED BY TARGET THEN
					INSERT (ItemNumber, TrueOperationCode, FiberCount, PrimaryAlternate)
					VALUES	(Source.item_number, Source.true_operation_code, Source.FiberCount, Source.alternate_designator);
				--OUTPUT $action, Inserted.*, Deleted.*; 


				IF OBJECT_ID(N'tempdb..##BomExplode', N'U') IS NOT NULL
				DROP TABLE ##BomExplode;
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
 
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorLine INT = ERROR_LINE();
 
		PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
		PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));
 
		THROW;
	END CATCH

				--INSERT INTO Setup.ItemAttributes(ItemNumber,FiberCount,FiberMeters)
				--SELECT DISTINCT K.item_number, 0,0
				--FROM dbo.Oracle_Items K INNER JOIN dbo.Oracle_BOMs P ON K.item_number = P.item_number
				--LEFT JOIN setup.ItemAttributes G ON K.item_number = G.ItemNumber
				--WHERE G.ItemNumber  IS NULL AND K.make_buy = 'MAKE'
				--ORDER BY item_number




END







GO
