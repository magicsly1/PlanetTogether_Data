SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Author:			Bryan Eddy
Date:			12/17/2017
Description:	An exclusion list for PlanetTogether to prevent orders from erroring out during import/refresh
Version:		1
Update:			n/a


*/

CREATE VIEW	[Setup].[vExclusionItemList]
as
	
	WITH cteSetupLocation
		AS(
			SELECT    DISTINCT 
			G.item_number Item, 
			true_operation_code Setup,
			g.alternate_routing_designator,
			k.MachineName,
			g.department_code
			FROM Setup.vSetupLineSpeed K RIGHT JOIN dbo.Oracle_Routes G ON G.true_operation_code = K.Setup 
			LEFT JOIN Setup.DepartmentIndicator I ON I.department_code = G.department_code
			INNER JOIN dbo.Oracle_Items P ON P.item_number = G.item_number
			WHERE P.inventory_item_status_code NOT IN ('obsolete','CAB REVIEW') AND P.make_buy = 'MAKE'
			AND I.department_code IS NULL AND G.true_operation_seq_num IS NOT NULL AND K.MachineName IS NULL 
		)
	SELECT DISTINCT AssemblyItemNumber AS ItemNumber, G.Setup
	FROM cteSetupLocation G CROSS APPLY setup.fn_whereused(item) K
	UNION 
	SELECT DISTINCT Item AS ItemNumber, cteSetupLocation.Setup
	FROM cteSetupLocation
	--ORDER BY ItemNumber


GO