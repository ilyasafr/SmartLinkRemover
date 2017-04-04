#pragma semicolon 1

#define PLUGIN_AUTHOR "Totenfluch [Fix by Agent Wesker]"
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>
#include <regex>

#pragma newdecls required

Regex urlPattern;
RegexError theError;
bool locked[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Smart URL Remover", 
	author = PLUGIN_AUTHOR, 
	description = "Removes all Links from Player Names", 
	version = PLUGIN_VERSION, 
	url = "https://totenfluch.de"
};

public void OnPluginStart()
{
	HookEvent("player_changename", onPlayerNameChange, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("SayText2"), SayText2, true);
	
	char error[256];
	urlPattern = CompileRegex("((http:[/]{2}|https:[/]{2}|www[.])?[-a-zA-Z0-9]{2,}[.][a-zA-Z]{2,5})", PCRE_CASELESS, error, sizeof(error), theError);
	if (!StrEqual(error, ""))
		LogError(error);
}

public void OnClientPostAdminCheck(int client)
{
	locked[client] = false;
	char cname[MAX_NAME_LENGTH];
	GetClientName(client, cname, sizeof(cname));
	checkNameURL(client, cname);
}

static bool checkNameURL(int client, char name[MAX_NAME_LENGTH])
{
	char match[MAX_NAME_LENGTH];
	int matchCount = MatchRegex(urlPattern, name, theError);
	if (matchCount > 0)
	{
		locked[client] = true;
		for (int i = 0; i < matchCount; i++)
		{
			//Substrings start at 0
			GetRegexSubString(urlPattern, i, match, sizeof(match));
			ReplaceString(name, sizeof(name), match, "", false);
		}
		if (StrEqual(name, ""))
			name = "URLRemoved";
		SetClientName(client, name);
		locked[client] = false;
		return true;
	}
	return false;
}

public Action onPlayerNameChange(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (locked[client])
		return Plugin_Changed;
		
	char newname[MAX_NAME_LENGTH];
	GetEventString(event, "newname", newname, sizeof(newname));
	if (checkNameURL(client, newname))
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public void OnMapEnd()
{
	if (urlPattern != INVALID_HANDLE)
		CloseHandle(urlPattern);
}

// BY https://forums.alliedmods.net/member.php?u=67162
public Action SayText2(UserMsg msg_id, Handle bf, int[] players, int playersNum, bool reliable, bool init)
{
	if (!reliable)
		return Plugin_Continue;
	
	char buffer[25];
	
	if (GetUserMessageType() == UM_Protobuf) {
		PbReadString(bf, "msg_name", buffer, sizeof(buffer));
		if (StrEqual(buffer, "#Cstrike_Name_Change"))
			return Plugin_Handled;
		
	} else {
		BfReadChar(bf);
		BfReadChar(bf);
		BfReadString(bf, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, "#Cstrike_Name_Change"))
			return Plugin_Handled;
		
	}
	return Plugin_Continue;
} 
