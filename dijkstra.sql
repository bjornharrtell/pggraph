-- Function: testschema.dijkstra(integer, integer)

-- DROP FUNCTION testschema.dijkstra(integer, integer);

CREATE OR REPLACE FUNCTION testschema.dijkstra(startnode integer, endnode integer)
  RETURNS void AS
$BODY$
DECLARE
    rowcount int;
    fromnode int;
    currentestimate int;
BEGIN
    -- Create a temporary table for storing the estimates as the algorithm runs
    CREATE TEMP TABLE nodeestimate
    (
        id int PRIMARY KEY,      -- The Node Id
        estimate int NOT NULL,   -- What is the distance to this node, so far?
        predecessor int NULL,    -- The node we came from to get to this node with this distance.
        done boolean NOT NULL    -- Are we done with this node yet (is the estimate the final distance)?
    );

    -- Fill the temporary table with initial data
    INSERT INTO nodeestimate (id, estimate, predecessor, done)
        SELECT id, 9999999999, NULL, 0 FROM nodeestimate;
    
    -- Set the estimate for the node we start in to be 0.
    UPDATE nodeestimate SET estimate = 0 WHERE id = startnode;
    GET DIAGNOSTICS rowcount = ROW_COUNT;
    IF rowcount <> 1 THEN
        DROP TABLE nodeestimate;
        RAISE 'Could not set start node';
        RETURN;
    END IF;

    fromnode := NULL;

    LOOP
        -- Select the Id and current estimate for a node not done, with the lowest estimate.
        SELECT fromnode = id, currentestimate = estimate
	    FROM nodeestimate WHERE done = 0 AND estimate < 9999999999
	    ORDER BY estimate LIMIT 1;
        
        -- Stop if we have no more unvisited, reachable nodes.
        IF fromnode IS NULL OR fromnode = endnode THEN EXIT; END IF;

        -- We are now done with this node.
        UPDATE nodeestimate SET done = TRUE WHERE id = fromnode;

        -- Update the estimates to all neighbour node of this one (all the nodes
        -- there are edges to from this node). Only update the estimate if the new
        -- proposal (to go via the current node) is better (lower).
        UPDATE nodes
            SET estimate = currentestimate + weight, predecessor = fromnode
            FROM nodes AS n INNER JOIN edge AS e ON n.id = e.tonode
            WHERE done = 0 AND e.fromnode = fromnode AND (currentestimate + e.weight) < n.estimate;

    END LOOP;

    -- Select the results. We use a recursive common table expression to
    -- get the full path from the start node to the current node.
    WITH RECURSIVE BacktraceCTE(id, name, distance)
    AS
    (
        -- Anchor/base member of the recursion, this selects the start node.
        SELECT n.id, n.estimate
        FROM nodeestimate n JOIN node ON n.id = node.id
        WHERE n.id = startnode
		
        UNION ALL
		
        -- Recursive member, select all the nodes which have the previous
        -- one as their predecessor. Concat the paths together.
        SELECT n.id, node.name, n.estimate
        FROM nodeestimate n JOIN BacktraceCTE cte ON n.predecessor = cte.Id
        JOIN node ON n.id = node.id
    )
    SELECT id, name, distance FROM BacktraceCTE
    WHERE id = endnode OR endnode IS NULL -- This kind of where clause can potentially produce
    ORDER BY Id;                           -- a bad execution plan, but I use it for simplicity here.
    
    DROP TABLE nodeestimate;

    RETURN;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION testschema.dijkstra(integer, integer)
  OWNER TO postgres;

