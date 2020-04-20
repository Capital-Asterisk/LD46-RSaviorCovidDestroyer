 
class ControllerCam : ScriptObject
{

    Node@ m_mech;
    Node@ m_cameraNode;
    float m_zoom = 15.0f;

    void DelayedStart()
    {
        
        m_mech = scene.GetChild("MechGuy");
        SubscribeToEvent("PhysicsPreStep", "PhysicsPreUpdate");
        SubscribeToEvent("RenderUpdate", "CameraUpdate");
        
        m_cameraNode = node.GetChild("CameraNode");
        
        Print("Camera is alive");
        
        audio.listener = m_cameraNode.GetComponent("SoundListener");
    }

    
    void PhysicsPreUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (scene.GetChild("TheTruck").vars["Health"].GetFloat() <= 0.0f)
        {
            return;
        }
        
        // Spaghetti input
        Vector3(bint(input.keyDown[KEY_Q]) - bint(input.keyDown[KEY_E]), bint(input.keyDown[KEY_D]) - bint(input.keyDown[KEY_A]), bint(input.keyDown[KEY_W]) - bint(input.keyDown[KEY_S]));
        
        
        Vector3 joystick;
        
        bool up = input.keyDown[KEY_W];
        bool dn = input.keyDown[KEY_S];
        bool lf = input.keyDown[KEY_A];
        bool rt = input.keyDown[KEY_D];
        
        joystick.z = bint(up) + bint(lf) - bint(dn) - bint(rt) ; 
        joystick.x = bint(up) + bint(rt) - bint(dn) - bint(lf); 
        
        m_mech.vars["MoveDesire"] = joystick;
        
        
        // zoom
        m_zoom = Clamp(m_zoom - input.mouseMoveWheel, 5.0f, 35.0f);
        m_cameraNode.position += (Vector3(-m_zoom, m_zoom * 1.4f, -m_zoom) - m_cameraNode.position) * 0.1f;
        
        
        // LAZOR
        m_mech.vars["LAZOR"] = input.mouseButtonDown[MOUSEB_LEFT];
    }
    
    void CameraUpdate(StringHash eventType, VariantMap& eventData)
    {
        Vector3 camTgt = m_mech.position + m_mech.direction * -(m_zoom - 5.0f) * 0.4f;
        Vector3 diff = camTgt - node.position;
        //diff.y = 0;
        diff *= 0.02;
        node.position += diff;
        
        
        Vector3 mechTarget;
        // mouse ray
        Camera@ cam = m_cameraNode.GetComponent("Camera");
        PhysicsWorld@ pw = scene.GetComponent("PhysicsWorld");
        
        Vector2 mouseNorm(input.mousePosition.x - (graphics.width - graphics.width / 2),
                          -input.mousePosition.y + (graphics.height - graphics.height / 2));
        
        Ray mouseRay = cam.GetScreenRay(float(input.mousePosition.x) / graphics.width,
                                        float(input.mousePosition.y) / graphics.height);
        
        float max = (m_cameraNode.worldPosition - m_mech.position).length;
        
        //mouseRay.direction = m_cameraNode.worldRotation * mouseRay.direction;
        PhysicsRaycastResult foo = pw.RaycastSingle(mouseRay, max, 8 | 16 | 32);
        
        // if nothing hit, cast again but with something else
        if (foo.body is null)
        {
            mouseRay.origin = mouseRay.origin + mouseRay.direction * max;
            
            foo = pw.RaycastSingle(mouseRay, 50, 10 | 16 | 32);
        }
        
        if (foo.body !is null)
        {
            m_mech.vars["Target"] = foo.position;
        }
    }
}


int bint(bool b)
{
    return b ? 1 : 0;
}
