# [NMRiH] Cornerbug Exploit Fix

Fixes an exploit where players abuse corner geometry to take no damage from NPCs

[AlliedModders thread](https://forums.alliedmods.net/showthread.php?p=2747413)


![image](https://user-images.githubusercontent.com/11559683/131224829-912643e3-c0aa-4aa3-9e2f-201135e675a9.png)


## ConVars
- `sm_cornerbug_fix` (1/0) (Default: 1)
  - Enables or disables the patch

## Notes
- This fix has the side effect of allowing zombies to attack through prison bars. From my playtesting this isn't a big deal, though.

## Technical Explanation

The fix works by reducing the dimensions of pre-attack and attack hull traces to 0, effectively turning them into rays.
This allows traces to squeeze through geometry that would otherwise block them.

![image](https://user-images.githubusercontent.com/11559683/131224708-7199d5b9-9e79-4a08-8da4-dbde381cc1c3.png)

