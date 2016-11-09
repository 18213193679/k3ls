#include "pssm\\config.fxh"

texture2D ScreenShadowMapProcessed : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "G16R16F";
>;
sampler2D ScreenShadowMapProcessedSamp = sampler_state {
    texture = <ScreenShadowMapProcessed>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};
texture ScreenShadowWorkBuff : RENDERCOLORTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "R16F";
>;
sampler ScreenShadowWorkBuffSampler = sampler_state {
    texture = <ScreenShadowWorkBuff>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture ScreenShadowMap : OFFSCREENRENDERTARGET <
    string Description = "PSSM";
    float2 ViewPortRatio = {1.0, 1.0};
    string Format = "A16B16G16R16F";
    float4 ClearColor = { 1, 0, 0, 0 };
    float ClearDepth = 1.0;
    int MipLevels = 1;
    string DefaultEffect =
        "self = hide;"
        "skybox*.* = hide;"
        "*.pmx=pssm\\object.fx;"
        "*.pmd=pssm\\object.fx;"
        "*.x=hide;";
>;
sampler ScreenShadowMapSampler = sampler_state {
    texture = <ScreenShadowMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

shared texture PSSMDepth : OFFSCREENRENDERTARGET <
    string Description = "PSSMDepth";
	int Width = SHADOW_MAP_SIZE;
    int Height = SHADOW_MAP_SIZE;
    string Format = "R32F";
    float4 ClearColor = { 0, 0, 0, 0 };
    float ClearDepth = 1.0;
    int MipLevels = 1;
    string DefaultEffect =
        "self = hide;"
        "skybox*.* = hide;"
        "*.pmx=pssm\\depth.fx;"
        "*.pmd=pssm\\depth.fx;"
        "*.x=hide;";
>;


float BilateralWeight(float r, float depth, float center_d, float sharpness)
{
    const float blurSigma = 6 * depth;
    const float blurFalloff = 1.0f / (2.0f * blurSigma * blurSigma);

    float ddiff = (depth - center_d) * sharpness;
    return exp2(-r * r * blurFalloff - ddiff * ddiff);
}

#define SHADOW_BLUR_COUNT 5

float4 ShadowMapBlurPS(float2 coord : TEXCOORD0, uniform sampler2D source, uniform float2 offset) : COLOR
{
    float4 center = tex2D(source, coord);
	
    float centerDepth = abs(tex2D(ScreenShadowMapSampler, coord).y);

    float2 sum = float2(center.x, 1);

    float2 offset1 = coord + offset;
    float2 offset2 = coord - offset;

    [unroll]
    for(int r = 1; r < SHADOW_BLUR_COUNT; r++)
    {        
        float shadow1 = tex2D(source, offset1).x;
		float s1Depth = abs(tex2D(ScreenShadowMapSampler, offset1).y);
        float shadow2 = tex2D(source, offset2).x;
        float s2Depth = abs(tex2D(ScreenShadowMapSampler, offset2).y);
		
        float bilateralWeight1 = BilateralWeight(r, s1Depth, centerDepth, 3);
        float bilateralWeight2 = BilateralWeight(r, s2Depth, centerDepth, 3);
        
        sum.x += shadow1.x * bilateralWeight1;
        sum.x += shadow2.x * bilateralWeight2;

        sum.y += bilateralWeight1;
        sum.y += bilateralWeight2;
        
        offset1 += offset;
        offset2 -= offset;
    }

    return float4(sum.x / sum.y, tex2D(ScreenShadowMapSampler, coord).z,0,1);
}

#undef SHADOW_BLUR_COUNT

#define GENPSSM \
		"RenderColorTarget0=ScreenShadowWorkBuff;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=PSSMBilateralBlurX;" \
		\
		"RenderColorTarget0=ScreenShadowMapProcessed;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=PSSMBilateralBlurY;"