using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyShader : MonoBehaviour
{
    public Material volumetricLightingShader;
    public Material combineTextureWithOriginalColor;
    public Camera mainCam;
    public float photonMapSizeScale = 0.5f;
    // Start is called before the first frame update
    void Start()
    {
        mainCam.depthTextureMode = DepthTextureMode.Depth;

        Matrix4x4 ditherPatternMatrix = Matrix4x4.identity;
        ditherPatternMatrix.SetRow(0, new Vector4(0.0f, 0.5f, 0.125f, 0.625f));
        ditherPatternMatrix.SetRow(1, new Vector4(0.75f, 0.22f, 0.875f, 0.375f));
        ditherPatternMatrix.SetRow(2, new Vector4(0.1875f, 0.6875f, 0.0625f, 0.5625f));
        ditherPatternMatrix.SetRow(3, new Vector4(0.9375f, 0.4375f, 0.8125f, 0.3125f));

        volumetricLightingShader.SetMatrix("_DitherPattern", ditherPatternMatrix);
    }

    // Update is called once per frame
    void Update()
    {

    }

    private void OnPreRender()
    {
        Matrix4x4 mainCamToWorld = mainCam.cameraToWorldMatrix;
        Matrix4x4 projectionMatrix = mainCam.projectionMatrix;
        Matrix4x4 inverseViewProjection = GL.GetGPUProjectionMatrix(projectionMatrix, true).inverse;

        // Negate [1,1] to reflect Unity's CBuffer state
        inverseViewProjection[1, 1] *= -1;
        
        volumetricLightingShader.SetMatrix("_MainCamToWorld", mainCamToWorld);
        volumetricLightingShader.SetMatrix("_MainCamInverseProjection", inverseViewProjection);

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

        // Render photon map
        int photonMapWidth = (int)(Screen.width * photonMapSizeScale);
        int photonMapHeight = (int)(Screen.height * photonMapSizeScale);
        RenderTexture lightMap = new RenderTexture(photonMapWidth, photonMapHeight, 16, RenderTextureFormat.Default, RenderTextureReadWrite.sRGB);
        volumetricLightingShader.SetVector("_PhotonMapSize",new Vector3(photonMapWidth, photonMapHeight,0));
        Graphics.Blit(src, lightMap, volumetricLightingShader);

        // Render blur
        combineTextureWithOriginalColor.SetTexture("_VolumetricLightingTex", lightMap);
        combineTextureWithOriginalColor.SetVector("_PhotonMapSize", new Vector3(photonMapWidth, photonMapHeight, 0));
        Graphics.Blit(src, dst, combineTextureWithOriginalColor);

    }
}
