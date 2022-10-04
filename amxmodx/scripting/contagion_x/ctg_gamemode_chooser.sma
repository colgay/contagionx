#include <amxmodx>
#include <ctg_gamerules_const>
#include <ctg_gamemode>
#include <ctg_util>

enum (+=100)
{
	TASK_START
};

new CvarMinPlayers;

public plugin_init()
{
	register_plugin("[CTG] Game Mode Chooser", CTG_VERSION, "colg");

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start");

	new pcvar = get_cvar_pointer("ctg_min_players");
	if (pcvar)
		bind_pcvar_num(pcvar, CvarMinPlayers);
}

public Event_NewRound()
{
	remove_task(TASK_START);
}

public LogEvent_RoundStart()
{
	set_dhudmessage(0, 255, 0, -1.0, 0.25, 0, 0.0, 10.0, 1.0, 1.0);
	show_dhudmessage(0, "covid-19 病毒在空氣中飄散...");

	remove_task(TASK_START);
	set_task(20.0, "TaskStartGame", TASK_START);
}

public TaskStartGame()
{
	if (get_gamerules_int("CHalfLifeMultiplay", "m_iRoundWinStatus") != WINSTATUS_NONE)
	{
		return;
	}

	new count = CountSpawnablePlayers();
	if (count < CvarMinPlayers || !get_gamerules_int("CHalfLifeMultiplay", "m_bFirstConnected"))
	{
		client_print(0, print_center, "Wait for %d more human(s) to participate the covid-19 party...", CvarMinPlayers - count);
		remove_task(TASK_START);
		set_task(2.0, "TaskStartGame", TASK_START);
		return;
	}

	ctg_StartGameMode(_, "infection");
}