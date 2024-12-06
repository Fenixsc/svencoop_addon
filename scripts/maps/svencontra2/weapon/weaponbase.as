abstract class CBaseContraWeapon : ScriptBasePlayerWeaponEntity{
    protected CBasePlayer@ m_pPlayer = null;
    protected int iShell = -1;
    
    protected string szWModel;
    protected string szPModel;
    protected string szVModel;
    protected string szShellModel;
    protected string szPickUpSound = "svencontra2/picked.wav";
    protected string szFloatFlagModel;

    protected int iMaxAmmo;
    protected int iMaxAmmo2 = -1;
    protected int iDefaultAmmo;
    protected int iSlot;
    protected int iPosition;

    protected float flDeployTime;
    protected float flPrimeFireTime;
    protected float flSecconaryFireTime;

    protected string szWeaponAnimeExt;
    protected int iDeployAnime;
    protected int iReloadAnime;
    protected array<int> aryFireAnime;
    protected array<int> aryIdleAnime;

    protected string szFireSound;

    protected Vector2D vecPunchX;
    protected Vector2D vecPunchY;
    protected float flBulletSpeed;
    protected float flDamage;
    protected TE_BOUNCE iShellBounce = TE_BOUNCE_SHELL;

    protected Vector vecEjectOffset;

    protected EHandle pFlagEntity = null;
    protected float flFlagHeight = 24;

    void Spawn(){
        Precache();
        g_EntityFuncs.SetModel( self, szWModel );
        self.m_iDefaultAmmo = iDefaultAmmo;
        self.FallInit();
    }
    void Precache(){
        g_SoundSystem.PrecacheSound( "weapons/svencontra2/ar_reload.wav" );
        g_Game.PrecacheGeneric( "sound/weapons/svencontra2/ar_reload.wav" );
        g_SoundSystem.PrecacheSound( szPickUpSound );
        g_Game.PrecacheGeneric( "sound/" + szPickUpSound );
        g_SoundSystem.PrecacheSound( szFireSound );
        g_Game.PrecacheGeneric( "sound/" + szFireSound );

        g_Game.PrecacheModel( szWModel );
        g_Game.PrecacheModel( szPModel );
        g_Game.PrecacheModel( szVModel );
        if(!szShellModel.IsEmpty()){
            iShell = g_Game.PrecacheModel( szShellModel );
            g_Game.PrecacheGeneric( szShellModel );
        }
        if(!szFloatFlagModel.IsEmpty()){
            g_Game.PrecacheModel( szFloatFlagModel );
            g_Game.PrecacheGeneric( szFloatFlagModel );
        }
        g_Game.PrecacheGeneric( szWModel );
        g_Game.PrecacheGeneric( szPModel );
        g_Game.PrecacheGeneric( szVModel );
    }
    bool GetItemInfo( ItemInfo& out info ){
        info.iMaxAmmo1     = iMaxAmmo;
        info.iMaxAmmo2     = iMaxAmmo2;
        info.iMaxClip     = -1;
        info.iSlot         = iSlot;
        info.iPosition     = iPosition;
        info.iFlags     = ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
        info.iWeight     = 998;

        return true;
    }
    bool AddToPlayer( CBasePlayer@ pPlayer ){
        if( !BaseClass.AddToPlayer( pPlayer ) )
            return false;
        @m_pPlayer = pPlayer;    
        NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
            message.WriteLong( self.m_iId );
        message.End();
        g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, szPickUpSound, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        if(pFlagEntity.IsValid())
            g_EntityFuncs.Remove(pFlagEntity);
        return true;
    }
    void Materialize(){
        if(!szFloatFlagModel.IsEmpty() && !pFlagEntity.IsValid()){
            Vector vecOrigin = self.pev.origin;
            vecOrigin.z += flFlagHeight;
            CBaseEntity@ pEntity = g_EntityFuncs.Create(WEAPONFLAG_REGISTERNAME, vecOrigin, self.pev.angles, true, self.edict());
            pEntity.pev.fov = flFlagHeight;
            g_EntityFuncs.SetModel(@pEntity, szFloatFlagModel);
            g_EntityFuncs.DispatchSpawn( pEntity.edict() );
            pFlagEntity = EHandle(pEntity);
        }
        BaseClass.Materialize();
    }
    void UpdateOnRemove(){
        if(pFlagEntity.IsValid())
            g_EntityFuncs.Remove(pFlagEntity);
    }
    void Holster( int skiplocal /* = 0 */ ){    
        SetThink( null );
        BaseClass.Holster();
    }
    bool PlayEmptySound(){
        if( self.m_bPlayEmptySound ){
            self.m_bPlayEmptySound = false;
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/svencontra2/ar_reload.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
        }
        return false;
    }
    bool Deploy(){
        bool bResult = true;
        bResult = self.DefaultDeploy( self.GetV_Model( szVModel ), self.GetP_Model( szPModel ), iDeployAnime, szWeaponAnimeExt );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flDeployTime;
        return bResult;
    }
    int GetRandomAnime(array<int>&in ary){
        return ary[g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed,0,ary.length()-1)];
    }
    void CreateProj(int pellet = 1){
        //Dummy
    }
    void Fire(int pellet = 1){
        CreateProj(pellet);
        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType)-1);
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, szFireSound, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        self.SendWeaponAnim(GetRandomAnime(aryFireAnime));
        m_pPlayer.pev.punchangle.x = Math.RandomFloat( vecPunchX.x, vecPunchX.y );
        m_pPlayer.pev.punchangle.y = Math.RandomFloat( vecPunchY.x, vecPunchY.y );
        if(iShell > -1)
            g_EntityFuncs.EjectBrass( 
                m_pPlayer.GetGunPosition() + g_Engine.v_forward * vecEjectOffset.x + g_Engine.v_right * vecEjectOffset.y + g_Engine.v_up * vecEjectOffset.z, 
                m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomLong(80,120),
                m_pPlayer.pev.angles[1], iShell, iShellBounce );
    }
    void PrimaryAttack(){
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0){
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
            return;
        }
        Fire();
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flPrimeFireTime;
    }
    void SecondaryAttack(){
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0){
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.15f;
            return;
        }
        Fire();
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flSecconaryFireTime;
    }
    void WeaponIdle(){
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
        if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
            return;
        self.SendWeaponAnim(GetRandomAnime(aryIdleAnime));
        self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
    }
    float WeaponTimeBase(){
        return g_Engine.time;
    }
}