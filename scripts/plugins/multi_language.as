void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Gaftherman" );
	g_Module.ScriptInfo.SetContactInfo( "https://github.com/Mikk155/Sven-Coop-Multi-language-localizations" );

	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
    g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
    g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
}

EHandle InfoTarget;

void MapStart()
{
	bool blIsInstalled = g_CustomEntityFuncs.IsCustomEntity( "game_text_custom" );

	for( int i = 0; i < g_Engine.maxEntities; ++i )
	{
		edict_t@ edict = @g_EntityFuncs.IndexEnt(i);
		CBaseEntity@ FindInfoTarget = g_EntityFuncs.Instance( edict );

		if( FindInfoTarget !is null && FindInfoTarget.pev.classname == "info_target" && FindInfoTarget.pev.targetname == "language" )
		{
			InfoTarget = FindInfoTarget;
		}
	}

	if( blIsInstalled )
	{
		g_Scheduler.SetInterval( "SpamsMultilanguage", 140.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
	}
}

void SpamsMultilanguage()
{
	string Available = "";

	if( InfoTarget.GetEntity() !is null )
	{
		CBaseEntity@ FindInfoTarget = cast<CBaseEntity@>(InfoTarget);

		CustomKeyvalues@ ckLenguage = FindInfoTarget.GetCustomKeyvalues();  

		CustomKeyvalue ckEnglish = ckLenguage.GetKeyvalue("$i_message");
		CustomKeyvalue ckSpanish = ckLenguage.GetKeyvalue("$i_message_spanish");
		CustomKeyvalue ckPortuguese = ckLenguage.GetKeyvalue("$i_message_portuguese");
		CustomKeyvalue ckGerman = ckLenguage.GetKeyvalue( "$i_message_german" );
		CustomKeyvalue ckFrench = ckLenguage.GetKeyvalue( "$i_message_french" );
		CustomKeyvalue ckItalian = ckLenguage.GetKeyvalue( "$i_message_italian" );
		CustomKeyvalue ckEsperanto = ckLenguage.GetKeyvalue( "$i_message_esperanto" );

		int English = ckEnglish.GetInteger();
		int Spanish = ckSpanish.GetInteger();
		int Portuguese = ckPortuguese.GetInteger();
		int German = ckGerman.GetInteger();
		int French = ckFrench.GetInteger();
		int Italian = ckItalian.GetInteger();
		int Esperanto = ckEsperanto.GetInteger();

		if( English == 1 )
			Available = Available == "" ? "English" : Available + " || " + "English";

		if( Spanish == 1 )
			Available = Available == "" ? "Spanish" : Available + " || " + "Spanish";

		if( Portuguese == 1 )
			Available = Available == "" ? "Portuguese" : Available + " || " + "Portuguese";

		if( German == 1 )
			Available = Available == "" ? "German" : Available + " || " + "German";

		if( French == 1 )
			Available = Available == "" ? "French" : Available + " || " + "French";

		if( Italian == 1 )
			Available = Available == "" ? "Italian" : Available + " || " + "Italian";

		if( Esperanto == 1 )
			Available = Available == "" ? "Esperanto" : Available + " || " + "Esperanto";

	//	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[Multi-Language] This map supports multi-language, use /language (language).\n" );
	//	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Available: " +Available+ "\n" );
	}

}

dictionary g_PlayerKeepLenguage;

class PlayerKeepLenguageData
{
	int lenguage;
}

HookReturnCode MapChange()
{
	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if( pPlayer is null or !pPlayer.IsConnected() )
			continue;

		string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

		CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
        CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
        int iLanguage = int(ckLenguageIs.GetFloat());

		PlayerKeepLenguageData pData;
		pData.lenguage = iLanguage;
		g_PlayerKeepLenguage[SteamID] = pData;
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if(pPlayer is null)
		return HOOK_CONTINUE;

	string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

	if( g_PlayerKeepLenguage.exists(SteamID) )
	{
        PlayerLoadLenguage( g_EngineFuncs.IndexOfEdict(pPlayer.edict()), SteamID );
	}
    else
    {
		CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
		CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
		int iLanguage = int(ckLenguageIs.GetFloat());

		PlayerKeepLenguageData pData;
		pData.lenguage = iLanguage;
		g_PlayerKeepLenguage[SteamID] = pData;
    }

	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if(pPlayer is null)
		return HOOK_CONTINUE;

    string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

	CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
    CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
    int iLanguage = int(ckLenguageIs.GetFloat());

    PlayerKeepLenguageData pData;
	pData.lenguage = iLanguage;
	g_PlayerKeepLenguage[SteamID] = pData;   

    return HOOK_CONTINUE;
}

void PlayerLoadLenguage( int &in iIndex, string &in SteamID )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(iIndex);

	if( pPlayer is null )
		return;

	PlayerKeepLenguageData@ pData = cast<PlayerKeepLenguageData@>(g_PlayerKeepLenguage[SteamID]);

	CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
	ckLenguage.SetKeyvalue("$f_lenguage", int(pData.lenguage));
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ args = pParams.GetArguments();

    if(args[0] == "/language" || args[0] == "/lenguaje" || args[0] == "/idioma") 
    {
        if(args.ArgC() < 2)
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[Multi-Language] Select a language, you can use: 'english' or '0'; 'spanish' or '1'; and so on.\n" );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Example: /language english\n" );
		}
		else
        {
			CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
            CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
            int iLanguage = int(ckLenguageIs.GetFloat());

			if(args[1] == "esperanto" || args[1] == "6")
			{
				if(iLanguage == 5)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Vi aktivigis ci tiun lingvon\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Esperonton aktivigis\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 6);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "italian" || args[1] == "5")
			{
				if(iLanguage == 5)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "hai gia questa lingua\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Lingua in italiano attivata\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 5);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "french" || args[1] == "4")
			{
				if(iLanguage == 4)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "vous avez deja cette langue\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Langue en francais activee\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 4);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "german" || args[1] == "3")
			{
				if(iLanguage == 3)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Sie haben diese Sprache bereits\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "deutsche sprache aktiviert\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 3);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "portuguese" || args[1] == "2")
			{
				if(iLanguage == 2)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Voce ativou este idioma\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Idioma em portugues ativado\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 2);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "spanish" || args[1] == "1")
			{
				if(iLanguage == 1)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Ya tienes activado este lenguaje\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Lenguaje en español activado\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 1);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "english" || args[1] == "0")
			{
				if(iLanguage == 0)
				{
                    g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You have activated this leguage\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Language in english activated\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 0);
				}

				pParams.ShouldHide = true;
			}
			else
			{		
        		pParams.ShouldHide = false;
			}
        }

        return HOOK_HANDLED;
    }

    return HOOK_CONTINUE;
}
