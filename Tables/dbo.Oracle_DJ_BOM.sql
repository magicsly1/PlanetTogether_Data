CREATE TABLE [dbo].[Oracle_DJ_BOM]
(
[unique_id] [decimal] (38, 0) NOT NULL,
[organization_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wip_entity_name] [varchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job_type] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assembly_item] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assembly_description] [varchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[class_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dj_status] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_quantity] [float] NULL,
[net_quantity] [float] NULL,
[dj_wip_supply_type] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[completion_subinventory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[completion_locator] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity_remaining] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity_completed] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity_scrapped] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_released] [datetime] NULL,
[date_completed] [datetime] NULL,
[date_closed] [datetime] NULL,
[schedule_group_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dj_creation_date] [datetime] NULL,
[dj_last_update_date] [datetime] NULL,
[component_item] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operation_seq_num] [float] NULL,
[department_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_required] [datetime] NULL,
[component_description] [varchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[component_primary_uom_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[basis_type] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity_per_assembly] [float] NULL,
[required_quantity] [float] NULL,
[quantity_issued] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity_open] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wip_supply_type] [float] NULL,
[com_wip_supply_type] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity_allocated] [float] NULL,
[comments] [varchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supply_subinventory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supply_locator] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[count_per_uom] [float] NULL,
[layer_id] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_id] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[creation_date] [datetime] NULL,
[last_update_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Oracle_DJ_BOM] ADD CONSTRAINT [PK_Oracle_DJ_BOM] PRIMARY KEY CLUSTERED  ([unique_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_OracleDjBom] ON [dbo].[Oracle_DJ_BOM] ([assembly_item]) INCLUDE ([component_item], [count_per_uom], [operation_seq_num], [quantity_issued], [wip_entity_name]) ON [PRIMARY]
GO
DENY DELETE ON  [dbo].[Oracle_DJ_BOM] TO [NAA\SPB_Scheduling_RW]
GO
