using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyShader : MonoBehaviour
{
    public Material postprocessingShader;
    public Camera mainCam;

    // Start is called before the first frame update
    void Start()
    {
        mainCam.depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    // src = scene right before pixel shader
    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        Vector4 camPos = mainCam.transform.position;
        camPos.w = 1;
        Vector4 camDir = mainCam.transform.forward;
        camDir.w = 1;
        Shader.SetGlobalVector("_CameraPosition", camPos);
        Shader.SetGlobalVector("_CamNormal", camDir);
        
        Graphics.Blit(src, dst, postprocessingShader);
    }
}
