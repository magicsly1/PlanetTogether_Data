SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*
Author:			Bryan Eddy
Date:			3/16/2018	
Description:	Shows missing setups and associated items
Version:		1
Update:			Initial creation


*/

CREATE VIEW [Setup].[vMissingSetupsUnion]
AS

	SELECT    DISTINCT 
	G.item_number Item,
	true_operation_code AS Setup
	FROM Setup.vSetupLineSpeed K RIGHT JOIN Setup.vRoutesUnion G ON G.true_operation_code = K.Setup 
	LEFT JOIN Setup.DepartmentIndicator I ON I.department_code = G.department_code
	INNER JOIN dbo.Oracle_Items P ON P.item_number = G.item_number
	WHERE P.inventory_item_status_code NOT IN ('obsolete','CAB REVIEW') AND P.make_buy = 'MAKE' AND g.pass_to_aps ='Y'
	AND I.department_code IS NULL AND G.true_operation_seq_num IS NOT NULL AND (K.MachineName IS NULL)-- OR K.LineSpeed = 0)


GO
