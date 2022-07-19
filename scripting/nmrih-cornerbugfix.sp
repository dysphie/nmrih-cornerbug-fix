// TODO: 
// - Patch Ray_t::b_isRay to be 1 on Linux

#pragma semicolon 1
#pragma newdecls required

#define URL "https://github.com/dysphie/nmrih-cornerbug-fix"
#define PREFIX "[CornerBugFix] "

public Plugin myinfo = 
{
	name        = "Cornerbug Exploit Fix",
	author      = "Dysphie",
	description = "Fix exploit abusing corner geometry to take no damage from NPCs",
	version     = "1.3.2",
	url         = URL
};

// This basically turns the tracehulls created by CanAttackEntity and ClawAttack into tracerays
// This prevents LOS checks from hitting world geometry instead of the player

ConVar cvPatch;

Address clawAttackFn;
Address canAttackEntityFn;

#define OS_WINDOWS 0
#define OS_LINUX 1

int os = -1;
bool patched;

int linux_CanAttackEntity_isRay;
int linux_CanAttackEntity_ExtentsX;
int linux_CanAttackEntity_ExtentsY;
int linux_CanAttackEntity_ExtentsZ;

int linux_ClawAttack_isRay;
int linux_ClawAttack_ExtentsX;
int linux_ClawAttack_ExtentsY;
int linux_ClawAttack_ExtentsZ;

int windows_CanAttackEntity_MinsX;
int windows_CanAttackEntity_MinsY;
int windows_CanAttackEntity_MinsZ;
int windows_CanAttackEntity_MaxsX;
int windows_CanAttackEntity_MaxsY;
int windows_CanAttackEntity_MaxsZ;

int windows_ClawAttack_MinsX;
int windows_ClawAttack_MinsY;
int windows_ClawAttack_MinsZ;
int windows_ClawAttack_MaxsX;
int windows_ClawAttack_MaxsY;
int windows_ClawAttack_MaxsZ;

public void OnPluginStart()
{
	GameData gamedata = new GameData("cornerbugfix.games");
	if (!gamedata)
		SetFailState("Failed to locate gamedata file");

	os = gamedata.GetOffset("Operating System");

	if (os == OS_WINDOWS)
	{
		windows_CanAttackEntity_MinsX = GetKeyIntOrFail(gamedata, "windows_CanAttackEntity_MinsX");
		windows_CanAttackEntity_MinsY = GetKeyIntOrFail(gamedata, "windows_CanAttackEntity_MinsY");
		windows_CanAttackEntity_MinsZ = GetKeyIntOrFail(gamedata, "windows_CanAttackEntity_MinsZ");
		windows_CanAttackEntity_MaxsX = GetKeyIntOrFail(gamedata, "windows_CanAttackEntity_MaxsX");
		windows_CanAttackEntity_MaxsY = GetKeyIntOrFail(gamedata, "windows_CanAttackEntity_MaxsY");
		windows_CanAttackEntity_MaxsZ = GetKeyIntOrFail(gamedata, "windows_CanAttackEntity_MaxsZ");

		windows_ClawAttack_MinsX = GetKeyIntOrFail(gamedata, "windows_ClawAttack_MinsX");
		windows_ClawAttack_MinsY = GetKeyIntOrFail(gamedata, "windows_ClawAttack_MinsY");
		windows_ClawAttack_MinsZ = GetKeyIntOrFail(gamedata, "windows_ClawAttack_MinsZ");
		windows_ClawAttack_MaxsX = GetKeyIntOrFail(gamedata, "windows_ClawAttack_MaxsX");
		windows_ClawAttack_MaxsY = GetKeyIntOrFail(gamedata, "windows_ClawAttack_MaxsY");
		windows_ClawAttack_MaxsZ = GetKeyIntOrFail(gamedata, "windows_ClawAttack_MaxsZ");	
	}
	else if (os == OS_LINUX)
	{
		linux_CanAttackEntity_isRay = GetKeyIntOrFail(gamedata, "linux_CanAttackEntity_isRay");
		linux_CanAttackEntity_ExtentsX = GetKeyIntOrFail(gamedata, "linux_CanAttackEntity_ExtentsX");
		linux_CanAttackEntity_ExtentsY = GetKeyIntOrFail(gamedata, "linux_CanAttackEntity_ExtentsY");
		linux_CanAttackEntity_ExtentsZ = GetKeyIntOrFail(gamedata, "linux_CanAttackEntity_ExtentsZ");

		linux_ClawAttack_isRay = GetKeyIntOrFail(gamedata, "linux_ClawAttack_isRay");
		linux_ClawAttack_ExtentsX = GetKeyIntOrFail(gamedata, "linux_ClawAttack_ExtentsX");
		linux_ClawAttack_ExtentsY = GetKeyIntOrFail(gamedata, "linux_ClawAttack_ExtentsY");
		linux_ClawAttack_ExtentsZ = GetKeyIntOrFail(gamedata, "linux_ClawAttack_ExtentsZ");		
	}
	else
	{
		SetFailState("Unsupported operating system");
	}

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

int GetKeyIntOrFail(GameData gamedata, const char[] key)
{
	char buffer[11];
	if (!gamedata.GetKeyValue(key, buffer, sizeof(buffer)))
		SetFailState("Failed to get offset %s", key);

	int offs;
	if (StringToIntEx(buffer, offs) != strlen(buffer))
		SetFailState("Expected numerical offset, got %s", buffer);

	return offs;
}

public void OnConfigsExecuted()
{
	if (cvPatch.BoolValue)
		Patch();

	cvPatch.AddChangeHook(OnPatchToggle);
}

public void OnPatchToggle(ConVar convar, const char[] oldValue, const char[] newValue)
{
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
	if (!patched)
		return;
	
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
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_isRay, 0, 1);
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_ExtentsX, 0x41, 0);
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_ExtentsY, 0x41, 0);
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_ExtentsZ, 0x41, 0);

	PatchByte(clawAttackFn, linux_ClawAttack_isRay, 0, 1);
	PatchByte(clawAttackFn, linux_ClawAttack_ExtentsX, 0x41, 0);
	PatchByte(clawAttackFn, linux_ClawAttack_ExtentsY, 0x41, 0);
	PatchByte(clawAttackFn, linux_ClawAttack_ExtentsZ, 0x41, 0);

	patched = true;
	PrintToServer(PREFIX ... "Linux patch applied");
}

void UnpatchLinux()
{
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_isRay, 1, 0);
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_ExtentsX, 0, 0x41);
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_ExtentsY, 0, 0x41);
	PatchByte(canAttackEntityFn, linux_CanAttackEntity_ExtentsZ, 0, 0x41);

	PatchByte(clawAttackFn, linux_ClawAttack_isRay, 1, 0);
	PatchByte(clawAttackFn, linux_ClawAttack_ExtentsX, 0, 0x41);
	PatchByte(clawAttackFn, linux_ClawAttack_ExtentsY, 0, 0x41);
	PatchByte(clawAttackFn, linux_ClawAttack_ExtentsZ, 0, 0x41);

	PrintToServer(PREFIX ... "Linux patch removed");
	patched = false;
}

void PatchWindows()
{
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MinsX, 0x41, 0);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MinsY, 0x41, 0);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MinsZ, 0x41, 0);

	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MaxsX, 0xC1, 0);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MaxsY, 0xC1, 0);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MaxsZ, 0xC1, 0);

	PatchByte(clawAttackFn, windows_ClawAttack_MinsX, 0x41, 0);
	PatchByte(clawAttackFn, windows_ClawAttack_MinsY, 0x41, 0);
	PatchByte(clawAttackFn, windows_ClawAttack_MinsZ, 0x41, 0);

	PatchByte(clawAttackFn, windows_ClawAttack_MaxsX, 0xC1, 0);
	PatchByte(clawAttackFn, windows_ClawAttack_MaxsY, 0xC1, 0);
	PatchByte(clawAttackFn, windows_ClawAttack_MaxsZ, 0xC1, 0);

	patched = true;
	PrintToServer(PREFIX ... "Windows patch applied");
}

void UnpatchWindows()
{
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MinsX, 0, 0x41);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MinsY, 0, 0x41);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MinsZ, 0, 0x41);

	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MaxsX, 0, 0xC1);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MaxsY, 0, 0xC1);
	PatchByte(canAttackEntityFn, windows_CanAttackEntity_MaxsZ, 0, 0xC1);

	PatchByte(clawAttackFn, windows_ClawAttack_MinsX, 0, 0x41);
	PatchByte(clawAttackFn, windows_ClawAttack_MinsY, 0, 0x41);
	PatchByte(clawAttackFn, windows_ClawAttack_MinsZ, 0, 0x41);

	PatchByte(clawAttackFn, windows_ClawAttack_MaxsX, 0, 0xC1);
	PatchByte(clawAttackFn, windows_ClawAttack_MaxsY, 0, 0xC1);
	PatchByte(clawAttackFn, windows_ClawAttack_MaxsZ, 0, 0xC1);

	PrintToServer(PREFIX ... "Windows patch removed");
	patched = false;
}

void PatchByte(Address addr, int offset, int verify, int patch)
{
	int original = LoadFromAddress(addr + view_as<Address>(offset), NumberType_Int8);
	if (original != verify && original != patch)
	{
		SetFailState("Byte patcher expected %x or %x, got %x. Plugin needs to be updated! Check " ... URL, verify, patch, original);
		return;
	}

	StoreToAddress(addr + view_as<Address>(offset), patch, NumberType_Int8);
}