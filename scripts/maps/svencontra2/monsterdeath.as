array<EHandle> aryMonsterList = {};
//spr路径
const string szMonsterDeathSprPath = "sprites/deadspray_a.spr";
//默认音效路径
const string szMosnterDeathSoundPath = "sound/npcdead_a.wav";
//播放spr并删除延迟
const float flMonsterDeathSprRemoveDelay = 0.5f;
//spr速率
const float flMonsterDeathSprFrameRate = 20.0f;
//spr缩放
const float flSprScale = 2.0f;
//向上抬起速度
const float flMonsterDeathLiftSpeed = 200;
//修改重力
const float flMonsterDeathLiftGravity = 0.4;
//渲染模式
//kRenderNormal 0
//kRenderTransColor 1
//kRenderTransTexture 2
//kRenderGlow 3
//kRenderTransAlpha 4
//kRenderTransAdd 5 
const int iMosnterDeathSprRender = 1;
//音频对应表
const dictionary dicMonsterDeathMap = {
    {"monster_human_grunt", array<string> = {"sprites/svencontra2/deadspray_a.spr", "svencontra2/npcdead_a.wav"}},
    {"monster_human_grunt_ally", array<string> = {"sprites/svencontra2/deadspray_a.spr", "svencontra2/npcdead_b.wav"}},
    {"monster_grunt_repel", array<string> = {"sprites/svencontra2/deadspray_a.spr", "svencontra2/npcdead_a.wav"}},
    {"monster_human_torch_ally", array<string> = {"sprites/svencontra2/deadspray_a.spr", "svencontra2/npcdead_b.wav"}},
    {"monster_hwgrunt", array<string> = {"sprites/svencontra2/deadspray_a.spr", "svencontra2/npcdead_b.wav"}},
    {"monster_headcrab", array<string> = {"sprites/svencontra2/deadspray_c.spr", "svencontra2/npcdead_d.wav"}},
    {"monster_zombie_soldier", array<string> = {"sprites/svencontra2/deadspray_b.spr", "svencontra2/npcdead_c.wav"}},
    {"monster_handgrenade", array<string> = {"sprites/svencontra2/mark.spr", "svencontra2/mark.wav"}},
    {"monster_bullchicken", array<string> = {"sprites/svencontra2/deadspray_b.spr", "svencontra2/npcdead_e.wav"}}
};

void PrecacheAllMonsterDeath(){
    g_Game.PrecacheModel( szMonsterDeathSprPath );
    g_Game.PrecacheGeneric( szMonsterDeathSprPath );

    g_SoundSystem.PrecacheSound( szMosnterDeathSoundPath );
    g_Game.PrecacheGeneric( "sound/" + szMosnterDeathSoundPath );
    array<string>@ aryKey = dicMonsterDeathMap.getKeys();
    for(uint i = 0; i < aryKey.length();i++){
        array<string> aryVal = cast<array<string>>(dicMonsterDeathMap[aryKey[i]]);
        g_Game.PrecacheModel( aryVal[0] );
        g_Game.PrecacheGeneric( aryVal[0] );

        g_SoundSystem.PrecacheSound( aryVal[1] );
        g_Game.PrecacheGeneric( "sound/" + aryVal[1] );
    }
}

void PlayMonsterDeathSpr(EHandle pWho){
    if(!pWho.IsValid())
        return;
    CBaseEntity@ pEntity = pWho.GetEntity();
    string szSpr = szMonsterDeathSprPath;
    string szSound = szMosnterDeathSoundPath;
    if(dicMonsterDeathMap.exists(pEntity.pev.classname)){
        array<string> aryVal = cast<array<string>>(dicMonsterDeathMap[string(pEntity.pev.classname)]);
        szSpr = aryVal[0];
        szSound = aryVal[1];
    }
    g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_WEAPON, szSound, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
    CSprite@ pSpr = g_EntityFuncs.CreateSprite(szSpr, pEntity.pev.origin, true);
    pSpr.AnimateAndDie(flMonsterDeathSprFrameRate);
    pSpr.SetTransparency( kRenderTransAlpha, 255, 255, 255, 255, iMosnterDeathSprRender );
    pSpr.pev.velocity.z = Math.RandomFloat(40, 80);
    pSpr.SetScale( flSprScale );
    g_EntityFuncs.Remove(@pEntity);
}

void SearchAndDestoryMonster(){
    for(uint i = 0; i < aryMonsterList.length(); i ++){
        if(aryMonsterList[i].IsValid()){
            if(!aryMonsterList[i].GetEntity().IsAlive()){
                aryMonsterList[i].GetEntity().pev.velocity.z += flMonsterDeathLiftSpeed;
                aryMonsterList[i].GetEntity().pev.gravity = flMonsterDeathLiftGravity;
                g_Scheduler.SetTimeout("PlayMonsterDeathSpr", flMonsterDeathSprRemoveDelay, aryMonsterList[i]);
                aryMonsterList.removeAt(i);
            }
        }
        else
            aryMonsterList.removeAt(i);
    }
}

void InitMonsterList(){
    CBaseEntity@ pEntity = null;
    while((@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "monster_*")) !is null){
        if(pEntity.IsMonster() && pEntity.IsAlive())
            aryMonsterList.insertLast(EHandle(@pEntity));
    }
}
