CREATE OR REPLACE FUNCTION dijkstra2(startnode int, endnode int)
  RETURNS int AS
$BODY$
DECLARE
    rowcount int;
    currentfromnode int;
    currentestimate int;
BEGIN
    -- Create a temporary table for storing the estimates as the algorithm runs
    CREATE TEMP TABLE nodeestimate
    (
        id int PRIMARY KEY,      -- The Node Id
        estimate int NOT NULL,   -- What is the distance to this node, so far?
        predecessor int NULL,    -- The node we came from to get to this node with this distance.
        done boolean NOT NULL    -- Are we done with this node yet (is the estimate the final distance)?
    ) ON COMMIT DROP;

    -- Fill the temporary table with initial data
    INSERT INTO nodeestimate (id, estimate, predecessor, done)
        SELECT node.id, 999999999, NULL, FALSE FROM node;
    
    -- Set the estimate for the node we start in to be 0.
    UPDATE nodeestimate SET estimate = 0 WHERE nodeestimate.id = startnode;
    GET DIAGNOSTICS rowcount = ROW_COUNT;
    IF rowcount <> 1 THEN
        DROP TABLE nodeestimate;
        RAISE 'Could not set start node';
        RETURN -1;
    END IF;

    -- Run the algorithm until we decide that we are finished
    LOOP
        -- Reset the variable, so we can detect getting no records in the next step.
        currentfromnode := NULL;
    
        -- Select the Id and current estimate for a node not done, with the lowest estimate.
        SELECT nodeestimate.id, estimate INTO currentfromnode, currentestimate
	        FROM nodeestimate WHERE done = FALSE AND estimate < 999999999
	        ORDER BY estimate LIMIT 1;

        -- Stop if we have no more unvisited, reachable nodes.
        IF currentfromnode IS NULL OR currentfromnode = endnode THEN EXIT; END IF;

        -- We are now done with this node.
        UPDATE nodeestimate SET done = TRUE WHERE nodeestimate.id = currentfromnode;

        -- Update the estimates to all neighbour node of this one (all the nodes
        -- there are edges to from this node). Only update the estimate if the new
        -- proposal (to go via the current node) is better (lower).
        UPDATE nodeestimate n
            SET estimate = currentestimate + weight, predecessor = currentfromnode
            FROM edge AS e
            WHERE n.id = e.tonode AND n.done = FALSE AND e.fromnode = currentfromnode AND (currentestimate + e.weight) < n.estimate;

    END LOOP;

    RETURN currentestimate;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

