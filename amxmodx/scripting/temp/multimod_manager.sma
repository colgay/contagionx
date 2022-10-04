#include <amxmodx>
#include <amxmisc>

#pragma ctrlchar '\'

#define VERSION "0.1"
#define szx(%0) %0, charsmax(%0)

enum _:GameMod_e
{
	GM_Name[32],
	GM_Desc[50],
	Array:GM_aPlugins,
	Array:GM_aMaps,
	Trie:GM_tMaps,
	GM_CfgFile[96],
};

new Array:g_aMaps;
new Trie:g_tMaps;
new g_mapCount;

new Array:g_aGameMods;
new g_gameModCount;

public plugin_precache()
{
	// prepare data
	g_aMaps = ArrayCreate(32);
	g_tMaps = TrieCreate();
	g_aGameMods = ArrayCreate(GameMod_e);

	g_mapCount = loadMaps();
	g_gameModCount = loadMods();
}

public plugin_init()
{
	register_plugin("Multi-Mod Manager", VERSION, "peter5001");
}

loadMaps()
{
	new fileName[40];
	new handleDir = open_dir("maps", szx(fileName)); // open the map directory

	if (!handleDir) // cannot open directory
		return 0;
	
	new fileNameLen = 0;
	new mapCount = 0;
	new mapIndex;
	do
	{
		fileNameLen = strlen(fileName);
		if (fileNameLen < 5)
			continue;

		if (equal(fileName[fileNameLen - 4], ".bsp")) // is .bsp file
		{
			fileName[fileNameLen - 4] = '\0';
			mapIndex = mapCount;
			ArrayPushString(g_aMaps, fileName); // push to array
			TrieSetCell(g_tMaps, fileName, mapIndex); // set to hashmap
			//server_print("map '%s' added", fileName);
			mapCount++;
		}
	}
	while (next_file(handleDir, szx(fileName))); // find next file

	close_dir(handleDir);
	return mapCount; // return the number of loaded maps
}

loadMods()
{
	new dirName[96];
	get_configsdir(szx(dirName));

	new modIniPath[96];
	formatex(szx(modIniPath), "%s/multimod/multimod.ini", dirName);

	new file = fopen(modIniPath, "r");

	while (!feof(file))
	{
		fgets(file)
	}
}