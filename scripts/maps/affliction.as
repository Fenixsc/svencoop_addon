#include "anti_rush"
#include "HLSPClassicMode2"
#include "point_checkpoint"

const bool blAntiRushEnable = true; // You can change this to have AntiRush mode enabled or disabled
const bool blDoorCrush = false; // Set to false if you wan't want doors to crush players
const float flSurvivalVoteAllow = g_EngineFuncs.CVarGetFloat( "mp_survival_voteallow" );

void MapInit()
{
    RegisterPointCheckPointEntity();
    ANTI_RUSH::EntityRegister( blAntiRushEnable );
    g_SurvivalMode.EnableMapSupport();
    ClassicModeMapInit();
}

void MapActivate()
{
	g_EngineFuncs.ServerPrint( "Affliction - Download this campaign from scmapdb.com\n" );
	// I can't be assed to go through each bsp and adding damage manually to every func_door just to prevent trolling
    CBaseEntity@ pEntity;
    while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_door*" ) ) !is null )
	{
		if( blDoorCrush && pEntity.pev.dmg == 0.0f )
			pEntity.pev.dmg = 50000.0f;
	}
}

void ActivateSurvival( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	g_SurvivalMode.Activate();
}
