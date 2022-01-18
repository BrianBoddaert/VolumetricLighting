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

    void SetCorners()
    {
        Vector3[] FrustumCorners = new Vector3[4];
        Vector3[] NormCorners = new Vector3[4];

        mainCam.CalculateFrustumCorners(new Rect(0, 0, 1, 1), mainCam.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, FrustumCorners);
        for (int i = 0; i < 4; i++)
        {
            NormCorners[i] = mainCam.transform.TransformVector(FrustumCorners[i]);
            NormCorners[i] = NormCorners[i].normalized;
        }
        Debug.DrawRay(new Vector3(0, 0, 0), NormCorners[0], Color.red);   //BL
        Debug.DrawRay(new Vector3(0, 0, 0), NormCorners[1], Color.blue);  //TL
        Debug.DrawRay(new Vector3(0, 0, 0), NormCorners[2], Color.yellow);//TR
        Debug.DrawRay(new Vector3(0, 0, 0), NormCorners[3], Color.green); //BR
        postprocessingShader.SetVector("_BL", NormCorners[0]);
        postprocessingShader.SetVector("_TL", NormCorners[1]);
        postprocessingShader.SetVector("_TR", NormCorners[2]);
        postprocessingShader.SetVector("_BR", NormCorners[3]);
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

        SetCorners();

        Graphics.Blit(src, dst, postprocessingShader);
    }
}
