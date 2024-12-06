#include "acehigh/CustomHUD"

enum DIFFICULTY
{
	DIFFICULTY_EASY = 0,
	DIFFICULTY_MED,
	DIFFICULTY_HARD,
	DIFFICULTY_EXTREME,
};

DIFFICULTY g_difficulty = DIFFICULTY_MED;

void MapInit()
{
	CustomHUD::Init();
}

void VoteStart( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	CustomHUD::ToggleTimeDisplay( false );
	CustomHUD::SetTarget( 10, "vote_end" );
	CustomHUD::SetWarningTarget( 5, "" );
	CustomHUD::ToggleTimeDisplay( true );
}

void VoteResults( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	g_Game.AlertMessage( at_console, "Calculating results\n");
	array<string> voteZones;
	array<string> voteCounters;
	CBaseEntity@ pZone, pCounter, pWinningCounter;
	
	while( ( @pZone = g_EntityFuncs.FindEntityByTargetname( pZone, "vote_zone_*" ) ) !is null )
	{
		voteZones.insertLast( pZone.pev.targetname );
	}
	while( ( @pCounter = g_EntityFuncs.FindEntityByTargetname( pCounter, "vote_count_*" ) ) !is null )
	{
		voteCounters.insertLast( pCounter.pev.targetname );
		pCounter.pev.frags = 0;
	}	
	for( uint i = 0; i < voteZones.length(); i++ )
	{
		g_EntityFuncs.FireTargets( voteZones[i], null, null, USE_ON );
	}
	
	float score = 0;
	string winningVote = "No result";
	for( uint i = 0; i < voteCounters.length(); i++ )
	{
		@pCounter = g_EntityFuncs.FindEntityByTargetname( pCounter, voteCounters[i] );
		if( pCounter !is null )
		{
			g_Game.AlertMessage( at_console, voteCounters[i] + ": " + pCounter.pev.frags + "\n");
			if( pCounter.pev.frags > score )
			{
				score = pCounter.pev.frags;
				@pWinningCounter = @pCounter;
			}
			else
				continue;
		}
	} 
	
	if( pWinningCounter !is null )
	{
		CustomKeyvalues@ kvCounter = pWinningCounter.GetCustomKeyvalues();
		int iDiff = kvCounter.GetKeyvalue( "$i_diff" ).GetInteger();
		g_Game.AlertMessage( at_console, "iDiff: " + iDiff + "\n");
		
		switch( iDiff )
		{
			case 0:
			{	
				winningVote = "Easy Difficulty";
				g_difficulty = DIFFICULTY_EASY;
				//Fire Target Here
				break;
			}
			case 1:
			{	
				winningVote = "Med Difficulty";
				g_difficulty = DIFFICULTY_MED;
				//Fire Target Here
				break;
			}			
			case 2:
			{	
				winningVote = "Hard Difficulty";
				g_difficulty = DIFFICULTY_HARD;
				//Fire Target Here
				break;
			}			
			case 3:
			{	
				winningVote = "Extreme";
				g_difficulty = DIFFICULTY_EXTREME;
				//Fire Target Here
				break;
			}			
			default:
			{	
				winningVote = "Med Difficulty";
				g_difficulty = DIFFICULTY_MED;
				//Fire Target Here
				break;
			}			
		}
	}
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[Vote] Winner: " + winningVote + "\n");
}