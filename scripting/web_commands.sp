/**
 * Web Commands
 * 
 * Provides a few common commands related to opening an MOTD webview panel.
 */
#pragma semicolon 1
#include <sourcemod>

#include <advanced_motd>

#pragma newdecls required

#include <stocksoup/maps>

#define PLUGIN_VERSION "0.0.1"
public Plugin myinfo = {
	name = "Web Commands",
	author = "nosoop",
	description = "Provides some basic webview panel commands.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-WebCommands"
}

public void OnPluginStart() {
	RegConsoleCmd("sm_workshop", OpenWorkshopPage,
			"Opens the current map's workshop page in a large MOTD window.");
	RegConsoleCmd("sm_group", OpenServerGroupPage,
			"Opens the server's group page in a large MOTD window.");
	RegConsoleCmd("sm_profile", OpenProfilePage,
			"Opens a player's profile page in a large MOTD window.");
}

public Action OpenWorkshopPage(int client, int argc) {
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	int id = GetMapWorkshopID(currentMap);
	
	if (id) {
		char url[256];
		Format(url, sizeof(url), "https://steamcommunity.com/sharedfiles/filedetails/?id=%d",
				id);
		
		AdvMOTD_ShowMOTDPanel(client, "Workshop Map Window", url, MOTDPANEL_TYPE_URL,
				true, true, true, OnPageOpenFailure);
	} else {
		char mapDisplay[PLATFORM_MAX_PATH];
		GetMapDisplayName(currentMap, mapDisplay, sizeof(mapDisplay));
		ReplyToCommand(client, "%s doesn't appear to be a Workshop map.", mapDisplay);
	}
	return Plugin_Handled;
}

public Action OpenServerGroupPage(int client, int argc) {
	ConVar steamGroup = FindConVar("sv_steamgroup");
	int gid = steamGroup? steamGroup.IntValue : 0;
	
	if (gid) {
		char url[PLATFORM_MAX_PATH];
		Format(url, sizeof(url), "https://steamcommunity.com/gid/%d", gid);
		AdvMOTD_ShowMOTDPanel(client, "Steam Group Window", url, MOTDPANEL_TYPE_URL, true, true,
				true, OnPageOpenFailure);
	}
	
	return Plugin_Handled;
}

public Action OpenProfilePage(int client, int argc) {
	if (argc == 0) {
		ReplyToCommand(client, "Usage: sm_profile <target>");
		return Plugin_Handled;
	}
	
	char targetArg[MAX_NAME_LENGTH];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	int target = FindTarget(client, targetArg, true, false);
	
	if (target > 0 && IsClientAuthorized(target)) {
		char url[PLATFORM_MAX_PATH];
		
		Format(url, sizeof(url), "https://steamcommunity.com/profiles/[U:1:%d]",
				GetSteamAccountID(target));
		
		AdvMOTD_ShowMOTDPanel(client, "Profile Window", url, MOTDPANEL_TYPE_URL,
				_, true, _, INVALID_FUNCTION);
	}
	
	return Plugin_Handled;
}

/**
 * Return failure reason on page open.
 */
public void OnPageOpenFailure(int client, MOTDFailureReason reason) {
	if (IsClientInGame(client)) {
		switch (reason) {
			case MOTDFailure_Disabled: {
				PrintToChat(client, "Can't open group info:  You have HTML MOTDs disabled.");
			}
			case MOTDFailure_Matchmaking: {
				PrintToChat(client, "Can't open group info:  "
						... "HTML MOTDs are disabled for Quickplay users.");
			}
		}
	}
}
