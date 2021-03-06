static float lastCommandTime[MAXPLAYERS + 1];

void RegisterCommands() {
    RegConsoleCmd("sm_rank", Command_Rank, "[KZ] Gets your, or another players, ranks. Usage: sm_rank <player>");
    RegConsoleCmd("sm_ranks", Command_Ranks, "[KZ] Show all ranks for your current mode");
    RegConsoleCmd("sm_ranktop", Command_RankTop, "[KZ] Opens menu to view rank top");

    RegAdminCmd("sm_recalculate_top", Command_Recalculate_Top, ADMFLAG_ROOT, "[KZ] Recalculates player profiles in TOP list");
}

public Action Command_Rank(int client, int args)
{
    if (IsSpammingCommands(client))
    {
        return Plugin_Handled;
    }

    if (args < 1) // If not arguments, show own rank
    {
        int steamID = GetSteamAccountID(client);
        DB_OpenPlayerRank(client, steamID);
    }
    else // Get the player we want
    {
        char specifiedPlayer[MAX_NAME_LENGTH];
        GetCmdArg(1, specifiedPlayer, sizeof(specifiedPlayer));

        int target = FindTarget(client, specifiedPlayer, true, false);
        if (target != -1)
        {
            int steamID = GetSteamAccountID(target);
            DB_OpenPlayerRank(client, steamID);
        }
    }

    return Plugin_Handled;
}

public Action Command_Ranks(int client, int args)
{
    char rankBuffer[256];
    char buffer[256];
    int mode = GOKZ_GetCoreOption(client, Option_Mode);

    Format(buffer, sizeof(buffer), "%s: ", gC_ModeNamesShort[mode]);

    for (int i = 0; i < gI_SkillGroupCount; i++) {
        Format(rankBuffer, sizeof(rankBuffer), "%s%s (%d) ", gS_SkillGroupColor[i], gS_SkillGroupName[i], RoundFloat(gI_MaxScore[mode] * gF_SkillGroupPercentage[i]));
        StrCat(buffer, sizeof(buffer), rankBuffer);

        if (i > 0 && i % 8 == 0) {
            GOKZ_PrintToChat(client, true, buffer);
            Format(buffer, sizeof(buffer), "%s: ", gC_ModeNamesShort[mode]);
        }
    }

    GOKZ_PrintToChat(client, true, buffer);

    return Plugin_Handled;
}

public Action Command_RankTop(int client, int args)
{
    if (IsSpammingCommands(client))
    {
        return Plugin_Handled;
    }

    DisplayRankTopModeMenu(client);
    return Plugin_Handled;
}

public Action Command_Recalculate_Top(int client, int args)
{
    if (gB_RecalculationInProgess)
    {
        GOKZ_PrintToChat(client, true, "%t", "Recalculation In Progress");
        return Plugin_Handled;
    }

    DB_RecalculateTop(client);

    return Plugin_Handled;
}

// =====[ PRIVATE ]=====
// Spamming check stolen from GOKZ plugin:
// https://bitbucket.org/kztimerglobalteam/gokz/src/master/addons/sourcemod/scripting/gokz-localranks/commands.sp

bool IsSpammingCommands(int client, bool printMessage = true)
{
    float currentTime = GetEngineTime();
    float timeSinceLastCommand = currentTime - lastCommandTime[client];
    if (timeSinceLastCommand < MYRANK_COMMAND_COOLDOWN)
    {
        if (printMessage)
        {
            GOKZ_PrintToChat(client, true, "%t", "Please Wait Before Using Command", MYRANK_COMMAND_COOLDOWN - timeSinceLastCommand + 0.1);
        }
        return true;
    }

    // Not spamming commands - all good!
    lastCommandTime[client] = currentTime;
    return false;
}