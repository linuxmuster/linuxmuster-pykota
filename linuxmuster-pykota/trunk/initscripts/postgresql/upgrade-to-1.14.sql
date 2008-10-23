--
-- PyKota - Print Quotas for CUPS and LPRng
--
-- (c) 2003, 2004, 2005, 2006, 2007 Jerome Alet <alet@librelogiciel.com>
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
--
-- $Id: upgrade-to-1.14.sql 2440 2007-01-17 22:19:42Z jerome $
--
--
                        
--                         
-- WARNING : YOU NEED A RECENT VERSION OF POSTGRESQL FOR THE ALTER COLUMN STATEMENT TO WORK !
--

--                         
-- Modify the old database schema
--
ALTER TABLE users ADD COLUMN email TEXT;
CREATE USER pykotauser;
REVOKE ALL ON users, groups, printers, userpquota, grouppquota, groupsmembers, jobhistory FROM pykotauser;
REVOKE ALL ON users_id_seq, groups_id_seq, printers_id_seq, userpquota_id_seq, grouppquota_id_seq, jobhistory_id_seq FROM pykotauser;
GRANT SELECT ON users, groups, printers, userpquota, grouppquota, groupsmembers, jobhistory TO pykotauser;
