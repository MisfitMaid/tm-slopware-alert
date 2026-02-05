namespace Slopware {
    Json::Value cache;

    void init() {
        if (IO::FileExists(IO::FromStorageFolder("cache.json"))) {
            cache = Json::FromFile(IO::FromStorageFolder("cache.json"));
        } else {
            cache = Json::Object();
        }
        
        array<Meta::Plugin@> plugs = Meta::AllPlugins();

        for (uint i = 0; i < plugs.Length; i++) {
            if (isSlop(plugs[i])) {
                UI::ShowNotification("AI-coded plugin found!", plugs[i].Name + " by " + plugs[i].Author + " is known to have AI code.\n\nPlease see the plugin page on openplanet.dev for more information.", vec4(0.5, 0, 0, 1));
            }
        }
    }

    bool isSlop(Meta::Plugin@ plugin) {
        string key = plugin.ID + "___" + plugin.Version;
        if (cache.HasKey(key)) {
            return cache.Get(key);
        }

        if (plugin.SiteID == 0) return false;

        // not cached, let's ask
        Net::HttpRequest@ req = Net::HttpGet("https://api.openplanet.dev/plugin/"+plugin.SiteID);

        while (!req.Finished()) yield();
        sleep(1000); // dont spam opdev xoxo

        if (req.ResponseCode() != 200 || req.String() == "null") return false;

        auto resp = req.Json();
        if (resp.HasKey("genai")) {
            cache[key] = resp["genai"];
            Json::ToFile(IO::FromStorageFolder("cache.json"), cache, true);
            return cache[key];
        }
        return false;
    }
}
