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
        Shader.SetGlobalVector("_LightDirection", shadowCasterCam.transform.forward);
        Shader.SetGlobalVector("_LightPos", shadowCasterCam.transform.position);
        
        //TEMPMAINCAMERA.lookat
        // Vector4 CAMPOS = new Vector4(TEMPMAINCAMERA.transform.position.x, TEMPMAINCAMERA.transform.position.y, TEMPMAINCAMERA.transform.position.z,1);
        // var temp = viewProj * CAMPOS;

        //Vector3 CAMPOS = viewProj.MultiplyPoint(TEMPMAINCAMERA.transform.position);
        //Debug.Log(CAMPOS.ToString());

    }

}

