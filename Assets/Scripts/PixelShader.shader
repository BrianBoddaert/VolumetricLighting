
Shader "PostProcessing/PixelShader"
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
            sampler2D _MainTex;
            fixed PI;
            float _Scattering;
            float _NumberOfSteps;
            sampler2D _ShadowTex;
            float4x4 _ShadowViewProjectionMatrix;
            float3 _LightDirection;
            fixed4 _LightColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                return o;
            }
            
            // Mie scaterring approximated with Henyey-Greenstein phase function.
            float ComputeScattering(float lightDotView)
            {
                float result = 1.0f - _Scattering * _Scattering;
                result /= (4.0f * PI * pow(1.0f + _Scattering * _Scattering - (2.0f * _Scattering) * lightDotView, 1.5f));
                return result;
            }

            fixed4 frag (v2f input) : SV_Target
            {
                // sample depth texture
                float depthNonLinear = tex2D(_CameraDepthTexture, input.uv);

                // forward vector of player's camera
                float3 forward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));
                
                // depth of ray hit
                float depth = LinearEyeDepth(depthNonLinear) * length(forward);
                
                float3 rayOrigin = _CameraPosition;
                float3 rayDir = normalize(forward);
                float3 rayEnd = rayOrigin + rayDir * depth;
                float3 rayVector = rayEnd - rayOrigin;
                float rayLength = length(rayVector);
                
                float stepLength = rayLength / _NumberOfSteps;
                float3 step = rayDir * stepLength;
                float3 currentPosition = rayOrigin;
                float3 accumFog = 0.0f.xxx;
                float4 worldInShadowCameraSpace;

                 for (int i = 0; i < _NumberOfSteps; i++)
                {
                    currentPosition = rayOrigin + step * i;
                    worldInShadowCameraSpace = mul(float4(currentPosition, 1.0f), _ShadowViewProjectionMatrix);
                    //worldInShadowCameraSpace /= worldInShadowCameraSpace.w; //Is this necessary?

                   if (worldInShadowCameraSpace.x > -1.0 || worldInShadowCameraSpace.x < 1.0 ||
                       worldInShadowCameraSpace.y > -1.0 || worldInShadowCameraSpace.y < 1.0)
                       {
                            float shadowMapDepthNonLinear = tex2D(_ShadowTex, worldInShadowCameraSpace.xy);
                            float shadowMapDepth = LinearEyeDepth(shadowMapDepthNonLinear) * length(forward);
                            
                            if (shadowMapDepth > worldInShadowCameraSpace.z)
                            {
                             accumFog += 1;
                            // Temporarily disabled this for testing
                            // accumFog += ComputeScattering(dot(rayDir, _LightDir)).xxx * _LightColor; 
                            }
                       }
                  }

                accumFog /= _NumberOfSteps;
                
                return float4(accumFog,1);
            }
            ENDCG
        }
    }
}