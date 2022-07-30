#include <sourcemod>

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

#define PLUGIN_NAME "LastNamePlayers"
#define PLUGIN_AUTHOR "phenom"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "https://vk.com/jquerry"

Database g_hDatabase;

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description = "",
	version 	= PLUGIN_VERSION,
	url 		= PLUGIN_URL
}

public void OnPluginStart()
{
	if (SQL_CheckConfig("LastNamePlayers"))
		Database.Connect(OnSqlConnect, "LastNamePlayers");
	else
		Database.Connect(OnSqlConnect, "default");

	RegConsoleCmd("sm_lastname", LPN_Info, "Last Name Players check", ADMFLAG_BAN);
	
}

public void OnSqlConnect(Database hDatabase, const char[] sError, any data)
{
	if (hDatabase == null)
	{
		SetFailState("Database failure: %s", sError); 
		return;
	}

	g_hDatabase = hDatabase; 
	
	SQL_LockDatabase(g_hDatabase); 
	g_hDatabase.Query(SQL_Callback_CheckError, "CREATE TABLE last_name (\
													`id` int(11) NOT NULL ,\  
													auth CHAR(34) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\  
													nick CHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\   
													time INT(11) NOT NULL \
													);");
	SQL_UnlockDatabase(g_hDatabase); 
	g_hDatabase.SetCharset("utf8");

}

public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	char szClientAuth[34], szName[MAX_NAME_LENGTH], buffer2[512], buffer[512];
    GetClientAuthId(iClient, AuthId_Steam2, szClientAuth, sizeof(szClientAuth));
    GetClientName(iClient, szName, sizeof(szName));

    if(IsClientConnected(iClient) && !IsClientSourceTV(iClient))
    {
		Format(buffer2, sizeof(buffer2), "SELECT * FROM `last_name` WHERE `nick` LIKE '%s' ORDER BY `time` DESC LIMIT 0,10", szName);
		DBResultSet query = SQL_Query(g_hDatabase, buffer2);

		if(query.FetchRow())
		{
			FormatEx(buffer, sizeof(buffer), "UPDATE `u24182_rush_sourcebans`.`last_name` SET `time` = '%i' WHERE `last_name`.`auth` = '%s'", GetTime(), szClientAuth);
			g_hDatabase.Query(SQL_Callback_CheckError, buffer);
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "INSERT INTO `u24182_rush_sourcebans`.`last_name` (`id`, `auth`, `nick`, `time`) VALUES (NULL, '%s', '%s', '%i');", szClientAuth, szName, GetTime());
			g_hDatabase.Query(SQL_Callback_CheckError, buffer);
		}
    }
}

Action LPN_Info(int iClient, int iArgs)
{
	if(iClient > 0)
	{
		Open_MainMenu(iClient);
	}

	return Plugin_Handled;
}

void Open_MainMenu(int iClient)
{

	Handle hMenu = CreateMenu(CallBack_MainMenu);
	SetMenuTitle(hMenu, "Last Player Name | Главная");

	AddMenuItem(hMenu, "", "Список игроков");
	AddMenuItem(hMenu, "", "В разработке(не трогать)");
	AddMenuItem(hMenu, "", "В разработке(не трогать)");

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

int CallBack_MainMenu(Menu hMenu, MenuAction eAction, int iClient, int iItem)
{
	switch(eAction)
	{
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 0:
				{
					LPN_Players(iClient);
				}
				case 1:
				{
					
				}
				case 2:
				{
					
				}
			}
		}
	}

	return 0;
}

void LPN_Players(int iClient)
{
	char szPlayerName[MAX_NAME_LENGTH],
		 szClient[8];

	Handle hMenu = CreateMenu(CallBack_PlayerMenu);
	SetMenuTitle(hMenu, "Last Player Name | Игроки");

	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			GetClientName(i, szPlayerName, 64);
			IntToString(i, szClient, 8);
			AddMenuItem(hMenu, szClient, szPlayerName, 0);
		}
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

int CallBack_PlayerMenu(Menu hMenu, MenuAction eAction, int iClient, int iItem)
{
	switch(eAction)
	{
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
		case MenuAction_Select:
		{
			char szInfo[8];
			GetMenuItem(hMenu, iItem, szInfo, 8);
			int iTarget = StringToInt(szInfo, 10);
			if (IsClientConnected(iTarget))
			{
				LPN_ListPlayers(iClient, iTarget);
			}
		}
	}

	return 0;
}

void LPN_ListPlayers(int iClient, int iTarget)
{
	char szClientAuth[34], buffer2[512], buffer[512], szPlayerName[MAX_NAME_LENGTH], date[32];
	int iTimePlayer;
	GetClientAuthId(iTarget, AuthId_Steam2, szClientAuth, sizeof(szClientAuth));
	Format(buffer2, sizeof(buffer2), "SELECT * FROM `last_name` WHERE `auth` LIKE '%s' ORDER BY `time` DESC LIMIT 0,10", szClientAuth);
	DBResultSet query = SQL_Query(g_hDatabase, buffer2);

	Panel panel = new Panel();
	panel.SetTitle("Last Player Name | Информация");

	int i = 1;
	while (SQL_FetchRow(query))
	{
		query.FetchString(2, szPlayerName, sizeof(szPlayerName));
		iTimePlayer = query.FetchInt(3);

		FormatTime(date, sizeof(date), "%d/%m/%Y", iTimePlayer);
		FormatEx(buffer, sizeof(buffer), "%i. %s - %s", i, szPlayerName, date);
		i++;
		panel.DrawText(buffer);
	}

	SetPanelCurrentKey(panel, 8);
	DrawPanelItem(panel, "Назад");
	SetPanelCurrentKey(panel, 0);
	DrawPanelItem(panel, "Выход");
	panel.Send(iClient, Select_Panel, 20);
}

public int Select_Panel(Handle panel, MenuAction eAction, int iClient, int iItem) 
{
    if(eAction == MenuAction_Select && iItem == 8)
	{
		Open_MainMenu(iClient);
	}
}