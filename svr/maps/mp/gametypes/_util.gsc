disableWeapon() {
    if (self.disabled)
        return;

    self.disabled = true;
    self.pers["storeweapon"] = [];

    self.pers["storeweapon"]["currentweapon"] = self getcurrentweapon();

    weaponSlots = [];
    weaponSlots[0] = "primary";
    weaponSlots[1] = "primaryb";
    weaponSlots[2] = "pistol";
    weaponSlots[3] = "grenade";
    weaponSlots[4] = "smokegrenade";

    for (i = 0; i < weaponSlots.size; i++) {
        slot = weaponSlots[i];
        self.pers["storeweapon"][slot] = self getWeaponSlotWeapon(slot);
        self.pers["storeweapon"][slot + "_clipammo"] = self getWeaponSlotClipAmmo(slot);
        self.pers["storeweapon"][slot + "_ammo"] = self getWeaponSlotAmmo(slot);
    }

    self takeallweapons();
}

enableWeapon() {
    if (!self.disabled)
        return;

    weaponSlots = [];
    weaponSlots[0] = "primary";
    weaponSlots[1] = "primaryb";
    weaponSlots[2] = "pistol";
    weaponSlots[3] = "grenade";
    weaponSlots[4] = "smokegrenade";

    for (i = 0; i < weaponSlots.size; i++) {
        slot = weaponSlots[i];
        if (isDefined(self.pers["storeweapon"][slot])) {
            self setWeaponSlotWeapon(slot, self.pers["storeweapon"][slot]);
            self setWeaponSlotClipAmmo(slot, self.pers["storeweapon"][slot + "_clipammo"]);
            self setWeaponSlotAmmo(slot, self.pers["storeweapon"][slot + "_ammo"]);
        }
    }

    // Handle weapon switching differently for bots vs players
    if (isDefined(self.pers["storeweapon"]["currentweapon"])) {
        if (isDefined(self.isbot) && self.isbot) {
            // For bots, use a different approach to ensure weapon is properly equipped
            // First try to switch to the weapon
            self switchToWeapon(self.pers["storeweapon"]["currentweapon"]);
            
            // Wait a moment for the switch to take effect
            wait 0.1;
            
            // If the current weapon doesn't match what we expect, try switching again
            currentWeapon = self getCurrentWeapon();
            if (isDefined(currentWeapon) && currentWeapon != self.pers["storeweapon"]["currentweapon"]) {
                // Try switching to the primary slot first, then to the target weapon
                if (isDefined(self.pers["storeweapon"]["primary"])) {
                    self switchToWeapon(self.pers["storeweapon"]["primary"]);
                    wait 0.05;
                }
                self switchToWeapon(self.pers["storeweapon"]["currentweapon"]);
            }
        } else {
            // For human players, use the normal approach
            self switchToWeapon(self.pers["storeweapon"]["currentweapon"]);
        }
    }

    self.disabled = false;
}

resetWeapons() {
    self.pers["storeweapon"] = [];
    self.pers["storeweapon"]["currentweapon"] = undefined;

    weaponSlots = [];
    weaponSlots[0] = "primary";
    weaponSlots[1] = "primaryb";
    weaponSlots[2] = "pistol";
    weaponSlots[3] = "grenade";
    weaponSlots[4] = "smokegrenade";

    for (i = 0; i < weaponSlots.size; i++) {
        slot = weaponSlots[i];
        self.pers["storeweapon"][slot] = undefined;
        self.pers["storeweapon"][slot + "_clipammo"] = undefined;
        self.pers["storeweapon"][slot + "_ammo"] = undefined;
    }
}

updateDisabledSlotAfterPickup(slot)
{
    if (!isDefined(self.disabled) || !self.disabled)
        return;

    self.pers["storeweapon"][slot] = self getWeaponSlotWeapon(slot);
    self.pers["storeweapon"][slot + "_clipammo"] = self getWeaponSlotClipAmmo(slot);
    self.pers["storeweapon"][slot + "_ammo"] = self getWeaponSlotAmmo(slot);

    // Always update current weapon
    self.pers["storeweapon"]["currentweapon"] = self getCurrentWeapon();
}