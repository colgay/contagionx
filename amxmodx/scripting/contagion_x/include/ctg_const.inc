#if defined _ctg_const_included
	#endinput
#endif
#define _ctg_const_included

#define CTG_VERSION "0.1"

#define CTG_PREFIX "^4[CTG]^1 "

#define CTG_NULL -1

enum PlayerTeam
{
	Team_None = 0,
	Team_Zombie,
	Team_Human,
	Team_Spectator,
};

enum _:Forward_e
{
	FwPre,
	FwPost
};

enum _:PlayerClassAssets_e
{
	Array:PlClsAsset_PlayerModels,
	Trie:PlClsAsset_ViewModels,
	Trie:PlClsAsset_WeapModels,
	Trie:PlClsAsset_Sounds,
};

enum _:PlayerClassCvars_e
{
	PlClsCvar_Hp,
	PlClsCvar_Gravity,
	PlClsCvar_Speed,
	PlClsCvar_Knockback,
};

enum _:PlayerClass_e
{
	PlCls_Name[32],
	PlCls_Desc[64],
	PlCls_UniqueId[32],
	PlCls_Flags,
	PlayerTeam:PlCls_Team,
	PlCls_Parent,
	PlCls_Assets[PlayerClassAssets_e],
	PlCls_Cvars[PlayerClassCvars_e],
	PlCls_Plugin,
};