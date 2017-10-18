USE SANDBOX
GO

IF OBJECT_ID('dbo.TESTCOMPRESS') IS NOT NULL
	DROP TABLE dbo.TESTCOMPRESS;

CREATE TABLE dbo.TESTCOMPRESS
(	ID BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY
	, MESSAGE_ID INT
	, LANGUAGE_ID SMALLINT
	, SEVERITY TINYINT
	, IS_EVENT_LOGGED BIT
	, MSGTEXT NVARCHAR(MAX)
	, OBJNAME NVARCHAR(128)
	, COUNTERNAME NVARCHAR(128)
	, INSTANCENAME NVARCHAR(128)
	, CNTR_VALUE BIGINT
	, CNTR_TYPE INT
);

INSERT INTO dbo.TESTCOMPRESS (MESSAGE_ID, LANGUAGE_ID, SEVERITY, IS_EVENT_LOGGED, MSGTEXT, OBJNAME, COUNTERNAME, INSTANCENAME, CNTR_VALUE, CNTR_TYPE)
SELECT TOP (5000000) M.message_id, M.language_id, M.severity, M.is_event_logged, M.text, P.object_name, P.counter_name, P.instance_name, P.cntr_value, P.cntr_type
FROM SYS.messages AS M
CROSS JOIN SYS.dm_os_performance_counters AS P;

CHECKPOINT;
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;

-- check query
select count(*) from TESTCOMPRESS where MSGTEXT like '%column%';

-- other queries


EXEC sp_estimate_data_compression_savings 'dbo','TESTCOMPRESS',null,null,'row';
EXEC sp_estimate_data_compression_savings 'dbo','TESTCOMPRESS',null,null,'page';

sp_spaceused 'dbo.TESTCOMPRESS'

ALTER TABLE [dbo].[TESTCOMPRESS] REBUILD WITH ( DATA_COMPRESSION = ROW );
ALTER TABLE [dbo].[TESTCOMPRESS] REBUILD WITH ( DATA_COMPRESSION = PAGE );
ALTER TABLE [dbo].[TESTCOMPRESS] REBUILD WITH ( DATA_COMPRESSION = NONE );

ALTER INDEX IDX_MESSAGE_ID ON DBO.TESTCOMPRESS REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IDX_MESSAGE_ID ON DBO.TESTCOMPRESS (MESSAGE_ID) WITH (FILLFACTOR=90);
CREATE NONCLUSTERED INDEX IDX_COUNTERNAME ON DBO.TESTCOMPRESS (COUNTERNAME) WITH (FILLFACTOR=90);

select o.name as 'objectname'
	, o.type as 'objecttype'  
	, i.name as 'indexname'
	, i.type as 'indextype'
	, p.partition_number
	, p.data_compression_desc
from sys.partitions as p
inner join sys.objects as o on p.object_id = o.object_id 
inner join sys.indexes as i on p.object_id = i.object_id and p.index_id = i.index_id
where p.object_id = object_id('testcompress')
