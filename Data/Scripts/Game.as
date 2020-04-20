#include "CommonStuff.as"

namespace S_Game
{


Node@ g_mech;
Node@ g_truck;
Node@ g_bigcorona;


float g_coronaStartHealth;
UIElement@ g_gameUI;
UIElement@ g_nice;
UIElement@ g_truckBar;
UIElement@ g_coronaBar;
UIElement@ g_coronaHealth;

UIElement@ g_help;

SoundSource@ g_music;



int g_numberOfGames = 0;

float g_whatTime;

enum GameState
{
    E_START,
    E_GAME_MAIN,
    E_UPGRADE_TIME,
    E_GAME_OVER
}

GameState g_gameState;

Color ColourHealth(float percent)
{
    return Color(0.5 - percent * 0.5f, percent * 0.5f, 0.0f);
}

void SpawnHugeCorona()
{
    g_bigcorona = scene_.InstantiateJSON(cache.GetResource("JSONFile", "Objects/BigCorowona.json"), Vector3(39, 22.7, -135), Quaternion());

    g_coronaStartHealth = 200 + g_numberOfGames * 120;

    g_bigcorona.vars["Health"] = g_coronaStartHealth;
    g_bigcorona.vars["Spawngroup"] = int(g_numberOfGames * 3) + 3;
    g_bigcorona.vars["Spawnrate"] = 10.0f + 40.0f / (1.0f + g_numberOfGames);
}

void Teleport()
{
    Print("Teleport!");
    g_mech.vars["TeleportRequest"] = true;
    
    if (g_gameState == E_UPGRADE_TIME)
    {
        g_mech.vars["LaserDamage"] = 30 + g_numberOfGames * 20;
        g_gameState = E_START;
        g_whatTime = scene_.elapsedTime;
        g_nice.opacity = 0.0f;
    }
}

void CloseThat()
{
    g_help.SetPosition(0, 10000);
}

// Game stuff go here
void Salamander(int stats)
{
    if (stats == 1)
    {
        scene_.LoadXML(cache.GetFile("Scenes/Scene1.xml"));
        
        g_truck = scene_.GetChild("TheTruck");
        
        g_gameUI = ui.LoadLayout(cache.GetResource("XMLFile", "UI/Game.xml"));
        ui.root.AddChild(g_gameUI);
        
        g_help = ui.LoadLayout(cache.GetResource("XMLFile", "UI/Welcome.xml"));
        ui.root.AddChild(g_help);
        
        SubscribeToEvent(cast<Button@>(g_help.GetChild("Exit")), "Pressed", "S_Game::CloseThat");
        
        SubscribeToEvent(cast<Button@>(g_gameUI.GetChild("Teleport")), "Pressed", "S_Game::Teleport");
        
        g_music = scene_.GetComponent("SoundSource");
        
        g_truckBar = g_gameUI.GetChild("Truckbar");
        g_coronaBar = g_gameUI.GetChild("Coronabar");
        g_nice = g_gameUI.GetChild("Nice");
        g_nice.opacity = 0.0f;

        g_mech = scene_.GetChild("MechGuy");
        
        Viewport@ viewport = Viewport(scene_, scene_.GetChild("CameraTgt").GetChild("CameraNode").GetComponent("Camera"));
        renderer.viewports[0] = viewport;
        
        g_numberOfGames = 0;
        
        g_whatTime = 0;
        
        scene_.vars["SmallKills"] = 0;

    }
    else
    {
        // Update Truck health bar
    
        float truckPercent = g_truck.vars["Health"].GetFloat() / 1000.0f;
    
        g_truckBar.SetSize(truckPercent * 600.0f, 20);
        g_truckBar.color = ColourHealth(truckPercent);
        
        // Corona bar
        
        float coronaPercent;
       
        if (g_bigcorona is null)
        {
            g_coronaBar.color = Color(1.0f, 0.0f, 0.0f);
            coronaPercent = 1.0f;
        }
        else
        {
            coronaPercent = g_bigcorona.vars["Health"].GetFloat() / g_coronaStartHealth;
            g_coronaBar.color = ColourHealth(coronaPercent);
        }
        
        g_coronaBar.SetSize(coronaPercent * 600.0f, 20);
        g_coronaBar.SetPosition(660 + (1.0f - coronaPercent) * 600.0f, 20);
        
        
        
        if (g_gameState == E_START)
        {
            // 10 seconds to learn to walk
            if (scene_.elapsedTime - g_whatTime > 4.0f)
            {
                SpawnHugeCorona();
                g_gameState = E_GAME_MAIN;
                g_music.sound.looped = true;
                g_music.Play(g_music.sound);
            }
        }
        else if (g_gameState == E_GAME_MAIN)
        {
            // wait for huge virus to die
            if (g_bigcorona.vars["Health"].GetFloat() <= 0)
            {
                @g_bigcorona = null;
                g_gameState = E_UPGRADE_TIME;
                g_nice.opacity = 1.0f;
                g_music.Stop();
                g_numberOfGames ++;
            }
        }
        
        
        if (g_truck.vars["Health"].GetFloat() <= 0.0f && g_gameState != E_GAME_OVER)
        {
            // game over
            g_music.Stop();
            g_gameState = E_GAME_OVER;
            UIElement@ over = ui.LoadLayout(cache.GetResource("XMLFile", "UI/GameOver.xml"));
            Text@ overA = over.GetChild("KilledA");
            Text@ overB = over.GetChild("KilledB");
            
            overA.text = "Viruses Killed: " + scene_.vars["SmallKills"].GetInt();
            overB.text = "HUGE Viruses Killed: " + g_numberOfGames;
            
            ui.root.AddChild(over);
        }
        else
        {
            if (input.keyDown[KEY_H])
            {
                g_help.SetPosition(0, 0);
            }
        }
    }
    
}

}
