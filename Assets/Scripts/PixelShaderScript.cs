using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class PixelShaderScript : MonoBehaviour
{
    public Camera shadowCasterCam;
    public GameObject lightGameObj;
    public int textureSize = 512;
    public float shadowBias = 0.005f;

    private RenderTexture depthTarget;

    private void OnEnable()
    {
        UpdateResources();
    }

    private void OnValidate()
    {
        UpdateResources();
    }

    private void UpdateResources()
    {
        if (shadowCasterCam == null)
        {
            shadowCasterCam = GetComponent<Camera>();
            shadowCasterCam.depth = -1000;
        }

        if (depthTarget == null || depthTarget.width != textureSize)
        {
            int sz = Mathf.Max(textureSize, 16);
            depthTarget = new RenderTexture(sz, sz, 16, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
            depthTarget.wrapMode = TextureWrapMode.Clamp;
            depthTarget.filterMode = FilterMode.Bilinear;
            depthTarget.autoGenerateMips = false;
            depthTarget.useMipMap = false;
            shadowCasterCam.targetTexture = depthTarget;
        }
    }

    private void OnPostRender()
    {
        Matrix4x4 view = shadowCasterCam.worldToCameraMatrix;
        Matrix4x4 proj = shadowCasterCam.projectionMatrix;
        Matrix4x4 viewProj = proj * view;

        Shader.SetGlobalMatrix("_ShadowViewProjectionMatrix", viewProj);
        Shader.SetGlobalTexture("_ShadowTex", depthTarget);
        Shader.SetGlobalFloat("_ShadowBias", shadowBias);
        Shader.SetGlobalVector("_SunDirection", shadowCasterCam.transform.rotation.eulerAngles);

    }

}