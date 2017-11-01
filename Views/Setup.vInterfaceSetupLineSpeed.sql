SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Bryan Eddy
-- Create date: 9/14/2017
-- Description:	Interface view of needed information from the Recipe Management Syste / PSS DB
-- =============================================
CREATE VIEW [Setup].[vInterfaceSetupLineSpeed]
AS
	SELECT K.SetupNumber,E.AttributeValue, k.SetupDesc, PlanetTogetherMachineNumber, I.AttributeID,
	ROW_NUMBER() OVER (PARTITION BY K.SetupNumber,PlanetTogetherMachineNumber ORDER BY K.SetupNumber,PlanetTogetherMachineNumber,E.AttributeValue  ASC ) AS RowNumber
	 FROM  Setup.tblSetup K
	 INNER JOIN setup.tblSetupAttributes E ON E.SetupID = K.SetupID
	 INNER JOIN [Setup].[tblAttributes] I ON E.AttributeID = I.AttributeID
	 INNER JOIN setup.tblProcessMachines B ON B.MachineID = K.MachineID
	 AND B.ProcessID = E.ProcessID
	 INNER JOIN Scheduling.MachineCapabilityScheduler Y ON Y.MachineName = B.PlanetTogetherMachineNumber AND Y.Setup = K.SetupNumber
	 WHERE I.AttributeName LIKE 'LINESPEED' 
	  --and K.IneffectiveDate > GETDATE() 
	  AND I.AttrIneffectiveDate > GETDATE()
	 AND e.IneffectiveDate > GETDATE() --AND E.ProcessID NOT IN (510,523,615,850)
	 AND b.Active <> 0 AND K.IneffectiveDate >= GETDATE()
	 AND Y.ActiveScheduling = 1
	 

GO