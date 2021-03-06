SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:      Bryan Eddy
-- Create date: 8/23/2017
-- Description: Procedure to update the fiber count of cables with open orders
-- Version: 3
-- Update:	Removed [PlanetTogether_Data_Test] pointer
-- =============================================

CREATE PROCEDURE [Setup].[usp_GetFiberCount]

@RunType INT  --1 to get fiber count data for all items else get fiber count just for open orders

AS

	SET NOCOUNT ON;
BEGIN
DECLARE @ErrorNumber INT = ERROR_NUMBER();
DECLARE @ErrorLine INT = ERROR_LINE();

DECLARE @BomExplode TABLE(
   FinishedGood VARCHAR(100),
   item_number VARCHAR(100), 
   comp_item VARCHAR(100),
   comp_qty_per DECIMAL(18,10),
   ExtendedQuantityPer DECIMAL(18,10),
   primary_uom_code  VARCHAR(50),
   BOMLevel INT NULL,
   item_seq SMALLINT,
   opseq SMALLINT,
   unit_id INT NULL,
   layer_id INT NULL,
   count_per_uom INT,
   alternate_designator  NVARCHAR(10),
   FinishedGoodOpSeq SMALLINT
   )


			--IF OBJECT_ID(N'tempdb..#BomExplode', N'U') IS NOT NULL
			--DROP TABLE #BomExplode;

	IF @RunType = 1
		BEGIN
			INSERT INTO @BomExplode
			SELECT E.*
			--INTO #BomExplode
			FROM dbo.Oracle_Items G CROSS APPLY dbo.fn_ExplodeBOM(G.item_number) E

		END
	ELSE
		BEGIN
			--Insert items from orders
			IF OBJECT_ID(N'tempdb..#OrderItems', N'U') IS NOT NULL
			DROP TABLE #OrderItems;
			SELECT DISTINCT assembly_item 
			INTO #OrderItems
			FROM dbo.Oracle_Orders

			INSERT INTO #OrderItems(assembly_item)
			SELECT DISTINCT component_item 
			FROM dbo.Oracle_Orders I LEFT JOIN #OrderItems K ON K.assembly_item = I.component_item
			WHERE K.assembly_item IS NULL


			INSERT INTO #OrderItems
			SELECT DISTINCT G.item_number
			FROM dbo.Oracle_Items G LEFT JOIN #OrderItems K ON G.item_number = K.assembly_item
			LEFT JOIN SETUP.ItemAttributes P ON P.ItemNumber = G.item_number
			INNER JOIN Oracle_BOMs I ON I.item_number = G.item_number
			WHERE K.assembly_item IS NULL AND P.ItemNumber IS NULL


			INSERT INTO #OrderItems(assembly_item)
			SELECT DISTINCT g.item_number FROM Setup.ItemAttributes K RIGHT JOIN dbo.Oracle_Items G ON K.ItemNumber = G.item_number
			LEFT JOIN #OrderItems P ON P.assembly_item = G.item_number
			WHERE K.ItemNumber IS NULL AND g.make_buy = 'make' AND P.assembly_item IS NULL




			--IF OBJECT_ID(N'tempdb..#BomExplode', N'U') IS NOT NULL
			--DROP TABLE #BomExplode;
			INSERT INTO @BomExplode
			SELECT E.*
			--INTO #BomExplode 
			FROM #OrderItems G CROSS APPLY dbo.fn_ExplodeBOM(G.assembly_item) E

		END


	--Insert Fiber count for all BOM's containing fiber
	BEGIN TRY
		BEGIN tran
			;WITH cteFiber
			AS(
				SELECT FinishedGood,p.comp_item, part, position ,make_buy, ExtendedQuantityPer, CAST(P.ExtendedQuantityPer AS INT) FloorFiberQuanity
				FROM dbo.Oracle_Items G CROSS APPLY dbo.usf_SplitString(g.product_class,'.') 
				INNER JOIN @BomExplode P ON P.comp_item = G.item_number
				WHERE  ((part IN ('Fiber','Ribbon') AND position = 4)  OR (part ='Bare Ribbon' AND position = 5)) AND make_buy = 'buy' AND p.alternate_designator = 'primary'
			)
			SELECT FinishedGood,SUM(CAST(FloorFiberQuanity AS INT)) AS FiberCount,SUM(ExtendedQuantityPer) AS FiberMeters
			INTO #FiberCount
			FROM cteFiber
			GROUP BY FinishedGood


			--Insert items 
			INSERT INTO #FiberCount(FinishedGood, FiberCount, FiberMeters)
			SELECT g.FinishedGood, 0, 0
			FROM #FiberCount K RIGHT JOIN (SELECT DISTINCT FinishedGood FROM @BomExplode g INNER JOIN dbo.Oracle_Items k ON K.item_number = G.FinishedGood WHERE k.make_buy = 'BUY' ) G
			ON G.FinishedGood = K.FinishedGood
			WHERE K.FinishedGood IS NULL

			MERGE setup.ItemAttributes AS Target
			USING (SELECT * FROM #FiberCount) AS Source
			ON (Target.ItemNumber = Source.FinishedGood)
			WHEN MATCHED THEN
				UPDATE SET	Target.FiberCount = source.FiberCount,
							Target.FiberMeters = Source.FiberMeters
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (ItemNumber, FiberCount, FiberMeters)
				VALUES (Source.FinishedGood, Source.FiberCount, Source.FiberMeters);

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
 
		PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
		PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));
 
		THROW;
	END CATCH;

	--Get fiber count for all other items not found above.  Insert fiber count of 0.
	BEGIN TRY
		BEGIN TRAN


			MERGE setup.ItemAttributes AS Target
			USING (SELECT DISTINCT K.assembly_item, 0 FiberCount ,0 FiberMeters
			FROM #OrderItems K INNER JOIN dbo.Oracle_BOMs P ON K.assembly_item = P.item_number
			LEFT JOIN setup.ItemAttributes G ON K.assembly_item = G.ItemNumber
			WHERE G.ItemNumber  IS NULL ) AS Source
			ON (Target.ItemNumber = Source.assembly_item)
			WHEN MATCHED THEN
				UPDATE SET	Target.FiberCount = source.FiberCount,
							Target.FiberMeters = Source.FiberMeters
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (ItemNumber, FiberCount, FiberMeters)
				VALUES (Source.assembly_item, Source.FiberCount, Source.FiberMeters);
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
 
		PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
		PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));
 
		THROW;
	END CATCH;

			--Update any fiber count where product category > 0
	BEGIN TRY
		BEGIN TRAN
			;WITH cteZeroFiberCount
			AS(
				SELECT G.ItemNumber,CategoryName
				FROM Setup.ItemAttributes K INNER JOIN [NAASPB-PRD04\SQL2014].Premise.dbo.AFLPRD_INVItmCatg_CAB G ON K.ItemNumber = G.ItemNumber
				WHERE  G.CategorySetName LIKE '%FIBER COUNT%' --AND ISNUMERIC(G.CategoryName) = 1

			)
			UPDATE K
			SET FiberCount = X.FiberCount
			FROM(
				SELECT SUM(CAST(cteZeroFiberCount.CategoryName AS INT)) FiberCount, cteZeroFiberCount.ItemNumber
				FROM cteZeroFiberCount
				GROUP BY ItemNumber
				) X INNER JOIN Setup.ItemAttributes K ON K.itemnumber = X.itemnumber
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;

 
		PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
		PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));
 
		THROW;
	END CATCH;


END



GO
