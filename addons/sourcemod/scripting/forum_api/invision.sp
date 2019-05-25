
void Invision_LoadGroups()
{
    char sQuery[256];
    Format(sQuery, sizeof(sQuery), "SELECT g_id FROM core_groups");
    g_dDatabase.Query(Invision_GetGroupIDs, sQuery);

    if (g_cDebug.BoolValue)
    {
        LogMessage("[Forum-API] (Invision_LoadGroups) Query: %s", sQuery);
    }
}

public int Invision_GetGroupIDs(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        LogError("[Forum-API] (Invision_GetGroupIDs) Query error by void: '%s'", error);
        return;
    }
    else
    {
        if (results.HasResults)
        {
            delete g_smGroups;
            g_smGroups = new StringMap();

            delete g_smGroupBanner;
            g_smGroupBanner = new StringMap();

            while (results.FetchRow())
            {
                int groupid = results.FetchInt(0);

                char sKey[16];
                Format(sKey, sizeof(sKey), "core_group_%d", groupid);

                if (g_cDebug.BoolValue)
                {
                    LogMessage("[Forum-API] (Invision_GetGroupIDs) GroupID: %d, Key: %s", groupid, sKey);
                }

                char sQuery[256];
                Format(sQuery, sizeof(sQuery), "SELECT word_key, word_default FROM core_sys_lang_words WHERE word_key = \"%s\"", sKey);
                g_dDatabase.Query(Invision_GetGroupNames, sQuery, groupid);
            }
        }
    }
}


public int Invision_GetGroupNames(Database db, DBResultSet results, const char[] error, int groupid)
{
    if (db == null || strlen(error) > 0)
    {
        LogError("[Forum-API] (Invision_GetGroupNames) Query error by void: '%s'", error);
        return;
    }
    else
    {
        if (results.HasResults)
        {
            while (results.FetchRow())
            {
                char sGroupID[12];
                IntToString(groupid, sGroupID, sizeof(sGroupID));

                char sKey[16];
                results.FetchString(0, sKey, sizeof(sKey));

                char sName[64];
                results.FetchString(1, sName, sizeof(sName));

                if (g_cDebug.BoolValue)
                {
                    LogMessage("[Forum-API] (Invision_GetGroupNames) Key: %s, Name: %s", sKey, sName);
                }

                g_smGroups.SetString(sGroupID, sName);
                g_smGroupBanner.SetString(sGroupID, sName);
            }

            g_bGroups = true;
            LoadClients();
        }
    }
}


void Invision_LoadUserFields()
{
    delete g_smFields;
    g_smFields = new StringMap();

    char sQuery[256];
    Format(sQuery, sizeof(sQuery), "SELECT pf_id FROM core_pfields_data");
    g_dDatabase.Query(Invision_GetUserFieldIDs, sQuery);

    if (g_cDebug.BoolValue)
    {
        LogMessage("[Forum-API] (Invision_LoadUserFields) Query: %s", sQuery);
    }
}

public int Invision_GetUserFieldIDs(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        LogError("[Forum-API] (Invision_GetUserFieldIDs) Query error by void: '%s'", error);
        delete g_smFields;
        return;
    }
    else
    {
        if (results.HasResults)
        {
            while (results.FetchRow())
            {
                int iFieldID = results.FetchInt(0);

                char sKey[16];
                Format(sKey, sizeof(sKey), "core_pfield_%d", iFieldID);

                if (g_cDebug.BoolValue)
                {
                    LogMessage("[Forum-API] (Invision_GetUserFieldIDs) UserFieldID: %d, Key: %s", iFieldID, sKey);
                }

                char sQuery[256];
                Format(sQuery, sizeof(sQuery), "SELECT word_key, word_default FROM core_sys_lang_words WHERE word_key = \"%s\"", sKey);
                g_dDatabase.Query(Invision_GetUserFieldNames, sQuery);
            }

            g_bFields = true;
            LoadClients();
        }
    }
}


public int Invision_GetUserFieldNames(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        LogError("[Forum-API] (Invision_GetUserFieldNames) Query error by void: '%s'", error);
        return;
    }
    else
    {
        if (results.HasResults)
        {
            while (results.FetchRow())
            {
                char sKey[16];
                results.FetchString(0, sKey, sizeof(sKey));

                char sName[64];
                results.FetchString(1, sName, sizeof(sName));

                if (g_cDebug.BoolValue)
                {
                    LogMessage("[Forum-API] (Invision_GetUserFieldNames) Key: %s, Name: %s", sKey, sName);
                }

                g_smFields.SetString(sKey, sName);
            }
        }
    }
}


void Invision_LoadClient(int client, const char[] sCommunityID)
{
    char sQuery[256];
    Format(sQuery, sizeof(sQuery), "SELECT member_id FROM core_members WHERE steamid = '%s'", sCommunityID);
    g_dDatabase.Query(Invision_GetUserId, sQuery, GetClientUserId(client));
    
    if (g_cDebug.BoolValue)
    {
        LogMessage("[Forum-API] (Invision_LoadClient) Query: %s", sQuery);
    }
}

public void Invision_GetUserId(Database db, DBResultSet results, const char[] error, int userid)
{
    if(db == null || strlen(error) > 0)
    {
        SetFailState("[Forum-API] (Invision_GetUserId) Fail at Query: %s", error);
        return;
    }
    else
    {
        int client = GetClientOfUserId(userid);
        
        if (client > 0 && !IsClientValid(client))
        {
            LogError("[Forum-API] (Invision_GetUserId) Error grabbing User Data: Client invalid");
            return;
        }
        
        if (g_cDebug.BoolValue)
        {
            LogMessage("[Forum-API] (Invision_GetUserId) Retrieving data for %N...", client);
        }
        
        if (results.FetchRow())
        {
            if (results.IsFieldNull(0))
            {
                LogError("[Forum-API] (Invision_GetUserId) Error retrieving User Data: (Field is null)");
                return;
            }
            
            g_iUserID[client] = results.FetchInt(0);
            g_bIsProcessed[client] = true;
            
            Call_StartForward(g_hOnGrabProcessed);
            Call_PushCell(client);
            Call_PushCell(g_iUserID[client]);
            Call_Finish();
            
            if (g_cDebug.BoolValue)
            {
                LogMessage("[Forum-API] (Invision_GetUserId) User '%N' has been processed successfully!", client);
            }

            char sQuery[256];
            Format(sQuery, sizeof(sQuery), "SELECT name, member_group_id, mgroup_others, member_title FROM core_members WHERE member_id = '%d'", g_iUserID[client]);
            g_dDatabase.Query(Invision_UserInformations, sQuery, userid);

            if (g_cDebug.BoolValue)
            {
                LogMessage("[Forum-API] (Invision_GetUserId) - User Informations - Query: %s", sQuery);
            }

            StringMapSnapshot smFields = g_smFields.Snapshot();
            char sKey[32];

            g_iFieldCount[client] = 0;

            delete g_smUserFields[client];
            g_smUserFields[client] = new StringMap();

            for (int i = 0; i < smFields.Length; i++)
            {
                smFields.GetKey(i, sKey, sizeof(sKey));

                LogMessage("smFields.Length: %d, g_smFields.Size: %d", smFields.Length, g_smFields.Size);

                ReplaceString(sKey, sizeof(sKey), "core_pfield_", "");
                LogMessage("(ReplaceString) sKey: %s", sKey);

                Format(sQuery, sizeof(sQuery), "SELECT field_%s FROM core_pfields_content WHERE member_id = '%d'", sKey, g_iUserID[client]);
                DataPack pack = new DataPack();
                pack.WriteCell(userid);
                Format(sKey, sizeof(sKey), "core_pfield_%s", sKey); // Just an workaround
                pack.WriteString(sKey);
                g_dDatabase.Query(Invision_UserFields, sQuery, pack);

                if (g_cDebug.BoolValue)
                {
                    LogMessage("[Forum-API] (Invision_GetUserId) - User Fields - Query: %s", sQuery);
                }
            }

            delete smFields;
        }
        else
        {
            LogError("[Forum-API] (Invision_GetUserId) Error retrieving User (\"%L\") Data: (Row not fetched)", client);
        }
    }
}

public void Invision_UserInformations(Database db, DBResultSet results, const char[] error, int userid)
{
    if(db == null || strlen(error) > 0)
    {
        SetFailState("[Forum-API] (Invision_UserInformations) Fail at Query: %s", error);
        return;
    }
    else
    {
        int client = GetClientOfUserId(userid);
        
        if (!IsClientValid(client))
        {
            LogError("[Forum-API] (Invision_UserInformations) Error grabbing User informations: Client invalid");
            return;
        }
        
        if (g_cDebug.BoolValue)
        {
            LogMessage("[Forum-API] (Invision_UserInformations) Retrieving informations for %N...", client);
        }
        
        if (results.FetchRow())
        {
            if (results.IsFieldNull(0))
            {
                LogError("[Forum-API] (Invision_UserInformations) Error retrieving User informations: (Field is null)");
                return;
            }

            results.FetchString(0, g_sName[client], sizeof(g_sName[]));

            g_iPrimaryGroup[client] = results.FetchInt(1);

            char sSecondaryIDs[64];
            results.FetchString(2, sSecondaryIDs, sizeof(sSecondaryIDs));

            char sSecondaryGroups[12][12];
            int iSecondaryCount = ExplodeString(sSecondaryIDs, ",", sSecondaryGroups, sizeof(sSecondaryGroups), sizeof(sSecondaryGroups[]));

            delete g_aSecondaryGroups[client];
            g_aSecondaryGroups[client] = new ArrayList();

            for (int i = 0; i < iSecondaryCount; i++)
            {
                g_aSecondaryGroups[client].Push(StringToInt(sSecondaryGroups[i]));
            }

            results.FetchString(3, g_sCustomTitle[client], sizeof(g_sCustomTitle[]));
            
            Call_StartForward(g_hOnInfoProcessed);
            Call_PushCell(client);
            Call_PushString(g_sName[client]);
            Call_PushCell(g_iPrimaryGroup[client]);
            Call_PushCell(g_aSecondaryGroups[client]);
            Call_Finish();
            
            if (g_cDebug.BoolValue)
            {
                LogMessage("[Forum-API] (Invision_UserInformations) User informations for'%N' has been processed successfully!", client);
            }
        }
        else
        {
            LogError("[Forum-API] (Invision_UserInformations) Error retrieving User (\"%L\") informations: (Row not fetched)", client);
        }
    }
}

public void Invision_UserFields(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if(db == null || strlen(error) > 0)
    {
        SetFailState("[Forum-API] (Invision_UserFields) Fail at Query: %s", error);
        delete pack;
        return;
    }
    else
    {
        pack.Reset();

        int client = GetClientOfUserId(pack.ReadCell());

        char sKey[32];
        pack.ReadString(sKey, sizeof(sKey));
        
        if (!IsClientValid(client))
        {
            LogError("[Forum-API] (Invision_UserFields) Error grabbing user fields: Client invalid");
            return;
        }

        g_iFieldCount[client]++;
        LogMessage("Field Count: %d", g_iFieldCount[client]);

        if (g_cDebug.BoolValue)
        {
            LogMessage("[Forum-API] (Invision_UserFields) Retrieving user field %s for %N...", sKey, client);
        }
        
        if (results.FetchRow())
        {
            if (results.IsFieldNull(0))
            {
                LogError("[Forum-API] (Invision_UserFields) Error retrieving user fields: (Field is null)");
                return;
            }

            char sValue[128];
            results.FetchString(0, sValue, sizeof(sValue));

            if (strlen(sValue) > 1)
            {
                g_smUserFields[client].SetString(sKey, sValue);
            }

            if (g_iFieldCount[client] == g_smFields.Size)
            {
                Call_StartForward(g_hOnUserFieldsProcessed);
                Call_PushCell(client);
                Call_PushCell(g_smUserFields[client]);
                Call_Finish();

                if (g_cDebug.BoolValue)
                {
                    LogMessage("[Forum-API] (Invision_UserFields) User fields for'%N' has been processed successfully!", client);
                }
            }
        }
        else
        {
            LogError("[Forum-API] (Invision_UserFields) Error retrieving User (\"%L\") fields: (Row not fetched)", client);
        }
    }
}

