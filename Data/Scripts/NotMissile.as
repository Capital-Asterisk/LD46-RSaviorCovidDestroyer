/* File
 * File File
 * File File File File
 * File File File File File File File File File File
 * 
 * Copyright (C) 2019 Neal Nicdao
 * 
 * Licensed under the Holy Open Software License of the Computer Gods V1
 * 
 * This software comes with ABSOLUTELY NO WARANTEEEEE. By plagiarizing the
 * work, you agree to the HIGHEST POSSIBLE PUNISHMENT from the the might of the
 * COMPUTER GODS through rolling the DICE.
 * 
 * 
 * About walking the thing:
 * 
 * States:
 * 
 * * Planted
 *   * Both legs on ground
 *   * Upper Torso can rotate
 *   * If walk requested, set lifted leg as furthest foot, and goto Walking
 * 
 * * Walking
 *   * One leg up, one leg planted
 *   * Pivots around planted foot
 *   * If foot has reached a set distance, down and goto Planted
 * 
 * * Jumping
 *   * Yeah
 * 
 * * Airborne
 *   * Corona
 * 
 * 
 * 
 * 
 * NEGATIVE Z IS FORWARD
 * NEGATIVE X IS RIGHT
 */


enum MechState
{
    E_MECH_PLANTED,
    E_MECH_WALkING,
    E_MECH_JUMPING,
    E_MECH_AIRBORNE
}

float SolveAngleC(float a, float b, float c)
{
    return Acos((c*c - a*a - b*b) / (-2 * a * b));
}

class MechLeg
{
    
    Node@ m_upper;
    Node@ m_lower;
    Node@ m_foot;
    
    float footAngle;
    
    // foot position relative to upper leg
    Vector3 m_footPos;
    Vector3 m_footVelocity;

    
    float m_lengthUpper = -1.04086f;
    float m_lengthLower = -1.02196f;
    
    void Set(Node@ torso, String upperStr, String lowerStr, String footStr)
    {
        m_upper = torso.GetChild(upperStr);
        m_lower = m_upper.GetChild(lowerStr);
        m_foot = m_lower.GetChild(footStr);
        
        
        Print("foo: " + m_foot.position.y);
    }
    
    void MoveToFootPos()
    {
        float footDist = m_footPos.length;
        float legAngle = Atan2(-m_footPos.z, m_footPos.y);
        
        float upperAng = -SolveAngleC(m_lengthUpper, footDist, m_lengthLower) - legAngle;
        float lowerAng = -180.0f + SolveAngleC(m_lengthLower, m_lengthUpper, footDist);
        
        m_upper.rotation = Quaternion(upperAng, 0.0f, 0.0f);
        m_lower.rotation = Quaternion(lowerAng, 0.0f, 0.0f);
        
        m_foot.rotation = Quaternion(-lowerAng - upperAng + footAngle, 0.0f, 0.0f);
    }
    
    void RecalculateFootPos()
    {
        float keepX = m_footPos.x;
        m_footPos = m_upper.transform * m_foot.position;
        m_footPos.x = keepX;
        Print("foot: " + m_footPos.ToString());
    }
    
    void UnstuckSpaghetti()
    {
        //RecalculateFootPos();
        m_footPos.y += 0.1f;
        MoveToFootPos();
    }
}

class NotMissile : ScriptObject
{

    MechState m_state;
    
    Node@ m_rotator;
    Node@ m_rightShoulder;
    Node@ m_rightLazor;
    
    //Node@ m_torsoLower;
    MechLeg m_legL;
    MechLeg m_legR;
    
    // when walking
    MechLeg@ m_walkPivot;
    MechLeg@ m_walkLifted;
    
    //float m_walkLiftTarget = -1.0f;
    //float m_walkPlantTarget = -1.8f;
    //float m_walkExtendTarget = -1.3f;
    float m_spdmul = 1.3f;
    float m_walkPlantThreshold = -1.0f;
    float m_walkBackwardsPlantThreshold = 0.0f;
    int m_walkFrame;
    
    Vector2 m_walkZLimit;
    Vector2 m_walkYLimit;
    
    //float m_walkPivotBackTarget = 1.2f;
    //float m_walkPivotLiftTarget = -1.9;
    
    Vector3 m_pivotPos;
    
    float m_walkStepForward = -1.0f;
    float m_walkStepBackwards = -0.5f;

    Vector3 m_moveDesire; // direction mech wants to move 
    float m_walkThreshold = 0.1f;
    
    Vector3 m_originalPos;
    Quaternion m_originalRotation;
    
    Vector3 m_originalLFootPos;
    Vector3 m_originalRFootPos;
    
    bool m_laserFiring;
    
    void SoundMetalstep()
    {
        SoundSource3D@ ss = node.GetChild("StepSound").GetComponent("SoundSource3D");
        Sound@ s = cache.GetResource("Sound", "Sounds/metalstep.wav");
        ss.frequency = (44100 * Random(0.9, 1.2));
        ss.Play(s);
    }
    
    void ShoopDaWhoop(bool fire)
    {
        SoundSource3D@ lazorSound = m_rightLazor.GetComponent("SoundSource3D");
        Light@ lazorShow = m_rightLazor.GetComponent("Light");
        Node@ lazorHit = scene.GetChild("Laserhit");
        
        
        if (!m_laserFiring && fire)
        {
            // FIRE LAZOR
            m_laserFiring = true;
            m_rightLazor.enabled = true;
            lazorHit.enabled = true;
           lazorSound.sound.looped = true;
        }
        else if (m_laserFiring && fire)
        {
            PhysicsWorld@ pw = scene.GetComponent("PhysicsWorld");
            
            // LAZOR IS FIRING
            m_rightLazor.position = Vector3(0.0f, -0.575f, Random(-3.6f, -3.1f));
            lazorShow.brightness = Random(0.6f, 1.0f);
            
            Vector3 dir = m_rightLazor.worldDirection;
            
            PhysicsRaycastResult foo = pw.RaycastSingle(Ray(m_rightLazor.worldPosition + dir * 2.0f, -dir), 80, 10 | 16 | 32);
            
            lazorHit.position = foo.position;
            
            if (foo.body !is null)
            {
                if (foo.body.node.vars.Contains("Health"))
                {
                    float f = foo.body.node.vars["Health"].GetFloat();
                    f -= node.vars["LaserDamage"].GetFloat() * (1.0f / 60.0f);
                    foo.body.node.vars["Health"] = f;
                }
            }
            
        }
        else if (m_laserFiring && !fire)
        {
            // STOP LAZOR
            m_laserFiring = false;
            m_rightLazor.enabled = false;
            lazorHit.enabled = false;
        }
    }
    
    void DelayedStart()
    {
        
        m_state = E_MECH_PLANTED;
        
        SubscribeToEvent("PhysicsPreStep", "PhysicsUpdate");
        
        m_rotator = node.GetChild("Torso");
        m_rightShoulder = m_rotator.GetChild("R_Shoulder");
        m_rightLazor = m_rightShoulder.GetChild("Flash");
        //m_torsoLower = 
        
        // Set leg nodes
        m_legL.Set(node, "L_Leg", "L_Down", "L_Foot");
        m_legR.Set(node, "R_Leg", "R_Down", "R_Foot");
        
        m_legL.RecalculateFootPos();
        m_legR.RecalculateFootPos();
        
        m_originalLFootPos = m_legL.m_footPos;
        m_originalRFootPos = m_legL.m_footPos;
        
        m_originalPos = node.position;
        m_originalRotation = node.rotation;
        
        
        Print(node.direction.ToString());
        
        m_laserFiring = false;
    }
    
    void AimAt(Vector3 towards, float armX, float armZ)
    {
        Vector3 dir = towards - node.position;
        Vector3 dirnorm = dir.Normalized();
        Vector3 right = Vector3(0, 1, 0).CrossProduct(dirnorm);
        
        Vector3 compensatedH = towards + right * armX;
        compensatedH.y = node.position.y;
        
        Quaternion fish;
        fish.FromLookRotation(-(compensatedH - node.position));
        m_rotator.worldRotation = m_rotator.worldRotation.Slerp(fish, 0.2f);
        
        
        Vector3 down = right.CrossProduct(dirnorm).Normalized();
        Vector3 compensatedV = m_rightShoulder.worldPosition - down * armZ;
        fish.FromEulerAngles(Asin((towards.y - compensatedV.y) / (towards - compensatedV).length ), 0.0f, 0.0f);
        m_rightShoulder.rotation = m_rightShoulder.rotation.Slerp(fish, 0.2f);
        
    }

    
    float frog = 0;
    
    void PhysicsUpdate(StringHash eventType, VariantMap& eventData)
    {
        
        if (node.vars["TeleportRequest"].GetBool())
        {
            m_state = E_MECH_PLANTED;
            node.position = m_originalPos;
            node.rotation = m_originalRotation;
            m_legL.m_footPos = m_originalLFootPos;
            m_legR.m_footPos = m_originalRFootPos;
            
            m_legL.MoveToFootPos();
            m_legR.MoveToFootPos();
            
            m_moveDesire = Vector3();
            
            node.vars["TeleportRequest"] = false;
        }
        
        frog += eventData["TimeStep"].GetFloat();
        
        //Print("frog: " + frog);
        
        //m_legL.m_footPos = Vector3(0, -1.5f + Sin(scene.elapsedTime * 400) * 0.5, Cos(scene.elapsedTime * 400) * 0.5);
        //m_legL.MoveToFootPos();
        
        //m_legR.m_footPos = Vector3(0, -1.5f + Sin(180 + scene.elapsedTime * 400) * 0.5, Cos(180 + scene.elapsedTime * 400) * 0.5);
        //m_legR.MoveToFootPos();
        
        // inputs from ControllerCam
        m_moveDesire -= (m_moveDesire - node.vars["MoveDesire"].GetVector3()) * 0.1f;

        if (m_state == E_MECH_PLANTED)
        {
            // if wants to walk
            if (m_moveDesire.length > m_walkThreshold)
            {
                // pick the furthest back foot
                
                //Matrix3 mat;
                //mat = (mat * node.rotation).inverse();
                
                if (m_legL.m_footPos.z > m_legR.m_footPos.z)
                {
                    // left leg is further back
                    @m_walkPivot = @m_legL;
                    @m_walkLifted = @m_legR;
                }
                else
                {
                    // right leg is further back
                    @m_walkPivot = @m_legR;
                    @m_walkLifted = @m_legL;
                }
                
                m_walkLifted.UnstuckSpaghetti();
                node.Translate(Vector3(0, 0.05f, 0));
                
                m_pivotPos = m_walkPivot.m_foot.worldPosition;
                
                m_state = E_MECH_WALkING;
                m_walkFrame = 0;
                
                //SoundSource3D@ s = (node.GetComponent("SoundSource3D"));
                //s.Play(s.sound);
            }
            else
            {
                float avgFootZ = (m_legL.m_footPos.z + m_legR.m_footPos.z) * 0.5f;
                avgFootZ *= 0.07f;
                m_legL.m_footPos.z -= avgFootZ;
                m_legR.m_footPos.z -= avgFootZ;
                m_legL.MoveToFootPos();
                m_legR.MoveToFootPos();
                node.position += node.direction * avgFootZ;
            }
            
            
            
        }
        
        if (m_state == E_MECH_WALkING)
        {
            // save values because they might be reverted
            Vector3 liftedPrevFootPos = m_walkLifted.m_footPos;
            Vector3 pivotPrevFootPos = m_walkPivot.m_footPos;
            Vector3 liftedPrevPos = m_walkLifted.m_foot.worldPosition;
            Quaternion nodePrevRot = node.rotation;
            Vector3 liftedPrevFootVelocity = m_walkLifted.m_footVelocity;
            Vector3 pivotPrevFootVelocity = m_walkPivot.m_footVelocity;
            

            float spdmulabs = Abs(m_spdmul);
            float plantThreshold = (m_spdmul < 0) ? m_walkPlantThreshold : m_walkBackwardsPlantThreshold;
            bool legMovingDownNow = (plantThreshold > m_walkLifted.m_footPos.z) ^^ (m_spdmul < 0);
            PhysicsWorld@ pw = scene.GetComponent("PhysicsWorld");
            
            if (m_moveDesire.length < m_walkThreshold)
            {
                // want's to stop walking now
                legMovingDownNow = true;
            }
            
            // Forward collision detector
            PhysicsRaycastResult terCast = pw.SphereCast(Ray(node.position + Vector3(0, 2, 0), m_moveDesire), 3, 1, 2);
            if (terCast.body !is null)
            {
                Print("Stop!");
                //m_moveDesire = Vector3(0, 0, 0);
                
                m_moveDesire = m_moveDesire.Normalized();
                
                // Reflect movedesire
                float dot = terCast.normal.DotProduct(-m_moveDesire);
                
                m_moveDesire += terCast.normal * dot * 2;
                m_moveDesire.y = 0;
                m_moveDesire.Normalized();
                
            }
            
           

           
            // Move the lifted leg up then forward spaghetti

            if (legMovingDownNow)
            {
                m_walkLifted.m_footVelocity.y -= 0.01f * spdmulabs;
                m_walkLifted.m_footVelocity.z += 0.0005f * m_spdmul;
            }
            else
            {
                m_walkLifted.m_footVelocity.y += 0.001f * spdmulabs;
                m_walkLifted.m_footVelocity.z -= 0.001f * m_spdmul;
            }
            
            m_walkLifted.m_footVelocity.y = Clamp(m_walkLifted.m_footVelocity.y, -0.03f * spdmulabs, 0.03f * spdmulabs);
            m_walkLifted.m_footVelocity.z = Clamp(m_walkLifted.m_footVelocity.z, -0.04f * spdmulabs, 0.03f * spdmulabs);
            
            m_walkLifted.m_footPos += m_walkLifted.m_footVelocity;
            
            
            // Move Pivot leg backwards
            
            
            if (legMovingDownNow)
            {
                m_walkPivot.m_footVelocity.y += 0.01f * spdmulabs;
                m_walkPivot.m_footVelocity.z += 0.002f * m_spdmul;
            }
            else
            {
                m_walkPivot.m_footVelocity.y -= 0.002f * spdmulabs;
                m_walkPivot.m_footVelocity.z += 0.002f * m_spdmul;
            }
            
            
            m_walkPivot.m_footVelocity.y = Clamp(m_walkPivot.m_footVelocity.y, -0.02f * spdmulabs, 0.02f * spdmulabs);
            m_walkPivot.m_footVelocity.z = Clamp(m_walkPivot.m_footVelocity.z, -0.02f * spdmulabs, 0.02f * spdmulabs);
            
            m_walkPivot.m_footPos += m_walkPivot.m_footVelocity;
            
            m_walkLifted.m_footPos.y = Clamp(m_walkLifted.m_footPos.y, m_walkYLimit.x, m_walkYLimit.y);
            m_walkLifted.m_footPos.z = Clamp(m_walkLifted.m_footPos.z, m_walkZLimit.x, m_walkZLimit.y);
            m_walkPivot.m_footPos.y = Clamp(m_walkPivot.m_footPos.y, m_walkYLimit.x, m_walkYLimit.y);
            m_walkPivot.m_footPos.z = Clamp(m_walkPivot.m_footPos.z, m_walkZLimit.x, m_walkZLimit.y);
            
            //m_legL.m_footPos += m_legL.m_footVelocity;
            
            

            m_legL.MoveToFootPos();
            m_legR.MoveToFootPos();
            
            // Do rotation
            Quaternion dummy;
            
            dummy.FromLookRotation(-m_moveDesire);
            node.rotation = node.rotation.Slerp(dummy, 0.02); 
            
            Vector3 liftedPos = m_walkLifted.m_foot.worldPosition;
            Vector3 liftedDelta = liftedPos - liftedPrevPos;
            
            // Pivot on leg
            Vector3 diff = m_pivotPos - m_walkPivot.m_foot.worldPosition;
            
            node.position += diff;
            
            // Sphere cast the foot
            
            //Print("LiftedDelta: " + liftedDelta.ToString());
            PhysicsRaycastResult footCast = pw.SphereCast(Ray(liftedPrevPos, liftedDelta), 0.5, liftedDelta.length + 0.01, 2);
            
            //Print("liftedDelta: " + liftedDelta.ToString());
            

            
            if (footCast.body !is null)
            {
                // something was hit
                //Print("HIT" + footCast.normal.DotProduct(Vector3(0, 1, 0)));
                
                // revert positions
                m_walkLifted.m_footPos = liftedPrevFootPos;
                m_walkPivot.m_footPos = pivotPrevFootPos;
                m_walkLifted.m_footVelocity = liftedPrevFootVelocity;
                m_walkPivot.m_footVelocity = pivotPrevFootVelocity;
                node.position -= diff;
                node.rotation = nodePrevRot;
                m_walkLifted.MoveToFootPos();
                m_walkPivot.MoveToFootPos();
                
                if (m_moveDesire.length < m_walkThreshold)
                {
                    m_state = E_MECH_PLANTED;
                    SoundMetalstep();
                }
                else if (m_walkLifted.m_footPos.z < m_walkPivot.m_footPos.z || legMovingDownNow)
                {
                    Print("switch");
                    
                    SoundMetalstep();
                    
                    MechLeg@ prevPivot = @m_walkPivot;
                    @m_walkPivot = @m_walkLifted;
                    @m_walkLifted = @prevPivot;
                    
                    m_pivotPos = m_walkPivot.m_foot.worldPosition;
                    
                    m_walkPivot.m_footVelocity *= 0;
                    m_walkLifted.m_footVelocity *= 0;
                    
                    m_walkLifted.UnstuckSpaghetti();
                    node.Translate(Vector3(0, 0.05f, 0));
                }
            }
            
            m_walkFrame ++;
            
           
        }
        
        
        // LAZOR
        Vector3 target = node.vars["Target"].GetVector3();
        AimAt(target, -1.25, -0.574975);
        ShoopDaWhoop(node.vars["LAZOR"].GetBool());
        
        
    }
}

float bsign(bool b)
{
    return b ? 1.0f : -1.0f;
}

int bint(bool b)
{
    return b ? 1 : 0;
}
