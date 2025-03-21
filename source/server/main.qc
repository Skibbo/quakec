/*
	server/main.qc

	mostly functions that will be called from the engine and are
	expected to exist

	Copyright (C) 2021-2022 NZ:P Team

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

*/

void() LS_Setup;
void() PU_Init;
void() SUB_Remove = {remove(self);}

//called when starting server/loading the map
void() main =
{
	cheats_have_been_activated = false;
	global_trace_damage_multiplier = 1;
}

float ai_delay_time;

//
// Way_SetBrushEntNonSolid(ent_name)
// FIXME: Move this elsewhere..
// Wrapper for finding brush ents of classname
// and making them non-solid. For use only
// with Waypoint Mode.
//
void(string ent_name) Way_SetBrushEntNonSolid =
{
	entity ent = find(world, classname, ent_name);
	while(ent != world) {
		ent.solid = SOLID_NOT;
		ent.touch = SUB_Null;
		ent = find(ent, classname, ent_name);
	}
}

//called for each frame that QC runs
float zombie_cleaned_w;
void() StartFrame =
{
	framecount = framecount + 1;

	if (waypoint_mode) {
		if (!zombie_cleaned_w) {
			entity zent;
			zent = find (world, classname, "ai_zombie");
			while (zent)
			{
				remove (zent);
				zent = find (zent, classname, "ai_zombie");
			}
			zombie_cleaned_w = true;

			zent = find (world, classname, "waypoint");
			while (zent)
			{
				if (zent.targetname)
					setmodel(zent, "models/way/normal_way_door.spr");
				else
					setmodel(zent, "models/way/normal_way.spr");
				zent = find (zent, classname, "waypoint");
			}
			Way_SetBrushEntNonSolid("door_nzp_cost");
			Way_SetBrushEntNonSolid("door_nzp");
			Way_SetBrushEntNonSolid("door");
		}
		return;
	}


	if (roundinit) {
		Round_Core();

		if (ai_delay_time < time) {
			Do_Zombie_AI ();

			// This determines the delay between each AI's update sequence.
			// It needs to be variable -- the more AI, the smaller this number
			// should end up being, or else you'll have AI completely stall
			// waiting for it's chance in the spotlight.
			// -----

#ifdef FTE

			// On FTE, resources are available to make this super short (0.01s,
			// meaning all 24 ai update 4 times a second).
			ai_delay_time = time + 0.01;

#else

			// On other platforms, have this be 0.03 / ai factor / 12.
			// This means that:
			// AI Updates at ~30Hz with 12 Zombies
			// AI Updates at ~45Hz with 18 Zombies
			// AI Updates at ~60Hz with 24 Zombies
			ai_delay_time = time + (0.03 / (nzp_maxai()/12));

#endif // FTE

		}
	} else {
		entity SpawnedIn;
		SpawnedIn = find(world, classname, "player");

		if (SpawnedIn) {
			entity getdog = find(world, classname, "spawn_dog");
			if (getdog)
				gotdog = 1;
			else
				gotdog = 0;

			updateDogRound();
			InitRounds();
		}
	}
}
string(string s) precache_model         = #20;

void() precaches =
{
	precache_model ("models/player.mdl");

	//
	// Models
	//

	// sprites
	precache_model ("models/sprites/sprkle.spr");
	precache_model ("models/sprites/explosion.spr");
	precache_model ("models/sprites/null.spr");

	if (cvar("waypoint_mode")) {
		precache_model ("models/way/current_way.spr");
		precache_model ("models/way/current_way_door.spr");
		precache_model ("models/way/last_way.spr");
		precache_model ("models/way/last_way_door.spr");
		precache_model ("models/way/normal_way.spr");
		precache_model ("models/way/normal_way_door.spr");
		precache_model ("models/way/way_jump.spr");
		precache_model ("models/way/way_land.spr");
	}

	// zombie
	precache_model ("models/ai/zfull.mdl");
	precache_model ("models/ai/zal(.mdl");
	precache_model ("models/ai/zar(.mdl");
	precache_model ("models/ai/zb%.mdl");
	precache_model ("models/ai/zh^.mdl");

	// For debugging zombie AI
	if (cvar("developer")) {
		precache_model ("models/way/normal_way.spr");
	}

	// zombie crawler
	precache_model ("models/ai/zcfull.mdl");
	precache_model ("models/ai/zbc%.mdl");
	precache_model ("models/ai/zalc(.mdl");
	precache_model ("models/ai/zarc(.mdl");
	precache_model ("models/ai/zhc^.mdl");

	// start weapons
	precache_model ("models/weapons/m1911/v_colt.mdl");
	precache_model ("models/weapons/m1911/g_colt.mdl");
	precache_model ("models/weapons/knife/v_knife.mdl");
	precache_model ("models/weapons/grenade/v_grenade.mdl");
	precache_model ("models/weapons/grenade/g_grenade.mdl");

#ifdef FTE

	// FTE only has co-op, so don't precache morphine elsewhere.
	precache_model ("models/weapons/morphine/v_morphine.mdl");

#endif // FTE

	//
	// Sounds
	//

	// player-made

#ifdef FTE

	precache_sound("sounds/player/footstep1.wav");
	precache_sound("sounds/player/footstep2.wav");
	precache_sound("sounds/player/footstep3.wav");
	precache_sound("sounds/player/footstep4.wav");
	precache_sound("sounds/player/footstep5.wav");

#endif // FTE

	precache_sound("sounds/player/jump.wav");
	precache_sound("sounds/player/land.wav");
	precache_sound("sounds/player/pain4.wav");

	// weapons
	precache_sound("sounds/weapons/colt/magin.wav");
	precache_sound("sounds/weapons/colt/magout.wav");
	precache_sound("sounds/weapons/colt/shoot.wav");
	precache_sound("sounds/weapons/colt/slide.wav");

	// grenade
	precache_sound("sounds/weapons/grenade/prime.wav");
	precache_sound("sounds/weapons/grenade/throw.wav");
	precache_sound("sounds/weapons/grenade/explode.wav");

	// melee
	precache_sound("sounds/weapons/knife/knife_hitbod.wav");
	precache_sound("sounds/weapons/knife/knife.wav");
	precache_sound("sounds/weapons/knife/knife_hit.wav");

	// tunes
	precache_sound("sounds/rounds/eround.wav");
	precache_sound("sounds/rounds/nround.wav");
	precache_sound("sounds/rounds/splash.wav");
	precache_sound("sounds/music/end.wav");

	// purchasing
	precache_sound("sounds/misc/buy.wav");
	precache_sound("sounds/misc/denybuy.wav");

	// power-ups
	precache_sound ("sounds/pu/pickup.wav");
	precache_sound ("sounds/pu/powerup.wav");
	precache_sound ("sounds/pu/drop.wav");

	// zombie walk
	precache_sound ("sounds/zombie/w0.wav");
	precache_sound ("sounds/zombie/w1.wav");
	precache_sound ("sounds/zombie/w2.wav");
	precache_sound ("sounds/zombie/w3.wav");
	precache_sound ("sounds/zombie/w4.wav");
	precache_sound ("sounds/zombie/w5.wav");
	precache_sound ("sounds/zombie/w6.wav");
	precache_sound ("sounds/zombie/w7.wav");
	precache_sound ("sounds/zombie/w8.wav");
	precache_sound ("sounds/zombie/w9.wav");

	// zombie run
	precache_sound ("sounds/zombie/r0.wav");
	precache_sound ("sounds/zombie/r1.wav");
	precache_sound ("sounds/zombie/r2.wav");
	precache_sound ("sounds/zombie/r3.wav");
	precache_sound ("sounds/zombie/r4.wav");
	precache_sound ("sounds/zombie/r5.wav");
	precache_sound ("sounds/zombie/r6.wav");
	precache_sound ("sounds/zombie/r7.wav");
	precache_sound ("sounds/zombie/r8.wav");
	precache_sound ("sounds/zombie/r9.wav");

	// zombie swipe
	precache_sound ("sounds/zombie/a0.wav");
	precache_sound ("sounds/zombie/a1.wav");
	precache_sound ("sounds/zombie/a2.wav");
	precache_sound ("sounds/zombie/a3.wav");
	precache_sound ("sounds/zombie/a4.wav");
	precache_sound ("sounds/zombie/a5.wav");
	precache_sound ("sounds/zombie/a6.wav");
	precache_sound ("sounds/zombie/a7.wav");

	// zombie death
	precache_sound ("sounds/zombie/d0.wav");
	precache_sound ("sounds/zombie/d1.wav");
	precache_sound ("sounds/zombie/d2.wav");
	precache_sound ("sounds/zombie/d3.wav");
	precache_sound ("sounds/zombie/d4.wav");
	precache_sound ("sounds/zombie/d5.wav");
	precache_sound ("sounds/zombie/d6.wav");
	precache_sound ("sounds/zombie/d7.wav");

	// zombie taunt
	precache_sound ("sounds/zombie/t0.wav");
	precache_sound ("sounds/zombie/t1.wav");
	precache_sound ("sounds/zombie/t2.wav");
	precache_sound ("sounds/zombie/t3.wav");
	precache_sound ("sounds/zombie/t4.wav");

	// zombie footsteps
	precache_sound ("sounds/zombie/s0.wav");
	precache_sound ("sounds/zombie/s1.wav");
	precache_sound ("sounds/zombie/sc0.wav");
	precache_sound ("sounds/zombie/sc1.wav");

	// null
	precache_sound("sounds/null.wav");
}

//called when map loaded
void() worldspawn =
{
	precaches();

	// Define all of our Light Styles
	LS_Setup();

	// Init Power-Ups
	PU_Init();

#ifdef FTE

	clientstat(STAT_CURRENTMAG, EV_FLOAT, weapons[0].weapon_magazine);
	clientstat(STAT_CURRENTMAG2, EV_FLOAT, weapons[0].weapon_magazine_left);
	clientstat(STAT_POINTS, EV_FLOAT, points);
	clientstat(STAT_WEAPON2FRAME, EV_FLOAT, weapon2frame);
	clientstat(STAT_WEAPON2MODEL, EV_STRING, weapon2model);
	clientstat(STAT_GRENADES, EV_FLOAT, primary_grenades);
	clientstat(STAT_SECGRENADES, EV_FLOAT, secondary_grenades);
	clientstat(STAT_PROGRESSBAR, EV_FLOAT, progress_bar_percent);
	clientstat(STAT_WEAPONDURATION, EV_FLOAT, weapon_animduration);
	clientstat(STAT_WEAPON2DURATION, EV_FLOAT, weapon2_animduration);
	clientstat(STAT_WEAPONZOOM, EV_FLOAT, zoom);
	clientstat(STAT_INSTA, EV_FLOAT, insta_icon);
	clientstat(STAT_X2, EV_FLOAT, x2_icon);
	clientstat(STAT_SPECTATING, EV_FLOAT, isspec);
	clientstat(STAT_PLAYERNUM, EV_FLOAT, playernum);		// literally useless but will be kept in case
	clientstat(STAT_PLAYERSTANCE, EV_FLOAT, stance);
	clientstat(STAT_FACINGENEMY, EV_FLOAT, facingenemy);
	clientstat(STAT_VIEWZOOM, EV_FLOAT, viewzoom);
	clientstat(STAT_MAXHEALTH, EV_FLOAT, max_health);
	clientstat(STAT_PLAYERNAME, EV_STRING, name);

#endif // FTE

	mappath = strcat("maps/", mapname);
	mappath = strzone(mappath);

	LoadWaypointData();

	//set game elements
	G_STARTPOINTS = 500;
	G_STARTROUND = 1;
	G_PRONEPOINTS = 0;
	G_STARTWEAPON[0] = W_COLT;
	G_STARTWEAPON[1] = 8;
	G_STARTWEAPON[2] = 32;
	G_WORLDTEXT = 1;
	G_PERKS = 0;
	G_PERKPOWER = 0;
}

void() SpectatorConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the spectators.\n");
}

void() RelinkZombies =
{
	entity ent,ent2;
	local float i;
	local vector min, max;


	//warn
	ent = ent2 = world;

	while ((ent = find (ent, classname, "ai_zombie")))
	{
		if(ent.currentHitBoxSetup == 0)//empty bbox, we don't care to update
			continue;

#ifdef FTE
		// This is just a weird hack we do to avoid spamming other clients in co-op with
		// the update positions for limbs. Brings bandwidth from 90kbps->30kbps without
		// a tick rate limit. 30kbps->12kbps with a tickrate of 20Hz. Basically, like we
		// do other platforms for render speedups, if a zombie has all of its limbs dont
		// bother drawing them all separately. draw one full mesh instead, then when it
		// has been gibbed, then begin drawing separately -- cypress
		if (ent.larm.deadflag && ent.rarm.deadflag && ent.head.deadflag) {
			setmodel(ent.larm, "");
			setmodel(ent.rarm, "");
			setmodel(ent.head, "");

			if (ent.crawling == 1)
				setmodel(ent, "models/ai/zcfull.mdl");
			else
				setmodel(ent, "models/ai/zfull.mdl");
		} else if (!(ent.crawling == 1 && ent.model == "models/ai/zbc%.mdl") || !(ent.model == "models/ai/zb%.mdl")) {
			if (ent.crawling == 1)
				setmodel(ent, "models/ai/zbc%.mdl");
			else
				setmodel(ent, "models/ai/zb%.mdl");

			if (ent.larm.deadflag) {
				if (ent.crawling == 1)
					setmodel(ent.larm, "models/ai/zalc(.mdl");
				else
					setmodel(ent.larm, "models/ai/zal(.mdl");
			}

			if (ent.rarm.deadflag) {
				if (ent.crawling == 1)
					setmodel(ent.rarm, "models/ai/zarc(.mdl");
				else
					setmodel(ent.rarm, "models/ai/zar(.mdl");
			}

			if (ent.head.deadflag) {
				if (ent.crawling == 1)
					setmodel(ent.head, "models/ai/zhc^.mdl");
				else
					setmodel(ent.head, "models/ai/zh^.mdl");
			}
		}
#endif // FTE

		makevectors (ent.angles);

		for(i = 0; i < 3; i++)
		{
			if(i == 0)
				ent2 = ent.head;
			if(i == 1)
				ent2 = ent.larm;
			if(i == 2)
				ent2 = ent.rarm;


			if (ent2)
			{
				//setorigin (ent.head, ent.origin + v_right * ent.head.view_ofs_x + v_forward * ent.head.view_ofs_y + v_up * ent.head.view_ofs_z);
				setorigin (ent2, ent.origin);
				//fixme, move angles set and frame set to below the continue, we only want to update origin (maybe angles too?)
				ent2.angles = ent.angles;

				if(ent2.deadflag)
					ent2.frame = ent.frame;

				//if(OnlyOrigin)
				//	continue;
				
				
				min = ent2.bbmins + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);
				max = ent2.bbmaxs + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);

				if(min_x > max_x) { min_x += max_x; max_x = min_x - max_x; min_x -= max_x; }
				if(min_y > max_y) { min_y += max_y; max_y = min_y - max_y; min_y -= max_y; }
				if(min_z > max_z) { min_z += max_z; max_z = min_z - max_z; min_z -= max_z; }

				setsize(ent2,min,max);
				
			}

		}
	}
}

void() LinkZombiesHitbox =
{
	entity ent,ent2;
	local float i;
	local vector min, max;


	//warn
	ent = ent2 = world;

	while ((ent = find (ent, classname, "ai_zombie")))
	{
		if(ent.currentHitBoxSetup == 0)//empty bbox, we don't care to update
			continue;

		makevectors (ent.angles);

		for(i = 0; i < 3; i++)
		{
			if(i == 0)
				ent2 = ent.head;
			if(i == 1)
				ent2 = ent.larm;
			if(i == 2)
				ent2 = ent.rarm;


			if (ent2)
			{
				ent2.angles = ent.angles;

				if(ent2.deadflag)
					ent2.frame = ent.frame;

				//if(OnlyOrigin)
				//	continue;
				
				
				min = ent2.bbmins + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);
				max = ent2.bbmaxs + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);

				if(min_x > max_x) { min_x += max_x; max_x = min_x - max_x; min_x -= max_x; }
				if(min_y > max_y) { min_y += max_y; max_y = min_y - max_y; min_y -= max_y; }
				if(min_z > max_z) { min_z += max_z; max_z = min_z - max_z; min_z -= max_z; }

				setsize(ent2,min,max);
				
			}

		}
	}
}

void() EndFrame =
{
	RelinkZombies();

	if (cheats_have_been_activated == false && cvar("sv_cheats") == 1) {
		cheats_have_been_activated = true;
	}
};

//
// convert_old_asset_path(asset)
// a large switch statement to convert asset paths made for
// older versions of nzp to the new standard
//
string(string asset) convert_old_asset_path =
{
	string lowered_asset = strzone(strtolower(asset));
	string ret = "";

	switch(lowered_asset) {
		case "progs/player.mdl":
			ret = "models/player.mdl";
			break;
		case "progs/ai/zal(.mdl":
			ret = "models/ai/zal(.mdl";
			break;
		case "models/machines/quick_revive.mdl":
			ret = "models/machines/quake_scale/quick_revive.mdl";
			break;
		case "models/machines/juggernog.mdl":
			ret = "models/machines/quake_scale/juggernog.mdl";
			break;
		case "models/machines/speed_cola.mdl":
			ret = "models/machines/quake_scale/speed_cola.mdl";
			break;
		case "progs/misc/double_tap.mdl":
		case "models/machines/double_tap.mdl":
			ret = "models/machines/quake_scale/double_tap.mdl";
			break;
		case "progs/misc/flopper.mdl":
		case "models/machines/flopper.mdl":
			ret = "models/machines/quake_scale/flopper.mdl";
			break;
		case "models/machines/staminup.mdl":
			ret = "models/machines/quake_scale/staminup.mdl";
			break;
		case "models/machines/deadshot.mdl":
			ret = "models/machines/quake_scale/deadshot.mdl";
			break;
		case "models/machines/mulekick.mdl":
			ret = "models/machines/quake_scale/mulekick.mdl";
			break;
		case "progs/misc/pap.mdl":
		case "models/machines/pap.mdl":
			ret = "models/machines/quake_scale/pap.mdl";
			break;
		case "progs/sprites/lamp_glow.spr":
			ret = "models/sprites/lamp_glow.spr";
			break;
		case "progs/sprites/lamp_glow2.spr":
			// HACK HACK -- old maps that used this sprite were working with
			// a broken offset, fix it.
			self.origin_z -= 32;
			ret = "models/sprites/lamp_glow2.spr";
			break;
		case "progs/sprites/lamp_glow3.spr":
			ret = "models/sprites/lamp_glow.spr";
			break;
		case "progs/props/kino_boxes2.mdl":
			ret = "models/props/Kino_boxes2.mdl";
			break;
		case "progs/props/kino_boxes3.mdl":
			ret = "models/props/Kino_boxes3.mdl";
			break;
		case "progs/props/kino_boxes4.mdl":
			ret = "models/props/Kino_boxes4.mdl";
			break;
		case "progs/props/teddy.mdl":
		case "progs/misc/teddy.mdl":
			ret = "models/props/teddy.mdl";
			break;
		case "progs/props/kino_box.mdl":
			ret = "models/props/Kino_box.mdl";
			break;
		case "progs/props/table_dinner.mdl":
			ret = "models/props/table_dinner.mdl";
			break;
		case "progs/props/table_sq.mdl":
			ret = "models/props/table_sq.mdl";
			break;
		case "progs/props/rebar.mdl":
			ret = "models/props/rebar.mdl";
			break;
		case "progs/props/kino_table.mdl":
			ret = "models/props/Kino_table.mdl";
			break;
		case "progs/props/kino_couch.mdl":
			ret = "models/props/kino_couch.mdl";
			break;
		case "progs/props/metal_chair.mdl":
			ret = "models/props/metal_chair.mdl";
			break;
		case "progs/props/sandbags.mdl":
			ret = "models/props/sandbags.mdl";
			break;
		case "progs/props/dentist_chair.mdl":
			ret = "models/props/dentist_chair.mdl";
			break;
		case "progs/props/bath.mdl":
			ret = "models/props/bath.mdl";
			break;
		case "progs/props/shelf.mdl":
			ret = "models/props/shelf.mdl";
			break;
		case "progs/props/dummy.mdl":
			ret = "models/props/dummy.mdl";
			break;
		case "progs/props/stand.mdl":
			ret = "models/props/stand.mdl";
			break;
		case "progs/props/radio.mdl":
			ret = "models/props/radio.mdl";
			break;
		case "progs/props/radiator.mdl":
			ret = "models/props/radiator.mdl";
			break;
		case "progs/props/lamp_ndu.mdl":
			ret = "models/props/lamp_ndu.mdl";
			break;
		case "progs/props/lamp_ndu45.mdl":
			ret = "models/props/lamp_ndu45.mdl";
			break;
		case "progs/props/barrel_m.mdl":
			ret = "models/props/barrel_m.mdl";
			break;
		case "progs/props/lamp_oil.mdl":
			ret = "models/props/lamp_oil.mdl";
			break;
		case "progs/props/piano.mdl":
			ret = "models/props/piano.mdl";
			break;
		case "progs/props/pisuar.mdl":
			ret = "models/props/pisuar.mdl";
			break;
		case "progs/props/teleporter.mdl":
			ret = "models/props/teleporter.mdl";
			break;
		case "progs/props/chandelier.mdl":
			ret = "models/props/chandelier.mdl";
			break;
		case "progs/props/vanity_table.mdl":
			ret = "models/props/vanity_table.mdl";
			break;
		case "progs/props/trash_con.mdl":
			ret = "models/props/trash_con.mdl";
			break;
		case "progs/props/fridge.mdl":
			ret = "models/props/fridge.mdl";
			break;
		case "progs/props/kino_chairset.mdl":
			ret = "models/props/kino_chairset.mdl";
			break;
		case "progs/props/kino_lounge.mdl":
			ret = "models/props/Kino_lounge.mdl";
			break;
		case "progs/props/kino_stageprop.mdl":
			ret = "models/props/kino_stageprop.mdl";
			break;
		case "progs/props/mainframe_pad.mdl":
			ret = "models/props/mainframe_pad.mdl";
			break;
		case "progs/props/tree_ch.mdl":
			ret = "models/props/tree_ch.mdl";
			break;
		case "progs/props/treesl.mdl":
			ret = "models/props/treesl.mdl";
			break;
		case "progs/props/bed.mdl":
			ret = "models/props/bed.mdl";
			break;
		case "progs/gmodels/g_mp40.mdl":
			ret = "models/weapons/mp40/g_mp40.mdl";
			break;
		case "progs/gmodels/g_thomp.mdl":
			ret = "models/weapons/thomp/g_thomp.mdl";
			break;
		case "progs/gmodels/g_betty.mdl":
			ret = "models/weapons/grenade/g_betty.mdl";
			break;
		case "progs/gmodels/g_fg.mdl":
			ret = "models/weapons/fg42/g_fg.mdl";
			break;
		case "progs/gmodels/g_m1.mdl":
			ret = "models/weapons/garand/g_m1.mdl";
			break;
		case "progs/gmodels/g_sawnoff.mdl":
			ret = "models/weapons/sawnoff/g_sawnoff.mdl";
			break;
		case "progs/gmodels/g_trench.mdl":
			ret = "models/weapons/trench/g_trench.mdl";
			break;
		case "progs/gmodels/g_bar.mdl":
			ret = "models/weapons/bar/g_bar.mdl";
			break;
		case "progs/gmodels/g_grenade.mdl":
			ret = "models/weapons/grenade/g_grenade.mdl";
			break;
		case "progs/gmodels/g_gewehr.mdl":
			ret = "models/weapons/gewehr/g_gewehr.mdl";
			break;
		case "progs/gmodels/g_bowie.mdl":
			ret = "models/weapons/knife/g_bowie.mdl";
			break;
		case "progs/gmodels/g_type.mdl":
			ret = "models/weapons/type/g_type.mdl";
			break;
		case "progs/gmodels/g_ppsh.mdl":
			ret = "models/weapons/ppsh/g_ppsh.mdl";
			break;
		case "progs/gmodels/g_stg.mdl":
			ret = "models/weapons/stg/g_stg.mdl";
			break;
		case "models/misc/lightning.spr":
			ret = "models/sprites/lightning.spr";
			break;
		case "models/derped/wall_lamp.mdl":
			ret = "models/props/lamp_wall.mdl";
			break;
		case "models/machines/power_switch.mdl":
			ret = "models/machines/quake_scale/power_switch.mdl";
			break;
		case "models/machines/hl_scale/packapunch/p_machine.mdl":
			ret = "models/machines/hl_scale/pap/p_machine.mdl";
			break;
		case "models/machines/hl_scale/packapunch/p_roller.mdl":
			ret = "models/machines/hl_scale/pap/p_roller.mdl";
			break;
		case "models/machines/hl_scale/packapunch/p_flag.mdl":
			ret = "models/machines/hl_scale/pap/p_flag.mdl";
			break;
		default: 
			ret = asset;
			break;
	}

	strunzone(lowered_asset);
	return ret;
};
