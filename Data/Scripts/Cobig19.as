 
 
class Cobig : ScriptObject
{
    float lastSpawnTime;
    
    
    void DelayedStart()
    {
        SubscribeToEvent("PhysicsPreStep", "PhysicsUpdate");
        SubscribeToEvent("RenderUpdate", "RenderUpdate");
    }

    
    void PhysicsUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (node.vars["Health"].GetFloat() <= 0)
        {
            // Explode
            SoundSource3D@ ss = node.GetComponent("SoundSource3D");
            Sound@ s = ss.sound;
            ss.frequency = (44100 * Random(0.9, 1.2)) * 0.5;
            ss.Play(s);
            
            node.RemoveComponent("StaticModel");
            node.RemoveComponent("RigidBody");
            ParticleEmitter@ emit = node.GetComponent("ParticleEmitter");
            emit.enabled = true;
            node.rotation = Quaternion();
            node.SetScale(40.0f);
            
            UnsubscribeFromAllEvents();
            return;
        }
        
        
        
        // Spawning
        
        if (lastSpawnTime + node.vars["Spawnrate"].GetFloat() < scene.elapsedTime)
        {
            Print("spawning cowonas");
            // Spawn cowonas
            lastSpawnTime = scene.elapsedTime;
            int amount = Random(1, node.vars["Spawngroup"].GetInt());
            float sphealth = node.vars["Spawnhealth"].GetFloat();
            
            for (uint i = 0; i < amount; i++)
            {
                scene.InstantiateJSON(cache.GetResource("JSONFile", "Objects/Corowona.json"), node.position + Vector3(Random(-10, 10), 0, Random(-10, 10)), Quaternion());
            }
        }
    }
    
    void RenderUpdate(StringHash eventType, VariantMap& eventData)
    {
        Vector3 ay = node.position;
        ay.y /*lmao*/ = 14.1454 + Sin(scene.elapsedTime * 90 * 2);
        node.position = ay;
        
        node.rotation = Quaternion(0.0f, scene.elapsedTime * 3.0f, 0.0f);
    }
}
