using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class PixelShaderScript : MonoBehaviour
{
    public Camera shadowCasterCam;
    public GameObject lightGameObj;
    public int depthTextureSize = 512;
    public float shadowBias = 0.005f;
    private RenderTexture depthTarget;
    public Material volumetricLightingShader;

    private void OnEnable()
    {
        UpdateResources();
    }

    private void OnValidate()
    {
        UpdateResources();
    }

    private void OnPreRender()
    {

        Matrix4x4 mainCamToWorld = shadowCasterCam.cameraToWorldMatrix;
        Matrix4x4 projectionMatrix = shadowCasterCam.projectionMatrix;
        Matrix4x4 inverseViewProjection = GL.GetGPUProjectionMatrix(projectionMatrix, true).inverse;

        // Negate [1,1] to reflect Unity's CBuffer state
        inverseViewProjection[1, 1] *= -1;

        volumetricLightingShader.SetMatrix("_ShadowCamToWorld", mainCamToWorld);
        volumetricLightingShader.SetMatrix("_ShadowCamInverseProjection", inverseViewProjection);
    }
    private void UpdateResources()
    {
        if (shadowCasterCam == null)
        {
            shadowCasterCam = GetComponent<Camera>();

        }

        if (depthTarget == null || depthTarget.width != depthTextureSize)
        {
            int sz = Mathf.Max(depthTextureSize, 16);
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

        volumetricLightingShader.SetMatrix("_ShadowViewProjectionMatrix", viewProj);
        volumetricLightingShader.SetTexture("_ShadowTex", depthTarget);
        volumetricLightingShader.SetFloat("_ShadowBias", shadowBias);
        volumetricLightingShader.SetVector("_LightDirection", shadowCasterCam.transform.forward);
        volumetricLightingShader.SetVector("_LightPos", shadowCasterCam.transform.position);

    }

}

