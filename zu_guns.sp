#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <csgo_colors>
#include <zu_core>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "[ZU] Weapon Menu",
	author = "CheaT",
	version = "1.0.1",
	description = "Weapon menu for zombie ultimate.",
	url = "https://t.me/cheatdestroy"
};

enum Category {
	Category_NONE = -1,
	Category_Pistol = 0,
	Category_Shotgun,
	Category_Submachine,
	Category_Rifle,
	Category_Machinegun,
	Category_Grenade
};

enum Extra {
	Extra_Rebuy = 6,
	Extra_SaveWeapon
};

static const char g_sCategoryName[][64] = {
	"Пистолеты",
	"Дробовики",
	"Пистолеты-пулемёты",
	"Винтовки",
	"Пулемёты",
	"Гранаты\n ",
	"Последнее вооружение",
	"Сохранить вооружение"
};

//Pistols
static const char g_sPistolName[][32] = {
	"USP-S/P2000",
	"Glock-18",
	"Dual Berettas",
	"P250",
	"Five-Seven",
	"CZ75-Auto",
	"Desert Eagle"
};

static const char g_sPistolClassname[sizeof(g_sPistolName)][32] = {
	"weapon_hkp2000",
	"weapon_glock",
	"weapon_elite",
	"weapon_p250",
	"weapon_fiveseven",
	"weapon_cz75a",
	"weapon_deagle"
};
/////////////////////////////////////////////////////////////////////////

//Shotguns
static const char g_sShotgunName[][32] = {
	"Nova",
	"XM1014",
	"MAG-7",
	"Sawed-Off"
};

static const char g_sShotgunClassname[sizeof(g_sShotgunName)][32] = {
	"weapon_nova",
	"weapon_xm1014",
	"weapon_mag7",
	"weapon_sawedoff"
};
//////////////////////////////////////////////////////////////////////////

//Submachine
static const char g_sSubmachineName[][32] = {
	"MAC-10",
	"MP-9",
	"MP7",
	"UMP-45",
	"P90",
	"PP-Bizon",
	"MP5-SD"
};

static const char g_sSubmachineClassname[sizeof(g_sSubmachineName)][32] = {
	"weapon_mac10",
	"weapon_mp9",
	"weapon_mp7",
	"weapon_ump45",
	"weapon_p90",
	"weapon_bizon",
	"weapon_mp5sd"
};
//////////////////////////////////////////////////////////////////////////

//Automatic
static const char g_sRifleName[][32] = {
	"Galil AR",
	"FAMAS",
	"AK-47",
	"M4A1",
	"M4A1-S",
	"SG 553",
	"AUG",
	"G3SG1",
	"SCAR-20"
};

static const char g_sRifleClassname[sizeof(g_sRifleName)][32] = {
	"weapon_galilar",
	"weapon_famas",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_m4a1_silencer",
	"weapon_sg556",
	"weapon_aug",
	"weapon_g3sg1",
	"weapon_scar20"
};
//////////////////////////////////////////////////////////////////////////

//Machinegun
static const char g_sMachinegunName[][32] = {
	"M249",
	"Negev"
};

static const char g_sMachinegunClassname[sizeof(g_sMachinegunName)][32] = {
	"weapon_m249",
	"weapon_negev"
};

//////////////////////////////////////////////////////////////////////////

//Grenade
static const char g_sGrenadeName[][32] = {
	"Огненная",
	"Ядовитая",
	"Замораживающая"
};

static const char g_sGrenadeDesc[sizeof(g_sGrenadeName)][64] = {
	"[Урон: ? | Длит: 7 сек.]",
	"[Урон: 300/с | Радиус: 150 | Длит: 7 сек.]",
	"[Радиус: 150 | Длит: 3 сек.]"
};

static const char g_sGrenadeClassname[sizeof(g_sGrenadeName)][32] = {
	"weapon_hegrenade",
	"weapon_smokegrenade",
	"weapon_flashbang"
};
////////////////////////////////////////////////////////////////////////////

Handle trie_armas;

new Handle:hCvar_Debug, iCvar_Debug;

new Category:g_iPlayerWeaponMenu[MAXPLAYERS+1];
new bool:g_bPlayerHasSecondary[MAXPLAYERS+1],bool:g_bPlayerHasPrimary[MAXPLAYERS+1], bool:g_bPlayerWeaponSave[MAXPLAYERS+1], bool:g_bPlayerHasGrenade[MAXPLAYERS+1];
new String:g_iPlayerSecondaryPre[MAXPLAYERS+1][32], String:g_iPlayerPrimaryPre[MAXPLAYERS+1][32], String:g_iPlayerGrenadePre[MAXPLAYERS+1][32];

public OnPluginStart()
{
	hCvar_Debug = CreateConVar("sm_guns_debug", "0", "Debug mode for weapons menu.", _, true, 0.0, true, 1.0);
	iCvar_Debug = GetConVarInt(hCvar_Debug);
	HookConVarChange(hCvar_Debug, Cvars_OnCvarChanged);

	RegConsoleCmd("sm_guns", Command_Guns, "Open Weapon Menu");
	RegConsoleCmd("sm_weapons", Command_Guns, "Open Weapon Menu");
	RegConsoleCmd("sm_buymenu", Command_Guns, "Open Weapon Menu");

	trie_armas = CreateTrie();

	//HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Post);

	LoadTranslations("zu_game_cs.phrases");

	for(int i = 1; i <= MaxClients; i++)
	{
	    if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnMapStart()
{
	RemoveBuyZones();
}

public OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponEquipPost, OnItemPickup);
}

public OnClientDisconnect_Post(int iClient)
{
	g_iPlayerPrimaryPre[iClient] = "";
	g_iPlayerSecondaryPre[iClient] = "";
	g_iPlayerGrenadePre[iClient] = "";
	g_bPlayerHasSecondary[iClient] = false;
	g_bPlayerHasPrimary[iClient] = false;
	g_bPlayerWeaponSave[iClient] = false;
	g_bPlayerHasGrenade[iClient] = false;
	g_iPlayerWeaponMenu[iClient] = Category_NONE;
}

public Cvars_OnCvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == hCvar_Debug)
	{
		iCvar_Debug = StringToInt(newValue);
	}
}

/*public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && ZU_IsHuman(i))
		{
			for(int iSlot = 0; iSlot < 5; iSlot++)
			{
				ClearSlotWeapon(i, iSlot);
			}

			g_iPlayerWeaponMenu[i] = Category_NONE;
			g_bPlayerHasSecondary[i] = false;
			g_bPlayerHasPrimary[i] = false;
			g_bPlayerHasGrenade[i] = false;

			//GivePlayerItem(i, "weapon_knife");

			CreateTimer(0.5, Timer_Weapons, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}*/

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!iClient || !IsClientInGame(iClient) || IsPlayerAlive(iClient))
	{
		return;
	}

	g_iPlayerWeaponMenu[iClient] = Category_NONE;
	g_bPlayerHasSecondary[iClient] = false;
	g_bPlayerHasPrimary[iClient] = false;
	g_bPlayerHasGrenade[iClient] = false;
}

public Action:OnPlayerSpawn(Handle event, const String:name[], bool dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if(iClient && IsClientInGame(iClient))
	{
		/*for(int iSlot = 0; iSlot < 5; iSlot++)
		{
			ClearSlotWeapon(iClient, iSlot);
		}*/

		g_iPlayerWeaponMenu[iClient] = Category_NONE;
		g_bPlayerHasSecondary[iClient] = false;
		g_bPlayerHasPrimary[iClient] = false;
		g_bPlayerHasGrenade[iClient] = false;

		//GivePlayerItem(iClient, "weapon_knife");

		if(IsPlayerAlive(iClient) && ZU_IsHuman(iClient))
		{
			CreateTimer(0.7, Timer_Weapons, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Continue;
}

public Action:Timer_Weapons(Handle hTiemr, any UserId)
{
	int iClient = GetClientOfUserId(UserId);
	if(iClient && IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		if(!g_bPlayerWeaponSave[iClient])
		{
			Command_Guns(iClient, 0);
		}
		else
		{
			GiveLastWeapon(iClient);
		}
	}

	return Plugin_Stop;
}

public ZU_OnMotherZombiesSpawned(const clients[], numClients)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && ZU_IsHuman(i) && g_bPlayerHasGrenade[i])
		{
			new weapon = GetPlayerWeaponSlot(i, CS_SLOT_GRENADE);
			if(weapon == -1)
			{
				GivePlayerItem(i, g_iPlayerGrenadePre[i]);
			}
		}
	}
}

public void OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	
	if(iClient && IsPlayerAlive(iClient) && ZU_IsHuman(iClient))
	{
		SetInfiniteAmmo(iClient);
	}
}

public Action OnItemPickup(int iClient, int weapon)
{
	if(weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY))
	{
		int warray;
		char classname[4];

		Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
	
		if(!GetTrieValue(trie_armas, classname, warray))
		{
			warray = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		
			SetTrieValue(trie_armas, classname, warray);
		}
	}
}

public Action:Command_Guns(int iClient, args)
{
	if (!iClient || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
	{
		return Plugin_Handled;
	}

	if(ZU_IsZombie(iClient))
	{
		return Plugin_Handled;
	}

	if(g_bPlayerWeaponSave[iClient])
	{
		g_bPlayerWeaponSave[iClient] = false;
		CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, "ZWeapons_NotSave", iClient);
	}
	
	GunsMenu(iClient);
	
	return Plugin_Handled;
}

GunsMenu(int iClient)
{
	new Handle:hMenu = CreateMenu(GunsMenu_Handler);
	SetMenuTitle(hMenu, "%T\n", "ZWeapons_MenuWeaponTitle", iClient);

	decl String:display[32];
	for(int i = 0; i < sizeof(g_sCategoryName); i++)
	{
		IntToString(i, display, sizeof(display));
		int condition = (i == _:Category_Pistol && GetUserWeapon(iClient, CS_SLOT_SECONDARY)
			|| i >= _:Category_Shotgun && i <= _:Category_Machinegun && GetUserWeapon(iClient, CS_SLOT_PRIMARY)
			|| i == _:Category_Grenade && GetUserWeapon(iClient, CS_SLOT_GRENADE)
			|| i == _:Extra_Rebuy && GetUserAllWeapon(iClient)
			|| i == _:Extra_SaveWeapon && !IsPlayerSelectWeapon(iClient));
		AddMenuItem(hMenu, display, g_sCategoryName[i], condition ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}


public GunsMenu_Handler(Handle:menu, MenuAction:action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		if(ZU_IsZombie(iClient))
		{
			return 0;
		}

		switch(iItem)
		{
			case Category_Pistol,Category_Shotgun,Category_Submachine,Category_Rifle,Category_Machinegun,Category_Grenade:
			{
				g_iPlayerWeaponMenu[iClient] = Category:iItem;
				WeaponMenuManager(iClient);
			}
			case Extra_Rebuy:
			{
				if(IsPlayerSelectWeapon(iClient))
				{
					GiveLastWeapon(iClient);
				}
				else
				{
					CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, "ZWeapons_NotFound", iClient);
					Command_Guns(iClient, 0);
				}
			}
			case Extra_SaveWeapon:
			{
				if(IsPlayerSelectWeapon(iClient))
				{
					GiveLastWeapon(iClient);
					g_bPlayerWeaponSave[iClient] = true;
					CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, "ZWeapons_Saved", iClient);
				}
				else
				{
					CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, "ZWeapons_NotSelected", iClient);
				}
			}
		}
	}

	return 0;
}

WeaponMenuManager(int iClient)
{
	new Handle:hMenu = CreateMenu(WeaponMenuManager_Handler);
	int size;
	if(g_iPlayerWeaponMenu[iClient] == Category_Pistol)
	{
		SetMenuTitle(hMenu, "%T\n", "ZWeapons_ChoosePistol", iClient);

		size = sizeof(g_sPistolName);
		for(int i = 0; i < size; i++)
		{
			AddMenuItem(hMenu, g_sPistolClassname[i], g_sPistolName[i]);
		}

		if(size < 9)
		{
			SetMenuPagination(hMenu, MENU_NO_PAGINATION);
		}
	}
	else if(g_iPlayerWeaponMenu[iClient] == Category_Shotgun)
	{
		SetMenuTitle(hMenu, "%T\n", "ZWeapons_ChooseShotgun", iClient);

		size = sizeof(g_sShotgunName);
		for(int i = 0; i < size; i++)
		{
			AddMenuItem(hMenu, g_sShotgunClassname[i], g_sShotgunName[i]);
		}

		if(size < 9)
		{
			SetMenuPagination(hMenu, MENU_NO_PAGINATION);
		}
	}
	else if(g_iPlayerWeaponMenu[iClient] == Category_Submachine)
	{
		SetMenuTitle(hMenu, "%T\n", "ZWeapons_ChooseSubmachine", iClient);

		size = sizeof(g_sSubmachineName);
		for(int i = 0; i < size; i++)
		{
			AddMenuItem(hMenu, g_sSubmachineClassname[i], g_sSubmachineName[i]);
		}

		if(size < 9)
		{
			SetMenuPagination(hMenu, MENU_NO_PAGINATION);
		}
	}
	else if(g_iPlayerWeaponMenu[iClient] == Category_Rifle)
	{
		SetMenuTitle(hMenu, "%T\n", "ZWeapons_ChooseRifle", iClient);

		size = sizeof(g_sRifleName);
		for(int i = 0; i < size; i++)
		{
			AddMenuItem(hMenu, g_sRifleClassname[i], g_sRifleName[i]);
		}

		if(size < 9)
		{
			SetMenuPagination(hMenu, MENU_NO_PAGINATION);
		}
	}
	else if(g_iPlayerWeaponMenu[iClient] == Category_Machinegun)
	{
		SetMenuTitle(hMenu, "%T\n", "ZWeapons_ChooseMachinegun", iClient);

		size = sizeof(g_sMachinegunName);
		for(int i = 0; i < size; i++)
		{
			AddMenuItem(hMenu, g_sMachinegunClassname[i], g_sMachinegunName[i]);
		}

		if(size < 9)
		{
			SetMenuPagination(hMenu, MENU_NO_PAGINATION);
		}
	}
	else if(g_iPlayerWeaponMenu[iClient] == Category_Grenade)
	{
		SetMenuTitle(hMenu, "%T\n", "ZWeapons_ChooseGrenade", iClient);

		decl String:szBuffer[256];
		size = sizeof(g_sGrenadeName);
		for(int i = 0; i < size; i++)
		{
			FormatEx(szBuffer, sizeof(szBuffer), "%s\n%s", g_sGrenadeName[i], g_sGrenadeDesc[i]);
			AddMenuItem(hMenu, g_sGrenadeClassname[i], szBuffer);
		}

		if(size < 9)
		{
			SetMenuPagination(hMenu, MENU_NO_PAGINATION);
		}
	}

	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public WeaponMenuManager_Handler(Handle:menu, MenuAction:action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		if(ZU_IsZombie(iClient))
		{
			return;
		}

		decl String:sInfo[32];
		GetMenuItem(menu, iItem, sInfo, sizeof(sInfo));
		switch(g_iPlayerWeaponMenu[iClient])
		{
			case Category_Pistol:
			{
				if(!GetUserWeapon(iClient, CS_SLOT_SECONDARY))
				{
					GivePlayerSecondaryWeapon(iClient, sInfo);
				}
				else
				{
					CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, "ZWeapons_SecondarySelected", iClient);
				}
			}
			case Category_Shotgun,Category_Submachine,Category_Rifle,Category_Machinegun:
			{
				if(!GetUserWeapon(iClient, CS_SLOT_PRIMARY))
				{
					GivePlayerPrimaryWeapon(iClient, sInfo);
				}
				else
				{
					CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, "ZWeapons_PrimarySelected", iClient);
				}
			}
			case Category_Grenade:
			{
				if(!GetUserWeapon(iClient, CS_SLOT_GRENADE))
				{
					GivePlayerGrenade(iClient, sInfo);
				}
				else
				{
					CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, "ZWeapons_GrenadeSelected", iClient);
				}
			}
		}
		GunsMenu(iClient);
	}
}

GivePlayerSecondaryWeapon(int iClient, char secondary[32])
{
	ClearSlotWeapon(iClient, CS_SLOT_SECONDARY);

	new iSecondary = GivePlayerItem(iClient, secondary);
	if(!iCvar_Debug)
	{
		g_bPlayerHasSecondary[iClient] = true;
		g_iPlayerSecondaryPre[iClient] = secondary;
	}

	SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iSecondary);
}

GivePlayerPrimaryWeapon(int iClient, char primary[32])
{
	ClearSlotWeapon(iClient, CS_SLOT_PRIMARY);

	new iPrimary = GivePlayerItem(iClient, primary);
	if(!iCvar_Debug)
	{
		g_bPlayerHasPrimary[iClient] = true;
		g_iPlayerPrimaryPre[iClient] = primary;
	}

	SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iPrimary);
}

GivePlayerGrenade(int iClient, char grenade[32])
{
	ClearSlotWeapon(iClient, CS_SLOT_GRENADE);

	if(ZU_MotherZombiesSpawned() && !g_bPlayerHasGrenade[iClient])
	{
		new iGrenade = GivePlayerItem(iClient, grenade);

		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iGrenade);
	}
	if(!iCvar_Debug)
	{
		g_bPlayerHasGrenade[iClient] = true;
		g_iPlayerGrenadePre[iClient] = grenade;
	}
}

GiveLastWeapon(int iClient)
{
	if(g_iPlayerSecondaryPre[iClient][0] && !GetUserWeapon(iClient, CS_SLOT_SECONDARY))
	{
		GivePlayerSecondaryWeapon(iClient, g_iPlayerSecondaryPre[iClient]);
	}
	if(g_iPlayerPrimaryPre[iClient][0] && !GetUserWeapon(iClient, CS_SLOT_PRIMARY))
	{
		GivePlayerPrimaryWeapon(iClient, g_iPlayerPrimaryPre[iClient]);
	}
	if(g_iPlayerGrenadePre[iClient][0] && !GetUserWeapon(iClient, CS_SLOT_GRENADE))
	{
		GivePlayerGrenade(iClient, g_iPlayerGrenadePre[iClient]);
	}
}

SetInfiniteAmmo(int iClient)
{
	int weapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
	if(weapon > 0 && (weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY)))
	{
		int warray;
		char classname[4];

		Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			
		if(GetTrieValue(trie_armas, classname, warray))
		{
			if(GetReserveAmmo(weapon) != warray)
			{
				SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", warray);
			}
		}
	}
}

stock GetReserveAmmo(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}

stock RemoveBuyZones()
{
	new MaxEntities = GetMaxEntities();
	decl String:szClassname[16];

	for(new entity_index = MaxClients+1; entity_index < MaxEntities; ++entity_index)
	{
		if(IsValidEdict(entity_index))
		{
			GetEdictClassname(entity_index, szClassname, sizeof(szClassname));
			if(StrEqual(szClassname, "func_buyzone"))
			{
				AcceptEntityInput(entity_index, "Kill");
			}
		}
	}
}

stock int IsPlayerSelectWeapon(int iClient)
{
	return (g_iPlayerSecondaryPre[iClient][0] && g_iPlayerPrimaryPre[iClient][0] && g_iPlayerGrenadePre[iClient][0]) ? 1 : 0;
}

stock bool GetUserWeapon(int iClient, int iSlot)
{
	if(!iClient || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
	{
		return false;
	}

	if(iCvar_Debug)
	{
		return false;
	}

	new Slot = GetPlayerWeaponSlot(iClient, iSlot);

	if(ZU_MotherZombiesSpawned())
	{
		if(Slot != -1)
		{
			return true;
		}

		return CheckHasWeapon(iClient, iSlot);
	}
	else
	{
		return CheckHasWeapon(iClient, iSlot);
	}
}

stock bool GetUserAllWeapon(int iClient)
{
	if(GetUserWeapon(iClient, CS_SLOT_SECONDARY)
		&& GetUserWeapon(iClient, CS_SLOT_PRIMARY)
		&& GetUserWeapon(iClient, CS_SLOT_GRENADE))
	{
		return true;
	}

	return false;
}

stock bool CheckHasWeapon(int iClient, int iSlot)
{
	if(iSlot == CS_SLOT_SECONDARY && g_bPlayerHasSecondary[iClient]
		|| iSlot == CS_SLOT_PRIMARY && g_bPlayerHasPrimary[iClient]
		|| iSlot == CS_SLOT_GRENADE && g_bPlayerHasGrenade[iClient])
	{
		return true;
	}

	return false;
}

stock bool ClearSlotWeapon(int iClient, int Slot)
{
	if(!iClient || !IsClientInGame(iClient) || !IsPlayerAlive(iClient) || !ZU_IsHuman(iClient))
	{
		return false;
	}

	new iSlot = GetPlayerWeaponSlot(iClient, Slot);
	if(iSlot != -1)
	{
		RemovePlayerItem(iClient, iSlot);
		AcceptEntityInput(iSlot, "kill");
	}

	return true;
}