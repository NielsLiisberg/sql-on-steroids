-- SQL Services:
-- https://www.ibm.com/docs/en/i/7.5?topic=optimization-i-services

-- My favorite "goto guy"
select * from qsys2.services_info;

-- Anything with IFS
select * from qsys2.services_info where service_name like '%IFS%';

-- and then use the example of the service:
select example from qsys2.services_info where service_name like '%IFS%';

-- .. copy / paste and modify from the example column:

-- Description: List basic information for all the objects in directory /usr. 
SELECT PATH_NAME, OBJECT_TYPE, DATA_SIZE, OBJECT_OWNER 
FROM TABLE (QSYS2.IFS_OBJECT_STATISTICS(START_PATH_NAME => '/home/nli', SUBTREE_DIRECTORIES => 'YES')); -- Description: List basic information for all the objects in /usr, processing all -- subdirectories as well. SELECT PATH_NAME, OBJECT_TYPE, DATA_SIZE, OBJECT_OWNER FROM TABLE (QSYS2.IFS_OBJECT_STATISTICS(START_PATH_NAME => '/usr', SUBTREE_DIRECTORIES => 'YES'));


-- Description: Read the data from stream file /usr/file1. Break lines when a carriage -- return/line feed sequence is encountered. The result will be in the job's CCSID. 
SELECT line FROM TABLE(QSYS2.IFS_READ(PATH_NAME => '/home/nli/.viminfo', END_OF_LINE => 'LF'));

-- Or use "Insert from examples"

-- Or look into my "gist"
-- https://www.ibm.com/docs/en/i/7.5?topic=is-ifs-write-ifs-write-binary-ifs-write-utf8-procedures
-- https://gist.github.com/NielsLiisberg/3a5ea6d03687310f877ec65a7748e196
