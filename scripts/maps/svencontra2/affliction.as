#include "point_checkpoint"
#include "HLSPClassicMode"
#include "cubemath/trigger_once_mp"
#include "cubemath/trigger_mediaplayer"
#include "cubemath/item_airbubble"
//#include "ofnvision"
#include "crouch_spawn"

const bool blDoorCrush = false; // Set to false if you wan't want doors to crush players

void MapInit()
{	
	RegisterPointCheckPointEntity();
	RegisterTriggerOnceMpEntity();
	RegisterTriggerMediaPlayerEntity();
	RegisterAirbubbleCustomEntity();
	//g_nv.MapInit();
	g_crspawn.Enable();  
	
	// Map support is enabled here by default.
	// So you don't have to add "mp_survival_supported 1" to the map config
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

void ActivateSurvival( CBaseEntity@ pActivator, CBaseEntity@ pCaller,
	USE_TYPE useType, float flValue )
{
	g_SurvivalMode.Activate();
}
