/*
kSpawnItem 生成物品名称
kReverseTime 气球上下反装时间
kBaloonFloatSpeed 气球上下移动速度
kSprPath 爆炸spr路径
kSprScale 爆炸spr缩放
kSoundPath 爆炸音效路径
kShowName 显示名称
speed 飞行速度
model 模型路径
target info_target名称
*/
//生成时自动触发
const int SF_WEAPONBALLON_STARTSPAWN = 1;

class CWeaponBalloon : ScriptBaseMonsterEntity{
    private bool bInUp = true;
    private string szSpawnItem = "";
    private string szSprPath = "";
    private int iSprScale = 10;
    private string szSoundPath = "";
    private float flDestoryTime;
    private int iFlyReverseTime = 4;
    private float flBaloonUpSpeed = 16.0f;
    private float flInitVelocityZ;
    private CScheduledFunction@ pDestoryScheduler = null;

    bool KeyValue(const string& in szKeyName, const string& in szValue){
        if(szKeyName == "kSpawnItem"){
            szSpawnItem = szValue;
            return true;
        }
        else if(szKeyName == "kReverseTime"){
            iFlyReverseTime = atoi(szValue);
            return true;
        }
        else if(szKeyName == "kBaloonFloatSpeed"){
            flBaloonUpSpeed = atof(szValue);
            return true;
        }
        else if(szKeyName == "kSprPath"){
            szSprPath = szValue;
            return true;
        }
        else if(szKeyName == "kSprScale"){
            iSprScale = int(atof(szValue) * 10.0f);
            return true;
        }
        else if(szKeyName == "kSoundPath"){
            szSoundPath = szValue;
            return true;
        }
        else if(szKeyName == "kShowName"){
            self.m_FormattedName = szValue;
            return true;
        }
        return BaseClass.KeyValue(szKeyName, szValue);
    }
    void Precache(){
        if( string( self.pev.model ).IsEmpty() )
            g_Game.PrecacheModel( "models/common/lambda.mdl" );
        else{
            g_Game.PrecacheModel( self.pev.model );
            g_Game.PrecacheGeneric( self.pev.model );
        }
        g_Game.PrecacheModel( szSprPath );
        g_Game.PrecacheGeneric( szSprPath );
        g_SoundSystem.PrecacheSound( szSoundPath );
        g_Game.PrecacheGeneric( "sound/" + szSoundPath );
    }
    void Init(){
        CBaseEntity@ pEntity = self.GetNextTarget();
        if(@pEntity is null){
            g_EntityFuncs.Remove(self);
            return;
        }
        Vector vecLine = pEntity.pev.origin - self.pev.origin;
        self.pev.angles = Math.VecToAngles(vecLine.Normalize());
        flDestoryTime = float(vecLine.Length()) / self.pev.speed;
        self.pev.velocity = vecLine.Normalize() * self.pev.speed;
        flInitVelocityZ = self.pev.velocity.z;
        self.pev.velocity.z += flBaloonUpSpeed;
        self.pev.nextthink = g_Engine.time + iFlyReverseTime / 2;

        self.pev.movetype = MOVETYPE_FLY;
        self.pev.solid = SOLID_SLIDEBOX;
        self.pev.effects &= ~EF_NODRAW;
        self.pev.takedamage = DAMAGE_YES;

        self.pev.health = self.pev.max_health = 1;

        g_EntityFuncs.SetModel( self, string( self.pev.model ).IsEmpty() ? "models/common/lambda.mdl" : string(self.pev.model) );
        g_EntityFuncs.SetSize( self.pev, Vector(-16,-16,-16), Vector(16, 16, 16));

        @pDestoryScheduler = g_Scheduler.SetTimeout(this, "Remove", flDestoryTime);
    }
    void Remove(){
        if(self !is null)
            g_EntityFuncs.Remove(self);
    }
    void Spawn(){
        if(szSpawnItem.IsEmpty())
            return;
        Precache();

        if(self.pev.spawnflags & SF_WEAPONBALLON_STARTSPAWN != 0)
            Init();
        else{
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.solid = SOLID_NOT;
            self.pev.effects |= EF_NODRAW;
        }
        g_EntityFuncs.SetOrigin( self, self.pev.origin );
        BaseClass.Spawn();
    }
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f){
        Init();
    }
    void Think(){
        self.pev.velocity.z = flInitVelocityZ + (bInUp ? -flBaloonUpSpeed : flBaloonUpSpeed);
        bInUp = !bInUp;      
        self.pev.nextthink = g_Engine.time + iFlyReverseTime;
    }
    void Killed(entvars_t@ pevAttacker, int iGib){
        BaseClass.Killed(pevAttacker, iGib);

        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, szSoundPath, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

        NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
            m.WriteByte(TE_EXPLOSION);
            m.WriteCoord(self.pev.origin.x);
            m.WriteCoord(self.pev.origin.y);
            m.WriteCoord(self.pev.origin.z);
            m.WriteShort(g_EngineFuncs.ModelIndex(szSprPath));
            m.WriteByte(iSprScale);
            m.WriteByte(15);
            m.WriteByte(0);
        m.End();

        CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity(szSpawnItem, 
            dictionary = {
                {"origin", self.pev.origin.ToString()},
                {"angles", self.pev.angles.ToString()},
                {"m_flCustomRespawnTime", "-1"},
                {"IsNotAmmoItem", "1"}
            }, false);
        @pEntity.pev.owner = self.edict();
        g_EntityFuncs.DispatchSpawn(pEntity.edict());
        SetThink(null);
        g_Scheduler.RemoveTimer(@pDestoryScheduler);
        g_EntityFuncs.Remove(self);
    }
}