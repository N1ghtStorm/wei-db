# Find all graph nodes
MATCH (n)
RETURN n
LIMIT 100

# Find a single node by od 

MATCH (n)
WHERE n.id = 0x0123...
RETURN n