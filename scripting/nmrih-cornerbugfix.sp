// TODO: 
// - Patch Ray_t::b_isRay to be 1 on Linux

#pragma semicolon 1
#pragma newdecls required

#define PREFIX "[CornerBugFix] "

public Plugin myinfo = 
{
	name        = "Cornerbug Exploit Fix",
	author      = "Dysphie",
	description = "Fix exploit abusing corner geometry to take no damage from NPCs",
	version     = "1.3.0",
	url         = "https://forums.alliedmods.net/showthread.php?p=2747413"
};

ConVar cvPatch;

Address clawAttackFn;
Address canAttackEntityFn;

#define OS_WINDOWS 0
#define OS_LINUX 1

int os = -1;
bool patched;

public void OnPluginStart()
{
	GameData gamedata = new GameData("corner15.games");
	if (!gamedata)
		SetFailState("Failed to locate gamedata file");

	os = gamedata.GetOffset("Operating System");
	if (os != OS_WINDOWS && os != OS_LINUX)
		SetFailState("Unsupported operating system");

	clawAttackFn = gamedata.GetAddress("CNMRiH_BaseZombie::ClawAttack");
	if (!clawAttackFn)
		SetFailState("Failed to resolve address for CNMRiH_BaseZombie::ClawAttack");

	canAttackEntityFn = gamedata.GetAddress("CNMRiH_BaseZombie::CanAttackEntity");
	if (!canAttackEntityFn)
		SetFailState("Failed to resolve address for CNMRiH_BaseZombie::ClawAttack");

	delete gamedata;

	cvPatch = CreateConVar("sm_cornerbug_fix", "1", "Toggle the patch on and off");
	AutoExecConfig();
}

public void OnConfigsExecuted()
{
	if (cvPatch.BoolValue)
		Patch();

	cvPatch.AddChangeHook(OnPatchToggle);
}

public void OnPatchToggle(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PrintToServer("OnPatchToggle");
	if (cvPatch.BoolValue)
		Patch();
	else
		Unpatch();
}

void Patch()
{
	if (patched)
		return;

	if (os == OS_WINDOWS)
		PatchWindows();
	else if (os == OS_LINUX)
		PatchLinux();
}

void Unpatch()
{
	if (os == OS_WINDOWS)
		UnpatchWindows();
	else if (os == OS_LINUX)
		UnpatchLinux();
}

public void OnPluginEnd()
{
	Unpatch();
}

void PatchLinux()
{
	PatchByte(canAttackEntityFn, 0x710, 0x41, 0x00);
	PatchByte(canAttackEntityFn, 0x71A, 0x41, 0x00);
	PatchByte(canAttackEntityFn, 0x724, 0x41, 0x00);


	PatchByte(clawAttackFn, 0x130, 0x41, 0x00);
	PatchByte(clawAttackFn, 0x13E, 0x41, 0x00);
	PatchByte(clawAttackFn, 0x154, 0x41, 0x00);

	patched = true;
	PrintToServer(PREFIX ... "Linux patch applied");
}

void UnpatchLinux()
{
	PatchByte(canAttackEntityFn, 0x710, 0x00, 0x41, false);
	PatchByte(canAttackEntityFn, 0x71A, 0x00, 0x41, false);
	PatchByte(canAttackEntityFn, 0x724, 0x00, 0x41, false);

	PatchByte(clawAttackFn, 0x130, 0x00, 0x41, false);
	PatchByte(clawAttackFn, 0x13E, 0x00, 0x41, false);
	PatchByte(clawAttackFn, 0x154, 0x00, 0x41, false);

	PrintToServer(PREFIX ... "Linux patch removed");
	patched = false;
}

void PatchWindows()
{
	PatchByte(canAttackEntityFn, 0x40A, 0x41, 0x00);
	PatchByte(canAttackEntityFn, 0x417, 0x41, 0x00);
	PatchByte(canAttackEntityFn, 0x423, 0x41, 0x00);

	PatchByte(canAttackEntityFn, 0x42D, 0xC1, 0x00);
	PatchByte(canAttackEntityFn, 0x446, 0xC1, 0x00);
	PatchByte(canAttackEntityFn, 0x457, 0xC1, 0x00);

	PatchByte(clawAttackFn, 0x0F9, 0x41, 0x00);
	PatchByte(clawAttackFn, 0x103, 0x41, 0x00);
	PatchByte(clawAttackFn, 0x116, 0x41, 0x00);

	PatchByte(clawAttackFn, 0x121, 0xC1, 0x00);
	PatchByte(clawAttackFn, 0x12B, 0xC1, 0x00);
	PatchByte(clawAttackFn, 0x132, 0xC1, 0x00);

	patched = true;
	PrintToServer(PREFIX ... "Windows patch applied");
}

void UnpatchWindows()
{
	PatchByte(canAttackEntityFn, 0x40A, 0x00, 0x41, false);
	PatchByte(canAttackEntityFn, 0x417, 0x00, 0x41, false);
	PatchByte(canAttackEntityFn, 0x423, 0x00, 0x41, false);

	PatchByte(canAttackEntityFn, 0x42D, 0x00, 0xC1, false);
	PatchByte(canAttackEntityFn, 0x446, 0x00, 0xC1, false);
	PatchByte(canAttackEntityFn, 0x457, 0x00, 0xC1, false);

	PatchByte(clawAttackFn, 0x0F9, 0x00, 0x41, false);
	PatchByte(clawAttackFn, 0x103, 0x00, 0x41, false);
	PatchByte(clawAttackFn, 0x116, 0x00, 0x41, false);

	PatchByte(clawAttackFn, 0x121, 0x00, 0xC1, false);
	PatchByte(clawAttackFn, 0x12B, 0x00, 0xC1, false);
	PatchByte(clawAttackFn, 0x132, 0x00, 0xC1, false);

	PrintToServer(PREFIX ... "Windows patch removed");
	patched = false;
}

void PatchByte(Address addr, int offset, int verify, int patch, bool raise = true)
{
	int original = LoadFromAddress(addr + view_as<Address>(offset), NumberType_Int8);
	if (original != verify && original != patch)
	{
		if (raise)
			SetFailState("Byte patcher expected %x or %x, got %x. Plugin likely outdated", verify, patch, original);
		return;
	}

	StoreToAddress(addr + view_as<Address>(offset), patch, NumberType_Int8);
}