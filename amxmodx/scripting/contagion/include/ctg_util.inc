#if defined _ctg_util_included
	#endinput
#endif

#define _ctg_util_included

#define @CGR 		"CGameRules"
#define @CHLMP 		"CHalfLifeMultiplay"
#define @CBPLR 		"CBasePlayer"
#define @CBPWPN		"CBasePlayerWeapon"
#define @CBPITEM	"CBasePlayerItem"
#define @CBMON		"CBaseMonster"

enum
{
	WINSTATUS_NONE = 0,
	WINSTATUS_CTS,
	WINSTATUS_TERRORISTS,
	WINSTATUS_DRAW
};

enum
{
	ROUND_NONE,
	ROUND_TARGET_BOMB,
	ROUND_VIP_ESCAPED,
	ROUND_VIP_ASSASSINATED,
	ROUND_TERRORISTS_ESCAPED,
	ROUND_CTS_PREVENT_ESCAPE,
	ROUND_ESCAPING_TERRORISTS_NEUTRALIZED,
	ROUND_BOMB_DEFUSED,
	ROUND_CTS_WIN,
	ROUND_TERRORISTS_WIN,
	ROUND_END_DRAW,
	ROUND_ALL_HOSTAGES_RESCUED,
	ROUND_TARGET_SAVED,
	ROUND_HOSTAGE_NOT_RESCUED,
	ROUND_TERRORISTS_NOT_ESCAPED,
	ROUND_VIP_NOT_ESCAPED,
	ROUND_GAME_COMMENCE,
	ROUND_GAME_RESTART,
	ROUND_GAME_OVER
};

stock PrecachePlayerModel(const model[])
{
	static path[128];
	formatex(path, charsmax(path), "models/player/%s/%s.mdl", model, model);
	if (file_exists(path))
		precache_model(path);

	// Support modelT.mdl files
	formatex(path, charsmax(path), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(path))
		precache_model(path);
}

stock ArrayGetRandomString(Array:which, output[], maxlen)
{
	return ArrayGetString(which, random(ArraySize(which)), output, maxlen);
}

stock DropPlayerWeapons(id, slot=0)
{
	for (new i = 1; i <= 5; i++)
	{
		if (slot && slot != i)
			continue;
		
		new weapon = get_ent_data_entity(id, "CBasePlayer", "m_rgpPlayerItems", i);
		
		while (pev_valid(weapon))
		{
			if (ExecuteHamB(Ham_CS_Item_CanDrop, weapon))
			{
				static class[32];
				pev(weapon, pev_classname, class, charsmax(class));
				
				engclient_cmd(id, "drop", class);
			}
			
			// Find next weapon
			weapon = get_ent_data_entity(weapon, "CBasePlayerItem", "m_pNext");
		}
	}
}

stock TerminateRound(Float:delay, status, event, const message[], const audio[]="", bool:score=true)
{
	if (audio[0])
	{
		static msgSendAudio;
		msgSendAudio || (msgSendAudio = get_user_msgid("SendAudio"));
		
		static code[STRLEN_SHORT];
		formatex(code, charsmax(code), "%!MRAD_%s", audio);

		emessage_begin(MSG_BROADCAST, msgSendAudio);
		ewrite_byte(0);
		ewrite_string(code);
		ewrite_short(100);
		emessage_end();
	}

	if (score && status != WINSTATUS_DRAW)
	{
		new score_tr = get_gamerules_int(@CHLMP, "m_iNumTerroristWins");
		new score_ct = get_gamerules_int(@CHLMP, "m_iNumCTWins");

		if (status == WINSTATUS_CTS)
			set_gamerules_int(@CHLMP, "m_iNumCTWins", ++score_ct);
		else
			set_gamerules_int(@CHLMP, "m_iNumTerroristWins", ++score_tr);
		
		static msgTeamScore;
		msgTeamScore || (msgTeamScore = get_user_msgid("TeamScore"));

		emessage_begin(MSG_BROADCAST, msgTeamScore);
		ewrite_string(status == WINSTATUS_CTS ? "CT" : "TERRORIST");
		ewrite_short(status == WINSTATUS_CTS ? score_ct : score_tr);
		emessage_end();
	}

	static OrpheuFunction:funcEndRoundMsg;
	funcEndRoundMsg || (funcEndRoundMsg = OrpheuGetFunction("EndRoundMessage"));
	OrpheuCall(funcEndRoundMsg, message, event);

	set_gamerules_int(@CHLMP, "m_iRoundWinStatus", status);
	set_gamerules_int(@CHLMP, "m_bRoundTerminating", true);
	set_gamerules_float(@CHLMP, "m_fTeamCount", get_gametime() + delay);
}

stock IsPlayerSpawnable(id)
{
	return (CS_TEAM_T <= cs_get_user_team(id) <= CS_TEAM_CT) && get_ent_data(id, @CBPLR, "m_iMenu") != _:CS_Menu_ChooseAppearance;
}