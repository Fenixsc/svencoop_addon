HookReturnCode EntityCreated( CBaseEntity@ pEntity ){
    if(pEntity is null)
        return HOOK_CONTINUE;
    if(pEntity.IsMonster())
        aryMonsterList.insertLast(EHandle(@pEntity));
    return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer ){
    if(pPlayer is null)
        return HOOK_CONTINUE;
    PlayerDMGTweak();
    return HOOK_CONTINUE;
}