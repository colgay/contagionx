#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <orpheu>
#include <orpheu_stocks>
#include <ctg_gamemode>
#include <ctg_gamerules_const>
#include <ctg_util>

enum (+=100)
{
	TASK_RESPAWN = 0,
}

const WEAPON_SUIT_BIT = 1 << 31;
const OFFSET_MAPZONES = 235;
const MAPZONE_BUY = (1 << 0);
const VGUIMENU_JOINCLASS_T = 26;
const VGUIMENU_JOINCLASS_CT = 27;
new const SHOWMENU_JOINCLASS_T[] = "#Terrorist_Select";
new const SHOWMENU_JOINCLASS_CT[] = "#CT_Select";

new const g_RemoveEntities[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"func_buyzone"
};

new g_fwEntSpawn;
new g_pGameRules;

new CvarMinPlayers, CvarDeathMatch, CvarRespawnHumans, CvarRespawnZombies, CvarRespawnSuicide;
new Float:CvarRespawnDelayMin, Float:CvarRespawnDelayMax;

public plugin_precache()
{
	// create dummy buyzone
	new ent;
	for (new team = 1; team <= 2; team++)
	{
		ent = create_entity("func_buyzone");
		if (ent)
		{
			set_pev(ent, pev_team, team);
			DispatchSpawn(ent);
			entity_set_origin(ent, Float:{0.0, 0.0, 0.0});
			entity_set_size(ent, Float:{-4096.0, -4096.0, -4096.0}, Float:{4096.0, 4096.0, 4096.0});
		} 
	}

	ent = create_entity("info_map_parameters");
	DispatchKeyValue(ent, "buying", "1");
	DispatchSpawn(ent);

	g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules_P", OrpheuHookPost);
}

public plugin_init()
{
	register_plugin("[CTG] Game Rules", CTG_VERSION, "colg");

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");

	register_message(get_user_msgid("ShowMenu"), "OnMsgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "OnMsgVGUIMenu");

	//register_message(get_user_msgid("StatusIcon"), "OnMsgStatusIcon");

	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponTouch", 0, true);
	RegisterHam(Ham_Touch, "armoury_entity", "OnWeaponTouch", 0, true);
	RegisterHam(Ham_Touch, "weapon_shield", "OnWeaponTouch", 0, true);

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 0, true);
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_P", 1, true);

	RegisterHam(Ham_Killed, "player", "OnPlayerKilled_P", 1, true);

	OrpheuRegisterHookFromObject(g_pGameRules, "CheckWinConditions", "CGameRules", "OnCheckWinConditions");
	OrpheuRegisterHookFromObject(g_pGameRules, "FPlayerCanRespawn", "CGameRules", "OnFPlayerCanRespawn");
	OrpheuRegisterHookFromObject(g_pGameRules, "Think", "CGameRules", "OnGameRulesThink");

	unregister_forward(FM_Spawn, g_fwEntSpawn);

	new pcvar = create_cvar("ctg_min_players", "5");
	bind_pcvar_num(pcvar, CvarMinPlayers);

	pcvar = create_cvar("ctg_deathmatch", "2");
	bind_pcvar_num(pcvar, CvarDeathMatch);

	pcvar = create_cvar("ctg_respawn_on_suicide", "0");
	bind_pcvar_num(pcvar, CvarRespawnSuicide);

	pcvar = create_cvar("ctg_respawn_zombies", "1");
	bind_pcvar_num(pcvar, CvarRespawnZombies);

	pcvar = create_cvar("ctg_respawn_humans", "1");
	bind_pcvar_num(pcvar, CvarRespawnHumans);

	pcvar = create_cvar("ctg_respawn_delay_min", "3");
	bind_pcvar_float(pcvar, CvarRespawnDelayMin);

	pcvar = create_cvar("ctg_respawn_delay_max", "10");
	bind_pcvar_float(pcvar, CvarRespawnDelayMax);
}

public OnInstallGameRules_P()
{
	g_pGameRules = OrpheuGetReturn();
}

public OnEntSpawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;

	new classname[32];
	pev(ent, pev_classname, strcm(classname));

	for (new i = 0; i < sizeof g_RemoveEntities; i++)
	{
		if (equal(classname, g_RemoveEntities[i]))
		{
			remove_entity(ent);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public OnMsgShowMenu(iMsgid, iDest, id)
{
	static menucode[32];
	get_msg_arg_string(4, strcm(menucode));

	if (equal(menucode, SHOWMENU_JOINCLASS_T) || equal(menucode, SHOWMENU_JOINCLASS_CT))
	{
		RequestFrame("AutoJoinClass", id);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public OnMsgVGUIMenu(iMsgid, iDest, id)
{
	new menuid = get_msg_arg_int(1);
	if (menuid == VGUIMENU_JOINCLASS_T || menuid == VGUIMENU_JOINCLASS_CT)
	{
		RequestFrame("AutoJoinClass", id);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public AutoJoinClass(id)
{
	if (is_user_connected(id))
		engclient_cmd(id, "joinclass", "5");
}

public OnMsgStatusIcon(msgid, msgdest, id)
{
	if (is_user_alive(id))
	{
		new icon[8];
		get_msg_arg_string(2, strcm(icon));

		if (equal(icon, "buyzone") && get_msg_arg_int(1))
		{
			set_pdata_int(id, OFFSET_MAPZONES, get_pdata_int(id, OFFSET_MAPZONES) & ~MAPZONE_BUY);
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public Event_NewRound()
{
	set_gamerules_int("CHalfLifeMultiplay", "m_iUnBalancedRounds", -1); // force disable auto team balance

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || !(CS_TEAM_T <= cs_get_user_team(i) <= CS_TEAM_CT))
			continue;

		ctg_SetPlayerClassId(i, ctg_Human());
	}

}

public OrpheuHookReturn:OnCheckWinConditions()
{
	new numSpawnableTs, numSpawnableCt;
	InitializePlayerCounts(_, _, numSpawnableTs, numSpawnableCt);

	if (get_gamerules_int("CHalfLifeMultiplay", "m_iRoundWinStatus") != WINSTATUS_NONE)
		return OrpheuSupercede;

	// needed players
	if (!get_gamerules_int("CHalfLifeMultiplay", "m_bFirstConnected"))
	{
		// enough players
		if (numSpawnableTs + numSpawnableCt >= CvarMinPlayers)
		{
			// execute game commencing
			set_gamerules_int("CGameRules", "m_bFreezePeriod", 0);
			set_gamerules_int("CHalfLifeMultiplay", "m_bCompleteReset", 1);

			EndRoundMessage("#Game_Commencing", ROUND_GAME_COMMENCE);
			TerminateRound(3.0, WINSTATUS_DRAW);

			set_gamerules_int("CHalfLifeMultiplay", "m_bFirstConnected", 1);
		}

		return OrpheuSupercede;
	}
	else
	{
		// gamemode not yet started
		if (ctg_GetCurrentGameMode() == CTG_NULL)
		{
			// not enough players
			if (numSpawnableTs + numSpawnableCt < CvarMinPlayers)
			{
				set_gamerules_int("CHalfLifeMultiplay", "m_bFirstConnected", 0); // reset
				return OrpheuSupercede;
			}
		}
		else
		{
			// zombies win
			if (CountPlayers(true, ctg_Human(), true) < 1)
			{
				Broadcast("terwin");
				EndRoundMessage("#Terrorists_Win", ROUND_TERRORISTS_WIN);
				TerminateRound(5.0, WINSTATUS_TERRORISTS);
				return OrpheuSupercede;
			}
		}
	}

	return OrpheuSupercede;
}

public OrpheuHookReturn:OnFPlayerCanRespawn(pGameRules, id)
{
	if (!get_gamerules_int("CHalfLifeMultiplay", "m_bFirstConnected") || ctg_GetCurrentGameMode() == CTG_NULL)
	{
		OrpheuSetReturn(true);
		return OrpheuSupercede;
	}

	OrpheuSetReturn(false);
	return OrpheuSupercede;
}

public OnGameRulesThink(pGameRules)
{
	if (!get_gamerules_int("CGameRules", "m_bFreezePeriod") && GetRoundRemainingTime() <= 0 && get_gamerules_int("CHalfLifeMultiplay", "m_iRoundWinStatus") == WINSTATUS_NONE)
	{
		Broadcast("ctwin");
		EndRoundMessage("#Target_Saved", ROUND_TARGET_SAVED);
		TerminateRound(5.0, WINSTATUS_CTS);

		set_gamerules_float("CHalfLifeMultiplay", "m_fRoundCount", get_gametime() + 60.0);
	}
}

public OnPlayerKilled_P(id, attacker)
{
	if (CvarDeathMatch)
	{
		if (!CvarRespawnSuicide && (id == attacker || !is_user_connected(attacker)))
			return;
		
		new PlayerTeam:team = ctg_GetPlayerTeam(id);
		if ((team == Team_Zombie && !CvarRespawnZombies) || (team == Team_Human && !CvarRespawnHumans))
			return;
		
		new zombie_num = CountPlayers(true, ctg_Zombie(), true);
		new alive_num = CountPlayers(true);
		new Float:ratio = zombie_num / float(alive_num);
		new Float:delay = floatmax(CvarRespawnDelayMax * ratio, CvarRespawnDelayMin);

		client_print(id, print_center, "你將於 %.f 秒後重生...", delay);

		set_task(delay, "TaskRespawnPlayer", id+TASK_RESPAWN);
	}
}

public OnWeaponTouch(ent, toucher)
{
	if (is_user_alive(toucher) && ctg_IsZombie(toucher))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public OnPlayerSpawn(id)
{
	if (!pev_valid(id) || !(1 <= get_ent_data(id, "CBasePlayer", "m_iTeam") <= 2))
		return;

	static team; team = !team;
	set_ent_data(id, "CBasePlayer", "m_iTeam", team + 1); // fix spawn points
	set_ent_data(id, "CBasePlayer", "m_bNotKilled", true);

	new weaponbits = pev(id, pev_weapons);
	if (~weaponbits & WEAPON_SUIT_BIT)
		set_pev(id, pev_weapons, weaponbits | WEAPON_SUIT_BIT);
}

public OnPlayerSpawn_P(id)
{
	if (!is_user_alive(id) || !(1 <= get_ent_data(id, "CBasePlayer", "m_iTeam") <= 2))
		return;

	new class_id = ctg_GetPlayerClassId(id);
	if (class_id != CTG_NULL)
		ctg_ChangePlayerClass(id, class_id);

	if (!user_has_weapon(id, CSW_KNIFE))
		give_item(id, "weapon_knife");

	remove_task(id + TASK_RESPAWN);
}

public ctg_OnChangePlayerClass_P(id, class_id)
{
	new PlayerTeam:team = ctg_GetPlayerTeam(id);
	cs_set_user_team(id, CsTeams:team, CS_NORESET, true);

	if (team == Team_Zombie)
	{
		DropPlayerWeapons(id, 0);
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
	}
	else
	{
		new ent = get_ent_data_entity(id, "CBasePlayer", "m_pActiveItem");
		if (pev_valid(ent))
			ExecuteHamB(Ham_Item_Deploy, ent);
	}

	OnCheckWinConditions(); // fix
}

public ctg_OnGameModeEnd()
{
	for (new i = 1; i <= MaxClients; i++)
		remove_task(i+TASK_RESPAWN);
}

public client_disconnected(id)
{
	remove_task(id+TASK_RESPAWN);
}

public TaskRespawnPlayer(taskid)
{
	new id = taskid - TASK_RESPAWN;

	if (is_user_alive(id) || ctg_GetCurrentGameMode() == CTG_NULL)
		return;

	new CsTeams:team = cs_get_user_team(id)
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return;

	if (CvarDeathMatch == 2 || (CvarDeathMatch == 3 && random_num(0, 1)) 
		|| (CvarDeathMatch == 4 && CountPlayers(true, ctg_Zombie(), true) <= CountPlayers(true) / 2))
		ctg_SetPlayerClassId(id, ctg_Zombie());
	else
		ctg_SetPlayerClassId(id, ctg_Human());

	ExecuteHamB(Ham_CS_RoundRespawn, id);
}

stock InitializePlayerCounts(&numTs=0, &numCt=0, &numSpawnableTs=0, &numSpawnableCt=0)
{
	numTs = 0;
	numCt = 0;
	numSpawnableTs = 0;
	numSpawnableCt = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		switch (cs_get_user_team(i))
		{
			case CS_TEAM_T:
			{
				numTs++;

				if (GetPlayerCsMenu(i) != CS_Menu_ChooseAppearance)
					numSpawnableTs++;
			}
			case CS_TEAM_CT:
			{
				numCt++;

				if (GetPlayerCsMenu(i) != CS_Menu_ChooseAppearance)
					numSpawnableCt++;
			}
		}
	}

	set_gamerules_int("CHalfLifeMultiplay", "m_iNumTerrorist", numTs);
	set_gamerules_int("CHalfLifeMultiplay", "m_iNumSpawnableTerrorist", numSpawnableTs);
	set_gamerules_int("CHalfLifeMultiplay", "m_iNumCT", numCt);
	set_gamerules_int("CHalfLifeMultiplay", "m_iNumSpawnableCT", numSpawnableCt);
}

EndRoundMessage(const message[], type)
{
	static OrpheuFunction:func;
	func || (func = OrpheuGetFunction("EndRoundMessage"));

	OrpheuCallSuper(func, message, type);
}

TerminateRound(Float:delay, status)
{
	set_gamerules_int("CHalfLifeMultiplay", "m_iRoundWinStatus", status);
	set_gamerules_float("CHalfLifeMultiplay", "m_fTeamCount", get_gametime() + delay);
	set_gamerules_int("CHalfLifeMultiplay", "m_bRoundTerminating", 1);
}

Broadcast(const sentence[])
{
	new text[32];
	formatex(strcm(text), "%!MRAD_%s", sentence);

	static msgSendAudio;
	msgSendAudio || (msgSendAudio = get_user_msgid("SendAudio"));

	emessage_begin(MSG_BROADCAST, msgSendAudio)
	ewrite_byte(0);
	ewrite_string(text);
	ewrite_short(PITCH_NORM);
	emessage_end();
}

Float:GetRoundRemainingTime()
{
	return get_gamerules_float("CHalfLifeMultiplay", "m_fRoundCount") + float(get_gamerules_int("CHalfLifeMultiplay", "m_iRoundTimeSecs")) - get_gametime();
}