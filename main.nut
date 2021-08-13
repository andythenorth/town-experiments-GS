/** Import SuperLib for GameScript **/
import("util.superlib", "SuperLib", 36);
Result <- SuperLib.Result;
Log <- SuperLib.Log;
Helper <- SuperLib.Helper;
Tile <- SuperLib.Tile;
Direction <- SuperLib.Direction;
Town <- SuperLib.Town;
Industry <- SuperLib.Industry;
Story <- SuperLib.Story;
// Additional SuperLib sub libraries can be found here:
// http://dev.openttdcoop.org/projects/superlib/repository

/** Import other libs **/
// There are several other libraries for Game Scripts out there. Check out
// http://bananas.openttd.org/en/gslibrary/ for an up to date list.
//
// Remember to set dependencies in the bananas web manager for all libraries
// that you use. This way users will automatically get all libraries of the
// version you selected when they download your Game Script.


/** Import other source code files **/
require("version.nut"); // get SELF_VERSION
//require("some_file.nut");
//..


class MainClass extends GSController
{
	_loaded_data = null;
	_loaded_from_version = null;
	_init_done = null;

	/*
	 * This method is called when your GS is constructed.
	 * It is recommended to only do basic initialization of member variables
	 * here.
	 * Many API functions are unavailable from the constructor. Instead do
	 * or call most of your initialization code from MainClass::Init.
	 */
	constructor()
	{
		this._init_done = false;
		this._loaded_data = null;
		this._loaded_from_version = null;
	}
}

/*
 * This method is called by OpenTTD after the constructor, and after calling
 * Load() in case the game was loaded from a save game. You should never
 * return back from this method. (if you do, the script will crash)
 *
 * Start() contains of two main parts. First initialization (which is
 * located in Init), and then the main loop.
 */
function MainClass::Start()
{
	// Some OpenTTD versions are affected by a bug where all API methods
	// that create things in the game world during world generation will
	// return object id 0 even if the created object has a different ID.
	// In that case, the easiest workaround is to delay Init until the
	// game has started.
	if (Helper.HasWorldGenBug()) GSController.Sleep(1);

	this.Init();

	// Wait for the game to start (or more correctly, tell OpenTTD to not
	// execute our GS further in world generation)
	GSController.Sleep(1);

	// Game has now started and if it is a single player game,
	// company 0 exist and is the human company.

	// Main Game Script loop
	local last_loop_date = GSDate.GetCurrentDate();
	while (true) {
		local loop_start_tick = GSController.GetTick();

		// Handle incoming messages from OpenTTD
		this.HandleEvents();

		// Reached new year/month?
		local current_date = GSDate.GetCurrentDate();
		if (last_loop_date != null) {
			local year = GSDate.GetYear(current_date);
			local month = GSDate.GetMonth(current_date);
			if (year != GSDate.GetYear(last_loop_date)) {
				this.EndOfYear();
			}
			if (month != GSDate.GetMonth(last_loop_date)) {
				this.EndOfMonth();
			}
		}
		last_loop_date = current_date;

		// Loop with a frequency of five days
		local ticks_used = GSController.GetTick() - loop_start_tick;
		GSController.Sleep(max(1, 5 * 74 - ticks_used));
	}
}

/*
 * This method is called during the initialization of your Game Script.
 * As long as you never call Sleep() and the user got a new enough OpenTTD
 * version, all initialization happens while the world generation screen
 * is shown. This means that even in single player, company 0 doesn't yet
 * exist. The benefit of doing initialization in world gen is that commands
 * that alter the game world are much cheaper before the game starts.
 */
function MainClass::Init()
{
	if (this._loaded_data != null) {
		// Copy loaded data from this._loaded_data to this.*
		// or do whatever you like with the loaded data
	} else {
		// construct goals etc.
	}

    Log.Info(typeof(GSNewGRFList()), Log.LVL_INFO);

    GSLog.Info("GSNewGRFList()...");
    local grf_list = GSNewGRFList();
    grf_list.Sort(GSList.SORT_BY_VALUE, true);
    foreach (grf, _ in grf_list) {
    //for (local i = grf_list.Begin(); !grf_list.IsEnd(); i = grf_list.Next()) {
        //Log.Info(i, Log.LVL_INFO);
        Log.Info(grf, Log.LVL_INFO);
        Log.Info(_, Log.LVL_INFO);
    }

    GSLog.Info("GSNewGRF.IsLoaded(0x80025f1)...");
    if (GSNewGRF.IsLoaded(0xf1250008)) {
        Log.Info(GSNewGRF.IsLoaded(0xf1250008), Log.LVL_INFO);
        Log.Info(GSNewGRF.GetVersion(0xf1250008), Log.LVL_INFO);
        Log.Info(GSNewGRF.GetName(0xf1250008), Log.LVL_INFO);
        /*
        Log.Info("Industry count..");
        local industry_list = GSIndustryList();
        Log.Info(industry_list.Count(), Log.LVL_INFO);
        foreach (industry, _ in industry_list) {
            Log.Info(GSIndustry.GetIndustryType(industry), Log.LVL_INFO);
            Log.Info(GSIndustry.GetName(industry), Log.LVL_INFO);
        }
        */
        Log.Info("get all tiles, start tick:" + GSController.GetTick(), Log.LVL_INFO);
        local all_map_tiles = GSTileList();
        all_map_tiles.AddRectangle(0, GSMap.GetMapSize() -1);
        Log.Info("all_map_tiles length: " + all_map_tiles.Count(), Log.LVL_INFO);
        local tiles_grouped_by_town = {};
        foreach (town, _ in GSTownList()) {
            tiles_grouped_by_town[town] <- [];
        }
        for (local tile = 0; tile < GSMap.GetMapSize(); tile++) {
            if (GSMap.IsValidTile(tile)) {
                local tile_town = GSTile.GetClosestTown(tile);
                tiles_grouped_by_town[tile_town].append(tile);
            }
        }
        Log.Info("get all tiles, end tick:" + GSController.GetTick(), Log.LVL_INFO);
        local towns_with_info_industry = GSList();
        foreach (industry, _ in GSIndustryList()) {
            if (GSIndustry.GetIndustryType(industry) == 2) {
                Log.Info(GSIndustry.GetName(industry), Log.LVL_INFO);
                Log.Info(GSIndustry.GetIndustryType(industry), Log.LVL_INFO);
                local town = GetIndustryTown(industry);
                towns_with_info_industry.AddItem(town, 0);
            }
        }
        foreach (town, _ in GSTownList()) {
            if (towns_with_info_industry.HasItem(town) == false) {
                local town_name = GSTown.GetName(town);
                Log.Info(town_name, Log.LVL_INFO);
                foreach (tile in tiles_grouped_by_town[town]) {
                    local result = GSIndustryType.BuildIndustry(2, tile);
                    if (result == true) {
                        Log.Info("...built industry", Log.LVL_INFO);
                    }
                }
            }
        }
    }

    /*
    foreach (industry, _ in industry_list) {
        Log.Info(GSIndustry.GetIndustryType(industry), Log.LVL_INFO);
        Log.Info(GSIndustry.GetName(industry), Log.LVL_INFO);
    }
    */
    /*
    local counter = 0;
    foreach (town, _ in GSTownList()) {
        counter++;
        local town_name = GSTown.GetName(town);
        local new_name = "CABBAGE " + counter;
        if (GSTown.SetName(town, new_name) == true) {
            Log.Info(town_name + " renamed to " + new_name, Log.LVL_INFO);
        } else {
            Log.Info(town_name + " failed to rename to " + new_name, Log.LVL_INFO);
        }
    }
    foreach (cargo, _ in GSCargoList()) {
        if (GSCargo.GetTownEffect(cargo) != 0) {
            Log.Info(GSCargo.GetCargoLabel(cargo) + ": " + GSCargo.GetTownEffect(cargo), Log.LVL_INFO);
        }
    }
    */
	// Indicate that all data structures has been initialized/restored.
	this._init_done = true;
	this._loaded_data = null; // the loaded data has no more use now after that _init_done is true.
}

/*
 * This method handles incoming events from OpenTTD.
 */
function MainClass::HandleEvents()
{
	if(GSEventController.IsEventWaiting()) {
		local ev = GSEventController.GetNextEvent();
		if (ev == null) return;

		local ev_type = ev.GetEventType();
		switch (ev_type) {
			case GSEvent.ET_COMPANY_NEW: {
				local company_event = GSEventCompanyNew.Convert(ev);
				local company_id = company_event.GetCompanyID();

				// Here you can welcome the new company
				Story.ShowMessage(company_id, GSText(GSText.STR_WELCOME, company_id));
				break;
			}

			// other events ...
		}
	}
}

/*
 * Called by our main loop when a new month has been reached.
 */
function MainClass::EndOfMonth()
{
    // Fuck about with vehicles
    local vehicle_list = GSVehicleList();
    Log.Info("Vehicle count..");
    Log.Info(vehicle_list.Count());
    foreach (vehicle, _ in vehicle_list) {
        Log.Info("Start/stop vehicle:" + GSVehicle.GetName(vehicle));
        local company = GSCompanyMode(GSVehicle.GetOwner(vehicle));
        Log.Info(GSVehicle.IsValidVehicle(vehicle));
        GSVehicle.StartStopVehicle(vehicle);
    }

}

/*
 * Called by our main loop when a new year has been reached.
 */
function MainClass::EndOfYear()
{
}

/*
 * This method is called by OpenTTD when an (auto)-save occurs. You should
 * return a table which can contain nested tables, arrays of integers,
 * strings and booleans. Null values can also be stored. Class instances and
 * floating point values cannot be stored by OpenTTD.
 */
function MainClass::Save()
{
	Log.Info("Saving data to savegame", Log.LVL_INFO);

	// In case (auto-)save happens before we have initialized all data,
	// save the raw _loaded_data if available or an empty table.
	if (!this._init_done) {
		return this._loaded_data != null ? this._loaded_data : {};
	}

	return {
		some_data = null,
		//some_other_data = this._some_variable,
	};
}

/*
 * When a game is loaded, OpenTTD will call this method and pass you the
 * table that you sent to OpenTTD in Save().
 */
function MainClass::Load(version, tbl)
{
	Log.Info("Loading data from savegame made with version " + version + " of the game script", Log.LVL_INFO);

	// Store a copy of the table from the save game
	// but do not process the loaded data yet. Wait with that to Init
	// so that OpenTTD doesn't kick us for taking too long to load.
	this._loaded_data = {}
   	foreach(key, val in tbl) {
		this._loaded_data.rawset(key, val);
	}

	this._loaded_from_version = version;
}

function MainClass::GetIndustryTown(industry)
{
	local tile = GSIndustry.GetLocation(industry);
	local town = GSTile.GetClosestTown(tile);
	return town;
}
