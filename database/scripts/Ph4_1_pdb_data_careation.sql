-- 1. CREATE THE PLUGGABLE DATABASE
CREATE PLUGGABLE DATABASE tue_27242_aime_irrigationMS_db
ADMIN USER irrigation_admin IDENTIFIED BY aime
DEFAULT TABLESPACE users
DATAFILE 'C:\oracle21c\oradata\ORCL\tue_27242_aime_irrigationMS_db\users01.dbf' 
SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE 1G
FILE_NAME_CONVERT = ('C:\oracle21c\oradata\ORCL\pdbseed\', 
                     'C:\oracle21c\oradata\ORCL\tue_27242_aime_irrigationMS_db\');

-- 3. OPEN THE NEW PDB
ALTER PLUGGABLE DATABASE tue_27242_aime_irrigationMS_db OPEN;

-- 4. SAVE THE STATE (so it opens automatically on restart)
ALTER PLUGGABLE DATABASE tue_27242_aime_irrigationMS_db SAVE STATE;

-- 5. SHOW ALL PDBS (Verification)
SELECT name, open_mode FROM v$pdbs WHERE name LIKE '%IRRI%';