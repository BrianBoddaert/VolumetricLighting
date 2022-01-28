
Shader "PostProcessing/PixelShader"
{

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scattering ("Scattering", float) = 0
        PI("Pi",float) = 3.14159265359
        _SampleAmount("_SampleAmount", int) = 100
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
            float _SampleAmount;
            sampler2D _ShadowTex;
            float4x4 _ShadowViewProjectionMatrix;
            float3 _LightDirection;
            float3 _PhotonMapSize;

			float4x4 _MainCamToWorld;
			float4x4 _MainCamInverseProjection;

            float4x4 _ShadowCamToWorld;
			float4x4 _ShadowCamInverseProjection;

            float4x4 _DitherPattern;

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
            
            // Mie scattering phase function.
            float HenyeyGreenstein(float angle)
            {
                return ((1.0f -  _Scattering) * (1.0f -  _Scattering)) / (4.0f * PI * pow(1.0f + (_Scattering * _Scattering) - (2.0f * _Scattering) * angle, 1.5f ) );
            }

            // Rayleigh scattering phase function.
            float Rayleigh(float angle)
            {
                return (3 * (1 + (angle * angle))) / (16 * PI);   
            }

            float3 GetWorldPos(float2 uv)
            {
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(uv));
                // from -1 - 1 TO 0 - 1
				float2 uvClip = uv * 2.0 - 1.0;
				float4 clipPos = float4(uvClip, depth, 1.0);
				float4 viewPos = mul(_MainCamInverseProjection, clipPos);
                // perspective divide  
				viewPos /= viewPos.w;
				float3 worldPos = mul(_MainCamToWorld, viewPos).xyz;

                return worldPos;
            }
            float3 GetShadowWorldPos(float2 uv)
            {
				float depth = SAMPLE_DEPTH_TEXTURE(_ShadowTex, UnityStereoTransformScreenSpaceTex(uv)); 
                // from -1 - 1 TO 0 - 1
				float2 uvClip = uv * 2.0 - 1.0;
				float4 clipPos = float4(uvClip, depth, 1.0);
				float4 viewPos = mul(_ShadowCamInverseProjection, clipPos); 
                // perspective divide  
				viewPos /= viewPos.w; 
				float3 worldPos = mul(_ShadowCamToWorld, viewPos).xyz;

                return worldPos;
            }

            fixed4 frag (v2f input) : SV_Target
            {
                
                float3 rayOrigin = _CameraPosition;
                float3 rayEnd = GetWorldPos(input.uv);

                float3 ray = rayEnd - rayOrigin;
                float3 rayDir = normalize(ray); 
                float rayLength = length(ray);
                
                float stepLength = rayLength / _SampleAmount;
                float3 step = rayDir * stepLength;

                float3 currentPosition = rayOrigin;

                float radiance = 0;
              
                float firstIntersectionDepth = -1.0f;

                 /*Chowder pattern */
                 float ditherValue = _DitherPattern[(input.uv.x * _PhotonMapSize.x) % 4][(input.uv.y * _PhotonMapSize.y) % 4];

                for (int i = 0; i < _SampleAmount; i++)
                {
                    float4 samplePointFromLightsPerspective = mul(_ShadowViewProjectionMatrix,float4(currentPosition, 1.0f));

                    // Clip space to screen space perspective divide and from -1 - 1 TO 0 - 1
                    float2 uv = samplePointFromLightsPerspective / samplePointFromLightsPerspective.w * 0.5f + 0.5f;
                    
                    float shadowMapDepth = LinearEyeDepth(tex2D(_ShadowTex, uv).r);
                       
                    float offsetRayLight = distance(_LightPos,currentPosition);
                    float offsetShadowMapDataLight = distance(_LightPos,GetShadowWorldPos(uv));

                    if (offsetShadowMapDataLight > offsetRayLight)
                    {
                    
                       radiance += HenyeyGreenstein(dot(rayDir, _LightDirection)); 
                       if (firstIntersectionDepth == -1)
                       {
                            firstIntersectionDepth = abs(_CameraPosition - currentPosition);
                       }
                     }
                       //currentPosition += step;
                       currentPosition += step * ditherValue;
                       
                }
                
                radiance /= _SampleAmount;

                return float4(radiance,firstIntersectionDepth,0,0);
            }
            ENDCG
        }
    }
}