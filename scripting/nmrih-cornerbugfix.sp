#include <sourcescramble>

public Plugin myinfo = 
{
	name        = "Cornerbug Exploit Fix",
	author      = "Dysphie",
	description = "",
	version     = "0.3.0",
	url         = "https://forums.alliedmods.net/showthread.php?p=2747413"
};

/* 
 * When a zombie attacks a player it fires a hull of volume 16^3 towards them. If it hits,
 * damage is dealt. If a client hugs a corner then the hull hits world geometry instead.
 * We solve this by resizing the hull to size 0 so it effectively turns into a ray.
 * On Windows the hullMin and hullMax in CNMRiH_BaseZombie::ClawAttack (which are fed to 
 * UTIL_TraceHull) are edited. On Linux the UTIL_TraceHull function is inlined, so the resulting 
 * Ray_t struct is edited directly. Ray_t only stores an equal-sized extent rather than mins 
 * and maxes, so we patch the extent and make Ray_t->m_IsRay true.
 */
public void OnPluginStart()
{
	GameData gamedata = new GameData("cornerbugfix.games");
	if (!gamedata)
		SetFailState("Failed to locate gamedata file");

	char keys[][] = 
	{
		"hullMax.x", "hullMax.y", "hullMax.z", 
		"hullMin.x", "hullMin.y", "hullMin.z",
		"m_isRay", "m_Extents.x", "m_Extents.y", "m_Extents.z"
	}

	for (int i; i < sizeof(keys); i++)
	{
		MemoryPatch patch = MemoryPatch.CreateFromConf(gamedata, keys[i]);
		if (!patch.Enable())
			SetFailState("Failed to patch %s", keys[i]);
	}

	PrintToServer("[Cornerbug Exploit Fix] Applied patch");
	delete gamedata;
}
