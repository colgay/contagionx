#if defined _ctg_const_included
	#endinput
#endif
#define _ctg_const_included

#define CTG_VERSION "0.1.0"

#define STRLEN_SHORTER 	16
#define STRLEN_SHORT 	32
#define STRLEN_NORMAL 	64
#define STRLEN_LONG 	128
#define STRLEN_LONGER 	256
#define STRLEN_LONGEST 	512

enum _:ForwardType
{
	FW_PRE,
	FW_POST
};

enum PlayerTeam
{
	Team_None,
	Team_Zombie,
	Team_Human,
	Team_Spectator,
};