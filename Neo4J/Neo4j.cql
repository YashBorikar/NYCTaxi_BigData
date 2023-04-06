// Task 0: Finding isolated nodes

// Task 0.1: Find all self pointing relationship instances of type :CONNECTS
MATCH (zone)-[trip:CONNECTS]->(zone)
RETURN zone, trip

// Count of self pointing relationship instances of type :CONNECTS
MATCH (zone)-[trip:CONNECTS]->(zone)
RETURN count(zone)

// Task 0.2: Find all isolated nodes
MATCH (nodes)
WHERE NOT ((nodes)-[:CONNECTS]-())
AND NOT (nodes)-[:CONNECTS]-(nodes)
RETURN nodes


// Task 1: Community Detection using Louvain algorithm

// Graph projection
CALL gds.graph.create(
'220624059-communities',
'zone',
{
CONNECTS: {
    orientation: 'UNDIRECTED',
    properties: 'trips'
}
});

// Task 1.1: Louvain algorithm for community detection in stream mode
CALL gds.louvain.stream('220624059-communities')
YIELD nodeId, communityId
WITH gds.util.asNode(nodeId) AS node, communityId
RETURN node.id AS zone_id, communityId AS community_id;

// Task 1.2: Louvain algorithm for community detection in stats mode
CALL gds.louvain.stats('220624059-communities')
YIELD communityCount


// Task 2: Centrality Analysis using Page Rank Algorithm

// Graph projection
CALL gds.graph.create(
    '220624059-centraility',
    'zone',
{
    CONNECTS: {
        orientation: 'NATURAL',
        properties: 'trips'
    }
}
)

// Task 2.1: Page Rank Algorithm for Centrality Analysis in stream mode
CALL gds.pageRank.stream('220624059-centraility', {dampingFactor: 0.75})
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS node, score
RETURN node.id AS zone_id, score AS score
ORDER BY zone_id ASC

// Task 2.2: Page Rank Algorithm for Centrality Analysis in stats mode
CALL gds.pageRank.stats('220624059-centraility', {dampingFactor: 0.75})
YIELD centralityDistribution
RETURN centralityDistribution.max AS max, centralityDistribution.min AS min


// Task 3: Zone Recommendation

// Task 3.1: Top 3 highest centraility zones per each community including Manhattan borough
MATCH (z:zone)-[:IN]->(b:borough)
WITH z, z.centrality AS score
ORDER BY z.community, score DESC
WITH z.community AS community_id, collect({zone_id: z.id, score: score})[..3] AS top3zones
UNWIND top3zones AS zones
RETURN zones.zone_id AS zone_id, community_id
ORDER BY community_id, zone_id

// Task 3.2: Top 3 highest centraility zones per each community excluding Manhattan borough
MATCH (z:zone)-[:IN]->(b:borough)
WHERE NOT b.name = 'Manhattan'
WITH z, z.centrality AS score
ORDER BY z.community, score DESCENDING
WITH z.community AS community_id, collect({zone_id: z.id, score: score})[..3] AS top3zones
UNWIND top3zones AS zones
RETURN zones.zone_id AS zone_id, community_id
ORDER BY community_id, zone_id
