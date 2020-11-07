#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <zu_core>

public Plugin myinfo =  {
	name = "[ZU] NoBlock",
	author = "CheaT",
	description = "Team noblock for ZU",
	version = "1.0.0",
	url = "https://t.me/cheatdestroy"
};

bool bLate;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
}

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnRoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for(new i = 1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_StartTouch, OnStartTouch);
	SDKHook(iClient, SDKHook_Touch, OnStartTouch);
}

public void OnStartTouch(int iClient, int iEnt)
{
	if(0 < iEnt <= MaxClients)
	{
		if(ZU_IsZombie(iClient) && ZU_IsZombie(iEnt) || ZU_IsHuman(iClient) && ZU_IsHuman(iEnt))
		{
			SetEntProp(iClient, Prop_Data, "m_CollisionGroup", 2);
		}
		else
		{
			SetEntProp(iClient, Prop_Data, "m_CollisionGroup", 5);
		}
	}
	else
	{
		SetEntProp(iClient, Prop_Data, "m_CollisionGroup", 5);
	}
}