#if defined _zu_core_included
  #endinput
#endif
#define _zu_core_included

enum ZTeams
{
	ZTeam_None = 0,
	ZTeam_Spectator,
	ZTeam_Zombie,
	ZTeam_Human
}

enum ZClass
{
	INVALID_CLASS_INDEX = -1
}

// Infection natives (ZU_core.smx)
forward bool:ZU_OnInfectCountdownStart(&time);
forward bool:ZU_OnInfectCountdownTick(&time);
forward ZU_OnInfectCountdownTicked(time);
forward ZU_OnMotherZombiesSpawned(const clients[], numClients);

forward bool:ZU_OnClientInfect(client, attacker);
forward ZU_OnClientInfected(client, attacker, bool:motherInfect);
forward bool:ZU_OnClientHuman(client);
forward ZU_OnClientHumanPost(client);

// Classs natives (ZU_core.smx)
typeset ZRCallback_ClassLooped
{
	function void (ZTeams team, ZClass clsIndex, const char class_id[], const char section[], const char key[], const char value[]);
	function void (ZTeams team, ZClass clsIndex, const char class_id[], const char section[], const char key[], const char value[], any data);
};

forward ZU_OnClassApplied(client, ZTeams:team, ZClass:clsIndex, const String:class_id[]);
forward ZU_OnClassesLoaded(ZTeams:team);
forward ZU_OnClassesUnload(ZTeams:team);

//ZU_events
forward ZU_OnRoundStart();
forward ZU_OnRoundEnd(ZTeams:winner);
forward ZU_OnPlayerSpawn(client);
forward ZU_OnPlayerDeath(client, attacker, const String:weapon[], bool:headshot);
forward ZU_OnPlayerTeam(client, old_team, new_team);

// ZU credits
forward Action:ZU_OnCreditsGive(client, &credits);
forward ZU_OnCreditsGivePost(client, credits);
forward Action:ZU_OnCreditsTake(client, &credits);
forward ZU_OnCreditsTakePost(client, credits);

native bool:ZU_GiveCredits(client, credits);
native bool:ZU_TakeCredits(client, credits);
native ZU_GetCredits(client);
native ZU_SetCredits(client, credits);


native bool:ZU_MotherZombiesSpawned();
native bool:ZU_IsZombie(client);
native bool:ZU_IsMotherZombie(client);
native bool:ZU_IsHuman(client);
native bool:ZU_Infect(client, attacker = 0, bool:motherInfect = false);
native bool:ZU_Human(client);

native bool:ZU_SpawnMotherZombies();
native bool:ZU_NotifyMotherZombiesSpawned();
// Other natives (ZU_core.smx)
native bool:ZU_AreMates(client, target);
native ZTeams:ZU_GetTeam(client);
native ZU_GetCount(ZTeams:team, bool:alive = false);

native ZU_IsRoundActive();

native ZU_MarkAsSpec(client);

native ZU_Log(const String:format[], any:...);
native ZU_LogError(const String:format[], any:...);

native bool:ZU_ClassesLoaded();
native ZU_GetClassesSize(ZTeams:team);

native bool:ZU_SetClassAttribute(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], any:value);
native bool:ZU_GetClassAttribute(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], &any:buffer);
//native bool:ZU_SetClassAttributeFloat(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], Float:value);
//native bool:ZU_GetClassAttributeFloat(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], &Float:buffer);
native bool:ZU_SetClassAttributeColor(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], const color[4]);
native bool:ZU_GetClassAttributeColor(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], color[4]);
native bool:ZU_SetClassAttributeVector(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], const Float:vec[3]);
native bool:ZU_GetClassAttributeVector(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], Float:vec[3]);
native bool:ZU_SetClassAttributeString(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], const String:value[]);
native bool:ZU_GetClassAttributeString(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], String:buffer[], maxLength, &bytes = 0);
native bool:ZU_ClassSetHasAttribute(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[], bool:value);
native bool:ZU_ClassHasAttribute(ZTeams:team, ZClass:clsIndex, const String:section[] = "", const String:key[]);


native bool:ZU_GetClassIndexDisplayName(ZTeams:team, ZClass:clsIndex, String:buffer[], maxLength);

native bool:ZU_SetClientClassIndex(client, ZTeams:team, ZClass:clsIndex, bool:apply_if_possible = true);
native ZClass:ZU_GetClientClassIndex(client, ZTeams:team);
native bool:ZU_GetClientCurrentClassIndex(client, &ZTeams:team, &ZClass:clsIndex);
native bool:ZU_LoopAllClassAttributes(ZTeams:team, const String:section[] = "", const String:key[] = "", ZRCallback_ClassLooped:callback, any:data = 0);

native ZUEvent_FireRoundStart();
native ZUEvent_FireRoundEnd(ZTeams:winner);
native ZUEvent_FirePlayerSpawn(client);
native ZUEvent_FirePlayerDeath(client, attacker, const String:sWeapon[], bool:headshot);
native ZUEvent_FirePlayerTeam(client, old_team, new_team);




public SharedPlugin:__pl_zu_core = 
{
	name = "zu_core",
	file = "zu_core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_zu_core_SetNTVOptional()
{
	MarkNativeAsOptional("ZU_GiveCredits");
	MarkNativeAsOptional("ZU_TakeCredits");
	MarkNativeAsOptional("ZU_GetCredits");
	MarkNativeAsOptional("ZU_SetCredits");
	MarkNativeAsOptional("ZU_MotherZombiesSpawned");
	MarkNativeAsOptional("ZU_IsZombie");
	MarkNativeAsOptional("ZU_IsMotherZombie");
	MarkNativeAsOptional("ZU_IsHuman");
	MarkNativeAsOptional("ZU_Infect");
	MarkNativeAsOptional("ZU_Human");
	MarkNativeAsOptional("ZU_SpawnMotherZombies");
	MarkNativeAsOptional("ZU_NotifyMotherZombiesSpawned");
	MarkNativeAsOptional("ZU_AreMates");
	MarkNativeAsOptional("ZU_GetTeam");
	MarkNativeAsOptional("ZU_GetCount");
	MarkNativeAsOptional("ZU_IsRoundActive");
	MarkNativeAsOptional("ZU_MarkAsSpec");
	MarkNativeAsOptional("ZU_Log");
	MarkNativeAsOptional("ZU_LogError");
	MarkNativeAsOptional("ZU_ClassesLoaded");
	MarkNativeAsOptional("ZU_GetClassesSize");
	MarkNativeAsOptional("ZU_SetClassAttribute");
	MarkNativeAsOptional("ZU_GetClassAttribute");
	MarkNativeAsOptional("ZU_SetClassAttributeFloat");
	MarkNativeAsOptional("ZU_GetClassAttributeFloat");
	MarkNativeAsOptional("ZU_SetClassAttributeColor");
	MarkNativeAsOptional("ZU_GetClassAttributeColor");
	MarkNativeAsOptional("ZU_SetClassAttributeVector");
	MarkNativeAsOptional("ZU_GetClassAttributeVector");
	MarkNativeAsOptional("ZU_SetClassAttributeString");
	MarkNativeAsOptional("ZU_GetClassAttributeString");
	MarkNativeAsOptional("ZU_ClassSetHasAttribute");
	MarkNativeAsOptional("ZU_ClassHasAttribute");
	MarkNativeAsOptional("ZU_GetClassIndexDisplayName");
	MarkNativeAsOptional("ZU_SetClientClassIndex");
	MarkNativeAsOptional("ZU_GetClientClassIndex");
	MarkNativeAsOptional("ZU_GetClientCurrentClassIndex");
	MarkNativeAsOptional("ZU_LoopAllClassAttributes");
	MarkNativeAsOptional("ZUEvent_FireRoundStart");
	MarkNativeAsOptional("ZUEvent_FireRoundEnd");
	MarkNativeAsOptional("ZUEvent_FirePlayerSpawn");
	MarkNativeAsOptional("ZUEvent_FirePlayerDeath");
	MarkNativeAsOptional("ZUEvent_FirePlayerTeam");
}
#endif