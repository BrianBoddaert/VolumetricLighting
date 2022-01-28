Shader "PostProcessing/CombiningShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightColor("_LightColor",Color) = (255,255,0,0)
        _Intensity ("_Intensity", float) = 1
        _BilateralFilterDistanceFallOff("_BilateralFilterDistanceFallOff", float) = 0.05

    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM


            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #pragma enable_d3d11_debug_symbols

            uniform sampler2D _VolumetricLightingTex;
            fixed4 _LightColor;
            float _Intensity;
            float3 _PhotonMapSize;
            float _BilateralFilterDistanceFallOff;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {           
                float upSampledDepth = tex2D(_VolumetricLightingTex,i.uv).y;

                float2 pixelSize = float2(1,1) / _PhotonMapSize.xy;
                float2 pixelSizeNegative = pixelSize * -1;

                int2 currentPixel = _PhotonMapSize.xy * i.uv.xy;

                float xOffset = currentPixel.x % 2 == 0 ? pixelSizeNegative.x : pixelSize.x;
                float yOffset = currentPixel.x % 2 == 0 ? pixelSizeNegative.y : pixelSize.y;

                float2 offsets[] = {float2(0, 0),
                                    float2(0, yOffset),
                                    float2(xOffset, 0),
                                    float2(xOffset, yOffset)};

                float totalWeight = 0.0f;
                float3 volumetricLight = 0.0f.xxx;
                
                // Apply Blur
                for (int j = 0; j < 4; j ++)
                {
                    float2 neighborUv = i.uv + offsets[j];

                    float3 downscaledColor = tex2D(_VolumetricLightingTex,neighborUv);
                    float downscaledDepth = downscaledColor.y;
                    downscaledColor.xyz = downscaledColor.x;

                    // Bilateral filter
                    float currentWeight = 1.0f;
                    currentWeight *= max(0.0f, 1.0f - _BilateralFilterDistanceFallOff * abs(downscaledDepth - upSampledDepth));

                    volumetricLight += downscaledColor * currentWeight;
                    totalWeight += currentWeight;
                }

                const float epsilon = 0.0001f;
                volumetricLight.xyz  /= (totalWeight + epsilon);

                volumetricLight = clamp(volumetricLight,0,1);
                volumetricLight *= _Intensity;
            
/* Dither */        //return float4(tex2D(_VolumetricLightingTex,i.uv).xxx,0) * _Intensity;
/* Dither_ */       //return tex2D(_MainTex,i.uv) + float4(tex2D(_VolumetricLightingTex,i.uv).xxx,0) * _Intensity * _LightColor ;
/* Dither+Blur */   //return float4(volumetricLight,0);
/* Dither+Blur+ */  return tex2D(_MainTex,i.uv) + float4(volumetricLight,0) * _LightColor;
            }
            ENDCG
        }
    }
}
