-- Tags: no-parallel
-- Test for issue #93193: Wrong query result with old analyzer and filter by currentDatabase()

-- Create a test table with literal database name values
DROP TABLE IF EXISTS test_03780;
CREATE TABLE test_03780 (id UInt32, db String) ENGINE = MergeTree ORDER BY id;

-- Insert rows - use literal values to avoid any issues with function evaluation during INSERT
INSERT INTO test_03780 SELECT 1, currentDatabase();
INSERT INTO test_03780 SELECT 2, currentDatabase();
INSERT INTO test_03780 VALUES (3, 'other_db');

-- Test with old analyzer and non-localhost replica
SET prefer_localhost_replica=0;
SET enable_analyzer=0;
SET enable_parallel_replicas=0;

-- Test 1: Filter with currentDatabase() using remote() to trigger distributed path
-- This tests the fix for issue #93193 where currentDatabase() was not evaluated
-- on the initiator before being sent to remote shards
SELECT count() FROM remote('127.0.0.1', currentDatabase(), test_03780) WHERE db = currentDatabase();

-- Test 2: Same query twice to ensure consistency
SELECT count() FROM remote('127.0.0.1', currentDatabase(), test_03780) WHERE db = currentDatabase();

-- Test 3: More specific test - should only match rows where db equals currentDatabase()
SELECT id FROM remote('127.0.0.1', currentDatabase(), test_03780) WHERE db = currentDatabase() ORDER BY id;

DROP TABLE test_03780;
