// Made with Amplify Shader Editor v1.9.3.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Hidden/NOT_Lonely/Weatherade/SRS_ParticleSystem_Render"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_NearBlurFalloff("_NearBlurFalloff", Float) = 0.8
		_MainTex("Texture", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_OpacityFadeFalloff("_OpacityFadeFalloff", Float) = 1
		_OpacityFadeStartDistance("_OpacityFadeStartDistance", Float) = 1
		_NearBlurDistance("_NearBlurDistance", Int) = 8
		_sizeMinMax("_sizeMinMax", Vector) = (0.004,0.008,0,0)
		_lightsCount("_lightsCount", Int) = 5
		[HideInInspector]_startRotationMinMax("_startRotationMinMax", Vector) = (0,0,0,0)
		[HideInInspector]_rotationSpeedMinMax("_rotationSpeedMinMax", Vector) = (-5,5,0,0)
		_SRS_particles("_SRS_particles", 2D) = "white" {}
		_gradientTexOLT("gradientTexOLT", 2D) = "white" {}
		[HDR]_color("color", Color) = (1,1,1,1)
		[HideInInspector]_gradientsRatio("_gradientsRatio", Float) = 0.5
		_sunMaskSize("Sun Mask Size", Float) = 0
		_sunMaskSharpness("Sun Mask Sharpness", Range( 0 , 1)) = 0
		_sparklesStartDistance("Sparkles Start Distance", Float) = 1
		_lightDirection("lightDirection", Vector) = (0,0,0,0)
		[HDR]_lightColor("lightColor", Color) = (1,1,1,1)
		_stretchingMultiplier("_stretchingMultiplier", Float) = 1
		_pointLightsIntensity("_pointLightsIntensity", Float) = 1
		_spotLightsIntensity("_spotLightsIntensity", Float) = 1
		_ColorMultiplier("ColorMultiplier", Color) = (1,1,1,1)
		_SimTexSize("SimTexSize", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Unlit" }

		Cull Front
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_COLOR
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local _SPARKLES
			#pragma shader_feature_local _REFRACTION
			#pragma shader_feature_local _COLOR_GRADIENT
			#pragma shader_feature_local _RAND_GRADIENT_OLT
			#pragma shader_feature_local _RAND_GRADIENT
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile _ _FORWARD_PLUS
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _color;
			float4 _ColorMultiplier;
			float4 _Normal_ST;
			float4 _MainTex_ST;
			float4 _lightColor;
			float3 _lightDirection;
			float2 _SimTexSize;
			float2 _sizeMinMax;
			float2 _rotationSpeedMinMax;
			float2 _startRotationMinMax;
			float _NearBlurFalloff;
			int _NearBlurDistance;
			float _sparklesStartDistance;
			float _pointLightsIntensity;
			float _sunMaskSize;
			float _spotLightsIntensity;
			float _OpacityFadeStartDistance;
			int _lightsCount;
			float _gradientsRatio;
			float _stretchingMultiplier;
			float _sunMaskSharpness;
			float _OpacityFadeFalloff;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			TEXTURE2D(_SRS_particles);
			TEXTURE2D(_gradientTexOLT);
			TEXTURE2D(_Normal);
			SAMPLER(sampler_Normal);
			float4 _srs_lightsPositions[(int)16.0];
			float4 _srs_lightsColors[(int)16.0];
			float4 _srs_spotsPosRange[(int)16.0];
			float4 _srs_spotsDirAngle[(int)16.0];
			float4 _srs_spotsColors[(int)16.0];
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);


			float4 ReadPixels1_g13( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float3 CalculateCustomLighting( float3 worldPos )
			{
				float4 ShadowCoords = float4(0, 0, 0, 0);
				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord(worldPos);
					#endif
				#endif
				float3 indirectLighting = SampleSH(half3(0, 1, 0));
				Light mainLight = GetMainLight(ShadowCoords);
				float mainLightAtten = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
				float3 lighting = _MainLightColor.rgb * mainLightAtten;
				lighting += indirectLighting;
				return lighting;
			}
			
			float4 ReadPixels1_g24( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g22( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g21( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g23( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			
			float4 PointsMask7_g45( float positionsArray, float colorsArray, float4 screenPosN, float3 worldPos, int lightsCount )
			{
				float4 mask = 0;
				for(int i = 0; i < lightsCount; i++)
				{
					if(_srs_lightsPositions[i].w > 0)
					{
						float4 worldToClip = mul(UNITY_MATRIX_VP, float4(_srs_lightsPositions[i].xyz, 1.0));
						float3 worldToClipN = worldToClip.xyz / worldToClip.w;
						float linearDepth = Linear01Depth(worldToClipN.z, _ZBufferParams);
						float linearScreenDepth = Linear01Depth(SampleSceneDepth(screenPosN.xy), _ZBufferParams);
						float dist = distance(worldPos, _srs_lightsPositions[i].xyz) * 2;
						//float circle = 1/dist * _srs_lightsPositions[i].w * 0.5;
						float attn = 1.0 / (10.0 + _srs_lightsPositions[i].w * 0.5 * dist + 1 * dist * dist) * _srs_lightsPositions[i].w * 10;
						mask += attn.xxxx * half4(_srs_lightsColors[i].xyz, 1) /* * step(linearDepth, linearScreenDepth)*/; //TODO: add depth mask
						//mask = max(mask, 1-(distance(worldPos, (_srs_lightsPositions[i]).xyz)  / _srs_lightsPositions[i].w)) * step(linearDepth, sceneDepth);
						//mask = max(mask, 1-(distance(worldPos, (_srs_lightsPositions[i]).xyz)  / _srs_lightsPositions[i].w)) * step(linearDepth, sceneDepth) * step(linearDepth, linearScreenDepth);
					}	
				}
				return mask;
			}
			
			float4 SpotsMask18_g45( int spotsCount, float3 worldPos, float4 screenPosN, float spotsPosArray, float spotsDirArray, float spotsColorArray )
			{
				float4 mask = 0;
				for(int i = 0; i < spotsCount; i++)
				{
					if(_srs_spotsPosRange[i].w > 0)
					{
						float4 worldToClip = mul(UNITY_MATRIX_VP, float4(_srs_spotsPosRange[i].xyz, 1.0));
						float3 worldToClipN = worldToClip.xyz / worldToClip.w;
						float linearDepth = Linear01Depth(worldToClipN.z, _ZBufferParams);
						float linearScreenDepth = Linear01Depth(SampleSceneDepth(screenPosN.xy), _ZBufferParams);
						float dist = distance(worldPos, _srs_spotsPosRange[i].xyz);
						float attn = 1 / (10 + _srs_spotsPosRange[i].w * 0.5 * dist + 1 * dist * dist) * _srs_spotsPosRange[i].w * 50;
						float3 dir = normalize(worldPos - _srs_spotsPosRange[i].xyz);
						float angle = acos(clamp(dot(dir, _srs_spotsDirAngle[i].xyz), 0.00001, 1.0));
						float spotAngleRad = radians(_srs_spotsDirAngle[i].w * 0.5);
						float4 cone = saturate(1 - angle/spotAngleRad) * attn * half4(_srs_spotsColors[i].xyz, 1) *  _srs_spotsColors[i].w;
						//cone = dist < 0.2 ? 0 : cone;
						//mask += (cone + pow(attn, 3) * _srs_spotsColors[i].xyz * _srs_spotsColors[i].w * haloIntensity) * step(linearDepth, linearScreenDepth);
						mask += cone /* * step(linearDepth, linearScreenDepth)*/; //TODO: add depth mask
					}
				}
				return mask;
			}
			
			float4 ReadPixels1_g31( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float temp_output_1165_0 = ( v.ase_vertexID * 0.25 );
				int u1_g13 = (int)( temp_output_1165_0 % _SimTexSize.x );
				int v1_g13 = (int)( temp_output_1165_0 / _SimTexSize.y );
				Texture2D tex1_g13 =(Texture2D)_SRS_particles;
				float4 localReadPixels1_g13 = ReadPixels1_g13( u1_g13 , v1_g13 , tex1_g13 );
				float4 temp_output_1206_0 = localReadPixels1_g13;
				float3 temp_output_1_0_g14 = (temp_output_1206_0).xyz;
				float3 temp_output_6_0_g14 = frac( temp_output_1_0_g14 );
				float3 particlePos952 = ( ( temp_output_1_0_g14 - temp_output_6_0_g14 ) / 1000.0 );
				float3 temp_cast_2 = (1.0).xxx;
				float3 direction975 = ( ( temp_output_6_0_g14 * 2.0 ) - temp_cast_2 );
				float3 temp_output_977_0 = ( direction975 * _stretchingMultiplier );
				float2 temp_cast_3 = (1.0).xx;
				float mulTime588 = _TimeParameters.x * (_rotationSpeedMinMax.x + (v.ase_color.a - 0.0) * (_rotationSpeedMinMax.y - _rotationSpeedMinMax.x) / (1.0 - 0.0));
				float cos587 = cos( ( mulTime588 + ( (_startRotationMinMax.x + (v.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float sin587 = sin( ( mulTime588 + ( (_startRotationMinMax.x + (v.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float2 rotator587 = mul( ( ( ( v.ase_texcoord.xy * 2.0 ) - temp_cast_3 ) * (_sizeMinMax.x + (v.ase_color.a - 0.0) * (_sizeMinMax.y - _sizeMinMax.x) / (1.0 - 0.0)) ) - float2( 0,0 ) , float2x2( cos587 , -sin587 , sin587 , cos587 )) + float2( 0,0 );
				float2 break252 = rotator587;
				float flakeOffset_x231 = break252.x;
				float flakeOffset_y253 = break252.y;
				float3 normalizeResult956 = normalize( ( particlePos952 - _WorldSpaceCameraPos ) );
				float3 normalizeResult961 = normalize( cross( temp_output_977_0 , normalizeResult956 ) );
				float3 billboard239 = ( ( temp_output_977_0 * flakeOffset_x231 ) + ( flakeOffset_y253 * normalizeResult961 ) );
				float3 temp_output_261_0 = ( particlePos952 + billboard239 );
				float3 worldToObj558 = mul( GetWorldToObjectMatrix(), float4( temp_output_261_0, 1 ) ).xyz;
				float3 vPos633 = worldToObj558;
				
				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord4 = screenPos;
				
				o.ase_texcoord3.x = v.ase_vertexID;
				o.ase_texcoord3.yz = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vPos633;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float temp_output_1165_0 = ( IN.ase_texcoord3.x * 0.25 );
				int u1_g13 = (int)( temp_output_1165_0 % _SimTexSize.x );
				int v1_g13 = (int)( temp_output_1165_0 / _SimTexSize.y );
				Texture2D tex1_g13 =(Texture2D)_SRS_particles;
				float4 localReadPixels1_g13 = ReadPixels1_g13( u1_g13 , v1_g13 , tex1_g13 );
				float4 temp_output_1206_0 = localReadPixels1_g13;
				float3 temp_output_1_0_g14 = (temp_output_1206_0).xyz;
				float3 temp_output_6_0_g14 = frac( temp_output_1_0_g14 );
				float3 particlePos952 = ( ( temp_output_1_0_g14 - temp_output_6_0_g14 ) / 1000.0 );
				float3 temp_cast_2 = (1.0).xxx;
				float3 direction975 = ( ( temp_output_6_0_g14 * 2.0 ) - temp_cast_2 );
				float3 temp_output_977_0 = ( direction975 * _stretchingMultiplier );
				float2 temp_cast_3 = (1.0).xx;
				float mulTime588 = _TimeParameters.x * (_rotationSpeedMinMax.x + (IN.ase_color.a - 0.0) * (_rotationSpeedMinMax.y - _rotationSpeedMinMax.x) / (1.0 - 0.0));
				float cos587 = cos( ( mulTime588 + ( (_startRotationMinMax.x + (IN.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float sin587 = sin( ( mulTime588 + ( (_startRotationMinMax.x + (IN.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float2 rotator587 = mul( ( ( ( IN.ase_texcoord3.yz * 2.0 ) - temp_cast_3 ) * (_sizeMinMax.x + (IN.ase_color.a - 0.0) * (_sizeMinMax.y - _sizeMinMax.x) / (1.0 - 0.0)) ) - float2( 0,0 ) , float2x2( cos587 , -sin587 , sin587 , cos587 )) + float2( 0,0 );
				float2 break252 = rotator587;
				float flakeOffset_x231 = break252.x;
				float flakeOffset_y253 = break252.y;
				float3 normalizeResult956 = normalize( ( particlePos952 - _WorldSpaceCameraPos ) );
				float3 normalizeResult961 = normalize( cross( temp_output_977_0 , normalizeResult956 ) );
				float3 billboard239 = ( ( temp_output_977_0 * flakeOffset_x231 ) + ( flakeOffset_y253 * normalizeResult961 ) );
				float3 temp_output_261_0 = ( particlePos952 + billboard239 );
				float3 vPosWS1263 = temp_output_261_0;
				float3 worldPos1325 = vPosWS1263;
				float3 localCalculateCustomLighting1325 = CalculateCustomLighting( worldPos1325 );
				float3 lighting1152 = localCalculateCustomLighting1325;
				float temp_output_2_0_g15 = (temp_output_1206_0).w;
				float temp_output_3_0_g15 = frac( temp_output_2_0_g15 );
				float lifetime662 = ( ( temp_output_2_0_g15 - temp_output_3_0_g15 ) / 1000.0 );
				float maxLifetime669 = ( 1000.0 * temp_output_3_0_g15 );
				float lerpResult1232 = lerp( (float)256 , 0.0 , (0.0 + (lifetime662 - 0.0) * (1.0 - 0.0) / (maxLifetime669 - 0.0)));
				float lifetimeUVx683 = lerpResult1232;
				int u1_g24 = (int)lifetimeUVx683;
				int v1_g24 = (int)0.0;
				Texture2D tex1_g24 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g24 = ReadPixels1_g24( u1_g24 , v1_g24 , tex1_g24 );
				float4 colorOLT_A673 = localReadPixels1_g24;
				int u1_g22 = (int)( IN.ase_color.a * 256.0 );
				int v1_g22 = (int)0.0;
				Texture2D tex1_g22 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g22 = ReadPixels1_g22( u1_g22 , v1_g22 , tex1_g22 );
				float4 gradient_A750 = localReadPixels1_g22;
				int u1_g21 = (int)( IN.ase_color.a * 256.0 );
				int v1_g21 = (int)1.0;
				Texture2D tex1_g21 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g21 = ReadPixels1_g21( u1_g21 , v1_g21 , tex1_g21 );
				float4 gradient_B762 = localReadPixels1_g21;
				float blend767 = step( IN.ase_color.a , _gradientsRatio );
				float4 lerpResult765 = lerp( gradient_A750 , gradient_B762 , blend767);
				#ifdef _RAND_GRADIENT
				float4 staticSwitch743 = lerpResult765;
				#else
				float4 staticSwitch743 = colorOLT_A673;
				#endif
				int u1_g23 = (int)lifetimeUVx683;
				int v1_g23 = (int)1.0;
				Texture2D tex1_g23 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g23 = ReadPixels1_g23( u1_g23 , v1_g23 , tex1_g23 );
				float4 colorOLT_B727 = localReadPixels1_g23;
				float4 lerpResult735 = lerp( colorOLT_A673 , colorOLT_B727 , blend767);
				#ifdef _RAND_GRADIENT_OLT
				float4 staticSwitch736 = lerpResult735;
				#else
				float4 staticSwitch736 = staticSwitch743;
				#endif
				#ifdef _COLOR_GRADIENT
				float4 staticSwitch720 = staticSwitch736;
				#else
				float4 staticSwitch720 = _color;
				#endif
				float4 color740 = ( staticSwitch720 * _ColorMultiplier );
				float3 temp_output_1310_0 = (color740).rgb;
				float4 screenPos = IN.ase_texcoord4;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 uv_Normal = IN.ase_texcoord3.yz * _Normal_ST.xy + _Normal_ST.zw;
				float3 unpack988 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal, sampler_Normal, uv_Normal ), 1.0 );
				unpack988.z = lerp( 1, unpack988.z, saturate(1.0) );
				float4 fetchOpaqueVal990 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ( ase_grabScreenPosNorm + float4( unpack988 , 0.0 ) ).xy ), 1.0 );
				#ifdef _REFRACTION
				float3 staticSwitch1156 = ( temp_output_1310_0 * saturate( (fetchOpaqueVal990).rgb ) );
				#else
				float3 staticSwitch1156 = temp_output_1310_0;
				#endif
				float3 temp_output_1265_0 = ( lighting1152 * staticSwitch1156 );
				float positionsArray7_g45 = _srs_lightsPositions[0].x;
				float colorsArray7_g45 = _srs_lightsColors[0].r;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 screenPosN7_g45 = ase_screenPosNorm;
				float3 temp_output_28_0_g45 = vPosWS1263;
				float3 worldPos7_g45 = temp_output_28_0_g45;
				int temp_output_9_0_g45 = _lightsCount;
				int lightsCount7_g45 = temp_output_9_0_g45;
				float4 localPointsMask7_g45 = PointsMask7_g45( positionsArray7_g45 , colorsArray7_g45 , screenPosN7_g45 , worldPos7_g45 , lightsCount7_g45 );
				int spotsCount18_g45 = temp_output_9_0_g45;
				float3 worldPos18_g45 = temp_output_28_0_g45;
				float4 screenPosN18_g45 = ase_screenPosNorm;
				float spotsPosArray18_g45 = _srs_spotsPosRange[0].x;
				float spotsDirArray18_g45 = _srs_spotsDirAngle[0].x;
				float spotsColorArray18_g45 = _srs_spotsColors[0].r;
				float4 localSpotsMask18_g45 = SpotsMask18_g45( spotsCount18_g45 , worldPos18_g45 , screenPosN18_g45 , spotsPosArray18_g45 , spotsDirArray18_g45 , spotsColorArray18_g45 );
				float clampDepth1138 = Linear01Depth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float temp_output_909_0 = ( 1.0 - _sunMaskSize );
				float temp_output_914_0 = ( temp_output_909_0 * ( 1.0 - ( 0.99 + (-0.5 + (_sunMaskSharpness - 0.0) * (0.01 - -0.5) / (1.0 - 0.0)) ) ) );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float dotResult910 = dot( _lightDirection , ase_worldViewDir );
				float temp_output_912_0 = saturate( dotResult910 );
				float dotResult913 = dot( temp_output_912_0 , temp_output_912_0 );
				float smoothstepResult915 = smoothstep( ( temp_output_909_0 - temp_output_914_0 ) , ( temp_output_909_0 + temp_output_914_0 ) , dotResult913);
				float dotResult924 = dot( WorldPosition.y , 1.0 );
				float temp_output_1_0_g32 = ( 3.0 + _sparklesStartDistance );
				int u1_g31 = (int)lifetimeUVx683;
				int v1_g31 = (int)2.0;
				Texture2D tex1_g31 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g31 = ReadPixels1_g31( u1_g31 , v1_g31 , tex1_g31 );
				float4 sparkles928 = ( ( ( ( localPointsMask7_g45 * _pointLightsIntensity ) + ( _spotLightsIntensity * localSpotsMask18_g45 ) ) + ( saturate( ( saturate( sign( ( clampDepth1138 - 0.99 ) ) ) * ( smoothstepResult915 * saturate( dotResult924 ) ) ) ) * _lightColor * saturate( ( ( distance( _WorldSpaceCameraPos , vPosWS1263 ) - temp_output_1_0_g32 ) / ( _sparklesStartDistance - temp_output_1_0_g32 ) ) ) ) ) * (localReadPixels1_g31).w );
				float temp_output_677_0 = (color740).a;
				float2 uv_MainTex = IN.ase_texcoord3.yz * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode561 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
				float pDist1404 = distance( _WorldSpaceCameraPos , vPosWS1263 );
				float temp_output_1_0_g34 = ( _NearBlurDistance + _NearBlurFalloff + 0.001 );
				float texDistBlend1248 = saturate( ( ( pDist1404 - temp_output_1_0_g34 ) / ( (float)_NearBlurDistance - temp_output_1_0_g34 ) ) );
				float lerpResult607 = lerp( ( temp_output_677_0 * tex2DNode561.r ) , ( temp_output_677_0 * tex2DNode561.g ) , texDistBlend1248);
				float temp_output_1_0_g33 = ( 0.001 + _OpacityFadeStartDistance + _OpacityFadeFalloff );
				float distFade1258 = ( 1.0 - saturate( ( ( pDist1404 - temp_output_1_0_g33 ) / ( _OpacityFadeStartDistance - temp_output_1_0_g33 ) ) ) );
				float opacity1149 = saturate( ( lerpResult607 * distFade1258 ) );
				float3 lerpResult1312 = lerp( temp_output_1265_0 , (sparkles928).xyz , ( (sparkles928).w * opacity1149 ));
				#ifdef _SPARKLES
				float3 staticSwitch1144 = lerpResult1312;
				#else
				float3 staticSwitch1144 = temp_output_1265_0;
				#endif
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = min( staticSwitch1144 , float3( 100,100,100 ) );
				float Alpha = opacity1149;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.positionCS, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			

			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _COLOR_GRADIENT
			#pragma shader_feature_local _RAND_GRADIENT_OLT
			#pragma shader_feature_local _RAND_GRADIENT
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile _ _FORWARD_PLUS
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _color;
			float4 _ColorMultiplier;
			float4 _Normal_ST;
			float4 _MainTex_ST;
			float4 _lightColor;
			float3 _lightDirection;
			float2 _SimTexSize;
			float2 _sizeMinMax;
			float2 _rotationSpeedMinMax;
			float2 _startRotationMinMax;
			float _NearBlurFalloff;
			int _NearBlurDistance;
			float _sparklesStartDistance;
			float _pointLightsIntensity;
			float _sunMaskSize;
			float _spotLightsIntensity;
			float _OpacityFadeStartDistance;
			int _lightsCount;
			float _gradientsRatio;
			float _stretchingMultiplier;
			float _sunMaskSharpness;
			float _OpacityFadeFalloff;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			TEXTURE2D(_SRS_particles);
			TEXTURE2D(_gradientTexOLT);
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);


			float4 ReadPixels1_g13( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g24( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g22( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g21( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g23( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			

			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float temp_output_1165_0 = ( v.ase_vertexID * 0.25 );
				int u1_g13 = (int)( temp_output_1165_0 % _SimTexSize.x );
				int v1_g13 = (int)( temp_output_1165_0 / _SimTexSize.y );
				Texture2D tex1_g13 =(Texture2D)_SRS_particles;
				float4 localReadPixels1_g13 = ReadPixels1_g13( u1_g13 , v1_g13 , tex1_g13 );
				float4 temp_output_1206_0 = localReadPixels1_g13;
				float3 temp_output_1_0_g14 = (temp_output_1206_0).xyz;
				float3 temp_output_6_0_g14 = frac( temp_output_1_0_g14 );
				float3 particlePos952 = ( ( temp_output_1_0_g14 - temp_output_6_0_g14 ) / 1000.0 );
				float3 temp_cast_2 = (1.0).xxx;
				float3 direction975 = ( ( temp_output_6_0_g14 * 2.0 ) - temp_cast_2 );
				float3 temp_output_977_0 = ( direction975 * _stretchingMultiplier );
				float2 temp_cast_3 = (1.0).xx;
				float mulTime588 = _TimeParameters.x * (_rotationSpeedMinMax.x + (v.ase_color.a - 0.0) * (_rotationSpeedMinMax.y - _rotationSpeedMinMax.x) / (1.0 - 0.0));
				float cos587 = cos( ( mulTime588 + ( (_startRotationMinMax.x + (v.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float sin587 = sin( ( mulTime588 + ( (_startRotationMinMax.x + (v.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float2 rotator587 = mul( ( ( ( v.ase_texcoord.xy * 2.0 ) - temp_cast_3 ) * (_sizeMinMax.x + (v.ase_color.a - 0.0) * (_sizeMinMax.y - _sizeMinMax.x) / (1.0 - 0.0)) ) - float2( 0,0 ) , float2x2( cos587 , -sin587 , sin587 , cos587 )) + float2( 0,0 );
				float2 break252 = rotator587;
				float flakeOffset_x231 = break252.x;
				float flakeOffset_y253 = break252.y;
				float3 normalizeResult956 = normalize( ( particlePos952 - _WorldSpaceCameraPos ) );
				float3 normalizeResult961 = normalize( cross( temp_output_977_0 , normalizeResult956 ) );
				float3 billboard239 = ( ( temp_output_977_0 * flakeOffset_x231 ) + ( flakeOffset_y253 * normalizeResult961 ) );
				float3 temp_output_261_0 = ( particlePos952 + billboard239 );
				float3 worldToObj558 = mul( GetWorldToObjectMatrix(), float4( temp_output_261_0, 1 ) ).xyz;
				float3 vPos633 = worldToObj558;
				
				o.ase_texcoord.x = v.ase_vertexID;
				o.ase_color = v.ase_color;
				o.ase_texcoord.yz = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vPos633;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float temp_output_1165_0 = ( IN.ase_texcoord.x * 0.25 );
				int u1_g13 = (int)( temp_output_1165_0 % _SimTexSize.x );
				int v1_g13 = (int)( temp_output_1165_0 / _SimTexSize.y );
				Texture2D tex1_g13 =(Texture2D)_SRS_particles;
				float4 localReadPixels1_g13 = ReadPixels1_g13( u1_g13 , v1_g13 , tex1_g13 );
				float4 temp_output_1206_0 = localReadPixels1_g13;
				float temp_output_2_0_g15 = (temp_output_1206_0).w;
				float temp_output_3_0_g15 = frac( temp_output_2_0_g15 );
				float lifetime662 = ( ( temp_output_2_0_g15 - temp_output_3_0_g15 ) / 1000.0 );
				float maxLifetime669 = ( 1000.0 * temp_output_3_0_g15 );
				float lerpResult1232 = lerp( (float)256 , 0.0 , (0.0 + (lifetime662 - 0.0) * (1.0 - 0.0) / (maxLifetime669 - 0.0)));
				float lifetimeUVx683 = lerpResult1232;
				int u1_g24 = (int)lifetimeUVx683;
				int v1_g24 = (int)0.0;
				Texture2D tex1_g24 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g24 = ReadPixels1_g24( u1_g24 , v1_g24 , tex1_g24 );
				float4 colorOLT_A673 = localReadPixels1_g24;
				int u1_g22 = (int)( IN.ase_color.a * 256.0 );
				int v1_g22 = (int)0.0;
				Texture2D tex1_g22 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g22 = ReadPixels1_g22( u1_g22 , v1_g22 , tex1_g22 );
				float4 gradient_A750 = localReadPixels1_g22;
				int u1_g21 = (int)( IN.ase_color.a * 256.0 );
				int v1_g21 = (int)1.0;
				Texture2D tex1_g21 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g21 = ReadPixels1_g21( u1_g21 , v1_g21 , tex1_g21 );
				float4 gradient_B762 = localReadPixels1_g21;
				float blend767 = step( IN.ase_color.a , _gradientsRatio );
				float4 lerpResult765 = lerp( gradient_A750 , gradient_B762 , blend767);
				#ifdef _RAND_GRADIENT
				float4 staticSwitch743 = lerpResult765;
				#else
				float4 staticSwitch743 = colorOLT_A673;
				#endif
				int u1_g23 = (int)lifetimeUVx683;
				int v1_g23 = (int)1.0;
				Texture2D tex1_g23 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g23 = ReadPixels1_g23( u1_g23 , v1_g23 , tex1_g23 );
				float4 colorOLT_B727 = localReadPixels1_g23;
				float4 lerpResult735 = lerp( colorOLT_A673 , colorOLT_B727 , blend767);
				#ifdef _RAND_GRADIENT_OLT
				float4 staticSwitch736 = lerpResult735;
				#else
				float4 staticSwitch736 = staticSwitch743;
				#endif
				#ifdef _COLOR_GRADIENT
				float4 staticSwitch720 = staticSwitch736;
				#else
				float4 staticSwitch720 = _color;
				#endif
				float4 color740 = ( staticSwitch720 * _ColorMultiplier );
				float temp_output_677_0 = (color740).a;
				float2 uv_MainTex = IN.ase_texcoord.yz * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode561 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
				float3 temp_output_1_0_g14 = (temp_output_1206_0).xyz;
				float3 temp_output_6_0_g14 = frac( temp_output_1_0_g14 );
				float3 particlePos952 = ( ( temp_output_1_0_g14 - temp_output_6_0_g14 ) / 1000.0 );
				float3 temp_cast_12 = (1.0).xxx;
				float3 direction975 = ( ( temp_output_6_0_g14 * 2.0 ) - temp_cast_12 );
				float3 temp_output_977_0 = ( direction975 * _stretchingMultiplier );
				float2 temp_cast_13 = (1.0).xx;
				float mulTime588 = _TimeParameters.x * (_rotationSpeedMinMax.x + (IN.ase_color.a - 0.0) * (_rotationSpeedMinMax.y - _rotationSpeedMinMax.x) / (1.0 - 0.0));
				float cos587 = cos( ( mulTime588 + ( (_startRotationMinMax.x + (IN.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float sin587 = sin( ( mulTime588 + ( (_startRotationMinMax.x + (IN.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float2 rotator587 = mul( ( ( ( IN.ase_texcoord.yz * 2.0 ) - temp_cast_13 ) * (_sizeMinMax.x + (IN.ase_color.a - 0.0) * (_sizeMinMax.y - _sizeMinMax.x) / (1.0 - 0.0)) ) - float2( 0,0 ) , float2x2( cos587 , -sin587 , sin587 , cos587 )) + float2( 0,0 );
				float2 break252 = rotator587;
				float flakeOffset_x231 = break252.x;
				float flakeOffset_y253 = break252.y;
				float3 normalizeResult956 = normalize( ( particlePos952 - _WorldSpaceCameraPos ) );
				float3 normalizeResult961 = normalize( cross( temp_output_977_0 , normalizeResult956 ) );
				float3 billboard239 = ( ( temp_output_977_0 * flakeOffset_x231 ) + ( flakeOffset_y253 * normalizeResult961 ) );
				float3 temp_output_261_0 = ( particlePos952 + billboard239 );
				float3 vPosWS1263 = temp_output_261_0;
				float pDist1404 = distance( _WorldSpaceCameraPos , vPosWS1263 );
				float temp_output_1_0_g34 = ( _NearBlurDistance + _NearBlurFalloff + 0.001 );
				float texDistBlend1248 = saturate( ( ( pDist1404 - temp_output_1_0_g34 ) / ( (float)_NearBlurDistance - temp_output_1_0_g34 ) ) );
				float lerpResult607 = lerp( ( temp_output_677_0 * tex2DNode561.r ) , ( temp_output_677_0 * tex2DNode561.g ) , texDistBlend1248);
				float temp_output_1_0_g33 = ( 0.001 + _OpacityFadeStartDistance + _OpacityFadeFalloff );
				float distFade1258 = ( 1.0 - saturate( ( ( pDist1404 - temp_output_1_0_g33 ) / ( _OpacityFadeStartDistance - temp_output_1_0_g33 ) ) ) );
				float opacity1149 = saturate( ( lerpResult607 * distFade1258 ) );
				

				surfaceDescription.Alpha = opacity1149;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			

			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _COLOR_GRADIENT
			#pragma shader_feature_local _RAND_GRADIENT_OLT
			#pragma shader_feature_local _RAND_GRADIENT
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile _ _FORWARD_PLUS
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _color;
			float4 _ColorMultiplier;
			float4 _Normal_ST;
			float4 _MainTex_ST;
			float4 _lightColor;
			float3 _lightDirection;
			float2 _SimTexSize;
			float2 _sizeMinMax;
			float2 _rotationSpeedMinMax;
			float2 _startRotationMinMax;
			float _NearBlurFalloff;
			int _NearBlurDistance;
			float _sparklesStartDistance;
			float _pointLightsIntensity;
			float _sunMaskSize;
			float _spotLightsIntensity;
			float _OpacityFadeStartDistance;
			int _lightsCount;
			float _gradientsRatio;
			float _stretchingMultiplier;
			float _sunMaskSharpness;
			float _OpacityFadeFalloff;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			TEXTURE2D(_SRS_particles);
			TEXTURE2D(_gradientTexOLT);
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);


			float4 ReadPixels1_g13( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g24( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g22( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g21( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			
			float4 ReadPixels1_g23( int u, int v, Texture2D tex )
			{
				return tex.Load(int3(u, v, 0));
			}
			

			float4 _SelectionID;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float temp_output_1165_0 = ( v.ase_vertexID * 0.25 );
				int u1_g13 = (int)( temp_output_1165_0 % _SimTexSize.x );
				int v1_g13 = (int)( temp_output_1165_0 / _SimTexSize.y );
				Texture2D tex1_g13 =(Texture2D)_SRS_particles;
				float4 localReadPixels1_g13 = ReadPixels1_g13( u1_g13 , v1_g13 , tex1_g13 );
				float4 temp_output_1206_0 = localReadPixels1_g13;
				float3 temp_output_1_0_g14 = (temp_output_1206_0).xyz;
				float3 temp_output_6_0_g14 = frac( temp_output_1_0_g14 );
				float3 particlePos952 = ( ( temp_output_1_0_g14 - temp_output_6_0_g14 ) / 1000.0 );
				float3 temp_cast_2 = (1.0).xxx;
				float3 direction975 = ( ( temp_output_6_0_g14 * 2.0 ) - temp_cast_2 );
				float3 temp_output_977_0 = ( direction975 * _stretchingMultiplier );
				float2 temp_cast_3 = (1.0).xx;
				float mulTime588 = _TimeParameters.x * (_rotationSpeedMinMax.x + (v.ase_color.a - 0.0) * (_rotationSpeedMinMax.y - _rotationSpeedMinMax.x) / (1.0 - 0.0));
				float cos587 = cos( ( mulTime588 + ( (_startRotationMinMax.x + (v.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float sin587 = sin( ( mulTime588 + ( (_startRotationMinMax.x + (v.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float2 rotator587 = mul( ( ( ( v.ase_texcoord.xy * 2.0 ) - temp_cast_3 ) * (_sizeMinMax.x + (v.ase_color.a - 0.0) * (_sizeMinMax.y - _sizeMinMax.x) / (1.0 - 0.0)) ) - float2( 0,0 ) , float2x2( cos587 , -sin587 , sin587 , cos587 )) + float2( 0,0 );
				float2 break252 = rotator587;
				float flakeOffset_x231 = break252.x;
				float flakeOffset_y253 = break252.y;
				float3 normalizeResult956 = normalize( ( particlePos952 - _WorldSpaceCameraPos ) );
				float3 normalizeResult961 = normalize( cross( temp_output_977_0 , normalizeResult956 ) );
				float3 billboard239 = ( ( temp_output_977_0 * flakeOffset_x231 ) + ( flakeOffset_y253 * normalizeResult961 ) );
				float3 temp_output_261_0 = ( particlePos952 + billboard239 );
				float3 worldToObj558 = mul( GetWorldToObjectMatrix(), float4( temp_output_261_0, 1 ) ).xyz;
				float3 vPos633 = worldToObj558;
				
				o.ase_texcoord.x = v.ase_vertexID;
				o.ase_color = v.ase_color;
				o.ase_texcoord.yz = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vPos633;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				o.positionCS = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float temp_output_1165_0 = ( IN.ase_texcoord.x * 0.25 );
				int u1_g13 = (int)( temp_output_1165_0 % _SimTexSize.x );
				int v1_g13 = (int)( temp_output_1165_0 / _SimTexSize.y );
				Texture2D tex1_g13 =(Texture2D)_SRS_particles;
				float4 localReadPixels1_g13 = ReadPixels1_g13( u1_g13 , v1_g13 , tex1_g13 );
				float4 temp_output_1206_0 = localReadPixels1_g13;
				float temp_output_2_0_g15 = (temp_output_1206_0).w;
				float temp_output_3_0_g15 = frac( temp_output_2_0_g15 );
				float lifetime662 = ( ( temp_output_2_0_g15 - temp_output_3_0_g15 ) / 1000.0 );
				float maxLifetime669 = ( 1000.0 * temp_output_3_0_g15 );
				float lerpResult1232 = lerp( (float)256 , 0.0 , (0.0 + (lifetime662 - 0.0) * (1.0 - 0.0) / (maxLifetime669 - 0.0)));
				float lifetimeUVx683 = lerpResult1232;
				int u1_g24 = (int)lifetimeUVx683;
				int v1_g24 = (int)0.0;
				Texture2D tex1_g24 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g24 = ReadPixels1_g24( u1_g24 , v1_g24 , tex1_g24 );
				float4 colorOLT_A673 = localReadPixels1_g24;
				int u1_g22 = (int)( IN.ase_color.a * 256.0 );
				int v1_g22 = (int)0.0;
				Texture2D tex1_g22 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g22 = ReadPixels1_g22( u1_g22 , v1_g22 , tex1_g22 );
				float4 gradient_A750 = localReadPixels1_g22;
				int u1_g21 = (int)( IN.ase_color.a * 256.0 );
				int v1_g21 = (int)1.0;
				Texture2D tex1_g21 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g21 = ReadPixels1_g21( u1_g21 , v1_g21 , tex1_g21 );
				float4 gradient_B762 = localReadPixels1_g21;
				float blend767 = step( IN.ase_color.a , _gradientsRatio );
				float4 lerpResult765 = lerp( gradient_A750 , gradient_B762 , blend767);
				#ifdef _RAND_GRADIENT
				float4 staticSwitch743 = lerpResult765;
				#else
				float4 staticSwitch743 = colorOLT_A673;
				#endif
				int u1_g23 = (int)lifetimeUVx683;
				int v1_g23 = (int)1.0;
				Texture2D tex1_g23 =(Texture2D)_gradientTexOLT;
				float4 localReadPixels1_g23 = ReadPixels1_g23( u1_g23 , v1_g23 , tex1_g23 );
				float4 colorOLT_B727 = localReadPixels1_g23;
				float4 lerpResult735 = lerp( colorOLT_A673 , colorOLT_B727 , blend767);
				#ifdef _RAND_GRADIENT_OLT
				float4 staticSwitch736 = lerpResult735;
				#else
				float4 staticSwitch736 = staticSwitch743;
				#endif
				#ifdef _COLOR_GRADIENT
				float4 staticSwitch720 = staticSwitch736;
				#else
				float4 staticSwitch720 = _color;
				#endif
				float4 color740 = ( staticSwitch720 * _ColorMultiplier );
				float temp_output_677_0 = (color740).a;
				float2 uv_MainTex = IN.ase_texcoord.yz * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode561 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
				float3 temp_output_1_0_g14 = (temp_output_1206_0).xyz;
				float3 temp_output_6_0_g14 = frac( temp_output_1_0_g14 );
				float3 particlePos952 = ( ( temp_output_1_0_g14 - temp_output_6_0_g14 ) / 1000.0 );
				float3 temp_cast_12 = (1.0).xxx;
				float3 direction975 = ( ( temp_output_6_0_g14 * 2.0 ) - temp_cast_12 );
				float3 temp_output_977_0 = ( direction975 * _stretchingMultiplier );
				float2 temp_cast_13 = (1.0).xx;
				float mulTime588 = _TimeParameters.x * (_rotationSpeedMinMax.x + (IN.ase_color.a - 0.0) * (_rotationSpeedMinMax.y - _rotationSpeedMinMax.x) / (1.0 - 0.0));
				float cos587 = cos( ( mulTime588 + ( (_startRotationMinMax.x + (IN.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float sin587 = sin( ( mulTime588 + ( (_startRotationMinMax.x + (IN.ase_color.a - 0.0) * (_startRotationMinMax.y - _startRotationMinMax.x) / (1.0 - 0.0)) * PI * 0.005555556 ) ) );
				float2 rotator587 = mul( ( ( ( IN.ase_texcoord.yz * 2.0 ) - temp_cast_13 ) * (_sizeMinMax.x + (IN.ase_color.a - 0.0) * (_sizeMinMax.y - _sizeMinMax.x) / (1.0 - 0.0)) ) - float2( 0,0 ) , float2x2( cos587 , -sin587 , sin587 , cos587 )) + float2( 0,0 );
				float2 break252 = rotator587;
				float flakeOffset_x231 = break252.x;
				float flakeOffset_y253 = break252.y;
				float3 normalizeResult956 = normalize( ( particlePos952 - _WorldSpaceCameraPos ) );
				float3 normalizeResult961 = normalize( cross( temp_output_977_0 , normalizeResult956 ) );
				float3 billboard239 = ( ( temp_output_977_0 * flakeOffset_x231 ) + ( flakeOffset_y253 * normalizeResult961 ) );
				float3 temp_output_261_0 = ( particlePos952 + billboard239 );
				float3 vPosWS1263 = temp_output_261_0;
				float pDist1404 = distance( _WorldSpaceCameraPos , vPosWS1263 );
				float temp_output_1_0_g34 = ( _NearBlurDistance + _NearBlurFalloff + 0.001 );
				float texDistBlend1248 = saturate( ( ( pDist1404 - temp_output_1_0_g34 ) / ( (float)_NearBlurDistance - temp_output_1_0_g34 ) ) );
				float lerpResult607 = lerp( ( temp_output_677_0 * tex2DNode561.r ) , ( temp_output_677_0 * tex2DNode561.g ) , texDistBlend1248);
				float temp_output_1_0_g33 = ( 0.001 + _OpacityFadeStartDistance + _OpacityFadeFalloff );
				float distFade1258 = ( 1.0 - saturate( ( ( pDist1404 - temp_output_1_0_g33 ) / ( _OpacityFadeStartDistance - temp_output_1_0_g33 ) ) ) );
				float opacity1149 = saturate( ( lerpResult607 * distFade1258 ) );
				

				surfaceDescription.Alpha = opacity1149;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19303
Node;AmplifyShaderEditor.CommentaryNode;632;3098.332,-1035.785;Inherit;False;2888.927;547.5844;;21;262;633;261;558;952;975;669;662;1179;529;1160;813;1198;1178;543;542;1166;1165;532;1206;1263;Vertex Position;1,1,1,1;0;0
Node;AmplifyShaderEditor.VertexIdVariableNode;532;3401.293,-1002.518;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;1166;3379.778,-899.9541;Inherit;False;Constant;_Float13;Float 13;26;0;Create;True;0;0;0;False;0;False;0.25;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1165;3582.778,-972.954;Inherit;False;2;2;0;INT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;1198;3554.711,-801.5508;Inherit;False;Property;_SimTexSize;SimTexSize;24;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleRemainderNode;543;3816.097,-984.6882;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;1178;3838.529,-805.1607;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;542;3751.198,-688.7853;Inherit;True;Property;_SRS_particles;_SRS_particles;10;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.CommentaryNode;270;3101.714,-63.81917;Inherit;False;2351.489;877.0695;;22;593;774;233;587;588;590;777;778;776;775;581;238;236;659;583;773;231;253;252;234;237;235;Calculate Particle Size And Rotation;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;1206;4080.202,-825.8301;Inherit;False;TexLoad;-1;;13;24997ab8bd7822d44bede2b16c924318;0;3;2;INT;0;False;3;INT;0;False;4;OBJECT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;235;3360.225,134.9178;Inherit;False;Constant;_Float4;Float 4;5;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;659;3169.873,147.9715;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;774;3732.79,595.28;Inherit;False;Property;_startRotationMinMax;_startRotationMinMax;8;1;[HideInInspector];Create;True;0;0;0;False;0;False;0,0;-180,180;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;593;3772.412,294.7991;Inherit;False;Property;_rotationSpeedMinMax;_rotationSpeedMinMax;9;1;[HideInInspector];Create;True;0;0;0;False;0;False;-5,5;-10,10;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TexCoordVertexDataNode;233;3151.715,-13.81873;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;529;4348.551,-917.8436;Inherit;False;True;True;True;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;237;3520.225,134.9178;Inherit;False;Constant;_Float5;Float 5;5;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;234;3568.714,4.179867;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;581;3176.219,349.9035;Inherit;False;Property;_sizeMinMax;_sizeMinMax;6;0;Create;True;0;0;0;False;0;False;0.004,0.008;0.007,0.01;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TFHCRemapNode;775;4028.793,461.2805;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;776;4042.795,636.2798;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;778;4067.437,715.8223;Inherit;False;Constant;_Float3;Float 3;17;0;Create;True;0;0;0;False;0;False;0.005555556;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;590;4038.663,232.3907;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1160;4655.843,-952.5403;Inherit;False;Unpack3dVectors;-1;;14;b7fd13cda2d9947418e24c4aad49bb03;0;1;1;FLOAT3;0,0,0;False;2;FLOAT3;4;FLOAT3;3
Node;AmplifyShaderEditor.CommentaryNode;966;3097.668,888.2849;Inherit;False;1664.285;696.488;;15;976;239;948;947;974;954;953;955;977;961;957;963;962;956;949;Stretched Billboard;1,1,1,1;0;0
Node;AmplifyShaderEditor.TFHCRemapNode;583;3439.091,337.2854;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;236;3726.715,10.17986;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;777;4343.32,430.9386;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;588;4235.647,235.8981;Inherit;False;1;0;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;952;4953.946,-982.0891;Inherit;False;particlePos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;1179;4347.21,-741.9963;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;773;4645.765,78.35391;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;238;3947.699,9.768453;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;953;3210.306,1313.579;Inherit;False;952;particlePos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;954;3155.355,1407.229;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;975;4924.608,-868.3993;Inherit;False;direction;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;813;4599.677,-693.6192;Inherit;False;UnpackFloats;-1;;15;fb7d2f1b3bb77824887f04cb05937452;0;1;2;FLOAT;0;False;2;FLOAT;0;FLOAT;1
Node;AmplifyShaderEditor.SimpleSubtractOpNode;955;3417.355,1351.229;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;974;3359.82,1157.694;Inherit;False;Property;_stretchingMultiplier;_stretchingMultiplier;20;0;Create;True;0;0;0;False;0;False;1;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;587;4778.946,15.66256;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;976;3344.889,996.4633;Inherit;False;975;direction;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;684;6141.033,1378.722;Inherit;False;1071.926;359.5641;;7;670;663;665;683;1201;1232;1233;Calculate UV.x from lifetime;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;662;4870.401,-700.607;Inherit;False;lifetime;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;669;4878.215,-614.6395;Inherit;False;maxLifetime;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;252;4973.319,18.61098;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;977;3628.889,1053.464;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;956;3594.355,1326.228;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;663;6171.714,1496.53;Inherit;False;662;lifetime;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;670;6173.033,1567.815;Inherit;False;669;maxLifetime;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;253;5205.821,69.71091;Inherit;False;flakeOffset_y;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;231;5203.832,-11.11861;Inherit;False;flakeOffset_x;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CrossProductOpNode;957;3776.034,1185.485;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;744;6145.145,-772.1112;Inherit;False;983.017;515.2935;;7;750;1224;1223;1222;1221;1220;1219;Gradient A;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;754;6141.349,-170.7516;Inherit;False;947.6141;495.0339;;7;1213;1214;1212;1217;1218;762;1216;Gradient B;1,1,1,1;0;0
Node;AmplifyShaderEditor.TexturePropertyNode;686;5656.661,717.8879;Inherit;True;Property;_gradientTexOLT;gradientTexOLT;11;0;Create;True;0;0;0;True;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TFHCRemapNode;665;6392.971,1516.286;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;4;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;1201;6582.908,1415.587;Inherit;False;Constant;_NoiseTexWidth;NoiseTexWidth;25;0;Create;True;0;0;0;False;0;False;256;0;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;1233;6603.424,1492.707;Inherit;False;Constant;_Float12;Float 12;25;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;961;3971.794,1190.366;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;947;3937.873,1105.396;Inherit;False;253;flakeOffset_y;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;948;3935.506,1019.263;Inherit;False;231;flakeOffset_x;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;766;3216.497,-2687.677;Inherit;False;540;353.3416;;4;738;733;767;734;Blend;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;1232;6791.424,1466.707;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1218;6241.635,66.67521;Inherit;False;Constant;_Float17;Float 17;25;0;Create;True;0;0;0;False;0;False;256;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;1216;6209.65,-110.1404;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1223;6238.638,-528.3011;Inherit;False;Constant;_Float19;Float 17;25;0;Create;True;0;0;0;False;0;False;256;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;1224;6181.638,-707.3011;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;716;5896.564,717.942;Inherit;False;gradientTexOLT;-1;True;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;949;4176.834,958.9292;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;962;4182.892,1109.17;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;674;6135.311,393.8713;Inherit;False;883.272;350.9368;;5;673;1211;685;1209;1210;Color over lifetime A;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;721;6134.96,850.7137;Inherit;False;885.272;345.9368;;5;727;1203;1208;726;1207;Color over lifetime B;1,1,1,1;0;0
Node;AmplifyShaderEditor.VertexColorNode;738;3233.711,-2643.172;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;734;3237.167,-2440.83;Inherit;False;Property;_gradientsRatio;_gradientsRatio;14;1;[HideInInspector];Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;683;6983.958,1467.391;Inherit;False;lifetimeUVx;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1214;6237.803,145.1754;Inherit;False;Constant;_Float16;Float 2;25;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1217;6428.635,31.67527;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1213;6190.299,227.6743;Inherit;False;716;gradientTexOLT;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;1219;6180.302,-363.3012;Inherit;False;716;gradientTexOLT;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RangedFloatNode;1220;6234.806,-449.8008;Inherit;False;Constant;_Float18;Float 2;25;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1222;6425.638,-563.301;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;963;4358.985,1016.408;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StepOpNode;733;3428.167,-2550.83;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;726;6218.08,910.3963;Inherit;False;683;lifetimeUVx;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1208;6173.587,1085.15;Inherit;False;716;gradientTexOLT;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RangedFloatNode;1203;6228.091,998.651;Inherit;False;Constant;_Float2;Float 2;25;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1210;6202.251,638.1489;Inherit;False;716;gradientTexOLT;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;685;6221.431,453.5538;Inherit;False;683;lifetimeUVx;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1211;6256.755,547.6499;Inherit;False;Constant;_Float15;Float 2;25;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1212;6612.804,42.17551;Inherit;False;TexLoad;-1;;21;24997ab8bd7822d44bede2b16c924318;0;3;2;INT;0;False;3;INT;0;False;4;OBJECT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;1221;6614.806,-496.801;Inherit;False;TexLoad;-1;;22;24997ab8bd7822d44bede2b16c924318;0;3;2;INT;0;False;3;INT;0;False;4;OBJECT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;239;4536.808,1019.594;Inherit;False;billboard;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;767;3553.729,-2550.422;Inherit;False;blend;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1207;6486.091,920.651;Inherit;False;TexLoad;-1;;23;24997ab8bd7822d44bede2b16c924318;0;3;2;INT;0;False;3;INT;0;False;4;OBJECT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;1209;6470.755,500.6499;Inherit;False;TexLoad;-1;;24;24997ab8bd7822d44bede2b16c924318;0;3;2;INT;0;False;3;INT;0;False;4;OBJECT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;762;6823.921,38.73969;Inherit;False;gradient_B;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;750;6882.903,-495.5097;Inherit;False;gradient_A;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;262;5176.041,-864.6547;Inherit;False;239;billboard;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;739;3196.739,-2757.343;Inherit;False;2788.118;862.2819;;4;740;1162;1163;768;Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;764;3799.629,-2592.853;Inherit;False;762;gradient_B;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;769;3803.326,-2506.983;Inherit;False;767;blend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;763;3800.547,-2682.866;Inherit;False;750;gradient_A;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;727;6725.105,919.5098;Inherit;False;colorOLT_B;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;673;6714.456,494.6674;Inherit;False;colorOLT_A;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;261;5369.739,-979.4252;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;1410;2448,-1792;Inherit;False;2068;659;;21;1382;1387;1388;1406;1407;1376;1408;1384;1383;1248;1258;1405;1375;1374;1385;1386;1409;1377;1378;1381;1404;Particles distance blend;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;765;4031.919,-2585.306;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;729;3806.593,-2247.998;Inherit;False;727;colorOLT_B;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;728;3804.593,-2375.998;Inherit;False;673;colorOLT_A;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;768;3813.719,-2159.568;Inherit;False;767;blend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1263;5510.024,-782.6433;Inherit;False;vPosWS;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;735;4041.229,-2268.221;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StaticSwitch;743;4238.905,-2435.344;Inherit;False;Property;_RAND_GRADIENT;RAND_GRADIENT;24;0;Create;True;0;0;0;True;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;1377;2496,-1552;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;1378;2560,-1392;Inherit;False;1263;vPosWS;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;736;4531.531,-2357.767;Inherit;False;Property;_RAND_GRADIENT_OLT;RAND_GRADIENT_OLT;21;0;Create;True;0;0;0;True;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;719;4592.045,-2568.888;Inherit;False;Property;_color;color;13;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DistanceOpNode;1381;2784,-1488;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;720;4842.18,-2463.631;Inherit;False;Property;_COLOR_GRADIENT;COLOR_GRADIENT;18;0;Create;True;0;0;0;True;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;1162;4866.369,-2347.337;Inherit;False;Property;_ColorMultiplier;ColorMultiplier;23;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1407;3248,-1248;Inherit;False;Property;_OpacityFadeFalloff;_OpacityFadeFalloff;3;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1376;3216,-1360;Inherit;False;Property;_OpacityFadeStartDistance;_OpacityFadeStartDistance;4;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1374;3232,-1488;Inherit;False;Constant;_Float21;Float 13;25;0;Create;True;0;0;0;False;0;False;0.001;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;1385;3232,-1728;Inherit;False;Property;_NearBlurDistance;_NearBlurDistance;5;0;Create;True;0;0;0;False;0;False;8;10;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;1386;3248,-1648;Inherit;False;Property;_NearBlurFalloff;_NearBlurFalloff;0;0;Create;True;0;0;0;False;0;False;0.8;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1404;2976,-1488;Inherit;False;pDist;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1163;5200.911,-2466.159;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;1406;3504,-1232;Inherit;False;1404;pDist;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1408;3552,-1440;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1405;3488,-1536;Inherit;False;1404;pDist;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1375;3536,-1712;Inherit;False;3;3;0;INT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1409;3456,-1616;Inherit;False;1;0;INT;0;False;1;INT;0
Node;AmplifyShaderEditor.CommentaryNode;1148;4549.294,-1768.024;Inherit;False;1735.416;503.3545;;11;1034;1149;644;741;636;561;677;607;642;614;566;Opacity;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;740;5434.06,-2463.588;Inherit;False;color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;1382;3712,-1392;Inherit;False;Inverse Lerp;-1;;33;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1383;3712,-1616;Inherit;False;Inverse Lerp;-1;;34;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;741;4599.294,-1682.174;Inherit;False;740;color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;1387;3904,-1392;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;1384;3888,-1632;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;677;4788.424,-1680.316;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;561;4689.368,-1586.707;Inherit;True;Property;_MainTex;Texture;1;0;Create;False;0;0;0;False;0;False;-1;None;d8fe714c5c4ed5c40bee4dd67a209895;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;1388;4080,-1392;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1248;4080,-1632;Inherit;False;texDistBlend;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;566;5107.049,-1718.024;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;614;5109.558,-1614.009;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;636;5117.87,-1507.035;Inherit;False;1248;texDistBlend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1258;4272,-1392;Inherit;False;distFade;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;607;5325.875,-1615.079;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;644;5325.822,-1464.895;Inherit;False;1258;distFade;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;642;5555.762,-1553.185;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;558;5490.977,-986.3579;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;1034;5808.867,-1553.324;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;1341;10017.79,-1765.694;Inherit;False;228;211;Clamp too bright pixels;1;1343;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1151;6393.666,-1313.023;Inherit;False;973.229;369.058;;4;1325;1152;1326;1331;Lighting;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;897;3177.825,-4226.904;Inherit;False;2948.069;1343.103;;49;1138;1137;1136;1135;1134;924;1024;1025;1026;1028;1015;1045;893;895;906;928;933;1039;919;902;886;921;918;926;922;852;851;925;917;916;915;914;913;912;910;909;908;1225;1226;1227;1231;1279;1281;1282;1283;1284;1285;1287;1319;Sparkles;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;633;5716.255,-987.9651;Inherit;False;vPos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;703;7165.692,1837.129;Inherit;False;1069.661;408.0276;;8;699;694;691;698;700;693;692;689;Size and rotation over lifetime;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1149;5986.338,-1552.631;Inherit;False;opacity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;908;3884.611,-3676.69;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;909;3694.546,-3821.934;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;910;3623.357,-3923.004;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;912;3819.23,-3929.997;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;913;4026.683,-3953.378;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;914;4069.684,-3703.677;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;915;4432.004,-3904.079;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;916;4249.542,-3761.045;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;917;4236.526,-3864.435;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;925;3498.529,-3699.835;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-0.5;False;4;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;851;3495.851,-3803.169;Inherit;False;Property;_sunMaskSize;Sun Mask Size;15;0;Create;False;0;0;0;False;0;False;0;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;852;3197.669,-3706.109;Inherit;False;Property;_sunMaskSharpness;Sun Mask Sharpness;16;0;Create;False;0;0;0;False;0;False;0;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;922;3712.576,-3721.191;Inherit;False;2;2;0;FLOAT;0.99;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;926;3347.262,-3941.619;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;918;4416.511,-3649.931;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;921;4066.365,-3583.221;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;902;3335.941,-4106.386;Inherit;False;Property;_lightDirection;lightDirection;18;0;Create;False;0;0;0;False;0;False;0,0,0;-0.2816645,-0.5045274,0.81616;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;919;4600.217,-3735.004;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1039;5080.465,-3757.71;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;933;5488.115,-3579.519;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1024;4759.819,-3812.311;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;1134;4081.347,-4129.084;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1135;3902.348,-4045.086;Inherit;False;Constant;_Float14;Float 10;28;0;Create;True;0;0;0;False;0;False;0.99;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;1136;4243.349,-4127.084;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;1137;4389.471,-4047.409;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1025;5277.609,-3745.493;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;1026;4924.417,-3770.963;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1157;8837.097,-1897.239;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;1227;4712.321,-3103.07;Inherit;False;TexLoad;-1;;31;24997ab8bd7822d44bede2b16c924318;0;3;2;INT;0;False;3;INT;0;False;4;OBJECT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;1231;4918.152,-3105.404;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1226;4511.321,-3068.07;Inherit;False;Constant;_Float20;Float 2;25;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1225;4461.817,-2979.571;Inherit;False;716;gradientTexOLT;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;886;4480.81,-3175.708;Inherit;False;683;lifetimeUVx;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;924;4271.429,-3574.846;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;1284;4177.135,-3097.088;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;1283;3867.135,-3171.088;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;895;3883.634,-3260.282;Inherit;False;Property;_sparklesStartDistance;Sparkles Start Distance;17;0;Create;False;0;0;0;False;0;False;1;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1281;3968.42,-3366.389;Inherit;False;Constant;_Float1;Float 1;24;0;Create;True;0;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1282;4204.42,-3344.389;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1279;4383.269,-3322.502;Inherit;False;Inverse Lerp;-1;;32;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;1015;4726.435,-4174.552;Inherit;False;Property;_lightsCount;_lightsCount;7;0;Create;True;0;0;0;False;0;False;5;16;False;0;1;INT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1285;3932.135,-3002.088;Inherit;False;1263;vPosWS;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;1028;4688.69,-4015.663;Inherit;False;Property;_pointLightsIntensity;_pointLightsIntensity;21;0;Create;True;0;0;0;False;0;False;1;0.01;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1045;4728,-3931.935;Inherit;False;Property;_spotLightsIntensity;_spotLightsIntensity;22;0;Create;True;0;0;0;False;0;False;1;0.01;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1287;4712.241,-4094.785;Inherit;False;1263;vPosWS;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScreenDepthNode;1138;3841.347,-4134.776;Inherit;False;1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;893;4851.334,-3390.282;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;742;8277.56,-2128.235;Inherit;False;740;color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;993;8010.646,-1827.399;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GrabScreenPosition;992;7671.65,-1949.398;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;988;7704.685,-1673.975;Inherit;True;Property;_Normal;Normal;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;989;7484.65,-1624.399;Inherit;False;Constant;_NormalIntensity;Normal Intensity;4;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;990;8146.125,-1824.141;Inherit;False;Global;_GrabScreen0;Grab Screen 0;28;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;1310;8581.308,-2047.749;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;1234;8628.986,-1867.229;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;1311;8366.308,-1848.749;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;1309;8895.325,-1552.067;Inherit;False;True;True;True;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;1313;8894.308,-1472.749;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;906;4644.86,-3624.133;Inherit;False;Property;_lightColor;lightColor;19;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,1;47.93726,47.93726,47.93726,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;1156;9009.73,-1945.22;Inherit;False;Property;_REFRACTION;_REFRACTION;26;0;Create;True;0;0;0;True;0;False;0;1;1;False;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;1315;8925.232,-1379.188;Inherit;False;1149;opacity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1316;9148.486,-1471.667;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StickyNoteNode;1331;6403.175,-1269.656;Inherit;False;886.8867;191.451;New Note;;0,0,0,1;Add next directives to make custom lighting work:$$#define ASE_NEEDS_FRAG_SHADOWCOORDS$#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN$multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH$#pragma multi_compile _ _FORWARD_PLUS$;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;1326;6422.998,-1054.922;Inherit;False;1263;vPosWS;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;699;7976.755,2148.557;Inherit;False;rotMaxOLT;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;694;7971.94,1883.129;Inherit;False;sizeMinOLT;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;691;7596.034,1918.189;Inherit;True;Property;_colorOverLifetime1;sizeAndRotOverLife;12;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;698;7976.654,1970.857;Inherit;False;sizeMaxOLT;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;700;7979.656,2066.457;Inherit;False;rotMinOLT;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;693;7430.158,1946.787;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;692;7252.103,2030.147;Inherit;False;Constant;_Float7;Float 6;9;0;Create;True;0;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;689;7213.692,1930.206;Inherit;False;683;lifetimeUVx;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;634;10411.94,-1476.054;Inherit;False;633;vPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;1150;10412.15,-1575.164;Inherit;False;1149;opacity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;1325;6634.059,-1053.839;Inherit;False;float4 ShadowCoords = float4(0, 0, 0, 0)@$#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)$	#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)$		ShadowCoords = TransformWorldToShadowCoord(worldPos)@$	#endif$#endif$float3 indirectLighting = SampleSH(half3(0, 1, 0))@$Light mainLight = GetMainLight(ShadowCoords)@$float mainLightAtten = mainLight.distanceAttenuation * mainLight.shadowAttenuation@$float3 lighting = _MainLightColor.rgb * mainLightAtten@$lighting += indirectLighting@$return lighting@;3;Create;1;True;worldPos;FLOAT3;0,0,0;In;;Inherit;False;CalculateCustomLighting;False;False;0;;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1152;6876.507,-1054.704;Inherit;False;lighting;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;1187;9055.049,-2046.272;Inherit;False;1152;lighting;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1265;9313.137,-1793.911;Inherit;False;2;2;0;FLOAT3;1,1,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;1312;9504.72,-1643.625;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;1144;9731.192,-1712;Inherit;False;Property;_SPARKLES;SPARKLES;27;0;Create;True;0;0;0;True;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;850;8678.461,-1552.913;Inherit;False;928;sparkles;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;1319;4968.666,-4092.797;Inherit;False;GetPointLightsMask;-1;;45;5fc1436ebbdcf85419c854243b4ddabf;0;4;9;INT;5;False;28;FLOAT3;5,0,0;False;23;FLOAT;5;False;26;FLOAT;5;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;928;5691.443,-3581.905;Inherit;False;sparkles;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMinOpNode;1343;10089.35,-1701.356;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;100,100,100;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1235;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1237;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1238;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1239;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1240;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1241;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1242;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1243;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1244;10824.47,-1658.888;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1236;10824.47,-1659.888;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;Hidden/NOT_Lonely/Weatherade/SRS_ParticleSystem_Render;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;1;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;5;Include;;False;;Native;False;0;0;;Define;ASE_NEEDS_FRAG_SHADOWCOORDS;False;;Custom;False;0;0;;Pragma;multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN;False;;Custom;False;0;0;;Pragma;multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH;False;;Custom;False;0;0;;Pragma;multi_compile _ _FORWARD_PLUS;False;;Custom;False;0;0;;;0;0;Standard;21;Surface;1;638473867910758580;  Blend;0;0;Two Sided;2;638473867211662689;Forward Only;0;0;Cast Shadows;0;638473856194667547;  Use Shadow Threshold;0;0;GPU Instancing;0;638473856210527346;LOD CrossFade;0;638473856230363676;Built-in Fog;1;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;0;638473856354748348;0;10;False;True;False;False;False;False;True;True;False;False;False;;True;0
WireConnection;1165;0;532;0
WireConnection;1165;1;1166;0
WireConnection;543;0;1165;0
WireConnection;543;1;1198;1
WireConnection;1178;0;1165;0
WireConnection;1178;1;1198;2
WireConnection;1206;2;543;0
WireConnection;1206;3;1178;0
WireConnection;1206;4;542;0
WireConnection;529;0;1206;0
WireConnection;234;0;233;0
WireConnection;234;1;235;0
WireConnection;775;0;659;4
WireConnection;775;3;774;1
WireConnection;775;4;774;2
WireConnection;590;0;659;4
WireConnection;590;3;593;1
WireConnection;590;4;593;2
WireConnection;1160;1;529;0
WireConnection;583;0;659;4
WireConnection;583;3;581;1
WireConnection;583;4;581;2
WireConnection;236;0;234;0
WireConnection;236;1;237;0
WireConnection;777;0;775;0
WireConnection;777;1;776;0
WireConnection;777;2;778;0
WireConnection;588;0;590;0
WireConnection;952;0;1160;4
WireConnection;1179;0;1206;0
WireConnection;773;0;588;0
WireConnection;773;1;777;0
WireConnection;238;0;236;0
WireConnection;238;1;583;0
WireConnection;975;0;1160;3
WireConnection;813;2;1179;0
WireConnection;955;0;953;0
WireConnection;955;1;954;0
WireConnection;587;0;238;0
WireConnection;587;2;773;0
WireConnection;662;0;813;0
WireConnection;669;0;813;1
WireConnection;252;0;587;0
WireConnection;977;0;976;0
WireConnection;977;1;974;0
WireConnection;956;0;955;0
WireConnection;253;0;252;1
WireConnection;231;0;252;0
WireConnection;957;0;977;0
WireConnection;957;1;956;0
WireConnection;665;0;663;0
WireConnection;665;2;670;0
WireConnection;961;0;957;0
WireConnection;1232;0;1201;0
WireConnection;1232;1;1233;0
WireConnection;1232;2;665;0
WireConnection;716;0;686;0
WireConnection;949;0;977;0
WireConnection;949;1;948;0
WireConnection;962;0;947;0
WireConnection;962;1;961;0
WireConnection;683;0;1232;0
WireConnection;1217;0;1216;4
WireConnection;1217;1;1218;0
WireConnection;1222;0;1224;4
WireConnection;1222;1;1223;0
WireConnection;963;0;949;0
WireConnection;963;1;962;0
WireConnection;733;0;738;4
WireConnection;733;1;734;0
WireConnection;1212;2;1217;0
WireConnection;1212;3;1214;0
WireConnection;1212;4;1213;0
WireConnection;1221;2;1222;0
WireConnection;1221;3;1220;0
WireConnection;1221;4;1219;0
WireConnection;239;0;963;0
WireConnection;767;0;733;0
WireConnection;1207;2;726;0
WireConnection;1207;3;1203;0
WireConnection;1207;4;1208;0
WireConnection;1209;2;685;0
WireConnection;1209;3;1211;0
WireConnection;1209;4;1210;0
WireConnection;762;0;1212;0
WireConnection;750;0;1221;0
WireConnection;727;0;1207;0
WireConnection;673;0;1209;0
WireConnection;261;0;952;0
WireConnection;261;1;262;0
WireConnection;765;0;763;0
WireConnection;765;1;764;0
WireConnection;765;2;769;0
WireConnection;1263;0;261;0
WireConnection;735;0;728;0
WireConnection;735;1;729;0
WireConnection;735;2;768;0
WireConnection;743;1;728;0
WireConnection;743;0;765;0
WireConnection;736;1;743;0
WireConnection;736;0;735;0
WireConnection;1381;0;1377;0
WireConnection;1381;1;1378;0
WireConnection;720;1;719;0
WireConnection;720;0;736;0
WireConnection;1404;0;1381;0
WireConnection;1163;0;720;0
WireConnection;1163;1;1162;0
WireConnection;1408;0;1374;0
WireConnection;1408;1;1376;0
WireConnection;1408;2;1407;0
WireConnection;1375;0;1385;0
WireConnection;1375;1;1386;0
WireConnection;1375;2;1374;0
WireConnection;1409;0;1385;0
WireConnection;740;0;1163;0
WireConnection;1382;1;1408;0
WireConnection;1382;2;1376;0
WireConnection;1382;3;1406;0
WireConnection;1383;1;1375;0
WireConnection;1383;2;1409;0
WireConnection;1383;3;1405;0
WireConnection;1387;0;1382;0
WireConnection;1384;0;1383;0
WireConnection;677;0;741;0
WireConnection;1388;0;1387;0
WireConnection;1248;0;1384;0
WireConnection;566;0;677;0
WireConnection;566;1;561;1
WireConnection;614;0;677;0
WireConnection;614;1;561;2
WireConnection;1258;0;1388;0
WireConnection;607;0;566;0
WireConnection;607;1;614;0
WireConnection;607;2;636;0
WireConnection;642;0;607;0
WireConnection;642;1;644;0
WireConnection;558;0;261;0
WireConnection;1034;0;642;0
WireConnection;633;0;558;0
WireConnection;1149;0;1034;0
WireConnection;908;0;922;0
WireConnection;909;0;851;0
WireConnection;910;0;902;0
WireConnection;910;1;926;0
WireConnection;912;0;910;0
WireConnection;913;0;912;0
WireConnection;913;1;912;0
WireConnection;914;0;909;0
WireConnection;914;1;908;0
WireConnection;915;0;913;0
WireConnection;915;1;917;0
WireConnection;915;2;916;0
WireConnection;916;0;909;0
WireConnection;916;1;914;0
WireConnection;917;0;909;0
WireConnection;917;1;914;0
WireConnection;925;0;852;0
WireConnection;922;1;925;0
WireConnection;918;0;924;0
WireConnection;919;0;915;0
WireConnection;919;1;918;0
WireConnection;1039;0;1026;0
WireConnection;1039;1;906;0
WireConnection;1039;2;893;0
WireConnection;933;0;1025;0
WireConnection;933;1;1231;0
WireConnection;1024;0;1137;0
WireConnection;1024;1;919;0
WireConnection;1134;0;1138;0
WireConnection;1134;1;1135;0
WireConnection;1136;0;1134;0
WireConnection;1137;0;1136;0
WireConnection;1025;0;1319;0
WireConnection;1025;1;1039;0
WireConnection;1026;0;1024;0
WireConnection;1157;0;1310;0
WireConnection;1157;1;1234;0
WireConnection;1227;2;886;0
WireConnection;1227;3;1226;0
WireConnection;1227;4;1225;0
WireConnection;1231;0;1227;0
WireConnection;924;0;921;2
WireConnection;1284;0;1283;0
WireConnection;1284;1;1285;0
WireConnection;1282;0;1281;0
WireConnection;1282;1;895;0
WireConnection;1279;1;1282;0
WireConnection;1279;2;895;0
WireConnection;1279;3;1284;0
WireConnection;893;0;1279;0
WireConnection;993;0;992;0
WireConnection;993;1;988;0
WireConnection;988;5;989;0
WireConnection;990;0;993;0
WireConnection;1310;0;742;0
WireConnection;1234;0;1311;0
WireConnection;1311;0;990;0
WireConnection;1309;0;850;0
WireConnection;1313;0;850;0
WireConnection;1156;1;1310;0
WireConnection;1156;0;1157;0
WireConnection;1316;0;1313;0
WireConnection;1316;1;1315;0
WireConnection;699;0;691;4
WireConnection;694;0;691;1
WireConnection;691;1;693;0
WireConnection;698;0;691;2
WireConnection;700;0;691;3
WireConnection;693;0;689;0
WireConnection;693;1;692;0
WireConnection;1325;0;1326;0
WireConnection;1152;0;1325;0
WireConnection;1265;0;1187;0
WireConnection;1265;1;1156;0
WireConnection;1312;0;1265;0
WireConnection;1312;1;1309;0
WireConnection;1312;2;1316;0
WireConnection;1144;1;1265;0
WireConnection;1144;0;1312;0
WireConnection;1319;9;1015;0
WireConnection;1319;28;1287;0
WireConnection;1319;23;1028;0
WireConnection;1319;26;1045;0
WireConnection;928;0;933;0
WireConnection;1343;0;1144;0
WireConnection;1236;2;1343;0
WireConnection;1236;3;1150;0
WireConnection;1236;5;634;0
ASEEND*/
//CHKSM=7E5FCD2634C1548FE212445741DB80596717CD52