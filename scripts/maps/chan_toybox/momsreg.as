#include "common"
void PluginInit()
{
	g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @SpawnedMOM);
}

void MapInit()
{
	RegisterMOM();
}

HookReturnCode SpawnedMOM(CBasePlayer@ pPlayer)
{
	pPlayer.GiveNamedItem("weapon_momslipper");
 
    	return HOOK_CONTINUE;
}