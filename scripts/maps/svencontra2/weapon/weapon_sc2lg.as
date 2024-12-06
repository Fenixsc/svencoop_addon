namespace ProjBulletTouch{
    void LaserGunFirstShotTouch(CProjBullet@ pThis, CBaseEntity@ pOther){
        pThis.pev.velocity = g_vecZero;
    }
    void LaserGunShotTouch(CProjBullet@ pThis, CBaseEntity@ pOther){
        ProjBulletTouch::DefaultDirectTouch(@pThis, @pOther);
        if(pOther.IsBSPModel()){
            TraceResult tr;
            Vector vecStart = pThis.pev.origin;
            Vector vecEnd = vecStart + pThis.pev.velocity;
            g_Utility.TraceHull(vecStart, vecEnd, missile, point_hull, pThis.self.edict(), tr);
            g_WeaponFuncs.DecalGunshot(tr, BULLET_PLAYER_EAGLE);
            g_Utility.Sparks(vecStart);
        }
        ProjBulletTouch::DefaultPostTouch(@pThis, @pOther);
    }
    void LaserGunLastShotTouch(CProjBullet@ pThis, CBaseEntity@ pOther){
        ProjBulletTouch::DefaultDirectTouch(@pThis, @pOther);
        NetworkMessage kbm(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
            kbm.WriteByte(TE_KILLBEAM);
            kbm.WriteShort(pThis.self.entindex());
        kbm.End();
        CBaseEntity@ pFirst = g_EntityFuncs.Instance(pThis.pev.euser2);
        g_EntityFuncs.Remove(pFirst);
        ProjBulletTouch::DefaultPostTouch(@pThis, @pOther);
    }
}

class  weapon_sc2lg : CBaseContraWeapon{
    //激光宽度
    private uint8 uiBeamWidth = 40;
    //激光SPR
    private string szBeamSpr = "sprites/svencontra2/lgbeam.spr";
    //激光伤害间隔
    private float flShotFireInterv = 0.01;
    //激光伤害总数
    private int iShotMaxFire = 10;

    private int iShotFire = iShotMaxFire;
    private bool bInFiring = false;
    private EHandle eFirst;
    private Vector vecOldVel;
    weapon_sc2lg(){
        szVModel = "models/svencontra2/v_sc2lg.mdl";
        szPModel = "models/svencontra2/wp_sc2lg.mdl";
        szWModel = "models/svencontra2/wp_sc2lg.mdl";
        szShellModel = "models/saw_shell.mdl";
        szFloatFlagModel = "sprites/svencontra2/icon_sc2lg.spr";

        iMaxAmmo = 100;
        iMaxAmmo2 = 6;
        iDefaultAmmo = 50;
        iSlot = 3;
        iPosition = 21;

        flDeployTime = 0.8f;
        flPrimeFireTime = 1.0f;

        szWeaponAnimeExt = "m16";

        iDeployAnime = 8;
        iReloadAnime = 0;
        aryFireAnime = {5, 6};
        aryIdleAnime = {0, 1};

        szFireSound = "weapons/svencontra2/shot_lg.wav";

        flBulletSpeed = 4000;
        flDamage = g_WeaponDMG.LG;
        vecPunchX = Vector2D(-1,1);
        vecPunchY = Vector2D(-1,1);
        vecEjectOffset = Vector(24,8,-5);
    }
    void Precache() override{
        g_SoundSystem.PrecacheSound( "weapons/svencontra2/shot_lg.wav" );
        g_Game.PrecacheGeneric( "sound/weapons/svencontra2/shot_lg.wav" );

        g_Game.PrecacheModel(szBeamSpr);
        g_Game.PrecacheGeneric( szBeamSpr );
        g_Game.PrecacheModel("sprites/svencontra2/hud_sc2lg.spr");
        g_Game.PrecacheGeneric( "sprites/svencontra2/hud_sc2lg.spr" );
        g_Game.PrecacheGeneric( "sprites/svencontra2/weapon_sc2lg.txt" );

        CBaseContraWeapon::Precache();
    }
    bool CanHolster(){
        return !bInFiring;
    }
    void KillBeam(int entindex){
        NetworkMessage kbm(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
            kbm.WriteByte(TE_KILLBEAM);
            kbm.WriteShort(entindex);
        kbm.End();
    }
    void KillBeam(CBaseEntity@ pWho){
        KillBeam(pWho.entindex());
    }
    void EntBeam(int eindex1, int eindex2){
        NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
            m.WriteByte(TE_BEAMENTS);
            m.WriteShort(eindex1);
            m.WriteShort(eindex2);
            m.WriteShort(g_EngineFuncs.ModelIndex(szBeamSpr));
            m.WriteByte(0);
            m.WriteByte(0);
            m.WriteByte(255);
            m.WriteByte(uiBeamWidth);
            m.WriteByte(0);
            m.WriteByte(255);
            m.WriteByte(255);
            m.WriteByte(255);
            m.WriteByte(255); // actually brightness
            m.WriteByte(0);
        m.End();
    }
    void Holster(int skiplocal){
        KillBeam(m_pPlayer.entindex() + 4096);
        bInFiring = false;
        CBaseContraWeapon::Holster(skiplocal);
    }
    void PrimaryAttack() override{
        KillBeam(m_pPlayer.entindex() + 4096);
        CBaseContraWeapon::PrimaryAttack();
        self.m_flNextSecondaryAttack = WeaponTimeBase() + flPrimeFireTime;
    }
    void SecondaryAttack() override{
        PrimaryAttack();
    }
    CProjBullet@ CreateIvisibleProj(){
        CProjBullet@ pBullet = cast<CProjBullet@>(CastToScriptClass(g_EntityFuncs.CreateEntity( BULLET_REGISTERNAME, null,  false)));
        g_EntityFuncs.SetOrigin( pBullet.self, m_pPlayer.GetGunPosition() );
        @pBullet.pev.owner = @m_pPlayer.edict();
        pBullet.pev.dmg = flDamage;
        g_EntityFuncs.DispatchSpawn( pBullet.self.edict() );
        //不能用no_draw与model=0, 否则将不会被绘制
        pBullet.pev.rendermode = kRenderTransAdd;
        pBullet.pev.renderamt = 0;
        return @pBullet;
    }
    void CreateProj(int pellet = 1) override{
        bInFiring = true;
        SetThink(ThinkFunction(ShotFireThink));
        self.pev.nextthink = WeaponTimeBase() + flShotFireInterv;
        CProjBullet@ pBullet = CreateIvisibleProj();
        pBullet.pev.velocity = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ) * flBulletSpeed;
        pBullet.pev.angles = Math.VecToAngles( pBullet.pev.velocity );
        EntBeam(pBullet.self.entindex(), m_pPlayer.entindex() + 4096);
        @pBullet.pTouchFunc = ProjBulletTouch::LaserGunFirstShotTouch;
        vecOldVel = pBullet.pev.velocity;
        eFirst = EHandle(pBullet.self);
    }
    void ShotFireThink(){
        CProjBullet@ pBullet = CreateIvisibleProj();
        pBullet.pev.velocity = vecOldVel;
        if(iShotFire > 0){
            @pBullet.pTouchFunc = ProjBulletTouch::LaserGunShotTouch;
            iShotFire--;
            self.pev.nextthink = WeaponTimeBase() + flShotFireInterv;
        } 
        else{
            if(eFirst.IsValid()){
                @pBullet.pTouchFunc = ProjBulletTouch::LaserGunLastShotTouch;
                CBaseEntity@ pEntity = eFirst.GetEntity();
                @pBullet.pev.euser2 = pEntity.edict();
                KillBeam(pEntity.entindex());
                EntBeam(pEntity.entindex(), pBullet.self.entindex());
            }
            iShotFire = iShotMaxFire;
            bInFiring = false;
        }
    }
}
