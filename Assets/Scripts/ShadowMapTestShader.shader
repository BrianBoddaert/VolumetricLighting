Shader "PostProcessing/ShadowMapTestShader"
{
 Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scattering ("Scattering", float) = 0.5
        PI("Pi",float) = 3.14159265359
        _NumberOfSteps("_NumberOfSteps", int) = 100
        SunColor("SunColor",Color) = (255,255,0,0)
    }

    SubShader
    {
        
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #pragma enable_d3d11_debug_symbols
     
            uniform sampler2D _CameraDepthTexture; 
            float4 _CameraPosition;
            float4 _LightPos;
            sampler2D _MainTex;
            fixed PI;
            float _Scattering;
            float _NumberOfSteps;
            sampler2D _ShadowTex;
            float4x4 _ShadowViewProjectionMatrix;
            float3 _LightDirection;
            fixed4 _LightColor;



            // TEMP v


            float4 _BL;
            float4 _TL;
            float4 _TR;
            float4 _BR;
 
            float4 NormalLeft;
            float4 NormalRight;
            float4 NormalH;



            // TEMP ^
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;

            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f input) : SV_Target
            {


                        // sample depth texture
                        float depthNonLinear = tex2D(_CameraDepthTexture, float2(0.5,0.5));

                        // forward vector of player's camera
                        float3 forward = float3(1,0,0);
                        
                        // depth of ray hit
                        float depth = LinearEyeDepth(depthNonLinear) * length(forward);
                        
                        float3 rayOrigin = _CameraPosition; // CHANGED FROM CAM POS
                        float3 rayDir = forward;
                        float3 rayEnd = rayOrigin + rayDir * depth;
                        float3 rayVector = rayEnd - rayOrigin;
                        float rayLength = length(rayVector);
                        
                        float stepLength = rayLength / _NumberOfSteps;
                        float3 step = rayDir * stepLength;
                        float3 currentPosition = rayOrigin;
                        float3 accumFog = 0.0f.xxx;
                        float4 pointInProjectedSpace;

                        for (int i = 0; i < _NumberOfSteps; i++)
                        {
                            currentPosition = rayOrigin + step * i;
                            pointInProjectedSpace = mul(_ShadowViewProjectionMatrix,float4(currentPosition, 1.0f));

                            // Clip space to screen space perspective divide and from -1 - 1 TO 0 - 1
                            float2 uv = pointInProjectedSpace / pointInProjectedSpace.w * 0.5f + 0.5f;

                            float shadowMapDepthNonLinear = tex2D(_ShadowTex, uv);
                            float shadowMapDepth = LinearEyeDepth(shadowMapDepthNonLinear);
                            
                            float offsetRayLight = distance(_LightPos,currentPosition);

                            if (uv.x > 0 && uv.x < 1.0 &&
                             uv.y > 0 && uv.y < 1.0)
                             {
                                    if (shadowMapDepth > offsetRayLight)
                                    {
                                       return float4(1,0,0,1);
                                    }
                            }

                        }

                float shadowMapDepthNonLinear = tex2D(_ShadowTex, input.uv);
                float shadowMapDepth = LinearEyeDepth(shadowMapDepthNonLinear);
               return shadowMapDepth / 100;

            }
            ENDCG
        }
    }
}
