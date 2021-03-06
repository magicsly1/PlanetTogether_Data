CREATE TABLE [dbo].[APS_BuffersAndWindows_HardCoded]
(
[Name] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ItemType] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [int] NULL,
[DurationDays] [float] NULL,
[ID] [uniqueidentifier] NOT NULL CONSTRAINT [DF__APS_BuffersA__ID__164F3FA9] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[APS_BuffersAndWindows_HardCoded] ADD CONSTRAINT [PK_APS_BuffersAndWindows_HardCoded] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
