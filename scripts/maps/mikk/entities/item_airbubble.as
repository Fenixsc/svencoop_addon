/*
	Original script by Cubemath: https://github.com/CubeMath/UCHFastDL2/blob/master/svencoop/scripts/maps/cubemath/item_airbubble.as
	
	i've just fixed the sound being global and removed the miniairbubble because i don't use it. -Mikk
*/
void RegisterAirbubbleCustomEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "item_airbubble", "item_airbubble" );
		
	dictionary keyvalues;
	keyvalues =	
	{
		{ "volume", "10"},
		{ "message", "debris/bustflesh1.wav"},
		{ "spawnflags", "5"},
		{ "targetname", "AirBubbleSound" }
	};
	g_EntityFuncs.CreateEntity( "ambient_music", keyvalues, true );
}

class item_airbubble : ScriptBaseEntity 
{
	void Precache() 
	{
		BaseClass.Precache();
		g_Game.PrecacheModel( "models/w_oxygen.mdl" );
		g_Game.PrecacheModel( "sprites/bubble.spr" );
		g_SoundSystem.PrecacheSound( "debris/bustflesh1.wav" );
	}
	
	void Spawn()
	{
		Precache();
		
		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_TRIGGER;
		self.pev.scale 			= 1.0;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		
		g_EntityFuncs.SetModel( self, "models/w_oxygen.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-32, -32, -32), Vector(32, 32, 32) );
		
		SetThink( ThinkFunction( this.letsRespawn ) );
	}
	
	void letsRespawn() 
	{
		self.pev.solid = SOLID_TRIGGER;
	}
	
	void Touch( CBaseEntity@ pOther ) 
	{
		if( pOther is null || !pOther.IsPlayer() ) 
		return;
		
		g_EntityFuncs.FireTargets( "AirBubbleSound", pOther, pOther, USE_TOGGLE );
		
		pOther.pev.air_finished = g_Engine.time + 12.0;
		self.pev.solid = SOLID_NOT;
        self.pev.nextthink = g_Engine.time + 1.0f;
	}
}