#include <amxmodx>

#define MAX_NODES 1024
#define MAX_EDGES 4096
#define MAX_EDGES_PER_NODE 8

#define NULL -1
#define IsValidNode(%0) (NULL < %0 <= g_nodesCount)
#define IsValidEdge(%0) (NULL < %0 <= g_edgesCount)

enum _:Node
{
	Float:Node_Pos[3],
	Float:Node_Radius,
	Node_Flags,
	Node_Edges[MAX_EDGES_PER_NODE], // Edge Index
};

enum _:Edge
{
	Edge_From, // Node Index
	Edge_To, // Node Index
	Edge_Flags,
	Float:Edge_Cost, // Line distance
};

new g_nodes[MAX_NODES][Node];
new g_nodesCount;

new g_edges[MAX_EDGES][Edge];
new g_edgesCount;

stock AddNode(Float:pos[3], Float:radius, flags)
{
	new i = g_nodesCount;
	g_nodes[i][Node_Pos] = pos;
	g_nodes[i][Node_Radius] = radius;
	g_nodes[i][Node_Flags] = flags;
	
	for ()
}

stock bool:AddEdge(from, to, flags, bool:bothWays=true)
{
	if (!IsValidNode(from))
	{
		log_error(AMX_ERR_GENERAL, "[WP] invalid {from} node id (%d)", from);
		return false;
	}

	if (!IsValidNode(to))
	{
		log_error(AMX_ERR_GENERAL, "[WP] invalid {to} node id (%d)", to);
		return false;
	}

	new edgeId;
	new bool:hasEdge = false;
	for (new i = 0; i < MAX_EDGES_PER_NODE; i++)
	{
		edgeId = g_nodes[i][Node_Edges][i];
		if (edgeId == NULL) // invalid edge
			continue;
		
		if (g_edges[edgeId][Edge_To] == to)
		{
			hasEdge = true;
			break;
		}
	}

	new i = g_edgesCount;
	g_edges[i][Edge_From] = from;
	g_edges[i][Edge_To] = to;
	g_edges[i][Edge_Flags] = flags;
	g_edges[i][Edge_Cost] = get_distance_f(g_nodes[from][Node_Pos], g_nodes[to][Node_Pos]);
	return true;
}

SetIndex_Auto(&var, index)
{
	var = index;
	ArrayPushCell()
}