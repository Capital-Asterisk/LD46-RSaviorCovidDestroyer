 
 
class Cowowna : ScriptObject
{
    
    Node@ m_points;
    Node@ m_currentPoint;
    RigidBody@ m_body;
    
    float m_accel;
    float m_topspeed;
    
    void PickNewPoint()
    {
        const Array<Node@> childs = m_points.GetChildren();
        float diffX, diffZ;
        uint indToInsert;
        Node@ currentChild;
        
        Array<Node@> canidateSorted;
        
        for (uint i = 0; i < childs.length; i ++)
        {
            currentChild = childs[i];
            diffX = Abs(node.position.x - currentChild.position.x);
            diffZ = currentChild.position.z - node.position.z;
            
            if (diffX > diffZ)
            {
                continue;
            }
            
            indToInsert = 0;
            
            if (canidateSorted.length != 0)
            {
                while(indToInsert != canidateSorted.length && (canidateSorted[indToInsert].position.z - node.position.z < diffZ))
                {
                    indToInsert ++;
                }
            }
            canidateSorted.Insert(indToInsert, currentChild);
        }
        
        if (canidateSorted.length == 0)
        {
            m_currentPoint = scene.GetChild("TheTruck");
            return;
        }
        
        // add sorted by diffZ
        for (uint j = 0; j < canidateSorted.length; j ++)
        {
            Print("Sorted: " + (canidateSorted[j].position.z - node.position.z));
        }
        
        int rindex = RandomInt(0, Min(3, canidateSorted.length));
        
        // pick one
        m_currentPoint = canidateSorted[rindex];
        
        Print("picked: " + rindex);
    }

    void DelayedStart()
    {
        SubscribeToEvent("PhysicsPreStep", "PhysicsUpdate");
        SubscribeToEvent(node, "NodeCollision", "NodeCollision");

        m_points = scene.GetChild("Coronapoints");
        m_body = node.GetComponent("RigidBody");
        
        
        PickNewPoint();
    }
    
    void NodeCollision(StringHash evtType, VariantMap& evtData)
    {
        Node@ hit = evtData["OtherNode"].GetPtr();
        
        if (hit.name == "TheTruck")
        {
            // damage
            node.vars["Health"] = 0;
            hit.vars["Health"] = hit.vars["Health"].GetFloat() - Random(40, 100);
            UnsubscribeFromEvent("NodeCollision");
            
            SoundSource3D@ ss = hit.GetComponent("SoundSource3D");
            Sound@ s = ss.sound;
            ss.Play(s);
            
            
        }
        else if (hit.name.StartsWith("Rok"))
        {
            m_body.ApplyImpulse(Vector3(Random(-1.0f, 1.0f), 0, Random(-1.0f, 1.0f)));
        }
        
    }
    
    void PhysicsUpdate(StringHash eventType, VariantMap& eventData)
    {
    
        if (node.vars["Health"].GetFloat() <= 0)
        {
            // Explode
            SoundSource3D@ ss = node.GetComponent("SoundSource3D");
            Sound@ s = ss.sound;
            ss.frequency = (44100 * Random(0.9, 1.2));
            ss.Play(s);
            
            node.RemoveComponent("StaticModel");
            node.RemoveComponent("RigidBody");
            ParticleEmitter@ emit = node.GetComponent("ParticleEmitter");
            emit.enabled = true;
            node.rotation = Quaternion();
            node.SetScale(8.0f);
            
            UnsubscribeFromAllEvents();
            scene.vars["SmallKills"] = scene.vars["SmallKills"].GetInt() + 1;
            scene.vars["SmallKills"] = scene.vars["SmallKills"].GetInt() + 1;

            return;
        }
    
        Vector3 diff = (m_currentPoint.position - node.position);
        diff.y = 0;
        
        if (m_body.linearVelocity.length < m_topspeed)
        {
            m_body.ApplyForce(diff.Normalized() * m_accel);
        }
        //node.position += diff.Normalized() * 0.2f;
        
        if (diff.z < 0 && m_currentPoint.name.length == 0)
        {
            PickNewPoint();
        }
    }
}
