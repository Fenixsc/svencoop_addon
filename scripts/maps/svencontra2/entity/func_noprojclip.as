const int SF_TRIG_PUSH_ONCE = 1;
const int SF_TRIGGER_PUSH_START_OFF = 2;
class CNoProjClip : ScriptBaseEntity{
    void Spawn(){
        if ( self.pev.angles == g_vecZero )
            self.pev.angles.y = 360;
        if (self.pev.angles != g_vecZero){
            if (self.pev.angles == Vector(0, -1, 0))
                self.pev.movedir = Vector(0, 0, 1);
            else if (self.pev.angles == Vector(0, -2, 0))
                self.pev.movedir = Vector(0, 0, -1);
            else{
                Math.MakeVectors(self.pev.angles);
                self.pev.movedir = g_Engine.v_forward;
            }
            self.pev.angles = g_vecZero;
        }
        self.pev.solid = SOLID_TRIGGER;
        self.pev.movetype = MOVETYPE_NONE;
        g_EntityFuncs.SetModel(self, self.pev.model);

        if ( g_EngineFuncs.CVarGetFloat("showtriggers") == 0 )
            self.pev.effects |= EF_NODRAW;
        if (self.pev.speed == 0)
            self.pev.speed = 100;

        if ( self.pev.spawnflags & SF_TRIGGER_PUSH_START_OFF != 0 )
            self.pev.solid = SOLID_NOT;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );
    }
    void Touch(CBaseEntity@ pOther){
        if(!pOther.IsPlayer())
            return;
        entvars_t@ pevToucher = pOther.pev;
        switch( pevToucher.movetype ){
            case MOVETYPE_NONE:
            case MOVETYPE_PUSH:
            case MOVETYPE_NOCLIP:
            case MOVETYPE_FOLLOW:
            return;
        }

        if ( pevToucher.solid != SOLID_NOT && pevToucher.solid != SOLID_BSP ){
            if (self.pev.spawnflags & SF_TRIG_PUSH_ONCE != 0){
                pevToucher.velocity = pevToucher.velocity + (self.pev.speed * self.pev.movedir);
                if ( pevToucher.velocity.z > 0 )
                    pevToucher.flags &= ~FL_ONGROUND;
                g_EntityFuncs.Remove( self );
            }
            else{
                Vector vecPush = (self.pev.speed * self.pev.movedir);
                if ( pevToucher.flags & FL_BASEVELOCITY != 0 )
                    vecPush = vecPush +  pevToucher.basevelocity;
                pevToucher.basevelocity = vecPush;
                pevToucher.flags |= FL_BASEVELOCITY;
            }
        }
    }
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f){
        if (self.pev.solid == SOLID_NOT){
            self.pev.solid = SOLID_TRIGGER;
            g_Engine.force_retouch++;
        }
        else
            self.pev.solid = SOLID_NOT;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );
    }
    int ObjectCaps() { 
        return BaseClass.ObjectCaps() & ~FCAP_ACROSS_TRANSITION; 
    }
}
