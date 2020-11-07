#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 
#include <zu_core>
#include <csgo_colors>
#include <clientprefs>

public Plugin:myinfo =  
{ 
    name = "[ZU] Transparency Team", 
    author = "CheaT", 
    description = "Transparency team for ZU", 
    version = "1.0.0", 
    url = "t.me/cheatdestroy" 
}

Handle:g_hImmCvar, Handle:g_hClientHideCookie, Handle:g_hClientDistCookie;

bool: g_bHide[MAXPLAYERS+1], g_bHidePlayers[MAXPLAYERS+1][MAXPLAYERS+1];
float g_fDistance[MAXPLAYERS+1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("GetHide", Native_GetHide);
	CreateNative("GetHideDistance", Native_GetHideDistance);
	CreateNative("SetHideDistance", Native_SetHideDistance);
}

public OnPluginStart() 
{ 
	CreateTimer(0.5, Checker, _, TIMER_REPEAT);
	
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	RegConsoleCmd("sm_hide", Command_Hide, "Transparency players");

	g_hImmCvar = FindConVar("sv_disable_immunity_alpha");
	if(g_hImmCvar == INVALID_HANDLE)
		return;
		
	SetConVarInt(g_hImmCvar, 1);
	
	HookConVarChange(g_hImmCvar, ConVarChanged);

	g_hClientHideCookie = RegClientCookie("transhide", "Transparency Hide Prefs", CookieAccess_Protected);
	g_hClientDistCookie = RegClientCookie("transdistance", "Transparency Distance Prefs", CookieAccess_Protected);

	LoadTranslations("zu_game_cs.phrases");
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(g_hImmCvar, 1);
}

public Action:Command_Hide(iClient, args)
{
	g_bHide[iClient] = !g_bHide[iClient];
	CGOPrintToChat(iClient, "%T %T", "Z_Prefix", iClient, g_bHide[iClient] ? "ZSettings_HideOff" : "ZSettings_HideOn", iClient);

	char sCookieValue[12];
	IntToString(_:g_bHide[iClient], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(iClient, g_hClientHideCookie, sCookieValue);
	
	return Plugin_Handled;
}

public void OnClientCookiesCached(int iClient)
{
	char sCookieValue[12];

	GetClientCookie(iClient, g_hClientHideCookie, sCookieValue, sizeof(sCookieValue));
	if(sCookieValue[0])
	{
		if(StringToInt(sCookieValue) > 0)
		{
			g_bHide[iClient] = true;
		}
		else
		{
			g_bHide[iClient] = false;
		}
	}
	else
	{
		g_bHide[iClient] = false;
	}

	sCookieValue = "";
	GetClientCookie(iClient, g_hClientDistCookie, sCookieValue, sizeof(sCookieValue));
	if(sCookieValue[0])
	{
		g_fDistance[iClient] = StringToFloat(sCookieValue);
	}
	else
	{
		g_fDistance[iClient] = 100.0;
	}
}

public OnClientPutInServer(int iClient) 
{ 
	SDKHook(iClient, SDKHook_SetTransmit, Hook_SetTransmit); 
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	ClearPlayerTransparency(iClient);
}

public ZU_OnClientInfected(int iClient, int attacker, bool:motherInfect)
{
	ClearPlayerTransparency(iClient);
}

public Action:Checker(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && g_bHide[i])
		{
			CheckTransparencies(i);
		}
	}

	return Plugin_Handled;
}

CheckTransparencies(int iClient) 
{
	decl Float:MedicOrigin[3],Float:TargetOrigin[3], Float:Distance;
	GetClientAbsOrigin(iClient, MedicOrigin);
	for (new i = 1; i <= MaxClients; i++)
	{
		if(i != iClient && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(ZU_IsZombie(iClient) && ZU_IsZombie(i) || ZU_IsHuman(iClient) && ZU_IsHuman(i))
			{
				GetClientAbsOrigin(i, TargetOrigin);
				Distance = GetVectorDistance(TargetOrigin, MedicOrigin);
				if(Distance <= g_fDistance[iClient])
				{
					g_bHidePlayers[iClient][i] = true;
				}
				else
				{
					g_bHidePlayers[iClient][i] = false;
				}
			}
			else
			{
				g_bHidePlayers[iClient][i] = false;
			}
		}
	}
}

public Action:Hook_SetTransmit(int iEnt, int iClient) 
{ 
    if (iClient != iEnt && g_bHide[iClient] && g_bHidePlayers[iClient][iEnt])
    {
        return Plugin_Handled;
    }
     
    return Plugin_Continue; 
}

stock ClearPlayerTransparency(int iClient)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		g_bHidePlayers[i][iClient] = false; 
	}
}

public Native_GetHide(Handle:pluginn, numParams)
{
	int iClient = GetNativeCell(1);
	return g_bHide[iClient];
}

public Native_GetHideDistance(Handle:pluginn, numParams)
{
	int iClient = GetNativeCell(1);
	return RoundFloat(g_fDistance[iClient]);
}

public Native_SetHideDistance(Handle:pluginn, numParams)
{
	int iClient = GetNativeCell(1);
	float fDistance = GetNativeCell(2);
	g_fDistance[iClient] = fDistance;

	char sCookieValue[12];
	FloatToString(g_fDistance[iClient], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(iClient, g_hClientDistCookie, sCookieValue);
}