#include "../hunger/weapons/weapon_spanner"

/* Santas Workshop map script
By Meryilla

*/

enum e_teams
{
    YELLOW = 0,
    GREEN
}

dictionary BASE_TOKEN_DICT =
{
	{ "model", "models/tfc/keycard.mdl" },
	{ "holder_can_drop", "0" },
	{ "holder_keep_on_respawn", "1" },
	{ "holder_keep_on_death", "1" },
	{ "carried_hidden", "1" },
	{ "carried_sequencename", "null" },
	{ "item_group", "token" },
	{ "display_name", "Suit" },
	{ "description", "This item shows you which team you are on" }
};

const string SPRITE_TEAM_YELLOW = "sprites/santas_workshop/yellteam.spr";
const string SPRITE_TEAM_GREEN = "sprites/santas_workshop/greenteam.spr";

const string SPRITE_HUD_YELLOW = "santas_workshop/yellhud.spr";
const string SPRITE_HUD_GREEN = "santas_workshop/greenhud.spr";

float g_flChatCooldown;

void MapInit()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, PlayerSpawn );
    g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, PlayerDisconnected );
    g_Hooks.RegisterHook( Hooks::Player::ClientSay, ChatCheck );
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamage );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PlayerThink );

    THWeaponSpanner::Register();

    Precache();

    g_Scheduler.SetInterval( "ModelChange", 1.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
}

void Precache()
{
    g_Game.PrecacheModel( SPRITE_TEAM_YELLOW );
    g_Game.PrecacheModel( SPRITE_TEAM_GREEN );
    g_Game.PrecacheModel( "sprites/" + SPRITE_HUD_YELLOW );
    g_Game.PrecacheModel( "sprites/" + SPRITE_HUD_GREEN );
    g_Game.PrecacheModel( "models/player/pedobear/pedobear.mdl" );
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;
	
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();

    pPlayer.pev.targetname = "" + pPlayer.entindex();
    g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_isDying", "0" );

    if( !kvPlayer.HasKeyvalue( "$i_hasTeam" ) )
    {
        if( GetTeamBalance() )
        {
            AssignTeam( pPlayer, YELLOW );
        }
        else
        {
            AssignTeam( pPlayer, GREEN );
        }

        g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_hasTeam", "1" );
    }
	
	return HOOK_CONTINUE;
}

HookReturnCode PlayerDisconnected( CBasePlayer@ pPlayer )
{
    CBaseEntity@ pSprite, pAttach;
    @pSprite = g_EntityFuncs.FindEntityByTargetname( null, "" + pPlayer.pev.targetname + "_teamSprite" );
    @pAttach = g_EntityFuncs.FindEntityByTargetname( null, "" + pPlayer.pev.targetname + "team_attachSprite" );

    if( pSprite !is null )
        g_EntityFuncs.Remove( pSprite );

    if( pAttach !is null )
        g_EntityFuncs.Remove( pAttach ); 
	
	return HOOK_CONTINUE;
}

HookReturnCode ChatCheck( SayParameters@ pParams )
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const CCommand@ pArguments = pParams.GetArguments();
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	
	if( pPlayer is null )
		return HOOK_CONTINUE;	

    if( pArguments[0] == ".yellow")
    {
        pParams.ShouldHide = true;
        SwitchTeam( pPlayer, YELLOW );
    }
    else if( pArguments[0] == ".green" )
    {
        pParams.ShouldHide = true;
        SwitchTeam( pPlayer, GREEN );
    }
	
	if( pArguments[ 0 ] == ".debug" )
	{
		pParams.ShouldHide = true;
        pPlayer.Killed( null, GIB_NOPENALTY );
        pPlayer.m_iDeaths++;
        
	}

    string szMessage = pParams.GetCommand();
    szMessage.ToUppercase();
    bool blMessageTest = false;
    bool blPrintReady = true;

    blMessageTest = ( szMessage.Find( "TEAM" ) < String::INVALID_INDEX );
    blMessageTest = blMessageTest || ( szMessage.Find( "GREEN" ) < String::INVALID_INDEX );
    blMessageTest = blMessageTest || ( szMessage.Find( "YELLOW" ) < String::INVALID_INDEX );
    blMessageTest = blMessageTest && ( g_flChatCooldown < g_Engine.time );

    if( blMessageTest && blPrintReady )
    {
		g_flChatCooldown = g_Engine.time + 30.0f;
		string aStr = "SANTA: Type .yellow or .green in chat to switch to the yellow or green team respectively.\n";
		g_Game.AlertMessage( at_logged, "\"SANTA\" says \"Type .yellow or .green in chat to switch to the yellow or green team respectively.\"\n" );
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, aStr );
		blPrintReady = false;        
    }

	return HOOK_CONTINUE;
}

HookReturnCode PlayerThink( CBasePlayer@ pPlayer )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;

    CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();

    if( kvPlayer.GetKeyvalue( "$i_isDying" ).GetInteger() == 1 )
    {
        pPlayer.pev.solid = SOLID_NOT;      
    }  

    return HOOK_CONTINUE;
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	CBaseEntity@ pAttacker = pDamageInfo.pAttacker;
	CBaseEntity@ pInflictor = pDamageInfo.pInflictor;
	CBasePlayer@ pVictim = cast<CBasePlayer@>( g_EntityFuncs.Instance( pDamageInfo.pVictim.pev ) );
    float flDamage = pDamageInfo.flDamage;

    if( pVictim.pev.health - flDamage < 1 && pInflictor.pev.classname == "func_tank" )
    {
        pDamageInfo.flDamage = 0;

        if ( ( pVictim.pev.health < -40 && pDamageInfo.bitsDamageType & DMG_NEVERGIB > 0 ) || pDamageInfo.bitsDamageType & DMG_ALWAYSGIB > 0 )
        {
            pVictim.GibMonster();	// This clears pev->model
            pVictim.pev.effects |= EF_NODRAW;
        }   

        pVictim.Killed( null, GIB_NOPENALTY );
        pVictim.m_iDeaths++;             

        string szMessage;

        if( string( g_Engine.mapname ) == "santas_workshop" )
        {
            szMessage = "" + pVictim.pev.netname + " was killed by a security turret.\n";
        }
        else
        {
            szMessage = "" + pVictim.pev.netname + " was killed by the Grinch.\n";
        }
        g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, szMessage );
    }

    return HOOK_CONTINUE;
}

bool GetTeamBalance()
{
    int iYellowCount = 0;
    int iGreenCount = 0;
    CBasePlayer@ pPlayer;

    for( int i = 1; i <= g_Engine.maxClients; i++ )
    {
        @pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
        if( pPlayer !is null && pPlayer.IsConnected() )
        {
            CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
            if( kvPlayer.HasKeyvalue( "$i_hasTeam" ) )
            {
                if( kvPlayer.GetKeyvalue( "$i_team" ).GetInteger() == 0 )
                    iYellowCount++;
                else
                    iGreenCount++;
            }
        }
    }

    if( iYellowCount <= iGreenCount )
        return true;
    else
        return false;
}

void AssignTeam( EHandle hPlayer, int iTeam )
{
    if( !hPlayer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
    CBaseEntity@ pToken;
    dictionary dictKeys = BASE_TOKEN_DICT;

    switch( iTeam )
    {
        case YELLOW:
        {
            dictKeys.set( "item_name", "yellow" );
            dictKeys.set( "display_name", "Yellow Team" );
            dictKeys.set( "item_name_canthave", "green" );
            break;
        }
        case GREEN:
        {
            dictKeys.set( "item_name", "green" );
            dictKeys.set( "display_name", "Green Team" );
            dictKeys.set( "item_name_canthave", "yellow" );
            break;
        }
        default:
        {
            dictKeys.set( "item_name", "yellow" );
            dictKeys.set( "display_name", "Yellow Team" );
            dictKeys.set( "item_name_canthave", "green" );
            break;
        }
    }

    @pToken = g_EntityFuncs.CreateEntity( "item_inventory", dictKeys, true );
    pToken.pev.targetname = "" + pToken.entindex() + "_" + pPlayer.entindex();
    g_EntityFuncs.FireTargets( pToken.pev.targetname, pPlayer, pPlayer, USE_ON );

    g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_team", string(iTeam) );

    AttachTeamSprite( pPlayer, iTeam );
    ShowHUDTeamSprite( pPlayer );
}

void SwitchTeam( EHandle hPlayer, int iTeam )
{
    if( !hPlayer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
    InventoryList@ pInvList = @pPlayer.m_pInventory;  
    while( pInvList !is null )
    {
        CItemInventory@ pInvItem = cast<CItemInventory@>( pInvList.hItem.GetEntity() );

        if( pInvItem !is null && ( pInvItem.m_szItemName == "yellow" || pInvItem.m_szItemName == "green" ) )
        {
            g_EntityFuncs.Remove( pInvItem );
            break;
        }
        @pInvList = @pInvList.pNext;
    }        

    g_PlayerFuncs.RespawnPlayer( pPlayer );
    pPlayer.RemoveAllItems( false ); //We don't want people picking up the wrench and then switching to yellow
    
    CBaseEntity@ pSprite, pAttach;
    @pSprite = g_EntityFuncs.FindEntityByTargetname( null, "" + pPlayer.pev.targetname + "_teamSprite" );
    @pAttach = g_EntityFuncs.FindEntityByTargetname( null, "" + pPlayer.pev.targetname + "team_attachSprite" );

    if( pSprite !is null )
        g_EntityFuncs.Remove( pSprite );

    if( pAttach !is null )
        g_EntityFuncs.Remove( pAttach ); 

    AssignTeam( pPlayer, iTeam );
}

void AttachTeamSprite( EHandle hEntity, int iTeam )
{
	if ( !hEntity )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hEntity.GetEntity() );
	CBaseEntity@ pSprite, pAttach;
	
	dictionary attachValues =
	{
		{ "origin", "" + pPlayer.pev.origin.ToString() },
		{ "targetname", "" + pPlayer.pev.targetname + "team_attachSprite" },
		{ "target", "" + pPlayer.pev.targetname + "_teamSprite" },
		{ "offset", "0 0 64" },
		{ "copypointer", "" + pPlayer.pev.targetname },
		{ "spawnflags", "1011" }
	};
	
	@pAttach = g_EntityFuncs.CreateEntity( "trigger_setorigin", attachValues, true );
	
	if( pAttach !is null )
	{
		dictionary sprValues =
		{
			{ "origin", "" + pPlayer.pev.origin.ToString() },
			{ "targetname", "" + pPlayer.pev.targetname + "_teamSprite" },
			{ "scale", "0.05" },
			{ "spawnflags", "1" }	
		};

        switch( iTeam )
        {
            case YELLOW:
            {
                sprValues.set( "model", SPRITE_TEAM_YELLOW );
                break;
            }
            case GREEN:
            {
                sprValues.set( "model", SPRITE_TEAM_GREEN );
                break;
            }
            default:
            {
                sprValues.set( "model", SPRITE_TEAM_YELLOW );
                break;
            }
        }
		
		@pSprite = g_EntityFuncs.CreateEntity( "env_sprite", sprValues, true );
		g_EntityFuncs.FireTargets( "" + pPlayer.pev.targetname + "team_attachSprite", null, null, USE_ON, 0, 0 );
		
		CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
		
		if( kvPlayer !is null )
			g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_hasTeamSprite", "1" );
    }
}

void ModelChange()
{
    CBasePlayer@ pPlayer;
    for( int i = 1; i <= g_Engine.maxClients; i++ ) 
    {
        @pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if( pPlayer is null || !pPlayer.IsConnected() ) 
            continue;
        
        InventoryList@ pInvList = @pPlayer.m_pInventory;  
        while( pInvList !is null )
        {
            CItemInventory@ pInvItem = cast<CItemInventory@>( pInvList.hItem.GetEntity() );

            if( pInvItem !is null && pInvItem.m_szItemName == "pedobear" )
            {
				//hahaha le ebin 2008 meme
                pPlayer.SetOverriddenPlayerModel( "pedobear" );
                break;
            }
            @pInvList = @pInvList.pNext;
        } 
        
    }	
}

void ShowHUDTeamSprite( EHandle hPlayer )
{
	if( !hPlayer )
		return;
		
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
		
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	
	int iTeam = kvPlayer.GetKeyvalue( "$i_team" ).GetInteger();
    string szTeamSprite;
    g_Game.AlertMessage(at_console, "team is: " + iTeam + "\n");
	
	RGBA RGBA_DISC = RGBA( 255, 255, 255, 255 );

    switch( iTeam )
    {
        case YELLOW:
        {
            szTeamSprite = SPRITE_HUD_YELLOW;
            break;
        }
        case GREEN:
        {
            szTeamSprite = SPRITE_HUD_GREEN;
            break;
        }
        default:
        {
            szTeamSprite = SPRITE_HUD_YELLOW;
            break;
        }
    }

	HUDSpriteParams TeamSpriteDisplayParams;
	TeamSpriteDisplayParams.channel = 0;
	TeamSpriteDisplayParams.flags = HUD_ELEM_EFFECT_ONCE;
	TeamSpriteDisplayParams.x = 0.01;
	TeamSpriteDisplayParams.y = 0.45;
	TeamSpriteDisplayParams.spritename = szTeamSprite;
	TeamSpriteDisplayParams.left = 0; 
	TeamSpriteDisplayParams.top = 255; 
	TeamSpriteDisplayParams.width = 0; 
	TeamSpriteDisplayParams.height = 0;
	TeamSpriteDisplayParams.color1 = RGBA( 255, 255, 255, 255 );
	TeamSpriteDisplayParams.color2 = RGBA( 255, 255, 255, 255 );
	TeamSpriteDisplayParams.fxTime = 0.5;
	TeamSpriteDisplayParams.effect = HUD_EFFECT_RAMP_DOWN;
	
	g_PlayerFuncs.HudCustomSprite( pPlayer, TeamSpriteDisplayParams );
}