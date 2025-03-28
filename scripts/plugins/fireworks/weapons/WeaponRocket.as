namespace Fireworks
{

class FireworkWeaponRocket : BaseWeaponLayer, BaseWeapon
{
	protected float animDrawTime = 0.66f;
	protected float animIdleTime = 3.61f;
	protected float animWindTime = 0.39f;
	protected float animThrowTime = 0.74f;

	void Spawn()
	{
		MakeSpawn(Vector(-3, -3, -0), Vector(3, 3, 40));
		self.pev.body = 2;
		self.FallInit();
		self.m_iDefaultAmmo = 2;
	}

	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1 = 50;
		info.iAmmo1Drop = 1;
		info.iMaxAmmo2 = -1;
		info.iAmmo2Drop = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 7;
		info.iPosition = 24;
		info.iFlags = ITEM_FLAG_EXHAUSTIBLE;
		info.iWeight = 1;
		info.iId = g_ItemRegistry.GetIdForName(self.pev.classname);

		return true;
	}

	bool Deploy()
	{
		return Deploy("models/fireworks/v_pop.mdl", "models/fireworks/p_pop.mdl", FW_WEP_DRAW, "hive", animDrawTime);
	}

	void Throw()
	{
		ThrowEntity("fw_rocket");
	}

	int SafetyCheck()
	{
		return SafeToMake(2);
	}
}

}