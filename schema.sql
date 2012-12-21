CREATE TABLE node
(
  id serial NOT NULL,
  CONSTRAINT node_pkey PRIMARY KEY (id )
)

CREATE TABLE edge
(
  id serial NOT NULL,
  fromnode integer,
  tonode integer,
  weight integer,
  CONSTRAINT edge_pkey PRIMARY KEY (id )
)
