
Shader "PostProcessing/PixelShader"
{

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scattering ("Scattering", float) = 0.5
        _Intensity ("_Intensity", float) = 1
        PI("Pi",float) = 3.14159265359
        _NumberOfSteps("_NumberOfSteps", int) = 100
        _LightColor("_LightColor",Color) = (255,255,0,0)
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
            float _Intensity;
            float _NumberOfSteps;
            sampler2D _ShadowTex;
            float4x4 _ShadowViewProjectionMatrix;
            float3 _LightDirection;
            fixed4 _LightColor;

            // Variables for finding the current pixel position
            float4 _BL; // Bottom Left
            float4 _TL;
            float4 _TR;
            float4 _BR;
            float4 NormalLeft;
            float4 NormalRight;
            float4 NormalH;


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
                // Formula from GPU Pro 5
                return ((1.0f -  _Scattering) * (1.0f -  _Scattering)) / (4.0f * PI * pow(1.0f + (_Scattering * _Scattering) - (2.0f * _Scattering) * angle, 1.5f ) );
            }

            // Rayleigh scattering phase function.
            float Rayleigh(float angle)
            {
                return (3 * (1 + (angle * angle))) / (16 * PI);   
            }

            fixed4 frag (v2f input) : SV_Target
            {
                // Getting the position of the pixel.
                NormalLeft = lerp(_BL, _TL,input.uv.y);
                NormalRight = lerp(_BR, _TR, input.uv.y);
                NormalH = lerp(NormalLeft, NormalRight,input.uv.x);
                NormalH = normalize(NormalH);

                // sample depth texture
                float depthNonLinear = tex2D(_CameraDepthTexture, input.uv);

                // forward vector of player's camera
                float3 forward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));
                
                // depth of current pixel
                float depth = LinearEyeDepth(depthNonLinear) * length(forward);
                
                float3 rayOrigin = _CameraPosition;
                float3 rayDir = NormalH;
                float3 rayEnd = rayOrigin + rayDir * depth;
                float3 rayVector = rayEnd - rayOrigin;
                float rayLength = length(rayVector);
                
                float stepLength = rayLength / _NumberOfSteps;
                float3 step = rayDir * stepLength;
                float3 currentPosition = rayOrigin;
                float accumFog = 0;

                 for (int i = 0; i < _NumberOfSteps; i++)
                {
                    currentPosition = rayOrigin + step * i;
                    float4 samplePointFromLightsPerspective = mul(_ShadowViewProjectionMatrix,float4(currentPosition, 1.0f));

                    // Clip space to screen space perspective divide and from -1 - 1 TO 0 - 1
                    float2 uv = samplePointFromLightsPerspective / samplePointFromLightsPerspective.w * 0.5f + 0.5f;

                   if (uv.x > 0 && uv.x < 1.0 &&
                       uv.y > 0 && uv.y < 1.0)
                       {
                            float shadowMapDepthNonLinear = tex2D(_ShadowTex, uv);
                            float shadowMapDepth = LinearEyeDepth(shadowMapDepthNonLinear);
                            
                            float offsetRayLight = distance(_LightPos,currentPosition);

                            if (shadowMapDepth > offsetRayLight)
                            {
                            // - 90
                               accumFog += Rayleigh(dot(rayDir, _LightDirection)); 
                               //accumFog += HenyeyGreenstein(dot(rayDir, _LightDirection)); 
                            }
                       }

                  }
         
                accumFog /= _NumberOfSteps;
                accumFog = clamp(accumFog,0,255);
                accumFog *= _Intensity;
               
                //return accumFog;
                return tex2D(_MainTex,input.uv) + accumFog * _LightColor;
            }
            ENDCG
        }
    }
}