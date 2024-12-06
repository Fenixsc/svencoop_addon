 class  weapon_sc2ar : CBaseContraWeapon{
     private bool bInRecharg = false;
     private float flRechargInterv = 0.02;
     private string szGrenadeSpr = "sprites/svencontra2/bullet_gr.spr";
     private string szGrenadeFireSound = "weapons/svencontra2/shot_gr.wav";
     weapon_sc2ar(){
        szVModel = "models/svencontra2/v_sc2ar.mdl";
        szPModel = "models/svencontra2/wp_sc2ar.mdl";
        szWModel = "models/svencontra2/wp_sc2ar.mdl";
        szShellModel = "models/saw_shell.mdl";
        szFloatFlagModel = "sprites/svencontra2/icon_sc2ar.spr";
        iMaxAmmo = 100;
        iMaxAmmo2 = 6;
        iDefaultAmmo = 100;
        iSlot = 1;
        iPosition = 20;

        flDeployTime = 0.8f;
        flPrimeFireTime = 0.11f;
        flSecconaryFireTime = 1.5f;

        szWeaponAnimeExt = "m16";

        iDeployAnime = 4;
        iReloadAnime = 3;
        aryFireAnime = {5, 6, 7};
        aryIdleAnime = {0, 1};

        szFireSound = "weapons/svencontra2/shot_ar.wav";

        flBulletSpeed = 1900;
        flDamage = g_WeaponDMG.AR;
        vecPunchX = Vector2D(-1,1);
        vecPunchY = Vector2D(-1,1);
        vecEjectOffset = Vector(24,8,-5);
     }
     void Precache() override{
        g_SoundSystem.PrecacheSound( "weapons/svencontra2/shot_ar.wav" );
        g_SoundSystem.PrecacheSound( "weapons/svencontra2/shot_gr.wav" );
        g_SoundSystem.PrecacheSound( szGrenadeFireSound );
        g_Game.PrecacheGeneric( "sound/" + szGrenadeFireSound );
        g_Game.PrecacheGeneric( "sound/weapons/svencontra2/shot_ar.wav" );
        g_Game.PrecacheGeneric( "sound/weapons/svencontra2/shot_gr.wav" );

        g_Game.PrecacheModel("sprites/svencontra2/bullet_ar.spr");
        g_Game.PrecacheModel("sprites/svencontra2/bullet_gr.spr");
        g_Game.PrecacheModel("sprites/svencontra2/hud_sc2ar.spr");
        g_Game.PrecacheModel(szGrenadeSpr);
        g_Game.PrecacheGeneric( szGrenadeSpr );
        g_Game.PrecacheGeneric( "sprites/svencontra2/bullet_ar.spr" );
        g_Game.PrecacheGeneric( "sprites/svencontra2/bullet_gr.spr" );
        g_Game.PrecacheGeneric( "sprites/svencontra2/hud_sc2ar.spr" );

        g_Game.PrecacheGeneric( "sprites/svencontra2/weapon_sc2ar.txt" );

        CBaseContraWeapon::Precache();
     }
     void Holster(int skiplocal){
         bInRecharg = false;
         CBaseContraWeapon::Holster(skiplocal);
     }
     void CreateProj(int pellet = 1) override{
        CProjBullet@ pBullet = cast<CProjBullet@>(CastToScriptClass(g_EntityFuncs.CreateEntity( BULLET_REGISTERNAME, null,  false)));
        g_EntityFuncs.SetOrigin( pBullet.self, m_pPlayer.GetGunPosition() );
        @pBullet.pev.owner = @m_pPlayer.edict();
        pBullet.pev.model = "sprites/svencontra2/bullet_ar.spr";
        pBullet.pev.velocity = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ) * flBulletSpeed;
        pBullet.pev.angles = Math.VecToAngles( pBullet.pev.velocity );
        pBullet.pev.dmg = flDamage;
        g_EntityFuncs.DispatchSpawn( pBullet.self.edict() );
    }
    void RechargeThink(){
        if(m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) >= iMaxAmmo){
            bInRecharg = false;
            SetThink(null);
            return;
        }
        self.PlayEmptySound();
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + 1 );
        self.pev.nextthink = WeaponTimeBase() + flRechargInterv;
    }
    void Recharge(){
        bInRecharg = true;
        SetThink(ThinkFunction(RechargeThink));
        self.pev.nextthink = WeaponTimeBase() + flRechargInterv;
    }
    void PrimaryAttack(){
        if(bInRecharg)
            return;
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && !bInRecharg){
            self.PlayEmptySound();
            Recharge();
            return;
        }
        Fire();
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        self.m_flNextPrimaryAttack = WeaponTimeBase() + flPrimeFireTime;
    }
    void SecondaryAttack() override{    
        if(bInRecharg)
            return;
        if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0){
            self.PlayEmptySound();
            return;
        }    
        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
        m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
        m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;
        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
        m_pPlayer.pev.punchangle.x = -10.0;
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, szGrenadeFireSound, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        self.SendWeaponAnim(GetRandomAnime(aryFireAnime));
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        CGrenade@ pGrenade = g_EntityFuncs.ShootContact( m_pPlayer.pev, 
            m_pPlayer.GetGunPosition() + g_Engine.v_forward * 12 + g_Engine.v_right * 6,  g_Engine.v_forward * 800 );
        g_EntityFuncs.SetModel(@pGrenade, szGrenadeSpr);
        pGrenade.pev.rendermode = kRenderTransAdd;
        pGrenade.pev.renderamt = 255;
        pGrenade.pev.rendercolor = Vector(255, 255, 255);
        pGrenade.pev.avelocity = g_vecZero;

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flSecconaryFireTime;
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;
    }
}
