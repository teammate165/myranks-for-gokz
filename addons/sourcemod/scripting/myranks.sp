#include <sourcemod>
#include <myranks>
#include <gokz/core>
#include <gokz/localdb>
#include <gokz/localranks>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = "MyRanks for GOKZ",
    author = "Walliski",
    description = "KZTimer-isch ranks for GOKZ on MySQL DB",
    version = MYRANK_VERSION,
    url = "https://github.com/walliski/myranks-for-gokz"
};

Database gH_DB = null;
DatabaseType g_DBType = DatabaseType_None;

bool gB_mapInRanked = false;

int gI_Score[MODE_COUNT][MAXPLAYERS + 1];
int gI_OldScore[MODE_COUNT][MAXPLAYERS + 1];
int gI_MaxScore[MODE_COUNT];
bool gB_RecalculationInProgess = false;

char gS_SkillGroupName[MYRANK_SG_MAXCOUNT][MYRANK_SG_NAME_MAXLENGTH];
char gS_SkillGroupColor[MYRANK_SG_MAXCOUNT][MYRANK_SG_NAME_MAXLENGTH];
float gF_SkillGroupPercentage[MYRANK_SG_MAXCOUNT];
int gI_SkillGroupCount = 0;

#include "myranks/db/sql.sp"
#include "myranks/db/helpers.sp"
#include "myranks/db/setup_client.sp"
#include "myranks/db/setup_database.sp"
#include "myranks/db/setup_maxscore.sp"
#include "myranks/db/set_map_ranked_status.sp"
#include "myranks/db/player_on_new_record.sp"
#include "myranks/db/player_ranktopmenu.sp"
#include "myranks/db/player_rankmenu.sp"
#include "myranks/db/recalculate_top.sp"
#include "myranks/skillgroups.sp"
#include "myranks/commands.sp"
#include "myranks/natives.sp"
#include "myranks/forwards.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNatives();
    RegPluginLibrary("myranks");
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateGlobalForwards();
    LoadTranslations("myranks.phrases");
    LoadTranslations("common.phrases.txt"); // For FindTarget

    RegisterCommands();
}

public void OnAllPluginsLoaded()
{
    gH_DB = GOKZ_DB_GetDatabase();
    if (gH_DB != null)
    {
        g_DBType = GOKZ_DB_GetDatabaseType();
        if (g_DBType != DatabaseType_MySQL) {
            SetFailState("Only MySQL/MariaDB databases are supported!");
        }

        DB_CreateTables();
    }
}

public void OnClientAuthorized(int client, const char[] auth)
{
    DB_SetupClient(client);
}

public void OnConfigsExecuted()
{
    DB_SetupMaxScore();
}

public void GOKZ_DB_OnDatabaseConnect(DatabaseType DBType)
{
    gH_DB = GOKZ_DB_GetDatabase();
    g_DBType = DBType;

    if (g_DBType != DatabaseType_MySQL) {
        SetFailState("Only MySQL/MariaDB databases are supported!");
    }

    DB_CreateTables();
}

public void GOKZ_DB_OnMapSetup(int mapID)
{
    gB_mapInRanked = false; // Reset this to false to begin with.

    DB_SetMapRankedStatus(mapID);
}

public void GOKZ_LR_OnTimeProcessed(
    int client,
    int steamID,
    int mapID,
    int course,
    int mode,
    int style,
    float runTime,
    int teleportsUsed,
    bool firstTime,
    float pbDiff,
    int rank,
    int maxRank,
    bool firstTimePro,
    float pbDiffPro,
    int rankPro,
    int maxRankPro
)
{
    if (course != 0) {
        return;
    }

    if (pbDiff < 0 || pbDiffPro < 0 || firstTime || firstTimePro) // Negative diffs means new best time!
    {
        if (!gB_mapInRanked)
        {
            GOKZ_PrintToChatAll(true, "%t", "Map Not In Local Ranked Pool");
            return;
        }

        DB_OnNewRecord(client, steamID, mode);
    }
}
