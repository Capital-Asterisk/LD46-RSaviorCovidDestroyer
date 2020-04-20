// Some simple base code for Urho3d
// Programming Simulator style

#include "CommonStuff.as"
#include "Game.as"

void Start()
{

    // enable cursor
    input.mouseVisible = true;
    graphics.windowTitle = "R-SAVIOR: COVID DESTROYER";

    // Set default UI style
    XMLFile@ style = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    ui.root.defaultStyle = style;

    scene_ = Scene();

    input.mouseMode = MM_FREE;

    SubscribeToEvent(scene_, "SceneUpdate", "HandleUpdate");

    // make some randomness random
    SetRandomSeed(time.systemTime);

    //ChangeScene(@S_VIntro::Salamander);
    ChangeScene(@S_Game::Salamander);

}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
  
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    int stat = 0;
    if (ffirst_)
    {
        stat = 1;
        time_ = 0;
        ffirst_ = false;
    }
    delta_ = eventData["TimeStep"].GetFloat();
    time_ += delta_ * timescale_;
    sceneFunc_(stat);
}

void ChangeScene(SCENEFUNCTION@ to)
{
    ui.root.RemoveAllChildren();
    scene_.RemoveAllChildren();
    //ui.root.defaultStyle = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    sceneFunc_ = to;
    time_ = 0;
    ffirst_ = true;
}

namespace S_VIntro
{

Sprite@ aAAAAAAA;
Sprite@ bA;
Sprite@ cAAAAw;
Text@ dAAAAAAA;

Array<String> phrase = {
    "play my gamez",
    "my ********* are becoming ******",
    "%INSPIRING QUOTE%",
    "great, another Vendalenger game.",
    "I think I can count to 2",
    "No Durian",
    "don't check out my gamejolt",
    "This game has no fish",
    "Don't expect anything to work",
    "Also try Boundless Power",
    "Also try Innotgeneric",
    "Also try Rook vs Rook",
    "Also try 200 Bit Fish",
    "Also try Manned Missile Master",
    "Also try Electric Fence Micro-B",
    "I won coriolis three more motorcycle",
    "The earth is a curved hexagon.",
    "Pinch cat at back of neck.",
    "colourful clocks clicking cautiously",
    "When computerized trees wave around in the wind.",
    "sudo rm -rf /*",
    "JavaScript wasted my time",
    "CAW CAW CAW",
    "crows can use debuggers",
    "might also be known as caws-a-bit",
    "Wet and metallic spikes, do not respond to hazard light.",
    "You are having a Spiny Day",
    "Farganelle is the conspiracy crow",
    "The printing system is actually sentient",
    "btw i use arch",
    ".... @CaptailShashlik",
    ".... discord.gg/yAUqxS6",
    "*notices you stawt prowogram* uvu have fun",
    "wine is not an emulator",
    "stay inside, beware of CORVID-19 salty crow Crow Na",
    "wash your hands before playing",
    "clean your keyboard too"
};

// The Vendalenger screen
void Salamander(int stats)
{
    if (stats == 1)
    {
    
        menuSounds_ = scene_.CreateComponent("SoundSource");
        menuSounds_.soundType = SOUND_MUSIC;
    
        Sprite@ background = ui.root.CreateChild("Sprite", "Background");
        background.color = Color(0.03, 0.03, 0.03);
        background.SetSize(graphics.width, graphics.height);
        
        aAAAAAAA = ui.root.CreateChild("Sprite", "VendalengerText");
        aAAAAAAA.texture = Texture2D();
        aAAAAAAA.texture.SetNumLevels(1);
        aAAAAAAA.texture.filterMode = FILTER_NEAREST;
        aAAAAAAA.texture.Load("Data/Textures/vendalenger.png");
        aAAAAAAA.SetSize(240, 29);
        aAAAAAAA.imageRect = IntRect (0, 0, 240, 29);
        aAAAAAAA.blendMode = BLEND_ADD;
        

        cAAAAw = aAAAAAAA.CreateChild("Sprite", "VendalengerText");
        cAAAAw.texture = null;

        dAAAAAAA = ui.root.CreateChild("Text", "MachinerineMackreywon");
        dAAAAAAA.SetFont(cache.GetResource("Font", "Fonts/Louis George Cafe.ttf"), 16);
        dAAAAAAA.text = "Game by Capital_Asterisk\n" + phrase[RandomInt(0, phrase.length - 1)];
        dAAAAAAA.textAlignment = HA_CENTER;
        dAAAAAAA.color = Color(0.2, 0.2, 0.2);

        bA = ui.root.CreateChild("Sprite", "Square2");  
        bA.texture = null;
        bA.color = Color(0.4, 1.0, 0.0);
        bA.SetSize(40, 40);
        Sprite@ bB = bA.CreateChild("Sprite", "Square1");
        bB.texture = null;
        bB.color = Color(0.4, 1.0, 0.0);
        bB.SetSize(40, 40);
        bB.SetPosition(-40, -40);
        Sprite@ bC = bA.CreateChild("Sprite", "Square3");
        bC.texture = null;
        bC.color = Color(0.4, 1.0, 0.0);
        bC.SetSize(40, 40);
        bC.SetPosition(40, -80);
        
        menuSounds_.Seek(0);
        menuSounds_.Play(cache.GetResource("Sound", "Sounds/vendalenger.ogg"));
        menuSounds_.frequency *= timescale_;
        
        time_ = 0;
        
        cache.BackgroundLoadResource("Model", "Models/ezsphere.mdl");
        
    } else {
        
        aAAAAAAA.SetPosition((graphics.width - aAAAAAAA.width) / 2, (time_ > 0.5) ? (graphics.height - aAAAAAAA.height) / 2 + 75 : -1000000000);
        dAAAAAAA.SetPosition((graphics.width - dAAAAAAA.width) / 2, (time_ > 1.2) ? (graphics.height - dAAAAAAA.height) / 2 + 200 : -1000000000);
        
        float eggs = 32 * (0.7 - time_) * 9;  
        float rock = 240 * Pow(time_ - 0.5, 2) * 80 + 240;
        cAAAAw.SetSize(rock, eggs);
        cAAAAw.SetPosition((-rock + aAAAAAAA.width) / 2, (-eggs + aAAAAAAA.height) / 2);
        float quadratic = 12000.0f * Pow(Min(time_, 0.5f) - 0.47f, 2);
        bA.SetPosition((graphics.width - bA.width) / 2, quadratic + (graphics.height - bA.height) / 2);
        
        if (cache.numBackgroundLoadResources == 0 && time_ > 3)
        {
            ChangeScene(@S_Game::Salamander);
        }
        
    }
}

}
